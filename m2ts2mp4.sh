#!/bin/bash


### functions

function vcrop {
    echo "detecting video dimensions"
    ffmpeg -i *.m2ts -t 1 -vf cropdetect -f null - 2>&1 | \
    awk '/crop/ { print $NF }' | tail -1
}

function main {
    vcrop
}

### error handling

if [ ! -d ./m2ts ]; then mkdir m2ts; fi
if [ ! -d ./mp4 ]; then mkdir mp4; fi

if ! command -v ffmpeg &> /dev/null; then echo "ffmpeg is not installed"
elif ! command  -v ffprobe &> /dev/null; then echo "ffprobe is not installed"
fi

if [[ $( \ls | wc -l ) = 0 ]]; then :
elif [[ $( \ls | wc -l ) < 1 ]]; then echo "too many files in source folder"
else if [ ! -f *.m2ts ]; then :; else main; fi
fi

### function calls




