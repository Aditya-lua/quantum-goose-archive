import React from "react";
import { AbsoluteFill } from "remotion";
import { camAt, cutIndex, Shot, useBeat } from "../engine/beat";
import { kf, ramp } from "../engine/anim";
import { At, Layer } from "../engine/Stage";
import type { Cam } from "../engine/Stage";
import { StudyBack, Chair, PlasticChair, STUDY } from "../sets/Study";
import { HouseFront, HOUSE } from "../sets/House";
import { SchoolGate, GATE, FloodLane, Water } from "../sets/Factory";
import { VikramOffice, OFFICE, MemorialYard, MEMORIAL, MemorialStone, Roadside, Newspaper, StatementDesk, FilesTable } from "../sets/Places";
import { Cassette, Diary, IDCard, Keys, Laptop, Paper, Phone, Recorder, Scribble, Waveform, Whistle, Microphone, Handwriting } from "../props/Props";
import { Clock, ClockBack } from "../props/Clock";
import { BigHand } from "../rigs/BigHand";
import { anshu, dineshYoung, harish, kabir, kabirStreet, meeraAdult, meeraChild, meeraMemorial, mother, vikram } from "../rigs/characters";
import { questionMan, roadFather, roadGirl, sisterWoman, townsperson } from "../rigs/crowd";
import type { CharSpec, Pose } from "../rigs/types";
import { at, envSlice, nf, para } from "../timing/time";
import { Actor, alive, PLACES, reachW, recorderKey, speaks, type Place } from "./common";
import { C } from "../style/palette";

const M = meeraAdult;
const rec = PLACES.recorderAtDesk;

/** Absolute film frame of the battery moment: the only time the clock may start. */
export const CLOCK_START = (): number => nf(at(319, "सेकंड की सुई"));

const walkPose = (t: number, seed: string, phase: number, extra: Partial<Pose> = {}): Pose =>
  alive(t, seed, {
    stance: "walk",
    walk: phase,
    near: { sh: -16 * Math.sin(phase * 6.283), el: 16, hand: "relaxed" },
    far: { sh: 16 * Math.sin(phase * 6.283), el: 14 },
    ...extra,
  });

const nodAt = (lt: number, t0: number) => Math.max(0, Math.sin(Math.max(0, Math.min(1, (lt - t0) / 0.9)) * Math.PI * 2)) * 9;

/** Study staging for S15/S16/S22: Meera at the desk, Kabir in the doorway or seated at the desk's end. */
const StudyScene: React.FC<{
  f: number;
  t: number;
  cam: Cam;
  grade?: "present" | "ending";
  meera?: Partial<Pose>;
  hands?: "desk" | "lap" | "page" | "clock" | "face";
  kabirAt?: "work" | "door" | "seat" | "none";
  kabirP?: Partial<Pose>;
  drawer?: number;
  laptop?: boolean;
  recorder?: { playing: boolean; playFrom?: number };
  clockStart?: number | null;
  hideClock?: boolean;
  lamp?: number;
  extra?: React.ReactNode;
  meeraPlace?: Place;
  meeraStand?: boolean;
}> = ({ f, t, cam, grade = "present", meera, hands = "desk", kabirAt = "none", kabirP, drawer = 0, laptop = true, recorder, clockStart = null, hideClock = false, lamp, extra, meeraPlace, meeraStand }) => {
  const place = meeraPlace ?? PLACES.meeraAtDesk;
  const ending = grade === "ending";
  const base: Pose = alive(t, "studyS", { stance: meeraStand ? "stand" : "sit", lean: meeraStand ? 0 : 10, headTilt: 8, gazeX: 0.8, gazeY: 0.3, expr: "listen", ...meera });
  const pose: Pose = {
    ...base,
    near:
      hands === "desk"
        ? reachW(M, base, "near", { x: 990, y: STUDY.deskTop - 6 }, place, "relaxed", 70)
        : hands === "page"
          ? reachW(M, base, "near", { x: 930, y: STUDY.deskTop - 60 }, place, "hold", 80)
          : hands === "clock"
            ? { sh: 40, el: 70, hand: "hold" }
            : hands === "face"
              ? { sh: 120, el: 115, hand: "open" }
              : { sh: 30, el: 60 },
    far: hands === "lap" || hands === "clock" ? { sh: 34, el: 66, hand: "hold" } : reachW(M, base, "far", { x: 950, y: STUDY.deskTop - 4 }, place, "relaxed", 60),
    ...(meera?.near ? { near: meera.near } : {}),
    ...(meera?.far ? { far: meera.far } : {}),
  };
  const kSeat: Place = { x: 1600, y: STUDY.floorY, s: 0.95, flip: true };
  return (
    <Shot cam={cam} grade={grade}>
      <Layer>
        <StudyBack frame={f} clockStart={clockStart} rain={ending ? 0 : 0.6} warm={ending ? 1 : 0} drawer={drawer} boxes={!ending} doorLight={ending ? 1 : 0.8} hideClock={hideClock} lamp={lamp ?? (ending ? 0.6 : 1)} />
        {kabirAt === "work" ? <Actor spec={kabir} place={{ x: 1790, y: 900, s: 0.62, flip: true }} pose={alive(t, "kW", { stance: "sit", lean: 24, headTilt: 20, gazeY: 0.9, near: { sh: 60, el: 60, hand: "grip" }, far: { sh: 50, el: 70 } })} /> : null}
        {kabirAt === "door" ? <Actor spec={kabir} place={{ x: 1730, y: STUDY.floorY - 30, s: 0.88, flip: true }} pose={alive(t, "kD", { stance: "stand", headTilt: 6, gazeX: 0.7, expr: "soft", near: { sh: 30, el: 60 }, far: { sh: -4, el: 14 }, ...kabirP })} /> : null}
        {kabirAt === "seat" ? (
          <>
            <At x={kSeat.x + 40} y={kSeat.y} s={0.95}>
              <g transform="scale(-1 1)">
                <Chair />
              </g>
            </At>
            <Actor spec={kabir} place={kSeat} pose={alive(t, "kS", { stance: "sit", lean: 12, headTilt: 8, gazeX: 0.8, gazeY: 0.3, expr: "soft", near: { sh: 40, el: 70 }, far: { sh: 30, el: 70 }, ...kabirP })} />
          </>
        ) : null}
        {laptop ? (
          <At x={1240} y={STUDY.deskTop} s={1}>
            <Laptop w={200} />
          </At>
        ) : null}
        {recorder ? (
          <At x={rec.x} y={rec.y} s={1}>
            <Recorder w={rec.w} frame={f} playing={recorder.playing} playFrom={recorder.playFrom ?? 0} />
          </At>
        ) : null}
        {!meeraStand ? (
          <At x={place.x - 40} y={place.y} s={0.95}>
            <Chair />
          </At>
        ) : null}
        <Actor spec={M} place={place} pose={pose} />
        {extra}
      </Layer>
    </Shot>
  );
};

const SC2 = {
  wide: { x: 1180, y: 560, z: 1.0 } as Cam,
  meera: { x: 860, y: 560, z: 2.4 } as Cam,
  meeraTight: { x: 830, y: 530, z: 3.2 } as Cam,
  door: { x: 1640, y: 560, z: 2.0 } as Cam,
  two: { x: 1180, y: 600, z: 1.35 } as Cam,
  kabirSeat: { x: 1560, y: 560, z: 2.4 } as Cam,
};

// S15-01 — she lifts her hand off the laptop: «मैंने उसका हाथ छोड़ा था।»
export const S15_01: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const said = T(at(181, "मैंने उसका"));
  const shot = cutIndex(lt, [said - 0.3]);
  return <StudyScene f={f} t={t} kabirAt="work" hands={lt > 0.8 ? "lap" : "desk"} cam={shot === 0 ? camAt(lt, [[0, SC2.wide], [said, { ...SC2.wide, x: 1100, z: 1.2 }]]) : SC2.meeraTight} meera={{ expr: "grief", gazeY: 0.7, talk: speaks(t, 181, "मैंने उसका", "था,”") }} />;
};

// S15-02 — Kabir at the door; «अंशु का...» «पानी में गिरी थीं तुम।» «फिर भी।»
export const S15_02: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const m1 = T(at(185));
  const k1 = T(at(187));
  const m2 = T(at(189));
  const shot = cutIndex(lt, [m1 - 0.1, k1 - 0.1, m2 - 0.1]);
  return (
    <StudyScene
      f={f}
      t={t}
      kabirAt="door"
      hands="lap"
      cam={shot === 0 || shot === 2 ? SC2.door : SC2.meera}
      kabirP={{ talk: speaks(t, 187), expr: "sad" }}
      meera={{ talk: speaks(t, 185) + speaks(t, 189), expr: "grief", gazeX: 0.9, headTurn: 0.3, gazeY: shot === 3 ? 0.7 : 0.2 }}
    />
  );
};

// S15-03 — «दस साल की बच्ची के हाथ में...» She bows her head; he goes back.
export const S15_03: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const bow = T(at(193));
  const shot = cutIndex(lt, [bow - 0.1]);
  return (
    <StudyScene
      f={f}
      t={t}
      kabirAt={shot === 0 ? "door" : lt > bow + 2.5 ? "work" : "door"}
      hands="lap"
      cam={shot === 0 ? camAt(lt, [[0, SC2.door], [bow, { ...SC2.door, z: 2.3 }]]) : camAt(lt - bow, [[0, SC2.meera], [dur - bow, SC2.meeraTight]])}
      kabirP={{ talk: speaks(t, 191, "मीरा, दस", "नहीं थी।”"), expr: "soft" }}
      meera={{ expr: "crying", headTilt: 8 + ramp(lt, bow, bow + 1) * 16, gazeY: 0.9 }}
    />
  );
};

/** Insert: pages on the desk under lamp light. */
const PageInsert: React.FC<{ cam: Cam; children: React.ReactNode }> = ({ cam, children }) => (
  <Shot cam={cam} grade="present" bg="#2a2018">
    <Layer>
      <rect x={-300} y={-300} width={2520} height={1600} fill="#4a3324" />
      {[...Array(10)].map((_, i) => (
        <line key={i} x1={-300} x2={2220} y1={i * 130} y2={i * 130 + 30} stroke="#3e2b1f" strokeWidth={4} />
      ))}
      <circle cx={1300} cy={300} r={900} fill="#f3c779" opacity={0.12} />
      {children}
    </Layer>
  </Shot>
);

// S16-01 — the drawer; the diary; her childhood school ID inside
export const S16_01: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const id = T(at(195, "बीच में"));
  const shot = cutIndex(lt, [Math.min(2.6, id - 0.2), id - 0.1]);
  if (shot === 0) return <StudyScene f={f} t={t} drawer={ramp(lt, 0.3, 1.4)} hands="desk" cam={{ x: 1150, y: 760, z: 2.6 }} meera={{ expr: "listen", gazeY: 0.9 }} />;
  const open = shot === 2 ? 1 : ramp(lt, 2.6, 3.4);
  return (
    <PageInsert cam={camAt(lt, [[0, { x: 960, y: 540, z: 1 }], [dur, { x: 960, y: 540, z: 1.1 }]])}>
      <At x={960} y={560} s={2.6}>
        <Diary w={260} open={open} />
      </At>
      {shot === 2 ? (
        <At x={700} y={540} s={2.4} rot={-6}>
          <IDCard w={150} />
        </At>
      ) : null}
    </PageInsert>
  );
};

const DIARY_197 = ["आज फिर फ़ोन किया।", "उसने कहा, काम में हूँ।", "अच्छी बात है।", "उसके पास काम है।"];
const LETTER_201 = [
  "मीरा, उस रात के बाद मैंने कई बार",
  "सोचा कि तुम्हें सब बता दूँ। हर बार अपने",
  "लिए कोई वजह ढूँढ़ ली। तुम छोटी हो।",
  "तुम्हारी पढ़ाई है। तुम्हारी नौकरी शुरू",
  "हुई है। सच यह है कि मुझे तुम्हारा",
  "सवाल सुनने से डर लगता था।",
  "आपने उनकी बात क्यों मानी?",
];

// S16-02 — the diary page in his hand
export const S16_02: React.FC = () => {
  const { lt, dur } = useBeat();
  return (
    <PageInsert cam={camAt(lt, [[0, { x: 960, y: 520, z: 1.05 }], [dur, { x: 960, y: 560, z: 1.18 }]])}>
      <At x={960} y={540} s={1} rot={-2}>
        <Paper w={900} h={720} lines={DIARY_197} size={64} color="#ebe2cb" lined />
      </At>
    </PageInsert>
  );
};

// S16-03 — hospital accounts; then the unfinished letter
export const S16_03: React.FC = () => {
  const { lt, dur, T } = useBeat();
  const letter = T(at(199, "उसके बाद"));
  const shot = cutIndex(lt, [letter - 0.1]);
  return (
    <PageInsert cam={camAt(lt, [[0, { x: 960, y: 540, z: 1.05 }], [dur, { x: 960, y: 540, z: 1.12 }]])}>
      {shot === 0 ? (
        <At x={960} y={540} s={1} rot={2}>
          <Paper w={900} h={720} scribbleLines={8} size={56} color="#ebe2cb" lined seed={7} />
          <Handwriting x={-380} y={-260} size={52} text="अस्पताल" color="#26335e" rot={-1} />
        </At>
      ) : (
        <At x={960} y={560} s={1} rot={-1.5}>
          <Paper w={980} h={800} lines={[LETTER_201[0]]} size={56} color="#f1ead6" lined />
        </At>
      )}
    </PageInsert>
  );
};

// S16-04 — the letter, line by line, ending on the question he feared
export const S16_04: React.FC = () => {
  const { lt, dur } = useBeat();
  const shown = Math.min(LETTER_201.length, 1 + Math.floor((lt / Math.max(1, dur - 1.5)) * LETTER_201.length));
  return (
    <PageInsert cam={camAt(lt, [[0, { x: 900, y: 340, z: 1.5 }], [dur, { x: 900, y: 700, z: 1.5 }]])}>
      <At x={960} y={560} s={1} rot={-1.5}>
        <Paper w={980} h={800} lines={LETTER_201.slice(0, shown)} size={56} color="#f1ead6" lined />
      </At>
    </PageInsert>
  );
};

// S16-05 — she lays the page down; «वे डर गए थे।» «हाँ।» «इतने साल?»
export const S16_05: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const enter = T(at(205));
  const yes = T(at(207));
  const years = T(at(209));
  const shot = cutIndex(lt, [enter - 0.1, yes - 0.1, years - 0.1]);
  return (
    <StudyScene
      f={f}
      t={t}
      kabirAt={shot >= 1 ? "door" : "work"}
      hands={shot === 0 ? "page" : "lap"}
      cam={shot === 2 ? SC2.door : shot === 0 ? SC2.meera : SC2.meeraTight}
      kabirP={{ talk: speaks(t, 207), expr: "sad" }}
      meera={{ talk: speaks(t, 205, "वे डर", "थे।”") + speaks(t, 209), expr: { browInner: 0.7, browY: 0.1, lid: 0.35, lower: 0.25, mouth: -0.4, open: 0, tears: 0.8 }, gazeX: 0.9, headTurn: 0.25 }}
    />
  );
};

// S16-06 — he pulls a chair close: his Abba's watch his mother never threw away
export const S16_06: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const speak = T(at(211, "मेरे अब्बा"));
  const shot = cutIndex(lt, [speak - 0.1]);
  return (
    <StudyScene
      f={f}
      t={t}
      kabirAt="seat"
      hands="lap"
      cam={shot === 0 ? SC2.two : camAt(lt - speak, [[0, SC2.kabirSeat], [6, { ...SC2.kabirSeat, z: 2.6 }]])}
      kabirP={{ talk: speaks(t, 211, "मेरे अब्बा", "पाते।”"), expr: "soft" }}
      meera={{ expr: "sad", gazeX: 0.9, gazeY: 0.3 }}
    />
  );
};

/** Vikram's office staging. */
const OfficeScene: React.FC<{ f: number; t: number; cam: Cam; meera?: Partial<Pose>; vik?: Partial<Pose>; phone?: "desk" | "hand" | "none"; phoneLit?: boolean; paper?: boolean; meeraStand?: boolean; enter?: number }> = ({ t, cam, meera, vik, phone = "none", phoneLit, paper, meeraStand, enter }) => {
  const mPlace: Place = enter !== undefined ? { x: 200 + enter * 360, y: OFFICE.floorY, s: 0.95 } : { x: 600, y: OFFICE.floorY, s: 0.95 };
  const vPlace: Place = { x: 1230, y: OFFICE.floorY, s: 0.95, flip: true };
  const mBase: Pose = enter !== undefined && enter < 1 ? walkPose(t, "offEnter", enter * 2.2) : alive(t, "offM", { stance: meeraStand ? "stand" : "sit", lean: meeraStand ? 0 : 8, headTilt: 4, gazeX: 0.8, gazeY: 0.1, expr: "resolve", ...meera });
  const mPose: Pose =
    phone === "hand"
      ? { ...mBase, near: reachW(M, mBase, "near", { x: mPlace.x + 160, y: mPlace.y - 380 }, mPlace, "hold", 90) }
      : phone === "desk"
        ? { ...mBase, near: reachW(M, mBase, "near", { x: 840, y: OFFICE.deskTop - 6 }, mPlace, "relaxed", 70) }
        : mBase;
  const vBase: Pose = alive(t, "offV", { stance: "sit", lean: 6, headTilt: 2, gazeX: 0.8, gazeY: 0.1, expr: "stern", near: { sh: 50, el: 60 }, far: { sh: 40, el: 70 }, ...vik });
  return (
    <Shot cam={cam} grade="day">
      <Layer>
        <VikramOffice />
        <At x={vPlace.x + 40} y={vPlace.y} s={1}>
          <g transform="scale(-1 1)">
            <Chair color="#1e1a18" />
          </g>
        </At>
        <Actor spec={vikram} place={vPlace} pose={vBase} />
        <rect x={OFFICE.deskL} y={OFFICE.deskTop} width={OFFICE.deskR - OFFICE.deskL} height={300} fill="#2e221b" stroke={C.ink} strokeWidth={2} />
        <rect x={OFFICE.deskL - 10} y={OFFICE.deskTop - 4} width={OFFICE.deskR - OFFICE.deskL + 20} height={26} fill="#3a2a22" stroke={C.ink} strokeWidth={2} />
        {paper ? (
          <At x={1000} y={OFFICE.deskTop - 4} s={1}>
            <g transform="scale(1 0.35)">
              <Paper w={200} h={260} scribbleLines={4} size={24} color="#f3f1ea" />
            </g>
          </At>
        ) : null}
        {phone === "desk" ? (
          <At x={860} y={OFFICE.deskTop - 6} s={1}>
            <g transform="scale(1 0.35) rotate(90)">
              <Phone w={40} lit={!!phoneLit} sender="" />
            </g>
          </At>
        ) : null}
        {!meeraStand && enter === undefined ? (
          <At x={mPlace.x - 40} y={mPlace.y} s={0.95}>
            <Chair color="#1e1a18" />
          </At>
        ) : null}
        <Actor spec={M} place={mPlace} pose={mPose} nearHold={phone === "hand" ? <g transform="translate(0 20) rotate(180)"><Phone w={36} lit={!!phoneLit} sender="" /></g> : null} />
      </Layer>
    </Shot>
  );
};

const OC = {
  wide: { x: 960, y: 560, z: 1.0 } as Cam,
  two: { x: 920, y: 560, z: 1.3 } as Cam,
  meera: { x: 680, y: 520, z: 2.5 } as Cam,
  vikram: { x: 1180, y: 480, z: 2.5 } as Cam,
};

// S17-01 — morning, Vikram's office
export const S17_01: React.FC = () => {
  const { f, t, lt, dur } = useBeat();
  return <OfficeScene f={f} t={t} cam={camAt(lt, [[0, OC.wide], [dur, OC.two]])} enter={Math.min(1, lt / Math.max(1, dur))} />;
};

// S17-02 — the market model; a glass door where the gate stood
export const S17_02: React.FC = () => {
  const { lt, dur } = useBeat();
  return (
    <Shot cam={camAt(lt, [[0, { x: OFFICE.model.x, y: OFFICE.model.y - 70, z: 3.4 }], [dur, { x: OFFICE.model.x + 82, y: OFFICE.model.y - 84, z: 6.5 }]])} grade="day">
      <Layer>
        <VikramOffice />
      </Layer>
    </Shot>
  );
};

// S17-03 — she plays the order without preamble; his finger stops on the desk
export const S17_03: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const finger = T(at(219));
  const shot = cutIndex(lt, [finger - 0.1]);
  if (shot === 0) return <OfficeScene f={f} t={t} cam={OC.two} phone="desk" phoneLit={lt > 1} meera={{ expr: "resolve" }} vik={{ expr: "smug" }} />;
  const tap = lt - finger < 0.8 ? Math.abs(Math.sin((lt - finger) * 14)) * 10 : 0;
  return (
    <Shot cam={camAt(lt - finger, [[0, { x: 960, y: 560, z: 1 }], [dur - finger, { x: 960, y: 560, z: 1.06 }]])} grade="day" bg="#2e221b">
      <Layer>
        <rect x={-300} y={-300} width={2520} height={1600} fill="#3a2a22" />
        <At x={1000} y={720 - tap} s={1.3} rot={-150}>
          <BigHand skin={vikram.skin} shade={vikram.skinShade} sleeve="#ece7dc" sleeveShade="#c9c1b2" pose={{ curl: [0.4, 0.05, 0.7, 0.75, 0.75] }} />
          <rect x={10} y={-80} width={18} height={14} rx={4} fill="#c99a3c" />
        </At>
      </Layer>
    </Shot>
  );
};

// S17-04 — «इतने पुराने टेप से क्या साबित होगा?» — her bluff; her heartbeat in her throat
export const S17_04: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const m = T(at(223));
  const lie = T(at(225));
  const shot = cutIndex(lt, [m - 0.1, lie - 0.1]);
  const pulse = shot === 2 ? Math.max(0, Math.sin(lt * 7.5)) ** 8 * 0.04 : 0;
  const cam = shot === 0 ? OC.vikram : shot === 1 ? OC.meera : { ...OC.meera, z: 3.2 + pulse };
  return <OfficeScene f={f} t={t} cam={cam} phone="desk" vik={{ talk: speaks(t, 221, "इतने पुराने", "होगा?”"), expr: "stern" }} meera={{ talk: speaks(t, 223), expr: shot === 2 ? "fear" : "resolve" }} />;
};

// S17-05 — he leans back: an honourable version of her father's name; the house
export const S17_05: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const how = T(at(229));
  const v2 = T(at(231));
  const shot = cutIndex(lt, [how - 0.1, v2 - 0.1]);
  return <OfficeScene f={f} t={t} cam={shot === 1 ? OC.meera : OC.vikram} paper vik={{ lean: -8, talk: speaks(t, 227, "तुम्हारे पिता") + speaks(t, 231), expr: "smug" }} meera={{ talk: speaks(t, 229), expr: "tense" }} />;
};

// S17-06 — the purchase paper; the amount
export const S17_06: React.FC = () => {
  const { f, t, lt, dur } = useBeat();
  const shot = cutIndex(lt, [dur * 0.55]);
  if (shot === 1) return <OfficeScene f={f} t={t} cam={{ ...OC.meera, z: 3 }} paper meera={{ expr: "tired", gazeY: 0.9, headTilt: 16 }} />;
  return (
    <PageInsert cam={camAt(lt, [[0, { x: 960, y: 540, z: 1 }], [dur, { x: 1100, y: 600, z: 1.5 }]])}>
      <At x={960} y={540} s={1} rot={-3}>
        <Paper w={900} h={760} scribbleLines={7} size={52} color="#f3f1ea" seed={17} />
        <text x={100} y={240} fontSize={70} fill="#1a1a1a" fontWeight={700}>
          ₹
        </text>
        <Scribble x={160} y={222} w={260} h={20} seed={77} color="#1a1a1a" width={3} />
      </At>
    </PageInsert>
  );
};

// S17-07 — «और सायरन?» «ग़लतफ़हमी थी।» «फाटक?» «तुम तब बच्ची थीं...»
export const S17_07: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const cuts = [T(at(237)) - 0.1, T(at(239)) - 0.1, T(at(241)) - 0.1];
  const shot = cutIndex(lt, cuts);
  return <OfficeScene f={f} t={t} cam={shot % 2 === 0 ? OC.meera : OC.vikram} paper vik={{ talk: speaks(t, 237) + speaks(t, 241), expr: "smug" }} meera={{ talk: speaks(t, 235) + speaks(t, 239), expr: "anger" }} />;
};

// S17-08 — she picks up her phone: «इसीलिए सुन रही हूँ।»
export const S17_08: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const say = T(at(245));
  const shot = cutIndex(lt, [say - 0.1]);
  return <OfficeScene f={f} t={t} cam={shot === 0 ? OC.two : OC.meera} paper phone="hand" phoneLit meeraStand={lt > say + 0.6} meera={{ talk: speaks(t, 245), expr: "resolve", gazeX: 0.9 }} vik={{ expr: "stern" }} />;
};

// S18-01 — outside: she calls Kabir
export const S18_01: React.FC = () => {
  const { f, t, lt, dur } = useBeat();
  const place: Place = { x: 900, y: 1000, s: 0.95 };
  const base: Pose = alive(t, "call", { stance: "stand", headTilt: 6, gazeX: 0.4, gazeY: 0.4, expr: "tense", talk: speaks(t, 249) });
  return (
    <Shot cam={camAt(lt, [[0, { x: 940, y: 560, z: 1.6 }], [dur, { x: 930, y: 520, z: 2.2 }]])} grade="day">
      <Layer>
        <Roadside frame={f} />
        <Actor spec={M} place={place} pose={{ ...base, near: { sh: 150, el: 140, hand: "hold" } }} />
      </Layer>
    </Shot>
  );
};

// S18-02 — a father ties his daughter's shoelace; she takes out the letter
export const S18_02: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const letter = T(at(251, "मीरा ने बैग"));
  const shot = cutIndex(lt, [letter - 0.1]);
  if (shot === 1) {
    return (
      <PageInsert cam={camAt(lt - letter, [[0, { x: 960, y: 540, z: 1 }], [dur - letter, { x: 960, y: 540, z: 1.12 }]])}>
        <rect x={-300} y={-300} width={2520} height={1600} fill="#8a8172" />
        <At x={960} y={520} s={1} rot={4}>
          <Paper w={800} h={640} lines={LETTER_201.slice(0, 4)} size={48} color="#f1ead6" lined />
        </At>
        <At x={560} y={860} s={1.1} rot={-25}>
          <BigHand skin={M.skin} shade={M.skinShade} sleeve={M.top.color} sleeveShade={M.top.shade} watch pose={{ curl: [0.3, 0.35, 0.4, 0.45, 0.5] }} />
        </At>
      </PageInsert>
    );
  }
  const tug = Math.sin(lt * 6) * 10;
  const fPlace: Place = { x: 1260, y: 1010, s: 0.95, flip: true };
  return (
    <Shot cam={camAt(lt, [[0, { x: 1040, y: 640, z: 1.35 }], [letter, { x: 1100, y: 680, z: 1.6 }]])} grade="day">
      <Layer>
        <Roadside frame={f} />
        <Actor spec={roadFather} place={fPlace} pose={alive(t, "rf", { stance: "crouch", headTilt: 28, gazeY: 1, expr: "soft", near: { sh: 60, el: 40, hand: "pinch" }, far: { sh: 50, el: 50, hand: "pinch" } })} />
        <Actor spec={roadGirl} place={{ x: 1120, y: 1010, s: 0.95 }} pose={alive(t, "rg", { stance: "stand", headTilt: -4, gazeX: 0.6, gazeY: 0.3, expr: "laugh", near: reachW(roadGirl, { stance: "stand" }, "near", { x: 1210 + tug, y: 760 }, { x: 1120, y: 1010, s: 0.95 }, "open", 0), far: { sh: 10, el: 20 } })} />
        <Actor spec={M} place={{ x: 640, y: 1000, s: 0.95 }} pose={alive(t, "rm", { stance: "stand", headTilt: 4, gazeX: 0.9, expr: "sad", near: { sh: 20, el: 40, hand: "hold" }, far: { sh: -6, el: 16 } })} />
      </Layer>
    </Shot>
  );
};

// S18-03 — «आपको पहले बताना चाहिए था।» ... the footsteps coming home
export const S18_03: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const steps = T(at(255, "मगर वह उनके घर"));
  const shot = cutIndex(lt, [steps - 0.1]);
  if (shot === 0) {
    return (
      <Shot cam={camAt(lt, [[0, { x: 690, y: 520, z: 2.6 }], [steps, { x: 690, y: 510, z: 3.0 }]])} grade="day">
        <Layer>
          <Roadside frame={f} />
          <Actor spec={M} place={{ x: 640, y: 1000, s: 0.95 }} pose={alive(t, "rm2", { stance: "stand", headTilt: 10, gazeX: 0.5, gazeY: 0.6, expr: { browInner: 0.6, browY: 0, lid: 0.3, lower: 0.2, mouth: -0.35, open: 0, press: 0.4 }, near: { sh: 30, el: 70, hand: "hold" }, far: { sh: 20, el: 60, hand: "hold" } })} />
        </Layer>
      </Shot>
    );
  }
  // the remembered footsteps, now walking toward home: low shot on his feet in the water
  const w = lt - steps;
  return (
    <Shot cam={camAt(w, [[0, { x: 960, y: 860, z: 2.2 }], [dur - steps, { x: 960, y: 860, z: 2.4 }]])} grade="memoryWarm" memoryEdge={0.7}>
      <Layer>
        <FloodLane frame={f} water={0.12} rain={0.6} light={1.2} />
        <Actor spec={dineshYoung} place={{ x: 1500 - w * 90, y: 1010, s: 1.0, flip: true }} pose={walkPose(t, "home", w * 0.6, { near: { sh: 70, el: 60, hand: "grip" }, far: { sh: 80, el: 70, hand: "grip" } })} />
        <Water frame={f} y={990} dye={0.3} seed="homeW" opacity={0.6} />
      </Layer>
    </Shot>
  );
};

/** School gate by day with Harish seated by the open chain. */
const GateDay: React.FC<{ f: number; t: number; cam: Cam; meeraSit?: number; meera?: Partial<Pose>; harishP?: Partial<Pose>; meeraIn?: boolean }> = ({ f, t, cam, meeraSit = 0, meera, harishP, meeraIn = true }) => {
  const hPlace: Place = { x: 1180, y: 1060, s: 0.95, flip: true };
  return (
    <Shot cam={cam} grade="day">
      <Layer>
        <SchoolGate frame={f} time="day" chain="open" />
        <rect x={1050} y={1000} width={340} height={60} fill="#8d8780" stroke={C.ink} strokeWidth={2} />
        <Actor spec={harish} place={hPlace} pose={alive(t, "hDay", { stance: "sit", lean: 14, headTilt: 14, gazeX: 0.6, gazeY: 0.6, expr: "tired", near: { sh: 50, el: 70, hand: "hold" }, far: { sh: 30, el: 70 }, ...harishP })} nearHold={<g transform="translate(0 26)"><Keys s={0.8} swing={Math.sin(t * 1.4) * 3} /></g>} />
        {meeraIn ? (
          <Actor
            spec={M}
            place={meeraSit > 0.5 ? { x: 960, y: 1060, s: 0.95 } : { x: 780, y: 1070, s: 0.95 }}
            pose={alive(t, "mDay", { stance: meeraSit > 0.5 ? "sit" : "stand", lean: meeraSit > 0.5 ? 12 : 0, headTilt: 6, gazeX: 0.8, gazeY: 0.3, expr: "soft", near: meeraSit > 0.5 ? { sh: 40, el: 70 } : { sh: 6, el: 16 }, far: meeraSit > 0.5 ? { sh: 30, el: 70 } : { sh: -6, el: 14 }, ...meera })}
          />
        ) : null}
      </Layer>
    </Shot>
  );
};

// S19-01 — Harish at the gate, the chain undone
export const S19_01: React.FC = () => {
  const { f, t, lt, dur } = useBeat();
  return <GateDay f={f} t={t} meeraIn={lt > dur * 0.5} cam={camAt(lt, [[0, { x: GATE.x, y: 620, z: 1.0 }], [dur, { x: GATE.x + 60, y: 680, z: 1.3 }]])} />;
};

// S19-02 — «आज चाबी साथ लाए?» «उस रात के बाद से जेब में रहती है।»
export const S19_02: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const h = T(at(261));
  const shot = cutIndex(lt, [h - 0.1]);
  return <GateDay f={f} t={t} cam={shot === 0 ? { x: 840, y: 560, z: 2.4 } : { x: 1150, y: 640, z: 2.6 }} meera={{ talk: speaks(t, 259, "आज चाबी", "लाए?”") }} harishP={{ talk: speaks(t, 261, "उस रात", "है।”"), expr: { browInner: 0.9, browY: 0.1, lid: 0.35, lower: 0.25, mouth: -0.4, open: 0, tears: 1 } }} />;
};

// S19-03 — she sits beside him; «माइक पर बोल पाएँगे?» — he looks at the verandah, nods
export const S19_03: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const ask = T(at(263, "थोड़ी देर बाद"));
  const nod = T(at(265, "फिर सिर"));
  const shot = cutIndex(lt, [ask - 0.1, T(at(265)) - 0.1]);
  return (
    <GateDay
      f={f}
      t={t}
      meeraSit={1}
      cam={shot === 0 ? { x: 1060, y: 680, z: 1.6 } : shot === 1 ? { x: 960, y: 640, z: 2.4 } : { x: 1150, y: 640, z: 2.6 }}
      meera={{ talk: speaks(t, 263, "माइक पर", "पाएँगे?”") }}
      harishP={{ headTilt: 4 + nodAt(lt, nod), gazeX: -0.8, gazeY: -0.2, headTurn: -0.5, expr: "resolve" }}
    />
  );
};

/** Memorial courtyard staging: crowd rows facing the stage (backs to camera). */
const CROWD_SPECS: CharSpec[] = [...Array(18)].map((_, i) => townsperson(`mem${i}`));
const Crowd: React.FC<{ t: number; front?: boolean; stir?: number; still?: boolean; turnHeads?: number }> = ({ t, front = false, stir = 0, turnHeads = 0 }) => (
  <g>
    {CROWD_SPECS.map((spec, i) => {
      const row = Math.floor(i / 6);
      const x = 220 + (i % 6) * 280 + (row % 2) * 120;
      const y = 1080 + row * 90;
      const s = 0.85 + row * 0.1;
      const flip = front ? i % 2 === 0 : false;
      const sway = stir * Math.sin(t * 2 + i) * 6;
      return (
        <g key={i}>
          <At x={x - 30} y={y} s={s * 0.95}>
            <PlasticChair />
          </At>
          <Actor spec={spec} place={{ x, y, s, flip }} pose={alive(t, `crowd${i}`, { stance: "sit", view: front ? "front" : "back", lean: 6 + sway, headTilt: front ? 4 : -2, headTurn: turnHeads * (i % 2 ? 0.6 : -0.6), gazeX: 0.6, near: { sh: 40, el: 70 }, far: { sh: 30, el: 70 } })} />
        </g>
      );
    })}
  </g>
);

const MemorialScene: React.FC<{
  f: number;
  t: number;
  cam: Cam;
  onStage?: "vikram" | "meera" | "harish" | "none";
  speakerTalk?: number;
  speakerExpr?: Pose["expr"];
  vikStand?: number;
  harishWalk?: number;
  crowd?: { stir?: number; turnHeads?: number };
  kabirBox?: boolean;
  meeraFront?: boolean;
  handsShake?: number;
}> = ({ f, t, cam, onStage = "none", speakerTalk = 0, speakerExpr = "neutral", vikStand = 0, harishWalk, crowd, kabirBox = true, meeraFront = true, handsShake = 0 }) => {
  const S = MEMORIAL;
  const stagePt: Place = { x: S.micX - 46, y: S.stageY - 124, s: 0.6 };
  const micTop = S.stageY - 124 - 0.6 * 1.25 * 370;
  const speaker = onStage === "vikram" ? vikram : onStage === "meera" ? meeraMemorial : onStage === "harish" ? harish : null;
  const sBase: Pose = alive(t, `stage${onStage}`, { stance: "stand", headTilt: 2, gazeX: 0.6, expr: speakerExpr, talk: speakerTalk });
  const sPose: Pose = speaker ? { ...sBase, near: reachW(speaker, sBase, "near", { x: S.micX + 8 + Math.sin(t * 30) * handsShake * 2, y: micTop + 30 }, stagePt, "grip", 30), far: onStage === "harish" ? { sh: 30, el: 60, hand: "hold" } : { sh: 6, el: 16 } } : sBase;
  const hw = harishWalk ?? -1;
  return (
    <Shot cam={cam} grade="day">
      <Layer>
        <MemorialYard frame={f} posters={false} />
        <At x={S.micX} y={S.stageY - 124} s={0.6}>
          <Microphone s={1.25} stand={330} />
        </At>
        {speaker ? <Actor spec={speaker} place={stagePt} pose={sPose} nearHold={null} farHold={onStage === "harish" ? <g transform="translate(0 26)"><Keys s={0.8} /></g> : null} /> : null}
        {kabirBox ? <Actor spec={kabirStreet} place={{ x: S.boxX + 90, y: S.stageY - 124, s: 0.58, flip: true }} pose={alive(t, "kBox", { stance: "stand", lean: 16, headTilt: 14, gazeY: 0.7, near: { sh: 60, el: 40, hand: "grip" }, far: { sh: 10, el: 20 } })} /> : null}
        {/* front row: Vikram (left), Harish (right), Meera (centre) */}
        <At x={560 - 30} y={960} s={0.95}>
          <PlasticChair />
        </At>
        <Actor spec={vikram} place={{ x: 560, y: 960, s: 0.95 }} pose={alive(t, "vFront", { stance: vikStand > 0.5 ? "stand" : "sit", view: "back", lean: 4, near: vikStand > 0.5 ? { sh: 90, el: 10, hand: "point" } : { sh: 40, el: 70 }, far: { sh: 30, el: 70 } })} />
        {hw < 0 ? (
          <>
            <At x={1400 - 30} y={960} s={0.95}>
              <PlasticChair />
            </At>
            <Actor spec={harish} place={{ x: 1400, y: 960, s: 0.95 }} pose={alive(t, "hFront", { stance: "sit", view: "back", lean: 10, near: { sh: 40, el: 70 }, far: { sh: 30, el: 70 } })} />
          </>
        ) : hw < 1 ? (
          <Actor spec={harish} place={{ x: 1400 - hw * 400, y: 960 - hw * 324, s: 0.95 - hw * 0.35, flip: true }} pose={walkPose(t, "hWalk", hw * 2.2, { headTilt: 16, near: { sh: 30, el: 60, hand: "hold" } })} nearHold={<g transform="translate(0 26)"><Keys s={0.8} /></g>} />
        ) : null}
        {meeraFront && onStage !== "meera" ? (
          <>
            <At x={960 - 30} y={960} s={0.95}>
              <PlasticChair />
            </At>
            <Actor spec={meeraMemorial} place={{ x: 960, y: 960, s: 0.95 }} pose={alive(t, "mFront", { stance: "sit", view: "back", lean: 6, near: { sh: 40, el: 70 }, far: { sh: 30, el: 70 } })} />
          </>
        ) : null}
        <Crowd t={t} stir={crowd?.stir} turnHeads={crowd?.turnHeads} />
      </Layer>
    </Shot>
  );
};

/** Reverse angle from the stage: the crowd facing camera. */
const CrowdReverse: React.FC<{ f: number; t: number; cam: Cam; stir?: number; turnHeads?: number; standing?: CharSpec; standingTalk?: number; holdBack?: number }> = ({ t, cam, stir = 0, turnHeads = 0, standing, standingTalk = 0, holdBack }) => (
  <Shot cam={cam} grade="day">
    <Layer>
      <rect x={-400} y={-300} width={2720} height={1500} fill="#8d8780" />
      <rect x={-400} y={160} width={2720} height={80} fill="#c46a2a" />
      <rect x={-400} y={700} width={2720} height={700} fill="#a39a88" />
      {CROWD_SPECS.slice(0, 12).map((spec, i) => {
        const row = Math.floor(i / 6);
        const x = 160 + (i % 6) * 320 + (row % 2) * 140;
        const y = 900 + row * 140;
        const s = 0.9 + row * 0.12;
        const sway = stir * Math.sin(t * 2.2 + i) * 8;
        return (
          <g key={i}>
            <At x={x + (i % 2 ? 30 : -30)} y={y} s={s * 0.95}>
              <g transform={i % 2 ? "scale(-1 1)" : undefined}>
                <PlasticChair />
              </g>
            </At>
            <Actor spec={spec} place={{ x, y, s, flip: i % 2 === 1 }} pose={alive(t, `rev${i}`, { stance: "sit", lean: 4 + sway, headTilt: 2, headTurn: turnHeads * (i % 2 ? 0.7 : -0.7), gazeX: 0.2, gazeY: -0.2, expr: stir > 0.5 ? "tense" : "listen", near: { sh: 40, el: 70 }, far: { sh: 30, el: 70 } })} />
          </g>
        );
      })}
      {standing ? <Actor spec={standing} place={{ x: 960, y: 980, s: 1.05 }} pose={alive(t, "standing", { stance: "stand", headTilt: -4, gazeX: 0.3, gazeY: -0.3, expr: "grief", talk: standingTalk, near: { sh: 40, el: 70, hand: "open" }, far: { sh: 10, el: 30 } })} /> : null}
      {holdBack !== undefined ? (
        <g>
          <Actor spec={townsperson("wireMan")} place={{ x: 1260 + holdBack * 60, y: 960, s: 1.0, flip: true }} pose={alive(t, "wm", { stance: "walk", walk: holdBack, lean: 14, expr: "anger", near: { sh: 60, el: 20, hand: "open" } })} />
          <Actor spec={townsperson("holder1")} place={{ x: 1120, y: 960, s: 1.0 }} pose={alive(t, "h1", { stance: "stand", lean: 10, expr: "resolve", near: { sh: 80, el: 10, hand: "open" }, far: { sh: 70, el: 10, hand: "open" } })} />
          <Actor spec={townsperson("holder2")} place={{ x: 1420, y: 960, s: 1.0, flip: true }} pose={alive(t, "h2", { stance: "stand", lean: 10, expr: "resolve", near: { sh: 80, el: 10, hand: "open" }, far: { sh: 70, el: 10, hand: "open" } })} />
        </g>
      ) : null}
    </Layer>
  </Shot>
);

const MC = {
  wide: { x: 960, y: 620, z: 1.0 } as Cam,
  stage: { x: 960, y: 470, z: 2.0 } as Cam,
  speaker: { x: 930, y: 380, z: 3.0 } as Cam,
  stone: { x: MEMORIAL.stone.x, y: MEMORIAL.stone.y - 60, z: 3.6 } as Cam,
  box: { x: MEMORIAL.boxX, y: MEMORIAL.stageY - 150, z: 4.4 } as Cam,
  speakers: { x: 140, y: 360, z: 3.4 } as Cam,
  rev: { x: 960, y: 640, z: 1.2 } as Cam,
};

// S20-01 — the courtyard fills; seventeen names, Anshu's last; the whistle in her pocket
export const S20_01: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const stone = T(at(267, "पत्थर पर"));
  const whistle = T(at(267, "उसे पढ़ते"));
  const shot = cutIndex(lt, [stone - 0.1, whistle - 0.1]);
  if (shot === 0) return <MemorialScene f={f} t={t} cam={camAt(lt, [[0, MC.wide], [stone, { ...MC.wide, z: 1.08 }]])} />;
  if (shot === 1) {
    return (
      <Shot cam={camAt(lt - stone, [[0, MC.stone], [whistle - stone, { x: MEMORIAL.stone.x, y: MEMORIAL.stone.y - 26, z: 6 }]])} grade="day">
        <Layer>
          <MemorialYard frame={f} />
          <At x={MEMORIAL.stone.x} y={MEMORIAL.stone.y} s={1}>
            <MemorialStone s={1} highlight={ramp(lt, stone + 1, stone + 2)} />
          </At>
        </Layer>
      </Shot>
    );
  }
  const squeeze = ramp(lt, whistle + 0.4, whistle + 1.2);
  return (
    <Shot cam={camAt(lt - whistle, [[0, { x: 960, y: 540, z: 1 }], [dur - whistle, { x: 960, y: 540, z: 1.1 }]])} grade="day" bg="#c9c2b0">
      <Layer>
        <rect x={-300} y={-300} width={2520} height={1600} fill="#d9d2c2" />
        <path d="M 600 300 Q 960 260 1320 300 L 1380 1100 L 540 1100 Z" fill="#c9c1ae" stroke={C.ink} strokeWidth={3} />
        <At x={1000} y={640} s={4}>
          <Whistle s={1} />
        </At>
        <At x={980} y={780 + (1 - squeeze) * 40} s={1.4} rot={170}>
          <BigHand skin={M.skin} shade={M.skinShade} sleeve="#d9d2c2" sleeveShade="#b3aa97" watch pose={{ curl: [0.4 + squeeze * 0.4, 0.4 + squeeze * 0.5, 0.45 + squeeze * 0.5, 0.5 + squeeze * 0.45, 0.55 + squeeze * 0.4] }} />
        </At>
      </Layer>
    </Shot>
  );
};

// S20-02 — Vikram's speech, from the back of the crowd
export const S20_02: React.FC = () => {
  const { f, t, lt, dur } = useBeat();
  return <MemorialScene f={f} t={t} onStage="vikram" speakerExpr="smug" speakerTalk={0.3 + 0.3 * Math.abs(Math.sin(t * 4))} cam={camAt(lt, [[0, MC.wide], [dur, { ...MC.wide, z: 1.15, y: 600 }]])} />;
};

// S20-03 — her name is called; Kabir connects the laptop to the mic box
export const S20_03: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const cable = T(at(271, "कबीर ने लैपटॉप"));
  const shot = cutIndex(lt, [cable - 0.2]);
  if (shot === 0) return <MemorialScene f={f} t={t} cam={camAt(lt, [[0, MC.rev], [cable, { ...MC.rev, z: 1.25 }]])} />;
  const plug = ramp(lt, cable + 0.3, cable + 1.2);
  return (
    <Shot cam={camAt(lt - cable, [[0, MC.box], [dur - cable, { ...MC.box, z: 4.8 }]])} grade="day">
      <Layer>
        <MemorialYard frame={f} />
        <At x={MEMORIAL.boxX - 120} y={MEMORIAL.stageY - 124} s={1}>
          <Laptop w={110} screen={<Waveform w={90} h={50} env={envSlice(para(279).start, para(279).end + 20, 40)} />} />
        </At>
        <path d={`M ${MEMORIAL.boxX - 70} ${MEMORIAL.stageY - 130} C ${MEMORIAL.boxX - 50} ${MEMORIAL.stageY - 110} ${MEMORIAL.boxX - 50} ${MEMORIAL.stageY - 150} ${MEMORIAL.boxX - 60 + plug * 30} ${MEMORIAL.stageY - 154}`} stroke="#1a1a1a" strokeWidth={4} fill="none" />
        <At x={MEMORIAL.boxX - 40 + plug * 10} y={MEMORIAL.stageY - 190} s={0.3} rot={160}>
          <BigHand skin={kabir.skin} shade={kabir.skinShade} sleeve={kabir.top.color} sleeveShade={kabir.top.shade} pose={{ curl: [0.6, 0.6, 0.7, 0.75, 0.8] }} />
        </At>
      </Layer>
    </Shot>
  );
};

// S20-04 — on stage she looks at Vikram until her hands stop shaking
export const S20_04: React.FC = () => {
  const { f, t, lt, dur } = useBeat();
  const shake = 1 - ramp(lt, dur * 0.3, dur * 0.9);
  const shot = cutIndex(lt, [dur * 0.45]);
  return <MemorialScene f={f} t={t} onStage="meera" speakerExpr="resolve" handsShake={shake} cam={shot === 0 ? MC.speaker : { x: 940, y: 470, z: 4.2 }} />;
};

// S20-05 — «मैं दिनेश सक्सेना की बेटी हूँ...»
export const S20_05: React.FC = () => {
  const { f, t, lt, dur } = useBeat();
  return <MemorialScene f={f} t={t} onStage="meera" speakerExpr="resolve" speakerTalk={speaks(t, 275, "मैं दिनेश", "हूँ,”") + speaks(t, 275, "आज मैं", "हूँ।”")} cam={camAt(lt, [[0, MC.stage], [dur, MC.speaker]])} />;
};

// S20-06 — his voice spreads through the courtyard; people shift
export const S20_06: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const conf = T(at(279));
  const stir = T(at(281));
  const shot = cutIndex(lt, [conf - 0.1, stir - 0.1]);
  if (shot === 0) return <MemorialScene f={f} t={t} onStage="meera" speakerExpr="resolve" cam={MC.speakers} />;
  return <CrowdReverse f={f} t={t} cam={shot === 1 ? MC.rev : { ...MC.rev, z: 1.4 }} stir={shot === 2 ? 1 : 0} turnHeads={shot === 2 ? ramp(lt, stir, stir + 0.8) : 0} />;
};

// S20-07 — she could have cut the first sentence; today she cut nothing
export const S20_07: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const nothing = T(at(285));
  const shot = cutIndex(lt, [nothing - 0.1]);
  if (shot === 1) return <MemorialScene f={f} t={t} onStage="meera" speakerExpr="resolve" cam={camAt(lt - nothing, [[0, MC.speaker], [dur - nothing, { ...MC.speaker, z: 3.4 }]])} />;
  const hover = kf(lt, [[0.5, 0], [2.5, 1], [nothing - 1.2, 1], [nothing - 0.3, 0]]);
  return (
    <Shot cam={{ x: 960, y: 540, z: 1 }} grade="day" bg="#0d1424">
      <Layer>
        <rect x={-300} y={-300} width={2520} height={1600} fill="#0d1424" />
        <g transform="translate(160 300)">
          <Waveform w={1600} h={420} env={envSlice(para(279).start - 0.5, para(279).start + 30, 220)} mark={[0.02, 0.12]} playhead={0.01} />
        </g>
        <g transform={`translate(${340 + hover * 60} ${280 - hover * 40})`} opacity={hover}>
          <circle cx={0} cy={0} r={22} fill="none" stroke="#f3eee4" strokeWidth={4} />
          <circle cx={0} cy={50} r={22} fill="none" stroke="#f3eee4" strokeWidth={4} />
          <path d="M 14 14 L 70 -30 M 14 36 L 70 80" stroke="#f3eee4" strokeWidth={4} />
        </g>
      </Layer>
    </Shot>
  );
};

// S20-08 — warning, order, click. Vikram stands: «इसे रोको...»
export const S20_08: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const up = T(at(289));
  const shot = cutIndex(lt, [up - 0.2]);
  if (shot === 0) return <CrowdReverse f={f} t={t} cam={{ ...MC.rev, z: 1.3 }} />;
  const rise = ramp(lt, up - 0.2, up + 0.4);
  return (
    <Shot cam={{ x: 560, y: 600, z: 2.4 }} grade="day">
      <Layer>
        <rect x={-400} y={-300} width={2720} height={1500} fill="#8d8780" />
        <rect x={-400} y={700} width={2720} height={700} fill="#a39a88" />
        <At x={560 + 30} y={1000} s={0.95}>
          <g transform="scale(-1 1)">
            <PlasticChair />
          </g>
        </At>
        <Actor spec={vikram} place={{ x: 560, y: 1000, s: 0.95, flip: true }} pose={alive(t, "vStand", { stance: rise > 0.5 ? "stand" : "sit", lean: 6, headTilt: -2, gazeX: 0.8, gazeY: -0.3, expr: "anger", talk: speaks(t, 289, "इसे रोको", "है।”"), near: rise > 0.5 ? { sh: 95, el: 10, hand: "point" } : { sh: 40, el: 70 }, far: { sh: 20, el: 30, hand: "fist" } })} />
      </Layer>
    </Shot>
  );
};

// S20-09 — «असली कैसेट सुरक्षित है...» Two men stop a man heading for the wires.
export const S20_09: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const hold = T(at(293));
  const shot = cutIndex(lt, [hold - 0.1]);
  if (shot === 0) return <MemorialScene f={f} t={t} onStage="meera" speakerExpr="resolve" speakerTalk={speaks(t, 291, "असली कैसेट", "दीजिए।”")} cam={MC.speaker} />;
  return <CrowdReverse f={f} t={t} cam={{ ...MC.rev, x: 1260, z: 1.6 }} stir={1} holdBack={Math.min(1, (lt - hold) * 0.5)} />;
};

// S20-10 — the mother's voice; stillness; Harish rises with his keys, stops twice
export const S20_10: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const rises = T(at(299, "हरीश अपनी"));
  const shot = cutIndex(lt, [T(at(299)) - 0.1, rises - 0.1]);
  if (shot === 0) return <MemorialScene f={f} t={t} onStage="meera" speakerExpr="grief" cam={MC.speakers} />;
  if (shot === 1) return <CrowdReverse f={f} t={t} cam={{ ...MC.rev, z: 1.25 }} />;
  const w = lt - rises;
  const total = Math.max(2, dur - rises - 0.5);
  // two pauses on the way
  const raw = Math.min(1, w / total);
  const hw = raw < 0.33 ? raw : raw < 0.45 ? 0.33 : raw < 0.75 ? 0.33 + (raw - 0.45) : raw < 0.85 ? 0.63 : 0.63 + (raw - 0.85) * 2.4;
  return <MemorialScene f={f} t={t} onStage="meera" speakerExpr="grief" harishWalk={Math.min(0.99, hw)} cam={camAt(w, [[0, { x: 1300, y: 640, z: 1.4 }], [total, { x: 1100, y: 600, z: 1.5 }]])} />;
};

// S20-11 — «मैं वहाँ चौकीदार था...»
export const S20_11: React.FC = () => {
  const { f, t, lt, dur } = useBeat();
  return <MemorialScene f={f} t={t} onStage="harish" speakerExpr="grief" meeraFront={false} harishWalk={2} speakerTalk={speaks(t, 301, "मैं वहाँ", "था,”") + speaks(t, 301, "ताला मैंने", "सका।”")} cam={camAt(lt, [[0, MC.stage], [dur, MC.speaker]])} />;
};

// S20-12 — a woman stands: her sister was at that gate; a man asks why it went unrecorded
export const S20_12: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const man = T(at(305));
  const shot = cutIndex(lt, [man - 0.1]);
  return shot === 0 ? (
    <CrowdReverse f={f} t={t} cam={{ x: 960, y: 640, z: 1.9 }} standing={sisterWoman} standingTalk={speaks(t, 303, "मेरी बहन", "थी।”")} />
  ) : (
    <CrowdReverse f={f} t={t} cam={{ x: 960, y: 640, z: 1.9 }} standing={questionMan} standingTalk={speaks(t, 305, "जाँच में", "नहीं?”")} stir={0.5} />
  );
};

// S20-13 — many voices; she lets the recording run: footsteps, the call, water, silence
export const S20_13: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const silence = T(at(307, "उसके बाद लंबे"));
  const shot = cutIndex(lt, [T(at(307, "मीरा ने रिकॉर्डिंग")) - 0.1, silence - 0.1]);
  if (shot === 0) return <CrowdReverse f={f} t={t} cam={{ ...MC.rev, z: 1.15 }} stir={1} turnHeads={Math.sin(lt * 1.5)} />;
  if (shot === 1) return <MemorialScene f={f} t={t} onStage="harish" speakerExpr="grief" meeraFront={false} harishWalk={2} cam={MC.wide} crowd={{ stir: 1 }} />;
  return <MemorialScene f={f} t={t} onStage="none" meeraFront kabirBox cam={camAt(lt - silence, [[0, MC.wide], [dur - silence, { x: 960, y: 640, z: 1.25 }]])} />;
};

// S21-01 — no arrest; questions in the papers; "fake"; threats; statements again and again
export const S21_01: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const papers = T(at(309, "अगले हफ़्ते"));
  const threats = T(at(309, "हरीश को"));
  const statements = T(at(309, "मीरा को बयान"));
  const shot = cutIndex(lt, [papers - 0.1, threats - 0.1, statements - 0.1]);
  if (shot === 0) {
    return (
      <Shot cam={camAt(lt, [[0, { x: 960, y: 600, z: 1.1 }], [papers, { x: 1000, y: 600, z: 1.2 }]])} grade="day">
        <Layer>
          <MemorialYard frame={f} posters={false} />
          <Actor spec={vikram} place={{ x: 900 + lt * 80, y: 1000, s: 0.95 }} pose={walkPose(t, "vLeave", lt * 0.45, { expr: "stern" })} />
        </Layer>
      </Shot>
    );
  }
  if (shot === 1) {
    return (
      <PageInsert cam={camAt(lt - papers, [[0, { x: 960, y: 540, z: 1 }], [threats - papers, { x: 960, y: 540, z: 1.12 }]])}>
        {[0, 1, 2].map((i) => (
          <At key={i} x={600 + i * 360} y={540 + (i % 2) * 40} s={1} rot={(i - 1) * 8}>
            <Newspaper s={1} seed={i * 20 + 3} />
          </At>
        ))}
      </PageInsert>
    );
  }
  if (shot === 2) {
    return (
      <Shot cam={{ x: 960, y: 560, z: 1.8 }} grade="present">
        <Layer>
          <SchoolGate frame={f} time="dusk" chain="none" />
          <Actor spec={harish} place={{ x: 960, y: 1060, s: 0.95 }} pose={alive(t, "threat", { stance: "stand", headTilt: 12, gazeY: 0.9, expr: "fear", near: { sh: 150, el: 140, hand: "hold" }, far: { sh: -4, el: 14 } })} nearHold={<g transform="translate(0 20) rotate(180)"><Phone w={34} lit sender="" /></g>} />
        </Layer>
      </Shot>
    );
  }
  return (
    <Shot cam={camAt(lt - statements, [[0, { x: 960, y: 560, z: 1.2 }], [dur - statements, { x: 960, y: 560, z: 1.3 }]])} grade="day">
      <Layer>
        <StatementDesk />
        <Actor spec={townsperson("official")} place={{ x: 1180, y: 1000, s: 0.95, flip: true }} pose={alive(t, "off", { stance: "sit", lean: 14, headTilt: 18, gazeY: 0.9, near: { sh: 60, el: 60, hand: "pinch" }, far: { sh: 40, el: 70 } })} />
        <Actor spec={M} place={{ x: 700, y: 1000, s: 0.95 }} pose={alive(t, "stmt", { stance: "sit", lean: 8, headTilt: 4, gazeX: 0.8, expr: "tired", talk: 0, near: { sh: 50, el: 60 }, far: { sh: 40, el: 60 } })} />
      </Layer>
    </Shot>
  );
};

// S21-02 — but the gate was not torn down
export const S21_02: React.FC = () => {
  const { f, lt, dur } = useBeat();
  return (
    <Shot cam={camAt(lt, [[0, { x: 1100, y: 620, z: 1.0 }], [dur, { x: GATE.x, y: 640, z: 1.15 }]])} grade="day">
      <Layer>
        <SchoolGate frame={f} time="day" chain="locked" machine />
      </Layer>
    </Shot>
  );
};

// S21-03 — old inquiry, new statements; families bring their papers to one table
export const S21_03: React.FC = () => {
  const { lt, dur } = useBeat();
  return (
    <Shot cam={camAt(lt, [[0, { x: 960, y: 540, z: 1.25 }], [dur, { x: 960, y: 560, z: 1.0 }]])} grade="day">
      <Layer>
        <FilesTable n={Math.floor(2 + (lt / Math.max(1, dur)) * 14)} />
      </Layer>
    </Shot>
  );
};

// S21-04 — she stops the sale; Delhi; the next month she comes back — not to throw things away
export const S21_04: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const back = T(at(315, "मगर अगले"));
  const shot = cutIndex(lt, [back - 0.1]);
  if (shot === 0) {
    return (
      <Shot cam={camAt(lt, [[0, { x: 960, y: 640, z: 1.2 }], [back, { x: 900, y: 640, z: 1.3 }]])} grade="day">
        <Layer>
          <HouseFront frame={f} time="day" wet={0} />
          <Actor spec={M} place={{ x: 800 - Math.max(0, lt - 1) * 90, y: HOUSE.groundY, s: 0.9, flip: true }} pose={lt > 1 ? walkPose(t, "leave", (lt - 1) * 0.45) : alive(t, "leave0", { stance: "stand", headTilt: -6, gazeX: -0.8, expr: "resolve" })} />
        </Layer>
      </Shot>
    );
  }
  const w = lt - back;
  return (
    <Shot cam={camAt(w, [[0, { x: 960, y: 640, z: 1.2 }], [dur - back, { x: 860, y: 640, z: 1.35 }]])} grade="ending">
      <Layer>
        <HouseFront frame={f} time="day" wet={0} />
        <Actor spec={M} place={{ x: 200 + Math.min(w, 4.5) * 110, y: HOUSE.groundY, s: 0.9 }} pose={w < 4.5 ? walkPose(t, "return", w * 0.45) : alive(t, "ret0", { stance: "stand", headTilt: -6, gazeX: 0.8, expr: "soft" })} />
      </Layer>
    </Shot>
  );
};

// S22-01 — she lifts the clock off the wall: dust; a pencilled date by the battery
export const S22_01: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const back = T(at(317, "पीछे धूल"));
  const shot = cutIndex(lt, [back - 0.1]);
  const c = STUDY.clock;
  if (shot === 0) {
    const lift = ramp(lt, 0.6, 2);
    const place: Place = { x: 1090, y: STUDY.floorY, s: 0.95 };
    const base: Pose = alive(t, "lift", { stance: "stand", headTilt: -16, gazeX: 0.6, gazeY: -0.8, expr: "soft" });
    const handPt = { x: c.x - 20, y: c.y + 50 + lift * 140 };
    return (
      <StudyScene
        f={f}
        t={t}
        grade="ending"
        meeraStand
        meeraPlace={place}
        hideClock={lift > 0.05}
        laptop={false}
        cam={camAt(lt, [[0, { x: 1140, y: 480, z: 1.8 }], [back, { x: 1140, y: 520, z: 1.9 }]])}
        meera={{ ...base, near: reachW(M, base, "near", handPt, place, "hold", 0), far: reachW(M, base, "far", { x: handPt.x + 120, y: handPt.y }, place, "hold", 0) }}
        hands="clock"
        extra={
          lift > 0.05 ? (
            <At x={c.x + 40} y={c.y + lift * 140} s={1}>
              <Clock r={c.r} frame={f} startFrame={CLOCK_START()} dusty />
            </At>
          ) : null
        }
      />
    );
  }
  return (
    <PageInsert cam={camAt(lt - back, [[0, { x: 960, y: 540, z: 1 }], [lt + 1, { x: 900, y: 640, z: 1.6 }]])}>
      <At x={960} y={540} s={3.6}>
        <ClockBack r={110} battery={0} />
        <circle r={110 * 0.95} fill="#a39a88" opacity={0.25} />
      </At>
    </PageInsert>
  );
};

// S22-02 — hesitation with the clock in her lap; the battery; the second hand shivers and moves on
export const S22_02: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const insert = T(at(319, "आख़िर बैटरी"));
  const moves = T(at(319, "सेकंड की सुई"));
  const shot = cutIndex(lt, [insert - 0.2, moves - 0.4]);
  const start = CLOCK_START();
  if (shot === 0) {
    return (
      <StudyScene
        f={f}
        t={t}
        grade="ending"
        hideClock
        hands="clock"
        laptop={false}
        cam={camAt(lt, [[0, { x: 880, y: 620, z: 2.0 }], [insert, { x: 880, y: 640, z: 2.3 }]])}
        meera={{ expr: "sad", gazeY: 0.9, headTilt: 20 }}
        extra={
          <At x={900} y={830} s={0.85} rot={-8}>
            <Clock r={STUDY.clock.r} frame={f} startFrame={start} />
          </At>
        }
      />
    );
  }
  if (shot === 1) {
    const slide = ramp(lt, insert, insert + 1.0);
    return (
      <PageInsert cam={{ x: 960, y: 540, z: 1 }}>
        <At x={960} y={540} s={3.6}>
          <ClockBack r={110} battery={slide} />
        </At>
        <At x={1500 - slide * 200} y={640} s={1.2} rot={-70}>
          <BigHand skin={M.skin} shade={M.skinShade} sleeve={M.top.color} sleeveShade={M.top.shade} watch pose={{ curl: [0.5, 0.6, 0.7, 0.75, 0.8] }} />
        </At>
      </PageInsert>
    );
  }
  return (
    <PageInsert cam={camAt(lt - moves, [[0, { x: 960, y: 540, z: 1 }], [dur - moves, { x: 960, y: 540, z: 1.08 }]])}>
      <At x={960} y={540} s={4.2}>
        <Clock r={110} frame={f} startFrame={start} />
      </At>
    </PageInsert>
  );
};

// S22-03 — another cassette, labelled in her mother's hand: «बच्चों की आवाज़ें». She plays it.
export const S22_03: React.FC = () => {
  const { f, lt, T } = useBeat();
  const play = T(at(323));
  const shot = cutIndex(lt, [play - 0.1]);
  const start = CLOCK_START();
  if (shot === 0) {
    return (
      <PageInsert cam={camAt(lt, [[0, { x: 960, y: 540, z: 1 }], [play, { x: 960, y: 520, z: 1.15 }]])}>
        <At x={960} y={540} s={6}>
          <Cassette w={130} label="बच्चों की आवाज़ें" shell="#6b5a48" handColor="#5a2a32" />
        </At>
      </PageInsert>
    );
  }
  const k = recorderKey(1);
  const press = ramp(lt, play + 0.3, play + 0.6);
  return (
    <Shot cam={{ x: k.x, y: k.y + 14, z: 5.6 }} grade="ending">
      <Layer>
        <StudyBack frame={f} clockStart={start} rain={0} warm={1} boxes={false} lamp={0.6} />
        <At x={rec.x} y={rec.y} s={1}>
          <Recorder w={rec.w} frame={f} playing={press > 0.5} playFrom={f - Math.round((lt - play - 0.6) * 24)} />
        </At>
        <At x={k.x - 6} y={k.y - 62 + press * 5} s={0.33} rot={160}>
          <BigHand skin={M.skin} shade={M.skinShade} sleeve={M.top.color} sleeveShade={M.top.shade} watch pose={{ curl: [0.55, 0, 0.85, 0.9, 0.9] }} />
        </At>
      </Layer>
    </Shot>
  );
};

// S22-04 — the family recording, remembered: the whistle, the complaint, the laugh, «रहने दो»
export const S22_04: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const mom = T(at(327));
  const loud = T(at(329));
  const shot = cutIndex(lt, [T(at(325, "छोटी मीरा")) - 0.1, mom - 0.1, T(at(327, "पिता ने")) - 0.1, loud - 0.1]);
  const blow = shot === 0 || shot === 4 ? 1 : 0;
  const cams: Cam[] = [
    { x: 760, y: 620, z: 2.3 },
    { x: 980, y: 600, z: 2.4 },
    { x: 1180, y: 520, z: 2.4 },
    { x: 1500, y: 520, z: 2.0 },
    { x: 960, y: 620, z: 1.3 },
  ];
  const aPlace: Place = { x: 720, y: STUDY.floorY, s: 1.15 };
  const aBase: Pose = alive(t, "famA", { stance: "stand", headTilt: shot === 4 ? -10 : -4, gazeX: 0.6, expr: blow ? { browInner: 0.2, browY: 0.4, lid: 0.2, lower: 0.1, mouth: 0, open: 0.2 } : "laugh" });
  return (
    <Shot cam={camAt(lt, [[0, cams[shot]], [dur, { ...cams[shot], z: cams[shot].z * 1.03 }]])} grade="memoryWarm" memoryEdge={0.6}>
      <Layer>
        <StudyBack frame={f} clockStart={null} rain={0} warm={1} boxes={false} lamp={0} hideClock={false} />
        <At x={rec.x} y={rec.y} s={1}>
          <Recorder w={rec.w} frame={f} playing playFrom={0} />
        </At>
        <Actor spec={anshu} place={aPlace} pose={{ ...aBase, near: blow ? reachW(anshu, aBase, "near", { x: 760, y: STUDY.floorY - 290 }, aPlace, "pinch", 0) : { sh: 30, el: 50 } }} />
        <Actor spec={meeraChild} place={{ x: 950, y: STUDY.floorY, s: 1.1, flip: true }} pose={alive(t, "famM", { stance: "stand", headTilt: 4, gazeX: 0.7, expr: shot === 1 ? "anger" : "soft", talk: speaks(t, 325, "माँ, इसे", "कराओ।”"), near: { sh: shot === 1 ? 60 : 10, el: shot === 1 ? 90 : 20, hand: "point" }, far: { sh: -6, el: 20 } })} />
        <Actor spec={mother} place={{ x: 1180, y: STUDY.floorY, s: 1.0, flip: true }} pose={alive(t, "famMom", { stance: "stand", headTilt: shot === 2 ? -8 : 2, gazeX: 0.7, expr: shot >= 2 ? "laugh" : "soft", near: { sh: 40, el: 80, hand: "open" }, far: { sh: -6, el: 20 } })} />
        <Actor spec={dineshYoung} place={{ x: 1560, y: STUDY.floorY - 40, s: 0.9, flip: true }} pose={alive(t, "famD", { stance: "stand", headTilt: 4, gazeX: 0.7, expr: "laugh", talk: speaks(t, 327, "रहने दो", "दो।”"), near: { sh: 50, el: 30, hand: "open" }, far: { sh: -6, el: 20 } })} />
      </Layer>
    </Shot>
  );
};

// S22-05 — she laughs, then cries; leaves it running; Kabir at the door; she moves a chair for him
export const S22_05: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const kabirAt = T(at(331, "बाहर कबीर"));
  const chair = T(at(331, "कुछ देर बाद"));
  const shot = cutIndex(lt, [kabirAt - 0.1, chair - 0.1]);
  const start = CLOCK_START();
  const cry = ramp(lt, T(at(331, "हँसते हुए")), T(at(331, "हँसते हुए")) + 1.2);
  const push = ramp(lt, chair + 0.4, chair + 1.6);
  return (
    <StudyScene
      f={f}
      t={t}
      grade="ending"
      clockStart={start}
      laptop={false}
      recorder={{ playing: true, playFrom: 0 }}
      kabirAt={shot >= 1 ? "door" : "none"}
      kabirP={{ expr: "soft", gazeX: 0.8 }}
      hands={shot === 2 ? "desk" : "lap"}
      meera={{ expr: cry > 0.5 ? "crying" : "laugh", gazeX: shot >= 1 ? 0.9 : 0.6, headTurn: shot >= 1 ? 0.3 : 0, ...(shot === 2 ? { far: { sh: 60 + push * 30, el: 10, hand: "open" } } : {}) }}
      cam={shot === 0 ? camAt(lt, [[0, SC2.meera], [kabirAt, SC2.meeraTight]]) : shot === 1 ? SC2.door : camAt(lt - chair, [[0, SC2.two], [dur - chair, { ...SC2.two, z: 1.25 }]])}
      extra={
        shot === 2 ? (
          <At x={610 - push * 120} y={STUDY.floorY + 20} s={0.95}>
            <Chair />
          </At>
        ) : null
      }
    />
  );
};

// S22-06 — two people listening; four old voices; the clock on the wall keeps going
export const S22_06: React.FC = () => {
  const { f, t, lt, dur } = useBeat();
  const start = CLOCK_START();
  const fade = ramp(lt, dur - 2.6, dur);
  const kPlace: Place = { x: 520, y: STUDY.floorY, s: 0.95 };
  return (
    <AbsoluteFadeOut amount={fade}>
      <StudyScene
        f={f}
        t={t}
        grade="ending"
        clockStart={start}
        laptop={false}
        recorder={{ playing: true, playFrom: 0 }}
        hands="lap"
        meera={{ expr: "soft", gazeX: 0.7, gazeY: 0.4 }}
        cam={camAt(lt, [[0, { x: 960, y: 520, z: 1.35 }], [dur, { x: 960, y: 540, z: 1.0 }]])}
        extra={
          <>
            <At x={kPlace.x - 40} y={kPlace.y} s={0.95}>
              <Chair />
            </At>
            <Actor spec={kabir} place={kPlace} pose={alive(t, "kEnd", { stance: "sit", lean: 6, headTilt: 6, gazeX: 0.7, gazeY: 0.3, expr: "soft", near: { sh: 40, el: 70 }, far: { sh: 30, el: 70 } })} />
          </>
        }
      />
    </AbsoluteFadeOut>
  );
};

const AbsoluteFadeOut: React.FC<{ amount: number; children: React.ReactNode }> = ({ amount, children }) => (
  <AbsoluteFill style={{ backgroundColor: "#000" }}>
    <AbsoluteFill style={{ opacity: 1 - amount }}>{children}</AbsoluteFill>
  </AbsoluteFill>
);
