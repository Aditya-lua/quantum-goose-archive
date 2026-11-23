#!/usr/bin/env bash
# Resumable chunked render of the full film (1920x1080, 24 fps, H.264 yuv420p + AAC).
#  1. bundle once
#  2. render the picture in absolute frame-range chunks (muted); finished chunks are kept
#  3. render the mixed soundtrack (narration + SFX) once, as WAV
#  4. concatenate chunks without re-encoding, mux the soundtrack once
#  5. verify frame count, durations and streams
# Env: CHUNK (frames, default 3000), CONCURRENCY (default 4), OUT (default out/barah-bajkar-satrah-minute.mp4)
set -euo pipefail
cd "$(dirname "$0")/.."

CHUNK="${CHUNK:-3000}"
CONCURRENCY="${CONCURRENCY:-4}"
OUT="${OUT:-out/barah-bajkar-satrah-minute.mp4}"
WORK=out/final
mkdir -p "$WORK/chunks"

TOTAL=$(npx tsx -e 'import { FILM_FRAMES } from "./src/timing/time"; console.log(FILM_FRAMES)')
echo "Film: $TOTAL frames ($(echo "scale=3; $TOTAL/24" | bc) s)"

if [ ! -f "$WORK/bundle/index.html" ] || [ "${REBUNDLE:-0}" = "1" ]; then
  rm -rf "$WORK/bundle"
  npx remotion bundle --out-dir="$WORK/bundle" --log=error
fi

frames_of() { ffprobe -v error -select_streams v:0 -count_packets -show_entries stream=nb_read_packets -of csv=p=0 "$1" 2>/dev/null || echo 0; }

i=0
: > "$WORK/list.txt"
for ((a = 0; a < TOTAL; a += CHUNK)); do
  b=$((a + CHUNK - 1)); ((b >= TOTAL)) && b=$((TOTAL - 1))
  f=$(printf "%s/chunks/c%03d.mp4" "$WORK" "$i")
  want=$((b - a + 1))
  if [ -f "$f" ] && [ "$(frames_of "$f")" = "$want" ]; then
    echo "chunk $i ($a-$b) already rendered"
  else
    echo "rendering chunk $i: frames $a-$b"
    npx remotion render "$WORK/bundle" Film "$f" --frames="$a-$b" --muted --codec=h264 --pixel-format=yuv420p --crf=18 \
      --concurrency="$CONCURRENCY" --image-format=jpeg --jpeg-quality=95 --log=error
    got=$(frames_of "$f")
    [ "$got" = "$want" ] || { echo "chunk $i has $got frames, expected $want" >&2; exit 1; }
  fi
  echo "file '$(realpath "$f")'" >> "$WORK/list.txt"
  i=$((i + 1))
done

if [ ! -f "$WORK/soundtrack.wav" ] || [ "${REAUDIO:-0}" = "1" ]; then
  echo "rendering soundtrack"
  npx remotion render "$WORK/bundle" Film "$WORK/soundtrack.wav" --codec=wav --concurrency="$CONCURRENCY" --log=error
fi

ffmpeg -v error -y -f concat -safe 0 -i "$WORK/list.txt" -c copy "$WORK/picture.mp4"
ffmpeg -v error -y -i "$WORK/picture.mp4" -i "$WORK/soundtrack.wav" -map 0:v:0 -map 1:a:0 \
  -c:v copy -c:a aac -b:a 192k -ar 48000 -movflags +faststart "$OUT"

echo "--- verification"
VF=$(frames_of "$OUT")
VD=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of csv=p=0 "$OUT")
AD=$(ffprobe -v error -select_streams a:0 -show_entries stream=duration -of csv=p=0 "$OUT")
ffprobe -v error -show_entries stream=codec_name,width,height,pix_fmt,r_frame_rate,sample_rate,channels -of compact "$OUT"
echo "video frames: $VF (expected $TOTAL); video duration: $VD s; audio duration: $AD s"
[ "$VF" = "$TOTAL" ] || { echo "FRAME COUNT MISMATCH" >&2; exit 1; }
echo "OK: $OUT"
