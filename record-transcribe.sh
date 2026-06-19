#!/usr/bin/env bash

TMP=$(mktemp --suffix=.wav)

echo "Recording... (press any key to stop)"
ffmpeg -f pulse -i default \
       -ac 1 -ar 16000 \
       "$TMP" -y 2>/tmp/ffmpeg-record.log &
FFMPEG_PID=$!

read -n 1
kill -SIGINT "$FFMPEG_PID" 2>/dev/null
wait "$FFMPEG_PID" 2>/dev/null
sleep 0.5
echo ""

echo ""
echo "File size: $(du -h "$TMP" | cut -f1)"
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$TMP" 2>/dev/null | xargs -I{} printf "Duration: %.1fs\n" {}
if [ ! -s "$TMP" ]; then
    echo "WARNING: File is empty. ffmpeg log:"
    cat /tmp/ffmpeg-record.log 2>/dev/null
fi
echo ""

echo "Transcribing..."
RESPONSE=$(curl -s \
  -H "Authorization: Bearer $WHISPER_API_KEY" \
  -F "file=@$TMP" \
  http://ai-office-server:8082/inference
)

# echo "Response: $RESPONSE"
  
TEXT=$(echo "$RESPONSE" | jq -r '.text')

echo ""
echo "$TEXT"
echo ""

echo -n "$TEXT" | wl-copy
echo "Copied to clipboard."

rm "$TMP"