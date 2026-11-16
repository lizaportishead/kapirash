#!/bin/bash
# качает звук по одному, считает долю неразмеченной речи, удаляет файл
cd /Users/elizavetamatveeva/projects/kapiras-player
OLD=/private/tmp/claude-501/-Users-elizavetamatveeva--claude-spares-spare-pTCQsJ/d5d6ab38-b713-4850-914b-bdd1c2c426fe/scratchpad
W=/private/tmp/claude-501/-Users-elizavetamatveeva--claude-spares-spare-uskiet/8d08f207-2e3c-4db2-9be5-013909a297d4/scratchpad/scan; mkdir -p $W
python3 -c "import json;[print(i,k) for i,k in json.load(open('tools/mamini_fix/todo_vad.json'))]" | while read i k; do
  rm -f $W/*
  if [ $k = tiktok ]; then $OLD/yt-dlp_macos -q -f "b[ext=mp4]/b" -o "$W/$i.mp4" "https://www.tiktok.com/@_/video/$i" >/dev/null 2>&1
  else $OLD/yt-dlp_macos -q -f 140 -o "$W/$i.m4a" "https://www.youtube.com/watch?v=$i" >/dev/null 2>&1; fi
  f=$(ls $W/$i.* 2>/dev/null | head -1)
  if [ -z "$f" ]; then echo "{'id': '$i', 'error': 'download'}"; continue; fi
  $OLD/v/bin/python tools/mamini_fix/vadcheck.py "$f" 2>&1 | grep "^{"
done
rm -f $W/*
