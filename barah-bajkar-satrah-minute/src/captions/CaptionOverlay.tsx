import React, { useMemo } from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { FONT_BODY } from "../style/fonts";
import { fn } from "../timing/time";
import { buildCues } from "./build";

/** Optional Hindi captions (off by default; toggled with the showCaptions prop). */
export const CaptionOverlay: React.FC = () => {
  const cues = useMemo(() => buildCues(), []);
  const t = fn(useCurrentFrame()) * 1000;
  const cue = cues.find((c) => t >= c.startMs && t < c.endMs);
  if (!cue) return null;
  return (
    <AbsoluteFill style={{ justifyContent: "flex-end", alignItems: "center", paddingBottom: 70 }}>
      <div
        style={{
          fontFamily: FONT_BODY,
          fontSize: 44,
          lineHeight: 1.45,
          color: "#f6f1e6",
          textAlign: "center",
          background: "rgba(8,10,18,0.62)",
          padding: "8px 26px 12px",
          borderRadius: 8,
          maxWidth: 1500,
        }}
      >
        {cue.lines.map((l, i) => (
          <div key={i}>{l}</div>
        ))}
      </div>
    </AbsoluteFill>
  );
};
