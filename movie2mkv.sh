#!/bin/bash
# movie2mkv v7

# automatically convert or copy all streams of a movie file into mkv
# tested with ffmpeg 3.2.15-0+deb9u2

### --- ERROR HANDLING --- ###

# check if ffmpeg is installed, if not, exit
if ! command -v ffmpeg &>/dev/null; then echo "ffmpeg is not installed"; exit 1
else echo -n "ffmpeg version "; echo $( ffmpeg -version | head -n1 | awk '{print $3}' ); fi

# check if argument is provided, if not exit
if [[ -z "$1" ]]; then echo "command requires 1 argument"; exit 1
elif [[ ! -z "$2" ]]; then echo "command requires no more than 1 argument"; exit 1; fi


### probe movie for specs ###
#if [ -f ./movie2probe.sh ]; then ./movie2probe.sh $1
#else pass; fi


### --- OPTIONS --- ###

# define if deinterlacing is required, will return 0 if true
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
# loop once
while [ ! "$v" -eq 1 ]; do
    # get video language of movie, set to undetermined if blank
    lang=$( ffprobe -i $1 v:$v -loglevel quiet -show_entries stream_tags=language -select_streams v -of default=noprint_wrappers=1:nokey=1 )
    if [ -z $lang ]; then lang="und"; fi
    # for video settings, set to libx264, bitrate to 8M, tune to film, set profile to high/4.0, keep metadata, add language
    vid+=$( echo -n '-c:v libx264 -b:v:'$v' 8M -tune film -vprofile high -vlevel 4.0 -metadata:s:v:'$v' language='$lang )
    v=$(( v + 1 ))
done
videostream="${vid[@]}"
# -c:v libx264 -b:v:0 8M -tune film -vprofile high -vlevel 4.0 -metadata:s:v:0 language=eng

# AUDIOSTREAMS
a=0
f=1
aud=()
# loop through each audio stream
while true; do
    # get audio language for each stream
    lang=$( ffprobe -i $1 a:$a -loglevel quiet -show_entries stream_tags=language -select_streams a -of default=noprint_wrappers=1:nokey=1 )
    if [ -z $lang ]; then lang="und"; fi
    # get audio format for each stream
    audioformat=$( ffmpeg -filter:v idet -frames:v 100 -f rawvideo -y /dev/null -i "$1" 2>&1 | grep "Audio:\ *" | grep "#0:"$f | awk '{print $4}' | sed 's/[^a-zA-Z0-9]//g' )
    # if audio is detected
    if [[ ! -z $audioformat ]]; then
        # if audioformat is dts, ac3 or aac, then just copy
        if [[ "$audioformat" == "dts" || "$audioformat" == "ac3" || "$audioformat" == "aac" ]]; then
            aud+=$( echo -n '-c:a:'$a' copy ' )
        # check number of channels in stream, set to convert all channels to aac    
        else
            audiostreams=$( ffprobe -select_streams a:$a -v error -show_entries program_stream=channels -of default=noprint_wrappers=1:nokey=1 "$1" )
            #aud+=$( echo -n '-ac '$audiostreams' aac -b:a 384k -ar 48000 -metadata:s:a:'$a' language='$lang' ' ) 
            if [[ $audiostreams -eq 6 ]]; then #
                aud+=$( echo -n '-ac 6 aac -b:a 384k -ar 48000 -metadata:s:a:'$a' language='$lang' ' ) #
            else #
                aud+=$( echo -n '-ac 2 aac -b:a 384k -ar 48000 -metadata:s:a:'$a' language='$lang' ' ) #
            fi #
        fi
    # if no audio detected, break loop
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

echo "ffmpeg -probesize 100M -analyzeduration 100M"
echo "-i $1"
echo "$options"
echo "-map 0"
if [ ! -z "${vid[@]}" ]; then echo "${vid[@]}"; fi
# sed expression creates newlines at each -c
if [ ! -z "${aud[@]}" ]; then echo "${aud[@]}" | sed 's/-c/\n-c/2g'; fi
if [ ! -z "${sub[@]}" ]; then echo "${sub[@]}" | sed 's/-c/\n-c/2g'; fi
echo "$1.mkv"; echo

# auto map all streams
maps="-map 0"

ffmpeg -probesize 100M -analyzeduration 100M -i $1 $options -loglevel warning -stats $maps $videostream $audiostreams $subtitlestreams $1.mkv



