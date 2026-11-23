import type { Caption } from "@remotion/captions";
import { ALIGN } from "../timing/time";

export type HindiCue = Caption & { lines: string[]; status: "aligned" | "provisional" };

const MAX_LINE = 42;
const MAX_CUE = 78;
const SENTENCE_END = /[।?!]["”]?$|\.\.\.["”]?$/;

const splitLines = (text: string): string[] => {
  if (text.length <= MAX_LINE) return [text];
  const words = text.split(" ");
  let best = 1;
  let bestDiff = Infinity;
  for (let i = 1; i < words.length; i++) {
    const a = words.slice(0, i).join(" ").length;
    const diff = Math.abs(a - (text.length - a));
    if (diff < bestDiff) {
      bestDiff = diff;
      best = i;
    }
  }
  return [words.slice(0, best).join(" "), words.slice(best).join(" ")];
};

/**
 * Hindi caption cues built from the manuscript words (never from the transcript
 * text). Breaks only between words, so grapheme clusters are never split.
 */
export const buildCues = (): HindiCue[] => {
  const cues: HindiCue[] = [];
  for (const p of ALIGN.paragraphs) {
    // captions show only what the recording actually says
    const words = ALIGN.words.slice(p.firstWord, p.firstWord + p.wordCount).filter((w) => !w.omitted);
    let cur: typeof words = [];
    const flush = () => {
      if (!cur.length) return;
      const text = cur.map((w) => w.text).join(" ");
      const conf = Math.min(...cur.map((w) => w.conf));
      cues.push({
        text,
        lines: splitLines(text),
        startMs: Math.round(cur[0].start * 1000),
        endMs: Math.round(cur[cur.length - 1].end * 1000),
        timestampMs: Math.round(cur[0].start * 1000),
        confidence: conf,
        status: ALIGN.status === "aligned" && conf >= 0.5 ? "aligned" : "provisional",
      });
      cur = [];
    };
    for (const w of words) {
      const next = [...cur, w].map((x) => x.text).join(" ");
      if (cur.length && next.length > MAX_CUE) flush();
      cur.push(w);
      const len = cur.map((x) => x.text).join(" ").length;
      if (SENTENCE_END.test(w.text) && len > 18) flush();
    }
    flush();
  }
  // extend each cue slightly for readability, never overlapping the next
  for (let i = 0; i < cues.length; i++) {
    const nextStart = i + 1 < cues.length ? cues[i + 1].startMs : Infinity;
    const minEnd = cues[i].startMs + 1000;
    cues[i].endMs = Math.min(Math.max(cues[i].endMs + 250, minEnd), nextStart - 40);
  }
  return cues;
};

const ts = (ms: number, sep: "," | ".") => {
  const h = Math.floor(ms / 3600000);
  const m = Math.floor((ms % 3600000) / 60000);
  const s = Math.floor((ms % 60000) / 1000);
  const r = ms % 1000;
  const p = (n: number, l = 2) => String(n).padStart(l, "0");
  return `${p(h)}:${p(m)}:${p(s)}${sep}${p(r, 3)}`;
};

/** offsetMs = picture head handle, so cues line up with the film (not the bare MP3). */
export const toSrt = (cues: HindiCue[], offsetMs: number) =>
  cues.map((c, i) => `${i + 1}\n${ts(c.startMs + offsetMs, ",")} --> ${ts(c.endMs + offsetMs, ",")}\n${c.lines.join("\n")}\n`).join("\n");

export const toVtt = (cues: HindiCue[], offsetMs: number) =>
  "WEBVTT\n\n" + cues.map((c, i) => `${i + 1}\n${ts(c.startMs + offsetMs, ".")} --> ${ts(c.endMs + offsetMs, ".")}\n${c.lines.join("\n")}\n`).join("\n");
