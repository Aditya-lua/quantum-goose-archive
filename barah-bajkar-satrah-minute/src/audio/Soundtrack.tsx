import React from "react";
import { Audio } from "@remotion/media";
import { interpolate, Sequence, staticFile } from "remotion";
import { FILM_FRAMES, NARRATION_FROM } from "../timing/time";
import { monotonic } from "../engine/anim";
import { SFX_CUES } from "./sfx";

/**
 * Master narration: mounted exactly once, starting at NARRATION_FROM (the 0.5 s
 * head handle) and never re-mounted per scene. SFX cues sit underneath it.
 */
export const Soundtrack: React.FC = () => {
  return (
    <>
      <Sequence from={NARRATION_FROM} durationInFrames={FILM_FRAMES - NARRATION_FROM} name="narration" layout="none">
        <Audio src={staticFile("audio/narration.mp3")} volume={1} />
      </Sequence>
      {SFX_CUES.map((c) => (
        <Sequence key={c.id} from={c.from} durationInFrames={c.frames} name={`sfx ${c.id}`} layout="none">
          <Audio
            src={staticFile(`audio/sfx/${c.file}`)}
            loop={c.loop}
            volume={(f) =>
              c.gain *
              interpolate(f, monotonic([0, c.fadeIn, c.frames - c.fadeOut, c.frames]), [c.fadeIn ? 0 : 1, 1, 1, 0], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
              })
            }
          />
        </Sequence>
      ))}
    </>
  );
};
