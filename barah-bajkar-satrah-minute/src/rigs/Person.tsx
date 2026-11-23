import React from "react";
import { Head, INK, useSvgId } from "./Head";
import type { ArmPose, CharSpec, HandShape, Pose } from "./types";

type Pt = { x: number; y: number };
const rad = (d: number) => (d * Math.PI) / 180;
const add = (p: Pt, len: number, angDeg: number): Pt => ({
  x: p.x + len * Math.sin(rad(angDeg)),
  y: p.y + len * Math.cos(rad(angDeg)),
});

export type Joints = {
  hipY: number;
  shY: number;
  chinY: number;
  hh: number;
  upperDy: number; // vertical offset applied to the upper body (sitting/crouching)
  nearSh: Pt;
  farSh: Pt;
  near: { elbow: Pt; wrist: Pt; handAng: number };
  far: { elbow: Pt; wrist: Pt; handAng: number };
};

const DEFAULT_ARM: ArmPose = { sh: 6, el: 14, wr: 0, hand: "relaxed" };

/** Pure joint computation shared by the renderer and by scenes that need hand positions. */
export const computeJoints = (spec: CharSpec, pose: Pose): Joints => {
  const H = spec.H;
  const hh = H * spec.headFrac;
  const chinY = -H + hh;
  const shY = chinY + 0.032 * H;
  const hipY = -0.47 * H;
  const upperDy =
    pose.stance === "sit" ? -0.25 * H - hipY : pose.stance === "crouch" ? -0.22 * H - hipY : 0;
  const sw = spec.shoulder * H;
  const up = (pose.shoulderUp ?? 0) * 0.015 * H;
  const nearSh = { x: -sw * 0.82, y: shY + 0.02 * H - up };
  const farSh = { x: sw * 0.72, y: shY + 0.025 * H - up };
  const arm = (s: Pt, a: ArmPose) => {
    const elbow = add(s, 0.185 * H, a.sh);
    const fore = a.sh + a.el;
    const wrist = add(elbow, 0.155 * H, fore);
    return { elbow, wrist, handAng: fore + (a.wr ?? 0) };
  };
  return {
    hipY,
    shY,
    chinY,
    hh,
    upperDy,
    nearSh,
    farSh,
    near: arm(nearSh, pose.near ?? DEFAULT_ARM),
    far: arm(farSh, pose.far ?? { ...DEFAULT_ARM, sh: -4 }),
  };
};

/** Hand in local space: wrist at origin, fingers along +y. */
export const Hand: React.FC<{ shape: HandShape; L: number; skin: string; shade: string; mirror?: boolean }> = ({
  shape,
  L,
  skin,
  shade,
  mirror,
}) => {
  const w = L * 0.62;
  const st = { stroke: INK, strokeWidth: 1.6, vectorEffect: "non-scaling-stroke" as const };
  const m = mirror ? -1 : 1;
  const thumb = (
    <path
      d={`M ${m * w * 0.42} ${L * 0.12} C ${m * w * 0.8} ${L * 0.25} ${m * w * 0.82} ${L * 0.5} ${m * w * 0.55} ${L * 0.62} C ${m * w * 0.45} ${L * 0.6} ${m * w * 0.4} ${L * 0.45} ${m * w * 0.3} ${L * 0.35}`}
      fill={skin}
      {...st}
    />
  );
  switch (shape) {
    case "fist":
      return (
        <g>
          <ellipse cx={0} cy={L * 0.38} rx={w * 0.55} ry={L * 0.36} fill={skin} {...st} />
          <path d={`M ${-w * 0.4} ${L * 0.5} Q 0 ${L * 0.62} ${w * 0.4} ${L * 0.5}`} fill="none" stroke={shade} strokeWidth={1} vectorEffect="non-scaling-stroke" />
          {thumb}
        </g>
      );
    case "open":
      return (
        <g>
          {[-0.36, -0.12, 0.12, 0.34].map((f, i) => (
            <path key={i} d={`M ${f * w} ${L * 0.45} L ${f * w * 1.35} ${L * (0.98 - Math.abs(f) * 0.3)}`} stroke={INK} strokeWidth={L * 0.17 + 2} strokeLinecap="round" />
          ))}
          {[-0.36, -0.12, 0.12, 0.34].map((f, i) => (
            <path key={`s${i}`} d={`M ${f * w} ${L * 0.45} L ${f * w * 1.35} ${L * (0.98 - Math.abs(f) * 0.3)}`} stroke={skin} strokeWidth={L * 0.17} strokeLinecap="round" />
          ))}
          <path d={`M ${-w / 2} 0 L ${w / 2} 0 L ${w * 0.52} ${L * 0.5} L ${-w * 0.5} ${L * 0.5} Z`} fill={skin} {...st} />
          {thumb}
        </g>
      );
    case "point":
      return (
        <g>
          <path d={`M 0 ${L * 0.4} L ${w * 0.05} ${L * 1.05}`} stroke={INK} strokeWidth={L * 0.17 + 2} strokeLinecap="round" />
          <path d={`M 0 ${L * 0.4} L ${w * 0.05} ${L * 1.05}`} stroke={skin} strokeWidth={L * 0.17} strokeLinecap="round" />
          <ellipse cx={0} cy={L * 0.36} rx={w * 0.52} ry={L * 0.33} fill={skin} {...st} />
          {thumb}
        </g>
      );
    case "grip":
    case "hold":
      return (
        <g>
          <path d={`M ${-w / 2} 0 C ${-w * 0.62} ${L * 0.4} ${-w * 0.5} ${L * 0.8} ${-w * 0.1} ${L * 0.85} C ${w * 0.3} ${L * 0.88} ${w * 0.5} ${L * 0.7} ${w * 0.45} ${L * 0.55} L ${w / 2} 0 Z`} fill={skin} {...st} />
          <path d={`M ${-w * 0.42} ${L * 0.62} Q ${-w * 0.05} ${L * 0.7} ${w * 0.3} ${L * 0.6}`} fill="none" stroke={shade} strokeWidth={1} vectorEffect="non-scaling-stroke" />
          {thumb}
        </g>
      );
    case "pinch":
      return (
        <g>
          <path d={`M ${-w / 2} 0 C ${-w * 0.6} ${L * 0.4} ${-w * 0.4} ${L * 0.7} 0 ${L * 0.95} C ${w * 0.2} ${L * 0.75} ${w * 0.45} ${L * 0.5} ${w / 2} 0 Z`} fill={skin} {...st} />
          {thumb}
        </g>
      );
    default:
      return (
        <g>
          <path d={`M ${-w / 2} 0 C ${-w * 0.62} ${L * 0.45} ${-w * 0.45} ${L * 0.95} ${-w * 0.05} ${L * 0.98} C ${w * 0.3} ${L * 0.98} ${w * 0.55} ${L * 0.7} ${w * 0.5} ${L * 0.4} L ${w / 2} 0 Z`} fill={skin} {...st} />
          <path d={`M ${-w * 0.3} ${L * 0.6} L ${-w * 0.32} ${L * 0.9} M ${0} ${L * 0.62} L ${0} ${L * 0.94}`} stroke={shade} strokeWidth={1} vectorEffect="non-scaling-stroke" />
          {thumb}
        </g>
      );
  }
};

const limbPath = (pts: Pt[]) => {
  if (pts.length === 3) {
    // soften the joint with a quadratic through the middle point
    const [a, b, c] = pts;
    return `M ${a.x} ${a.y} Q ${b.x} ${b.y} ${c.x} ${c.y}`;
  }
  return pts.map((p, i) => `${i ? "L" : "M"} ${p.x} ${p.y}`).join(" ");
};

const Limb: React.FC<{ pts: Pt[]; w: number; color: string; outline?: number }> = ({ pts, w, color, outline = 2.4 }) => {
  const d = limbPath(pts);
  return (
    <g>
      <path d={d} stroke={INK} strokeWidth={w + outline} fill="none" strokeLinecap="round" strokeLinejoin="round" />
      <path d={d} stroke={color} strokeWidth={w} fill="none" strokeLinecap="round" strokeLinejoin="round" />
    </g>
  );
};

/** Several limb segments sharing one outline pass so joints show no ink seams. */
const Limbs: React.FC<{ segs: { pts: Pt[]; w: number; color: string }[]; outline?: number }> = ({ segs, outline = 2.4 }) => (
  <g>
    {segs.map((s, i) => (
      <path key={`o${i}`} d={limbPath(s.pts)} stroke={INK} strokeWidth={s.w + outline} fill="none" strokeLinecap="round" strokeLinejoin="round" />
    ))}
    {segs.map((s, i) => (
      <path key={`f${i}`} d={limbPath(s.pts)} stroke={s.color} strokeWidth={s.w} fill="none" strokeLinecap="round" strokeLinejoin="round" />
    ))}
  </g>
);

const lerp = (a: Pt, b: Pt, t: number): Pt => ({ x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t });

const Arm: React.FC<{
  spec: CharSpec;
  sh: Pt;
  j: { elbow: Pt; wrist: Pt; handAng: number };
  hand: HandShape;
  hold?: React.ReactNode;
  far?: boolean;
}> = ({ spec, sh, j, hand, hold, far }) => {
  const H = spec.H;
  const sleeveColor =
    spec.top.kind === "sari" ? spec.top.color : spec.top.kind === "coat" || spec.top.kind === "cardigan" ? spec.top.color : spec.top.color;
  const sc = far ? spec.top.shade : sleeveColor;
  const skin = far ? spec.skinShade : spec.skin;
  const uw = 0.05 * H;
  const fw = 0.041 * H;
  const sleeveEnd =
    spec.sleeve === "long" ? 1 : spec.sleeve === "three-quarter" ? 0.55 : spec.top.kind === "sari" ? 0.25 : 0.5;
  const upperSleeveEnd = spec.sleeve === "half" ? (spec.top.kind === "sari" ? 0.4 : 0.6) : 1;
  return (
    <g>
      <Limbs
        segs={[
          { pts: [sh, j.elbow], w: uw * 0.92, color: skin },
          { pts: [j.elbow, j.wrist], w: fw, color: skin },
        ]}
      />
      {spec.sleeve === "half" ? (
        <Limb pts={[sh, lerp(sh, j.elbow, upperSleeveEnd)]} w={uw * 1.1} color={sc} />
      ) : (
        <Limbs
          segs={[
            { pts: [sh, j.elbow], w: uw, color: sc },
            { pts: [j.elbow, lerp(j.elbow, j.wrist, sleeveEnd)], w: fw * 1.12, color: sc },
          ]}
        />
      )}
      {spec.acc.bangles && !far ? (
        <g>
          {[0.8, 0.86].map((t) => {
            const p = lerp(j.elbow, j.wrist, t);
            return <circle key={t} cx={p.x} cy={p.y} r={fw * 0.62} fill="none" stroke={spec.acc.bangles} strokeWidth={2.4} vectorEffect="non-scaling-stroke" />;
          })}
        </g>
      ) : null}
      {spec.acc.watch && !far ? (
        (() => {
          const p = lerp(j.elbow, j.wrist, 0.88);
          return <circle cx={p.x} cy={p.y} r={fw * 0.42} fill="#1a1a1a" stroke="#c8c2b8" strokeWidth={1.2} vectorEffect="non-scaling-stroke" />;
        })()
      ) : null}
      <g transform={`translate(${j.wrist.x} ${j.wrist.y}) rotate(${-j.handAng})`}>
        <Hand shape={hand} L={0.075 * H} skin={skin} shade={spec.skinShade} mirror={far} />
        {hold}
      </g>
    </g>
  );
};

const Legs: React.FC<{ spec: CharSpec; pose: Pose; side: "near" | "far" }> = ({ spec, pose, side }) => {
  const H = spec.H;
  const hipY = -0.47 * H;
  const hw = spec.hip * H;
  const isNear = side === "near";
  const hx = isNear ? -hw * 0.45 : hw * 0.35;
  const legW = 0.068 * H;
  const shinW = 0.052 * H;
  const color = isNear ? spec.bottom.color : spec.bottom.shade;
  const skinLegs = spec.bottom.kind === "legs" || spec.bottom.kind === "shorts";
  const footColor = spec.shoe;
  let hip: Pt, knee: Pt, ankle: Pt;
  if (pose.stance === "sit") {
    hip = { x: hx * 0.5, y: -0.25 * H };
    knee = { x: hx * 0.3 + 0.23 * H, y: -0.255 * H };
    ankle = { x: hx * 0.3 + 0.22 * H + (isNear ? 0.01 * H : -0.02 * H), y: -0.03 * H };
  } else if (pose.stance === "crouch") {
    hip = { x: hx * 0.4 - 0.03 * H, y: -0.22 * H };
    knee = { x: hx * 0.3 + 0.13 * H, y: -0.3 * H };
    ankle = { x: hx * 0.3 + 0.05 * H, y: -0.03 * H };
  } else {
    const ph = (pose.walk ?? 0) * Math.PI * 2 + (isNear ? 0 : Math.PI);
    const swing = pose.stance === "walk" ? 20 * Math.sin(ph) : 0;
    const bend = pose.stance === "walk" ? Math.max(0, 28 * Math.cos(ph)) : 0;
    hip = { x: hx, y: hipY };
    knee = add(hip, 0.225 * H, swing);
    ankle = add(knee, 0.235 * H, swing - bend);
  }
  const foot = (
    <path
      d={`M ${ankle.x - 0.02 * H} ${ankle.y - 0.01 * H} L ${ankle.x + 0.065 * H} ${ankle.y + 0.012 * H} Q ${ankle.x + 0.075 * H} ${ankle.y + 0.035 * H} ${ankle.x + 0.05 * H} ${ankle.y + 0.035 * H} L ${ankle.x - 0.025 * H} ${ankle.y + 0.035 * H} Z`}
      fill={footColor}
      stroke={INK}
      strokeWidth={1.6}
      vectorEffect="non-scaling-stroke"
    />
  );
  if (spec.bottom.kind === "sari") return <g>{foot}</g>;
  return (
    <g>
      {skinLegs ? (
        <>
          <Limbs segs={[{ pts: [hip, knee], w: shinW, color: isNear ? spec.skin : spec.skinShade }, { pts: [knee, ankle], w: shinW * 0.85, color: isNear ? spec.skin : spec.skinShade }]} />
          {spec.bottom.kind === "shorts" ? <Limb pts={[hip, lerp(hip, knee, 0.55)]} w={legW * 1.05} color={color} /> : null}
        </>
      ) : (
        <Limbs segs={[{ pts: [hip, knee], w: legW, color }, { pts: [knee, ankle], w: spec.bottom.kind === "salwar" ? legW : shinW, color }]} />
      )}
      {foot}
    </g>
  );
};

const Torso: React.FC<{ spec: CharSpec; pose: Pose; j: Joints }> = ({ spec, pose, j }) => {
  const H = spec.H;
  const sw = spec.shoulder * H;
  const hw = spec.hip * H;
  const ww = (sw + hw) * 0.42;
  const { shY, hipY } = j;
  const waistY = -0.6 * H;
  const sitting = pose.stance === "sit" || pose.stance === "crouch";
  const len = spec.top.length;
  let hemY = -H * (1 - len);
  const kind = spec.top.kind;
  const flare = kind === "frock" ? 1.75 : kind === "kurta" || kind === "coat" ? 1.15 : 1.02;
  const st = { stroke: INK, strokeWidth: 2, vectorEffect: "non-scaling-stroke" as const };
  const thin = { stroke: INK, strokeWidth: 1, vectorEffect: "non-scaling-stroke" as const, fill: "none" };
  const elements: React.ReactNode[] = [];

  // Lower garments that cover legs (sari skirt) are drawn first.
  if (spec.bottom.kind === "sari") {
    if (sitting) {
      // drawn in upper-body space: hip at hipY, floor at -upperDy
      const kx = 0.25 * H;
      const fl = -j.upperDy - 0.01 * H;
      const top = hipY - 0.03 * H;
      elements.push(
        <path key="skirt" d={`M ${-ww * 1.05} ${waistY} C ${-hw * 1.15} ${hipY - 0.04 * H} ${-hw * 1.1} ${hipY + 0.04 * H} ${-hw * 0.8} ${hipY + 0.05 * H} L ${kx - 0.09 * H} ${hipY + 0.05 * H} C ${kx - 0.07 * H} ${hipY + 0.1 * H} ${kx - 0.08 * H} ${fl - 0.08 * H} ${kx - 0.09 * H} ${fl} L ${kx + 0.07 * H} ${fl} C ${kx + 0.05 * H} ${fl - 0.1 * H} ${kx + 0.05 * H} ${top + 0.04 * H} ${kx} ${top} C ${kx * 0.5} ${top - 0.01 * H} ${ww} ${waistY + 0.02 * H} ${ww * 1.05} ${waistY} Z`} fill={spec.bottom.color} {...st} />,
        <path key="border" d={`M ${kx - 0.09 * H} ${fl - 0.025 * H} L ${kx + 0.07 * H} ${fl - 0.025 * H}`} stroke={spec.top.trim} strokeWidth={0.018 * H} />,
      );
    } else {
      elements.push(
        <path key="skirt" d={`M ${-ww * 1.05} ${waistY} C ${-hw * 1.1} ${hipY} ${-hw * 1.25} ${-0.2 * H} ${-hw * 1.35} ${-0.02 * H} L ${hw * 1.3} ${-0.02 * H} C ${hw * 1.2} ${-0.2 * H} ${hw * 1.05} ${hipY} ${ww * 1.05} ${waistY} Z`} fill={spec.bottom.color} {...st} />,
        <path key="pleats" d={`M ${hw * 0.1} ${hipY + 0.04 * H} L ${hw * 0.2} ${-0.03 * H} M ${hw * 0.35} ${hipY + 0.05 * H} L ${hw * 0.55} ${-0.03 * H} M ${hw * 0.6} ${hipY + 0.06 * H} L ${hw * 0.85} ${-0.03 * H}`} {...thin} />,
        <path key="border" d={`M ${-hw * 1.33} ${-0.045 * H} L ${hw * 1.28} ${-0.045 * H}`} stroke={spec.top.trim} strokeWidth={0.02 * H} />,
      );
    }
  }

  if (kind === "sari") {
    // blouse + bare midriff hint + pallu
    elements.push(
      <path key="blouse" d={`M ${-sw * 0.3} ${shY - 2} L ${-sw} ${shY + 6} C ${-sw * 1.02} ${shY + 0.08 * H} ${-ww * 1.05} ${shY + 0.12 * H} ${-ww * 1.02} ${shY + 0.15 * H} L ${ww * 1.02} ${shY + 0.15 * H} C ${ww * 1.05} ${shY + 0.12 * H} ${sw * 1.02} ${shY + 0.08 * H} ${sw} ${shY + 6} L ${sw * 0.3} ${shY - 2} Z`} fill={spec.top.shade} {...st} />,
      <path key="mid" d={`M ${-ww * 1.02} ${shY + 0.15 * H} L ${ww * 1.02} ${shY + 0.15 * H} L ${ww * 1.05} ${waistY} L ${-ww * 1.05} ${waistY} Z`} fill={spec.skin} {...st} />,
    );
    if (spec.acc.pallu) {
      const p = spec.acc.pallu;
      elements.push(
        <path key="pallu" d={`M ${-hw * 0.9} ${waistY + 0.04 * H} C ${-sw * 0.3} ${shY + 0.18 * H} ${sw * 0.2} ${shY + 0.06 * H} ${sw * 0.75} ${shY - 2} L ${sw * 1.05} ${shY + 8} C ${sw * 0.7} ${shY + 0.12 * H} ${0} ${shY + 0.26 * H} ${-hw * 0.4} ${waistY + 0.07 * H} Z`} fill={p.color} {...st} />,
        <path key="palluB" d={`M ${-hw * 0.4} ${waistY + 0.07 * H} C ${0} ${shY + 0.26 * H} ${sw * 0.7} ${shY + 0.12 * H} ${sw * 1.05} ${shY + 8}`} stroke={p.border} strokeWidth={0.012 * H} fill="none" />,
        <path key="palluF" d={`M ${-hw * 0.6} ${waistY + 0.04 * H} C ${-sw * 0.1} ${shY + 0.2 * H} ${sw * 0.3} ${shY + 0.12 * H} ${sw * 0.6} ${shY + 0.04 * H}`} {...thin} />,
      );
    }
  } else {
    if (sitting && (kind === "kurta" || kind === "coat" || kind === "frock")) hemY = hipY + 0.02 * H;
    const hemW = hw * flare;
    const fold = sitting && (kind === "kurta" || kind === "coat" || kind === "frock");
    const body = `M ${-sw * 0.32} ${shY - 3} L ${-sw} ${shY + 5} C ${-sw * 1.04} ${shY + 0.07 * H} ${-ww * 1.08} ${shY + 0.14 * H} ${-ww} ${waistY} C ${-hw * 1.02} ${hipY - 0.04 * H} ${-hemW} ${hemY - 0.08 * H} ${-hemW} ${hemY} L ${hemW} ${hemY} C ${hemW} ${hemY - 0.08 * H} ${hw * 1.02} ${hipY - 0.04 * H} ${ww * 1.02} ${waistY} C ${ww * 1.1} ${shY + 0.14 * H} ${sw * 1.06} ${shY + 0.07 * H} ${sw} ${shY + 5} L ${sw * 0.32} ${shY - 3} Z`;
    elements.push(<path key="body" d={body} fill={spec.top.color} {...st} />);
    // side shade for volume
    elements.push(
      <path key="shade" d={`M ${-sw} ${shY + 6} C ${-sw * 1.04} ${shY + 0.07 * H} ${-ww * 1.08} ${shY + 0.14 * H} ${-ww} ${waistY} C ${-hw * 1.02} ${hipY - 0.04 * H} ${-hemW} ${hemY - 0.08 * H} ${-hemW} ${hemY} L ${-hemW * 0.72} ${hemY} C ${-hemW * 0.7} ${hipY} ${-ww * 0.75} ${shY + 0.14 * H} ${-sw * 0.7} ${shY + 8} Z`} fill={spec.top.shade} opacity={0.75} />,
    );
    if (fold) {
      // kurta / frock hem draped over the thighs
      const kx = 0.24 * H;
      elements.push(
        <path key="lap" d={`M ${-hemW * 0.9} ${hipY - 0.02 * H} C ${-hw * 0.4} ${hipY + 0.03 * H} ${kx * 0.6} ${hipY + 0.01 * H} ${kx + 0.03 * H} ${hipY + 0.005 * H} L ${kx + (kind === "frock" ? 0.04 * H : 0.01 * H)} ${hipY + 0.06 * H} L ${-hemW * 0.6} ${hipY + 0.07 * H} Z`} fill={spec.top.color} {...st} />,
      );
    }
    if (kind === "kurta") {
      elements.push(
        <path key="placket" d={`M ${sw * 0.18} ${shY - 2} L ${sw * 0.2} ${shY + 0.13 * H}`} stroke={spec.top.trim ?? spec.top.shade} strokeWidth={0.012 * H} />,
        <path key="neck" d={`M ${-sw * 0.32} ${shY - 3} Q ${0} ${shY + 0.035 * H} ${sw * 0.32} ${shY - 3}`} {...thin} strokeWidth={1.4} />,
      );
      if (!fold) elements.push(<path key="slit" d={`M ${-hemW * 0.98} ${hemY} L ${-hw * 1.0} ${hipY + 0.02 * H} M ${hemW * 0.98} ${hemY} L ${hw * 1.0} ${hipY + 0.02 * H}`} {...thin} />);
    }
    if (kind === "shirt") {
      elements.push(
        <path key="collar" d={`M ${-sw * 0.34} ${shY - 4} L ${-sw * 0.06} ${shY + 0.05 * H} L ${sw * 0.06} ${shY - 2} M ${sw * 0.34} ${shY - 4} L ${sw * 0.12} ${shY + 0.05 * H} L ${sw * 0.02} ${shY - 2}`} fill={spec.top.shade} stroke={INK} strokeWidth={1.4} vectorEffect="non-scaling-stroke" />,
        <path key="buttons" d={`M ${sw * 0.06} ${shY + 0.05 * H} L ${sw * 0.08} ${hemY}`} {...thin} />,
        <path key="pocket" d={`M ${-sw * 0.62} ${shY + 0.08 * H} l ${sw * 0.32} 0 l 0 ${0.05 * H} l ${-sw * 0.32} 0 Z`} {...thin} />,
      );
    }
    if (kind === "coat") {
      elements.push(
        <path key="lapel" d={`M ${-sw * 0.32} ${shY - 3} L ${sw * 0.02} ${shY + 0.13 * H} L ${sw * 0.32} ${shY - 3}`} fill={spec.top.trim ?? spec.top.shade} stroke={INK} strokeWidth={1.4} vectorEffect="non-scaling-stroke" />,
        <path key="front" d={`M ${sw * 0.04} ${shY + 0.13 * H} L ${sw * 0.06} ${hemY}`} {...thin} strokeWidth={1.5} />,
        ...[0.17, 0.24, 0.31].map((f) => <circle key={f} cx={sw * 0.16} cy={shY + f * H} r={0.008 * H} fill={INK} />),
        <path key="pockets" d={`M ${-hw * 0.9} ${hipY + 0.02 * H} l ${hw * 0.45} 0 M ${hw * 0.3} ${hipY + 0.02 * H} l ${hw * 0.45} 0`} {...thin} />,
      );
    }
    if (kind === "cardigan") {
      elements.push(
        <path key="shirtV" d={`M ${-sw * 0.3} ${shY - 3} L ${sw * 0.02} ${shY + 0.2 * H} L ${sw * 0.36} ${shY - 3} Z`} fill={spec.top.trim} stroke={INK} strokeWidth={1.2} vectorEffect="non-scaling-stroke" />,
        <path key="front" d={`M ${sw * 0.02} ${shY + 0.2 * H} L ${sw * 0.05} ${hemY}`} {...thin} />,
        ...[0.23, 0.29].map((f) => <circle key={f} cx={sw * 0.1} cy={shY + f * H} r={0.007 * H} fill={INK} />),
      );
    }
    if (kind === "frock") {
      elements.push(
        <path key="waistband" d={`M ${-ww * 1.02} ${waistY} L ${ww * 1.02} ${waistY}`} stroke={spec.top.shade} strokeWidth={0.02 * H} />,
        <path key="collar" d={`M ${-sw * 0.34} ${shY - 3} Q ${-sw * 0.15} ${shY + 0.05 * H} ${0} ${shY + 0.01 * H} Q ${sw * 0.15} ${shY + 0.05 * H} ${sw * 0.34} ${shY - 3}`} fill={spec.top.trim} stroke={INK} strokeWidth={1.2} vectorEffect="non-scaling-stroke" />,
        !fold ? <path key="gathers" d={`M ${-ww * 0.6} ${waistY + 0.01 * H} L ${-hemW * 0.6} ${hemY} M 0 ${waistY + 0.01 * H} L 0 ${hemY} M ${ww * 0.6} ${waistY + 0.01 * H} L ${hemW * 0.6} ${hemY}`} {...thin} opacity={0.6} /> : null,
      );
    }
  }

  if (spec.acc.apron) {
    const a = spec.acc.apron;
    const bot = sitting ? hipY + 0.02 * H : -0.36 * H;
    elements.push(
      <path key="apron" d={`M ${-sw * 0.42} ${shY + 0.07 * H} L ${sw * 0.48} ${shY + 0.07 * H} L ${sw * 0.62} ${waistY} L ${hw * 0.95} ${bot} L ${-hw * 0.9} ${bot} L ${-sw * 0.6} ${waistY} Z`} fill={a.color} {...st} />,
      <path key="apronStrap" d={`M ${-sw * 0.42} ${shY + 0.07 * H} L ${-sw * 0.3} ${shY - 3} M ${sw * 0.48} ${shY + 0.07 * H} L ${sw * 0.32} ${shY - 3}`} stroke={a.shade} strokeWidth={0.012 * H} />,
      <path key="apronPocket" d={`M ${-hw * 0.5} ${hipY - 0.02 * H} l ${hw * 1.1} 0 l 0 ${0.06 * H} l ${-hw * 1.1} 0 Z M ${hw * 0.05} ${hipY - 0.02 * H} l 0 ${0.06 * H}`} {...thin} />,
      <path key="screwdriver" d={`M ${-hw * 0.3} ${hipY - 0.05 * H} l 0 ${0.04 * H}`} stroke="#b3261e" strokeWidth={0.012 * H} />,
    );
  }
  if (spec.acc.jacket) {
    const jk = spec.acc.jacket;
    const bot = sitting ? hipY + 0.01 * H : hipY + 0.02 * H;
    elements.push(
      <path key="jacket" d={`M ${-sw * 0.3} ${shY - 2} L ${-sw * 0.92} ${shY + 6} C ${-sw * 0.9} ${shY + 0.1 * H} ${-ww * 1.08} ${shY + 0.16 * H} ${-ww * 1.04} ${waistY} L ${-hw * 1.06} ${bot} L ${hw * 1.06} ${bot} L ${ww * 1.06} ${waistY} C ${ww * 1.1} ${shY + 0.16 * H} ${sw * 0.95} ${shY + 0.1 * H} ${sw * 0.92} ${shY + 6} L ${sw * 0.3} ${shY - 2} L ${sw * 0.06} ${shY + 0.03 * H} Z`} fill={jk.color} {...st} />,
      <path key="jacketFront" d={`M ${sw * 0.06} ${shY + 0.03 * H} L ${sw * 0.08} ${bot}`} stroke={jk.shade} strokeWidth={2} vectorEffect="non-scaling-stroke" />,
      ...[0.08, 0.14, 0.2, 0.26].map((f) => <circle key={`jb${f}`} cx={sw * 0.14} cy={shY + f * H} r={0.006 * H} fill="#b89a5a" />),
      <path key="jacketCollar" d={`M ${-sw * 0.3} ${shY - 2} L ${-sw * 0.3} ${shY - 0.02 * H} M ${sw * 0.3} ${shY - 2} L ${sw * 0.3} ${shY - 0.02 * H}`} stroke={jk.color} strokeWidth={0.02 * H} />,
    );
  }
  if (spec.acc.dupatta) {
    const d = spec.acc.dupatta;
    const bot = sitting ? hipY + 0.03 * H : -0.42 * H;
    elements.push(
      <path key="dup" d={`M ${-sw * 0.95} ${shY + 2} C ${-sw * 0.5} ${shY + 0.08 * H} ${sw * 0.4} ${shY + 0.08 * H} ${sw * 0.95} ${shY + 2} L ${sw * 0.9} ${shY + 0.04 * H} C ${sw * 0.35} ${shY + 0.12 * H} ${-sw * 0.4} ${shY + 0.12 * H} ${-sw * 0.82} ${shY + 0.05 * H} Z`} fill={d.color} {...st} />,
      <path key="dupEnd" d={`M ${-sw * 0.98} ${shY + 4} C ${-sw * 1.06} ${shY + 0.15 * H} ${-sw * 1.02} ${bot - 0.05 * H} ${-sw * 0.92} ${bot} L ${-sw * 0.62} ${bot} C ${-sw * 0.66} ${bot - 0.08 * H} ${-sw * 0.7} ${shY + 0.12 * H} ${-sw * 0.68} ${shY + 0.06 * H} Z`} fill={d.shade} {...st} />,
    );
  }
  if (spec.acc.whistle) {
    elements.push(
      <path key="string" d={`M ${-sw * 0.3} ${shY - 2} Q ${0} ${shY + 0.12 * H} ${sw * 0.3} ${shY - 2}`} stroke="#b8392f" strokeWidth={1.6} vectorEffect="non-scaling-stroke" fill="none" />,
      <rect key="whistle" x={-0.015 * H} y={shY + 0.085 * H} width={0.045 * H} height={0.022 * H} rx={0.008 * H} fill="#b9bcc0" stroke={INK} strokeWidth={1.2} vectorEffect="non-scaling-stroke" />,
    );
  }
  if (spec.acc.pencil) {
    // pencil drawn with head (behind ear) - handled in Person
  }
  return <g>{elements}</g>;
};

/**
 * Full character rig. Origin = floor point under the hips; faces +x (use <At flip>).
 * Children placed via nearHold/farHold are drawn in the hand's local frame.
 */
export const Person: React.FC<{
  spec: CharSpec;
  pose: Pose;
  nearHold?: React.ReactNode;
  farHold?: React.ReactNode;
  silhouette?: string;
  hideHead?: boolean;
  headphones?: "on" | "neck";
}> = ({ spec, pose, nearHold, farHold, silhouette, hideHead, headphones }) => {
  const filt = useSvgId("sil");
  const j = computeJoints(spec, pose);
  const H = spec.H;
  const lean = pose.lean ?? (pose.stance === "crouch" ? 28 : 0);
  const br = (pose.breath ?? 0) * 0.006;
  const hs = j.hh / 103;
  const headX = spec.shoulder * H * 0.05;
  const headY = j.chinY - 48 * hs + 0.006 * H;
  const neckW = 0.042 * H;
  const back = pose.view === "back";
  const bob = pose.stance === "walk" ? -Math.abs(Math.sin((pose.walk ?? 0) * Math.PI * 2)) * 0.012 * H : 0;
  const pivotY = j.hipY;

  const upper = (
    <g transform={`translate(0 ${j.upperDy + bob}) rotate(${lean} 0 ${pivotY}) translate(0 ${pivotY}) scale(1 ${1 + br}) translate(0 ${-pivotY})`}>
      {!back ? (
        <Arm spec={spec} sh={j.farSh} j={j.far} hand={pose.far?.hand ?? "relaxed"} hold={farHold} far />
      ) : null}
      <Torso spec={spec} pose={pose} j={j} />
      {/* neck */}
      <path
        d={`M ${headX - neckW * 0.5} ${j.chinY - 0.01 * H} L ${headX - neckW * 0.55} ${j.shY + 2} L ${headX + neckW * 0.6} ${j.shY + 2} L ${headX + neckW * 0.55} ${j.chinY - 0.01 * H} Z`}
        fill={spec.skin}
        stroke={INK}
        strokeWidth={1.6}
        vectorEffect="non-scaling-stroke"
      />
      <path d={`M ${headX - neckW * 0.5} ${j.chinY} L ${headX + neckW * 0.5} ${j.chinY + 0.012 * H} L ${headX + neckW * 0.5} ${j.chinY + 0.022 * H} L ${headX - neckW * 0.52} ${j.chinY + 0.02 * H} Z`} fill={spec.skinShade} opacity={0.5} />
      {!hideHead ? (
        <g transform={`translate(${headX} ${headY}) rotate(${pose.headTilt ?? 0} 0 ${40}) scale(${hs})`}>
          <Head spec={spec} pose={pose} />
          {headphones === "on" ? (
            <g>
              <path d="M -30 0 C -40 -70 30 -78 30 -20" fill="none" stroke="#1b1b1d" strokeWidth={9} />
              <rect x={-36} y={-12} width={20} height={34} rx={8} fill="#202023" stroke={INK} strokeWidth={1.4} vectorEffect="non-scaling-stroke" />
            </g>
          ) : null}
          {spec.acc.pencil && !back ? (
            <path d="M -40 -8 L -14 -12" stroke="#d8b04a" strokeWidth={4} strokeLinecap="round" />
          ) : null}
        </g>
      ) : null}
      {headphones === "neck" && !back ? (
        <g transform={`translate(${headX} ${j.shY - 2})`}>
          <path d={`M ${-0.05 * H} 0 C ${-0.04 * H} ${0.05 * H} ${0.05 * H} ${0.05 * H} ${0.055 * H} 0`} fill="none" stroke="#1b1b1d" strokeWidth={0.012 * H} />
          <rect x={-0.065 * H} y={-0.015 * H} width={0.03 * H} height={0.045 * H} rx={0.01 * H} fill="#202023" />
          <rect x={0.04 * H} y={-0.015 * H} width={0.03 * H} height={0.045 * H} rx={0.01 * H} fill="#202023" />
        </g>
      ) : null}
      {back ? null : (
        <Arm spec={spec} sh={j.nearSh} j={j.near} hand={pose.near?.hand ?? "relaxed"} hold={nearHold} />
      )}
      {back ? (
        <>
          <Arm spec={spec} sh={{ x: -j.nearSh.x * 1.1, y: j.nearSh.y }} j={{ elbow: { x: -j.near.elbow.x, y: j.near.elbow.y }, wrist: { x: -j.near.wrist.x, y: j.near.wrist.y }, handAng: -j.near.handAng }} hand={pose.near?.hand ?? "relaxed"} />
          <Arm spec={spec} sh={{ x: -j.farSh.x * 1.1, y: j.farSh.y }} j={{ elbow: { x: -j.far.elbow.x, y: j.far.elbow.y }, wrist: { x: -j.far.wrist.x, y: j.far.wrist.y }, handAng: -j.far.handAng }} hand={pose.far?.hand ?? "relaxed"} far />
        </>
      ) : null}
    </g>
  );

  const body = (
    <g>
      <Legs spec={spec} pose={pose} side="far" />
      <Legs spec={spec} pose={pose} side="near" />
      {upper}
    </g>
  );

  if (!silhouette) return body;
  return (
    <g>
      <filter id={filt} x="-50%" y="-50%" width="200%" height="200%">
        <feFlood floodColor={silhouette} />
        <feComposite in2="SourceAlpha" operator="in" />
      </filter>
      <g filter={`url(#${filt})`}>{body}</g>
    </g>
  );
};

/**
 * Two-bone IK: arm pose that puts the wrist at `target` (character-local units,
 * same space as computeJoints, i.e. before the <At> placement). Elbow bends down.
 */
export const reach = (spec: CharSpec, pose: Pose, side: "near" | "far", target: Pt, hand: HandShape = "relaxed", wr = 0): ArmPose => {
  const H = spec.H;
  const j = computeJoints(spec, pose);
  const lean = pose.lean ?? (pose.stance === "crouch" ? 28 : 0);
  const pivot = { x: 0, y: j.hipY + j.upperDy };
  // undo the torso lean (rotation about the hip pivot) so IK runs in torso space
  const r = (-lean * Math.PI) / 180;
  const dx = target.x - pivot.x;
  const dy = target.y - pivot.y;
  const tx = pivot.x + dx * Math.cos(r) - dy * Math.sin(r);
  const ty = pivot.y + dx * Math.sin(r) + dy * Math.cos(r) - j.upperDy;
  const S = side === "near" ? j.nearSh : j.farSh;
  const L1 = 0.185 * H;
  const L2 = 0.155 * H;
  const vx = tx - S.x;
  const vy = ty - S.y;
  const d = Math.min(Math.hypot(vx, vy), L1 + L2 - 0.5);
  const base = (Math.atan2(vx, vy) * 180) / Math.PI;
  const cosA = Math.max(-1, Math.min(1, (L1 * L1 + d * d - L2 * L2) / (2 * L1 * d)));
  const A = (Math.acos(cosA) * 180) / Math.PI;
  const a = base - A;
  const E = add(S, L1, a);
  const b = (Math.atan2(tx - E.x, ty - E.y) * 180) / Math.PI;
  return { sh: a, el: b - a, wr, hand };
};

/** World -> character-local for a figure placed with <At x y s flip>. */
export const toLocal = (world: Pt, place: { x: number; y: number; s: number; flip?: boolean }): Pt => ({
  x: ((world.x - place.x) / place.s) * (place.flip ? -1 : 1),
  y: (world.y - place.y) / place.s,
});
