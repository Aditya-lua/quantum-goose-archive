// Writes docs/STORYBOARD.md from src/data/storyboard.ts + the aligned timeline.
// Usage: npx tsx scripts/storyboard-doc.ts
import fs from "node:fs";
import path from "node:path";
import { TIMELINE } from "../src/data/timeline";
import { ALIGN, FPS, para, wordIndex } from "../src/timing/time";

const ROOT = path.resolve(__dirname, "..");
const fmt = (s: number) => {
  const t = Math.max(0, s);
  return `${Math.floor(t / 60)}:${(t % 60).toFixed(1).padStart(4, "0")}`;
};
const anchorText = (line: number, anchor?: string) => {
  if (line === 0) return "(spoken title)";
  const i = wordIndex(line, anchor);
  const p = para(line);
  return ALIGN.words.slice(i, Math.min(i + 6, p.firstWord + p.wordCount)).map((w) => w.text).join(" ");
};

const rows = TIMELINE.map(
  (b) =>
    `| ${b.id} | ${fmt(b.from / FPS)}–${fmt(b.to / FPS)} | L${b.line} «${anchorText(b.line, b.anchor)}» | ${b.location} | ${b.period} | ${b.chars.join(", ") || "—"} | ${b.action} | ${b.framing} | ${b.transition} | ${b.props.join(", ") || "—"} | ${b.audio.join("; ") || "narration"} | ${b.status}${b.status === "aligned" ? "" : ` (conf ${b.anchorConf.toFixed(2)})`} |`,
);
const md = [
  "# Storyboard — बारह बजकर सत्रह मिनट",
  "",
  "Generated from `src/data/storyboard.ts` and the aligned timeline (`npx tsx scripts/storyboard-doc.ts`).",
  "Times are film time (0.5 s head handle before the narration). Anchor = first words of the beat in the manuscript",
  "(L = line in `source-text/Barah_Bajkar_Satrah_Minute_Hindi.txt`). Timing status: `aligned` = anchor word matched in",
  "the ASR timing evidence; `provisional` = anchor time interpolated between matched neighbours.",
  "",
  `Beats: ${TIMELINE.length}. Alignment: ${ALIGN.source}.`,
  "",
  "| ID | Film time | Anchor | Location | Period | Characters | Action | Framing | Transition | Props | Audio | Timing |",
  "|---|---|---|---|---|---|---|---|---|---|---|---|",
  ...rows,
  "",
];
fs.writeFileSync(path.join(ROOT, "docs/STORYBOARD.md"), md.join("\n"));
console.log(`wrote docs/STORYBOARD.md (${TIMELINE.length} beats)`);
