#!/bin/bash
# m2ts2mkv v1

### functions ###

function options {
    vfcrop=$( ffmpeg -i "$1" -t 1 -vf cropdetect -f null - 2>&1 | awk '/crop/ { print $NF }' | tail -1 )
    echo -n '-ss 0 -t 5 -pix_fmt + -vf'" \""$vfcrop"\" "'-map_metadata 0 -vsync vfr '
}

function videostream {
    n=0
    while [ ! "$n" -eq 1 ]; do
        echo -n ' libx264 -b:v:'$n' 8M -tune film -vprofile high -vlevel 4.0 -movflags faststart '
        n=$(( n + 1 ))
    done
}

function audiostreams {
    n=0
    while true; do
        x=$( ffprobe -select_streams a:$n -v error -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$1" )
        if [[ ! -z $x ]]; then
            echo -n '-c:a:'$n' ac'"$x"' '
        else
            break
        fi
        n=$(( n + 1 ))
    done
}

function subtitlestreams {
    n=0
    while true; do
        x=$( ffprobe -select_streams s:$n -v error -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$1" )
        if [[ ! -z $x ]]; then
            echo -n '-c:s:'$n' copy '
        else
            break
        fi
        n=$(( n + 1 ))
    done
}

function main {
    opt=$("options $1"); vid=$("videostream $1"); aud=$("audiostreams $1"); sub=$("subtitlestreams $1")
    ffmpeg -i "$1" $opt $vid $aud $sub "$1".mkv
}

### error handling / main

if [ ! -d ./m2ts ]; then mkdir m2ts; fi
if [ ! -d ./mkv ]; then mkdir mkv; fi

if ! command -v ffmpeg &> /dev/null; then echo "ffmpeg is not installed"
elif ! command -v ffprobe &> /dev/null; then echo "ffprobe is not installed"
fi

if [[ $( \ls ./m2ts | wc -l ) -eq 0 ]]; then echo "no m2ts file found"
elif [[ $( \ls ./m2ts | wc -l ) -gt 1 ]]; then echo "too many files in source folder"
else if [ ! -f ./m2ts/*.m2ts ]; then echo "file is not an m2ts file"; else main "$1"; fi
fi


