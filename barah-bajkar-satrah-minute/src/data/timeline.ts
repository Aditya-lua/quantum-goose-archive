import { STORYBOARD, type BeatDef } from "./storyboard";
import { ALIGN, at, FILM_FRAMES, HEAD, NARRATION_DURATION, nf, TAIL, wordIndex } from "../timing/time";

/** Lead time: a beat cuts in slightly before its anchor word is spoken. */
export const CUT_LEAD = 0.25;
/** Dissolve overlap in frames. */
export const DISSOLVE_FRAMES = 14;

export type BeatTiming = BeatDef & {
  start: number; // narration seconds (may be negative for the opening handle)
  end: number;
  from: number; // absolute film frame
  to: number; // exclusive
  anchorConf: number;
  status: "aligned" | "provisional";
};

const startOf = (b: BeatDef, i: number): number => {
  if (i === 0) return -HEAD;
  return at(b.line, b.anchor) - CUT_LEAD;
};

export const TIMELINE: BeatTiming[] = STORYBOARD.map((b, i) => {
  const start = startOf(b, i);
  const end = i + 1 < STORYBOARD.length ? startOf(STORYBOARD[i + 1], i + 1) : NARRATION_DURATION + TAIL;
  const conf = i === 0 ? 1 : ALIGN.words[wordIndex(b.line, b.anchor)].conf;
  return {
    ...b,
    start,
    end,
    from: i === 0 ? 0 : nf(start),
    to: i + 1 < STORYBOARD.length ? nf(startOf(STORYBOARD[i + 1], i + 1)) : FILM_FRAMES,
    anchorConf: conf,
    status: ALIGN.status === "aligned" && conf >= 0.5 ? "aligned" : "provisional",
  };
});

export const beatById = (id: string): BeatTiming => {
  const b = TIMELINE.find((x) => x.id === id);
  if (!b) throw new Error(`Unknown beat ${id}`);
  return b;
};
