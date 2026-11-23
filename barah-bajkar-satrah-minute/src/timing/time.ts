import alignment from "./alignment.json";
import envelope from "./envelope.json";

export type AlignedWord = {
  p: number; // paragraph index (0-based, order of non-empty manuscript lines)
  text: string;
  start: number; // seconds in the narration file
  end: number;
  conf: number; // 0..1 match confidence; interpolated words get 0
  omitted?: boolean; // manuscript word not read in this recording
};

export type AlignedParagraph = {
  line: number; // 1-based line number in source-text/Barah_Bajkar_Satrah_Minute_Hindi.txt
  text: string;
  start: number;
  end: number;
  firstWord: number;
  wordCount: number;
  omitted?: boolean;
};

export type Alignment = {
  source: string;
  status: "aligned" | "provisional";
  narrationDuration: number;
  title: { start: number; end: number } | null;
  paragraphs: AlignedParagraph[];
  words: AlignedWord[];
};

export const ALIGN = alignment as Alignment;

export const FPS = 24;
/** Intentional picture handle before the narration starts (seconds). */
export const HEAD = 0.5;
/** Intentional picture handle after the narration ends (seconds). */
export const TAIL = 3.0;
export const NARRATION_DURATION = ALIGN.narrationDuration;
export const FILM_SECONDS = HEAD + NARRATION_DURATION + TAIL;
export const FILM_FRAMES = Math.ceil(FILM_SECONDS * FPS);
/** Frame at which the narration audio starts. */
export const NARRATION_FROM = Math.round(HEAD * FPS);

/** Narration time (s) -> absolute film frame. The only sec->frame conversion for story time. */
export const nf = (narrationSec: number): number =>
  Math.round((HEAD + narrationSec) * FPS);

/** Absolute film frame -> narration time (s). */
export const fn = (frame: number): number => frame / FPS - HEAD;

const normalize = (s: string): string =>
  s
    .normalize("NFC")
    .replace(/़/g, "") // nukta
    .replace(/[“”"‘’'.,!?।…\-–—:;()]/g, "")
    .trim();

const paraByLine = new Map<number, AlignedParagraph>(
  ALIGN.paragraphs.map((p) => [p.line, p]),
);

export const para = (line: number): AlignedParagraph => {
  const p = paraByLine.get(line);
  if (!p) throw new Error(`No manuscript paragraph at line ${line}`);
  return p;
};

/** Index of the first word of `phrase` inside paragraph `line` (or the paragraph start). */
export const wordIndex = (line: number, phrase?: string): number => {
  const p = para(line);
  if (!phrase) return p.firstWord;
  const target = phrase.split(/\s+/).map(normalize).filter(Boolean);
  for (let i = 0; i <= p.wordCount - target.length; i++) {
    let ok = true;
    for (let k = 0; k < target.length; k++) {
      if (normalize(ALIGN.words[p.firstWord + i + k].text) !== target[k]) {
        ok = false;
        break;
      }
    }
    if (ok) return p.firstWord + i;
  }
  throw new Error(`Phrase "${phrase}" not found in line ${line}`);
};

/** Narration seconds where `phrase` starts in paragraph `line`. */
export const at = (line: number, phrase?: string): number =>
  ALIGN.words[wordIndex(line, phrase)].start;

/** Narration seconds where `phrase` ends in paragraph `line` (or the paragraph end). */
export const endOf = (line: number, phrase?: string): number => {
  if (!phrase) return para(line).end;
  const i = wordIndex(line, phrase);
  const n = phrase.split(/\s+/).filter((w) => normalize(w)).length;
  return ALIGN.words[i + n - 1].end;
};

const ENV = envelope as number[];

/** Narration loudness 0..1 at narration time t (24 fps resolution). */
export const env = (t: number): number => {
  const i = Math.round(t * FPS);
  if (i < 0 || i >= ENV.length) return 0;
  return ENV[i] / 100;
};

/** Envelope slice for waveform displays: n samples over [t0, t1]. */
export const envSlice = (t0: number, t1: number, n: number): number[] => {
  const out: number[] = [];
  for (let k = 0; k < n; k++) out.push(env(t0 + ((t1 - t0) * k) / n));
  return out;
};
