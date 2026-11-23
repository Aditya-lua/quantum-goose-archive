import React, { useMemo } from "react";
import { AbsoluteFill, Img, random, staticFile } from "remotion";
import type { Grade as GradeName } from "../style/palette";

/** Falling rain streaks as one path (cheap). Screen or world space depending on parent. */
export const Rain: React.FC<{
  frame: number;
  seed?: string;
  count?: number;
  x?: number;
  y?: number;
  w?: number;
  h?: number;
  speed?: number;
  len?: number;
  slant?: number;
  color?: string;
  opacity?: number;
  width?: number;
}> = ({ frame, seed = "rain", count = 180, x = 0, y = 0, w = 1920, h = 1080, speed = 46, len = 55, slant = 0.12, color = "#a9b8d8", opacity = 0.28, width = 1.4 }) => {
  const drops = useMemo(
    () =>
      new Array(count).fill(0).map((_, i) => ({
        x: random(`${seed}x${i}`) * (w + h * slant),
        y0: random(`${seed}y${i}`),
        v: 0.75 + random(`${seed}v${i}`) * 0.5,
        l: 0.6 + random(`${seed}l${i}`) * 0.8,
      })),
    [count, seed, w, h, slant],
  );
  let d = "";
  for (const dr of drops) {
    const span = h + len * 2;
    const py = ((dr.y0 * span + frame * speed * dr.v) % span) - len;
    const px = dr.x - py * slant;
    const L = len * dr.l;
    d += `M ${(x + px).toFixed(1)} ${(y + py).toFixed(1)} l ${(-L * slant).toFixed(1)} ${L.toFixed(1)} `;
  }
  return <path d={d} stroke={color} strokeWidth={width} opacity={opacity} strokeLinecap="round" fill="none" />;
};

/** Drops sliding down a window pane (world space). */
export const GlassRain: React.FC<{ frame: number; x: number; y: number; w: number; h: number; seed?: string; count?: number }> = ({
  frame,
  x,
  y,
  w,
  h,
  seed = "glass",
  count = 26,
}) => {
  const drops = useMemo(
    () =>
      new Array(count).fill(0).map((_, i) => ({
        x: random(`${seed}gx${i}`) * w,
        y0: random(`${seed}gy${i}`),
        v: 0.6 + random(`${seed}gv${i}`) * 2.4,
        r: 1.5 + random(`${seed}gr${i}`) * 2.5,
      })),
    [count, seed, w],
  );
  return (
    <g>
      {drops.map((dr, i) => {
        const span = h + 40;
        const py = ((dr.y0 * span + frame * dr.v) % span) - 20;
        return (
          <g key={i}>
            <path d={`M ${x + dr.x} ${y + Math.max(0, py - 40 * dr.v)} L ${x + dr.x} ${y + py}`} stroke="#c9d6ee" strokeWidth={dr.r * 0.6} opacity={0.18} />
            <circle cx={x + dr.x} cy={y + py} r={dr.r} fill="#dfe8f8" opacity={0.42} />
          </g>
        );
      })}
    </g>
  );
};

const GRADE_STYLE: Record<GradeName, { tint: string; tintOp: number; vignette: number; warm?: number }> = {
  present: { tint: "#3c4f86", tintOp: 0.22, vignette: 0.55 },
  flood: { tint: "#22325e", tintOp: 0.38, vignette: 0.7 },
  memoryWarm: { tint: "#f0b65d", tintOp: 0.16, vignette: 0.35, warm: 0.22 },
  hospital: { tint: "#71806f", tintOp: 0.3, vignette: 0.5 },
  ending: { tint: "#f0b65d", tintOp: 0.12, vignette: 0.4, warm: 0.12 },
  day: { tint: "#9aa6c4", tintOp: 0.1, vignette: 0.35 },
};

/** Colour grade + vignette + paper grain, applied over a finished shot. */
export const Grade: React.FC<{ grade: GradeName; memoryEdge?: number }> = ({ grade, memoryEdge = 0 }) => {
  const g = GRADE_STYLE[grade];
  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      <AbsoluteFill style={{ backgroundColor: g.tint, opacity: g.tintOp, mixBlendMode: "multiply" }} />
      {g.warm ? (
        <AbsoluteFill style={{ backgroundColor: "#ffcf86", opacity: g.warm, mixBlendMode: "soft-light" }} />
      ) : null}
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse at 50% 48%, rgba(0,0,0,0) 52%, rgba(4,6,14,${g.vignette}) 100%)`,
        }}
      />
      <Img src={staticFile("textures/paper.png")} style={{ position: "absolute", width: "100%", height: "100%", mixBlendMode: "multiply", opacity: 0.55 }} />
      {memoryEdge > 0 ? (
        <Img src={staticFile("textures/memory-edge.png")} style={{ position: "absolute", width: "100%", height: "100%", opacity: memoryEdge }} />
      ) : null}
    </AbsoluteFill>
  );
};

/** CSS filter applied to the picture for each grade (memories softer and warmer). */
export const gradeFilter = (grade: GradeName): string | undefined => {
  switch (grade) {
    case "memoryWarm":
      return "sepia(0.18) saturate(0.9) contrast(0.94) brightness(1.04)";
    case "hospital":
      return "saturate(0.45) contrast(0.9)";
    case "flood":
      return "saturate(0.75) contrast(1.05)";
    case "ending":
      return "saturate(1.02)";
    default:
      return "saturate(0.88)";
  }
};

/** Soft radial light in world space (lamp, window spill). */
export const Glow: React.FC<{ id: string; cx: number; cy: number; r: number; color: string; opacity: number }> = ({ id, cx, cy, r, color, opacity }) => (
  <g>
    <defs>
      <radialGradient id={id}>
        <stop offset="0%" stopColor={color} stopOpacity={opacity} />
        <stop offset="45%" stopColor={color} stopOpacity={opacity * 0.4} />
        <stop offset="100%" stopColor={color} stopOpacity={0} />
      </radialGradient>
    </defs>
    <circle cx={cx} cy={cy} r={r} fill={`url(#${id})`} />
  </g>
);
