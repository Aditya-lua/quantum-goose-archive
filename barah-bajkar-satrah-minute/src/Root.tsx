import React from "react";
import { AbsoluteFill, Composition, Still } from "remotion";
import { z } from "zod";
import { CharacterSheet } from "./sheets/CharacterSheet";
import { Film } from "./Film";
import { FILM_FRAMES, FPS } from "./timing/time";
import { beatById } from "./data/timeline";
import "./style/fonts";

const filmSchema = z.object({ showCaptions: z.boolean() });

/** Renders the 1920x1080 film tree into any output size (used for the 720p draft). */
const Scaled: React.FC<{ width: number; showCaptions: boolean; range?: [number, number] }> = ({ width, showCaptions, range }) => {
  const k = width / 1920;
  return (
    <AbsoluteFill style={{ overflow: "hidden", backgroundColor: "#000" }}>
      <div style={{ width: 1920, height: 1080, transform: `scale(${k})`, transformOrigin: "0 0", position: "absolute" }}>
        <Film showCaptions={showCaptions} range={range} />
      </div>
    </AbsoluteFill>
  );
};

const PILOT_END = beatById("S02-03").to;

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="Film"
        component={(p: z.infer<typeof filmSchema>) => <Film showCaptions={p.showCaptions} />}
        schema={filmSchema}
        defaultProps={{ showCaptions: false }}
        durationInFrames={FILM_FRAMES}
        fps={FPS}
        width={1920}
        height={1080}
        calculateMetadata={() => ({ durationInFrames: FILM_FRAMES, defaultOutName: "barah-bajkar-satrah-minute" })}
      />
      <Composition
        id="FilmDraft"
        component={(p: z.infer<typeof filmSchema>) => <Scaled width={1280} showCaptions={p.showCaptions} />}
        schema={filmSchema}
        defaultProps={{ showCaptions: false }}
        durationInFrames={FILM_FRAMES}
        fps={FPS}
        width={1280}
        height={720}
      />
      <Composition
        id="Pilot"
        component={(p: z.infer<typeof filmSchema>) => <Film showCaptions={p.showCaptions} range={[0, PILOT_END]} />}
        schema={filmSchema}
        defaultProps={{ showCaptions: false }}
        durationInFrames={PILOT_END}
        fps={FPS}
        width={1920}
        height={1080}
      />
      <Still id="CharacterSheet" component={CharacterSheet} width={1920} height={1080} />
    </>
  );
};
