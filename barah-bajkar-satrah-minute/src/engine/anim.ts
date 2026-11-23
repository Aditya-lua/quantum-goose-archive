import { Easing, interpolate, random } from "remotion";

export const easeInOut = Easing.bezier(0.45, 0, 0.25, 1);
export const easeOut = Easing.bezier(0.16, 1, 0.3, 1);
export const easeIn = Easing.bezier(0.5, 0, 0.75, 0);

export type Key = readonly [number, number];

/** Key times forced strictly increasing (anchor-derived times can coincide or cross). */
export const monotonic = (ts: readonly number[]): number[] => {
  const out: number[] = [];
  for (const t of ts) out.push(out.length ? Math.max(t, out[out.length - 1] + 1e-3) : t);
  return out;
};

/** Piecewise keyframe interpolation with easing on every segment. Clamped at both ends. */
export const kf = (t: number, keys: readonly Key[], easing = easeInOut): number => {
  if (keys.length === 1) return keys[0][1];
  return interpolate(
    t,
    monotonic(keys.map((k) => k[0])),
    keys.map((k) => k[1]),
    { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing },
  );
};

/** 0 -> 1 ramp between t0 and t1 (seconds or frames, caller's choice). */
export const ramp = (t: number, t0: number, t1: number, easing = easeInOut): number =>
  interpolate(t, [t0, Math.max(t1, t0 + 1e-3)], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing,
  });

export const mix = (a: number, b: number, t: number): number => a + (b - a) * t;

/** Smooth deterministic wander in -1..1 from layered sines with seeded phases. */
export const wander = (t: number, seed: string | number, speed = 1): number => {
  const p1 = random(`${seed}-a`) * Math.PI * 2;
  const p2 = random(`${seed}-b`) * Math.PI * 2;
  const p3 = random(`${seed}-c`) * Math.PI * 2;
  return (
    Math.sin(t * 0.61 * speed + p1) * 0.5 +
    Math.sin(t * 1.37 * speed + p2) * 0.32 +
    Math.sin(t * 2.71 * speed + p3) * 0.18
  );
};

/**
 * Eyelid closure 0..1 for natural blinking: one blink every ~2.8-5.5 s,
 * deterministic per seed. `t` in seconds.
 */
export const blink = (t: number, seed: string): number => {
  const period = 2.8 + random(`${seed}-period`) * 2.7;
  const offset = random(`${seed}-offset`) * period;
  const local = (t + offset) % period;
  const d = 0.16; // blink duration
  if (local > d) return 0;
  const x = local / d;
  return x < 0.4 ? x / 0.4 : 1 - (x - 0.4) / 0.6;
};

/** Breathing phase in -1..1 (~0.25 Hz). */
export const breath = (t: number, seed: string, rate = 0.25): number =>
  Math.sin(t * Math.PI * 2 * rate + random(`${seed}-br`) * 6.28);
