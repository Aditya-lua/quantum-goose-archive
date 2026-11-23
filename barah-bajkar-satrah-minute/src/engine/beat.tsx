import React, { createContext, useContext } from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { gradeFilter, Grade as GradeOverlay } from "../fx/fx";
import type { Grade } from "../style/palette";
import { FPS, fn, nf } from "../timing/time";
import { easeInOut, kf } from "./anim";
import { Cam, Stage } from "./Stage";

export type BeatWindow = { from: number; to: number; start: number; end: number };
export const BeatCtx = createContext<BeatWindow>({ from: 0, to: 1, start: 0, end: 0 });

/**
 * Timing inside a beat. f = absolute film frame, t = narration seconds,
 * lt = seconds since beat start, dur = beat length (s).
 * `T(sec)` converts an absolute narration time to beat-local seconds, so actions
 * can be pinned to aligned words: T(at(49, "आठ मिनट")).
 */
export const useBeat = () => {
  const rel = useCurrentFrame();
  const w = useContext(BeatCtx);
  const f = w.from + rel;
  return {
    f,
    t: fn(f),
    lt: rel / FPS,
    dur: (w.to - w.from) / FPS,
    T: (narrationSec: number) => (nf(narrationSec) - w.from) / FPS,
  };
};

export type CamKey = readonly [number, Cam];

/** Keyframed camera; times in beat-local seconds. */
export const camAt = (lt: number, keys: readonly CamKey[], easing = easeInOut): Cam => {
  if (keys.length === 1) return keys[0][1];
  const ts = keys.map((k) => k[0]);
  const comp = (sel: (c: Cam) => number) => kf(lt, ts.map((t, i) => [t, sel(keys[i][1])] as const), easing);
  return { x: comp((c) => c.x), y: comp((c) => c.y), z: comp((c) => c.z), rot: comp((c) => c.rot ?? 0) };
};

/** A graded shot: SVG world through a camera, then grade/paper overlays. */
export const Shot: React.FC<{
  cam: Cam;
  grade: Grade;
  bg?: string;
  memoryEdge?: number;
  children: React.ReactNode;
  overlay?: React.ReactNode; // HTML layer above the picture but below the grade (e.g. text on screen)
  opacity?: number;
}> = ({ cam, grade, bg = "#000", memoryEdge = 0, children, overlay, opacity = 1 }) => (
  <AbsoluteFill style={{ opacity }}>
    <AbsoluteFill style={{ filter: gradeFilter(grade) }}>
      <Stage cam={cam} bg={bg}>
        {children}
      </Stage>
      {overlay}
    </AbsoluteFill>
    <GradeOverlay grade={grade} memoryEdge={memoryEdge} />
  </AbsoluteFill>
);

/** Split a beat into internal shots: returns the index of the active cut for lt. */
export const cutIndex = (lt: number, cuts: readonly number[]): number => {
  let i = 0;
  for (let k = 0; k < cuts.length; k++) if (lt >= cuts[k]) i = k + 1;
  return i;
};
