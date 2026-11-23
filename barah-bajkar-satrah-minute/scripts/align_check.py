"""Independent check of an alignment: paragraph starts should follow audible pauses.

For every paragraph after the first, report whether a detected pause (>= 0.3 s
at -38 dB) ends within +-0.45 s of the aligned paragraph start.
Usage: python3 -I scripts/align_check.py [src/timing/alignment.json]
"""
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
path = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "src/timing/alignment.json"
al = json.loads(path.read_text(encoding="utf-8"))
log = subprocess.run(
    ["ffmpeg", "-hide_banner", "-nostats", "-i", str(ROOT / "public/audio/narration.mp3"), "-af", "silencedetect=noise=-38dB:d=0.3", "-f", "null", "-"],
    capture_output=True, text=True,
).stderr
ends = [float(m) for m in re.findall(r"silence_end: ([\d.]+)", log)]
ok, bad = 0, []
spoken = [p for p in al["paragraphs"] if not p.get("omitted")]
for p in spoken[1:]:
    near = min(ends, key=lambda e: abs(e - p["start"]))
    if abs(near - p["start"]) <= 0.45:
        ok += 1
    else:
        bad.append((p["line"], round(p["start"], 2), round(near, 2), p["conf"]))
n = len(spoken) - 1
print(f"{path.name}: {ok}/{n} spoken-paragraph starts within 0.45 s of a pause end ({100 * ok / n:.0f}%)")
print("worst:", sorted(bad, key=lambda b: -abs(b[1] - b[2]))[:15])
