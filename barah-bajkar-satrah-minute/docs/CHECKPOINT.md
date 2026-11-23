# Checkpoint (resume point)

Paths are relative to `barah-bajkar-satrah-minute/`.

## Done
- **Project:** pinned Remotion 4.0.546; local fonts; narration and manuscript in place (`source-text/SHA256SUMS`).
- **Alignment:** `scripts/transcribe_fw_clips.py` (faster-whisper large-v3-turbo, per-pause clips) → `scripts/align.py` → `src/timing/alignment.json`.
  - 152/154 spoken paragraphs start within 0.45 s of a real pause (`scripts/align_check.py`).
  - The recording does not read manuscript lines 1, 3, 7, 9, 11, 27, 31, 33, 35, 37, 39, 41. Each was verified by transcribing the region on its own; the speech is continuous there.
  - Earlier attempts and why they were replaced: whisper.cpp long-form (dropped text, about 1.5 s timestamp skew; 38% of paragraph starts at pauses) and faster-whisper long-form with VAD (skipped whole stretches; 87%).
- **Film:** all 110 beats implemented (`src/scenes/s*_s*.tsx`); storyboard in `src/data/storyboard.ts`; `npm run check` passes.
- **Sound:** sparse SFX (`docs/SOUND.md`); captions exported (`deliverables/captions`).

## Next
1. Pilot render and review; stills or contact sheet.
2. Final chunked render (`npm run render:final`); it resumes if interrupted.
3. ZIP, commit, push and deliver.
