movie2mkv v3

Automatically convert all streams of a movie file into an mkv.

basic command:
./movie2mkv.sh ~/path/of/movie.m2ts
 
features:
+ deinterlaces automatically when detected
+ crops out detected black bars from letterboxing 
+ converts 1 video stream providing visually lossless picture
+ converts all audio streams maintaining original channels
+ copies over all embedded subtitle tracks
+ copies over all metadata from source video

limitations at this time:
- not best for .avi and other low source videos
- scaling video and variable bitrate is not implemented
- no batch converting
- not tested for audio files only but possible

This script takes all of the guesswork out of converting high resolution video down to a smaller compression. There are no options or settings to monkey with. Simply execute the command plus the movie as an agrument you wish to convert. 

Submit all issues and requests to: https://github.com/rixwoodling/movie2mkv/issues

