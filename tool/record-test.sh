#!/bin/bash

# Define the output video file
OUTPUT_VIDEO="test_run_$(date +%Y-%m-%d_%H-%M-%S).mp4"

# Start recording with ffmpeg (adjust the screen dimensions as needed)
ffmpeg -f avfoundation -video_size 2000x800 -framerate 24 -i "Capture screen 0" "$OUTPUT_VIDEO" &
FFMPEG_PID=$!

# Run the Flutter integration test
# sh/test_clean.sh
flutter test integration_test -d macos --enable-impeller

# Stop the ffmpeg recording
kill $FFMPEG_PID
