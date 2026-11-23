import React, { createContext, useContext } from "react";
import { AbsoluteFill } from "remotion";

export const W = 1920;
export const H = 1080;

/** Camera: world point (x, y) is shown at frame centre with zoom z. */
export type Cam = { x: number; y: number; z: number; rot?: number };
export const WIDE: Cam = { x: W / 2, y: H / 2, z: 1 };

const CamCtx = createContext<Cam>(WIDE);
export const useCam = () => useContext(CamCtx);

/**
 * One SVG per shot. Sets and characters are drawn in a 1920x1080 world; the
 * camera is a transform, so close-ups re-rasterise the vector art crisply.
 */
export const Stage: React.FC<{
  cam: Cam;
  bg?: string;
  children: React.ReactNode;
  overlay?: React.ReactNode;
}> = ({ cam, bg = "#000", children, overlay }) => {
  return (
    <AbsoluteFill style={{ backgroundColor: bg }}>
      <svg
        viewBox={`0 0 ${W} ${H}`}
        width="100%"
        height="100%"
        style={{ position: "absolute", inset: 0 }}
        strokeLinejoin="round"
        strokeLinecap="round"
      >
        <CamCtx.Provider value={cam}>{children}</CamCtx.Provider>
      </svg>
      {overlay}
    </AbsoluteFill>
  );
};

/**
 * Parallax layer. p = 1 moves exactly with the world; p < 1 is farther (moves less),
 * p > 1 is nearer foreground.
 */
export const Layer: React.FC<{ p?: number; children: React.ReactNode; opacity?: number }> = ({
  p = 1,
  children,
  opacity,
}) => {
  const cam = useCam();
  const z = 1 + (cam.z - 1) * p;
  const x = W / 2 + (cam.x - W / 2) * p;
  const y = H / 2 + (cam.y - H / 2) * p;
  const rot = cam.rot ?? 0;
  return (
    <g
      opacity={opacity}
      transform={`translate(${W / 2} ${H / 2}) rotate(${rot}) scale(${z}) translate(${-x} ${-y})`}
    >
      {children}
    </g>
  );
};

/** Screen-space group (not affected by camera). */
export const Screen: React.FC<{ children: React.ReactNode }> = ({ children }) => <g>{children}</g>;

/** Place a child at world coordinates with optional scale/flip. */
export const At: React.FC<{
  x: number;
  y: number;
  s?: number;
  flip?: boolean;
  rot?: number;
  opacity?: number;
  children: React.ReactNode;
}> = ({ x, y, s = 1, flip = false, rot = 0, opacity, children }) => (
  <g
    opacity={opacity}
    transform={`translate(${x} ${y}) rotate(${rot}) scale(${flip ? -s : s} ${s})`}
  >
    {children}
  </g>
);
