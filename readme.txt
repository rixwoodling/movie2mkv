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

This script takes all of the guesswork out of converting high resolution video down to a smaller compression. There are no options or settings to monkey with. Simply execute the command plus the movie as an argument you wish to convert. 

---

example source/target:

Here is the source information of all streams when probing:
   
   31.75 GB
   0 h264 video 1920 1080 yuv420p N/A 
   1 flac audio 48000 2 stereo tgl 
   2 ac3 audio 48000 2 stereo eng 
   3 hdmv_pgs_subtitle subtitle eng 

Here is the target information of all streams:
   
   7.69 GB
   0 h264 video 1536 1040 yuv420p N/A 
   1 vorbis audio 48000 2 stereo tgl 
   2 vorbis audio 48000 2 stereo eng 
   3 hdmv_pgs_subtitle subtitle eng 

This script produces a quality archive at about 25% of the original size.
Notice the resolution after is the result of the crop detection and colorspace is preserved.
Audio is converted to vorbis and all channels are maintained.
Subtitles are copied over and left untouched.

---

Submit all issues and requests to: https://github.com/rixwoodling/movie2mkv/issues

