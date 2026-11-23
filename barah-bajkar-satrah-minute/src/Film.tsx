import React from "react";
import { AbsoluteFill, interpolate, Sequence, useCurrentFrame } from "remotion";
import { BeatCtx } from "./engine/beat";
import { DISSOLVE_FRAMES, TIMELINE } from "./data/timeline";
import { SCENES } from "./scenes";
import { Soundtrack } from "./audio/Soundtrack";
import { CaptionOverlay } from "./captions/CaptionOverlay";

const FadeIn: React.FC<{ frames: number; children: React.ReactNode }> = ({ frames, children }) => {
  const f = useCurrentFrame();
  const o = interpolate(f, [0, frames], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return <AbsoluteFill style={{ opacity: o }}>{children}</AbsoluteFill>;
};

export type FilmProps = { showCaptions: boolean; range?: [number, number] };

/**
 * The whole film. Each storyboard beat is a Sequence at its aligned frame range.
 * A beat followed by a dissolve is extended so the next beat fades in over it.
 * The narration is mounted once, in <Soundtrack>, for the full running time.
 */
export const Film: React.FC<FilmProps> = ({ showCaptions, range }) => {
  return (
    <AbsoluteFill style={{ backgroundColor: "#000" }}>
      {TIMELINE.map((b, i) => {
        if (range && (b.to <= range[0] || b.from >= range[1])) return null;
        const Comp = SCENES[b.id];
        if (!Comp) throw new Error(`No scene component for ${b.id}`);
        const next = TIMELINE[i + 1];
        const extend = next && next.transition === "dissolve" ? DISSOLVE_FRAMES : 0;
        const dur = b.to - b.from + extend;
        // A collapsed beat (bad alignment) is skipped here; `npm run check` fails on it.
        if (b.to - b.from <= 0) return null;
        const fadeIn = b.transition === "dissolve" ? DISSOLVE_FRAMES : b.transition === "fade" ? 18 : 0;
        return (
          <Sequence key={b.id} from={b.from} durationInFrames={dur} name={b.id} premountFor={24}>
            <BeatCtx.Provider value={{ from: b.from, to: b.to, start: b.start, end: b.end }}>
              {fadeIn ? (
                <FadeIn frames={fadeIn}>
                  <Comp />
                </FadeIn>
              ) : (
                <Comp />
              )}
            </BeatCtx.Provider>
          </Sequence>
        );
      })}
      <Soundtrack />
      {showCaptions ? <CaptionOverlay /> : null}
    </AbsoluteFill>
  );
};
