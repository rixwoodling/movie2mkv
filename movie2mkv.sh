#!/bin/bash
# movie2mkv v6

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
    deint=$( echo -n "-vf bwdif=mode=0" )
else deint=$( echo -n "" )
fi

# define crop dimensions and assign to options variable
vfcrop=$( ffmpeg -i "$1" -t 3 -vf cropdetect -f null - 2>&1 | awk '/crop/ { print $NF }' | tail -1 )
options=$( echo -n "-probesize 100M -analyzeduration 100M -pix_fmt + -vf "$vfcrop $deint "-map_metadata 0 -vsync vfr " )

# assign video options to videostream variable
v=0
vid=()
while [ ! "$v" -eq 1 ]; do
    vid+=$( echo -n '-c:v libx264 -b:v:'$v' 8M -tune film -vprofile high -vlevel 4.0 -movflags faststart ' )
    map+=$( echo -n "-map 0:v:$v " )
    v=$(( v + 1 ))
done
videostream="${vid[@]}"



# loop through audio streams and either convert or copy back to audiostream variable(s)
a=0
f=1
aud=()
while true; do
    audioformat=$( ffmpeg -filter:v idet -frames:v 100 -f rawvideo -y /dev/null -i "$1" 2>&1 | grep "Audio:\ *" | grep "#0:"$f | awk '{print $4}' | sed 's/[^a-zA-Z0-9]//g' )
    if [[ ! -z $audioformat ]]; then
        if [[ "$audioformat" == "dtsx" || "$audioformat" == "ac3x" || "$audioformat" == "flacx" ]]; then
            aud+=$( echo -n '-c:a:'$a' copy ' )
            map+=$( echo -n '-map 0:a:'$a' ' )
        else
            audiostreams=$( ffprobe -select_streams a:$a -v error -show_entries stream=channels -of default=noprint_wrappers=1:nokey=1 "$1" )
            if [[ $audiostreams -eq 6 ]]; then audiobitrate='-b:a 384k -ar 48000 '
            else audiobitrate=""; fi
            aud+=$( echo -n '-ac '$audiostreams' '"$audiobitrate" )
            map+=$( echo -n '-map 0:a:'$a' ' )
        fi
    else
        break
    fi
    a=$(( a + 1 ))
    f=$(( f + 1 ))
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

