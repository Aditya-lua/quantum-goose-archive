import React from "react";
import { INK } from "../rigs/Head";
import { C } from "../style/palette";

const ol = (w = 1.6) => ({ stroke: INK, strokeWidth: w, vectorEffect: "non-scaling-stroke" as const });
export const HAND_FONT = "TiroDeva, serif";
const PEN = "#26335e";

/** Handwritten Hindi line (Tiro Devanagari, ink blue, slight tilt). */
export const Handwriting: React.FC<{ x: number; y: number; size: number; text: string; color?: string; rot?: number; anchor?: "start" | "middle"; opacity?: number }> = ({
  x,
  y,
  size,
  text,
  color = PEN,
  rot = -2,
  anchor = "start",
  opacity = 0.92,
}) => (
  <text x={x} y={y} fontSize={size} fill={color} fontFamily={HAND_FONT} textAnchor={anchor} transform={`rotate(${rot} ${x} ${y})`} opacity={opacity}>
    {text}
  </text>
);

/** Illegible written line (for documents whose wording the story does not give). */
export const Scribble: React.FC<{ x: number; y: number; w: number; h: number; seed: number; color?: string; width?: number }> = ({ x, y, w, h, seed, color = PEN, width = 1.4 }) => {
  let d = `M ${x} ${y}`;
  let cx = x;
  let i = 0;
  while (cx < x + w) {
    const s = Math.sin(seed * 12.9898 + i * 78.233) * 43758.5453;
    const r = s - Math.floor(s);
    const step = h * (0.35 + r * 0.6);
    d += ` q ${step / 2} ${(r - 0.5) * h * 1.6} ${step} 0`;
    if (r > 0.82) d += ` m ${h * 0.6} 0`;
    cx += step + (r > 0.82 ? h * 0.6 : 0);
    i++;
  }
  return <path d={d} stroke={color} strokeWidth={width} fill="none" vectorEffect="non-scaling-stroke" opacity={0.85} />;
};

const Reel: React.FC<{ cx: number; cy: number; r: number; angle: number; tape: number }> = ({ cx, cy, r, angle, tape }) => (
  <g transform={`translate(${cx} ${cy})`}>
    <circle r={r * (0.55 + tape * 0.9)} fill="#3a2a22" opacity={0.95} />
    <circle r={r * 0.52} fill="#efe8da" {...ol(1)} />
    <g transform={`rotate(${angle})`}>
      {[0, 60, 120, 180, 240, 300].map((a) => (
        <rect key={a} x={-r * 0.06} y={-r * 0.5} width={r * 0.12} height={r * 0.2} fill="#2a2a2a" transform={`rotate(${a})`} />
      ))}
      <circle r={r * 0.22} fill="#2a2a2a" />
    </g>
  </g>
);

/** Cassette shell, centred at origin, width w. `angle` spins the hubs. */
export const Cassette: React.FC<{ w: number; label?: string; angle?: number; shell?: string; labelColor?: string; handColor?: string; tapeLeft?: number }> = ({
  w,
  label = "",
  angle = 0,
  shell = "#5b4636",
  labelColor = "#efe7d3",
  handColor = PEN,
  tapeLeft = 0.55,
}) => {
  const h = w * 0.64;
  return (
    <g>
      <rect x={-w / 2} y={-h / 2} width={w} height={h} rx={w * 0.04} fill={shell} {...ol(2)} />
      <rect x={-w * 0.44} y={-h * 0.42} width={w * 0.88} height={h * 0.58} rx={w * 0.02} fill={labelColor} {...ol(1)} />
      <rect x={-w * 0.44} y={-h * 0.42} width={w * 0.88} height={h * 0.08} fill="#b9472f" opacity={0.75} />
      <rect x={-w * 0.3} y={-h * 0.12} width={w * 0.6} height={h * 0.24} rx={h * 0.1} fill="#1d1a18" {...ol(1)} />
      <Reel cx={-w * 0.17} cy={0} r={h * 0.11} angle={angle} tape={tapeLeft} />
      <Reel cx={w * 0.17} cy={0} r={h * 0.11} angle={angle} tape={1 - tapeLeft} />
      <path d={`M ${-w * 0.32} ${h * 0.5} L ${-w * 0.26} ${h * 0.28} L ${w * 0.26} ${h * 0.28} L ${w * 0.32} ${h * 0.5}`} fill="#4a382c" {...ol(1)} />
      {label ? <Handwriting x={0} y={-h * 0.2} size={h * 0.13} text={label} anchor="middle" rot={-1.5} color={handColor} /> : null}
      {[[-0.45, -0.42], [0.45, -0.42], [-0.45, 0.42], [0.45, 0.42]].map(([x, y], i) => (
        <circle key={i} cx={x * w} cy={y * h} r={w * 0.012} fill="#2a2a2a" />
      ))}
    </g>
  );
};

/** Old black portable cassette recorder. Origin = bottom centre. Reels spin only when playing. */
export const Recorder: React.FC<{ w: number; frame: number; playing: boolean; playFrom?: number; pressed?: "play" | "stop" | "rew" | null; cassetteIn?: boolean; label?: string; silver?: boolean; angle?: number; cassetteLift?: number }> = ({
  w,
  frame,
  playing,
  playFrom = 0,
  pressed = null,
  cassetteIn = true,
  label = "",
  silver = false,
  angle: angleOverride,
  cassetteLift = 0,
}) => {
  const h = w * 0.55;
  const body = silver ? "#a7a9ab" : "#232326";
  const body2 = silver ? "#8c8e91" : "#18181a";
  const angle = angleOverride ?? (playing ? (frame - playFrom) * 9 : 0);
  const keys = ["rec", "play", "rew", "ff", "stop", "pause"];
  return (
    <g transform={`translate(0 ${-h})`}>
      <path d={`M ${-w * 0.36} ${h * 0.02} L ${-w * 0.3} ${-h * 0.14} L ${w * 0.3} ${-h * 0.14} L ${w * 0.36} ${h * 0.02}`} fill="none" stroke={body} strokeWidth={w * 0.025} />
      <rect x={-w / 2} y={0} width={w} height={h} rx={w * 0.04} fill={body} {...ol(2)} />
      <rect x={-w / 2} y={h * 0.82} width={w} height={h * 0.18} rx={w * 0.03} fill={body2} />
      {/* speaker grille */}
      <circle cx={-w * 0.26} cy={h * 0.55} r={h * 0.3} fill={body2} {...ol(1)} />
      {new Array(7).fill(0).map((_, i) => (
        <line key={i} x1={-w * 0.26 - h * 0.25} x2={-w * 0.26 + h * 0.25} y1={h * (0.37 + i * 0.06)} y2={h * (0.37 + i * 0.06)} stroke={silver ? "#6d6f72" : "#3b3b40"} strokeWidth={h * 0.02} />
      ))}
      {/* cassette window */}
      <rect x={w * 0.0} y={h * 0.28} width={w * 0.44} height={h * 0.46} rx={w * 0.02} fill="#0f0f10" {...ol(1)} />
      {cassetteIn ? (
        <g transform={`translate(${w * 0.22} ${h * 0.51 - cassetteLift * h * 0.5})`}>
          <Cassette w={w * 0.4} label={label} angle={angle} />
        </g>
      ) : null}
      <rect x={w * 0.0} y={h * 0.28} width={w * 0.44} height={h * 0.46} rx={w * 0.02} fill="#9fb0d0" opacity={0.12} />
      {/* piano keys */}
      {keys.map((k, i) => {
        const down = pressed === k || (k === "play" && playing);
        return (
          <g key={k} transform={`translate(${-w * 0.02 + i * w * 0.078} ${down ? h * 0.025 : 0})`}>
            <rect x={0} y={-h * 0.02} width={w * 0.068} height={h * 0.16} rx={w * 0.008} fill={k === "rec" ? "#8e2a22" : silver ? "#d9dadb" : "#4a4a50"} {...ol(1)} />
          </g>
        );
      })}
      <circle cx={w * 0.4} cy={h * 0.12} r={h * 0.035} fill={playing ? "#e0533c" : "#4a2020"} />
    </g>
  );
};

/** Laptop (open), origin = bottom centre of base. `screen` renders inside 0..sw x 0..sh. */
export const Laptop: React.FC<{ w: number; screen?: React.ReactNode; glow?: number }> = ({ w, screen, glow = 0.8 }) => {
  const sw = w * 0.9;
  const sh = sw * 0.6;
  return (
    <g>
      <path d={`M ${-w / 2} 0 L ${w / 2} 0 L ${w * 0.46} ${-w * 0.04} L ${-w * 0.46} ${-w * 0.04} Z`} fill="#3d3f45" {...ol(1.6)} />
      <g transform={`translate(${-sw / 2} ${-w * 0.04 - sh - w * 0.03})`}>
        <rect x={-w * 0.02} y={-w * 0.02} width={sw + w * 0.04} height={sh + w * 0.05} rx={w * 0.015} fill="#2b2d33" {...ol(1.6)} />
        <rect x={0} y={0} width={sw} height={sh} fill="#0d1424" />
        <g opacity={glow}>{screen}</g>
      </g>
    </g>
  );
};

/** Waveform display for the laptop screen. env = amplitudes 0..1. */
export const Waveform: React.FC<{
  w: number;
  h: number;
  env: number[];
  playhead?: number; // 0..1
  color?: string;
  title?: string;
  mark?: [number, number]; // highlighted uncertain region 0..1
  reduced?: number; // 0..1 noise reduction amount (shrinks floor)
}> = ({ w, h, env, playhead, color = "#6fc3c9", mark, reduced = 0 }) => {
  const n = env.length;
  let d = "";
  for (let i = 0; i < n; i++) {
    const x = (i / n) * w;
    const floor = 0.08 * (1 - reduced * 0.7);
    const a = Math.max(floor, env[i]) * h * 0.45;
    d += `M ${x.toFixed(1)} ${(h / 2 - a).toFixed(1)} L ${x.toFixed(1)} ${(h / 2 + a).toFixed(1)} `;
  }
  return (
    <g>
      <rect width={w} height={h} fill="#0f1a2e" />
      <line x1={0} x2={w} y1={h / 2} y2={h / 2} stroke="#2a3b5a" strokeWidth={1} />
      {mark ? <rect x={mark[0] * w} y={0} width={(mark[1] - mark[0]) * w} height={h} fill="#e8a54b" opacity={0.18} /> : null}
      <path d={d} stroke={color} strokeWidth={Math.max(1, (w / n) * 0.7)} />
      {playhead !== undefined ? <line x1={playhead * w} x2={playhead * w} y1={0} y2={h} stroke="#f3eee4" strokeWidth={2} /> : null}
    </g>
  );
};

export const Headphones: React.FC<{ s: number }> = ({ s }) => (
  <g transform={`scale(${s})`}>
    <path d="M -40 10 C -44 -40 44 -40 40 10" fill="none" stroke="#1b1b1d" strokeWidth={8} />
    <rect x={-52} y={0} width={18} height={30} rx={8} fill="#202023" {...ol(1.2)} />
    <rect x={34} y={0} width={18} height={30} rx={8} fill="#202023" {...ol(1.2)} />
  </g>
);

export const Handkerchief: React.FC<{ w: number; open: number }> = ({ w, open }) => (
  <g>
    <path d={`M ${-w / 2} 0 L ${-w * 0.1 - open * w * 0.3} ${-w * 0.35} L ${w / 2} ${-w * 0.05} L ${w * 0.1 + open * w * 0.2} ${w * 0.3} Z`} fill="#e8e1cf" {...ol(1.4)} />
    <path d={`M ${-w * 0.4} ${-w * 0.02} L ${w * 0.4} ${-w * 0.05} M ${-w * 0.2} ${-w * 0.2} L ${w * 0.2} ${w * 0.15}`} stroke="#9aa6c4" strokeWidth={1.2} vectorEffect="non-scaling-stroke" opacity={0.7} />
  </g>
);

/** Paper sheet with real text lines (array) or illegible lines. */
export const Paper: React.FC<{ w: number; h: number; lines?: string[]; scribbleLines?: number; rot?: number; lined?: boolean; size?: number; color?: string; seed?: number }> = ({
  w,
  h,
  lines,
  scribbleLines = 0,
  rot = 0,
  lined = false,
  size,
  color = C.paper,
  seed = 1,
}) => {
  const fs = size ?? h * 0.07;
  return (
    <g transform={`rotate(${rot})`}>
      <rect x={-w / 2 + 4} y={-h / 2 + 5} width={w} height={h} fill="#000" opacity={0.25} />
      <rect x={-w / 2} y={-h / 2} width={w} height={h} fill={color} {...ol(1.2)} />
      {lined
        ? new Array(Math.floor(h / (fs * 1.5))).fill(0).map((_, i) => (
            <line key={i} x1={-w / 2 + w * 0.05} x2={w / 2 - w * 0.05} y1={-h / 2 + fs * 1.5 * (i + 1.2)} y2={-h / 2 + fs * 1.5 * (i + 1.2)} stroke="#9fb0cf" strokeWidth={0.8} vectorEffect="non-scaling-stroke" opacity={0.6} />
          ))
        : null}
      {lines?.map((t, i) => <Handwriting key={i} x={-w / 2 + w * 0.07} y={-h / 2 + fs * 1.5 * (i + 1.05)} size={fs} text={t} rot={-0.8} />)}
      {new Array(scribbleLines).fill(0).map((_, i) => (
        <Scribble key={i} x={-w / 2 + w * 0.08} y={-h / 2 + fs * 1.5 * ((lines?.length ?? 0) + i + 1)} w={w * (0.7 + ((i * 37) % 20) / 100)} h={fs * 0.45} seed={seed * 10 + i} />
      ))}
    </g>
  );
};

export const Diary: React.FC<{ w: number; open: number }> = ({ w, open }) => {
  const h = w * 0.7;
  if (open < 0.5)
    return (
      <g>
        <rect x={-w / 2} y={-h / 2} width={w} height={h} rx={w * 0.03} fill="#5a3a26" {...ol(2)} />
        <rect x={-w / 2} y={-h / 2} width={w * 0.08} height={h} fill="#3e281a" />
        <rect x={-w * 0.2} y={-h * 0.2} width={w * 0.5} height={h * 0.18} fill="#4a3020" opacity={0.6} />
      </g>
    );
  return (
    <g>
      <rect x={-w} y={-h / 2} width={w * 2} height={h} rx={w * 0.03} fill="#5a3a26" {...ol(2)} />
      <rect x={-w * 0.97} y={-h * 0.47} width={w * 0.95} height={h * 0.94} fill="#e6dcc4" {...ol(1)} />
      <rect x={w * 0.02} y={-h * 0.47} width={w * 0.95} height={h * 0.94} fill="#ebe2cb" {...ol(1)} />
      <line x1={0} x2={0} y1={-h * 0.47} y2={h * 0.47} stroke="#8a7a60" strokeWidth={2} />
    </g>
  );
};

export const IDCard: React.FC<{ w: number }> = ({ w }) => {
  const h = w * 0.64;
  return (
    <g>
      <rect x={-w / 2} y={-h / 2} width={w} height={h} rx={w * 0.04} fill="#f0ead8" {...ol(1.4)} />
      <rect x={-w / 2} y={-h / 2} width={w} height={h * 0.2} fill="#3f5a8a" />
      <rect x={-w * 0.42} y={-h * 0.18} width={w * 0.3} height={h * 0.55} fill="#5d7aa6" {...ol(1)} />
      <circle cx={-w * 0.27} cy={-h * 0.0} r={w * 0.08} fill="#bd855d" />
      <path d={`M ${-w * 0.38} ${h * 0.37} Q ${-w * 0.27} ${h * 0.1} ${-w * 0.16} ${h * 0.37}`} fill="#5d7aa6" />
      <path d={`M ${-w * 0.36} ${-h * 0.05} C ${-w * 0.36} ${-h * 0.18} ${-w * 0.18} ${-h * 0.18} ${-w * 0.18} ${-h * 0.05}`} fill="#16100d" />
      <Handwriting x={-w * 0.05} y={-h * 0.02} size={h * 0.13} text="मीरा" color={INK} rot={0} />
      <Scribble x={-w * 0.05} y={h * 0.15} w={w * 0.4} h={h * 0.06} seed={4} color="#555" width={1} />
      <Scribble x={-w * 0.05} y={h * 0.28} w={w * 0.32} h={h * 0.06} seed={5} color="#555" width={1} />
    </g>
  );
};

export const Keys: React.FC<{ s: number; swing?: number }> = ({ s, swing = 0 }) => (
  <g transform={`scale(${s})`}>
    <circle r={14} fill="none" stroke="#5c5a57" strokeWidth={4} />
    {[-30, -10, 10, 28, 45].map((a, i) => (
      <g key={i} transform={`rotate(${a + swing * (i % 2 ? 1 : -1)}) translate(0 14)`}>
        <rect x={-4} y={0} width={8} height={10} rx={3} fill="#6b6560" {...ol(1)} />
        <rect x={-2} y={9} width={4} height={26 + (i % 3) * 4} fill="#77706a" {...ol(0.8)} />
        <rect x={-2} y={28 + (i % 3) * 4} width={6} height={4} fill="#77706a" />
      </g>
    ))}
  </g>
);

export const Padlock: React.FC<{ s: number; open?: boolean }> = ({ s, open = false }) => (
  <g transform={`scale(${s})`}>
    <path d={`M -10 0 L -10 -14 C -10 -26 10 -26 10 -14 L 10 ${open ? -22 : 0}`} fill="none" stroke="#56514b" strokeWidth={5} transform={open ? "translate(0 -6)" : undefined} />
    <rect x={-15} y={-2} width={30} height={26} rx={4} fill="#6d5a3c" {...ol(1.4)} />
    <circle cx={0} cy={9} r={3} fill="#1a1410" />
    <rect x={-1} y={9} width={2} height={7} fill="#1a1410" />
  </g>
);

export const Whistle: React.FC<{ s: number }> = ({ s }) => (
  <g transform={`scale(${s})`}>
    <path d="M -30 -8 L 18 -8 C 30 -8 34 0 34 6 C 34 16 26 20 18 20 C 10 20 6 14 6 8 L -30 8 Z" fill="#b9bcc0" {...ol(1.4)} />
    <rect x={-12} y={-8} width={8} height={6} fill="#22252a" />
    <path d="M -30 0 C -40 -6 -48 -2 -52 6" stroke="#b8392f" strokeWidth={2} fill="none" />
  </g>
);

export const Phone: React.FC<{ w: number; lit: boolean; sender?: string }> = ({ w, lit, sender = "वकील" }) => {
  const h = w * 2;
  return (
    <g>
      <rect x={-w / 2} y={-h / 2} width={w} height={h} rx={w * 0.12} fill="#141417" {...ol(1.6)} />
      <rect x={-w * 0.44} y={-h * 0.45} width={w * 0.88} height={h * 0.9} rx={w * 0.08} fill={lit ? "#1e2a44" : "#0a0a0c"} />
      {lit ? (
        <g>
          <rect x={-w * 0.38} y={-h * 0.3} width={w * 0.76} height={h * 0.2} rx={w * 0.06} fill="#e8e4da" />
          <text x={-w * 0.32} y={-h * 0.24} fontSize={w * 0.11} fill="#1c2a4a" fontFamily="NotoDeva, sans-serif" fontWeight={600}>
            {sender}
          </text>
          <Scribble x={-w * 0.32} y={-h * 0.19} w={w * 0.6} h={w * 0.05} seed={9} color="#6a6a6a" width={1} />
          <Scribble x={-w * 0.32} y={-h * 0.14} w={w * 0.45} h={w * 0.05} seed={11} color="#6a6a6a" width={1} />
        </g>
      ) : null}
    </g>
  );
};

/** Cutting-chai glass; steam 0..1. Origin = base. */
export const TeaGlass: React.FC<{ s: number; steam: number; frame: number }> = ({ s, steam, frame }) => (
  <g transform={`scale(${s})`}>
    <path d="M -14 -40 L 14 -40 L 11 0 L -11 0 Z" fill="#c9d4dc" opacity={0.55} {...ol(1.2)} />
    <path d="M -13 -30 L 13 -30 L 11 -1 L -11 -1 Z" fill="#9a6a3e" opacity={0.9} />
    {steam > 0
      ? [0, 1, 2].map((i) => (
          <path key={i} d={`M ${-6 + i * 6} -44 c ${Math.sin(frame / 9 + i) * 6} -10 ${-Math.sin(frame / 11 + i) * 6} -20 0 -30`} stroke="#e8e4da" strokeWidth={2} fill="none" opacity={0.3 * steam} />
        ))
      : null}
  </g>
);

/** Old stand microphone. Origin = base. `stand` = stem height in local units. */
export const Microphone: React.FC<{ s: number; stand?: number }> = ({ s, stand = 110 }) => (
  <g transform={`scale(${s})`}>
    <ellipse cx={0} cy={0} rx={30} ry={7} fill="#2a2a2c" {...ol(1.2)} />
    <rect x={-3} y={-stand} width={6} height={stand} fill="#4a4a4e" {...ol(1)} />
    <path d={`M 0 ${-stand} L 16 ${-stand - 14}`} stroke="#4a4a4e" strokeWidth={6} />
    <g transform={`translate(0 ${110 - stand})`}>
      <rect x={10} y={-150} width={18} height={30} rx={9} fill="#3a3b40" {...ol(1.2)} transform="rotate(35 19 -135)" />
      {[0, 1, 2].map((i) => (
        <line key={i} x1={13} x2={25} y1={-144 + i * 8} y2={-144 + i * 8} stroke="#6d6f75" strokeWidth={1.5} transform="rotate(35 19 -135)" />
      ))}
    </g>
  </g>
);

/** Siren switch box with a big lever; on 0..1 (1 = up/on). Origin = centre. */
export const SirenSwitch: React.FC<{ s: number; on: number; label?: boolean }> = ({ s, on, label = true }) => (
  <g transform={`scale(${s})`}>
    <rect x={-40} y={-55} width={80} height={110} rx={6} fill="#7a6a4a" {...ol(1.6)} />
    <rect x={-30} y={-45} width={60} height={90} rx={4} fill="#5c4f37" />
    <rect x={-6} y={-30} width={12} height={60} rx={4} fill="#1f1d1a" />
    <g transform={`rotate(${(1 - on) * 160 - 80} 0 0)`}>
      <rect x={-5} y={-42} width={10} height={42} rx={3} fill="#a3322b" {...ol(1)} />
      <circle cx={0} cy={-42} r={8} fill="#c74a3a" {...ol(1)} />
    </g>
    <circle r={7} fill="#2a2a2a" />
    {label ? <path d="M -24 -50 l 48 0" stroke="#e8c060" strokeWidth={4} /> : null}
  </g>
);
