import React from "react";
import { At, Layer } from "../engine/Stage";
import { Shot } from "../engine/beat";
import type { Cam } from "../engine/Stage";
import { SHOP, ShopInterior } from "../sets/Shop";
import { Chair } from "../sets/Study";
import { Cassette, Laptop, Recorder, TeaGlass, Waveform } from "../props/Props";
import { kabir, meeraAdult } from "../rigs/characters";
import type { Pose } from "../rigs/types";
import { envSlice } from "../timing/time";
import { Actor, alive, reachW, type Place } from "./common";

// Shared staging for every shop beat (fixed geography): Meera on a chair at the
// counter's left end facing right; Kabir standing behind the counter facing left.
export const SHOP_PLACES = {
  meera: { x: 560, y: SHOP.floorY, s: 0.95 } as Place,
  kabir: { x: 1150, y: SHOP.floorY, s: 0.95, flip: true } as Place,
  tea: { x: 820, y: SHOP.counterTop },
  cassette: { x: 905, y: SHOP.counterTop },
  laptop: { x: 1010, y: SHOP.counterTop, w: 220 },
  deck: { x: 1260, y: SHOP.counterTop, w: 150 },
};

export const SHOP_CAMS = {
  wide: { x: 960, y: 560, z: 1.0 } as Cam,
  two: { x: 870, y: 590, z: 1.5 } as Cam,
  meera: { x: 720, y: 590, z: 2.4 } as Cam,
  meeraTight: { x: 660, y: 545, z: 3.3 } as Cam,
  kabir: { x: 1110, y: 500, z: 2.5 } as Cam,
  screen: { x: 1010, y: 690, z: 4.2 } as Cam,
  deck: { x: 1260, y: 700, z: 5 } as Cam,
};

export type ShopState = {
  f: number;
  t: number;
  meera?: Partial<Pose>;
  kabir?: Partial<Pose>;
  meeraHands?: "counter" | "lap" | "grip" | "ears";
  kabirHands?: "counter" | "deck" | "cassette" | "side";
  shutter?: number;
  tea?: "hot" | "cold" | "none";
  cassette?: "counter" | "deck" | "none";
  laptop?: boolean;
  deck?: boolean;
  playing?: boolean;
  playFrom?: number;
  screen?: { t0: number; t1: number; playhead?: number; mark?: [number, number] };
  headphones?: "on" | "neck";
  hideKabir?: boolean;
  rain?: number;
};

const M = meeraAdult;
const K = kabir;

export const ShopStage: React.FC<{ s: ShopState }> = ({ s }) => {
  const P = SHOP_PLACES;
  const mBase: Pose = alive(s.t, "meeraShop", { stance: "sit", lean: 8, headTilt: 6, gazeX: 0.6, gazeY: 0.3, expr: "listen", ...s.meera });
  const hands = s.meeraHands ?? "counter";
  const mPose: Pose = {
    ...mBase,
    near:
      hands === "lap"
        ? { sh: 30, el: 60, hand: "relaxed" }
        : hands === "ears"
          ? { sh: 150, el: 95, hand: "open" }
          : reachW(M, mBase, "near", { x: hands === "grip" ? 786 : 800, y: SHOP.counterTop - 4 }, P.meera, hands === "grip" ? "grip" : "relaxed", hands === "grip" ? 70 : 60),
    far:
      hands === "grip"
        ? reachW(M, mBase, "far", { x: 830, y: SHOP.counterTop - 2 }, P.meera, "grip", 70)
        : hands === "ears"
          ? { sh: 150, el: 100, hand: "open" }
          : { sh: 34, el: 62, hand: "relaxed" },
    ...(s.meera?.near ? { near: s.meera.near } : {}),
    ...(s.meera?.far ? { far: s.meera.far } : {}),
  };
  const kBase: Pose = alive(s.t, "kabirShop", { stance: "stand", lean: 10, headTilt: 8, gazeX: 0.5, gazeY: 0.4, expr: "listen", ...s.kabir });
  const kh = s.kabirHands ?? "counter";
  const kTarget = kh === "deck" ? { x: P.deck.x + 18, y: P.deck.y - P.deck.w * 0.55 + 6 } : kh === "cassette" ? { x: 990, y: SHOP.counterTop - 60 } : { x: 1060, y: SHOP.counterTop - 4 };
  const kPose: Pose = {
    ...kBase,
    near: kh === "side" ? { sh: 6, el: 14 } : reachW(K, kBase, "near", kTarget, P.kabir, kh === "deck" ? "point" : kh === "cassette" ? "hold" : "relaxed", 50),
    far: kh === "side" ? { sh: -4, el: 10 } : reachW(K, kBase, "far", { x: 1110, y: SHOP.counterTop - 4 }, P.kabir, "relaxed", 50),
    ...(s.kabir?.near ? { near: s.kabir.near } : {}),
    ...(s.kabir?.far ? { far: s.kabir.far } : {}),
  };
  const env = s.screen ? envSlice(s.screen.t0, s.screen.t1, 90) : [];
  return (
    <g>
      <ShopInterior frame={s.f} shutter={s.shutter ?? 0} rain={s.rain ?? 1} layer="back" />
      {!s.hideKabir ? <Actor spec={K} place={P.kabir} pose={kPose} /> : null}
      <ShopInterior frame={s.f} shutter={s.shutter ?? 0} rain={s.rain ?? 1} layer="front" />
      {s.tea !== "none" ? (
        <At x={P.tea.x} y={P.tea.y} s={1}>
          <TeaGlass s={0.9} steam={s.tea === "cold" ? 0 : 1} frame={s.f} />
        </At>
      ) : null}
      {s.cassette === "counter" ? (
        <At x={P.cassette.x} y={P.cassette.y - 8} s={1} rot={-8}>
          <g transform="scale(1 0.5)">
            <Cassette w={80} />
          </g>
        </At>
      ) : null}
      {s.laptop ? (
        <At x={P.laptop.x} y={P.laptop.y} s={1}>
          <Laptop
            w={P.laptop.w}
            screen={
              s.screen ? (
                <g transform="translate(8 14)">
                  <Waveform w={P.laptop.w * 0.9 - 16} h={P.laptop.w * 0.54 - 28} env={env} playhead={s.screen.playhead} mark={s.screen.mark} />
                </g>
              ) : null
            }
          />
        </At>
      ) : null}
      {s.deck ? (
        <At x={P.deck.x} y={P.deck.y} s={1}>
          <Recorder w={P.deck.w} frame={s.f} playing={!!s.playing} playFrom={s.playFrom ?? 0} silver cassetteIn={s.cassette === "deck"} />
        </At>
      ) : null}
      <At x={P.meera.x - 40} y={P.meera.y} s={0.95}>
        <Chair />
      </At>
      <Actor spec={M} place={P.meera} pose={mPose} headphones={s.headphones} />
    </g>
  );
};

export const ShopShot: React.FC<{ cam: Cam; s: ShopState; grade?: "present" }> = ({ cam, s }) => (
  <Shot cam={cam} grade="present">
    <Layer>
      <ShopStage s={s} />
    </Layer>
  </Shot>
);
