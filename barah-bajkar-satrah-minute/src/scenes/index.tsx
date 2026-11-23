import React from "react";
import { AbsoluteFill } from "remotion";
import { STORYBOARD } from "../data/storyboard";
import * as A from "./s00_s02";
import * as B from "./s03_s08";
import * as C from "./s09_s14";
import * as D from "./s15_s22";

const MODULES: Record<string, unknown>[] = [A, B, C, D];

/** Beat id ("S03-01") -> component, collected from exports named S03_01 etc. */
export const IMPLEMENTED: Record<string, React.FC> = Object.fromEntries(
  MODULES.flatMap((m) => Object.entries(m))
    .filter(([k]) => /^S\d\d_\d\d$/.test(k))
    .map(([k, v]) => [k.replace("_", "-"), v as React.FC]),
);

/** Visible placeholder for a beat without a component (development only; `npm run check` fails on it). */
const pending = (id: string): React.FC => {
  const C: React.FC = () => (
    <AbsoluteFill style={{ backgroundColor: "#1a1220", color: "#e8a54b", fontSize: 60, justifyContent: "center", alignItems: "center" }}>PENDING {id}</AbsoluteFill>
  );
  return C;
};

export const SCENES: Record<string, React.FC> = Object.fromEntries(STORYBOARD.map((b) => [b.id, IMPLEMENTED[b.id] ?? pending(b.id)]));
