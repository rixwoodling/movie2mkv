#!/bin/bash


### functions

function vcrop {
    echo "detecting video dimensions"
    ffmpeg -i ./m2ts/*.m2ts -t 1 -vf cropdetect -f null - 2>&1 | awk '/crop/ { print $NF }' | tail -1
}

function main {
    vcrop
}

### error handling

if [ ! -d ./m2ts ]; then mkdir m2ts; fi
if [ ! -d ./mp4 ]; then mkdir mp4; fi

if ! command -v ffmpeg &> /dev/null; then echo "ffmpeg is not installed"
elif ! command -v ffprobe &> /dev/null; then echo "ffprobe is not installed"
fi

if [[ $( \ls ./m2ts | wc -l ) -eq 0 ]]; then echo "no m2ts file found"
elif [[ $( \ls ./m2ts | wc -l ) -gt 1 ]]; then echo "too many files in source folder"
else if [ ! -f ./m2ts/*.m2ts ]; then echo "file is not an m2ts file"; else main; fi
fi

### function calls

