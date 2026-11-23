import React from "react";
import { random } from "remotion";
import { Glow } from "../fx/fx";
import { INK } from "../rigs/Head";
import { C } from "../style/palette";
import { Handwriting, Scribble } from "../props/Props";
import { VikramPoster } from "./Factory";

const ol = (w = 2) => ({ stroke: INK, strokeWidth: w, vectorEffect: "non-scaling-stroke" as const });

// Vikram's office: bright, white, a big window; desk centre; the market model on a
// side table at the left.
export const OFFICE = { floorY: 1000, deskTop: 700, deskL: 760, deskR: 1460, model: { x: 330, y: 760 } };

export const VikramOffice: React.FC = () => (
  <g>
    <rect x={-300} y={-300} width={2520} height={1500} fill="#d9d6ce" />
    <rect x={620} y={120} width={980} height={440} fill="#9fb0c8" {...ol(1.6)} />
    {[...Array(9)].map((_, i) => (
      <rect key={i} x={660 + i * 104} y={300 + (i % 3) * 30} width={70} height={260 - (i % 3) * 30} fill={["#7a8aa4", "#8a98b0", "#6d7d98"][i % 3]} />
    ))}
    <rect x={1100} y={120} width={14} height={440} fill="#c9c6be" />
    <rect x={620} y={330} width={980} height={10} fill="#c9c6be" />
    <rect x={-300} y={880} width={2520} height={420} fill="#b9b2a4" />
    <rect x={1700} y={200} width={160} height={110} fill="#e9e6de" {...ol(1.2)} />
    <rect x={1720} y={220} width={120} height={70} fill="#c9a96a" />
    <rect x={1690} y={380} width={180} height={130} fill="#3a3e4c" {...ol(1.2)} />
    <rect x={1700} y={390} width={160} height={110} fill="#c9a96a" opacity={0.6} />
    {/* desk */}
    <rect x={OFFICE.deskL} y={OFFICE.deskTop} width={OFFICE.deskR - OFFICE.deskL} height={26} fill="#3a2a22" {...ol()} />
    <rect x={OFFICE.deskL + 20} y={OFFICE.deskTop + 26} width={OFFICE.deskR - OFFICE.deskL - 40} height={OFFICE.floorY - OFFICE.deskTop - 26} fill="#2e221b" {...ol(1.6)} />
    <rect x={1300} y={OFFICE.deskTop - 40} width={110} height={40} fill="#e9e6de" {...ol(1.2)} />
    {/* side table with market model */}
    <rect x={100} y={OFFICE.model.y} width={460} height={20} fill="#3a2a22" {...ol(1.6)} />
    <rect x={130} y={OFFICE.model.y + 20} width={18} height={220} fill="#2e221b" />
    <rect x={512} y={OFFICE.model.y + 20} width={18} height={220} fill="#2e221b" />
    <g transform={`translate(${OFFICE.model.x} ${OFFICE.model.y})`}>
      <MarketModel s={1} />
    </g>
    <Glow id="officeWin" cx={1100} cy={340} r={700} color="#ffffff" opacity={0.25} />
  </g>
);

/** The new-market model: white blocks, green trees, clean road, and a glass door where the gate was. */
export const MarketModel: React.FC<{ s: number }> = ({ s }) => (
  <g transform={`scale(${s})`}>
    <path d="M -220 0 L 220 0 L 180 -60 L -180 -60 Z" fill="#9aa29a" {...ol(1.2)} />
    <rect x={-170} y={-130} width={150} height={74} fill="#f3f1ea" {...ol(1.2)} />
    <rect x={10} y={-150} width={150} height={94} fill="#f3f1ea" {...ol(1.2)} />
    {[...Array(5)].map((_, i) => (
      <rect key={i} x={-160 + i * 28} y={-120} width={16} height={12} fill="#b8c6d8" />
    ))}
    {/* the glass door, at the spot of the school gate */}
    <rect x={60} y={-110} width={44} height={54} fill="#a9d0e0" opacity={0.85} {...ol(1.2)} />
    <line x1={82} x2={82} y1={-110} y2={-56} stroke="#e9f4fa" strokeWidth={2} />
    {[-200, -110, 190].map((x) => (
      <g key={x}>
        <rect x={x - 2} y={-40} width={4} height={18} fill="#6b4f3a" />
        <circle cx={x} cy={-46} r={14} fill="#5a8a4a" {...ol(1)} />
      </g>
    ))}
    <rect x={-120} y={-36} width={24} height={12} rx={3} fill="#f8f8f8" {...ol(0.8)} />
    <rect x={-60} y={-30} width={24} height={12} rx={3} fill="#f8f8f8" {...ol(0.8)} />
    <rect x={120} y={-34} width={24} height={12} rx={3} fill="#f8f8f8" {...ol(0.8)} />
    <path d="M -200 -20 L 200 -20" stroke="#e8e6de" strokeWidth={3} strokeDasharray="10 8" />
  </g>
);

// Memorial courtyard: the yard of the same factory office. Stage with marigolds,
// a stone with seventeen names, plastic chairs, speakers on poles.
export const MEMORIAL = { floorY: 1000, stageY: 760, stageL: 520, stageR: 1400, stone: { x: 1640, y: 760 }, micX: 960, boxX: 1300 };

export const MemorialStone: React.FC<{ s: number; highlight?: number }> = ({ s, highlight = 0 }) => (
  <g transform={`scale(${s})`}>
    <path d="M -110 0 L -110 -300 Q 0 -350 110 -300 L 110 0 Z" fill="#8a8680" {...ol(1.8)} />
    <path d="M -110 0 L -110 -300 Q -60 -330 -30 -340 L -40 0 Z" fill="#6f6b66" opacity={0.5} />
    {[...Array(16)].map((_, i) => (
      <Scribble key={i} x={-80} y={-280 + i * 16} w={100 + (i % 3) * 30} h={6} seed={100 + i} color="#3a3834" width={1.4} />
    ))}
    <text x={-30} y={-14} fontSize={26} fontFamily="NotoDeva, sans-serif" fill="#2a2824" fontWeight={600}>
      अंशु
    </text>
    {highlight > 0 ? <rect x={-40} y={-40} width={90} height={36} fill="#f3c779" opacity={0.25 * highlight} /> : null}
    <rect x={-130} y={0} width={260} height={24} fill="#7a7670" {...ol(1.4)} />
  </g>
);

export const MemorialYard: React.FC<{ frame: number; posters?: boolean }> = ({ frame, posters = true }) => {
  const M = MEMORIAL;
  return (
    <g>
      <rect x={-400} y={-300} width={2720} height={1500} fill="#9aa6c0" />
      {/* office building behind, with the announcement-room window */}
      <rect x={300} y={200} width={1300} height={460} fill="#8d8780" {...ol(1.6)} />
      <rect x={420} y={300} width={180} height={140} fill="#3a3e4c" {...ol(1.2)} />
      <rect x={1300} y={300} width={180} height={140} fill="#3a3e4c" {...ol(1.2)} />
      {posters ? <VikramPoster x={760} y={290} s={0.8} /> : null}
      {/* shamiana canopy */}
      <path d="M -200 160 L 2120 160 L 2120 240 L -200 240 Z" fill="#c46a2a" opacity={0.9} {...ol(1.2)} />
      {[...Array(24)].map((_, i) => (
        <path key={i} d={`M ${-200 + i * 100} 240 l 50 34 l 50 -34`} fill={i % 2 ? "#e8c060" : "#7a2f3a"} {...ol(1)} />
      ))}
      {[-160, 2080].map((x) => (
        <rect key={x} x={x} y={160} width={16} height={840} fill="#6b4f3a" />
      ))}
      {/* stage */}
      <rect x={M.stageL} y={M.stageY - 110} width={M.stageR - M.stageL} height={110} fill="#5a3f2c" {...ol(1.6)} />
      <rect x={M.stageL - 10} y={M.stageY - 124} width={M.stageR - M.stageL + 20} height={16} fill="#e9e1cf" {...ol(1.2)} />
      {[...Array(18)].map((_, i) => (
        <circle key={i} cx={M.stageL + 20 + i * 48} cy={M.stageY - 104} r={12} fill={i % 2 ? "#e8a03a" : "#f0c040"} {...ol(1)} />
      ))}
      {/* speakers on poles */}
      {[140, 1780].map((x) => (
        <g key={x}>
          <rect x={x - 6} y={300} width={12} height={700} fill="#3a3530" />
          <rect x={x - 40} y={300} width={80} height={110} rx={6} fill="#2a2b30" {...ol(1.4)} />
          <circle cx={x} cy={355} r={26} fill="#151515" />
        </g>
      ))}
      <g transform={`translate(${M.stone.x} ${M.stone.y})`}>
        <MemorialStone s={1} />
      </g>
      <rect x={-400} y={M.stageY} width={2720} height={600} fill="#a39a88" />
      {/* mic box (amplifier) */}
      <g transform={`translate(${M.boxX} ${M.stageY - 124})`}>
        <rect x={-60} y={-60} width={120} height={60} rx={6} fill="#2a2b30" {...ol(1.4)} />
        <circle cx={-30} cy={-30} r={8} fill="#888" />
        <circle cx={0} cy={-30} r={8} fill="#888" />
        <circle cx={30} cy={-30} r={4} fill={random(`box${Math.floor(frame / 12)}`) > 0.5 ? "#7ad06a" : "#3a6a3a"} />
      </g>
    </g>
  );
};

// Lane / roadside by day.
export const Roadside: React.FC<{ frame: number; dusk?: boolean }> = ({ dusk = false }) => (
  <g>
    <rect x={-400} y={-300} width={2720} height={1500} fill={dusk ? "#6a6a8a" : "#a7b2c8"} />
    {[...Array(6)].map((_, i) => (
      <g key={i}>
        <rect x={-380 + i * 460} y={260 + (i % 2) * 40} width={420} height={620} fill={["#b7a88f", "#a39a88", "#c2b49a"][i % 3]} {...ol(1.4)} />
        <rect x={-340 + i * 460} y={360} width={110} height={130} fill="#5a6278" {...ol(1)} />
        <rect x={-180 + i * 460} y={560} width={150} height={320} fill="#5a4030" {...ol(1.2)} />
        <path d={`M ${-390 + i * 460} ${520} L ${50 + i * 460} ${520} L ${30 + i * 460} ${560} L ${-370 + i * 460} ${560} Z`} fill={["#3f5a3a", "#7a2f3a", "#2f5a6b"][i % 3]} opacity={0.8} {...ol(1)} />
      </g>
    ))}
    <rect x={-400} y={880} width={2720} height={500} fill={dusk ? "#5a5650" : "#8a8172"} />
    <rect x={-400} y={880} width={2720} height={30} fill="#9a9182" />
    <ellipse cx={600} cy={1040} rx={200} ry={14} fill="#7a7466" opacity={0.6} />
  </g>
);

/** Newspaper with a question-mark headline (text illegible except punctuation). */
export const Newspaper: React.FC<{ s: number; seed: number }> = ({ s, seed }) => (
  <g transform={`scale(${s})`}>
    <rect x={-200} y={-260} width={400} height={520} fill="#e8e3d6" {...ol(1.4)} />
    <rect x={-180} y={-240} width={360} height={30} fill="#2a2a2a" />
    <Scribble x={-170} y={-170} w={300} h={22} seed={seed} color="#1a1a1a" width={5} />
    <text x={150} y={-150} fontSize={56} fill="#1a1a1a" fontWeight={700}>
      ?
    </text>
    <rect x={-170} y={-120} width={160} height={120} fill="#9a9a9a" />
    {[...Array(12)].map((_, i) => (
      <Scribble key={i} x={i < 5 ? 0 : -170} y={-110 + i * 26} w={i < 5 ? 170 : 340} h={8} seed={seed + i + 1} color="#555" width={1.2} />
    ))}
  </g>
);

/** Government office desk where statements are recorded (aftermath). */
export const StatementDesk: React.FC = () => (
  <g>
    <rect x={-300} y={-300} width={2520} height={1500} fill="#a8ae9e" />
    <rect x={-300} y={860} width={2520} height={440} fill="#6e6a5e" />
    <rect x={1300} y={160} width={300} height={360} fill="#5a6248" {...ol(1.2)} />
    {[...Array(4)].map((_, i) => (
      <rect key={i} x={1320} y={180 + i * 84} width={260} height={70} fill="#c9b994" {...ol(1)} />
    ))}
    <line x1={900} y1={-300} x2={900} y2={60} stroke="#2a2a2a" strokeWidth={4} />
    <g transform="translate(900 70)">
      <circle r={16} fill="#3a3a3a" />
      {[0, 120, 240].map((a) => (
        <ellipse key={a} cx={0} cy={-70} rx={18} ry={70} fill="#5a5a5a" opacity={0.7} transform={`rotate(${a})`} />
      ))}
    </g>
    <rect x={500} y={680} width={900} height={26} fill="#5a3f2c" {...ol(1.6)} />
    <rect x={520} y={706} width={860} height={300} fill="#4a3324" {...ol(1.4)} />
    {[0, 1, 2].map((i) => (
      <rect key={i} x={560 + i * 30} y={640 - i * 14} width={240} height={40} fill={["#c9b994", "#d8c79c", "#b9a77f"][i]} {...ol(1)} />
    ))}
  </g>
);

/** Top-down table with files from many families (S21-03). n = how many have arrived. */
export const FilesTable: React.FC<{ n: number }> = ({ n }) => (
  <g>
    <rect x={-300} y={-300} width={2520} height={1500} fill="#5a3f2c" />
    {[...Array(9)].map((_, i) => (
      <line key={i} x1={-300} x2={2220} y1={i * 140} y2={i * 140 + 20} stroke="#4a3324" strokeWidth={3} />
    ))}
    {[...Array(16)].map((_, i) => {
      const show = i < n;
      const x = 300 + (i % 6) * 230 + random(`ft${i}`) * 40;
      const y = 200 + Math.floor(i / 6) * 280 + random(`fty${i}`) * 40;
      return show ? (
        <g key={i} transform={`translate(${x} ${y}) rotate(${(random(`ftr${i}`) - 0.5) * 16})`}>
          <rect x={-90} y={-120} width={180} height={240} fill={["#c9b994", "#e8e1cf", "#b9a77f", "#d8c79c"][i % 4]} {...ol(1.2)} />
          <Scribble x={-70} y={-80} w={140} h={8} seed={200 + i} color="#3a3a3a" width={1.2} />
          <Scribble x={-70} y={-50} w={120} h={8} seed={220 + i} color="#3a3a3a" width={1.2} />
          <Scribble x={-70} y={-20} w={130} h={8} seed={240 + i} color="#3a3a3a" width={1.2} />
        </g>
      ) : null;
    })}
    <g transform="translate(960 560)">
      <rect x={-120} y={-160} width={240} height={320} fill="#ece4cf" {...ol(1.4)} />
      <Handwriting x={-90} y={-110} size={30} text="जाँच" color="#2a2a2a" rot={0} />
      {[...Array(7)].map((_, i) => (
        <Scribble key={i} x={-90} y={-60 + i * 30} w={170} h={8} seed={300 + i} color="#3a3a3a" width={1.2} />
      ))}
    </g>
    <Glow id="filesLamp" cx={960} cy={540} r={800} color={C.amberSoft} opacity={0.2} />
  </g>
);
