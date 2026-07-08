#!/usr/bin/env bash
# Toggle area screen recording with wf-recorder (NVENC on the RTX 4090).
# First press: pick a region with slurp and start recording.
# Second press: stop cleanly and finalize the file.

set -euo pipefail

OUTDIR="${XDG_VIDEOS_DIR:-$HOME/Videos}"
NVENC_DEVICE="/dev/dri/renderD128"   # RTX 4090

# Already recording? Stop it.
if pkill -INT -x wf-recorder; then
  notify-send -t 2000 "Recording" "Stopped — saved to $OUTDIR"
  exit 0
fi

mkdir -p "$OUTDIR"

region=$(slurp -b "#00000080" -c "#888888ff" -w 1) || exit 0
[ -z "$region" ] && exit 0

ts=$(date +%Y-%m-%d_%H-%M-%S)
file="$OUTDIR/recording_$ts.mp4"

notify-send -t 1500 "Recording" "Started — SUPER+ALT+R again to stop"

# NVENC; falls back to software x264 if the GPU encoder is unavailable.
if ! wf-recorder -c h264_nvenc -d "$NVENC_DEVICE" -x yuv420p -g "$region" -f "$file" 2>/tmp/wf-recorder.log; then
  notify-send -t 2000 "Recording" "NVENC failed, retrying with software encoder"
  wf-recorder -x yuv420p -g "$region" -f "$file"
fi
