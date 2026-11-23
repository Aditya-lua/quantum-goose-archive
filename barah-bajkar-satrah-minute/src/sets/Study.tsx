import React from "react";
import { Glow, GlassRain, Rain } from "../fx/fx";
import { INK } from "../rigs/Head";
import { Clock } from "../props/Clock";
import { C } from "../style/palette";

// Study (back room) of the family house. Fixed geography (see CHARACTER_BIBLE):
// window left with rain, tape almirah far left, clock above the desk, door to the
// outer room on the right, packing boxes by the door.
export const STUDY = {
  floorY: 1010,
  deskTop: 742,
  deskL: 880,
  deskR: 1560,
  clock: { x: 1190, y: 300, r: 88 },
  chairX: 770,
  window: { x: 300, y: 190, w: 420, h: 450 },
  almirah: { x: 30, y: 250, w: 240, h: 650 },
  door: { x: 1660, y: 230, w: 220, h: 670 },
  lamp: { x: 1460, y: 742 },
  drawer: { x: 1120, y: 762, w: 200, h: 56 },
};

const ol = (w = 2) => ({ stroke: INK, strokeWidth: w, vectorEffect: "non-scaling-stroke" as const });

export const StudyBack: React.FC<{
  frame: number;
  clockStart: number | null;
  lamp?: number;
  rain?: number; // 0..1 intensity outside
  warm?: number; // 0..1 ending warmth
  drawer?: number; // 0..1 drawer pulled out
  boxes?: boolean;
  doorLight?: number;
  hideClock?: boolean;
  tapesInAlmirah?: boolean;
}> = ({ frame, clockStart, lamp = 1, rain = 1, warm = 0, drawer = 0, boxes = true, doorLight = 0.6, hideClock = false, tapesInAlmirah = true }) => {
  const S = STUDY;
  const w = S.window;
  const a = S.almirah;
  const d = S.door;
  return (
    <g>
      <defs>
        <linearGradient id="studyWall" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor={warm ? "#4a4660" : "#262c42"} />
          <stop offset="1" stopColor={warm ? "#5d5468" : "#363d57"} />
        </linearGradient>
        <linearGradient id="studySky" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#070b17" />
          <stop offset="1" stopColor="#1b2645" />
        </linearGradient>
        <clipPath id="studyWin">
          <rect x={w.x + 18} y={w.y + 18} width={w.w - 36} height={w.h - 36} />
        </clipPath>
      </defs>
      {/* wall */}
      <rect x={-200} y={-200} width={2320} height={1110} fill="url(#studyWall)" />
      <ellipse cx={980} cy={120} rx={260} ry={70} fill="#1b2034" opacity={0.5} />
      <ellipse cx={1580} cy={640} rx={90} ry={150} fill="#1d2236" opacity={0.35} />
      <path d="M 740 0 C 760 60 735 120 750 190" stroke="#1e2335" strokeWidth={6} opacity={0.5} fill="none" />
      {/* floor */}
      <rect x={-200} y={900} width={2320} height={400} fill="#2b2520" />
      {[...Array(9)].map((_, i) => (
        <line key={i} x1={960 + (i - 4) * 140} y1={900} x2={960 + (i - 4) * 420} y2={1280} stroke="#1e1a16" strokeWidth={2} />
      ))}
      <line x1={-200} y1={960} x2={2120} y2={960} stroke="#1e1a16" strokeWidth={2} />
      <line x1={-200} y1={1040} x2={2120} y2={1040} stroke="#1e1a16" strokeWidth={2} />
      <rect x={-200} y={890} width={2320} height={14} fill="#1f1c22" />

      {/* window */}
      <rect x={w.x - 10} y={w.y - 10} width={w.w + 20} height={w.h + 20} fill="#3b2a1f" {...ol()} />
      <rect x={w.x + 18} y={w.y + 18} width={w.w - 36} height={w.h - 36} fill="url(#studySky)" />
      <g clipPath="url(#studyWin)">
        <path d={`M ${w.x} ${w.y + 330} L ${w.x + 60} ${w.y + 300} L ${w.x + 60} ${w.y + 250} L ${w.x + 150} ${w.y + 250} L ${w.x + 150} ${w.y + 290} L ${w.x + 250} ${w.y + 280} L ${w.x + 250} ${w.y + 220} L ${w.x + 340} ${w.y + 220} L ${w.x + 340} ${w.y + 300} L ${w.x + 420} ${w.y + 300} L ${w.x + 420} ${w.y + 500} L ${w.x} ${w.y + 500} Z`} fill="#0c1120" />
        <rect x={w.x + 95} y={w.y + 268} width={18} height={14} fill={C.amberSoft} opacity={0.55} />
        <rect x={w.x + 290} y={w.y + 240} width={14} height={18} fill={C.amberSoft} opacity={0.35} />
        <line x1={w.x + 200} y1={w.y + 140} x2={w.x + 200} y2={w.y + 450} stroke="#10141f" strokeWidth={6} />
        <Glow id="studyStreet" cx={w.x + 200} cy={w.y + 140} r={90} color={C.amber} opacity={0.6} />
        <Rain frame={frame} seed="studyWinRain" count={Math.round(70 * rain)} x={w.x} y={w.y} w={w.w} h={w.h} speed={30} len={40} opacity={0.35 * rain} />
        <GlassRain frame={frame} x={w.x + 18} y={w.y + 18} w={w.w - 36} h={w.h - 36} count={Math.round(22 * rain)} />
      </g>
      {/* frame bars and mullions */}
      <rect x={w.x + w.w / 2 - 7} y={w.y + 18} width={14} height={w.h - 36} fill="#3b2a1f" {...ol(1.2)} />
      <rect x={w.x + 18} y={w.y + w.h * 0.45} width={w.w - 36} height={12} fill="#3b2a1f" {...ol(1.2)} />
      {[1, 2, 3, 5, 6, 7].map((i) => (
        <line key={i} x1={w.x + (w.w / 8) * i} x2={w.x + (w.w / 8) * i} y1={w.y + 18} y2={w.y + w.h - 18} stroke="#151515" strokeWidth={4} />
      ))}
      <rect x={w.x - 30} y={w.y + w.h + 6} width={w.w + 60} height={22} fill="#4a3324" {...ol()} />
      {/* window light spill on floor */}
      <path d={`M ${w.x + 30} ${w.y + w.h + 30} L ${w.x + w.w - 30} ${w.y + w.h + 30} L ${w.x + w.w + 200} 1080 L ${w.x - 60} 1080 Z`} fill="#7d88ab" opacity={0.06} />

      {/* almirah */}
      <rect x={a.x} y={a.y} width={a.w} height={a.h} fill="#3e2b1f" {...ol()} />
      <rect x={a.x - 8} y={a.y - 16} width={a.w + 16} height={20} fill="#4f3828" {...ol(1.5)} />
      {[0, 1].map((k) => (
        <g key={k}>
          <rect x={a.x + 14 + k * (a.w / 2 - 6)} y={a.y + 20} width={a.w / 2 - 22} height={a.h * 0.62} fill="#1b1a20" {...ol(1.4)} />
          {[0, 1, 2, 3].map((r) => (
            <g key={r}>
              <line x1={a.x + 14 + k * (a.w / 2 - 6)} x2={a.x + a.w / 2 - 8 + k * (a.w / 2 - 6)} y1={a.y + 20 + (r + 1) * a.h * 0.155} y2={a.y + 20 + (r + 1) * a.h * 0.155} stroke="#3e2b1f" strokeWidth={6} />
              {tapesInAlmirah
                ? [...Array(7)].map((_, c) => (
                    <rect
                      key={c}
                      x={a.x + 20 + k * (a.w / 2 - 6) + c * 13}
                      y={a.y + 20 + (r + 1) * a.h * 0.155 - 38 - ((c * 7 + r * 3) % 3) * 2}
                      width={10}
                      height={36 + ((c * 7 + r * 3) % 3) * 2}
                      fill={["#6b5a48", "#2f3a50", "#5a3a2c", "#7a6a50", "#3b3f46"][(c + r + k) % 5]}
                      stroke="#111"
                      strokeWidth={0.8}
                    />
                  ))
                : null}
            </g>
          ))}
          <rect x={a.x + 14 + k * (a.w / 2 - 6)} y={a.y + 20} width={a.w / 2 - 22} height={a.h * 0.62} fill="#8fa0c8" opacity={0.08} />
          <rect x={a.x + 14 + k * (a.w / 2 - 6)} y={a.y + 40 + a.h * 0.62} width={a.w / 2 - 22} height={a.h * 0.3} fill="#4a3426" {...ol(1.2)} />
          <circle cx={a.x + a.w / 2 + (k ? 10 : -10)} cy={a.y + a.h * 0.55} r={4} fill="#b89a5a" />
        </g>
      ))}

      {/* clock: stopped at 12:17 until the battery moment */}
      {!hideClock ? (
        <g transform={`translate(${S.clock.x} ${S.clock.y})`}>
          <ellipse cx={10} cy={14} rx={S.clock.r * 1.18} ry={S.clock.r * 1.18} fill="#0b0d16" opacity={0.35} />
          <line x1={0} y1={-S.clock.r * 1.13} x2={0} y2={-S.clock.r * 1.3} stroke="#2a2420" strokeWidth={3} />
          <Clock r={S.clock.r} frame={frame} startFrame={clockStart} />
        </g>
      ) : (
        <g transform={`translate(${S.clock.x} ${S.clock.y})`}>
          <circle r={S.clock.r * 1.15} fill="#2c3350" opacity={0.9} />
          <circle r={S.clock.r * 1.15} fill="none" stroke="#1d2236" strokeWidth={6} opacity={0.7} />
          <circle cx={0} cy={-S.clock.r * 1.3} r={3} fill="#2a2420" />
        </g>
      )}

      {/* shelf with books */}
      <rect x={1400} y={430} width={300} height={14} fill="#4a3324" {...ol(1.4)} />
      {[...Array(9)].map((_, i) => (
        <rect key={i} x={1410 + i * 26 + (i > 5 ? 18 : 0)} y={360 + (i % 3) * 6} width={22} height={70 - (i % 3) * 6} fill={["#5a3a2c", "#2f3a50", "#6b5a48", "#3b3f46"][i % 4]} {...ol(1)} />
      ))}

      {/* door to outer room */}
      <rect x={d.x} y={d.y} width={d.w} height={d.h} fill="#3b2a1f" {...ol()} />
      <rect x={d.x + 16} y={d.y + 16} width={d.w - 32} height={d.h - 16} fill="#1a1612" />
      <rect x={d.x + 16} y={d.y + 16} width={(d.w - 32) * 0.35} height={d.h - 16} fill={C.amber} opacity={0.16 * doorLight} />
      <path d={`M ${d.x + 16 + (d.w - 32) * 0.35} ${d.y + 16} L ${d.x + d.w - 10} ${d.y + 6} L ${d.x + d.w - 10} ${d.y + d.h + 10} L ${d.x + 16 + (d.w - 32) * 0.35} ${d.y + d.h}`} fill="#4b3526" {...ol(1.5)} />
      <path d={`M ${d.x + 16 + (d.w - 32) * 0.35} ${d.y + d.h} L ${d.x - 150} 1080 L ${d.x + 40} 1080 Z`} fill={C.amber} opacity={0.07 * doorLight} />

      {/* packing boxes for the sale */}
      {boxes ? (
        <g>
          <rect x={1600} y={860} width={170} height={130} fill="#8a6a46" {...ol(1.6)} />
          <rect x={1620} y={760} width={140} height={100} fill="#94744e" {...ol(1.6)} />
          <path d="M 1600 900 L 1770 900 M 1620 800 L 1760 800" stroke="#6b5236" strokeWidth={3} />
          <path d="M 1690 760 L 1690 860" stroke="#d8cfb8" strokeWidth={2} />
        </g>
      ) : null}

      {/* desk */}
      <rect x={S.deskL} y={S.deskTop} width={S.deskR - S.deskL} height={24} fill="#5a3f2c" {...ol()} />
      <rect x={S.deskL + 20} y={S.deskTop + 24} width={S.deskR - S.deskL - 40} height={70} fill="#4a3324" {...ol(1.6)} />
      <rect x={S.deskL + 30} y={S.deskTop + 24} width={30} height={S.floorY - S.deskTop - 24} fill="#3e2b1f" {...ol(1.6)} />
      <rect x={S.deskR - 60} y={S.deskTop + 24} width={30} height={S.floorY - S.deskTop - 24} fill="#3e2b1f" {...ol(1.6)} />
      <g transform={`translate(0 ${drawer * 26})`}>
        <rect x={S.drawer.x - drawer * 10} y={S.drawer.y} width={S.drawer.w + drawer * 20} height={S.drawer.h + drawer * 10} fill="#5a3f2c" {...ol(1.6)} />
        <rect x={S.drawer.x + S.drawer.w / 2 - 22} y={S.drawer.y + 22 + drawer * 5} width={44} height={8} rx={3} fill="#b89a5a" />
      </g>

      {/* desk lamp */}
      <g transform={`translate(${S.lamp.x} ${S.lamp.y})`}>
        <ellipse cx={0} cy={0} rx={36} ry={8} fill="#7a5a2c" {...ol(1.4)} />
        <path d="M 0 0 L -14 -110 L 30 -150" stroke="#8a6a34" strokeWidth={7} fill="none" />
        <path d="M 10 -170 L 62 -150 L 48 -112 L -6 -128 Z" fill="#9a7a3c" {...ol(1.4)} />
      </g>
      {lamp > 0 ? (
        <g>
          <Glow id="studyLampPool" cx={S.lamp.x + 10} cy={S.deskTop + 6} r={330} color={C.amberSoft} opacity={0.42 * lamp} />
          <Glow id="studyLampWall" cx={S.lamp.x + 30} cy={S.lamp.y - 160} r={420} color={C.amber} opacity={0.2 * lamp + warm * 0.15} />
        </g>
      ) : null}
    </g>
  );
};

/** Wooden chair, origin at floor centre, facing +x. */
export const Chair: React.FC<{ s?: number; color?: string }> = ({ s = 1, color = "#4a3324" }) => (
  <g transform={`scale(${s})`}>
    <rect x={-70} y={-165} width={140} height={16} fill={color} {...ol(1.6)} />
    <rect x={-66} y={-150} width={12} height={150} fill={color} {...ol(1.4)} />
    <rect x={54} y={-150} width={12} height={150} fill={color} {...ol(1.4)} />
    <rect x={-74} y={-380} width={14} height={230} fill={color} {...ol(1.4)} />
    <rect x={-74} y={-370} width={14} height={60} fill="#5a3f2c" />
  </g>
);

/** Plastic chair used at the memorial. */
export const PlasticChair: React.FC<{ s?: number; color?: string }> = ({ s = 1, color = "#c9c2b0" }) => (
  <g transform={`scale(${s})`}>
    <path d="M -60 -150 L 60 -150 L 54 0 M -60 -150 L -54 0 M -60 -150 L -70 -330 L -50 -330 L -40 -150" stroke={color} strokeWidth={14} fill="none" />
    <rect x={-66} y={-160} width={132} height={16} rx={6} fill={color} {...ol(1.2)} />
  </g>
);
