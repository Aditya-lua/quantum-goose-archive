# Asset inventory

Everything the film uses lives in this folder, referenced by project-relative paths (`public/` via `staticFile()`). The render makes no remote requests.

## Inputs (supplied)
| File | Origin | Notes |
|---|---|---|
| `public/audio/narration.mp3` | The user's ElevenLabs narration (uploaded as `ElevenLabs_____________________.mp3`) | 1249.254 s, mono 44.1 kHz. SHA-256 in `source-text/SHA256SUMS`. Unmodified. |
| `source-text/Barah_Bajkar_Satrah_Minute_Hindi.txt` | The user's manuscript | 2,927 words, 167 paragraphs. The text authority. |
| `source-text/Barah_Bajkar_Satrah_Minute.epub` | The user's EPUB | Same text plus the title heading. |
| (embedded cover in the MP3) | ElevenLabs export | Used only as a composition and palette reference (window left, clock right, cassette on desk). Not used in the film. |

## Generated in this project
| Path | Made by | Purpose |
|---|---|---|
| `public/fonts/*.woff2` | Copied from `@fontsource/noto-sans-devanagari` and `@fontsource/tiro-devanagari-hindi` (OFL; licences beside them) | Devanagari text, title, captions |
| `public/textures/paper.png`, `memory-edge.png` | `scripts/make-textures.py` (deterministic) | Paper grain overlay; soft paper-edge vignette for memories |
| `public/audio/sfx/*.wav` | `scripts/synth-sfx.py` (deterministic) | Rain bed, tape keys, siren switch, clock tick (see `docs/SOUND.md`) |
| `src/timing/alignment.json` | `scripts/align.py` | Manuscript words with narration times |
| `src/timing/envelope.json` | `scripts/envelope.py` | Per-frame narration loudness (mouths and waveform displays) |
| `public/captions/hi.json`, `deliverables/captions/*.srt/.vtt` | `scripts/export-captions.ts` | Optional Hindi captions |

## Artwork (all original SVG, drawn in code)
| Kind | Where |
|---|---|
| Character rigs and age variants | `src/rigs/characters.ts`, `Head.tsx`, `Person.tsx`, `BigHand.tsx` (insert hands), `crowd.ts` (townspeople) |
| Locations | `src/sets/Study.tsx` (study, chairs), `House.tsx` (house front, height mark), `Hospital.tsx`, `Shop.tsx` (Kabir's shop, bazaar, Delhi studio), `Factory.tsx` (town, siren pole, inquiry file, factory gate, posters, announcement room, school gate, flood lane, water), `Places.tsx` (Vikram's office and market model, memorial yard and stone, roadside, newspaper, statement desk, files table) |
| Props | `src/props/Clock.tsx` (wall clock and clock back; stopped-time rule), `src/props/Props.tsx` (cassette, recorder or deck, laptop and waveform, headphones, handkerchief, paper or letter, diary, ID card, keys, padlock, whistle, phone, tea glass, microphone, siren switch) |
| Effects | `src/fx/fx.tsx` (rain, glass drops, grades, glow) |

No stock images, 3D models or remote assets are used. No image-generation service was available, so all artwork is the SVG fallback described in the brief.
