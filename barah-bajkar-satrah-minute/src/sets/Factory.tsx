import React from "react";
import { random } from "remotion";
import { Glow, GlassRain, Rain } from "../fx/fx";
import { INK } from "../rigs/Head";
import { C } from "../style/palette";
import { Handwriting, Microphone, Padlock, Scribble, SirenSwitch } from "../props/Props";
import { Head } from "../rigs/Head";
import { vikram } from "../rigs/characters";

const ol = (w = 2) => ({ stroke: INK, strokeWidth: w, vectorEffect: "non-scaling-stroke" as const });

/** Animated water surface from y down, with a dye tint. */
export const Water: React.FC<{ frame: number; y: number; x0?: number; x1?: number; dye?: number; seed?: string; opacity?: number }> = ({ frame, y, x0 = -400, x1 = 2320, dye = 0.5, seed = "w", opacity = 0.92 }) => {
  let d = `M ${x0} ${y}`;
  for (let x = x0; x <= x1; x += 40) {
    const k = Math.sin(x * 0.012 + frame * 0.09 + random(seed) * 6) * 6 + Math.sin(x * 0.031 - frame * 0.13) * 3;
    d += ` L ${x} ${y + k}`;
  }
  d += ` L ${x1} 1400 L ${x0} 1400 Z`;
  const col = dye > 0.5 ? C.dye : "#1d2a48";
  return (
    <g opacity={opacity}>
      <path d={d} fill={col} />
      <path d={d} fill={C.dyeRed} opacity={dye * 0.35} />
      {[...Array(10)].map((_, i) => {
        const xx = x0 + ((random(`${seed}r${i}`) * (x1 - x0) + frame * (2 + (i % 3))) % (x1 - x0));
        return <path key={i} d={`M ${xx} ${y + 30 + (i % 4) * 40} l 60 0`} stroke="#9aa6c4" strokeWidth={2} opacity={0.35} />;
      })}
    </g>
  );
};

// Sahajanpur from the hill road: factory and office (with siren pole) on the left
// rise, the lower settlement (निचली बस्ती) to the right, the pond behind the factory.
export const Town: React.FC<{ frame: number; flood: number; night?: boolean; rain?: number }> = ({ frame, flood, night = true, rain = 1 }) => (
  <g>
    <rect x={-400} y={-300} width={2720} height={1500} fill={night ? "#080c19" : "#5d6b8c"} />
    <path d="M -400 520 C 200 470 500 480 900 560 L 900 1300 L -400 1300 Z" fill={night ? "#121726" : "#4a5068"} />
    <ellipse cx={240} cy={470} rx={260} ry={34} fill="#1d2a48" {...ol(1.2)} />
    {/* factory sheds and chimney */}
    {[0, 1, 2].map((i) => (
      <path key={i} d={`M ${60 + i * 200} 560 L ${60 + i * 200} 480 L ${160 + i * 200} 440 L ${250 + i * 200} 480 L ${250 + i * 200} 560 Z`} fill="#20263a" {...ol(1.4)} />
    ))}
    <rect x={560} y={260} width={46} height={250} fill="#262c40" {...ol(1.4)} />
    <rect x={556} y={250} width={54} height={16} fill="#2e3448" {...ol(1)} />
    {/* office with siren pole */}
    <rect x={690} y={470} width={200} height={110} fill="#2a3046" {...ol(1.4)} />
    <rect x={720} y={500} width={40} height={36} fill={C.amber} opacity={night ? 0.7 : 0.1} />
    <line x1={860} y1={470} x2={860} y2={330} stroke="#1a1d27" strokeWidth={6} />
    <path d="M 860 330 l 34 -14 l 0 36 Z" fill="#3a3d44" {...ol(1)} />
    {/* settlement rooftops below */}
    {[...Array(26)].map((_, i) => {
      const x = 860 + (i % 13) * 110 + (i > 12 ? 50 : 0);
      const y = 700 + (i > 12 ? 130 : 0) + (i % 3) * 12;
      return (
        <g key={i}>
          <rect x={x} y={y} width={90} height={80} fill={night ? "#1a1f31" : "#6b6658"} {...ol(1.2)} />
          <path d={`M ${x - 8} ${y} L ${x + 45} ${y - 30} L ${x + 98} ${y} Z`} fill={night ? "#2a2020" : "#7a4f3a"} {...ol(1.2)} />
          {random(`tw${i}`) > 0.6 && night ? <rect x={x + 30} y={y + 25} width={20} height={20} fill={C.amberSoft} opacity={0.6 * (1 - flood * 0.7)} /> : null}
        </g>
      );
    })}
    {/* dye water streaming down from the factory into the lanes */}
    {flood > 0 ? (
      <g>
        <path d={`M 620 560 C 700 620 760 640 860 ${660 + flood * 30} L 860 ${700 + flood * 40} C 760 690 680 650 600 600 Z`} fill={C.dye} opacity={0.85} />
        <Water frame={frame} y={980 - flood * 230} x0={760} x1={2400} dye={0.9} seed="townW" opacity={0.85} />
      </g>
    ) : null}
    {rain > 0 ? <Rain frame={frame} seed="townRain" count={Math.round(240 * rain)} x={-400} y={-300} w={2720} h={1500} opacity={0.26 * rain} /> : null}
  </g>
);

/** Close: the siren horn on its pole (present day, rusted). */
export const SirenPole: React.FC<{ frame: number; day?: boolean }> = ({ frame, day = false }) => (
  <g>
    <rect x={-400} y={-300} width={2720} height={1500} fill={day ? "#7b86a3" : "#1a2238"} />
    <path d="M -400 900 L 2320 860 L 2320 1300 L -400 1300 Z" fill={day ? "#4d5064" : "#121624"} />
    <rect x={930} y={260} width={40} height={900} fill="#3a3530" {...ol(1.6)} />
    <g transform="translate(950 300)">
      <path d="M 0 0 L 230 -90 L 250 -70 L 250 90 L 230 110 L 0 40 Z" fill="#6b5a48" {...ol(2)} />
      <path d="M 120 -40 L 120 70" stroke="#7d3f24" strokeWidth={10} opacity={0.6} />
      <ellipse cx={248} cy={10} rx={14} ry={82} fill="#2a2420" {...ol(1.4)} />
      <path d="M 40 10 L 180 -40" stroke={C.rust} strokeWidth={6} opacity={0.5} />
    </g>
    <path d="M 950 420 C 800 460 600 500 -100 520" stroke="#15171d" strokeWidth={3} fill="none" />
    <Rain frame={frame} seed="sirenRain" count={day ? 0 : 120} x={-400} y={-300} w={2720} h={1500} opacity={0.22} />
  </g>
);

/** Inquiry file with the word «लापरवाही» (the word the narration uses). */
export const InquiryFile: React.FC<{ circle: number }> = ({ circle }) => (
  <g>
    <rect x={-200} y={-200} width={2320} height={1500} fill="#3a3028" />
    <rect x={520} y={120} width={880} height={860} fill="#c9b994" {...ol(2)} />
    <rect x={560} y={150} width={800} height={800} fill="#ece4cf" {...ol(1.2)} />
    {[...Array(14)].map((_, i) => (
      <Scribble key={i} x={620} y={230 + i * 48} w={640 - (i % 4) * 60} h={14} seed={i + 30} color="#3a3a3a" width={1.6} />
    ))}
    <rect x={600} y={560} width={720} height={70} fill="#ece4cf" />
    <Handwriting x={700} y={612} size={60} text="लापरवाही" color="#2a2a2a" rot={0} />
    <ellipse cx={830} cy={592} rx={170} ry={52} fill="none" stroke="#9a2a22" strokeWidth={5} strokeDasharray={`${circle * 760} 760`} transform="rotate(-4 830 592)" />
    <rect x={1120} y={800} width={160} height={90} fill="none" stroke="#7a2a22" strokeWidth={4} opacity={0.7} transform="rotate(-8 1200 845)" />
  </g>
);

/** Factory exterior (present): closed gate, posters, demolition board, office beyond. */
export const FactoryGate: React.FC<{ frame: number; dusk?: boolean; gateOpen?: number }> = ({ frame, dusk = true, gateOpen = 0 }) => (
  <g>
    <defs>
      <linearGradient id="fgSky" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stopColor={dusk ? "#2b3358" : "#7b86a3"} />
        <stop offset="1" stopColor={dusk ? "#9a6e64" : "#c9cfd8"} />
      </linearGradient>
    </defs>
    <rect x={-400} y={-300} width={2720} height={1500} fill="url(#fgSky)" />
    {/* sheds & chimney behind */}
    <rect x={1240} y={120} width={60} height={420} fill="#3a3e4c" {...ol(1.4)} />
    <path d="M 900 520 L 900 380 L 1100 320 L 1300 380 L 1300 520 Z" fill="#4a4e5c" {...ol(1.4)} />
    {/* office building beyond the gate (announcement room window) */}
    <rect x={640} y={360} width={420} height={260} fill="#6d6a66" {...ol(1.6)} />
    <rect x={700} y={420} width={110} height={90} fill="#2a2e3c" {...ol(1.2)} />
    <path d="M 700 420 L 760 470 L 730 510" stroke="#9aa6c4" strokeWidth={1.5} opacity={0.6} fill="none" />
    <line x1={1020} y1={360} x2={1020} y2={220} stroke="#2a2420" strokeWidth={6} />
    <path d="M 1020 220 l 30 -12 l 0 32 Z" fill="#5a4a3a" {...ol(1)} />
    {/* compound wall with posters */}
    <rect x={-400} y={560} width={2720} height={320} fill="#8d8780" {...ol(1.6)} />
    <rect x={-400} y={560} width={2720} height={20} fill="#6d6a66" />
    {[-260, 120, 1440, 1780].map((x, i) => (
      <VikramPoster key={x} x={x} y={600} s={0.9} torn={i % 2 === 1} />
    ))}
    {/* demolition notice */}
    <g transform="translate(1180 640)">
      <rect x={-6} y={0} width={12} height={240} fill="#3a3530" />
      <rect x={-110} y={-20} width={220} height={130} fill="#e8d36a" {...ol(1.6)} />
      <Scribble x={-90} y={20} w={180} h={14} seed={51} color="#2a2a2a" width={2} />
      <Scribble x={-90} y={50} w={150} h={14} seed={52} color="#2a2a2a" width={2} />
      <Scribble x={-90} y={80} w={170} h={14} seed={53} color="#a3322b" width={2} />
    </g>
    {/* iron gate */}
    <g>
      <rect x={560} y={540} width={30} height={360} fill="#4a4540" {...ol(1.4)} />
      <rect x={1090} y={540} width={30} height={360} fill="#4a4540" {...ol(1.4)} />
      {[0, 1].map((k) => (
        <g key={k} transform={`translate(${k ? 1090 : 590} 0) scale(${k ? -(1 - gateOpen * 0.6) : 1 - gateOpen * 0.6} 1)`}>
          <rect x={0} y={580} width={250} height={310} fill="none" stroke="#3a3530" strokeWidth={10} />
          {[...Array(9)].map((_, i) => (
            <line key={i} x1={14 + i * 28} x2={14 + i * 28} y1={580} y2={890} stroke="#3a3530" strokeWidth={6} />
          ))}
          <line x1={0} x2={250} y1={735} y2={735} stroke="#3a3530" strokeWidth={8} />
        </g>
      ))}
    </g>
    {/* watchman's cabin */}
    <rect x={240} y={700} width={200} height={190} fill="#6b6253" {...ol(1.6)} />
    <rect x={280} y={740} width={70} height={60} fill={C.amber} opacity={0.4} {...ol(1)} />
    <rect x={-400} y={880} width={2720} height={500} fill="#5a5245" />
    <path d="M -400 960 L 2320 940" stroke="#4a4438" strokeWidth={4} />
  </g>
);

/** Election-style poster of Vikram Vashishth (name from the story). */
export const VikramPoster: React.FC<{ x: number; y: number; s: number; torn?: boolean }> = ({ x, y, s, torn }) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <rect x={0} y={0} width={300} height={240} fill="#e9e1cf" {...ol(1.4)} />
    <rect x={0} y={0} width={300} height={40} fill="#c46a2a" />
    <g transform="translate(92 132) scale(1.05)">
      <Head spec={vikram} pose={{ stance: "stand", expr: "smug", headTurn: -0.3, gazeX: 0.1 }} />
    </g>
    <path d="M 30 240 L 40 196 C 60 180 120 180 140 196 L 150 240 Z" fill="#2a2d36" />
    <text x={170} y={120} fontSize={30} fontFamily="NotoDeva, sans-serif" fontWeight={600} fill="#2a2a2a">
      विक्रम
    </text>
    <text x={170} y={158} fontSize={30} fontFamily="NotoDeva, sans-serif" fontWeight={600} fill="#2a2a2a">
      वशिष्ठ
    </text>
    <Scribble x={170} y={190} w={110} h={10} seed={61} color="#555" width={1.2} />
    {torn ? <path d="M 220 0 L 300 0 L 300 90 L 270 60 L 250 80 Z" fill="#8d8780" /> : null}
  </g>
);

// Announcement room in the factory office. Fixed geography: desk on the back wall,
// siren switch to the right of the desk, window on the left (back verandah and the
// school gate beyond), door on the right.
export const ROOM = {
  floorY: 990,
  deskTop: 720,
  deskL: 700,
  deskR: 1300,
  switch: { x: 1440, y: 520 },
  window: { x: 140, y: 230, w: 420, h: 380 },
  door: { x: 1640, y: 260, w: 220 },
  mic: { x: 960, y: 720 },
  machine: { x: 1160, y: 720 },
};

export const AnnouncementRoom: React.FC<{
  frame: number;
  era: "flood" | "present" | "memory";
  sirenOn?: number;
  bulb?: number;
  rain?: number;
  showMic?: boolean;
  micSwing?: number;
}> = ({ frame, era, sirenOn = 0, bulb = 1, rain = 1, showMic = true, micSwing = 0 }) => {
  const R = ROOM;
  const w = R.window;
  const present = era === "present";
  const wall = era === "memory" ? "#a39a88" : present ? "#5f5b57" : "#3b4054";
  const flicker = era === "flood" ? 0.85 + 0.15 * Math.sin(frame * 1.7) * Math.sin(frame * 0.37) : 1;
  return (
    <g>
      <rect x={-200} y={-200} width={2320} height={1500} fill={wall} />
      {present ? (
        <g opacity={0.5}>
          <ellipse cx={400} cy={120} rx={240} ry={60} fill="#4a4642" />
          <ellipse cx={1500} cy={800} rx={160} ry={120} fill="#4a4642" />
        </g>
      ) : null}
      <rect x={-200} y={880} width={2320} height={420} fill={present ? "#4a4540" : era === "memory" ? "#7a6a58" : "#25232a"} />
      {/* window to the back verandah and the school gate */}
      <rect x={w.x - 12} y={w.y - 12} width={w.w + 24} height={w.h + 24} fill="#3b2a1f" {...ol()} />
      <g>
        <rect x={w.x} y={w.y} width={w.w} height={w.h} fill={era === "memory" ? "#c9cfd8" : present ? "#7d6a6a" : "#0b1020"} />
        {/* verandah railing and pillar */}
        <rect x={w.x} y={w.y + 220} width={w.w} height={14} fill={present ? "#8d8780" : "#2a2e3c"} />
        <rect x={w.x + 40} y={w.y} width={22} height={w.h} fill={present ? "#8d8780" : "#2a2e3c"} />
        {/* school gate beyond */}
        <rect x={w.x + 190} y={w.y + 120} width={180} height={120} fill="none" stroke={present ? "#5a3a2a" : "#1a1d27"} strokeWidth={6} />
        {[...Array(6)].map((_, i) => (
          <line key={i} x1={w.x + 205 + i * 30} x2={w.x + 205 + i * 30} y1={w.y + 120} y2={w.y + 240} stroke={present ? "#5a3a2a" : "#1a1d27"} strokeWidth={4} />
        ))}
        {era === "flood" ? (
          <>
            <Rain frame={frame} seed="roomWin" count={Math.round(80 * rain)} x={w.x} y={w.y} w={w.w} h={w.h} speed={36} len={44} opacity={0.4} />
            <Water frame={frame} y={w.y + 300} x0={w.x} x1={w.x + w.w} dye={0.7} seed="roomWater" />
          </>
        ) : null}
      </g>
      {present ? (
        <path d={`M ${w.x + 220} ${w.y} L ${w.x + 280} ${w.y + 120} L ${w.x + 200} ${w.y + 200} L ${w.x + 320} ${w.y + 260} L ${w.x + 420} ${w.y + 210} L ${w.x + 420} ${w.y} Z`} fill="#000" opacity={0.25} stroke="#c9d0e0" strokeWidth={1.5} />
      ) : null}
      <rect x={w.x + w.w / 2 - 6} y={w.y} width={12} height={w.h} fill="#3b2a1f" />
      {era === "flood" ? <GlassRain frame={frame} x={w.x} y={w.y} w={w.w} h={w.h} count={16} seed="roomGlass" /> : null}
      {/* notice board and wires */}
      {present ? (
        <g>
          {[0, 1, 2, 3].map((i) => (
            <path key={i} d={`M ${820 + i * 60} 250 C ${830 + i * 60} 320 ${800 + i * 60} 360 ${815 + i * 60} ${400 + i * 20}`} stroke={["#a3322b", "#2a2a2a", "#2f6f8f", "#d8b04a"][i]} strokeWidth={4} fill="none" />
          ))}
          <rect x={780} y={230} width={300} height={24} fill="#4a4540" {...ol(1)} />
        </g>
      ) : (
        <g>
          <rect x={780} y={230} width={300} height={24} fill="#4a4540" {...ol(1)} />
          <path d="M 930 254 L 930 720" stroke="#1a1a1a" strokeWidth={3} />
        </g>
      )}
      {/* siren switch box */}
      <g transform={`translate(${R.switch.x} ${R.switch.y})`}>
        <SirenSwitch s={1.1} on={sirenOn} />
        <circle cx={0} cy={-90} r={12} fill={sirenOn > 0.5 && era === "flood" ? "#ff4a3a" : "#4a2020"} {...ol(1)} />
        {sirenOn > 0.5 && era === "flood" ? <Glow id="sirenLamp" cx={0} cy={-90} r={120} color="#ff4a3a" opacity={0.5 * (0.6 + 0.4 * Math.sin(frame * 0.6))} /> : null}
      </g>
      {/* door */}
      <rect x={R.door.x} y={R.door.y} width={R.door.w} height={880 - R.door.y} fill="#3b2a1f" {...ol()} />
      <rect x={R.door.x + 14} y={R.door.y + 14} width={R.door.w - 28} height={880 - R.door.y - 14} fill={era === "flood" ? "#0b0e18" : "#2a2622"} />
      {/* desk */}
      <rect x={R.deskL} y={R.deskTop} width={R.deskR - R.deskL} height={22} fill="#5a3f2c" {...ol()} />
      <rect x={R.deskL + 20} y={R.deskTop + 22} width={R.deskR - R.deskL - 40} height={R.floorY - R.deskTop - 22} fill="#4a3324" {...ol(1.6)} />
      {present ? (
        <ellipse cx={R.machine.x} cy={R.deskTop + 2} rx={70} ry={8} fill="none" stroke="#3a2a1c" strokeWidth={4} opacity={0.8} />
      ) : (
        <g transform={`translate(${R.machine.x} ${R.deskTop})`}>
          <rect x={-80} y={-80} width={160} height={80} rx={6} fill="#2a2a2e" {...ol(1.4)} />
          <circle cx={-40} cy={-40} r={24} fill="#1a1a1a" {...ol(1)} />
          <circle cx={40} cy={-40} r={24} fill="#1a1a1a" {...ol(1)} />
          <g transform={`rotate(${era === "flood" ? frame * 6 : 0} -40 -40)`}>
            <path d="M -40 -60 L -40 -20 M -60 -40 L -20 -40" stroke="#555" strokeWidth={3} />
          </g>
          <g transform={`rotate(${era === "flood" ? frame * 6 : 0} 40 -40)`}>
            <path d="M 40 -60 L 40 -20 M 20 -40 L 60 -40" stroke="#555" strokeWidth={3} />
          </g>
          <circle cx={66} cy={-70} r={4} fill={era === "flood" ? "#e0533c" : "#3a1a1a"} />
        </g>
      )}
      {showMic && !present ? (
        <g transform={`translate(${R.mic.x} ${R.mic.y}) rotate(${micSwing})`}>
          <Microphone s={1.1} />
        </g>
      ) : null}
      {era === "memory" ? <rect x={R.deskL + 60} y={R.deskTop - 50} width={90} height={50} rx={10} fill="#b9bcc0" {...ol(1.4)} /> : null}
      {/* bare bulb */}
      <line x1={1000} y1={-200} x2={1000} y2={150} stroke="#1a1a1a" strokeWidth={2} />
      <circle cx={1000} cy={165} r={16} fill={bulb > 0 ? "#f6d28a" : "#5a5650"} {...ol(1)} />
      {bulb > 0 ? <Glow id={`roomBulb${era}`} cx={1000} cy={200} r={720} color={era === "memory" ? "#fff1c8" : C.amberSoft} opacity={0.32 * bulb * flicker} /> : null}
    </g>
  );
};

// School shelter gate: rusted double gate in a wall; dirt road outside (foreground);
// inside: a courtyard, two rooms and a verandah.
export const GATE = { x: 960, groundY: 1000, gateTop: 470, gateW: 520 };

export const SchoolGate: React.FC<{
  frame: number;
  time: "day" | "dusk" | "night";
  chain?: "locked" | "open" | "none";
  water?: number; // 0..1 flood level (night)
  rain?: number;
  machine?: boolean;
}> = ({ frame, time, chain = "locked", water = 0, rain = 0, machine = false }) => {
  const G = GATE;
  const night = time === "night";
  const sky = night ? "#070b17" : time === "dusk" ? "#4a4870" : "#8b99b8";
  const wall = night ? "#262a38" : time === "dusk" ? "#857a70" : "#b0a48c";
  const iron = night ? "#1a1d27" : "#5a3a2a";
  return (
    <g>
      <rect x={-400} y={-300} width={2720} height={1500} fill={sky} />
      {time === "dusk" ? <rect x={-400} y={300} width={2720} height={300} fill="#b48a74" opacity={0.5} /> : null}
      {/* school building: two rooms and a verandah */}
      <rect x={560} y={330} width={800} height={260} fill={night ? "#1f2333" : "#c9bca2"} {...ol(1.6)} />
      <rect x={540} y={310} width={840} height={30} fill={night ? "#2a2e3c" : "#a39a88"} {...ol(1.4)} />
      {[620, 840, 1080, 1300].map((x) => (
        <rect key={x} x={x - 14} y={340} width={28} height={250} fill={night ? "#2a2e3c" : "#d8cdb4"} {...ol(1.2)} />
      ))}
      <rect x={680} y={400} width={130} height={190} fill={night ? "#0e111b" : "#5a4a3c"} {...ol(1.2)} />
      <rect x={1120} y={400} width={130} height={190} fill={night ? "#0e111b" : "#5a4a3c"} {...ol(1.2)} />
      {/* wall */}
      <rect x={-400} y={560} width={2720} height={G.groundY - 560} fill={wall} {...ol(1.6)} />
      {!night ? <rect x={-400} y={560} width={2720} height={18} fill="#8d8780" /> : null}
      {/* gate opening shows the courtyard */}
      <rect x={G.x - G.gateW / 2} y={G.gateTop + 90} width={G.gateW} height={G.groundY - G.gateTop - 90} fill={night ? "#101420" : "#9a8e78"} />
      <rect x={G.x - G.gateW / 2 - 40} y={G.gateTop} width={40} height={G.groundY - G.gateTop} fill={wall} {...ol(1.6)} />
      <rect x={G.x + G.gateW / 2} y={G.gateTop} width={40} height={G.groundY - G.gateTop} fill={wall} {...ol(1.6)} />
      {/* double gate */}
      {[0, 1].map((k) => (
        <g key={k} transform={`translate(${k ? G.x : G.x - G.gateW / 2} 0)`}>
          <rect x={4} y={G.gateTop + 80} width={G.gateW / 2 - 8} height={G.groundY - G.gateTop - 90} fill="none" stroke={iron} strokeWidth={12} />
          {[...Array(8)].map((_, i) => (
            <line key={i} x1={20 + i * 32} x2={20 + i * 32} y1={G.gateTop + 80} y2={G.groundY - 10} stroke={iron} strokeWidth={8} />
          ))}
          <line x1={4} x2={G.gateW / 2 - 4} y1={G.gateTop + 260} y2={G.gateTop + 260} stroke={iron} strokeWidth={10} />
          {!night ? (
            <g opacity={0.6}>
              <path d={`M 30 ${G.gateTop + 300} l 40 20 l -10 40`} stroke={C.rustLight} strokeWidth={6} fill="none" />
              <path d={`M 160 ${G.gateTop + 150} l 30 20`} stroke={C.rustLight} strokeWidth={6} fill="none" />
            </g>
          ) : null}
        </g>
      ))}
      {/* chain + padlock where the leaves meet */}
      {chain !== "none" ? (
        <g transform={`translate(${G.x} ${G.gateTop + 300})`}>
          {chain === "locked"
            ? [...Array(6)].map((_, i) => <ellipse key={i} cx={-30 + i * 12} cy={(i % 2) * 6} rx={9} ry={6} fill="none" stroke="#56514b" strokeWidth={4} />)
            : [...Array(6)].map((_, i) => <ellipse key={i} cx={20} cy={20 + i * 12} rx={6} ry={9} fill="none" stroke="#56514b" strokeWidth={4} />)}
          <g transform={chain === "locked" ? "translate(36 16)" : "translate(20 96)"}>
            <Padlock s={1.1} open={chain === "open"} />
          </g>
        </g>
      ) : null}
      {/* dirt road outside */}
      <rect x={-400} y={G.groundY} width={2720} height={400} fill={night ? "#15161f" : "#7a6a52"} />
      {!night ? [...Array(8)].map((_, i) => <ellipse key={i} cx={-200 + i * 330} cy={1050 + (i % 2) * 30} rx={60} ry={6} fill="#6a5a44" />) : null}
      {machine ? (
        <g transform="translate(1600 1000)">
          <rect x={-180} y={-150} width={300} height={120} fill="#d8a83a" {...ol(1.6)} />
          <rect x={-120} y={-240} width={140} height={100} fill="#d8a83a" {...ol(1.6)} />
          <rect x={-106} y={-226} width={110} height={60} fill="#3a4256" />
          <circle cx={-120} cy={-20} r={40} fill="#2a2a2a" {...ol(1.4)} />
          <circle cx={60} cy={-20} r={40} fill="#2a2a2a" {...ol(1.4)} />
          <path d="M 120 -120 L 260 -220 L 320 -120" stroke="#c9982a" strokeWidth={18} fill="none" />
          <path d="M 300 -120 L 360 -60 L 280 -40 Z" fill="#8a8a8a" {...ol(1.2)} />
        </g>
      ) : null}
      {water > 0 ? <Water frame={frame} y={G.groundY - water * 200} dye={0.8} seed="gateWater" /> : null}
      {rain > 0 ? <Rain frame={frame} seed="gateRain" count={Math.round(240 * rain)} x={-400} y={-300} w={2720} h={1500} opacity={0.32 * rain} /> : null}
      {night ? <Glow id="gateFar" cx={300} cy={420} r={260} color={C.amber} opacity={0.25} /> : null}
    </g>
  );
};

/** Narrow lane on the flood night (water level 0..1). */
export const FloodLane: React.FC<{ frame: number; water: number; rain?: number; light?: number }> = ({ frame, water, rain = 1, light = 1 }) => (
  <g>
    <rect x={-400} y={-300} width={2720} height={1500} fill="#060914" />
    {[...Array(5)].map((_, i) => (
      <g key={i}>
        <rect x={-380 + i * 520} y={240 - (i % 2) * 40} width={420} height={700} fill={["#141a2b", "#171c2e", "#121727"][i % 3]} {...ol(1.4)} />
        <path d={`M ${-390 + i * 520} ${240 - (i % 2) * 40} L ${-170 + i * 520} ${150 - (i % 2) * 40} L ${50 + i * 520} ${240 - (i % 2) * 40} Z`} fill="#1d1a22" {...ol(1.2)} />
        <rect x={-300 + i * 520} y={420} width={90} height={110} fill="#0a0d16" {...ol(1)} />
      </g>
    ))}
    {light > 0 ? <Glow id="laneLight" cx={1700} cy={560} r={520} color={C.amber} opacity={Math.min(0.65, 0.3 * light)} /> : null}
    <rect x={-400} y={900} width={2720} height={500} fill="#10131c" />
    <Water frame={frame} y={1000 - water * 260} dye={0.75} seed="laneW" />
    <Rain frame={frame} seed="laneRain" count={Math.round(300 * rain)} x={-400} y={-300} w={2720} h={1500} opacity={0.36 * rain} />
  </g>
);
