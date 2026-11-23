// Prints representative frames for beats whose id starts with any given prefix.
// Usage: npx tsx scripts/beat-frames.ts S03 S04 [--pos=0.5]
import { TIMELINE } from "../src/data/timeline";
const args = process.argv.slice(2);
const pos = Number((args.find((a) => a.startsWith("--pos=")) ?? "--pos=0.5").slice(6));
const prefixes = args.filter((a) => !a.startsWith("--"));
const frames = TIMELINE.filter((b) => prefixes.length === 0 || prefixes.some((p) => b.id.startsWith(p))).map((b) => Math.min(b.to - 1, Math.round(b.from + (b.to - b.from) * pos)));
console.log(frames.join(","));
