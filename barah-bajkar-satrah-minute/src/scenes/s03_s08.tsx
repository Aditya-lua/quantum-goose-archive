import React from "react";
import { camAt, cutIndex, Shot, useBeat } from "../engine/beat";
import { kf, ramp } from "../engine/anim";
import { At, Layer } from "../engine/Stage";
import { StudyBack, Chair, STUDY } from "../sets/Study";
import { DelhiStudio, Bazaar, SHOP } from "../sets/Shop";
import { HouseFront } from "../sets/House";
import { Town, SirenPole, InquiryFile, AnnouncementRoom, ROOM, SchoolGate, FloodLane, Water } from "../sets/Factory";
import { Cassette, Handkerchief, Phone, Recorder } from "../props/Props";
import { BigHand } from "../rigs/BigHand";
import { anshu, dineshOld, dineshYoung, kabir, meeraAdult, meeraChild, meeraRain, mother, vikramNight } from "../rigs/characters";
import { townsperson } from "../rigs/crowd";
import { Person } from "../rigs/Person";
import { Head } from "../rigs/Head";
import type { Pose } from "../rigs/types";
import { at, para } from "../timing/time";
import { Actor, alive, PLACES, reachW, recorderKey, speaks } from "./common";
import { SHOP_CAMS as SC, SHOP_PLACES, ShopShot, ShopStage } from "./shop";
import { C } from "../style/palette";

const M = meeraAdult;
const rec = PLACES.recorderAtDesk;

const walkPose = (t: number, seed: string, phase: number, extra: Partial<Pose> = {}): Pose =>
  alive(t, seed, {
    stance: "walk",
    walk: phase,
    near: { sh: -16 * Math.sin(phase * 6.283), el: 16, hand: "relaxed" },
    far: { sh: 16 * Math.sin(phase * 6.283), el: 14 },
    ...extra,
  });

// S03-01 — Delhi: cleaning other people's recordings; silencing calls from home
export const S03_01: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const phoneAt = T(at(15, "अपने घर से"));
  const hushAt = T(at(15, "चुप करा देती"));
  const shot = cutIndex(lt, [Math.min(3.2, phoneAt - 3), phoneAt - 0.2]);
  const place = { x: 700, y: 1000, s: 0.95 };
  const base: Pose = alive(t, "delhi", { stance: "sit", lean: 12, headTilt: 6, gazeX: 0.8, gazeY: 0.1, expr: "listen" });
  const phoneLit = lt > phoneAt && lt < hushAt + 0.6;
  const silence = ramp(lt, hushAt - 0.3, hushAt + 0.2);
  const pose: Pose = {
    ...base,
    near: shot === 2 ? reachW(M, base, "near", { x: 640 + silence * 10, y: 690 }, place, "open", 70) : reachW(M, base, "near", { x: 860, y: 690 }, place, "relaxed", 60),
    far: reachW(M, base, "far", { x: 900, y: 696 }, place, "relaxed", 60),
  };
  const cam =
    shot === 0
      ? camAt(lt, [[0, { x: 1060, y: 470, z: 2.4 }], [3.2, { x: 1040, y: 480, z: 2.2 }]])
      : shot === 1
        ? camAt(lt, [[0, { x: 900, y: 560, z: 1.25 }], [dur, { x: 880, y: 570, z: 1.35 }]])
        : camAt(lt - phoneAt, [[0, { x: 650, y: 650, z: 3.2 }], [dur, { x: 650, y: 660, z: 3.4 }]]);
  return (
    <Shot cam={cam} grade="present">
      <Layer>
        <DelhiStudio frame={f} />
        <At x={640} y={690} s={1} rot={-80}>
          <Phone w={46} lit={phoneLit} sender="घर" />
        </At>
        <At x={place.x - 40} y={place.y} s={0.95}>
          <Chair color="#2a2b30" />
        </At>
        <Actor spec={M} place={place} pose={pose} headphones="on" />
      </Layer>
    </Shot>
  );
};

// S03-02 — the emptied house; the tape almirah; the cassette in a handkerchief
export const S03_02: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const almAt = T(at(17, "बस टेपों वाली"));
  const foundAt = T(at(17, "उसके भीतर"));
  const shot = cutIndex(lt, [almAt - 0.2, foundAt - 0.2]);
  if (shot === 2) {
    const open = ramp(lt, foundAt + 0.4, foundAt + 2.4);
    const cam = camAt(lt - foundAt, [[0, { x: 960, y: 560, z: 1.0 }], [dur, { x: 960, y: 560, z: 1.1 }]]);
    return (
      <Shot cam={cam} grade="present" bg="#2a2520">
        <Layer>
          <rect x={-200} y={-200} width={2400} height={1500} fill="#3a2a20" />
          <At x={960} y={600} s={3.2}>
            <Handkerchief w={200} open={open} />
          </At>
          <At x={960} y={560} s={3.2} opacity={open}>
            <Cassette w={110} />
          </At>
          <At x={620} y={900} s={1.1} rot={-30}>
            <BigHand skin={M.skin} shade={M.skinShade} sleeve={M.top.color} sleeveShade={M.top.shade} watch pose={{ curl: [0.3, 0.3, 0.35, 0.4, 0.45] }} />
          </At>
          <At x={1320} y={900} s={1.1} rot={35}>
            <g transform="scale(-1 1)">
              <BigHand skin={M.skin} shade={M.skinShade} sleeve={M.top.color} sleeveShade={M.top.shade} pose={{ curl: [0.3, 0.3, 0.35, 0.4, 0.45] }} />
            </g>
          </At>
        </Layer>
      </Shot>
    );
  }
  const place = { x: 380, y: STUDY.floorY, s: 0.95, flip: true };
  const crouch = shot === 1;
  const base: Pose = alive(t, "alm", { stance: crouch ? "crouch" : "stand", headTilt: crouch ? 20 : 10, gazeX: 0.5, gazeY: 0.5, expr: "tired" });
  const pose: Pose = crouch
    ? { ...base, near: reachW(M, base, "near", { x: 220 - ramp(lt, almAt, almAt + 1.5) * 50, y: 760 }, place, "grip", 40), far: { sh: 30, el: 40 } }
    : { ...base, near: { sh: 10, el: 30 }, far: { sh: -6, el: 20 } };
  const cam =
    shot === 0
      ? camAt(lt, [[0, { x: 960, y: 540, z: 1.0 }], [almAt, { x: 900, y: 560, z: 1.08 }]])
      : camAt(lt - almAt, [[0, { x: 300, y: 640, z: 2.0 }], [foundAt - almAt, { x: 260, y: 680, z: 2.3 }]]);
  return (
    <Shot cam={cam} grade="present">
      <Layer>
        <StudyBack frame={f} clockStart={null} />
        <At x={rec.x} y={rec.y} s={1}>
          <Recorder w={rec.w} frame={f} playing={false} />
        </At>
        <Actor spec={M} place={shot === 0 ? { x: 1300, y: STUDY.floorY, s: 0.95, flip: true } : place} pose={shot === 0 ? alive(t, "alm0", { stance: "stand", headTilt: 14, gazeX: 0.4, gazeY: 0.6, expr: "tired", near: { sh: 8, el: 20 }, far: { sh: -6, el: 16 } }) : pose} />
      </Layer>
    </Shot>
  );
};

// S03-03 — the stretched tape; she stops it
export const S03_03: React.FC = () => {
  const { f, lt, T } = useBeat();
  const stopAt = T(at(19, "मीरा ने बटन"));
  const pressPlay = ramp(lt, 0.1, 0.4);
  const playing = lt > 0.4 && lt < stopAt + 0.3;
  // slow, uneven reel motion: the loose tape drags
  const angle = playing ? (lt - 0.4) * 24 * 3.5 + Math.sin(lt * 5) * 8 : (stopAt - 0.1) * 24 * 3.5;
  const shot = cutIndex(lt, [stopAt - 0.8]);
  const cam =
    shot === 0
      ? camAt(lt, [[0, { x: rec.x + rec.w * 0.22, y: rec.y - rec.w * 0.27, z: 18 }], [stopAt, { x: rec.x + rec.w * 0.22, y: rec.y - rec.w * 0.27, z: 20 }]])
      : { x: recorderKey(4).x, y: recorderKey(4).y + 10, z: 5.6 };
  const k = recorderKey(4);
  const press = ramp(lt, stopAt - 0.2, stopAt + 0.1);
  return (
    <Shot cam={cam} grade="present">
      <Layer>
        <StudyBack frame={f} clockStart={null} />
        <At x={rec.x} y={rec.y} s={1}>
          <Recorder w={rec.w} frame={f} playing={playing} angle={angle} pressed={pressPlay < 1 && lt < 0.4 ? null : press > 0.5 ? "stop" : null} />
        </At>
        {shot === 1 ? (
          <At x={k.x - 4} y={k.y - 60 + press * 6} s={0.33} rot={165}>
            <BigHand skin={M.skin} shade={M.skinShade} sleeve={M.top.color} sleeveShade={M.top.shade} watch pose={{ curl: [0.55, 0, 0.85, 0.9, 0.9] }} />
          </At>
        ) : null}
      </Layer>
    </Shot>
  );
};

// S04-01 — the clock, stopped at 12:17 (over her shoulder)
export const S04_01: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const tight = T(at(21, "मीरा ने कई"));
  const c = STUDY.clock;
  const cam = camAt(lt, [
    [0, { x: 1080, y: 470, z: 1.7 }],
    [tight, { x: c.x - 20, y: c.y + 30, z: 2.6 }],
    [dur, { x: c.x, y: c.y, z: 4.4 }],
  ]);
  return (
    <Shot cam={cam} grade="present">
      <Layer>
        <StudyBack frame={f} clockStart={null} />
        <At x={rec.x} y={rec.y} s={1}>
          <Recorder w={rec.w} frame={f} playing={false} />
        </At>
      </Layer>
      <Layer p={1.35}>
        <Actor spec={M} place={{ x: 880, y: 1320, s: 1.25 }} pose={alive(t, "ots", { stance: "stand", view: "back", headTilt: -12, near: { sh: 4, el: 10 }, far: { sh: -4, el: 10 } })} />
      </Layer>
    </Shot>
  );
};

// S04-02 — Sahajanpur: dye water enters the lower settlement
export const S04_02: React.FC = () => {
  const { f, lt, dur, T } = useBeat();
  const entered = T(at(23, "निचली बस्ती"));
  const flood = kf(lt, [[0, 0.05], [entered + 1, 0.9], [dur, 1]]);
  const cam = camAt(lt, [[0, { x: 700, y: 560, z: 1.05 }], [dur, { x: 1100, y: 640, z: 1.25 }]]);
  return (
    <Shot cam={cam} grade="flood">
      <Layer>
        <Town frame={f} flood={flood} />
      </Layer>
    </Shot>
  );
};

// S04-03 — the siren, the whispering, the inquiry's word
export const S04_03: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const whisper = T(at(23, "लोगों ने कहा"));
  const file = T(at(23, "जाँच में भी"));
  const shot = cutIndex(lt, [whisper - 0.15, file - 0.15]);
  if (shot === 0) {
    const cam = camAt(lt, [[0, { x: 1060, y: 330, z: 1.5 }], [whisper, { x: 1100, y: 310, z: 1.7 }]]);
    return (
      <Shot cam={cam} grade="present">
        <Layer>
          <SirenPole frame={f} />
        </Layer>
      </Shot>
    );
  }
  if (shot === 1) {
    const cam = camAt(lt - whisper, [[0, { x: 980, y: 780, z: 1.6 }], [file - whisper, { x: 980, y: 790, z: 1.75 }]]);
    return (
      <Shot cam={cam} grade="present">
        <Layer>
          <HouseFront frame={f} time="night" rain={0.4} windowLit={0} />
          {[0, 1, 2].map((i) => (
            <Actor
              key={i}
              spec={townsperson(`whisper${i}`)}
              place={{ x: 880 + i * 95, y: 1000, s: 0.5, flip: i === 2 }}
              pose={alive(t, `wh${i}`, { stance: "stand", lean: i === 1 ? 4 : 14, headTilt: 12, near: { sh: i === 0 ? 70 : 10, el: i === 0 ? 90 : 20, hand: "open" }, far: { sh: -6, el: 10 } })}
              silhouette="#0d1120"
            />
          ))}
        </Layer>
      </Shot>
    );
  }
  const cam = camAt(lt - file, [[0, { x: 960, y: 560, z: 1.0 }], [dur - file, { x: 880, y: 590, z: 1.5 }]]);
  return (
    <Shot cam={cam} grade="present">
      <Layer>
        <InquiryFile circle={ramp(lt, file + 0.6, file + 2)} />
      </Layer>
    </Shot>
  );
};

// S04-04 — incomplete memory: a lone figure returning through the rain, backlit
export const S04_04: React.FC = () => {
  const { f, t, lt, dur } = useBeat();
  const k = Math.min(1, lt / Math.max(1, dur));
  const x = 1640 - k * 420;
  const s = 0.42 + k * 0.4;
  const cam = camAt(lt, [[0, { x: 1300, y: 560, z: 1.1 }], [dur, { x: 1240, y: 600, z: 1.2 }]]);
  return (
    <Shot cam={cam} grade="flood" memoryEdge={0.6}>
      <Layer>
        <FloodLane frame={f} water={0.25} light={1.6} />
        <Actor spec={dineshYoung} place={{ x, y: 900 + k * 120, s, flip: true }} pose={walkPose(t, "lone", lt * 0.85, { headTilt: 20 })} silhouette="#03040a" />
        <Water frame={f} y={900 + k * 120 - 30 * s} dye={0.6} seed="loneW" opacity={0.55} />
      </Layer>
    </Shot>
  );
};

// S05-02 — rainy bazaar; Kabir's shop where it always was
export const S05_02: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const coversAt = T(at(29, "अब शीशे"));
  const x = 200 + lt * 105;
  const cam = camAt(lt, [
    [0, { x: 600, y: 560, z: 1.15 }],
    [coversAt, { x: 900, y: 560, z: 1.2 }],
    [dur, { x: 1010, y: 560, z: 1.9 }],
  ]);
  return (
    <Shot cam={cam} grade="present">
      <Layer>
        <Bazaar frame={f} />
        <Actor spec={meeraRain} place={{ x: Math.min(x, 860), y: 960, s: 0.85 }} pose={x < 860 ? walkPose(t, "bz", lt * 0.48, { headTilt: 6 }) : alive(t, "bzStop", { stance: "stand", headTilt: -4, gazeX: 0.8, near: { sh: 6, el: 16 }, far: { sh: -6, el: 14 } })} />
      </Layer>
    </Shot>
  );
};

// S05-06 — inside: shutter half down, the cassette between them (wordless; lines
// 31–41 are not read in the recording). His silence; his father's photograph.
export const S05_06: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const photoAt = T(at(43, "उसके पिता भी"));
  const meeraAt = T(at(43, "मीरा को अचानक"));
  const shot = cutIndex(lt, [Math.min(1.8, photoAt - 1.2), photoAt - 0.1, meeraAt - 0.1]) - 1;
  const cam =
    shot === -1
      ? camAt(lt, [[0, SC.wide], [2, { ...SC.wide, z: 1.08 }]])
      : shot === 0
      ? SC.kabir
      : shot === 1
        ? camAt(lt - photoAt, [[0, { x: SHOP.photo.x, y: SHOP.photo.y, z: 4.4 }], [meeraAt - photoAt, { x: SHOP.photo.x, y: SHOP.photo.y, z: 4.9 }]])
        : camAt(lt - meeraAt, [[0, SC.meera], [dur, SC.meeraTight]]);
  return (
    <ShopShot
      cam={cam}
      s={{
        f,
        t,
        shutter: 1,
        tea: "hot",
        cassette: "counter",
        meera: { expr: shot === 2 ? "sad" : "listen", gazeX: 0.3, gazeY: 0.6, headTilt: 14 },
        kabir: { expr: "pressed", gazeX: 0.2, gazeY: 0.9, headTilt: 16 },
      }}
    />
  );
};

// S06-01 — second deck; the laptop; waveform rises
export const S06_01: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const laptopAt = T(at(45, "मीरा ने उसे"));
  const waveAt = T(at(45, "कुछ देर बाद"));
  const shot = cutIndex(lt, [laptopAt - 0.1, waveAt - 0.1]);
  const reveal = ramp(lt, waveAt, waveAt + 2.2);
  const cam = shot === 0 ? camAt(lt, [[0, SC.two], [laptopAt, { ...SC.two, x: 960 }]]) : shot === 1 ? SC.meera : SC.screen;
  return (
    <ShopShot
      cam={cam}
      s={{
        f,
        t,
        shutter: 1,
        tea: "hot",
        deck: true,
        cassette: "deck",
        laptop: shot > 0,
        screen: shot === 2 ? { t0: para(49).start, t1: para(49).start + 40 * reveal + 0.1 } : undefined,
        kabirHands: shot === 0 ? "deck" : "counter",
        meera: { expr: "tense", gazeX: 0.9, gazeY: 0.5 },
      }}
    />
  );
};

// S06-02 — the full confession in her headphones
export const S06_02: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const nameAt = T(at(49, "आठ मिनट बहुत"));
  const shot = cutIndex(lt, [2.4, nameAt - 0.3]);
  const p = para(49);
  const cam = shot === 0 ? SC.screen : shot === 1 ? camAt(lt - 2.4, [[0, SC.meera], [nameAt, SC.meeraTight]]) : SC.meeraTight;
  const look = ramp(lt, nameAt + 0.6, nameAt + 1.2);
  return (
    <ShopShot
      cam={cam}
      s={{
        f,
        t,
        shutter: 1,
        tea: "hot",
        deck: true,
        cassette: "deck",
        playing: true,
        laptop: true,
        headphones: "on",
        screen: { t0: p.start, t1: p.end, playhead: Math.max(0, Math.min(1, (t - p.start) / (p.end - p.start))) },
        meera: { expr: look > 0.5 ? "grief" : "listen", gazeX: 0.5 - look * 0.6, gazeY: 0.4 - look * 0.6, headTilt: 10 - look * 8 },
      }}
    />
  );
};

// S06-03 — (his words) his old hand on the clock face at 12:17; the hands stay put
export const S06_03: React.FC = () => {
  const { f, lt, dur } = useBeat();
  const c = STUDY.clock;
  const touch = kf(lt, [[0.3, 0], [1.6, 1], [dur - 1.2, 1], [dur - 0.2, 0]]);
  return (
    <Shot cam={camAt(lt, [[0, { x: c.x, y: c.y + 10, z: 4.2 }], [dur, { x: c.x, y: c.y + 10, z: 4.6 }]])} grade="memoryWarm" memoryEdge={0.6}>
      <Layer>
        <StudyBack frame={f} clockStart={null} />
        <At x={c.x + 70 - (1 - touch) * 60} y={c.y + 110 + (1 - touch) * 50} s={0.32} rot={-20}>
          <BigHand skin={dineshOld.skin} shade={dineshOld.skinShade} sleeve={dineshOld.top.color} sleeveShade={dineshOld.top.shade} pose={{ curl: [0.3, 0.05, 0.6, 0.7, 0.75] }} />
        </At>
      </Layer>
    </Shot>
  );
};

// S06-04 — his cough covers the next sentence
export const S06_04: React.FC = () => {
  const { f, t, lt } = useBeat();
  const shot = cutIndex(lt, [1.4]);
  const p = para(53);
  return (
    <ShopShot
      cam={shot === 0 ? SC.screen : SC.meera}
      s={{
        f,
        t,
        shutter: 1,
        tea: "hot",
        deck: true,
        cassette: "deck",
        playing: true,
        laptop: true,
        headphones: "on",
        screen: { t0: p.start - 4, t1: p.end + 2, playhead: 0.66, mark: [0.6, 0.78] },
        meera: { expr: "pressed", gazeY: 0.6, headTilt: 12 },
      }}
    />
  );
};

// S06-05 — the other side; «बस इसे मेरे साथ मत जला देना»
export const S06_05: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const hidden = T(at(55, "मैंने इसे छिपाया।"));
  const burn = T(at(55, "बस इसे"));
  const shot = cutIndex(lt, [hidden - 0.1, burn - 0.4]);
  const p = para(55);
  const closeEyes = ramp(lt, burn + 0.6, burn + 1.4);
  return (
    <ShopShot
      cam={shot === 0 ? SC.meera : shot === 1 ? SC.deck : camAt(lt - burn, [[0, SC.meeraTight], [6, { ...SC.meeraTight, z: 3.6 }]])}
      s={{
        f,
        t,
        shutter: 1,
        tea: "hot",
        deck: true,
        cassette: "deck",
        playing: true,
        laptop: true,
        headphones: "on",
        screen: { t0: p.start, t1: p.end, playhead: Math.max(0, Math.min(1, (t - p.start) / (p.end - p.start))) },
        meera: { expr: { browInner: 0.8, browY: 0.05, lid: 0.15 + closeEyes * 0.85, lower: 0.1, mouth: -0.5, open: 0, tears: closeEyes * 0.6 }, gazeY: 0.5, headTilt: 10 + closeEyes * 6 },
      }}
    />
  );
};

// S06-06 — silence; a chair scrapes; «दूसरी तरफ़ चलाएँ?» — she nods
export const S06_06: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const ask = T(at(59, "दूसरी तरफ़"));
  const nodAt = T(at(61));
  const nod = Math.max(0, Math.sin(Math.max(0, Math.min(1, (lt - nodAt - 0.2) / 0.8)) * Math.PI * 2)) * 10;
  const shot = cutIndex(lt, [ask - 0.2, nodAt - 0.1]);
  return (
    <ShopShot
      cam={shot === 0 ? SC.two : shot === 1 ? SC.kabir : SC.meera}
      s={{
        f,
        t,
        shutter: 1,
        tea: "hot",
        deck: true,
        cassette: "deck",
        laptop: true,
        headphones: "neck",
        screen: { t0: para(57).start - 8, t1: para(57).end, playhead: 0.97 },
        kabir: { talk: speaks(t, 59, "दूसरी तरफ़", "चलाएँ?”"), expr: "soft", gazeX: 0.8, lean: shot === 0 ? 4 + ramp(lt, 0.8, 1.4) * 8 : 10 },
        meera: { expr: "pressed", headTilt: 8 + nod, gazeY: 0.5 },
      }}
    />
  );
};

/** Announcement room on the flood night with young Dinesh at the microphone. */
const RoomNight: React.FC<{ f: number; t: number; cam: { x: number; y: number; z: number }; talk?: number; turn?: number; figure?: number; sirenOn?: number; hand?: "mic" | "switch" | "plead"; figureRaise?: number; switchPull?: number; memoryEdge?: number }> = ({
  f,
  t,
  cam,
  talk = 0,
  turn = 0,
  figure = 0,
  sirenOn = 1,
  hand = "mic",
  figureRaise = 0,
  memoryEdge = 0.5,
}) => {
  const place = { x: 870, y: ROOM.floorY, s: 0.95, flip: turn > 0.5 };
  const base: Pose = alive(t, "dinMic", { stance: "stand", lean: turn > 0.5 ? 4 : 14, headTilt: turn > 0.5 ? 2 : 10, gazeX: 0.8, gazeY: turn > 0.5 ? 0 : 0.5, expr: turn > 0.5 ? "fear" : "tense", talk });
  const pose: Pose = {
    ...base,
    near:
      hand === "switch"
        ? reachW(dineshYoung, base, "near", { x: ROOM.switch.x, y: ROOM.switch.y - 30 }, place, "grip", 0)
        : hand === "plead"
          ? { sh: 60, el: 50, hand: "open" }
          : reachW(dineshYoung, base, "near", { x: ROOM.mic.x + 30, y: ROOM.mic.y - 140 }, place, "grip", 20),
    far: hand === "plead" ? { sh: 50, el: 60, hand: "open" } : reachW(dineshYoung, base, "far", { x: 1000, y: ROOM.deskTop - 4 }, place, "relaxed", 40),
  };
  return (
    <Shot cam={cam} grade="flood" memoryEdge={memoryEdge}>
      <Layer>
        <AnnouncementRoom frame={f} era="flood" sirenOn={sirenOn} />
        {figure > 0 ? (
          <Actor
            spec={vikramNight}
            place={{ x: 1740, y: ROOM.floorY, s: 0.98, flip: true }}
            pose={{ stance: "stand", lean: 2, near: { sh: 20 + figureRaise * 60, el: 30, hand: "point" }, far: { sh: 4, el: 30, hand: "fist" } }}
            silhouette="#06080f"
            opacity={figure}
          />
        ) : null}
        <Actor spec={dineshYoung} place={place} pose={pose} />
      </Layer>
    </Shot>
  );
};

// S07-01 — side B: hiss, then the young voice at the microphone
export const S07_01: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const young = T(at(63, "फिर पिता"));
  const shot = cutIndex(lt, [young - 0.2]);
  if (shot === 0) {
    const p = para(63);
    return (
      <ShopShot
        cam={camAt(lt, [[0, SC.deck], [young, { ...SC.deck, z: 5.4 }]])}
        s={{ f, t, shutter: 1, tea: "hot", deck: true, cassette: "deck", playing: lt > 0.5, playFrom: f - Math.round(lt * 24) + 12, laptop: true, headphones: "on", kabirHands: lt < 0.6 ? "deck" : "counter", screen: { t0: p.start, t1: p.end + 6, playhead: 0.1 } }}
      />
    );
  }
  const talk = speaks(t, 65);
  const cam = camAt(lt - young, [[0, { x: 900, y: 560, z: 1.6 }], [dur - young, { x: 900, y: 540, z: 1.9 }]]);
  return <RoomNight f={f} t={t} cam={cam} talk={talk} />;
};

// S07-02 — a faceless figure orders the mic off
export const S07_02: React.FC = () => {
  const { f, t, lt, dur } = useBeat();
  const turn = ramp(lt, 0.8, 1.3);
  return <RoomNight f={f} t={t} cam={camAt(lt, [[0, { x: 1150, y: 560, z: 1.15 }], [dur, { x: 1200, y: 560, z: 1.25 }]])} turn={turn} figure={ramp(lt, 0, 0.6)} figureRaise={ramp(lt, 0.4, 1.0)} hand="plead" />;
};

// S07-03 — Meera hears the flat, irritated voice
export const S07_03: React.FC = () => {
  const { f, t } = useBeat();
  return <ShopShot cam={SC.meeraTight} s={{ f, t, shutter: 1, tea: "hot", deck: true, cassette: "deck", playing: true, laptop: true, headphones: "on", meera: { expr: "tense", gazeY: 0.4 } }} />;
};

// S07-04 — «पानी बढ़ रहा है, साहब।» / the order, the excuse
export const S07_04: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const reply = T(at(73));
  const shot = cutIndex(lt, [reply - 0.1]);
  if (shot === 0) return <RoomNight f={f} t={t} cam={{ x: 980, y: 470, z: 2.4 }} turn={1} figure={1} hand="plead" talk={speaks(t, 71)} />;
  return <RoomNight f={f} t={t} cam={camAt(lt - reply, [[0, { x: 1450, y: 520, z: 1.5 }], [dur - reply, { x: 1500, y: 520, z: 1.6 }]])} turn={1} figure={1} figureRaise={1} hand="plead" />;
};

// S07-05 — his own hand pulls the siren lever down
export const S07_05: React.FC = () => {
  const { f, lt, dur } = useBeat();
  const pull = ramp(lt, 0.5, 0.75);
  const sw = ROOM.switch;
  return (
    <Shot cam={camAt(lt, [[0, { x: sw.x, y: sw.y - 20, z: 4.2 }], [dur, { x: sw.x, y: sw.y - 10, z: 4.6 }]])} grade="flood" memoryEdge={0.5}>
      <Layer>
        <AnnouncementRoom frame={f} era="flood" sirenOn={1 - pull} />
        <At x={sw.x + 10} y={sw.y - 120 + pull * 110} s={0.3} rot={200}>
          <BigHand skin={dineshYoung.skin} shade={dineshYoung.skinShade} sleeve="#bfcfdf" sleeveShade="#9fb4c9" watch pose={{ curl: [0.6, 0.75, 0.8, 0.85, 0.85] }} />
        </At>
      </Layer>
    </Shot>
  );
};

// S07-06 — rain swallows the words; she presses the headphones closer
export const S07_06: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const woman = T(at(77, "किसी औरत"));
  const shot = cutIndex(lt, [T(at(77, "मीरा ने हेडफ़ोन")) - 0.1, woman - 0.1]);
  const p = para(77);
  return (
    <ShopShot
      cam={shot === 0 ? SC.screen : shot === 1 ? SC.meera : SC.meeraTight}
      s={{
        f,
        t,
        shutter: 1,
        tea: "hot",
        deck: true,
        cassette: "deck",
        playing: true,
        laptop: true,
        headphones: "on",
        meeraHands: shot >= 1 ? "ears" : "counter",
        screen: { t0: p.start - 6, t1: p.end, playhead: 0.5, mark: [0.3, 0.9] },
        meera: { expr: shot === 2 ? "shock" : "tense", gazeY: 0.3 },
      }}
    />
  );
};

// S07-07 — through the rain, a woman seen from behind calls toward the office
export const S07_07: React.FC = () => {
  const { f, t, lt, dur } = useBeat();
  return (
    <Shot cam={camAt(lt, [[0, { x: 960, y: 600, z: 1.2 }], [dur, { x: 960, y: 620, z: 1.3 }]])} grade="flood" memoryEdge={0.6}>
      <Layer>
        <SchoolGate frame={f} time="night" chain="locked" water={0.35} rain={1.2} />
        <Actor spec={mother} place={{ x: 760, y: 1060, s: 1.05 }} pose={alive(t, "momBack", { stance: "stand", view: "back", headTilt: -4, near: { sh: 140, el: 20, hand: "open" }, far: { sh: -10, el: 20 } })} />
        <Water frame={f} y={1000 - 0.35 * 200} dye={0.8} seed="gateWater2" opacity={0.7} />
      </Layer>
    </Shot>
  );
};

// S07-08 — both hands grip the table; «माँ।»
export const S07_08: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const maa = T(at(83));
  const shot = cutIndex(lt, [maa - 0.15]);
  if (shot === 0) {
    const grip = ramp(lt, 0.1, 0.5);
    return (
      <Shot cam={{ x: 960, y: 560, z: 1 }} grade="present" bg="#2a2520">
        <Layer>
          <rect x={-200} y={-200} width={2400} height={1500} fill="#2b2a35" />
          <rect x={-200} y={600} width={2400} height={80} fill="#5a3f2c" stroke={C.ink} strokeWidth={3} />
          <rect x={-200} y={680} width={2400} height={600} fill="#4a3324" />
          {[620, 1300].map((x, i) => (
            <At key={x} x={x} y={760 - grip * 40} s={1.3} rot={i ? 8 : -8}>
              <g transform={i ? "scale(-1 1)" : undefined}>
                <BigHand skin={M.skin} shade={M.skinShade} sleeve={M.top.color} sleeveShade={M.top.shade} watch={!i} pose={{ curl: [0.5, 0.3 + grip * 0.5, 0.3 + grip * 0.55, 0.35 + grip * 0.55, 0.4 + grip * 0.5], spread: 0.1 }} />
              </g>
            </At>
          ))}
        </Layer>
      </Shot>
    );
  }
  return <ShopShot cam={camAt(lt - maa, [[0, SC.meeraTight], [4, { ...SC.meeraTight, z: 3.6 }]])} s={{ f, t, shutter: 1, tea: "hot", deck: true, cassette: "deck", playing: true, laptop: true, headphones: "on", meeraHands: "grip", meera: { expr: "crying", gazeY: 0.2, headTilt: 4 } }} />;
};

// S07-09 — soft fragments of her mother: bangles, a profile, alive and hurried
export const S07_09: React.FC = () => {
  const { lt, dur, t } = useBeat();
  const shot = cutIndex(lt, [dur * 0.45]);
  return (
    <Shot cam={camAt(lt, [[0, { x: 960, y: 540, z: 1 }], [dur, { x: 960, y: 540, z: 1.12 }]])} grade="memoryWarm" memoryEdge={0.85}>
      <Layer>
        <rect x={-200} y={-200} width={2400} height={1500} fill="#6b5a48" />
        <circle cx={1300} cy={300} r={500} fill="#e8c08a" opacity={0.35} />
        {shot === 0 ? (
          <At x={900} y={1300} s={1.6} rot={-20}>
            <BigHand skin={mother.skin} shade={mother.skinShade} sleeve={mother.top.color} sleeveShade={mother.top.shade} bangles="#3f7a5a" pose={{ curl: [0.2, 0.15, 0.2, 0.25, 0.3], spread: 0.3 }} />
          </At>
        ) : (
          <At x={1220} y={640} s={4.6}>
            <Head spec={mother} pose={alive(t, "momSoft", { stance: "stand", expr: "soft", headTurn: 0.6, gazeX: 0.9, headTilt: -4 })} />
          </At>
        )}
      </Layer>
    </Shot>
  );
};

// S07-10 — «बस करो» — Kabir stops the tape at once
export const S07_10: React.FC = () => {
  const { f, t, lt, T } = useBeat();
  const stop = T(at(89));
  const shot = cutIndex(lt, [stop - 0.1]);
  if (shot === 0) return <ShopShot cam={SC.meeraTight} s={{ f, t, shutter: 1, tea: "hot", deck: true, cassette: "deck", playing: true, laptop: true, headphones: "on", meera: { expr: "crying", talk: speaks(t, 87, "बस करो", "करो,”"), gazeY: 0.5 } }} />;
  const press = ramp(lt, stop, stop + 0.15);
  const d = SHOP_PLACES.deck;
  const k = { x: d.x - d.w * 0.02 + 4 * d.w * 0.078 + d.w * 0.034, y: d.y - d.w * 0.55 + 4 };
  return (
    <Shot cam={{ x: k.x, y: k.y + 20, z: 5.5 }} grade="present">
      <Layer>
        <ShopInteriorDeckOnly f={f} playing={press < 0.5} />
        <At x={k.x + 6} y={k.y - 56 + press * 6} s={0.33} rot={190}>
          <BigHand skin={kabir.skin} shade={kabir.skinShade} sleeve={kabir.top.color} sleeveShade={kabir.top.shade} pose={{ curl: [0.55, 0, 0.85, 0.9, 0.9] }} />
        </At>
      </Layer>
    </Shot>
  );
};

const ShopInteriorDeckOnly: React.FC<{ f: number; playing: boolean }> = ({ f, playing }) => (
  <ShopStage s={{ f, t: 0, shutter: 1, tea: "hot", deck: true, cassette: "deck", playing, laptop: true, hideKabir: true }} />
);

// S08-01 — a long time; cold tea; a child's bicycle bell outside
export const S08_01: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const bell = T(at(91, "दुकान के बाहर"));
  const ride = ramp(lt, bell - 0.6, bell + 2.2, (x) => x);
  return (
    <Shot cam={camAt(lt, [[0, { x: 760, y: 560, z: 1.15 }], [dur, { x: 740, y: 570, z: 1.25 }]])} grade="present">
      <Layer>
        <ShopStage s={{ f, t, shutter: 1, tea: "cold", deck: true, cassette: "deck", laptop: true, headphones: "neck", meeraHands: "lap", meera: { expr: "grief", gazeY: 0.8, headTilt: 18 }, kabir: { expr: "sad", gazeY: 0.7 } }} />
        {ride > 0 && ride < 1 ? (
          <g transform={`translate(${-60 + ride * 540} ${SHOP.front.bottom - 70})`} opacity={0.9}>
            <circle cx={-40} cy={40} r={28} fill="none" stroke="#05070e" strokeWidth={5} />
            <circle cx={40} cy={40} r={28} fill="none" stroke="#05070e" strokeWidth={5} />
            <path d="M -40 40 L 0 0 L 40 40 M 0 0 L 30 -8" stroke="#05070e" strokeWidth={5} fill="none" />
            <At x={0} y={10} s={0.42}>
              <Person spec={anshu} pose={{ stance: "sit", near: { sh: 80, el: 10 }, far: { sh: 80, el: 10 } }} silhouette="#05070e" />
            </At>
          </g>
        ) : null}
      </Layer>
    </Shot>
  );
};

// S08-02 — Anshu's face; the flood night; «दीदी, तू हाथ तो नहीं छोड़ेगी?»
export const S08_02: React.FC = () => {
  const { f, t, lt, dur, T } = useBeat();
  const night = T(at(91, "फिर उसका")) ;
  const shot = cutIndex(lt, [Math.max(1.2, night - 0.1), T(at(93)) - 0.1]);
  if (shot === 0) {
    return (
      <Shot cam={{ x: 960, y: 540, z: 1 }} grade="memoryWarm" memoryEdge={0.8}>
        <Layer>
          <rect x={-200} y={-200} width={2400} height={1500} fill="#8a6a4f" />
          <circle cx={700} cy={300} r={600} fill="#f3c779" opacity={0.3} />
          <At x={980} y={560} s={5.2}>
            <Head spec={anshu} pose={alive(t, "anshuFace", { stance: "stand", expr: "soft", gazeX: 0.2 })} />
          </At>
        </Layer>
      </Shot>
    );
  }
  const place = { x: 800, y: 1040, s: 1.25 };
  const aPlace = { x: 1080, y: 1040, s: 1.25, flip: true };
  const mBase: Pose = alive(t, "kidM", { stance: "stand", headTilt: 6, gazeX: 0.6, gazeY: 0.4, expr: "fear" });
  const aBase: Pose = alive(t, "kidA", { stance: "stand", headTilt: -8, gazeX: 0.7, gazeY: -0.6, expr: "fear", talk: speaks(t, 93) });
  const handPt = { x: 950, y: 820 };
  return (
    <Shot cam={camAt(lt, [[0, { x: 940, y: 700, z: 1.7 }], [dur, { x: 940, y: 690, z: 1.85 }]])} grade="flood" memoryEdge={0.6}>
      <Layer>
        <FloodLane frame={f} water={0.45} />
        <Actor spec={meeraChild} place={place} pose={{ ...mBase, near: reachW(meeraChild, mBase, "near", handPt, place, "grip", 0) }} />
        <Actor spec={anshu} place={aPlace} pose={{ ...aBase, near: reachW(anshu, aBase, "near", handPt, aPlace, "grip", 0) }} />
        <Water frame={f} y={1000 - 0.45 * 260} dye={0.75} seed="kidW" opacity={0.75} />
      </Layer>
    </Shot>
  );
};

// S08-03 — the first push of water; the hands come apart; her hand is empty
export const S08_03: React.FC = () => {
  const { f, lt, dur, T } = useBeat();
  const fell = T(at(95, "पानी का पहला"));
  const empty = T(at(95, "उठी तो"));
  const shot = cutIndex(lt, [empty - 0.1]);
  const apart = ramp(lt, fell + 0.6, fell + 1.6);
  if (shot === 0) {
    return (
      <Shot cam={{ x: 960, y: 560, z: 1 }} grade="flood" memoryEdge={0.6}>
        <Layer>
          <rect x={-200} y={-200} width={2400} height={1500} fill="#0b1020" />
          <Water frame={f} y={620 - apart * 60} dye={0.75} seed="handsW" />
          <At x={820 - apart * 180} y={560 + apart * 40} s={0.9} rot={70 + apart * 20}>
            <BigHand skin={meeraChild.skin} shade={meeraChild.skinShade} sleeve={meeraChild.top.color} pose={{ curl: [0.5, 0.6 - apart * 0.4, 0.65 - apart * 0.4, 0.7 - apart * 0.4, 0.7 - apart * 0.3] }} />
          </At>
          <At x={1100 + apart * 260} y={560 + apart * 120} s={0.75} rot={-110 - apart * 30}>
            <BigHand skin={anshu.skin} shade={anshu.skinShade} sleeve={anshu.top.color} pose={{ curl: [0.5, 0.7, 0.7, 0.75, 0.75] }} />
          </At>
          <Water frame={f + 10} y={680 - apart * 40} dye={0.75} seed="handsW2" opacity={0.6} />
        </Layer>
      </Shot>
    );
  }
  const rise = ramp(lt, empty, empty + 1.4);
  return (
    <Shot cam={camAt(lt - empty, [[0, { x: 960, y: 560, z: 1 }], [dur - empty, { x: 960, y: 540, z: 1.1 }]])} grade="flood" memoryEdge={0.6}>
      <Layer>
        <rect x={-200} y={-200} width={2400} height={1500} fill="#0b1020" />
        <At x={960} y={900 - rise * 260} s={1.1} rot={180}>
          <BigHand skin={meeraChild.skin} shade={meeraChild.skinShade} sleeve={meeraChild.top.color} pose={{ curl: [0.15, 0.1, 0.1, 0.15, 0.2], spread: 0.5 }} />
        </At>
        <Water frame={f} y={700} dye={0.75} seed="emptyW" opacity={0.85} />
      </Layer>
    </Shot>
  );
};

