import sys
import subprocess

def mkv_chapter_extractor(filename):
    out = filename.rsplit('.', 1)[0] + '.ffmeta'
    subprocess.run(['ffmpeg', '-i', filename, '-f', 'ffmetadata', out], check=True)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 mkv_chapter_extractor.py <input.mkv>")
        sys.exit(1)
    mkv_chapter_extractor(sys.argv[1])
  
