import { loadFont } from "@remotion/fonts";
import { staticFile } from "remotion";

// Fonts are bundled locally (copied from @fontsource packages, OFL licensed) so the
// render never depends on a remote font request.
export const FONT_BODY = "NotoDeva, NotoDevaLatin, sans-serif";
export const FONT_TITLE = "TiroDeva, TiroDevaLatin, serif";

export const fontsReady = Promise.all([
  loadFont({ family: "NotoDeva", url: staticFile("fonts/noto-sans-devanagari-devanagari-400-normal.woff2"), weight: "400" }),
  loadFont({ family: "NotoDeva", url: staticFile("fonts/noto-sans-devanagari-devanagari-600-normal.woff2"), weight: "600" }),
  loadFont({ family: "NotoDevaLatin", url: staticFile("fonts/noto-sans-devanagari-latin-400-normal.woff2"), weight: "400" }),
  loadFont({ family: "NotoDevaLatin", url: staticFile("fonts/noto-sans-devanagari-latin-600-normal.woff2"), weight: "600" }),
  loadFont({ family: "TiroDeva", url: staticFile("fonts/tiro-devanagari-hindi-devanagari-400-normal.woff2"), weight: "400" }),
  loadFont({ family: "TiroDevaLatin", url: staticFile("fonts/tiro-devanagari-hindi-latin-400-normal.woff2"), weight: "400" }),
]);
