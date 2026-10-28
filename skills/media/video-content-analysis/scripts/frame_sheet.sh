#!/usr/bin/env bash
# frame_sheet.sh <video> [outdir] [fps] [tile]
# Samples frames from a video and writes montage sheets for text reading.
# Defaults: outdir under ~/.hermes/cache/scratch, 1 fps, 4x3 tiles.
set -euo pipefail

VIDEO=${1:?usage: frame_sheet.sh <video> [outdir] [fps] [tile]}
BASE=$(basename "${VIDEO%.*}")
OUT=${2:-$HOME/.hermes/cache/scratch/frames_$BASE}
FPS=${3:-1}
TILE=${4:-4x3}

mkdir -p "$OUT"
ffprobe -v error -show_entries format=duration -of csv=p=0 "$VIDEO" > "$OUT/duration.txt"

# Full frames (sample densely: list/title cards flash for under a second)
ffmpeg -y -v error -i "$VIDEO" -vf "fps=$FPS,scale=720:-1" "$OUT/f_%03d.jpg"

# Full-frame montage sheets
ffmpeg -y -v error -i "$OUT/f_%03d.jpg" \
  -vf "scale=560:-1,tile=$TILE:margin=6:padding=4" -frames:v 1 -q:v 3 "$OUT/sheet_%d.jpg"

# Top band (title cards / numbered badges)
ffmpeg -y -v error -i "$OUT/f_%03d.jpg" \
  -vf "crop=iw:ih*0.30:0:0,scale=600:-1,tile=$TILE:margin=6:padding=4" -frames:v 1 -q:v 3 "$OUT/band_top_%d.jpg"

# Bottom band (burned-in subtitles)
ffmpeg -y -v error -i "$OUT/f_%03d.jpg" \
  -vf "crop=iw:ih*0.35:0:ih*0.55,scale=600:-1,tile=$TILE:margin=6:padding=4" -frames:v 1 -q:v 3 "$OUT/band_bottom_%d.jpg"

# Audio track, for a transcription CLI when one is installed
ffmpeg -y -v error -i "$VIDEO" -vn -ac 1 -ar 16000 "$OUT/audio.wav" || true

echo "frames: $OUT"
ls -1 "$OUT" | sed 's/^/  /'
echo "duration: $(cat "$OUT/duration.txt")s"
echo "tip: to cover frames past the first sheet, re-run the montage with -start_number N"
