#!/bin/bash
# movie2mkv v7

# automatically convert or copy all streams of a movie file into mkv


### --- ERROR HANDLING --- ###

# tested with ffmpeg 3.2.15-0+deb9u2
if ! command -v ffmpeg &>/dev/null; then echo "ffmpeg is not installed"; exit 1
else echo -n "ffmpeg version "; echo $( ffmpeg -version | head -n1 | awk '{print $3}' ); fi

if [[ -z "$1" ]]; then echo "command requires 1 argument"; exit 1
elif [[ ! -z "$2" ]]; then echo "command requires no more than 1 argument"; exit 1; fi


### probe movie for specs ###
#if [ -f ./movie2probe.sh ]; then ./movie2probe.sh $1
#else pass; fi


### --- OPTIONS --- ###

# define if deinterlacing is required
deint=$( ffmpeg -hide_banner -filter:v idet -frames:v 100 -an -f rawvideo -y /dev/null -i "$1" 2>&1 | grep -m 1 BFF | sed 's/.*TFF\:\ *//' | sed 's/[^0-9].*//' )
if [ ! "$deint" -eq 0 ]; then
    deint=$( echo -n "-vf bwdif=mode=0" )
    echo -n "deinterlacing needed, and "
else
    deint=$( echo -n "" )
    echo -n "no deinterlacing needed, but "
fi

# define crop dimensions and assign to options variable
echo "detecting crop dimensions, please wait..."; echo
vfcrop=$( ffmpeg -i "$1" -t 300 -vf cropdetect -f null - 2>&1 | awk '/crop/ { print $NF }' | tail -1 )
options=$( echo -n '-pix_fmt + -vf '$vfcrop $deint '-map_metadata 0 -vsync vfr ' )


### --- VIDEO AUDIO SUBTITLES --- ###

# VIDEOSTREAMS
v=0
vid=()
while [ ! "$v" -eq 1 ]; do
    lang=$( ffprobe -i $1 v:$v -loglevel quiet -show_entries stream_tags=language -select_streams v -of default=noprint_wrappers=1:nokey=1 )
    if [ -z $lang ]; then lang="und"; fi
    vid+=$( echo -n '-c:v libx264 -b:v:'$v' 8M -tune film -vprofile high -vlevel 4.0 -metadata:s:v:'$v' language='$lang )
    v=$(( v + 1 ))
done
videostream="${vid[@]}"

# AUDIOSTREAMS
a=0
f=1
aud=()
while true; do
    lang=$( ffprobe -i $1 a:$a -loglevel quiet -show_entries stream_tags=language -select_streams a -of default=noprint_wrappers=1:nokey=1 )
    if [ -z $lang ]; then lang="und"; fi
    audioformat=$( ffmpeg -filter:v idet -frames:v 100 -f rawvideo -y /dev/null -i "$1" 2>&1 | grep "Audio:\ *" | grep "#0:"$f | awk '{print $4}' | sed 's/[^a-zA-Z0-9]//g' )
    if [[ ! -z $audioformat ]]; then
        if [[ "$audioformat" == "dts" || "$audioformat" == "ac3" || "$audioformat" == "flac" ]]; then
            aud+=$( echo -n '-c:a:'$a' copy ' )
        else
            audiostreams=$( ffprobe -select_streams a:$a -v error -show_entries program_stream=channels -of default=noprint_wrappers=1:nokey=1 "$1" )
            if [[ $audiostreams -eq 6 ]]; then
                aud+=$( echo -n '-ac 6 -b:a 384k -ar 48000 -metadata:s:a:'$a' language='$lang' ' )
            else
                aud+=$( echo -n '-ac 2 -metadata:s:a:'$a' language='$lang' ' )
            fi
        fi
    else
        break
    fi
    a=$(( a + 1 ))
    f=$(( f + 1 ))
done
audiostreams="${aud[@]}"

# SUBTITLES
s=0
sub=()
while true; do
    lang=$( ffmpeg -i $1 s:$s -loglevel quiet -show_entries stream_tags=language -select_streams s -of default=noprint_wrappers=1:nokey=1 )
    if [ -z $lang ]; then lang="und"; fi
    subtitlestreams=$( ffprobe -select_streams s:$s -v error -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 "$1" )
    if [[ ! -z $subtitlestreams ]]; then
        sub+=$( echo -n '-c:s:'$s' copy -metadata:s:s:'$s' language='$lang' ' )
        s=$(( s + 1 ))
    else
        break
    fi
done
subtitlestreams="${sub[@]}"


### --- STDOUT --- ###

echo "ffmpeg -i $1"
echo "$options"
echo "-map 0"
if [ ! -z "${vid[@]}" ]; then echo "${vid[@]}"; fi
if [ ! -z "${aud[@]}" ]; then echo "${aud[@]}" | sed 's/-c/\n-c/2g'; fi
if [ ! -z "${sub[@]}" ]; then echo "${sub[@]}" | sed 's/-c/\n-c/2g'; fi
echo "$1.mkv"; echo

maps="-map 0"

ffmpeg -probesize 100M -analyzeduration 100M -i $1 $options -loglevel warning -stats $maps $videostream $audiostreams $subtitlestreams $1.mkv



