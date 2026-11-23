"""Timing pass 3: transcribe each pause-delimited speech clip separately.

Long-form decoding (both whisper.cpp and faster-whisper) skipped whole stretches of
this narration and smeared the neighbouring timestamps. Clips of up to ~25 s
cut at detected pauses avoid that, and each clip's absolute start is known
exactly from the silence detection. Output shape matches scripts/align.py.

Run: work/.venv/bin/python -I scripts/transcribe_fw_clips.py [model]
"""
import json
import re
import subprocess
import sys
import time
import wave
from pathlib import Path

import numpy as np
from faster_whisper import WhisperModel

ROOT = Path(__file__).resolve().parent.parent
model_name = sys.argv[1] if len(sys.argv) > 1 else "large-v3-turbo"
out = ROOT / "work" / f"transcript.fwclips-{model_name}.json"
wav = ROOT / "work" / "narration16k.wav"

with wave.open(str(wav), "rb") as wf:
    audio = np.frombuffer(wf.readframes(wf.getnframes()), dtype=np.int16).astype(np.float32) / 32768.0
dur = len(audio) / 16000

log = subprocess.run(
    ["ffmpeg", "-hide_banner", "-nostats", "-i", str(wav), "-af", "silencedetect=noise=-38dB:d=0.28", "-f", "null", "-"],
    capture_output=True, text=True,
).stderr
starts = [float(x) for x in re.findall(r"silence_start: ([\d.]+)", log)]
ends = [float(x) for x in re.findall(r"silence_end: ([\d.]+)", log)]
# speech regions between silences
regions, cur = [], 0.0
for s, e in zip(starts, ends):
    if s - cur > 0.05:
        regions.append([cur, s])
    cur = e
if dur - cur > 0.05:
    regions.append([cur, dur])
# merge consecutive regions into clips of at most ~25 s (one 30 s whisper window each),
# cutting only at pauses
clips = []
for r in regions:
    if clips and r[1] - clips[-1][0] <= 25:
        clips[-1][1] = r[1]
    else:
        clips.append(list(r))
print(f"{len(regions)} speech regions -> {len(clips)} clips")

model = WhisperModel(model_name, device="cpu", compute_type="int8", cpu_threads=4)
t0 = time.time()
words = []
for i, (a, b) in enumerate(clips):
    pa, pb = max(0.0, a - 0.12), min(dur, b + 0.12)
    seg_audio = audio[int(pa * 16000) : int(pb * 16000)]
    segments, _ = model.transcribe(seg_audio, language="hi", word_timestamps=True, vad_filter=False, condition_on_previous_text=False, beam_size=5)
    for seg in segments:
        for w in seg.words or []:
            words.append({"text": w.word, "offsets": {"from": int((pa + w.start) * 1000), "to": int((pa + w.end) * 1000)}, "p": w.probability, "clip": i, "tokens": []})
    print(f"\rclip {i + 1}/{len(clips)} at {b:7.1f}s", end="", flush=True)
out.write_text(json.dumps({"engine": f"faster-whisper {model_name}, per-pause clips", "clips": clips, "transcription": words}, ensure_ascii=False))
print(f"\nwrote {out} ({len(words)} words) in {(time.time() - t0) / 60:.1f} min")
