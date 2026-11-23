import React from "react";
import { camAt, cutIndex, Shot, useBeat } from "../engine/beat";
import { kf, ramp } from "../engine/anim";
import { At, Layer } from "../engine/Stage";
import { HouseFront } from "../sets/House";
import { StudyBack, Chair, STUDY } from "../sets/Study";
import { HospitalVerandah } from "../sets/Hospital";
import { Recorder, Paper, Cassette } from "../props/Props";
import { BigHand } from "../rigs/BigHand";
import { meeraAdult, meeraChild, dineshYoung } from "../rigs/characters";
import type { Pose } from "../rigs/types";
import { at, endOf } from "../timing/time";
import { Actor, alive, PLACES, reachW, recorderKey, shoulderWorld, TitleCard } from "./common";

const M = meeraAdult;
const desk = PLACES.meeraAtDesk;
const rec = PLACES.recorderAtDesk;
const playKey = recorderKey(1);

/** Meera seated at the study desk; `hover` 0..1 raises her near hand over the Play key. */
const MeeraDesk: React.FC<{ t: number; hover: number; freeze?: number; expr?: Pose["expr"]; gaze?: [number, number]; tilt?: number; tremble?: number }> = ({
  t,
  hover,
  freeze = 0,
  expr = "listen",
  gaze = [0.7, 0.55],
  tilt = 10,
  tremble = 0,
}) => {
  const base: Pose = alive(t, "meeraDesk", { stance: "sit", lean: 10, headTilt: tilt, gazeX: gaze[0], gazeY: gaze[1], expr }, 0.6);
  const rest = { x: 960, y: STUDY.deskTop - 6 };
  const over = { x: playKey.x - 22 + Math.sin(t * 9) * tremble, y: playKey.y - 30 - freeze * 6 };
  const target = { x: rest.x + (over.x - rest.x) * hover, y: rest.y + (over.y - rest.y) * hover };
  const pose: Pose = {
    ...base,
    near: reachW(M, base, "near", target, desk, hover > 0.92 ? "point" : "relaxed", hover * 35),
    far: reachW(M, base, "far", { x: 930, y: STUDY.deskTop - 4 }, desk, "relaxed", 60),
  };
  return (
    <>
      <At x={desk.x - 40} y={desk.y} s={0.95}>
        <Chair />
      </At>
      <Actor spec={M} place={desk} pose={pose} />
    </>
  );
};

const StudyRecorder: React.FC<{ f: number; playing: boolean; playFrom?: number; pressed?: "play" | "stop" | null; angle?: number; lift?: number; cassetteIn?: boolean }> = (p) => (
  <At x={rec.x} y={rec.y} s={1}>
    <Recorder w={rec.w} frame={p.f} playing={p.playing} playFrom={p.playFrom} pressed={p.pressed} angle={p.angle} cassetteLift={p.lift} cassetteIn={p.cassetteIn ?? true} />
  </At>
);

// S00-01 — title over the house at night
export const S00_01: React.FC = () => {
  const { f, lt, dur } = useBeat();
  const cam = camAt(lt, [
    [0, { x: 960, y: 560, z: 1.0 }],
    [dur + 0.6, { x: 1040, y: 590, z: 1.22 }],
  ]);
  return (
    <Shot cam={cam} grade="present" overlay={<TitleCard lt={lt} dur={dur + 0.6} />}>
      <Layer>
        <HouseFront frame={f} time="night" rain={1} windowLit={1} />
      </Layer>
    </Shot>
  );
};

// S01-01 — study: her hand hovers above Play
export const S01_01: React.FC = () => {
  const { f, t, lt, dur } = useBeat();
  const cam = camAt(lt, [
    [0, { x: 960, y: 600, z: 1.25 }],
    [dur, { x: 990, y: 640, z: 1.55 }],
  ]);
  const hover = ramp(lt, dur * 0.25, dur * 0.85);
  return (
    <Shot cam={cam} grade="present">
      <Layer>
        <StudyBack frame={f} clockStart={null} />
        <StudyRecorder f={f} playing={false} />
        <MeeraDesk t={t} hover={hover} tremble={1.5 * hover} expr="tense" />
      </Layer>
    </Shot>
  );
};

/** Insert: big hand over the recorder keys. press 0..1 moves the finger down. */
const KeyInsert: React.FC<{ f: number; press: number; playing: boolean; playFrom: number; angle?: number; handIn: number; showHand?: boolean; lift?: number; cam: { x: number; y: number; z: number } }> = ({
  f,
  press,
  playing,
  playFrom,
  angle,
  handIn,
  showHand = true,
  lift = 0,
  cam,
}) => {
  const hx = playKey.x - 6 - (1 - handIn) * 80;
  const hy = playKey.y - 62 + press * 5 - (1 - handIn) * 40;
  return (
    <Shot cam={cam} grade="present">
      <Layer>
        <StudyBack frame={f} clockStart={null} />
        <StudyRecorder f={f} playing={playing} playFrom={playFrom} pressed={press > 0.6 ? "play" : null} angle={angle} lift={lift} />
        {showHand ? (
          <At x={hx} y={hy} s={0.33} rot={160}>
            <BigHand skin={M.skin} shade={M.skinShade} sleeve={M.top.color} sleeveShade={M.top.shade} watch pose={{ curl: [0.55, 0.0, 0.85, 0.9, 0.9], spread: 0 }} />
          </At>
        ) : null}
      </Layer>
    </Shot>
  );
};

// S01-02 — Play is pressed; the reels begin to turn
export const S01_02: React.FC = () => {
  const { f, lt, dur } = useBeat();
  const press = kf(lt, [[0.2, 0], [0.55, 1]]);
  const playFrom = Math.round(0.55 * 24);
  const cutAt = Math.min(4.2, dur * 0.55);
  const shot = cutIndex(lt, [cutAt]);
  if (shot === 0) {
    const cam = camAt(lt, [
      [0, { x: playKey.x - 10, y: playKey.y + 12, z: 5.6 }],
      [cutAt, { x: playKey.x + 4, y: playKey.y + 16, z: 6.1 }],
    ]);
    return <KeyInsert f={f} press={press} playing={lt > 0.55} playFrom={f - Math.round(lt * 24) + playFrom} handIn={1} cam={cam} />;
  }
  // reels turning while the sentence plays; hand withdrawn
  const cam = camAt(lt - cutAt, [
    [0, { x: rec.x + rec.w * 0.22, y: rec.y - rec.w * 0.27, z: 22 }],
    [dur, { x: rec.x + rec.w * 0.22, y: rec.y - rec.w * 0.27, z: 24 }],
  ]);
  return <KeyInsert f={f} press={1} playing playFrom={f - Math.round(lt * 24) + playFrom} handIn={0} showHand={false} cam={cam} />;
};

// S01-03 — her hand freezes; rain; his breathing
export const S01_03: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const rainAt = T(at(5, "बाहर बारिश"));
  const breathAt = T(at(5, "घर की छत"));
  const shot = cutIndex(lt, [rainAt, breathAt]);
  const playing = true;
  const reelFrom = f - Math.round(lt * 24) - 200;
  if (shot === 1) {
    const cam = camAt(lt - rainAt, [
      [0, { x: 500, y: 410, z: 2.5 }],
      [breathAt - rainAt, { x: 520, y: 400, z: 2.7 }],
    ]);
    return (
      <Shot cam={cam} grade="present">
        <Layer>
          <StudyBack frame={f} clockStart={null} rain={1.3} />
        </Layer>
      </Shot>
    );
  }
  const cam =
    shot === 0
      ? camAt(lt, [
          [0, { x: 880, y: 600, z: 1.9 }],
          [rainAt, { x: 875, y: 600, z: 2.0 }],
        ])
      : camAt(lt - breathAt, [
          [0, { x: 900, y: 610, z: 2.5 }],
          [dur - breathAt, { x: 890, y: 605, z: 2.75 }],
        ]);
  const lower = ramp(lt, breathAt + 1.5, breathAt + 4);
  const closeEyes = shot === 2 && lt > T(at(5, "धीमी और भारी")) ? 0.75 : 0;
  return (
    <Shot cam={cam} grade="present">
      <Layer>
        <StudyBack frame={f} clockStart={null} />
        <StudyRecorder f={f} playing={playing} playFrom={reelFrom} />
        <MeeraDesk t={t} hover={1 - lower * 0.6} freeze={1} expr={{ browInner: 0.55, browY: 0.15, lid: closeEyes || 0.15, lower: 0.05, mouth: -0.25, open: 0.06 }} gaze={[0.6, 0.3]} tilt={4} />
      </Layer>
    </Shot>
  );
};

// S01-04 — the tape stops
export const S01_04: React.FC = () => {
  const { f, lt } = useBeat();
  const base = (f - Math.round(lt * 24) - 400) * 9;
  // reels decelerate to a stop over ~0.5 s
  const angle = base + kf(lt, [[0, 0], [0.55, 60]]) + Math.min(lt, 0) * 0;
  const pressed = lt < 0.4 ? "play" : null;
  const cam = camAt(lt, [
    [0, { x: rec.x + rec.w * 0.22, y: rec.y - rec.w * 0.27, z: 24 }],
    [2, { x: rec.x + rec.w * 0.22, y: rec.y - rec.w * 0.27, z: 24.5 }],
  ]);
  return (
    <Shot cam={cam} grade="present">
      <Layer>
        <StudyBack frame={f} clockStart={null} />
        <StudyRecorder f={f} playing={false} angle={angle} pressed={pressed} />
      </Layer>
    </Shot>
  );
};

// S01-05 — the note «पहले पूरी बात सुनना» in her hand (lines 9–11 are not read
// in the recording; the note is shown as picture under «बाईस साल पहले भी...»)
export const S01_05: React.FC = () => {
  const { lt, dur } = useBeat();
  const cam = camAt(lt, [
    [0, { x: 960, y: 560, z: 1.0 }],
    [dur, { x: 1000, y: 540, z: 1.12 }],
  ]);
  return (
    <Shot cam={cam} grade="present" bg="#191a22">
      <Layer>
        <rect x={-100} y={-100} width={2200} height={1300} fill="#2a2520" />
        <rect x={-100} y={640} width={2200} height={600} fill="#4a3324" />
        <At x={600} y={720} s={2.3} rot={-12}>
          <Cassette w={160} label="" />
        </At>
        <At x={1060} y={520} s={1} rot={-3}>
          <Paper w={720} h={300} lines={["पहले पूरी बात सुनना।"]} size={78} color="#f4efe2" />
        </At>
        <At x={1360} y={700} s={0.85} rot={-35}>
          <BigHand skin={M.skin} shade={M.skinShade} sleeve={M.top.color} sleeveShade={M.top.shade} watch pose={{ curl: [0.3, 0.35, 0.4, 0.5, 0.55] }} />
        </At>
      </Layer>
    </Shot>
  );
};

// S02-01 — hospital verandah, 22 years earlier
const childBench = { x: 330, y: 980, s: 1.05 };
export const S02_01: React.FC = () => {
  const { t, lt, dur } = useBeat();
  const walk = Math.min(lt, dur);
  const dx = 1350 - Math.min(walk * 95, 700);
  const walking = walk * 95 < 700;
  const cam = camAt(lt, [
    [0, { x: 900, y: 560, z: 1.0 }],
    [dur, { x: 820, y: 580, z: 1.12 }],
  ]);
  return (
    <Shot cam={cam} grade="hospital" memoryEdge={0.55}>
      <Layer>
        <HospitalVerandah />
        <Actor spec={meeraChild} place={childBench} pose={alive(t, "childHosp", { stance: "sit", lean: 18, headTilt: 16, gazeX: -0.2, gazeY: 0.8, expr: "grief", near: { sh: 40, el: 60, hand: "relaxed" }, far: { sh: 30, el: 70 } })} />
        <Actor
          spec={dineshYoung}
          place={{ x: dx, y: 1010, s: 0.92, flip: true }}
          pose={alive(t, "dinHosp", { stance: walking ? "walk" : "stand", walk: walk * 95 / 280, headTilt: 12, gazeY: 0.5, expr: "grief", near: { sh: walking ? -12 * Math.sin(walk * 95 / 280 * 6.28) : 4, el: 12 }, far: { sh: walking ? 12 * Math.sin(walk * 95 / 280 * 6.28) : -4, el: 10 } })}
        />
      </Layer>
    </Shot>
  );
};

// S02-02 — he touches her shoulder; she jerks his hand away
export const S02_02: React.FC = () => {
  const { t, lt, dur, T } = useBeat();
  const jerk = T(at(13, "उसने उनका हाथ झटक दिया था।"));
  const touch = ramp(lt, 0.2, Math.max(0.6, jerk - 0.2));
  const away = ramp(lt, jerk, jerk + 0.35);
  // quick outward swipe of the arm nearest him, then it falls back
  const swipe = Math.max(0, Math.min(1, (lt - jerk) / 0.18)) * Math.max(0, 1 - Math.max(0, lt - jerk - 0.25) / 0.6);
  const dPlace = { x: 455, y: 1010, s: 0.92, flip: true };
  const dBase: Pose = alive(t, "dinTouch", { stance: "stand", lean: 8 + touch * 20 - away * 16, headTilt: 16, gazeX: 0.4, gazeY: 0.6, expr: away > 0.5 ? "grief" : "sad" });
  const shoulder = shoulderWorld(meeraChild, { stance: "sit", lean: 18 }, childBench, "far");
  const handTarget = {
    x: shoulder.x + 110 - touch * 104 + away * 120,
    y: shoulder.y + 40 - touch * 46 + away * 70,
  };
  const dPose: Pose = { ...dBase, near: reachW(dineshYoung, dBase, "near", handTarget, dPlace, "open", 50) };
  const cPose: Pose = alive(t, "childTouch", {
    stance: "sit",
    lean: 18 - away * 30,
    headTilt: 16 - away * 10,
    headTurn: away * -0.3,
    gazeX: -0.6 * away,
    gazeY: 0.7 - away * 0.4,
    expr: away > 0.3 ? "anger" : "grief",
    shoulderUp: away,
    near: { sh: 34 - away * 10, el: 50, hand: away > 0.3 ? "fist" : "relaxed" },
    far: { sh: 30 + swipe * 70 - away * 10, el: 60 - swipe * 40, wr: -20 * swipe, hand: "open" },
  });
  const cam = camAt(lt, [
    [0, { x: 470, y: 690, z: 2.0 }],
    [jerk, { x: 455, y: 680, z: 2.1 }],
    [dur, { x: 430, y: 690, z: 2.15 }],
  ]);
  return (
    <Shot cam={cam} grade="hospital" memoryEdge={0.55}>
      <Layer>
        <HospitalVerandah />
        <Actor spec={meeraChild} place={childBench} pose={cPose} />
        <Actor spec={dineshYoung} place={dPlace} pose={dPose} />
      </Layer>
    </Shot>
  );
};

// S02-03 — present: her face in lamp light, the stopped clock above
export const S02_03: React.FC = () => {
  const { f, t, lt, dur } = useBeat();
  const cam = camAt(lt, [
    [0, { x: 900, y: 500, z: 2.1 }],
    [dur, { x: 920, y: 480, z: 2.3 }],
  ]);
  const tEnd = endOf(13);
  return (
    <Shot cam={cam} grade="present">
      <Layer>
        <StudyBack frame={f} clockStart={null} />
        <StudyRecorder f={f} playing={false} />
        <MeeraDesk t={t} hover={0} expr={t > tEnd - 1 ? "sad" : "tired"} gaze={[0.2, 0.5]} tilt={14} />
      </Layer>
    </Shot>
  );
};
