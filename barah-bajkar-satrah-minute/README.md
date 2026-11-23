# बारह बजकर सत्रह मिनट

A 2D animated film (about 21 min, Hindi) built with Remotion, React and TypeScript from the supplied manuscript and the ElevenLabs narration. All artwork is original SVG drawn in code: character rigs, sets, props and effects. The narration is the only voice track. Sound effects are sparse and synthesised locally (see `docs/SOUND.md`).

- **Output:** 1920×1080, 24 fps, H.264 (yuv420p) + AAC, no burned-in subtitles.
- **Measured narration:** 1249.254 s. The film adds a 0.5 s picture head and a 3.0 s tail: 30 067 frames = **1252.79 s (20:52.8)**.
- **Pinned toolchain:** Remotion 4.0.546 (exact versions, `package-lock.json`); Node 20.19+ / 22.13+; ffmpeg on PATH for the scripts.

## Setup
```bash
npm ci
```

## Preview
```bash
npm run dev
```
Then open the `Film`, `Pilot`, `FilmDraft` (720p) or `CharacterSheet` composition. `showCaptions` (default `false`) overlays the optional Hindi captions.

## Checks
```bash
npm run check
```
Runs the typecheck plus `scripts/check.ts`:
- every storyboard beat has a scene;
- no gaps or overlaps;
- all manuscript paragraphs covered;
- every `staticFile` asset exists;
- narration mounted exactly once;
- the clock stays stopped at 12:17 until the battery frame.

It also writes the drift report to `docs/TIMING.md`.

## Renders
| What | Command |
|---|---|
| 10-second test (frames 0–239) | `npm run test-render` |
| Pilot (title → end of S02, 1080p) | `npm run pilot` |
| Full draft, 720p, same timing | `npm run draft` |
| Final 1080p, chunked and resumable | `npm run render:final` |

`render:final` (`scripts/render-final.sh`) works in steps:
1. Bundles once.
2. Renders picture-only chunks of 3000 frames using absolute frame ranges. Finished chunks are kept, so a rerun resumes.
3. Renders the soundtrack (narration + SFX) once.
4. Joins the chunks without re-encoding and muxes the soundtrack once.
5. Verifies the frame count and streams.

Output: `out/barah-bajkar-satrah-minute.mp4`. `CHUNK` and `CONCURRENCY` env vars tune it.

## Regenerating data
| Step | Command |
|---|---|
| Transcribe (timing evidence only) | `python3 -m venv work/.venv && work/.venv/bin/pip install faster-whisper` then `work/.venv/bin/python -I scripts/transcribe_fw_clips.py` |
| Align manuscript → narration | `python3 -I scripts/align.py work/transcript.fwclips-large-v3-turbo.json` |
| Check alignment against pauses | `python3 -I scripts/align_check.py` |
| Narration envelope (mouths, waveforms) | `python3 -I scripts/envelope.py` |
| Storyboard doc + captions | `npm run docs` |
| SFX / textures | `python3 -I scripts/synth-sfx.py` / `python3 -I scripts/make-textures.py` |

The manuscript is the text authority. The transcript only supplies timing, and caption text always comes from the manuscript.

## Layout
```
source-text/        manuscript TXT + EPUB, SHA256SUMS
public/             narration, sfx, fonts, textures, captions JSON
src/timing/         time.ts (only sec→frame conversion), alignment.json, envelope.json
src/data/           storyboard.ts (beats), timeline.ts (aligned frame ranges)
src/rigs/           characters, head, person (with IK), insert hands, crowd
src/sets/ src/props/ src/fx/   locations, props (clock rule in props/Clock.tsx), effects
src/scenes/         one component per beat (S00-01 … S22-06)
src/audio/          Soundtrack (narration once + SFX cues)
src/captions/       caption builder + optional overlay
scripts/            alignment, checks, docs, sfx, textures, chunked render
docs/               character bible, storyboard, timing report, sound, assets, checkpoint
deliverables/       pilot, character sheet, contact sheet, captions
```

## Editing
- **Timing:** each beat in `src/data/storyboard.ts` names its manuscript line and anchor words. Scene actions inside a beat are pinned to words with `T(at(line, "words"))`, so a re-alignment moves everything consistently.
- **The clock:** `src/props/Clock.tsx` (`clockAngles`). It is stopped (minute 102°, hour 8.5°, second hand fixed) for every frame before `CLOCK_START`, the aligned frame of «सेकंड की सुई हल्की सी काँपी».
