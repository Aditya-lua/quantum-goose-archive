import React from "react";
import { INK } from "./Head";

// Detailed hand for insert shots. Local space: wrist at origin, fingers toward -y,
// palm width ~100 units. Right hand seen from the back; mirror with scale(-1,1).
export type BigHandPose = {
  curl?: [number, number, number, number, number]; // thumb, index, middle, ring, pinky (0 straight .. 1 curled)
  spread?: number; // 0..1
  tremble?: number; // px amplitude applied by caller
};

const FINGERS = [
  { x: -36, len: 108, w: 22, ang: -7 }, // index (screen-left for a right hand seen from back)
  { x: -12, len: 120, w: 23, ang: -2 },
  { x: 12, len: 112, w: 22, ang: 3 },
  { x: 33, len: 90, w: 19, ang: 9 },
];

export const BigHand: React.FC<{
  skin: string;
  shade: string;
  pose?: BigHandPose;
  sleeve?: string;
  sleeveShade?: string;
  watch?: boolean;
  bangles?: string;
}> = ({ skin, shade, pose = {}, sleeve, sleeveShade, watch, bangles }) => {
  const curl = pose.curl ?? [0.2, 0.15, 0.2, 0.25, 0.3];
  const spread = pose.spread ?? 0.2;
  const st = { stroke: INK, strokeWidth: 2, vectorEffect: "non-scaling-stroke" as const };
  const finger = (f: (typeof FINGERS)[number], c: number, i: number) => {
    const ang = f.ang * (1 + spread * 2.2);
    // proximal segment shortens as the finger curls toward the viewer/palm
    const l1 = f.len * 0.55 * (1 - c * 0.35);
    const l2 = f.len * 0.48 * (1 - c * 0.75);
    const bend = c * 70;
    return (
      <g key={i} transform={`translate(${f.x} -60) rotate(${ang})`}>
        <path d={`M ${-f.w / 2} 10 L ${-f.w / 2} ${-l1} L ${f.w / 2} ${-l1} L ${f.w / 2} 10 Z`} fill={skin} {...st} />
        <g transform={`translate(0 ${-l1}) rotate(${bend * 0.25})`}>
          <path d={`M ${-f.w / 2 + 1} 4 L ${-f.w / 2 + 1.5} ${-l2 + f.w * 0.45} Q 0 ${-l2 - f.w * 0.25} ${f.w / 2 - 1.5} ${-l2 + f.w * 0.45} L ${f.w / 2 - 1} 4 Z`} fill={c > 0.6 ? shade : skin} {...st} />
          {c < 0.6 ? <path d={`M ${-f.w * 0.28} ${-l2 + f.w * 0.65} Q 0 ${-l2 - f.w * 0.05} ${f.w * 0.28} ${-l2 + f.w * 0.65} L ${f.w * 0.24} ${-l2 + f.w * 1.05} L ${-f.w * 0.24} ${-l2 + f.w * 1.05} Z`} fill="#e4c3a8" opacity={0.75} /> : null}
          <path d={`M ${-f.w * 0.3} 0 Q 0 -4 ${f.w * 0.3} 0`} stroke={shade} strokeWidth={1.2} fill="none" vectorEffect="non-scaling-stroke" />
        </g>
        <path d={`M ${-f.w * 0.3} -6 Q 0 -10 ${f.w * 0.3} -6`} stroke={shade} strokeWidth={1.2} fill="none" vectorEffect="non-scaling-stroke" />
      </g>
    );
  };
  const thumbC = curl[0];
  return (
    <g>
      {sleeve ? (
        <path d="M -80 700 L -58 40 L 58 40 L 82 700 Z" fill={sleeve} {...st} />
      ) : null}
      {sleeveShade && sleeve ? <path d="M -80 700 L -58 40 L -30 40 L -40 700 Z" fill={sleeveShade} opacity={0.8} /> : null}
      {/* wrist */}
      <path d="M -40 60 L -46 -10 L 46 -10 L 40 60 Z" fill={skin} {...st} />
      {watch ? (
        <g>
          <rect x={-46} y={22} width={92} height={18} rx={6} fill="#1b1b1d" {...st} />
          <rect x={-18} y={14} width={36} height={34} rx={7} fill="#2a2b2e" {...st} />
          <circle cx={0} cy={31} r={11} fill="#d8d2c4" />
        </g>
      ) : null}
      {bangles ? (
        <g>
          <ellipse cx={0} cy={30} rx={50} ry={9} fill="none" stroke={bangles} strokeWidth={6} />
          <ellipse cx={0} cy={44} rx={50} ry={9} fill="none" stroke="#c99a3c" strokeWidth={4} />
        </g>
      ) : null}
      {/* fingers behind palm edge */}
      {FINGERS.map((f, i) => finger(f, curl[i + 1], i))}
      {/* palm/back of hand */}
      <path d="M -50 -2 C -54 -40 -50 -62 -40 -70 L 44 -66 C 52 -56 52 -30 48 -2 Z" fill={skin} {...st} />
      <path d="M -30 -20 L -32 -58 M -8 -18 L -10 -62 M 14 -18 L 14 -60" stroke={shade} strokeWidth={1.2} opacity={0.5} vectorEffect="non-scaling-stroke" />
      {/* thumb */}
      <g transform={`translate(-46 -16) rotate(${-38 + thumbC * 40})`}>
        <path d={`M -14 6 L -16 ${-50 + thumbC * 18} Q -4 ${-70 + thumbC * 20} 10 ${-50 + thumbC * 18} L 12 6 Z`} fill={skin} {...st} />
        <path d={`M -9 ${-48 + thumbC * 18} Q -2 ${-60 + thumbC * 20} 6 ${-48 + thumbC * 18}`} fill="#e4c3a8" opacity={0.7} />
      </g>
    </g>
  );
};
