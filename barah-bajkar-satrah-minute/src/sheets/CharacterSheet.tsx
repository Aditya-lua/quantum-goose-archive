import React from "react";
import { AbsoluteFill } from "remotion";
import { At, Stage, WIDE } from "../engine/Stage";
import * as CH from "../rigs/characters";
import { Person } from "../rigs/Person";
import { Head } from "../rigs/Head";
import type { CharSpec, ExprName } from "../rigs/types";
import { C } from "../style/palette";
import { FONT_BODY } from "../style/fonts";

const ROW: { spec: CharSpec; label: string }[] = [
  { spec: CH.meeraAdult, label: "मीरा (32)" },
  { spec: CH.meeraRain, label: "मीरा — बरसाती" },
  { spec: CH.meeraChild, label: "मीरा (10)" },
  { spec: CH.dineshOld, label: "दिनेश (बाद में)" },
  { spec: CH.dineshYoung, label: "दिनेश (22 साल पहले)" },
  { spec: CH.mother, label: "माँ" },
  { spec: CH.anshu, label: "अंशु" },
  { spec: CH.kabir, label: "कबीर" },
  { spec: CH.vikram, label: "विक्रम वशिष्ठ" },
  { spec: CH.harish, label: "हरीश काका" },
];

const EXPRS: ExprName[] = ["neutral", "listen", "tense", "grief", "shock", "crying", "soft", "laugh"];

/** Reference sheet: full figures (top) and expression heads (bottom). */
export const CharacterSheet: React.FC = () => {
  return (
    <AbsoluteFill style={{ backgroundColor: C.paper }}>
      <Stage cam={WIDE} bg={C.paper}>
        <rect x={0} y={0} width={1920} height={1080} fill={C.paper} />
        {ROW.map((r, i) => (
          <At key={r.spec.id} x={110 + i * 185} y={640} s={0.86}>
            <Person
              spec={r.spec}
              pose={{ stance: "stand", expr: "neutral", near: { sh: 6, el: 10, hand: "relaxed" }, far: { sh: -6, el: 8 } }}
            />
          </At>
        ))}
        {EXPRS.map((e, i) => (
          <At key={e} x={140 + i * 220} y={820} s={1.35}>
            <Head spec={CH.meeraAdult} pose={{ stance: "stand", expr: e }} />
          </At>
        ))}
        {EXPRS.slice(0, 6).map((e, i) => (
          <At key={`k${e}`} x={140 + i * 220} y={985} s={1.0}>
            <Head spec={[CH.kabir, CH.dineshYoung, CH.mother, CH.anshu, CH.vikram, CH.harish][i]} pose={{ stance: "stand", expr: e }} />
          </At>
        ))}
        <At x={1520} y={985} s={1.0}>
          <Head spec={CH.meeraChild} pose={{ stance: "stand", expr: "fear" }} />
        </At>
        <At x={1720} y={985} s={1.0}>
          <Head spec={CH.dineshOld} pose={{ stance: "stand", expr: "tired" }} />
        </At>
      </Stage>
      <AbsoluteFill style={{ fontFamily: FONT_BODY, color: C.ink }}>
        {ROW.map((r, i) => (
          <div key={r.spec.id} style={{ position: "absolute", left: 110 + i * 185 - 90, width: 180, top: 652, textAlign: "center", fontSize: 19 }}>
            {r.label}
          </div>
        ))}
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
