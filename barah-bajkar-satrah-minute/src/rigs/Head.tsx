import React, { useId } from "react";
import { C } from "../style/palette";
import { EXPR } from "./characters";
import type { CharSpec, Expr, Pose } from "./types";

// Head drawn in a 100-unit space: crown y=-55, chin y=+48, facing right (3/4 view).
// Ink strokes are in screen pixels (non-scaling) so close-ups keep fine line weight.

export const INK = C.ink;
export const useSvgId = (prefix: string) => `${prefix}${useId().replace(/[^a-zA-Z0-9]/g, "")}`;

export const resolveExpr = (e: Pose["expr"]): Expr => {
  if (!e) return EXPR.neutral;
  if (typeof e === "string") return EXPR[e];
  return { ...EXPR.neutral, ...e };
};

const line = (w: number) => ({
  stroke: INK,
  strokeWidth: w,
  fill: "none",
  vectorEffect: "non-scaling-stroke" as const,
});

const facePath = (jaw: number) => {
  const j = jaw;
  return `M -37 -6 C -39 -34 -20 -56 4 -55 C 26 -54 37 -40 38 -22 C 39 -12 40 -6 40 2 C 41 14 ${37 + j} ${28 + j} ${28 + j * 2} ${38 + j} C ${22 + j} ${44 + j} 15 48 8 48 C ${-2 - 6 * j} 48 ${-12 - 4 * j} ${42 + 2 * j} -20 34 C -27 27 -31 20 -33 12 C -36 4 -37 0 -37 -6 Z`;
};

const Eye: React.FC<{
  x: number;
  y: number;
  w: number;
  h: number;
  open: number;
  lower: number;
  gx: number;
  gy: number;
  lashes: boolean;
  tears: number;
  under: number;
  shade: string;
  far: boolean;
}> = ({ x, y, w, h, open, lower, gx, gy, lashes, tears, under, shade, far }) => {
  const clip = useSvgId("eye");
  const hw = w / 2;
  const top = -h * (0.25 + 0.95 * open);
  const bot = h * (0.62 - 0.45 * lower);
  const almond = `M ${-hw} 0 C ${-hw * 0.5} ${top} ${hw * 0.5} ${top} ${hw} ${-h * 0.15} C ${hw * 0.5} ${bot} ${-hw * 0.5} ${bot} ${-hw} 0 Z`;
  const ix = gx * w * 0.2 + (far ? w * 0.08 : 0);
  const iy = gy * h * 0.22 + h * 0.05;
  const r = h * 0.78;
  return (
    <g transform={`translate(${x} ${y})`}>
      {under > 0 ? (
        <path
          d={`M ${-hw * 0.9} ${h * 0.55} Q 0 ${h * 1.6} ${hw * 0.9} ${h * 0.35}`}
          stroke={shade}
          strokeWidth={h * 0.55}
          opacity={0.18 * under}
          fill="none"
        />
      ) : null}
      {open > 0.1 ? (
        <>
          <clipPath id={clip}>
            <path d={almond} />
          </clipPath>
          <path d={almond} fill="#e9dfd2" />
          <g clipPath={`url(#${clip})`}>
            <circle cx={ix} cy={iy} r={r} fill="#3a2317" />
            <circle cx={ix} cy={iy} r={r * 0.62} fill="#1d110b" />
            <circle cx={ix} cy={iy} r={r * 0.36} fill="#080404" />
            <circle cx={ix + r * 0.35} cy={iy - r * 0.38} r={r * 0.2} fill="#fffaf0" opacity={0.9} />
            <path d={`M ${-hw} ${top * 0.6} L ${hw} ${top * 0.6} L ${hw} ${top * 1.4} L ${-hw} ${top * 1.4} Z`} fill={shade} opacity={0.25} />
          </g>
          {tears > 0 ? (
            <path
              d={`M ${-hw * 0.7} ${bot * 0.75} Q 0 ${bot * 1.05} ${hw * 0.7} ${bot * 0.6}`}
              stroke="#e6f0ff"
              strokeWidth={1.4}
              vectorEffect="non-scaling-stroke"
              opacity={0.75 * tears}
              fill="none"
            />
          ) : null}
          <path
            d={`M ${-hw * 1.05} ${0.5} C ${-hw * 0.5} ${top - 0.6} ${hw * 0.5} ${top - 0.6} ${hw * 1.05} ${-h * 0.2}${lashes ? ` l ${w * 0.12} ${-h * 0.18}` : ""}`}
            {...line(2.4)}
          />
          <path
            d={`M ${-hw * 0.8} ${top - h * 0.55} C ${-hw * 0.3} ${top - h * 1.05} ${hw * 0.4} ${top - h * 1.0} ${hw * 0.85} ${top - h * 0.45}`}
            {...line(0.9)}
            opacity={0.55}
          />
          <path d={`M ${-hw * 0.75} ${bot * 0.45} C ${-hw * 0.3} ${bot * 1.05} ${hw * 0.4} ${bot * 1.0} ${hw * 0.9} ${bot * 0.2}`} {...line(0.8)} opacity={0.6} />
        </>
      ) : (
        <>
          <path d={`M ${-hw} 0 C ${-hw * 0.4} ${h * 0.55} ${hw * 0.4} ${h * 0.5} ${hw} ${-h * 0.1}`} {...line(2.2)} />
          {tears > 0 ? (
            <path d={`M ${-hw * 0.5} ${h * 0.6} Q 0 ${h * 0.9} ${hw * 0.5} ${h * 0.5}`} stroke="#e6f0ff" strokeWidth={1.2} vectorEffect="non-scaling-stroke" opacity={0.6 * tears} fill="none" />
          ) : null}
        </>
      )}
    </g>
  );
};

const Brow: React.FC<{
  x: number;
  y: number;
  w: number;
  inner: number;
  raise: number;
  innerRight: boolean;
  color: string;
  thick: number;
}> = ({ x, y, w, inner, raise, innerRight, color, thick }) => {
  const s = innerRight ? 1 : -1;
  const ix = x + s * w * 0.55;
  const ox = x - s * w * 0.6;
  const iy = y - raise * 4 - inner * 4.5;
  const oy = y - raise * 3 + inner * 1.2 + 1;
  const my = Math.min(iy, oy) - 2.6 + inner * 0.8;
  return (
    <path
      d={`M ${ox} ${oy} Q ${x} ${my} ${ix} ${iy} L ${ix} ${iy + thick * 0.9} Q ${x} ${my + thick * 1.15} ${ox} ${oy + thick * 0.4} Z`}
      fill={color}
    />
  );
};

const Hair: React.FC<{ spec: CharSpec; layer: "back" | "front"; fx: number }> = ({ spec, layer, fx }) => {
  const c = spec.hairColor;
  const sh = spec.hairShade;
  const str = { stroke: sh, strokeWidth: 1, vectorEffect: "non-scaling-stroke" as const, fill: "none" };
  const out = { stroke: INK, strokeWidth: 1.6, vectorEffect: "non-scaling-stroke" as const };
  switch (spec.hair) {
    case "meeraAdult":
      return layer === "back" ? (
        <g>
          <path d="M 6 -62 C -26 -64 -50 -42 -48 -8 C -47 18 -42 38 -30 48 C -22 52 -16 46 -19 36 L -24 10 C -25 -10 -18 -30 4 -38 Z" fill={c} {...out} />
          <path d="M -40 -20 C -42 6 -36 28 -28 40 M -32 -38 C -38 -14 -34 14 -24 30" {...str} />
        </g>
      ) : (
        <g>
          <path d="M -8 -58 C 14 -62 38 -50 44 -26 C 46 -12 44 0 41 8 C 38 -8 31 -24 18 -33 C 7 -39 -4 -41 -14 -45 C -24 -48 -30 -44 -34 -38 C -30 -50 -20 -57 -8 -58 Z" fill={c} {...out} />
          <path d="M -4 -54 C 14 -52 30 -42 38 -22 M 4 -56 C 22 -50 34 -36 40 -10" {...str} />
          <path d="M -12 -42 C -8 -22 -16 -4 -12 16 C -11 22 -9 26 -7 28" stroke={c} strokeWidth={2.6} fill="none" />
        </g>
      );
    case "meeraChild":
      return layer === "back" ? (
        <g>
          <path d="M 4 -60 C -26 -62 -46 -40 -44 -10 C -43 8 -40 18 -34 26 L -24 20 C -28 0 -22 -26 4 -36 Z" fill={c} {...out} />
          {[0, 1, 2, 3, 4, 5].map((i) => (
            <ellipse key={i} cx={-34 + i * 0.6} cy={34 + i * 13} rx={7.5 - i * 0.4} ry={8} fill={c} {...out} />
          ))}
          <path d="M -40 104 l -9 9 l 9 -2 l 7 7 l 1 -12 Z" fill={spec.acc.ribbons} {...out} />
        </g>
      ) : (
        <g>
          <path d="M 2 -58 C 22 -60 40 -48 44 -26 C 45 -16 43 -8 40 -2 C 36 -20 28 -32 14 -38 C 2 -43 -10 -42 -22 -42 C -16 -52 -8 -57 2 -58 Z" fill={c} {...out} />
          <path d="M 4 -57 C 3 -52 4 -46 6 -40" stroke={spec.skinShade} strokeWidth={1.2} vectorEffect="non-scaling-stroke" fill="none" />
          <circle cx={-30} cy={22} r={4} fill={spec.acc.ribbons} />
        </g>
      );
    case "dineshYoung":
      return layer === "back" ? (
        <path d="M 10 -62 C -22 -66 -46 -46 -44 -14 C -43 2 -40 10 -36 16 L -26 6 C -28 -16 -16 -34 10 -40 Z" fill={c} {...out} />
      ) : (
        <g>
          <path d="M -10 -60 C 14 -66 40 -54 42 -30 C 43 -24 42 -20 40 -16 C 34 -30 24 -38 8 -40 C -6 -42 -20 -40 -32 -32 C -30 -48 -22 -57 -10 -60 Z" fill={c} {...out} />
          <path d="M -6 -54 C 10 -56 28 -48 36 -34" {...str} />
          <path d="M -22 -10 L -22 8" stroke={c} strokeWidth={4} vectorEffect="non-scaling-stroke" />
        </g>
      );
    case "dineshOld":
      return layer === "back" ? (
        <path d="M -30 -40 C -44 -28 -46 -6 -40 12 L -30 8 C -32 -10 -28 -26 -20 -36 Z" fill={c} {...out} />
      ) : (
        <g>
          <path d="M -26 -46 C -14 -56 6 -58 22 -54 C 10 -54 -4 -52 -16 -44 Z" fill={c} {...out} />
          <path d="M -6 -54 C 4 -56 14 -56 24 -52 M -12 -50 C -2 -53 8 -53 18 -50" {...str} stroke={c} />
          <path d="M -22 -12 L -22 4" stroke={c} strokeWidth={3} vectorEffect="non-scaling-stroke" />
        </g>
      );
    case "mother":
      return layer === "back" ? (
        <g>
          <path d="M 4 -60 C -26 -62 -46 -40 -44 -10 C -43 4 -40 12 -34 18 L -24 12 C -28 -8 -20 -30 4 -38 Z" fill={c} {...out} />
          <circle cx={-40} cy={14} r={14} fill={c} {...out} />
          <path d="M -50 8 C -44 4 -36 8 -32 16 M -50 20 C -44 16 -36 20 -32 26" {...str} />
          <circle cx={-34} cy={4} r={2.6} fill="#e8e0d0" />
          <circle cx={-38} cy={9} r={2.2} fill="#e8e0d0" />
        </g>
      ) : (
        <g>
          <path d="M 4 -58 C 24 -60 41 -48 43 -26 C 44 -18 42 -12 40 -8 C 36 -22 28 -32 14 -38 C 4 -42 -8 -42 -20 -40 C -30 -38 -34 -30 -34 -20 C -36 -38 -24 -56 4 -58 Z" fill={c} {...out} />
          <path d="M 6 -57 C 5 -52 6 -46 8 -40" stroke="#a3322b" strokeWidth={2.2} vectorEffect="non-scaling-stroke" fill="none" />
          <path d="M 10 -54 C 24 -50 36 -40 40 -24 M -4 -54 C -18 -50 -28 -40 -32 -26" {...str} />
        </g>
      );
    case "anshu":
      return layer === "back" ? (
        <path d="M 8 -62 C -24 -66 -48 -44 -45 -12 C -44 0 -40 8 -36 12 L -26 4 C -28 -18 -16 -36 8 -42 Z" fill={c} {...out} />
      ) : (
        <g>
          <path d="M -12 -60 C 12 -68 40 -56 43 -32 C 44 -24 42 -18 40 -14 C 36 -28 28 -36 16 -40 L 12 -34 L 6 -42 L 0 -36 L -6 -43 C -18 -42 -28 -38 -34 -30 C -32 -46 -24 -57 -12 -60 Z" fill={c} {...out} />
          <path d="M -6 -60 C -10 -72 -2 -78 4 -72 C 0 -70 -2 -66 -2 -61 Z" fill={c} {...out} />
        </g>
      );
    case "kabir":
      return layer === "back" ? (
        <path d="M 8 -64 C -24 -68 -48 -46 -45 -14 C -44 0 -41 8 -37 12 L -26 4 C -28 -18 -16 -36 8 -42 Z" fill={c} {...out} />
      ) : (
        <g>
          <path d="M -14 -60 C -8 -68 4 -64 8 -66 C 16 -68 24 -60 30 -60 C 40 -56 44 -44 42 -30 C 42 -24 41 -20 39 -17 C 34 -30 24 -37 10 -40 C -4 -42 -20 -40 -34 -30 C -34 -42 -26 -56 -14 -60 Z" fill={c} {...out} />
          <path d="M -10 -56 C -4 -60 2 -56 8 -58 C 14 -60 20 -54 28 -54 M -20 -48 C -12 -52 -6 -48 0 -50" {...str} />
          <path d="M -22 -12 L -22 10" stroke={c} strokeWidth={4} vectorEffect="non-scaling-stroke" />
        </g>
      );
    case "vikram":
      return layer === "back" ? (
        <path d="M 6 -64 C -26 -66 -48 -44 -45 -12 C -44 0 -41 6 -37 10 L -26 2 C -28 -18 -18 -36 6 -42 Z" fill={c} {...out} />
      ) : (
        <g>
          <path d="M 30 -50 C 18 -62 -8 -66 -26 -56 C -36 -50 -40 -40 -38 -30 C -30 -40 -16 -46 4 -46 C 18 -46 32 -42 40 -34 C 40 -40 36 -46 30 -50 Z" fill={c} {...out} />
          <path d="M 30 -48 C 14 -56 -10 -56 -30 -44 M 34 -42 C 16 -50 -6 -52 -26 -42 M 24 -54 C 6 -60 -14 -58 -28 -50" {...str} />
          <path d="M -22 -12 L -22 6" stroke={c} strokeWidth={3} vectorEffect="non-scaling-stroke" />
        </g>
      );
    case "harish":
      return layer === "back" ? (
        <path d="M -30 -20 C -40 -10 -40 4 -36 14 L -28 10 C -30 0 -30 -10 -26 -18 Z" fill={c} {...out} />
      ) : (
        <g>
          <path d="M -40 -20 C -44 -48 -20 -66 6 -64 C 30 -62 44 -48 42 -26 C 42 -22 40 -20 38 -19 L -38 -16 Z" fill={spec.acc.cap} {...out} />
          <path d="M -40 -22 C -10 -28 20 -27 42 -22 L 42 -14 C 20 -19 -10 -20 -40 -13 Z" fill={spec.acc.cap} {...out} />
          {[-30, -20, -10, 0, 10, 20, 30].map((x) => (
            <path key={x} d={`M ${x} -22 L ${x * 0.9} -56`} stroke="#3a2b22" strokeWidth={1} vectorEffect="non-scaling-stroke" opacity={0.6} />
          ))}
        </g>
      );
    default:
      return layer === "back" ? (
        <path d="M 8 -62 C -24 -66 -48 -44 -45 -12 C -44 0 -40 8 -36 12 L -26 4 C -28 -18 -16 -36 8 -42 Z" fill={c} {...out} />
      ) : (
        <path d="M -12 -60 C 12 -66 40 -54 42 -30 C 43 -24 42 -20 40 -16 C 34 -30 24 -38 8 -40 C -6 -42 -20 -40 -32 -32 C -30 -48 -22 -57 -12 -60 Z" fill={c} {...out} />
      );
  }
};

export const Head: React.FC<{ spec: CharSpec; pose: Pose }> = ({ spec, pose }) => {
  const faceClip = useSvgId("face");
  const e = resolveExpr(pose.expr);
  const t = Math.max(-1, Math.min(1, pose.headTurn ?? 0));
  const fx = 12 + 7 * t;
  const ey = -2;
  const lid = Math.max(e.lid, pose.blink ?? 0);
  const open = Math.max(0, 1 - lid);
  const gx = pose.gazeX ?? 0.35;
  const gy = pose.gazeY ?? 0;
  const female = ["meeraAdult", "meeraChild", "mother", "bunFemale", "plaitFemale"].includes(spec.hair);
  const mOpen = Math.min(1, Math.max(e.open, (pose.talk ?? 0) * 0.75));
  const mx = fx + 4;
  const my = 31;
  const curve = e.mouth * 3.2;
  const press = e.press ?? 0;
  const halfL = 10 - press * 1.5;
  const halfR = 7 * (1 - 0.3 * t) - press;
  const age = spec.acc.wrinkles ?? 0;
  const face = facePath(spec.jaw);
  const ol = { stroke: INK, strokeWidth: 2, vectorEffect: "non-scaling-stroke" as const };

  if (pose.view === "back") {
    return (
      <g transform={`scale(${spec.faceW} 1)`}>
        <path d={face} fill={spec.skin} {...ol} />
        <path d="M -48 -8 C -50 -44 -22 -64 6 -62 C 32 -60 46 -44 45 -16 C 44 6 38 26 28 38 C 10 44 -14 44 -32 38 C -42 26 -47 10 -48 -8 Z" fill={spec.acc.cap ?? spec.hairColor} {...ol} />
        <Hair spec={spec} layer="back" fx={fx} />
      </g>
    );
  }

  return (
    <g transform={`scale(${spec.faceW} 1)`}>
      <Hair spec={spec} layer="back" fx={fx} />
      <path d={face} fill={spec.skin} {...ol} />
      <clipPath id={faceClip}>
        <path d={face} />
      </clipPath>
      <g clipPath={`url(#${faceClip})`}>
        <ellipse cx={-34 - t * 4} cy={6} rx={22} ry={58} fill={spec.skinShade} opacity={0.42} />
        <ellipse cx={8} cy={58} rx={40} ry={14} fill={spec.skinShade} opacity={0.35} />
        <ellipse cx={fx - 14} cy={17} rx={8} ry={4.5} fill="#c4604e" opacity={female ? 0.14 : 0.07} />
        {spec.acc.stubble ? (
          <path d="M -20 30 C -6 46 14 50 32 36 L 30 30 C 16 40 0 40 -14 26 Z" fill={spec.acc.stubble} opacity={0.4} />
        ) : null}
      </g>
      {/* ear */}
      <g transform={`translate(${-19 - t * 3} 4)`}>
        <path d="M 2 -9 C -6 -11 -9 -2 -7 5 C -6 10 -2 12 3 10" fill={spec.skin} {...ol} strokeWidth={1.6} />
        <path d="M 0 -5 C -3 -4 -4 1 -2 4" {...line(0.9)} opacity={0.6} />
        {spec.acc.earrings ? <circle cx={-2} cy={12} r={2.4} fill={spec.acc.earrings} stroke={INK} strokeWidth={0.8} vectorEffect="non-scaling-stroke" /> : null}
      </g>
      {/* eyes */}
      <Eye x={fx - 15} y={ey} w={17 * (1 - 0.08 * t)} h={7.6} open={open} lower={e.lower} gx={gx} gy={gy} lashes={female} tears={e.tears ?? 0} under={spec.acc.underEye ?? 0} shade={spec.skinShade} far={false} />
      <Eye x={fx + 14} y={ey} w={12 * (1 - 0.35 * t)} h={7.2} open={open} lower={e.lower} gx={gx} gy={gy} lashes={female} tears={e.tears ?? 0} under={(spec.acc.underEye ?? 0) * 0.7} shade={spec.skinShade} far />
      <Brow x={fx - 15} y={ey - 12} w={17} inner={e.browInner} raise={e.browY} innerRight color={spec.hair === "harish" ? "#cfc9c0" : spec.hair === "dineshOld" ? "#7c766f" : spec.hair === "vikram" ? "#8d8880" : spec.hairColor} thick={female ? 2.4 : 3.4} />
      <Brow x={fx + 14} y={ey - 12} w={12} inner={e.browInner} raise={e.browY} innerRight={false} color={spec.hair === "harish" ? "#cfc9c0" : spec.hair === "dineshOld" ? "#7c766f" : spec.hair === "vikram" ? "#8d8880" : spec.hairColor} thick={female ? 2.2 : 3} />
      {/* nose */}
      <path d={`M ${fx + 2} ${ey + 2} C ${fx + 5} ${ey + 8} ${fx + 12 + 3 * t} ${ey + 14} ${fx + 12 + 3 * t} ${ey + 19} C ${fx + 11} ${ey + 22} ${fx + 6} ${ey + 23} ${fx + 2} ${ey + 21}`} {...line(1.5)} />
      <path d={`M ${fx - 2} ${ey + 20} C ${fx} ${ey + 23} ${fx + 3} ${ey + 23} ${fx + 4} ${ey + 22}`} {...line(1.1)} opacity={0.7} />
      {age > 0 ? (
        <g opacity={0.45 * age}>
          <path d={`M ${fx - 4} ${ey + 20} C ${fx - 10} ${ey + 27} ${fx - 10} ${ey + 33} ${fx - 8} ${ey + 38}`} {...line(1)} />
          <path d={`M ${fx - 26} ${ey - 2} l -4 -3 M ${fx - 26} ${ey + 2} l -5 0`} {...line(0.8)} />
          <path d={`M ${fx - 18} -30 C ${fx - 6} -32 ${fx + 8} -32 ${fx + 18} -29 M ${fx - 14} -36 C ${fx - 4} -38 ${fx + 6} -38 ${fx + 15} -35`} {...line(0.8)} />
        </g>
      ) : null}
      {/* mouth */}
      {mOpen > 0.04 ? (
        <g>
          <path
            d={`M ${mx - halfL} ${my - curve} Q ${mx} ${my - 2.5 - mOpen * 2} ${mx + halfR} ${my - curve} Q ${mx} ${my + 3 + mOpen * 11} ${mx - halfL} ${my - curve} Z`}
            fill="#3a1714"
            stroke={INK}
            strokeWidth={1.6}
            vectorEffect="non-scaling-stroke"
          />
          {mOpen > 0.25 ? (
            <path d={`M ${mx - halfL * 0.7} ${my - curve * 0.6 - 0.6} Q ${mx} ${my - 1.2 - mOpen * 1.5} ${mx + halfR * 0.7} ${my - curve * 0.6 - 0.6} L ${mx + halfR * 0.6} ${my + 0.8} Q ${mx} ${my + 0.2} ${mx - halfL * 0.6} ${my + 0.8} Z`} fill="#e9e1d4" opacity={0.85} />
          ) : null}
          <path d={`M ${mx - halfL * 0.8} ${my + 2 + mOpen * 8} Q ${mx} ${my + 5 + mOpen * 11} ${mx + halfR * 0.8} ${my + 2 + mOpen * 7}`} stroke={spec.lip} strokeWidth={2} vectorEffect="non-scaling-stroke" fill="none" opacity={0.6} />
        </g>
      ) : (
        <g>
          <path
            d={`M ${mx - halfL} ${my - curve} Q ${mx - 2} ${my + 0.6 + curve * 0.4 - press} ${mx + halfR} ${my - curve * 0.9}`}
            {...line(1.9)}
          />
          <path d={`M ${mx - halfL * 0.6} ${my + 4.5} Q ${mx} ${my + 6.5 - press * 1.5} ${mx + halfR * 0.6} ${my + 4.2}`} stroke={spec.lip} strokeWidth={2.2} vectorEffect="non-scaling-stroke" fill="none" opacity={female ? 0.65 : 0.4} />
          {press > 0.4 ? <path d={`M ${mx - halfL - 1} ${my - curve - 2} l -1 4`} {...line(0.9)} opacity={0.5} /> : null}
        </g>
      )}
      {spec.acc.moustache ? (
        <path d={`M ${mx - 13} ${my - 1} C ${mx - 8} ${my - 8} ${mx + 4} ${my - 9} ${mx + 10} ${my - 2} C ${mx + 4} ${my - 4} ${mx - 6} ${my - 4} ${mx - 13} ${my - 1} Z`} fill={spec.acc.moustache} stroke={INK} strokeWidth={1} vectorEffect="non-scaling-stroke" />
      ) : null}
      {spec.acc.beard ? (
        <path
          d={`M -30 14 C -28 30 -16 44 2 50 C 14 52 24 46 32 36 C 36 30 38 24 38 18 C 34 26 28 32 ${mx + 9} ${my + 2} C ${mx + 4} ${my + 8} ${mx - 6} ${my + 8} ${mx - 12} ${my + 2} C ${mx - 14} ${my - 6} ${mx - 4} ${my - 8} ${mx + 10} ${my - 3} C ${mx - 2} ${my - 9} ${mx - 14} ${my - 6} -14 22 C -20 20 -26 16 -30 14 Z`}
          fill={spec.acc.beard}
          stroke={INK}
          strokeWidth={1.2}
          vectorEffect="non-scaling-stroke"
        />
      ) : null}
      {spec.acc.bindi ? <circle cx={fx - 1} cy={ey - 17} r={2.8} fill="#b3261e" /> : null}
      {spec.acc.glasses ? (
        <g fill="none" stroke="#2a2420" strokeWidth={1.8} vectorEffect="non-scaling-stroke">
          <rect x={fx - 26} y={ey - 7} width={22} height={13} rx={3} />
          <rect x={fx + 6} y={ey - 7} width={16 * (1 - 0.3 * t)} height={13} rx={3} />
          <path d={`M ${fx - 4} ${ey - 2} Q ${fx + 1} ${ey - 5} ${fx + 6} ${ey - 2} M ${fx - 26} ${ey - 3} L -22 ${ey - 4}`} />
          <path d={`M ${fx - 24} ${ey - 6} l 6 0`} stroke="#ffffff" opacity={0.35} />
        </g>
      ) : null}
      <Hair spec={spec} layer="front" fx={fx} />
    </g>
  );
};
