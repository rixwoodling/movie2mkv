#!/bin/bash
# m2ts2mkv v3

# automatically convert or copy all streams of a movie file into mkv

### error handling ###

# tested with ffmpeg 3.2.15-0+deb9u2
if ! command -v ffmpeg &> /dev/null; then
    echo "ffmpeg is not installed"
    exit 1
elif ! command -v ffprobe &> /dev/null; then
    echo "ffprobe is not installed"
    exit 1
fi

# accepts only one file a time
if [[ -z "$1" ]]; then
    echo "command requires 1 argument"
    exit 1
elif [[ ! -z "$2" ]]; then
    echo "command requires no more than 1 argument"
    exit 1
fi


### variables and arrays ###

# define empty map array
map=()

# define if deinterlacing is required
deint=$( ffmpeg -hide_banner -filter:v idet -frames:v 100 -an -f rawvideo -y /dev/null -i "$1" 2>&1 | grep -m 1 BFF | sed 's/.*TFF\:\ *//' | sed 's/[^0-9].*//' )
if [ ! "$deint" -eq 0 ]; then
    deint=$( echo -n ", bwdif=mode=0" )
else deint=$( echo -n "" )
fi

# define crop dimensions and assign to options variable
vfcrop=$( ffmpeg -i "$1" -t 5 -vf cropdetect -f null - 2>&1 | awk '/crop/ { print $NF }' | tail -1 )
options=$( echo -n "-analyzeduration 1000000000 -pix_fmt + -vf \""$vfcrop$deint"\" -map_metadata 0 -vsync vfr " )

# assign video options to videostream variable
v=0
vid=()
while [ ! "$v" -eq 1 ]; do
    vid+=$( echo -n '-c:v libx264 -b:v:'$v' 8M -tune film -vprofile high -vlevel 4.0 -movflags faststart ' )
    map+=$( echo -n "-map 0:v:$v " )
    v=$(( v + 1 ))
done
videostream="${vid[@]}"

# loop through audio streams in file and assign back to audiostream variable
a=0
aud=()
while true; do
    audiostreams=$( ffprobe -select_streams a:$a -v error -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$1" )
    if [[ ! -z $audiostreams ]]; then
        aud+=$( echo -n "-ac $audiostreams " )
        map+=$( echo -n "-map 0:a:$a " )
    else
        break
    fi
    a=$(( a + 1 ))
done
audiostreams="${aud[@]}"

# loop through subtitle streams and assign back to subtitlestream variable
s=0
sub=()
while true; do
    subtitlestreams=$( ffprobe -select_streams s:$s -v error -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$1" )
    if [[ ! -z $subtitlestreams ]]; then
        sub+=$( echo -n '-c:s:'$s' copy ' )
        map+=$( echo -n "-map 0:s:$s "  )
    else
        break
    fi
    s=$(( s + 1 ))
done
subtitlestreams="${sub[@]}"

# map streams collected in array assigned to variable
maps="${map[@]}"


### main ###

echo -n "ffmpeg -i $1 "; echo -n "$options"; echo -n "$maps"; echo -n "$videostream"
echo -n "$audiostreams"; echo -n "$subtitlestreams"; echo -n "$1.mkv"; echo

ffmpeg -i $1 $options $maps $videostream $audiostreams $subtitlestreams $1.mkv


