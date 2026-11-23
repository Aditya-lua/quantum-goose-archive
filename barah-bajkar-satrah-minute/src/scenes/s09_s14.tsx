import React from "react";
import { camAt, cutIndex, Shot, useBeat } from "../engine/beat";
import { kf, ramp } from "../engine/anim";
import { At, Layer } from "../engine/Stage";
import type { Cam } from "../engine/Stage";
import { StudyBack, Chair, STUDY } from "../sets/Study";
import { HouseFront, HOUSE, HeightMark } from "../sets/House";
import { FactoryGate, AnnouncementRoom, ROOM, SchoolGate, GATE, FloodLane, Water } from "../sets/Factory";
import { Roadside } from "../sets/Places";
import { Cassette, Handkerchief, Keys, Laptop, Phone, Waveform } from "../props/Props";
import { BigHand } from "../rigs/BigHand";
import { Person } from "../rigs/Person";
import { anshu, dineshYoung, harish, kabir, kabirStreet, meeraAdult, meeraChild, mother } from "../rigs/characters";
import type { Pose } from "../rigs/types";
import { at, envSlice, para } from "../timing/time";
import { Actor, alive, PLACES, reachW, speaks, type Place } from "./common";
import { C } from "../style/palette";

const M = meeraAdult;

const walkPose = (t: number, seed: string, phase: number, extra: Partial<Pose> = {}): Pose =>
  alive(t, seed, {
    stance: "walk",
    walk: phase,
    near: { sh: -16 * Math.sin(phase * 6.283), el: 16, hand: "relaxed" },
    far: { sh: 16 * Math.sin(phase * 6.283), el: 14 },
    ...extra,
  });


// S09-01 — the closed factory; Vikram's posters
export const S09_01: React.FC = () => {
  const { f, lt, dur, T } = useBeat();
  const posters = T(at(97, "शहर में"));
  const ran = T(at(97, "उस रात संचालन"));
  const cam = camAt(lt, [
    [0, { x: 960, y: 560, z: 1.0 }],
    [posters, { x: 820, y: 640, z: 1.15 }],
    [ran, { x: 260, y: 720, z: 2.6 }],
    [dur, { x: 210, y: 730, z: 4.0 }],
  ]);
  return (
    <Shot cam={cam} grade="present">
      <Layer>
        <FactoryGate frame={f} dusk />
      </Layer>
    </Shot>
  );
};

// S09-02 — the watchman stops them, hears the name, takes out his keys. «हरीश काका?»
export const S09_02: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const name = T(at(99, "फिर दिनेश"));
  const kaka = T(at(101));
  const eyes = T(at(103));
  const shot = cutIndex(lt, [kaka - 0.15, eyes - 0.1]);
  const walk = Math.min(lt, 2.6);
  const hPlace: Place = { x: 520, y: 990, s: 0.95, flip: true };
  const keysOut = ramp(lt, name + 0.4, name + 1.4);
  const hBase: Pose = alive(t, "harishGate", { stance: "stand", lean: 10, headTilt: shot === 2 ? 22 : 8, gazeX: 0.6, gazeY: shot === 2 ? 1 : 0.2, expr: shot === 2 ? "pressed" : "tired" });
  const hPose: Pose = {
    ...hBase,
    near: lt < name ? { sh: 60, el: 20, hand: "open" } : { sh: 30 + keysOut * 20, el: 60, hand: "hold" },
    far: { sh: -4, el: 16 },
  };
  const mX = 1150 - walk * 120;
  const cam: Cam = shot === 0 ? camAt(lt, [[0, { x: 760, y: 600, z: 1.1 }], [kaka, { x: 720, y: 640, z: 1.3 }]]) : shot === 1 ? { x: 810, y: 520, z: 2.4 } : camAt(lt - eyes, [[0, { x: 520, y: 480, z: 2.8 }], [dur - eyes, { x: 520, y: 480, z: 3.2 }]]);
  return (
    <Shot cam={cam} grade="present">
      <Layer>
        <FactoryGate frame={f} dusk />
        <Actor spec={harish} place={hPlace} pose={hPose} nearHold={keysOut > 0 ? <g transform="translate(0 30)"><Keys s={0.9} swing={Math.sin(t * 3) * 6} /></g> : null} />
        <Actor spec={kabirStreet} place={{ x: mX + 170, y: 1000, s: 0.95, flip: true }} pose={walk < 2.6 ? walkPose(t, "kgate", walk * 0.45) : alive(t, "kg", { stance: "stand", expr: "listen", gazeX: 0.6, talk: speaks(t, 101), near: { sh: 6, el: 14 }, far: { sh: -6, el: 14 } })} />
        <Actor spec={M} place={{ x: mX, y: 1000, s: 0.92, flip: true }} pose={walk < 2.6 ? walkPose(t, "mgate", walk * 0.47) : alive(t, "mg", { stance: "stand", expr: "tense", gazeX: 0.6, near: { sh: 6, el: 14 }, far: { sh: -6, el: 14 } })} />
      </Layer>
    </Shot>
  );
};

// S09-03 — the mic room now: cut wires, a ring mark, the siren switch she does not touch
export const S09_03: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const sw = T(at(105, "पास ही"));
  const shot = cutIndex(lt, [sw - 0.2]);
  const place: Place = { x: 1230, y: ROOM.floorY, s: 0.95 };
  const hover = shot === 1 ? kf(lt - sw, [[0.4, 0], [1.6, 1], [3.2, 1], [4.2, 0.2]]) : 0;
  const base: Pose = alive(t, "room", { stance: "stand", headTilt: shot ? 4 : 10, gazeX: 0.8, gazeY: 0.2, expr: "tense" });
  const pose: Pose = { ...base, near: hover > 0 ? reachW(M, base, "near", { x: ROOM.switch.x - 80 + hover * 40, y: ROOM.switch.y }, place, "open", 70) : { sh: 6, el: 20 }, far: { sh: -6, el: 14 } };
  const cam: Cam = shot === 0 ? camAt(lt, [[0, { x: 960, y: 560, z: 1.0 }], [sw, { x: 1100, y: 640, z: 1.35 }]]) : camAt(lt - sw, [[0, { x: 1380, y: 540, z: 2.4 }], [dur - sw, { x: 1400, y: 530, z: 2.6 }]]);
  return (
    <Shot cam={cam} grade="present">
      <Layer>
        <AnnouncementRoom frame={f} era="present" bulb={0.4} />
        <Actor spec={M} place={place} pose={pose} />
      </Layer>
    </Shot>
  );
};

// S09-04 — memory: bringing her father's lunch to this desk
export const S09_04: React.FC = () => {
  const { f, t, lt, dur } = useBeat();
  const give = ramp(lt, 0.8, 2.0);
  const dPlace: Place = { x: 980, y: ROOM.floorY, s: 0.95, flip: true };
  const cPlace: Place = { x: 640 + give * 90, y: ROOM.floorY, s: 1.05 };
  const tiffin = { x: 820 + give * 30, y: 760 };
  const cBase: Pose = alive(t, "lunchC", { stance: give < 1 ? "walk" : "stand", walk: lt * 0.5, headTilt: -6, gazeX: 0.8, gazeY: -0.4, expr: "laugh" });
  const dBase: Pose = alive(t, "lunchD", { stance: "stand", lean: 14, headTilt: 12, gazeX: 0.8, gazeY: 0.6, expr: "laugh" });
  return (
    <Shot cam={camAt(lt, [[0, { x: 860, y: 600, z: 1.5 }], [dur, { x: 860, y: 600, z: 1.6 }]])} grade="memoryWarm" memoryEdge={0.7}>
      <Layer>
        <AnnouncementRoom frame={f} era="memory" sirenOn={0} />
        <Actor spec={dineshYoung} place={dPlace} pose={{ ...dBase, near: reachW(dineshYoung, dBase, "near", { x: tiffin.x + 40, y: tiffin.y - 20 }, dPlace, "open", 20) }} />
        <Actor spec={meeraChild} place={cPlace} pose={{ ...cBase, near: reachW(meeraChild, cBase, "near", tiffin, cPlace, "hold", 0) }} />
        <g transform={`translate(${tiffin.x} ${tiffin.y})`}>
          <rect x={-26} y={-60} width={52} height={60} rx={8} fill="#c4c7cc" stroke={C.ink} strokeWidth={2} />
          <path d="M -26 -40 L 26 -40 M -26 -20 L 26 -20" stroke="#8a8d92" strokeWidth={2} />
          <path d="M -16 -60 C -16 -84 16 -84 16 -60" stroke="#8a8d92" strokeWidth={5} fill="none" />
        </g>
      </Layer>
    </Shot>
  );
};

// S09-05 — through the broken pane: the back verandah, then the school gate, a few steps
export const S09_05: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const steps = T(at(109, "अब कमरे से"));
  const shot = cutIndex(lt, [steps - 0.2]);
  if (shot === 0) {
    const w = ROOM.window;
    return (
      <Shot cam={camAt(lt, [[0, { x: w.x + w.w / 2, y: w.y + w.h / 2, z: 2.3 }], [steps, { x: w.x + 280, y: w.y + 190, z: 3.4 }]])} grade="present">
        <Layer>
          <AnnouncementRoom frame={f} era="present" bulb={0.4} />
        </Layer>
      </Shot>
    );
  }
  const walk = lt - steps;
  return (
    <Shot cam={camAt(walk, [[0, { x: 760, y: 640, z: 1.2 }], [dur - steps, { x: 900, y: 640, z: 1.3 }]])} grade="present">
      <Layer>
        <SchoolGate frame={f} time="dusk" />
        <Actor spec={M} place={{ x: 300 + Math.min(walk, 3) * 130, y: 1060, s: 1.0 }} pose={walk < 3 ? walkPose(t, "steps", walk * 0.44) : alive(t, "stepStop", { stance: "stand", headTilt: -2, gazeX: 0.8, expr: "tense", near: { sh: 6, el: 14 }, far: { sh: -6, el: 14 } })} />
      </Layer>
    </Shot>
  );
};

/** Gate staging (present, dusk or day): Meera left, Kabir behind her, Harish right of the gate. */
const GateTrio: React.FC<{ f: number; t: number; time?: "dusk" | "day"; cam: Cam; meera?: Partial<Pose>; harishP?: Partial<Pose>; kabirP?: Partial<Pose>; keys?: boolean; chain?: "locked" | "open"; harishPlace?: Place; noKabir?: boolean }> = ({
  f,
  t,
  time = "dusk",
  cam,
  meera,
  harishP,
  kabirP,
  keys,
  chain = "locked",
  harishPlace = { x: 1330, y: 1040, s: 0.95, flip: true },
  noKabir,
}) => {
  const hBase: Pose = alive(t, "hTrio", { stance: "stand", lean: 10, headTilt: 10, gazeX: 0.7, gazeY: 0.4, expr: "tired", near: keys ? { sh: 40, el: 70, hand: "hold" } : { sh: 6, el: 16 }, far: { sh: -4, el: 12 }, ...harishP });
  return (
    <Shot cam={cam} grade={time === "day" ? "day" : "present"}>
      <Layer>
        <SchoolGate frame={f} time={time} chain={chain} />
        {!noKabir ? <Actor spec={kabirStreet} place={{ x: 470, y: 1050, s: 0.95 }} pose={alive(t, "kTrio", { stance: "stand", headTilt: 6, gazeX: 0.7, expr: "listen", near: { sh: 6, el: 14 }, far: { sh: -6, el: 14 }, ...kabirP })} /> : null}
        <Actor spec={M} place={{ x: 700, y: 1060, s: 0.95 }} pose={alive(t, "mTrio", { stance: "stand", headTilt: 4, gazeX: 0.8, expr: "tense", near: { sh: 8, el: 20 }, far: { sh: -6, el: 14 }, ...meera })} />
        <Actor spec={harish} place={harishPlace} pose={hBase} nearHold={keys ? <g transform="translate(0 30)"><Keys s={0.9} swing={Math.sin(t * 2) * 4} /></g> : null} />
      </Layer>
    </Shot>
  );
};

const GC = {
  wide: { x: 960, y: 640, z: 1.05 } as Cam,
  meera: { x: 760, y: 520, z: 2.6 } as Cam,
  harish: { x: 1290, y: 520, z: 2.6 } as Cam,
  kabir: { x: 520, y: 500, z: 2.6 } as Cam,
};

// S10-01 — «स्कूल का फाटक कहाँ था?» Harish leads them behind
export const S10_01: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const lead = T(at(113));
  const shot = cutIndex(lt, [lead - 0.1]);
  if (shot === 0) {
    return (
      <Shot cam={{ x: 1100, y: 520, z: 2.4 }} grade="present">
        <Layer>
          <AnnouncementRoom frame={f} era="present" bulb={0.4} />
          <Actor spec={M} place={{ x: 1230, y: ROOM.floorY, s: 0.95, flip: true }} pose={alive(t, "ask", { stance: "stand", headTilt: 2, gazeX: 0.8, expr: "tense", talk: speaks(t, 111, "स्कूल का", "था?”"), near: { sh: 6, el: 20 }, far: { sh: -6, el: 14 } })} />
        </Layer>
      </Shot>
    );
  }
  const w = lt - lead;
  return (
    <Shot cam={camAt(w, [[0, GC.wide], [5, { ...GC.wide, x: 1000 }]])} grade="present">
      <Layer>
        <SchoolGate frame={f} time="dusk" />
        <Actor spec={harish} place={{ x: 300 + w * 110, y: 1050, s: 0.95 }} pose={walkPose(t, "hLead", w * 0.4, { headTilt: 14 })} />
        <Actor spec={M} place={{ x: 80 + w * 110, y: 1060, s: 0.95 }} pose={walkPose(t, "mLead", w * 0.4)} />
        <Actor spec={kabirStreet} place={{ x: -120 + w * 110, y: 1050, s: 0.95 }} pose={walkPose(t, "kLead", w * 0.38)} />
      </Layer>
    </Shot>
  );
};

// S10-02 — the rusted gate; memory as darkness, cries, something striking iron
export const S10_02: React.FC = () => {
  const { f, lt, T } = useBeat();
  const mem = T(at(115, "मीरा की याद में"));
  const shot = cutIndex(lt, [mem - 0.1]);
  if (shot === 0) {
    return (
      <Shot cam={camAt(lt, [[0, { x: 960, y: 600, z: 1.0 }], [mem, { x: GATE.x, y: 700, z: 1.35 }]])} grade="present">
        <Layer>
          <SchoolGate frame={f} time="dusk" />
        </Layer>
      </Shot>
    );
  }
  const shake = Math.sin(lt * 31) * 4 * ramp(lt, mem + 0.5, mem + 1);
  return (
    <Shot cam={{ x: GATE.x + shake, y: 720, z: 1.8 }} grade="flood" memoryEdge={0.75}>
      <Layer>
        <SchoolGate frame={f} time="night" chain="locked" water={0.55} rain={1.3} />
        {[0, 1, 2, 3].map((i) => (
          <At key={i} x={GATE.x - 200 + i * 130} y={720 + (i % 2) * 40} s={0.38} rot={180 + (i % 2 ? 10 : -10)}>
            <g filter="url(#none)" opacity={0.95}>
              <BigHand skin="#05070e" shade="#05070e" pose={{ curl: [0.7, 0.75, 0.8, 0.8, 0.8] }} />
            </g>
          </At>
        ))}
      </Layer>
    </Shot>
  );
};

// S10-03 — «फाटक बंद क्यों था?» Harish presses his lips; Kabir: tomorrow it goes
export const S10_03: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const press = T(at(119));
  const kab = T(at(121, "काका, कल"));
  const shot = cutIndex(lt, [press - 0.1, kab - 0.1]);
  return (
    <GateTrio
      f={f}
      t={t}
      cam={shot === 0 ? GC.meera : shot === 1 ? GC.harish : GC.kabir}
      meera={{ talk: speaks(t, 117), expr: "anger" }}
      harishP={{ expr: shot === 1 ? "pressed" : "tired", gazeY: 0.8, headTilt: 16 }}
      kabirP={{ talk: speaks(t, 121, "काका, कल"), expr: "resolve" }}
    />
  );
};

// S10-04 — the order, the key in the office, trapped in the godown
export const S10_04: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const m = T(at(125));
  const h2 = T(at(127));
  const shot = cutIndex(lt, [m - 0.1, h2 - 0.1]);
  return (
    <GateTrio
      f={f}
      t={t}
      keys
      cam={shot === 1 ? GC.meera : camAt(lt, [[0, GC.harish], [lt + 1, { ...GC.harish, z: 2.8 }]])}
      meera={{ talk: speaks(t, 125), expr: "tense" }}
      harishP={{ talk: speaks(t, 123) + speaks(t, 127), expr: shot === 2 ? "grief" : "tired", gazeY: 0.6 }}
    />
  );
};

// S10-05 — her hands on the bars: they reached high ground and still could not get in
export const S10_05: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const face = T(at(129, "उसकी माँ"));
  const shot = cutIndex(lt, [face - 0.1]);
  if (shot === 0) {
    const grip = ramp(lt, 0.2, 0.8);
    return (
      <Shot cam={{ x: GATE.x, y: 700, z: 3.0 }} grade="present">
        <Layer>
          <SchoolGate frame={f} time="dusk" />
          {[-1, 1].map((k) => (
            <At key={k} x={GATE.x + k * 60} y={760 - grip * 20} s={0.42} rot={k * 6}>
              <g transform={k > 0 ? "scale(-1 1)" : undefined}>
                <BigHand skin={M.skin} shade={M.skinShade} sleeve={M.top.color} sleeveShade={M.top.shade} watch={k < 0} pose={{ curl: [0.6, 0.4 + grip * 0.45, 0.45 + grip * 0.45, 0.5 + grip * 0.4, 0.55 + grip * 0.35] }} />
              </g>
            </At>
          ))}
        </Layer>
      </Shot>
    );
  }
  // her face seen through the bars (from inside the courtyard)
  return (
    <Shot cam={camAt(lt - face, [[0, { x: 960, y: 540, z: 1 }], [dur - face, { x: 960, y: 540, z: 1.08 }]])} grade="present">
      <Layer>
        <rect x={-200} y={-200} width={2400} height={1500} fill="#4a4870" />
        <rect x={-200} y={760} width={2400} height={600} fill="#7a6a52" />
        <Actor spec={M} place={{ x: 930, y: 1900, s: 3.1 }} pose={alive(t, "barsFace", { stance: "stand", expr: "grief", gazeX: 0.2, gazeY: 0.3, near: { sh: 150, el: 20, hand: "grip" }, far: { sh: 150, el: 20, hand: "grip" } })} />
        {[...Array(9)].map((_, i) => (
          <rect key={i} x={560 + i * 100} y={-200} width={22} height={1500} fill="#4a3022" stroke={C.ink} strokeWidth={2} />
        ))}
        <rect x={-200} y={300} width={2400} height={26} fill="#4a3022" stroke={C.ink} strokeWidth={2} />
      </Layer>
    </Shot>
  );
};


// S10-06 — «यह बात आपने किसी को बताई?» «नौकरी बचानी थी» ... the habit of silence
export const S10_06: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const h = T(at(133));
  const quiet = T(at(133, "फिर बहुत धीमे"));
  const shot = cutIndex(lt, [h - 0.1]);
  return (
    <GateTrio
      f={f}
      t={t}
      keys
      cam={shot === 0 ? GC.meera : camAt(lt - h, [[0, GC.harish], [Math.max(1, quiet - h), { ...GC.harish, z: 2.9 }], [dur - h, { ...GC.harish, z: 3.4 }]])}
      meera={{ talk: speaks(t, 131), expr: "tense" }}
      harishP={{ talk: speaks(t, 133, "नौकरी बचानी", "थी,”") + speaks(t, 133, "बाद में", "रहने की।”"), expr: lt > quiet ? "grief" : "pressed", gazeY: 0.9, headTilt: 20 }}
    />
  );
};

// S11-01 — walking back: the lawyer's message. «शायद संयोग हो।» «शायद।»
export const S11_01: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const show = T(at(137));
  const k = T(at(139));
  const off = T(at(141));
  const shot = cutIndex(lt, [1.4, show - 0.1, k - 0.1, off - 0.1]);
  const walking = shot === 0;
  const phoneLit = lt > 0.6 && lt < off + 0.4;
  const mPlace: Place = { x: 900, y: 1000, s: 0.95 };
  const kPlace: Place = { x: 1160, y: 1000, s: 0.95, flip: true };
  const mBase: Pose = walking ? walkPose(t, "lw", lt * 0.45) : alive(t, "lw2", { stance: "stand", headTilt: shot === 1 ? 18 : 6, gazeX: 0.5, gazeY: shot === 1 ? 0.9 : 0.2, expr: shot === 4 ? "resolve" : "tense", talk: speaks(t, 141, "शायद।”") });
  const phonePt = { x: 960, y: 640 };
  const mPose: Pose = walking ? mBase : { ...mBase, near: reachW(M, mBase, "near", phonePt, mPlace, "hold", 90) };
  const cam: Cam = shot === 0 ? camAt(lt, [[0, { x: 1000, y: 600, z: 1.2 }], [1.4, { x: 1020, y: 600, z: 1.25 }]]) : shot === 1 ? { x: 960, y: 620, z: 4.0 } : shot === 3 ? { x: 1180, y: 520, z: 2.6 } : { x: 1020, y: 560, z: 1.9 };
  return (
    <Shot cam={cam} grade="present">
      <Layer>
        <Roadside frame={f} dusk />
        <Actor spec={kabirStreet} place={kPlace} pose={alive(t, "lk", { stance: "stand", headTilt: 6, gazeX: 0.8, expr: "listen", talk: speaks(t, 139), near: { sh: 6, el: 14 }, far: { sh: -6, el: 14 } })} />
        <Actor spec={M} place={mPlace} pose={mPose} nearHold={!walking ? <g transform="translate(0 30) rotate(180)"><Phone w={38} lit={phoneLit} sender="वकील" /></g> : null} />
      </Layer>
    </Shot>
  );
};

// S12-01 — washing the verandah steps; mud runs off
export const S12_01: React.FC = () => {
  const { f, t, lt, dur } = useBeat();
  const place: Place = { x: 900, y: HOUSE.verandahY + 112, s: 0.9 };
  const scrub = Math.sin(lt * 5);
  const base: Pose = alive(t, "wash", { stance: "crouch", headTilt: 24, gazeY: 0.9, expr: "tired" });
  return (
    <Shot cam={camAt(lt, [[0, { x: 960, y: 700, z: 1.3 }], [dur, { x: 1100, y: 720, z: 1.45 }]])} grade="day">
      <Layer>
        <HouseFront frame={f} time="day" mud={1 - ramp(lt, 0, dur)} wet={0.8} />
        <Actor spec={M} place={place} pose={{ ...base, near: reachW(M, base, "near", { x: 1000 + scrub * 50, y: HOUSE.verandahY + 70 }, place, "open", 70) }} />
        <rect x={760} y={HOUSE.verandahY + 70} width={60} height={50} fill="#5a6a7a" stroke={C.ink} strokeWidth={2} />
      </Layer>
    </Shot>
  );
};

// S12-02 — the height mark; her cloth stops short of it
export const S12_02: React.FC = () => {
  const { f, lt, dur } = useBeat();
  const reach = kf(lt, [[0.3, 0], [1.6, 1], [dur, 1]]);
  const hm = HOUSE.heightMark;
  return (
    <Shot cam={camAt(lt, [[0, { x: hm.x, y: hm.y - 20, z: 3.6 }], [dur, { x: hm.x, y: hm.y - 10, z: 4.2 }]])} grade="day">
      <Layer>
        <HouseFront frame={f} time="day" wet={0.8} mud={0.2} />
        <At x={hm.x + 120 - reach * 70} y={hm.y + 30} s={0.32} rot={-70}>
          <BigHand skin={M.skin} shade={M.skinShade} sleeve={M.top.color} sleeveShade={M.top.shade} watch pose={{ curl: [0.4, 0.3, 0.35, 0.4, 0.45] }} />
          <rect x={-70} y={-170} width={140} height={90} rx={10} fill="#c9c6be" stroke={C.ink} strokeWidth={2} />
        </At>
        <HeightMark x={hm.x} y={hm.y} s={0.6} />
      </Layer>
    </Shot>
  );
};

// S12-03 — warm afternoon: the whistle lesson; then the memory runs into water
export const S12_03: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const sound = T(at(145, "फिर जब निकली"));
  const water = T(at(145, "उसकी हर याद"));
  const laugh = lt > sound + 0.5 && lt < water;
  const cPlace: Place = { x: 860, y: HOUSE.verandahY + 40, s: 1.15 };
  const aPlace: Place = { x: 1080, y: HOUSE.verandahY + 40, s: 1.15, flip: true };
  const aBase: Pose = alive(t, "lesson", { stance: "sit", headTilt: laugh ? -6 : 4, gazeX: 0.5, expr: laugh ? "laugh" : { browInner: 0.3, browY: 0.3, lid: 0.1, lower: 0, mouth: 0, open: 0.18 } });
  const cBase: Pose = alive(t, "teach", { stance: "sit", headTilt: laugh ? -8 : 6, gazeX: 0.6, gazeY: 0.3, expr: laugh ? "laugh" : "soft" });
  const blowing = !laugh && lt < water;
  const flood = ramp(lt, water + 0.4, dur, (x) => x);
  return (
    <Shot cam={camAt(lt, [[0, { x: 970, y: 700, z: 2.0 }], [dur, { x: 970, y: 700, z: 2.2 }]])} grade="memoryWarm" memoryEdge={0.75}>
      <Layer>
        <HouseFront frame={f} time="day" wet={0} showMark={false} />
        <Actor spec={meeraChild} place={cPlace} pose={{ ...cBase, near: { sh: laugh ? 40 : 70, el: laugh ? 40 : 90, hand: "open" }, far: { sh: 30, el: 60 } }} />
        <Actor spec={anshu} place={aPlace} pose={{ ...aBase, near: blowing ? reachW(anshu, aBase, "near", { x: 1050, y: HOUSE.verandahY - 130 }, aPlace, "pinch", 0) : { sh: 30, el: 60, hand: "relaxed" } }} />
        {flood > 0 ? <Water frame={f} y={1100 - flood * 900} dye={0.2} seed="memWater" opacity={0.5 + flood * 0.5} /> : null}
      </Layer>
    </Shot>
  );
};

/** Study at night with Meera at her father's desk and the laptop. */
const DeskNight: React.FC<{ f: number; t: number; cam: Cam; meera?: Partial<Pose>; screen?: React.ReactNode; kabirInDoor?: "work" | "door" | "none"; kabirP?: Partial<Pose>; headphones?: "on" | "neck"; hands?: "laptop" | "lap" | "face"; grade?: "present" }> = ({
  f,
  t,
  cam,
  meera,
  screen,
  kabirInDoor = "work",
  kabirP,
  headphones = "neck",
  hands = "laptop",
}) => {
  const place = PLACES.meeraAtDesk;
  const base: Pose = alive(t, "deskNight", { stance: "sit", lean: 10, headTilt: 8, gazeX: 0.8, gazeY: 0.3, expr: "listen", ...meera });
  const pose: Pose = {
    ...base,
    near: hands === "laptop" ? reachW(M, base, "near", { x: 1010, y: STUDY.deskTop - 6 }, place, "relaxed", 70) : hands === "face" ? { sh: 120, el: 110, hand: "open" } : { sh: 30, el: 60 },
    far: hands === "lap" ? { sh: 30, el: 60 } : reachW(M, base, "far", { x: 960, y: STUDY.deskTop - 4 }, place, "relaxed", 60),
    ...(meera?.near ? { near: meera.near } : {}),
  };
  const showMeera = cam.z < 4;
  return (
    <Shot cam={cam} grade="present">
      <Layer>
        <StudyBack frame={f} clockStart={null} rain={0.6} doorLight={1} />
        {kabirInDoor === "work" ? (
          <Actor spec={kabir} place={{ x: 1790, y: 900, s: 0.62, flip: true }} pose={alive(t, "kWork", { stance: "sit", lean: 24, headTilt: 20, gazeY: 0.9, expr: "listen", near: { sh: 60, el: 60, hand: "grip" }, far: { sh: 50, el: 70 }, ...kabirP })} />
        ) : kabirInDoor === "door" ? (
          <Actor spec={kabir} place={{ x: 1730, y: STUDY.floorY - 30, s: 0.88, flip: true }} pose={alive(t, "kDoor", { stance: "stand", headTilt: 6, gazeX: 0.7, expr: "soft", near: { sh: 30, el: 60, hand: "relaxed" }, far: { sh: -4, el: 14 }, ...kabirP })} />
        ) : null}
        <At x={1040} y={STUDY.deskTop} s={1}>
          <Laptop w={240} screen={screen} />
        </At>
        <At x={1300} y={STUDY.deskTop - 10} s={1} rot={-6}>
          <Handkerchief w={110} open={0.6} />
        </At>
        <At x={1305} y={STUDY.deskTop - 16} s={1} rot={-6}>
          <g transform="scale(1 0.5)">
            <Cassette w={70} />
          </g>
        </At>
        <At x={desk().x - 40} y={desk().y} s={0.95}>
          <Chair />
        </At>
        {showMeera ? <Actor spec={M} place={place} pose={pose} headphones={headphones} /> : null}
      </Layer>
    </Shot>
  );
};
const desk = () => PLACES.meeraAtDesk;

/** Laptop restoration UI: original + cleaned tracks. */
const RestoreScreen: React.FC<{ t0: number; t1: number; reduce: number; playhead?: number; mark?: [number, number]; files?: number }> = ({ t0, t1, reduce, playhead, mark, files = 0 }) => {
  const w = 240 * 0.9;
  const h = w * 0.6;
  const env = envSlice(t0, t1, 80);
  const rain = env.map((v, i) => Math.max(v, 0.35 + 0.1 * Math.sin(i * 1.7)));
  return (
    <g>
      <rect width={w} height={h} fill="#0d1424" />
      <g transform="translate(6 8)">
        <Waveform w={w - 12} h={h * 0.38} env={rain} playhead={playhead} mark={mark} color="#6fc3c9" />
      </g>
      <g transform={`translate(6 ${h * 0.46})`}>
        <Waveform w={w - 12} h={h * 0.38} env={rain.map((v, i) => Math.max(env[i], v * (1 - reduce * 0.55)))} playhead={playhead} mark={mark} color="#e8a54b" reduced={reduce} />
      </g>
      <rect x={6} y={h * 0.9} width={w * 0.5} height={4} fill="#2a3b5a" />
      <circle cx={6 + w * 0.5 * (1 - reduce * 0.6)} cy={h * 0.9 + 2} r={5} fill="#f3eee4" />
      {files > 0 ? (
        <g opacity={files}>
          <rect x={w * 0.56} y={h * 0.84} width={w * 0.18} height={h * 0.14} rx={2} fill="#2a3b5a" />
          <rect x={w * 0.78} y={h * 0.84} width={w * 0.18} height={h * 0.14} rx={2} fill="#2a3b5a" />
          <text x={w * 0.65} y={h * 0.94} fontSize={7} fill="#f3eee4" textAnchor="middle" fontFamily="NotoDeva, sans-serif">
            मूल
          </text>
          <text x={w * 0.87} y={h * 0.94} fontSize={7} fill="#f3eee4" textAnchor="middle" fontFamily="NotoDeva, sans-serif">
            कम शोर
          </text>
        </g>
      ) : null}
    </g>
  );
};

const DC = {
  wide: { x: 1180, y: 560, z: 1.0 } as Cam,
  meera: { x: 860, y: 560, z: 2.4 } as Cam,
  screen: { x: 1040, y: 650, z: 4.6 } as Cam,
  door: { x: 1640, y: 560, z: 2.0 } as Cam,
};

// S13-01 — copies made; the original set apart; Kabir at work in the outer room
export const S13_01: React.FC = () => {
  const { f, t, lt, dur } = useBeat();
  return (
    <DeskNight f={f} t={t} cam={camAt(lt, [[0, DC.wide], [dur, { ...DC.wide, x: 1120, z: 1.15 }]])} screen={<RestoreScreen t0={para(165).start} t1={para(169).end} reduce={0} files={ramp(lt, 2, 3)} />} />
  );
};

// S13-02 — reduce the rain, never remove it; check the original before each change
export const S13_02: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const listen = T(at(149, "हर बदलाव"));
  const reduce = kf(lt, [[1, 0], [listen, 0.55], [dur, 0.55]]);
  const shot = cutIndex(lt, [listen - 0.1]);
  return (
    <DeskNight
      f={f}
      t={t}
      headphones="on"
      cam={shot === 0 ? DC.screen : DC.meera}
      meera={{ expr: "listen", gazeY: 0.4 }}
      screen={<RestoreScreen t0={para(165).start} t1={para(169).end} reduce={reduce} playhead={(lt % 4) / 4} />}
    />
  );
};

// S13-03 — breath only; maybe a name; she leaves it as it is
export const S13_03: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const leave = T(at(151, "फिर वैसा ही"));
  const shot = cutIndex(lt, [leave - 0.1]);
  const loop = 0.42 + ((lt * 0.12) % 0.16);
  if (shot === 1) {
    const back = ramp(lt, leave + 0.3, leave + 1.4);
    return (
      <Shot cam={{ x: 1040, y: 690, z: 4 }} grade="present">
        <Layer>
          <StudyBack frame={f} clockStart={null} rain={0.6} />
          <At x={1040} y={STUDY.deskTop} s={1}>
            <Laptop w={240} screen={<RestoreScreen t0={para(167).start} t1={para(169).start} reduce={0.55} playhead={0.5} mark={[0.42, 0.58]} />} />
          </At>
          <At x={1000 - back * 90} y={STUDY.deskTop + 30 + back * 40} s={0.4} rot={-130}>
            <BigHand skin={M.skin} shade={M.skinShade} sleeve={M.top.color} sleeveShade={M.top.shade} watch pose={{ curl: [0.3, 0.2 + back * 0.4, 0.3 + back * 0.4, 0.35 + back * 0.4, 0.4 + back * 0.4] }} />
          </At>
        </Layer>
      </Shot>
    );
  }
  return <DeskNight f={f} t={t} headphones="on" cam={camAt(lt, [[0, DC.screen], [leave, { ...DC.screen, z: 5.2 }]])} screen={<RestoreScreen t0={para(167).start} t1={para(169).start} reduce={0.55} playhead={loop} mark={[0.42, 0.58]} />} />;
};

// S13-04 — «कुछ समझ आया?» «नहीं।» ... «...नहीं भर सकते।»
export const S13_04: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const no = T(at(155));
  const k2 = T(at(157));
  const m2 = T(at(159));
  const shot = cutIndex(lt, [no - 0.1, k2 - 0.1, m2 - 0.1]);
  const cam = shot === 0 || shot === 2 ? DC.door : camAt(lt, [[0, DC.meera], [lt + 1, { ...DC.meera, z: 2.6 }]]);
  return (
    <DeskNight
      f={f}
      t={t}
      kabirInDoor="door"
      cam={cam}
      kabirP={{ talk: speaks(t, 153, "कुछ समझ", "आया?”") + speaks(t, 157) }}
      meera={{ talk: speaks(t, 155) + speaks(t, 159), expr: shot === 3 ? "resolve" : "tired", gazeX: 0.9, headTurn: 0.4 }}
      screen={<RestoreScreen t0={para(167).start} t1={para(169).start} reduce={0.55} mark={[0.42, 0.58]} />}
    />
  );
};

// S13-05 — two files, dated: the original and the reduced-noise copy
export const S13_05: React.FC = () => {
  const { f, t, lt } = useBeat();
  return <DeskNight f={f} t={t} cam={camAt(lt, [[0, { x: 1080, y: 650, z: 4.4 }], [lt + 1, { x: 1080, y: 650, z: 4.5 }]])} screen={<RestoreScreen t0={para(165).start} t1={para(169).end} reduce={0.55} files={ramp(lt, 0.4, 1.2)} />} />;
};

/** Flood night at the gate: mother (holding Anshu) and the young father. */
const GateNight: React.FC<{ f: number; t: number; cam: Cam; mom?: Partial<Pose>; dad?: Partial<Pose>; showDad?: boolean; momPoint?: number }> = ({ f, t, cam, mom, dad, showDad = false, momPoint = 0 }) => {
  const mPlace: Place = { x: 820, y: 1070, s: 1.0 };
  const aPlace: Place = { x: 680, y: 1070, s: 1.0 };
  const mBase: Pose = alive(t, "gateMom", { stance: "stand", lean: 6, headTilt: -2, headTurn: 0.5, gazeX: 0.9, expr: "fear", ...mom });
  const handPt = { x: 740, y: 870 };
  return (
    <Shot cam={cam} grade="flood" memoryEdge={0.6}>
      <Layer>
        <SchoolGate frame={f} time="night" chain="locked" water={0.4} rain={1.3} />
        <Actor spec={anshu} place={aPlace} pose={{ ...alive(t, "gateA", { stance: "stand", headTilt: -10, gazeX: 0.8, gazeY: -0.6, expr: "fear" }), near: reachW(anshu, { stance: "stand" }, "near", handPt, aPlace, "grip", 0) }} />
        <Actor spec={mother} place={mPlace} pose={{ ...mBase, far: reachW(mother, mBase, "far", handPt, mPlace, "grip", 0), near: momPoint > 0 ? { sh: -20 - momPoint * 50, el: 8, hand: "point" } : { sh: 40, el: 50, hand: "open" } }} />
        {showDad ? <Actor spec={dineshYoung} place={{ x: 1160, y: 1070, s: 1.0, flip: true }} pose={alive(t, "gateDad", { stance: "stand", lean: 12, headTilt: 4, gazeX: 0.8, expr: "fear", near: { sh: 30, el: 40 }, far: { sh: -10, el: 30 }, ...dad })} /> : null}
        <Water frame={f} y={1000 - 0.4 * 200} dye={0.8} seed="gateNightW" opacity={0.8} />
      </Layer>
    </Shot>
  );
};

// S14-01 — her mother's sentence surfaces: «...खोलो। बच्चे बाहर हैं।»
export const S14_01: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const line = T(at(165));
  const shot = cutIndex(lt, [line - 0.1]);
  if (shot === 0) return <DeskNight f={f} t={t} headphones="on" cam={DC.meera} meera={{ expr: "listen", gazeY: 0.4 }} screen={<RestoreScreen t0={para(165).start} t1={para(169).end} reduce={0.55} playhead={0.1} />} />;
  return <GateNight f={f} t={t} cam={camAt(lt - line, [[0, { x: 900, y: 680, z: 1.35 }], [dur - line, { x: 860, y: 660, z: 1.6 }]])} mom={{ talk: speaks(t, 165) }} />;
};

// S14-02 — the young father, panting: «मीरा कहाँ है?»
export const S14_02: React.FC = () => {
  const { f, t, lt, dur } = useBeat();
  return <GateNight f={f} t={t} showDad cam={camAt(lt, [[0, { x: 1130, y: 640, z: 2.4 }], [dur, { x: 1130, y: 630, z: 2.6 }]])} dad={{ talk: speaks(t, 167, "मीरा कहाँ", "है?”"), breath: Math.sin(t * 9) }} />;
};

// S14-03 — mother, holding Anshu, points back: «पीछे गिरी है। उसे उठाओ।»
export const S14_03: React.FC = () => {
  const { f, t, lt, dur } = useBeat();
  return <GateNight f={f} t={t} showDad cam={camAt(lt, [[0, { x: 860, y: 640, z: 2.0 }], [dur, { x: 840, y: 640, z: 2.15 }]])} mom={{ talk: speaks(t, 169), headTurn: 0.7 }} momPoint={ramp(lt, 0.6, 1.2)} />;
};

// S14-04 — a crash, a cry, footsteps running from the microphone; the empty room
export const S14_04: React.FC = () => {
  const { f, lt, dur } = useBeat();
  const swing = Math.sin(lt * 5) * 9 * Math.exp(-lt * 0.6);
  return (
    <Shot cam={camAt(lt, [[0, { x: ROOM.mic.x, y: ROOM.mic.y - 120, z: 2.6 }], [dur, { x: ROOM.mic.x, y: ROOM.mic.y - 120, z: 2.8 }]])} grade="flood" memoryEdge={0.5}>
      <Layer>
        <AnnouncementRoom frame={f} era="flood" sirenOn={0} micSwing={swing} />
      </Layer>
    </Shot>
  );
};

// S14-05 — she stops the recording
export const S14_05: React.FC = () => {
  const { f, t, lt } = useBeat();
  const shot = cutIndex(lt, [0.9]);
  return <DeskNight f={f} t={t} headphones="on" cam={shot === 0 ? DC.screen : DC.meera} meera={{ expr: "shock", gazeY: 0.2 }} screen={<RestoreScreen t0={para(169).start} t1={para(171).end} reduce={0.55} playhead={0.9} />} />;
};

// S14-06 — the memory completes: he carries her while she beats his back
export const S14_06: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const now = T(at(175, "अब वह सुन"));
  const shot = cutIndex(lt, [now - 0.1]);
  if (shot === 1) return <DeskNight f={f} t={t} headphones="neck" cam={camAt(lt - now, [[0, { ...DC.meera, z: 2.8 }], [dur - now, { ...DC.meera, z: 3.1 }]])} meera={{ expr: "crying", gazeY: 0.5 }} />;
  const walk = lt;
  const dPlace: Place = { x: 1300 - walk * 50, y: 1080, s: 1.1, flip: true };
  const beat = Math.abs(Math.sin(lt * 6));
  return (
    <Shot cam={camAt(lt, [[0, { x: 1150, y: 600, z: 1.5 }], [now, { x: 1050, y: 600, z: 1.6 }]])} grade="flood" memoryEdge={0.6}>
      <Layer>
        <FloodLane frame={f} water={0.5} light={0.8} />
        <Actor spec={dineshYoung} place={dPlace} pose={walkPose(t, "carry", walk * 0.6, { lean: 10, headTilt: 8, expr: "fear", near: { sh: 70, el: 60, hand: "grip" }, far: { sh: 80, el: 70, hand: "grip" } })} />
        <At x={dPlace.x + 20} y={dPlace.y - 330} s={0.88} rot={-12}>
          <Person spec={meeraChild} pose={alive(t, "carried", { stance: "sit", lean: -10, headTilt: -14, gazeX: 0.8, expr: "crying", near: { sh: 150 + beat * 25, el: 40 + beat * 30, hand: "fist" }, far: { sh: 110, el: 5, hand: "open" } })} />
        </At>
        <Water frame={f} y={1080 - 0.5 * 260} dye={0.75} seed="carryW" opacity={0.85} />
      </Layer>
    </Shot>
  );
};


// S14-07 — but he switched off the siren; both truths at once
export const S14_07: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const both = T(at(179));
  const shot = cutIndex(lt, [both - 0.1]);
  if (shot === 0) {
    const sw = ROOM.switch;
    return (
      <Shot cam={{ x: sw.x, y: sw.y, z: 4.6 }} grade="flood" memoryEdge={0.5}>
        <Layer>
          <AnnouncementRoom frame={f} era="flood" sirenOn={1 - ramp(lt, 0.4, 0.6)} />
        </Layer>
      </Shot>
    );
  }
  return <DeskNight f={f} t={t} kabirInDoor="none" hands="lap" cam={camAt(lt - both, [[0, { x: 1000, y: 560, z: 1.3 }], [dur - both, { x: 960, y: 560, z: 1.4 }]])} meera={{ expr: "grief", gazeY: 0.8, headTilt: 18 }} />;
};

