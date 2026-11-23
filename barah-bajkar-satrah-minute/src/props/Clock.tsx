import React from "react";
import { FPS } from "../timing/time";
import { INK } from "../rigs/Head";

// 12:17 — minute hand 17 * 6 = 102 deg, hour hand 17 * 0.5 = 8.5 deg (clockwise from 12).
export const STOPPED_MINUTE_DEG = 102;
export const STOPPED_HOUR_DEG = 8.5;
/** Second hand rests at "37 seconds" so it never hides behind the hour or minute hand. */
export const STOPPED_SECOND_DEG = 222;

/**
 * Hand angles for an absolute film frame. `startFrame` is the battery moment
 * (null = the clock never runs in this shot). Before it, every angle is fixed.
 */
export const clockAngles = (frame: number, startFrame: number | null) => {
  if (startFrame === null || frame < startFrame) {
    return { h: STOPPED_HOUR_DEG, m: STOPPED_MINUTE_DEG, s: STOPPED_SECOND_DEG };
  }
  const t = (frame - startFrame) / FPS;
  const tremble = 0.45; // "सेकंड की सुई हल्की सी काँपी" — a short shiver, then it moves on
  if (t < tremble) {
    const shiver = Math.sin(t * 70) * 1.6 * (1 - t / tremble);
    return { h: STOPPED_HOUR_DEG, m: STOPPED_MINUTE_DEG, s: STOPPED_SECOND_DEG + shiver };
  }
  const run = t - tremble;
  const whole = Math.floor(run) + 1;
  const frac = run - Math.floor(run);
  const snap = Math.min(1, frac / 0.08); // quartz tick: quick step, then rest
  const ticks = whole - 1 + snap;
  const secs = ticks;
  return {
    h: STOPPED_HOUR_DEG + (secs / 3600) * 30,
    m: STOPPED_MINUTE_DEG + (secs / 60) * 6,
    s: STOPPED_SECOND_DEG + ticks * 6,
  };
};

const hand = (deg: number, len: number, back: number, w: number, color: string) => (
  <g transform={`rotate(${deg})`}>
    <path d={`M ${-w / 2} ${back} L ${-w * 0.3} ${-len} L 0 ${-len - w} L ${w * 0.3} ${-len} L ${w / 2} ${back} Z`} fill={color} stroke={INK} strokeWidth={1} vectorEffect="non-scaling-stroke" />
  </g>
);

/** Wall clock, centred at origin, radius r. */
export const Clock: React.FC<{ r: number; frame: number; startFrame: number | null; dusty?: boolean }> = ({ r, frame, startFrame, dusty }) => {
  const a = clockAngles(frame, startFrame);
  return (
    <g>
      <circle r={r * 1.13} fill="#4a3324" stroke={INK} strokeWidth={2} vectorEffect="non-scaling-stroke" />
      <circle r={r * 1.13} fill="none" stroke="#6b4a33" strokeWidth={r * 0.06} opacity={0.8} />
      <circle r={r} fill="#e8dcc1" stroke={INK} strokeWidth={1.6} vectorEffect="non-scaling-stroke" />
      <circle r={r * 0.97} fill="none" stroke="#cbb994" strokeWidth={r * 0.04} />
      {new Array(60).fill(0).map((_, i) => {
        const big = i % 5 === 0;
        return (
          <line
            key={i}
            x1={0}
            y1={-r * 0.9}
            x2={0}
            y2={-r * (big ? 0.78 : 0.85)}
            stroke={INK}
            strokeWidth={big ? r * 0.03 : r * 0.012}
            transform={`rotate(${i * 6})`}
          />
        );
      })}
      {[12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map((n, i) => {
        const ang = (i * 30 * Math.PI) / 180;
        return (
          <text key={n} x={Math.sin(ang) * r * 0.64} y={-Math.cos(ang) * r * 0.64 + r * 0.075} fontSize={r * 0.2} textAnchor="middle" fill={INK} fontFamily="NotoDevaLatin, serif">
            {n}
          </text>
        );
      })}
      {hand(a.h, r * 0.48, r * 0.1, r * 0.075, "#1c1a18")}
      {hand(a.m, r * 0.74, r * 0.12, r * 0.055, "#1c1a18")}
      <g transform={`rotate(${a.s})`}>
        <line x1={0} y1={r * 0.18} x2={0} y2={-r * 0.82} stroke="#9a2a22" strokeWidth={r * 0.018} />
        <circle r={r * 0.045} fill="#9a2a22" />
      </g>
      <circle r={r * 0.03} fill="#d8c79c" />
      {/* glass highlight */}
      <path d={`M ${-r * 0.7} ${-r * 0.35} A ${r * 0.8} ${r * 0.8} 0 0 1 ${-r * 0.2} ${-r * 0.82}`} stroke="#ffffff" strokeWidth={r * 0.05} opacity={0.18} fill="none" />
      {dusty ? <circle r={r} fill="#9b8f7a" opacity={0.18} /> : null}
    </g>
  );
};

/** Back of the clock with battery slot and pencilled date (S22). */
export const ClockBack: React.FC<{ r: number; battery: number }> = ({ r, battery }) => (
  <g>
    <circle r={r * 1.13} fill="#5a4030" stroke={INK} strokeWidth={2} vectorEffect="non-scaling-stroke" />
    <circle r={r * 0.95} fill="#3b2a1f" />
    <circle r={r * 0.95} fill="#8a7a62" opacity={0.35} />
    <rect x={-r * 0.38} y={-r * 0.3} width={r * 0.76} height={r * 0.6} rx={r * 0.05} fill="#2a2724" stroke={INK} strokeWidth={1.5} vectorEffect="non-scaling-stroke" />
    <rect x={-r * 0.32} y={-r * 0.12} width={r * 0.64} height={r * 0.24} rx={r * 0.03} fill="#1a1918" />
    {/* battery slides in from the right as battery 0 -> 1 */}
    <g transform={`translate(${(1 - battery) * r * 0.9} 0)`} opacity={battery > 0 ? 1 : 0}>
      <rect x={-r * 0.3} y={-r * 0.1} width={r * 0.56} height={r * 0.2} rx={r * 0.03} fill="#c9a33a" stroke={INK} strokeWidth={1.2} vectorEffect="non-scaling-stroke" />
      <rect x={-r * 0.3} y={-r * 0.1} width={r * 0.2} height={r * 0.2} fill="#2b2b2b" />
      <rect x={r * 0.26} y={-r * 0.04} width={r * 0.04} height={r * 0.08} fill="#c8c8c8" />
    </g>
    {/* pencilled date (the manuscript gives no digits, so it stays an illegible scribble) */}
    <path
      d={`M ${-r * 0.36} ${r * 0.55} c ${r * 0.04} ${-r * 0.08} ${r * 0.08} ${r * 0.06} ${r * 0.1} 0 m ${r * 0.05} ${r * 0.02} l ${r * 0.03} ${-r * 0.06} m ${r * 0.06} ${r * 0.08} c ${r * 0.05} ${-r * 0.1} ${r * 0.1} ${r * 0.04} ${r * 0.08} ${r * 0.02} m ${r * 0.06} ${-r * 0.03} l ${r * 0.03} ${-r * 0.05} m ${r * 0.05} ${r * 0.07} c ${r * 0.04} ${-r * 0.06} ${r * 0.1} ${-r * 0.04} ${r * 0.12} ${r * 0.01} c ${r * 0.02} ${-r * 0.05} ${r * 0.05} ${-r * 0.03} ${r * 0.07} 0`}
      stroke="#4a4640"
      strokeWidth={r * 0.018}
      fill="none"
      opacity={0.85}
      transform="rotate(-4)"
    />
    {[[-0.6, -0.6], [0.55, -0.5], [-0.5, 0.65], [0.6, 0.6]].map(([x, y], i) => (
      <circle key={i} cx={x * r} cy={y * r} r={r * 0.06} fill="#2a1d15" stroke={INK} strokeWidth={1} vectorEffect="non-scaling-stroke" />
    ))}
  </g>
);
