"""Per-frame (24 fps) RMS envelope of the narration, normalised 0..100.

Written once to src/timing/envelope.json so scene components never decode audio.
Used only to open mouths during aligned direct speech, and for waveform displays.
"""
import json
import subprocess
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent.parent
SR = 4800
FPS = 24
raw = subprocess.check_output(
    ["ffmpeg", "-v", "error", "-i", str(ROOT / "public/audio/narration.mp3"), "-ac", "1", "-ar", str(SR), "-f", "s16le", "-"]
)
x = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
hop = SR // FPS
n = len(x) // hop
rms = np.sqrt(np.mean(x[: n * hop].reshape(n, hop) ** 2, axis=1))
ref = np.percentile(rms, 98)
env = np.clip(rms / ref, 0, 1)
out = ROOT / "src/timing/envelope.json"
out.write_text(json.dumps([int(round(v * 100)) for v in env]))
print(f"wrote {out.relative_to(ROOT)}: {n} frames ({n / FPS:.2f} s)")
