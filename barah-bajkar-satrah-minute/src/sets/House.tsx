import React from "react";
import { Glow, Rain } from "../fx/fx";
import { INK } from "../rigs/Head";
import { Handwriting } from "../props/Props";
import { C } from "../style/palette";

const ol = (w = 2) => ({ stroke: INK, strokeWidth: w, vectorEffect: "non-scaling-stroke" as const });

// Front of the family house: verandah with three steps down to the lane, pillars,
// the height-mark pillar on the right, the lit study window glimpsed at the side.
export const HOUSE = {
  groundY: 1000,
  verandahY: 820,
  pillarR: { x: 1390, top: 380, w: 56 },
  stepX: [760, 1220],
  heightMark: { x: 1360, y: 700 },
};

export const HouseFront: React.FC<{
  frame: number;
  time: "night" | "day" | "dusk";
  rain?: number;
  windowLit?: number;
  wet?: number;
  mud?: number; // 0..1 mud on steps (S12)
  showMark?: boolean;
}> = ({ frame, time, rain = 0, windowLit = 1, wet = 0.5, mud = 0, showMark = true }) => {
  const night = time === "night";
  const sky0 = night ? "#060a16" : time === "dusk" ? "#3d4a72" : "#8b99b8";
  const sky1 = night ? "#18223f" : time === "dusk" ? "#b48a74" : "#c9cfd8";
  const wall = night ? "#3a3f55" : time === "dusk" ? "#8a7d78" : "#b7a88f";
  const wallShade = night ? "#2a2e40" : time === "dusk" ? "#6d625f" : "#968870";
  const p = HOUSE.pillarR;
  return (
    <g>
      <defs>
        <linearGradient id={`hfSky${time}`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor={sky0} />
          <stop offset="1" stopColor={sky1} />
        </linearGradient>
      </defs>
      <rect x={-300} y={-300} width={2520} height={1400} fill={`url(#hfSky${time})`} />
      {/* neighbouring houses */}
      <path d="M -300 520 L 140 520 L 140 430 L 260 380 L 380 430 L 380 600 L -300 600 Z" fill={night ? "#10152a" : "#7d7f8c"} {...ol(1.2)} />
      <path d="M 1700 470 L 2200 470 L 2200 640 L 1700 640 Z" fill={night ? "#12172b" : "#80828e"} {...ol(1.2)} />
      <rect x={1760} y={520} width={36} height={44} fill={night ? C.amberSoft : "#56596a"} opacity={night ? 0.4 : 1} />
      {/* house body */}
      <rect x={420} y={300} width={1240} height={540} fill={wall} {...ol()} />
      <rect x={420} y={300} width={180} height={540} fill={wallShade} />
      <path d="M 380 300 L 1700 300 L 1660 250 L 420 250 Z" fill={night ? "#2a2020" : "#7a4f3a"} {...ol()} />
      {[...Array(24)].map((_, i) => (
        <line key={i} x1={430 + i * 52} y1={252} x2={410 + i * 53} y2={300} stroke="#1a1410" strokeWidth={1.4} />
      ))}
      {/* verandah roof slab and pillars */}
      <rect x={560} y={380} width={1000} height={34} fill={night ? "#4a4e62" : "#c8bba3"} {...ol(1.6)} />
      {[620, 900, 1180, p.x].map((x, i) => (
        <g key={i}>
          <rect x={x - p.w / 2} y={414} width={p.w} height={HOUSE.verandahY - 414} fill={night ? "#4f546a" : "#cfc3aa"} {...ol(1.6)} />
          <rect x={x - p.w / 2} y={414} width={p.w * 0.35} height={HOUSE.verandahY - 414} fill={wallShade} opacity={0.5} />
          <rect x={x - p.w / 2 - 8} y={HOUSE.verandahY - 26} width={p.w + 16} height={26} fill={night ? "#454a5e" : "#b9ad95"} {...ol(1.2)} />
        </g>
      ))}
      {/* door & windows behind the verandah */}
      <rect x={700} y={470} width={150} height={350} fill="#3b2a1f" {...ol(1.6)} />
      <rect x={712} y={482} width={60} height={326} fill="#4a3426" {...ol(1)} />
      <rect x={778} y={482} width={60} height={326} fill="#4a3426" {...ol(1)} />
      <rect x={980} y={500} width={150} height={170} fill={night ? "#0d1224" : "#3a4256"} {...ol(1.6)} />
      {night && windowLit > 0 ? (
        <>
          <rect x={980} y={500} width={150} height={170} fill={C.amber} opacity={0.75 * windowLit} />
          <Glow id="hfWin" cx={1055} cy={585} r={260} color={C.amber} opacity={0.35 * windowLit} />
        </>
      ) : null}
      {[1010, 1040, 1070, 1100].map((x) => (
        <line key={x} x1={x} x2={x} y1={500} y2={670} stroke="#1a1612" strokeWidth={4} />
      ))}
      {/* verandah floor and three steps */}
      <rect x={520} y={HOUSE.verandahY} width={1080} height={40} fill={night ? "#4a4d5c" : "#a39a88"} {...ol(1.6)} />
      {[0, 1, 2].map((i) => (
        <g key={i}>
          <rect x={HOUSE.stepX[0] - i * 40} y={HOUSE.verandahY + 40 + i * 34} width={HOUSE.stepX[1] - HOUSE.stepX[0] + i * 80} height={34} fill={night ? "#45485a" : "#9d9483"} {...ol(1.4)} />
          {mud > 0 ? (
            <path d={`M ${HOUSE.stepX[0] - i * 40 + 20} ${HOUSE.verandahY + 44 + i * 34} q 120 ${14 * mud} 260 2 q 140 ${-10 * mud} 300 ${6 * mud}`} stroke="#5a4532" strokeWidth={10 * mud} fill="none" opacity={0.7 * mud} />
          ) : null}
        </g>
      ))}
      {/* height mark on the right pillar */}
      {showMark ? <HeightMark x={HOUSE.heightMark.x} y={HOUSE.heightMark.y} s={0.6} /> : null}
      {/* lane */}
      <rect x={-300} y={HOUSE.groundY - 40} width={2520} height={400} fill={night ? "#1a1d27" : "#6b6253"} />
      <path d={`M -300 ${HOUSE.groundY + 30} L 2220 ${HOUSE.groundY + 10}`} stroke={night ? "#252a38" : "#5a5245"} strokeWidth={6} />
      {wet > 0 ? (
        <g opacity={wet}>
          <ellipse cx={420} cy={1040} rx={200} ry={18} fill={night ? "#2a3350" : "#8c94a6"} opacity={0.7} />
          <ellipse cx={1500} cy={1060} rx={260} ry={22} fill={night ? "#2a3350" : "#8c94a6"} opacity={0.7} />
          {night ? <ellipse cx={1055} cy={1055} rx={90} ry={10} fill={C.amber} opacity={0.35 * windowLit} /> : null}
        </g>
      ) : null}
      {/* street lamp */}
      <rect x={1840} y={360} width={10} height={640} fill="#15171d" />
      <path d="M 1845 362 L 1790 372" stroke="#15171d" strokeWidth={6} />
      {night ? <Glow id="hfLamp" cx={1788} cy={385} r={180} color={C.amber} opacity={0.55} /> : null}
      {rain > 0 ? <Rain frame={frame} seed="hfRain" count={Math.round(220 * rain)} x={-300} y={-300} w={2520} h={1400} opacity={0.3 * rain} /> : null}
    </g>
  );
};

/** Pencil height marks with the name अंशु in crooked writing (S12). */
export const HeightMark: React.FC<{ x: number; y: number; s: number }> = ({ x, y, s }) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    {[0, 1, 2].map((i) => (
      <line key={i} x1={-30} x2={30} y1={-i * 40} y2={-i * 40 - 2} stroke="#4a4640" strokeWidth={3} opacity={0.6 + i * 0.12} />
    ))}
    {/* date above (illegible) and the name below, crooked */}
    <path d="M -26 -104 q 6 -8 10 0 m 6 -4 l 4 -6 m 6 10 q 6 -10 12 0 m 6 -6 l 4 -6 m 4 10 q 5 -6 10 0" stroke="#4a4640" strokeWidth={2.2} fill="none" />
    <Handwriting x={-30} y={34} size={30} text="अंशु" color="#3a3632" rot={-9} />
  </g>
);
