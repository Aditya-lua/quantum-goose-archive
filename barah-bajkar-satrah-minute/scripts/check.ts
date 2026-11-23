// Project checks: scene coverage, timeline continuity, asset references, the
// stopped-clock rule, single narration mount, and the alignment drift report.
// Usage: npx tsx scripts/check.ts      (exit code 1 on any failure)
import { execFileSync, spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { STORYBOARD } from "../src/data/storyboard";
import { TIMELINE } from "../src/data/timeline";
import { ALIGN, at, FILM_FRAMES, FPS, HEAD, nf, NARRATION_DURATION, TAIL, wordIndex } from "../src/timing/time";
import { clockAngles, STOPPED_HOUR_DEG, STOPPED_MINUTE_DEG, STOPPED_SECOND_DEG } from "../src/props/Clock";

const ROOT = path.resolve(__dirname, "..");
const errors: string[] = [];
const warn: string[] = [];
const fail = (m: string) => errors.push(m);

// 1. every beat has a scene component (exported as Sxx_yy)
const sceneSrc = fs.readdirSync(path.join(ROOT, "src/scenes")).filter((f) => /^s\d\d_s\d\d\.tsx$/.test(f)).map((f) => fs.readFileSync(path.join(ROOT, "src/scenes", f), "utf8")).join("\n");
const exported = new Set([...sceneSrc.matchAll(/export const (S\d\d_\d\d)\b/g)].map((m) => m[1].replace("_", "-")));
for (const b of STORYBOARD) if (!exported.has(b.id)) fail(`beat ${b.id} has no scene component`);
const ids = new Set<string>();
for (const b of STORYBOARD) {
  if (ids.has(b.id)) fail(`duplicate beat id ${b.id}`);
  ids.add(b.id);
}

// anchors must be words the recording actually contains
for (const b of STORYBOARD) {
  if (b.line === 0) continue;
  if (ALIGN.words[wordIndex(b.line, b.anchor)].omitted) fail(`beat ${b.id} is anchored on manuscript text that the recording does not read (L${b.line})`);
}

// 2. timeline continuity
if (TIMELINE[0].from !== 0) fail(`first beat starts at frame ${TIMELINE[0].from}`);
for (let i = 0; i < TIMELINE.length; i++) {
  const b = TIMELINE[i];
  if (b.to <= b.from) fail(`beat ${b.id} has non-positive length (${b.from}..${b.to})`);
  if (i + 1 < TIMELINE.length && b.to !== TIMELINE[i + 1].from) fail(`gap/overlap between ${b.id} and ${TIMELINE[i + 1].id}`);
  if ((b.to - b.from) / FPS < 1.0) warn.push(`beat ${b.id} is short: ${((b.to - b.from) / FPS).toFixed(2)} s`);
  if (i > 0 && STORYBOARD[i].line < STORYBOARD[i - 1].line) fail(`beat ${b.id} anchor line goes backwards`);
}
const last = TIMELINE[TIMELINE.length - 1];
if (last.to !== FILM_FRAMES) fail(`last beat ends at ${last.to}, film has ${FILM_FRAMES} frames`);
const expected = Math.ceil((HEAD + NARRATION_DURATION + TAIL) * FPS);
if (FILM_FRAMES !== expected) fail(`FILM_FRAMES ${FILM_FRAMES} != ${expected}`);

// 3. paragraph coverage: every manuscript paragraph falls inside the beat timeline
const lines = ALIGN.paragraphs.filter((p) => !p.omitted).map((p) => p.line);
const beatLines = STORYBOARD.filter((b) => b.line > 0).map((b) => b.line);
for (const ln of lines) if (ln < beatLines[0]) fail(`paragraph line ${ln} precedes the first beat`);
const perBeat = new Map<string, number[]>();
for (const ln of lines) {
  let owner = STORYBOARD[0].id;
  for (const b of STORYBOARD) if (b.line > 0 && b.line <= ln) owner = b.id;
  perBeat.set(owner, [...(perBeat.get(owner) ?? []), ln]);
}
const coveredLines = [...perBeat.values()].flat().length;
if (coveredLines !== lines.length) fail(`only ${coveredLines}/${lines.length} spoken paragraphs covered`);

// 4. asset references
const allSrc = execFileSync("grep", ["-rhoE", 'staticFile\\("[^"]+"\\)', path.join(ROOT, "src")]).toString().trim().split("\n");
for (const ref of new Set(allSrc)) {
  const p = ref.slice(12, -2);
  if (!fs.existsSync(path.join(ROOT, "public", p))) fail(`missing asset public/${p}`);
}
const sfxSrc = fs.readFileSync(path.join(ROOT, "src/audio/sfx.ts"), "utf8");
for (const m of sfxSrc.matchAll(/file: "([^"]+)"/g)) if (!fs.existsSync(path.join(ROOT, "public/audio/sfx", m[1]))) fail(`missing sfx public/audio/sfx/${m[1]}`);

// 5. narration mounted exactly once
const narrationRefs = execFileSync("grep", ["-rc", "audio/narration.mp3", path.join(ROOT, "src")]).toString().trim().split("\n").reduce((a, l) => a + Number(l.split(":").pop()), 0);
if (narrationRefs !== 1) fail(`narration referenced ${narrationRefs} times in src (expected exactly 1)`);

// 6. the clock rule
const clockStart = nf(at(319, "सेकंड की सुई"));
const s2202 = TIMELINE.find((b) => b.id === "S22-02")!;
if (clockStart < s2202.from || clockStart >= s2202.to) fail(`clock start frame ${clockStart} is outside beat S22-02`);
for (let f = 0; f < clockStart; f += 97) {
  const a = clockAngles(f, clockStart);
  if (a.h !== STOPPED_HOUR_DEG || a.m !== STOPPED_MINUTE_DEG || a.s !== STOPPED_SECOND_DEG) fail(`clock moves at frame ${f}`);
}
const moved = clockAngles(clockStart + 2 * FPS, clockStart);
if (moved.s === STOPPED_SECOND_DEG) fail("clock does not run after the battery moment");
if (STOPPED_MINUTE_DEG !== 102 || STOPPED_HOUR_DEG !== 8.5) fail("stopped clock angles are not 12:17");
for (const m of sceneSrc.matchAll(/(clockStart|startFrame)=\{([^}]+)\}/g)) {
  const v = m[2].trim();
  if (!["null", "start", "CLOCK_START()", "clockStart"].includes(v)) fail(`unexpected clock start expression: ${m[0]}`);
}

// 7. drift report at the checkpoints
const pauses = (() => {
  const log = spawnSync("ffmpeg", ["-hide_banner", "-nostats", "-i", path.join(ROOT, "public/audio/narration.mp3"), "-af", "silencedetect=noise=-38dB:d=0.3", "-f", "null", "-"], { encoding: "utf8" }).stderr;
  return [...log.matchAll(/silence_end: ([\d.]+)/g)].map((m) => Number(m[1]));
})();
const pausesFromStderr = pauses.length ? pauses : [];
const CHECKPOINTS: [string, number, string | undefined][] = [
  ["opening: the recorder plays (L1/L3 not read)", 5, "बटन दबाते ही"],
  ["the full confession (side A)", 49, undefined],
  ["first appearance of the mother's voice", 79, undefined],
  ["recovered rescue instruction", 169, undefined],
  ["Vikram's offer", 227, undefined],
  ["memorial confession", 279, undefined],
  ["battery / clock restart", 319, "सेकंड की सुई"],
  ["family tape", 325, undefined],
];
const report: string[] = [];
for (const [name, line, phrase] of CHECKPOINTS) {
  const t = at(line, phrase);
  const w = ALIGN.words[wordIndex(line, phrase)];
  const near = pausesFromStderr.length ? pausesFromStderr.reduce((a, b) => (Math.abs(b - t) < Math.abs(a - t) ? b : a)) : NaN;
  report.push(`| ${name} | L${line} | ${t.toFixed(2)} s | ${(HEAD + t).toFixed(2)} s | ${w.conf.toFixed(2)} | ${Number.isNaN(near) ? "n/a" : (t - near).toFixed(2) + " s"} |`);
}

const md = [
  "# Timing report (generated by `npm run check`)",
  "",
  `- Alignment source: ${ALIGN.source} (status: ${ALIGN.status})`,
  `- Narration: ${NARRATION_DURATION.toFixed(3)} s; head handle ${HEAD} s; tail handle ${TAIL} s`,
  `- Film: ${FILM_FRAMES} frames at ${FPS} fps = ${(FILM_FRAMES / FPS).toFixed(3)} s`,
  `- Manuscript paragraphs not read in the recording: ${ALIGN.paragraphs.filter((p) => p.omitted).map((p) => "L" + p.line).join(", ") || "none"}`,
  `- Title spoken: ${ALIGN.title ? `${ALIGN.title.start.toFixed(2)}–${ALIGN.title.end.toFixed(2)} s (shown once, as the S00 title card)` : "not detected"}`,
  `- Clock restart frame: ${clockStart} (${(clockStart / FPS).toFixed(2)} s film time)`,
  `- Beats: ${TIMELINE.length}; aligned-anchor beats: ${TIMELINE.filter((b) => b.status === "aligned").length}; provisional-anchor beats: ${TIMELINE.filter((b) => b.status !== "aligned").map((b) => b.id).join(", ") || "none"}`,
  "",
  "## Drift checkpoints",
  "",
  "| Checkpoint | Line | Narration time | Film time | Word confidence | Offset from nearest pause end |",
  "|---|---|---|---|---|---|",
  ...report,
  "",
  "## Warnings",
  "",
  ...(warn.length ? warn.map((w) => `- ${w}`) : ["- none"]),
  "",
];
fs.writeFileSync(path.join(ROOT, "docs/TIMING.md"), md.join("\n"));
console.log(md.join("\n"));
if (errors.length) {
  console.error("\nFAILED:\n" + errors.map((e) => " - " + e).join("\n"));
  process.exit(1);
}
console.log("\nAll checks passed.");
