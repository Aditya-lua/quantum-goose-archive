// Exports optional Hindi captions from the manuscript text + aligned word times.
// SRT/VTT are offset by the 0.5 s picture head so they line up with the film MP4.
// Usage: npx tsx scripts/export-captions.ts
import fs from "node:fs";
import path from "node:path";
import { buildCues, toSrt, toVtt } from "../src/captions/build";
import { ALIGN, HEAD } from "../src/timing/time";

const ROOT = path.resolve(__dirname, "..");
const cues = buildCues();
const off = Math.round(HEAD * 1000);
fs.mkdirSync(path.join(ROOT, "deliverables/captions"), { recursive: true });
fs.mkdirSync(path.join(ROOT, "public/captions"), { recursive: true });
fs.writeFileSync(path.join(ROOT, "public/captions/hi.json"), JSON.stringify(cues.map(({ lines: _l, status: _s, ...c }) => c), null, 1));
fs.writeFileSync(path.join(ROOT, "deliverables/captions/barah-bajkar-satrah-minute.hi.srt"), toSrt(cues, off));
fs.writeFileSync(path.join(ROOT, "deliverables/captions/barah-bajkar-satrah-minute.hi.vtt"), toVtt(cues, off));
const prov = cues.filter((c) => c.status !== "aligned").length;
console.log(`${cues.length} cues (${prov} contain interpolated word times); alignment: ${ALIGN.source}`);
