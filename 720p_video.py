#!/usr/bin/env python3
import sys
import subprocess

def convert_to_plexsafe_720p(input_path, output_path):
    command = [
        "ffmpeg",
        "-i", input_path,
        "-c:v", "libx264",
        "-b:v", "1600k",
        "-maxrate", "1800k",
        "-bufsize", "3600k",
        "-c:a", "aac",
        "-b:a", "128k",
        "-vf", "scale=1280:-2",
        "-movflags", "+faststart",
        output_path
    ]
    
    print("Running ffmpeg with the following command:")
    print(" ".join(command))
    subprocess.run(command)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 plexrelay_convert.py input.mkv output.mp4")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    convert_to_plexsafe_720p(input_file, output_file)

#
