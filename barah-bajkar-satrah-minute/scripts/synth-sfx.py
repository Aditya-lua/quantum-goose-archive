"""Synthesise the film's few sound effects deterministically (numpy only).

The narration export contains no ambience or effects (checked: docs/SOUND.md),
so these are added sparsely, at their exact story moments (src/audio/sfx.ts).
Outputs 48 kHz mono 16-bit WAVs in public/audio/sfx/.
"""
import wave
from pathlib import Path

import numpy as np

SR = 48000
OUT = Path(__file__).resolve().parent.parent / "public" / "audio" / "sfx"
OUT.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(1217)


def write(name: str, x: np.ndarray, peak: float = 0.9) -> None:
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    print(f"{name}: {len(x) / SR:.2f} s")


def onepole_lp(x: np.ndarray, fc: float) -> np.ndarray:
    a = np.exp(-2 * np.pi * fc / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def hp(x: np.ndarray, fc: float) -> np.ndarray:
    return x - onepole_lp(x, fc)


def env(n: int, attack: float, decay: float) -> np.ndarray:
    t = np.arange(n) / SR
    return np.minimum(1, t / max(attack, 1e-4)) * np.exp(-t / decay)


# Rain bed: 24 s, seamless loop (end crossfaded into start).
n = SR * 24
noise = rng.normal(0, 1, n + SR)
bed = hp(onepole_lp(noise, 5000), 400) * 0.6 + onepole_lp(noise, 900) * 0.25
drops = np.zeros(n + SR)
for _ in range(2600):
    p = rng.integers(0, n + SR - 2000)
    L = int(SR * (0.004 + rng.random() * 0.01))
    drops[p : p + L] += rng.normal(0, 1, L) * env(L, 0.0005, 0.003) * (0.3 + rng.random())
rain = bed + hp(drops, 1500) * 0.5
fade = np.linspace(0, 1, SR)
rain[:SR] = rain[:SR] * fade + rain[n : n + SR] * (1 - fade)
write("rain_bed.wav", rain[:n], 0.7)

# Tape-recorder key press: plastic click + low mechanical thunk.
L = int(SR * 0.18)
click = hp(rng.normal(0, 1, L), 2500) * env(L, 0.0003, 0.006)
thunk = np.sin(2 * np.pi * 140 * np.arange(L) / SR) * env(L, 0.001, 0.03) * 0.6
latch = np.zeros(L)
o = int(SR * 0.035)
latch[o:] = hp(rng.normal(0, 1, L - o), 3000) * env(L - o, 0.0002, 0.004) * 0.6
write("tape_key.wav", click + thunk + latch, 0.8)

# Key release (stop): sharper, shorter.
L = int(SR * 0.12)
rel = hp(rng.normal(0, 1, L), 3500) * env(L, 0.0002, 0.004) + np.sin(2 * np.pi * 220 * np.arange(L) / SR) * env(L, 0.0005, 0.015) * 0.4
write("tape_stop.wav", rel, 0.75)

# Siren switch lever: heavy metal clunk.
L = int(SR * 0.6)
t = np.arange(L) / SR
clunk = (np.sin(2 * np.pi * 70 * t) * env(L, 0.001, 0.08) + np.sin(2 * np.pi * 410 * t) * env(L, 0.0005, 0.04) * 0.5 + hp(rng.normal(0, 1, L), 1200) * env(L, 0.0003, 0.012) * 0.8)
write("switch_clunk.wav", clunk, 0.85)

# Quartz clock tick: one soft tick at the start of a 1 s loop.
L = SR
tick = np.zeros(L)
T = int(SR * 0.02)
tick[:T] = hp(rng.normal(0, 1, T), 4000) * env(T, 0.0002, 0.002) + np.sin(2 * np.pi * 2600 * np.arange(T) / SR) * env(T, 0.0002, 0.003) * 0.5
write("clock_tick_loop.wav", tick, 0.6)
