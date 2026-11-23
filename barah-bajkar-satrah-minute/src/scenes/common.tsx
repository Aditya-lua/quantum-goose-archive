import React from "react";
import { AbsoluteFill, interpolate } from "remotion";
import { At } from "../engine/Stage";
import { blink, breath, monotonic, wander } from "../engine/anim";
import { computeJoints, Person, reach, toLocal } from "../rigs/Person";
import type { ArmPose, CharSpec, HandShape, Pose } from "../rigs/types";
import { FONT_BODY, FONT_TITLE } from "../style/fonts";
import { STUDY } from "../sets/Study";
import { at, endOf, env, FPS, para } from "../timing/time";

export type Place = { x: number; y: number; s: number; flip?: boolean };

/** Living layer: blink + breath + subtle head wander for any pose, from time t (s). */
export const alive = (t: number, seed: string, p: Pose, amount = 1): Pose => ({
  ...p,
  blink: Math.max(p.blink ?? 0, blink(t, seed)),
  breath: breath(t, seed),
  headTilt: (p.headTilt ?? 0) + wander(t * 0.6, `${seed}tilt`) * 1.6 * amount,
  headTurn: (p.headTurn ?? 0) + wander(t * 0.4, `${seed}turn`) * 0.05 * amount,
});

/** Arm pose reaching a world-space point for a placed character. */
export const reachW = (spec: CharSpec, pose: Pose, side: "near" | "far", world: { x: number; y: number }, place: Place, hand: HandShape = "relaxed", wr = 0): ArmPose =>
  reach(spec, pose, side, toLocal(world, place), hand, wr);

export const Actor: React.FC<{
  spec: CharSpec;
  place: Place;
  pose: Pose;
  nearHold?: React.ReactNode;
  farHold?: React.ReactNode;
  silhouette?: string;
  opacity?: number;
  headphones?: "on" | "neck";
}> = ({ spec, place, pose, nearHold, farHold, silhouette, opacity, headphones }) => (
  <At x={place.x} y={place.y} s={place.s} flip={place.flip} opacity={opacity}>
    <Person spec={spec} pose={pose} nearHold={nearHold} farHold={farHold} silhouette={silhouette} headphones={headphones} />
  </At>
);

/** Standard placements reused across scenes (fixed geography). */
export const PLACES = {
  meeraAtDesk: { x: STUDY.chairX, y: STUDY.floorY, s: 0.95 } as Place,
  recorderAtDesk: { x: 1040, y: STUDY.deskTop, w: 135 },
};

/** Play-key world position on the study recorder (see Recorder key layout). */
export const recorderKey = (i: number, rec = PLACES.recorderAtDesk) => {
  const h = rec.w * 0.55;
  return { x: rec.x - rec.w * 0.02 + i * rec.w * 0.078 + rec.w * 0.034, y: rec.y - h + h * 0.06 };
};

/** Speech mouth opening inside a direct-speech span [t0, t1] (narration seconds),
 * driven by the narration loudness envelope so lips follow the actual syllables. */
export const talkAt = (t: number, t0: number, t1: number): number => {
  if (t < t0 || t > t1) return 0;
  return Math.min(1, Math.max(0, env(t) - 0.08) * 1.5);
};

/** Mouth for the direct speech of manuscript line `line` (optionally the quoted phrase span). */
export const speaks = (t: number, line: number, from?: string, to?: string): number =>
  talkAt(t, from ? at(line, from) : para(line).start, to ? endOf(line, to) : para(line).end);

export const TitleCard: React.FC<{ lt: number; dur: number }> = ({ lt, dur }) => {
  const o = interpolate(lt, monotonic([0.15, 0.9, dur - 0.6, dur]), [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const y = interpolate(lt, [0, dur], [10, -6]);
  return (
    <AbsoluteFill style={{ justifyContent: "center", alignItems: "center", opacity: o }}>
      <div
        style={{
          fontFamily: FONT_TITLE,
          fontSize: 132,
          color: "#f1e4c6",
          textShadow: "0 4px 24px rgba(0,0,0,0.75), 0 0 2px rgba(0,0,0,0.8)",
          translate: `0px ${y - 120}px`,
          letterSpacing: 1,
        }}
      >
        बारह बजकर सत्रह मिनट
      </div>
    </AbsoluteFill>
  );
};

/** On-screen Hindi text that is part of the picture (labels, notes), not captions. */
export const ScreenText: React.FC<{ text: string; x: number; y: number; size: number; color?: string; opacity?: number }> = ({ text, x, y, size, color = "#f1e4c6", opacity = 1 }) => (
  <div style={{ position: "absolute", left: x, top: y, fontFamily: FONT_BODY, fontSize: size, color, opacity }}>{text}</div>
);

export const secs = (frames: number) => frames / FPS;

/** World position of a rig joint (shoulder) for a placed, posed character. */
export const shoulderWorld = (spec: CharSpec, pose: Pose, place: Place, side: "near" | "far" = "near") => {
  const j = computeJoints(spec, pose);
  const p = side === "near" ? j.nearSh : j.farSh;
  const lean = ((pose.lean ?? 0) * Math.PI) / 180;
  const pivotY = j.hipY + j.upperDy;
  const y0 = p.y + j.upperDy;
  const rx = p.x * Math.cos(lean) - (y0 - pivotY) * Math.sin(lean);
  const ry = pivotY + p.x * Math.sin(lean) + (y0 - pivotY) * Math.cos(lean);
  return { x: place.x + rx * place.s * (place.flip ? -1 : 1), y: place.y + ry * place.s };
};
