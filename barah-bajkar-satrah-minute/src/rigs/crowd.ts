import { random } from "remotion";
import { mother, dineshYoung, meeraChild } from "./characters";
import type { CharSpec } from "./types";

const pick = <T,>(arr: readonly T[], seed: string): T => arr[Math.floor(random(seed) * arr.length) % arr.length];

const SKINS = [
  ["#b47a54", "#8b5a3b"],
  ["#9c6a47", "#734b31"],
  ["#c08d68", "#946748"],
  ["#8f603f", "#6a442b"],
  ["#a8734d", "#7e5235"],
] as const;
const CLOTH = ["#6b5a48", "#3f5a3a", "#7a2f3a", "#2f5a6b", "#8a7558", "#5d7aa6", "#a39565", "#4a4e5c", "#c9b994", "#5a3f2c"];

/** Deterministic townsperson (memorial crowd, bazaar). */
export const townsperson = (seed: string): CharSpec => {
  const woman = random(`${seed}-sex`) > 0.5;
  const [skin, skinShade] = pick(SKINS, `${seed}-skin`);
  const c1 = pick(CLOTH, `${seed}-c1`);
  const c2 = pick(CLOTH, `${seed}-c2`);
  const old = random(`${seed}-age`) > 0.7;
  const base = woman ? mother : dineshYoung;
  return {
    ...base,
    id: `town-${seed}`,
    name: "townsperson",
    H: (woman ? 570 : 630) + random(`${seed}-h`) * 40,
    skin,
    skinShade,
    hair: woman ? "mother" : "shortMale",
    hairColor: old ? "#b9b3aa" : "#171210",
    hairShade: old ? "#8a857d" : "#2c2522",
    top: woman
      ? { kind: "sari", color: c1, shade: c1, trim: c2, length: 1 }
      : { kind: random(`${seed}-k`) > 0.5 ? "shirt" : "kurta", color: c1, shade: c1, trim: c2, length: random(`${seed}-k`) > 0.5 ? 0.55 : 0.68 },
    bottom: woman ? { kind: "sari", color: c1, shade: c1 } : { kind: "trousers", color: c2, shade: c2 },
    acc: woman
      ? { bindi: random(`${seed}-b`) > 0.4, pallu: { color: c1, shade: c1, border: c2 }, wrinkles: old ? 0.8 : 0 }
      : { moustache: random(`${seed}-m`) > 0.4 ? (old ? "#b9b3aa" : "#171210") : undefined, wrinkles: old ? 0.8 : 0, glasses: random(`${seed}-g`) > 0.8 },
  };
};

/** The woman who stands up at the memorial (green sari). */
export const sisterWoman: CharSpec = {
  ...townsperson("sister"),
  id: "sisterWoman",
  hair: "mother",
  skin: "#a8734d",
  skinShade: "#7e5235",
  top: { kind: "sari", color: "#3f6a4a", shade: "#2f5038", trim: "#c99a3c", length: 1 },
  bottom: { kind: "sari", color: "#3f6a4a", shade: "#2f5038" },
  acc: { bindi: true, pallu: { color: "#3f6a4a", shade: "#2f5038", border: "#c99a3c" }, wrinkles: 0.4 },
};

/** The man who asks why the inquiry did not record it (checked shirt). */
export const questionMan: CharSpec = {
  ...townsperson("question"),
  id: "questionMan",
  hair: "shortMale",
  hairColor: "#1a1412",
  top: { kind: "shirt", color: "#8a5a4a", shade: "#6c4436", length: 0.55 },
  bottom: { kind: "trousers", color: "#3a3c44", shade: "#2a2c32" },
  acc: { moustache: "#1a1412" },
};

/** Strangers at the roadside (S18): a father and his small daughter. */
export const roadFather: CharSpec = {
  ...dineshYoung,
  id: "roadFather",
  name: "roadside father",
  hair: "shortMale",
  top: { kind: "shirt", color: "#c9b994", shade: "#a8987a", length: 0.55 },
  bottom: { kind: "trousers", color: "#4a4e5c", shade: "#3a3d48" },
  acc: { moustache: "#141010" },
};

export const roadGirl: CharSpec = {
  ...meeraChild,
  id: "roadGirl",
  name: "roadside girl",
  H: 340,
  headFrac: 0.2,
  top: { kind: "frock", color: "#d8a83a", shade: "#b8882a", trim: "#f3eee4", length: 0.72 },
  acc: { ribbons: "#3f6a9a" },
};
