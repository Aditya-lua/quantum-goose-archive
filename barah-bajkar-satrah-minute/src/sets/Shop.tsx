import React from "react";
import { random } from "remotion";
import { Glow, GlassRain, Rain } from "../fx/fx";
import { INK } from "../rigs/Head";
import { C } from "../style/palette";
import { Handwriting } from "../props/Props";

const ol = (w = 2) => ({ stroke: INK, strokeWidth: w, vectorEffect: "non-scaling-stroke" as const });

// Kabir's shop. Glass storefront on the left with a rolling shutter over the door
// (door at its right end); counter centre; shelves of old radios; his father's photo.
export const SHOP = {
  floorY: 1000,
  counterTop: 760,
  counterL: 760,
  counterR: 1560,
  front: { x: 0, w: 720, top: 170, bottom: 880 },
  door: { x: 500, w: 220 },
  photo: { x: 1690, y: 330 },
  lamp: { x: 1480, y: 760 },
  customerX: 640,
  kabirX: 1280,
};

/** Hanging phone covers behind the glass. */
const Covers: React.FC = () => (
  <g>
    {[...Array(14)].map((_, i) => {
      const x = 40 + i * 32;
      const y = 220 + (i % 3) * 18;
      return (
        <g key={i}>
          <line x1={x + 9} y1={180} x2={x + 9} y2={y} stroke="#555" strokeWidth={1} />
          <rect x={x} y={y} width={18} height={34} rx={4} fill={["#a3322b", "#2f6f8f", "#d8b04a", "#6b4f8a", "#3f7a5a", "#e0e0e0"][i % 6]} {...ol(1)} />
        </g>
      );
    })}
  </g>
);

export const ShopInterior: React.FC<{ frame: number; shutter?: number; rain?: number; lamp?: number; layer?: "back" | "front" | "all" }> = ({ frame, shutter = 0, rain = 1, lamp = 1, layer = "all" }) => {
  const S = SHOP;
  const fr = S.front;
  return (
    <g>
      <g display={layer === "front" ? "none" : undefined}>
      <defs>
        <linearGradient id="shopWall" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#2b3048" />
          <stop offset="1" stopColor="#3c4156" />
        </linearGradient>
        <clipPath id="shopGlass">
          <rect x={fr.x + 20} y={fr.top + 20} width={fr.w - 40} height={fr.bottom - fr.top - 40} />
        </clipPath>
      </defs>
      <rect x={-200} y={-200} width={2320} height={1100} fill="url(#shopWall)" />
      <rect x={-200} y={880} width={2320} height={400} fill="#2a2622" />
      {[...Array(8)].map((_, i) => (
        <line key={i} x1={-200 + i * 300} y1={880} x2={-400 + i * 360} y2={1280} stroke="#1e1a16" strokeWidth={2} />
      ))}
      {/* storefront glass: the rainy bazaar outside */}
      <rect x={fr.x} y={fr.top} width={fr.w} height={fr.bottom - fr.top} fill="#3b2a1f" {...ol()} />
      <rect x={fr.x + 20} y={fr.top + 20} width={fr.w - 40} height={fr.bottom - fr.top - 40} fill="#0d1324" />
      <g clipPath="url(#shopGlass)">
        <rect x={0} y={560} width={720} height={340} fill="#151a2a" />
        {[0, 1, 2].map((i) => (
          <g key={i}>
            <rect x={60 + i * 230} y={430} width={180} height={140} fill="#1b2136" {...ol(1)} />
            <rect x={70 + i * 230} y={470} width={160} height={90} fill={C.amber} opacity={0.3 + 0.15 * i} />
            <Glow id={`shopOut${i}`} cx={150 + i * 230} cy={500} r={140} color={C.amber} opacity={0.35} />
          </g>
        ))}
        <ellipse cx={300} cy={760} rx={300} ry={30} fill={C.amber} opacity={0.12} />
        <Rain frame={frame} seed="shopOutRain" count={Math.round(90 * rain)} x={0} y={160} w={720} h={740} speed={40} len={50} opacity={0.3 * rain} />
        <GlassRain frame={frame} x={fr.x + 20} y={fr.top + 20} w={fr.w - 40} h={fr.bottom - fr.top - 40} count={Math.round(18 * rain)} seed="shopGlassRain" />
      </g>
      <Covers />
      <rect x={S.door.x - 8} y={fr.top} width={16} height={fr.bottom - fr.top} fill="#3b2a1f" />
      {/* rolling shutter over the door, pulled down by `shutter` (0..1) */}
      <g>
        <rect x={S.door.x} y={fr.top - 40} width={S.door.w} height={40} fill="#5a5d64" {...ol(1.4)} />
        <rect x={S.door.x} y={fr.top} width={S.door.w} height={(fr.bottom - fr.top) * shutter * 0.5} fill="#6b6e75" {...ol(1.4)} />
        {[...Array(Math.floor(((fr.bottom - fr.top) * shutter * 0.5) / 14))].map((_, i) => (
          <line key={i} x1={S.door.x} x2={S.door.x + S.door.w} y1={fr.top + 14 * (i + 1)} y2={fr.top + 14 * (i + 1)} stroke="#4a4c52" strokeWidth={2} />
        ))}
        {shutter > 0 ? <rect x={S.door.x + S.door.w / 2 - 20} y={fr.top + (fr.bottom - fr.top) * shutter * 0.5 - 14} width={40} height={10} rx={3} fill="#2a2a2a" /> : null}
      </g>
      {/* back shelves with old radios and boxes */}
      {[300, 470].map((y, r) => (
        <g key={y}>
          <rect x={800} y={y} width={760} height={14} fill="#4a3324" {...ol(1.4)} />
          {[...Array(6)].map((_, i) => {
            const x = 820 + i * 122;
            const kind = (i + r) % 3;
            return kind === 0 ? (
              <g key={i}>
                <rect x={x} y={y - 78} width={104} height={78} rx={8} fill={["#6b4a33", "#5a5048", "#7a5a43"][i % 3]} {...ol(1.2)} />
                <rect x={x + 8} y={y - 66} width={50} height={50} rx={4} fill="#c9b994" {...ol(1)} />
                <circle cx={x + 80} cy={y - 40} r={11} fill="#2a2420" {...ol(1)} />
              </g>
            ) : kind === 1 ? (
              <g key={i}>
                <rect x={x} y={y - 62} width={96} height={62} fill="#8a6a46" {...ol(1.2)} />
                <line x1={x} x2={x + 96} y1={y - 31} y2={y - 31} stroke="#6b5236" strokeWidth={2} />
              </g>
            ) : (
              <g key={i}>
                <rect x={x} y={y - 70} width={100} height={70} rx={6} fill="#2a2b30" {...ol(1.2)} />
                <rect x={x + 10} y={y - 60} width={64} height={46} rx={10} fill="#3b4258" />
              </g>
            );
          })}
        </g>
      ))}
      {/* old painted word above the shelves: what the shop used to be */}
      <Handwriting x={1000} y={170} size={64} text="रेडियो" color="#6c6650" rot={0} opacity={0.35} />
      {/* his father's photograph */}
      <g transform={`translate(${S.photo.x} ${S.photo.y})`}>
        <rect x={-72} y={-92} width={144} height={184} fill="#3b2a1f" {...ol(1.6)} />
        <rect x={-58} y={-78} width={116} height={156} fill="#b9a27c" />
        <circle cx={0} cy={-26} r={24} fill="#6e5236" />
        <path d="M -16 -48 C -10 -58 12 -58 18 -46 L 18 -38 C 8 -44 -8 -44 -18 -36 Z" fill="#2c241e" />
        <path d="M -40 78 L -36 22 C -30 6 30 6 36 22 L 40 78 Z" fill="#7a6a54" />
        <rect x={-30} y={34} width={60} height={34} rx={5} fill="#5a4030" {...ol(1)} />
        <circle cx={16} cy={51} r={7} fill="#2a2420" />
        <path d="M -58 -78 L 58 -78 L 58 78 L -58 78 Z" fill="#a37a42" opacity={0.25} />
        <path d="M -36 -100 L 0 -120 L 36 -100" fill="none" stroke="#2a2420" strokeWidth={2} />
      </g>
      </g>
      <g display={layer === "back" ? "none" : undefined}>
      {/* counter */}
      <rect x={S.counterL} y={S.counterTop} width={S.counterR - S.counterL} height={22} fill="#5a3f2c" {...ol()} />
      <rect x={S.counterL + 10} y={S.counterTop + 22} width={S.counterR - S.counterL - 20} height={S.floorY - S.counterTop - 22} fill="#4a3324" {...ol(1.6)} />
      <rect x={S.counterL + 40} y={S.counterTop + 60} width={S.counterR - S.counterL - 80} height={200} fill="#3e2b1f" opacity={0.6} />
      {/* tools on the counter */}
      <rect x={1380} y={S.counterTop - 8} width={90} height={8} fill="#a3322b" />
      <path d={`M 1300 ${S.counterTop - 6} L 1360 ${S.counterTop - 20}`} stroke="#c9c2b0" strokeWidth={4} />
      {/* bench lamp */}
      <g transform={`translate(${S.lamp.x} ${S.lamp.y})`}>
        <ellipse cx={0} cy={0} rx={30} ry={7} fill="#2e3036" {...ol(1.2)} />
        <path d="M 0 0 L 18 -120 L -40 -160" stroke="#3a3d44" strokeWidth={6} fill="none" />
        <path d="M -30 -180 L -80 -150 L -64 -118 L -16 -146 Z" fill="#4a4e58" {...ol(1.2)} />
      </g>
      {lamp > 0 ? (
        <>
          <Glow id="shopLamp" cx={S.lamp.x - 70} cy={S.counterTop} r={340} color={C.amberSoft} opacity={0.4 * lamp} />
          <Glow id="shopLampHi" cx={S.lamp.x - 60} cy={S.lamp.y - 150} r={160} color={C.amberSoft} opacity={0.3 * lamp} />
        </>
      ) : null}
      </g>
    </g>
  );
};

/** Customer stool. */
export const Stool: React.FC<{ s?: number }> = ({ s = 1 }) => (
  <g transform={`scale(${s})`}>
    <rect x={-56} y={-155} width={112} height={16} rx={4} fill="#5a3f2c" {...ol(1.4)} />
    <path d="M -48 -140 L -60 0 M 48 -140 L 60 0 M -40 -60 L 40 -60" stroke="#4a3324" strokeWidth={10} />
  </g>
);

// Rainy bazaar at night; Kabir's shop front with the faded word «रेडियो».
export const Bazaar: React.FC<{ frame: number; rain?: number }> = ({ frame, rain = 1 }) => (
  <g>
    <rect x={-400} y={-300} width={2720} height={1500} fill="#0b1020" />
    {[...Array(7)].map((_, i) => {
      const x = -300 + i * 380;
      const lit = random(`bz${i}`) > 0.3;
      return (
        <g key={i}>
          <rect x={x} y={250 + (i % 2) * 30} width={360} height={600} fill={["#1f2438", "#262a3c", "#1c2033"][i % 3]} {...ol(1.4)} />
          <path d={`M ${x - 10} ${420 + (i % 2) * 20} L ${x + 370} ${420 + (i % 2) * 20} L ${x + 340} ${470 + (i % 2) * 20} L ${x + 20} ${470 + (i % 2) * 20} Z`} fill={["#7a2f3a", "#2f5a6b", "#6b5a2f", "#3f5a3a"][i % 4]} opacity={0.85} {...ol(1.2)} />
          <rect x={x + 30} y={500} width={300} height={280} fill={lit ? "#3a2a1c" : "#151826"} />
          {lit ? <Glow id={`bzG${i}`} cx={x + 180} cy={620} r={220} color={C.amber} opacity={0.4} /> : null}
          {i === 3 ? (
            <g>
              <Handwriting x={x + 70} y={370} size={54} text="रेडियो" color="#a69c84" rot={0} opacity={0.55} />
              <rect x={x + 40} y={505} width={280} height={270} fill="#0f1526" opacity={0.5} />
              {[...Array(9)].map((_, k) => (
                <rect key={k} x={x + 50 + k * 30} y={520 + (k % 2) * 14} width={18} height={32} rx={4} fill={["#a3322b", "#2f6f8f", "#d8b04a", "#6b4f8a"][k % 4]} />
              ))}
            </g>
          ) : null}
        </g>
      );
    })}
    <rect x={-400} y={850} width={2720} height={500} fill="#141826" />
    {[...Array(6)].map((_, i) => (
      <ellipse key={i} cx={-200 + i * 420} cy={930 + (i % 2) * 50} rx={160} ry={14} fill={C.amber} opacity={0.12} />
    ))}
    <Rain frame={frame} seed="bazaarRain" count={Math.round(260 * rain)} x={-400} y={-300} w={2720} h={1500} opacity={0.32 * rain} />
  </g>
);

// Delhi: Meera's small restoration studio at night.
export const DelhiStudio: React.FC<{ frame: number }> = ({ frame }) => (
  <g>
    <rect x={-200} y={-200} width={2320} height={1500} fill="#151a2b" />
    <rect x={120} y={140} width={560} height={420} fill="#0b0f1d" {...ol(1.6)} />
    {[...Array(30)].map((_, i) => (
      <rect key={i} x={140 + (i * 53) % 520} y={420 + ((i * 37) % 120)} width={6} height={6} fill={C.amberSoft} opacity={0.3 + random(`dl${i}`) * 0.5} />
    ))}
    <rect x={-200} y={820} width={2320} height={500} fill="#1d1d24" />
    <rect x={540} y={700} width={1200} height={26} fill="#2e2f36" {...ol(1.6)} />
    <rect x={580} y={726} width={20} height={300} fill="#24252b" />
    <rect x={1680} y={726} width={20} height={300} fill="#24252b" />
    {/* speakers */}
    <rect x={600} y={540} width={90} height={160} rx={8} fill="#202127" {...ol(1.4)} />
    <circle cx={645} cy={650} r={30} fill="#111" />
    <rect x={1590} y={540} width={90} height={160} rx={8} fill="#202127" {...ol(1.4)} />
    <circle cx={1635} cy={650} r={30} fill="#111" />
    {/* monitors */}
    {[0, 1].map((i) => (
      <g key={i} transform={`translate(${880 + i * 360} 470)`}>
        <rect x={-160} y={-110} width={320} height={200} rx={6} fill="#1a1b20" {...ol(1.6)} />
        <rect x={-150} y={-100} width={300} height={180} fill="#0e1a2e" />
        {[...Array(50)].map((_, k) => {
          const a = Math.abs(Math.sin(k * 0.7 + i * 3) * 0.6 + Math.sin(k * 0.23 + frame * 0.01) * 0.3) * 60;
          return <line key={k} x1={-145 + k * 6} x2={-145 + k * 6} y1={-10 - a} y2={-10 + a} stroke={i ? "#e8a54b" : "#6fc3c9"} strokeWidth={3} />;
        })}
        <rect x={-10} y={90} width={20} height={50} fill="#2a2b30" />
      </g>
    ))}
    <Glow id="delhiScreen" cx={1060} cy={470} r={500} color="#6fc3c9" opacity={0.12} />
    {/* mixing console */}
    <rect x={820} y={670} width={480} height={30} fill="#33343b" {...ol(1.4)} />
    {[...Array(12)].map((_, k) => (
      <rect key={k} x={836 + k * 38} y={674} width={6} height={20} fill="#c9c2b0" />
    ))}
  </g>
);
