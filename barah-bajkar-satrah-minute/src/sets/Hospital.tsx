import React from "react";
import { INK } from "../rigs/Head";

const ol = (w = 2) => ({ stroke: INK, strokeWidth: w, vectorEffect: "non-scaling-stroke" as const });

// Hospital verandah, the day after the flood (memory). Long corridor of pillars
// in perspective; sheet-covered shapes stay soft and indistinct (non-graphic).
export const HOSPITAL = { floorY: 980, vanishX: 1260, vanishY: 520, benchY: 866 };

export const HospitalVerandah: React.FC<{ coveredShapes?: number }> = ({ coveredShapes = 1 }) => {
  const vx = HOSPITAL.vanishX;
  const vy = HOSPITAL.vanishY;
  return (
    <g>
      <defs>
        <linearGradient id="hospWall" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0" stopColor="#7c8478" />
          <stop offset="1" stopColor="#a5ab9d" />
        </linearGradient>
        <filter id="hospBlur" x="-20%" y="-50%" width="140%" height="200%">
          <feGaussianBlur stdDeviation="7" />
        </filter>
      </defs>
      <rect x={-200} y={-200} width={2320} height={1500} fill="#8f988c" />
      {/* back wall */}
      <path d={`M 0 0 L ${vx - 120} ${vy - 260} L ${vx - 120} ${vy + 120} L 0 ${HOSPITAL.floorY} Z`} fill="url(#hospWall)" />
      <rect x={vx - 120} y={vy - 260} width={360} height={380} fill="#c7cdbf" {...ol(1.2)} />
      {/* open side: sky light */}
      <path d={`M 1920 0 L ${vx + 240} ${vy - 260} L ${vx + 240} ${vy + 120} L 1920 ${HOSPITAL.floorY + 100} Z`} fill="#c9d0c6" />
      {/* floor */}
      <path d={`M 0 ${HOSPITAL.floorY} L ${vx - 120} ${vy + 120} L ${vx + 240} ${vy + 120} L 1920 ${HOSPITAL.floorY + 100} L 1920 1300 L 0 1300 Z`} fill="#6e756b" />
      {[...Array(8)].map((_, i) => {
        const t = i / 8;
        const y = vy + 120 + (HOSPITAL.floorY + 60 - vy - 120) * t * t;
        return <line key={i} x1={0} x2={1920} y1={y} y2={y + 30 * t} stroke="#5d6359" strokeWidth={2} opacity={0.6} />;
      })}
      {/* pillars receding on the right */}
      {[0, 1, 2, 3, 4, 5].map((i) => {
        const t = Math.pow(0.68, i);
        const x = vx + 240 + (1700 - vx - 240) * t;
        const top = vy - 260 + (-80 - (vy - 260)) * t;
        const bot = vy + 120 + (HOSPITAL.floorY + 90 - vy - 120) * t;
        const w = 110 * t + 10;
        return <rect key={i} x={x - w / 2} y={top} width={w} height={bot - top} fill="#d2d7cb" {...ol(1.2)} />;
      })}
      {/* windows on left wall */}
      {[0, 1, 2].map((i) => {
        const t = Math.pow(0.62, i);
        const x = vx - 120 - (vx - 300) * t;
        const w = 160 * t + 8;
        const y0 = vy - 180 + (220 - (vy - 180)) * t;
        const h = 260 * t + 40;
        return <rect key={i} x={x - w} y={y0} width={w} height={h} fill="#dfe4d7" opacity={0.7} {...ol(1)} />;
      })}
      {/* benches and covered shapes, kept soft and out of focus */}
      <g filter="url(#hospBlur)" opacity={coveredShapes}>
        <rect x={1100} y={690} width={320} height={40} rx={18} fill="#e9ebe3" />
        <rect x={1120} y={728} width={10} height={40} fill="#5d6359" />
        <rect x={1390} y={728} width={10} height={40} fill="#5d6359" />
        <rect x={1300} y={640} width={220} height={30} rx={14} fill="#e9ebe3" />
      </g>
      <rect x={120} y={HOSPITAL.benchY} width={420} height={24} fill="#5a4a3c" {...ol(1.4)} />
      <rect x={140} y={HOSPITAL.benchY + 24} width={14} height={HOSPITAL.floorY - HOSPITAL.benchY - 24} fill="#4a3c30" />
      <rect x={506} y={HOSPITAL.benchY + 24} width={14} height={HOSPITAL.floorY - HOSPITAL.benchY - 24} fill="#4a3c30" />
    </g>
  );
};
