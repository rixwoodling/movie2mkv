#!/bin/bash
# m2ts2mkv v1



### functions ###

function options {
    vfcrop=$( ffmpeg -i "$i" -t 1 -vf cropdetect -f null - 2>&1 | awk '/crop/ { print $NF }' | tail -1 )
    echo -n "-pix_fmt + -vf "$vfcrop" -map_metadata 0 -vsync vfr"
}

function videostream {
    n=0
    while [ ! "$n" -eq 1 ]; do
        echo -n '-c:v libx264 -b:v:'$n' 8M -tune film -vprofile high -vlevel 4.0 -movflags faststart '
        n=$(( n + 1 ))
    done
}

function audiostreams {
    n=0
    while true; do
        x=$( ffprobe -select_streams a:$n -v error -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$i" )
        if [[ ! -z $x ]]; then
            echo -n '-ac '$x' '
        else
            break
        fi
        n=$(( n + 1 ))
    done
}

function subtitlestreams {
    n=0
    while true; do
        x=$( ffprobe -select_streams s:$n -v error -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$i" )
        if [[ ! -z $x ]]; then
            echo -n '-c:s:'$n' copy '
        else
            break
        fi
        n=$(( n + 1 ))
    done
}


### error handling

if [ ! -d ./m2ts ]; then mkdir m2ts; fi
if [ ! -d ./mkv ]; then mkdir mkv; fi

if ! command -v ffmpeg &> /dev/null; then echo "ffmpeg is not installed"
elif ! command -v ffprobe &> /dev/null; then echo "ffprobe is not installed"
fi

### main ###

i=(m2ts/*); f=$(basename "$i"); o=(mkv/"$f")
opt=$(options "$i"); vid=$(videostream "$i"); aud=$(audiostreams "$i"); sub=$(subtitlestreams "$i")

ffmpeg -i "$i" $opt $vid $aud $sub "$o".mkv


