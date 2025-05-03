#!/bin/bash

# Auto-crop, trim, scale to 1280 wide or 720 high — 5-minute sample with audio

input="$1"
output="$2"

if [[ -z "$input" || -z "$output" ]]; then
  echo "Usage: $0 input.mkv output.mp4"
  exit 1
fi

start="00:00:00.000"
duration="10:00:00.000"
cropdetect_time="00:01:00.000"  # 25s after the actual start time

echo "Scanning crop values from '$input' at $cropdetect_time..."

crop=$(ffmpeg -fflags +genpts -analyzeduration 100M -probesize 100M -ss "$cropdetect_time" -i "$input" -t 10 -vf cropdetect -f null - 2>&1 \
  | grep -oP "crop=\d+:\d+:\d+:\d+" | tail -1)

if [[ -z "$crop" ]]; then
  echo "Could not auto-detect crop, aborting..."
  exit 1
fi

echo "Using crop filter: $crop"

# Parse crop values into variables
IFS=":" read -r crop_w crop_h crop_x crop_y <<< "$(echo "$crop" | cut -d= -f2)"

# Decide how to scale
if [[ "$crop_w" -lt 1920 && "$crop_h" -eq 1080 ]]; then
  echo "Detected pillarbox. Scaling by height to 720..."
  scale="scale=-1:720"
elif [[ "$crop_h" -lt 1080 && "$crop_w" -eq 1920 ]]; then
  echo "Detected letterbox. Scaling by width to 1280..."
  scale="scale=1280:-1"
else
  echo "No black bars detected. Scaling to 1280x720..."
  scale="scale=1280:720"
fi

echo "Creating 5-minute sample from $start using scale: $scale"

# Frame-accurate seek + scale
ffmpeg -fflags +genpts -analyzeduration 100M -probesize 100M -i "$input" \
  -ss "$start" -to "$duration" \
  -map 0:v:0 -map 0:a:0 \
  -vf "$crop,$scale,setsar=1" \
  -c:v libx264 -b:v 1600k -maxrate 1750k -bufsize 3500k \
  -c:a aac -b:a 192k \
  -movflags +faststart -avoid_negative_ts make_zero \
  "$output"

echo "Done. Output saved to: $output"

echo "Checking peak bitrate..."
peak=$(ffmpeg -v error -i "$output" -f null - 2>&1 \
  | grep bitrate= \
  | sed -n 's/.*bitrate=\([0-9]*\) kb\/s.*/\1/p' \
  | sort -nr | head -1)

echo "Max muxed bitrate: ${peak} kbps"

if (( peak > 2000 )); then
  echo "WARNING: Bitrate exceeds safe Plex Relay limits (2Mbps)"
else
  echo "Bitrate is safe for Plex Relay"
fi

