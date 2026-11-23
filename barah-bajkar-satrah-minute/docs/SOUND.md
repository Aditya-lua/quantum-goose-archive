# Sound

## What the narration already contains
I checked the ElevenLabs export (`public/audio/narration.mp3`, 1249.254 s, mono 44.1 kHz) before adding anything:

- Spectrograms of the whole file and of the final 70 s (`ffmpeg showspectrumpic`) show only speech, with true silence between phrases.
- I found no ambience, rain, clicks, siren, bell, whistle or clock tick.
- A constant hum line at about −100 dBFS is visible in the pauses. It is inaudible and was left alone.

So no effect added below doubles a sound that is already in the recording.

## Mix
- **Narration:** mounted once (`src/audio/Soundtrack.tsx`) from film frame 12 (the 0.5 s head handle) to the end, at unity gain and unprocessed.
- **SFX:** generated deterministically by `scripts/synth-sfx.py` (numpy only, 48 kHz mono WAV in `public/audio/sfx/`). They are placed by `src/audio/sfx.ts` from the same aligned timeline as the picture, and sit 20–30 dB under the narration.

| Cue | File | When | Gain |
|---|---|---|---|
| Rain outside the house | `rain_bed.wav` (24 s loop) | Title → start of the hospital memory (S02-01), fades in and out | 0.05 |
| Rain in the bazaar / shop | `rain_bed.wav` | S05-02 → start of S07-01 | 0.04 |
| Tape keys | `tape_key.wav`, `tape_stop.wav` | Exactly where a key is pressed or released on screen: S01-02, S01-04, S03-03 (play and stop), S07-01, S07-10, S22-03 | 0.2–0.24 |
| Siren switch | `switch_clunk.wav` | S07-05, when the lever is pulled | 0.22 |
| Clock tick | `clock_tick_loop.wav` | Only from the battery moment («सेकंड की सुई हल्की सी काँपी») to the end, in step with the second hand | 0.07 |

Deliberately excluded: no music, no generated speech, and no extra siren, whistle or bell, because the narration describes those sounds and imitating them could distract from it. No effect is processed to sound like an old cassette.
