// Sparse SFX cue list, derived from the same timeline as the picture so every
// sound stays locked to its beat/word. The narration export contains no effects
// or ambience (see docs/SOUND.md), so nothing here doubles an existing sound.
import { beatById } from "../data/timeline";
import { at, FILM_FRAMES, FPS, nf } from "../timing/time";

export type SfxCue = {
  id: string;
  file: string; // in public/audio/sfx/
  from: number; // absolute film frame
  frames: number;
  gain: number; // linear, relative to narration at 1.0
  fadeIn: number;
  fadeOut: number;
  loop: boolean;
};

const sec = (s: number) => Math.round(s * FPS);
const one = (id: string, file: string, from: number, gain: number, lenS = 0.7): SfxCue => ({ id, file, from, frames: sec(lenS), gain, fadeIn: 0, fadeOut: 2, loop: false });

const cues = (): SfxCue[] => {
  const b = beatById;
  const clockStart = nf(at(319, "सेकंड की सुई"));
  const list: SfxCue[] = [
    // rain outside the house: title through the first scene, until the hospital memory
    { id: "rain-house", file: "rain_bed.wav", from: 0, frames: b("S02-01").from + 12, gain: 0.05, fadeIn: sec(1.5), fadeOut: sec(1.2), loop: true },
    // rain in the bazaar and outside Kabir's shop
    { id: "rain-bazaar", file: "rain_bed.wav", from: b("S05-02").from, frames: b("S07-01").from + sec(1.5) - b("S05-02").from, gain: 0.04, fadeIn: sec(1), fadeOut: sec(1.5), loop: true },
    // tape keys and mechanisms
    one("play-S01", "tape_key.wav", b("S01-02").from + sec(0.5), 0.22),
    one("stop-S01", "tape_stop.wav", b("S01-04").from + sec(0.35), 0.2),
    one("play-S03", "tape_key.wav", b("S03-03").from + sec(0.35), 0.2),
    one("stop-S03", "tape_key.wav", nf(at(19, "मीरा ने बटन")) - sec(0.05), 0.2),
    one("play-S07", "tape_key.wav", b("S07-01").from + sec(0.45), 0.2),
    one("stop-S07", "tape_key.wav", nf(at(89)) - sec(0.15) + sec(0.1), 0.24),
    one("siren-switch", "switch_clunk.wav", b("S07-05").from + sec(0.62), 0.22, 0.8),
    one("play-S22", "tape_key.wav", nf(at(323)) - sec(0.1) + sec(0.4), 0.2),
    // the clock runs only from the battery moment: one tick per second-hand step
    { id: "clock", file: "clock_tick_loop.wav", from: clockStart + Math.round(0.45 * FPS), frames: FILM_FRAMES - clockStart - Math.round(0.45 * FPS), gain: 0.07, fadeIn: 0, fadeOut: sec(2.5), loop: true },
  ];
  return list.filter((c) => c.frames > 0);
};

export const SFX_CUES: SfxCue[] = cues();
