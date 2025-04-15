#!/usr/bin/env python3

import sys

def time_to_ms(timestr):
    h, m, s = timestr.strip().split(':')
    s, ms = s.split('.')
    return (int(h) * 3600 + int(m) * 60 + int(s)) * 1000 + int(ms[:3].ljust(3, '0'))

def extract_tag_value(line, tag):
    open_tag = f"<{tag}>"
    close_tag = f"</{tag}>"
    if open_tag in line and close_tag in line:
        return line.split(open_tag)[1].split(close_tag)[0].strip()
    return None

def parse_chapters(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    chapters = []
    current_title = None
    current_start = None

    for line in lines:
        line = line.strip()

        title = extract_tag_value(line, "ChapterString")
        start = extract_tag_value(line, "ChapterTimeStart")

        if title is not None:
            current_title = title

        if start is not None:
            current_start = time_to_ms(start)

        if current_title and current_start is not None:
            chapters.append({
                "title": current_title,
                "start": current_start
            })
            current_title = None
            current_start = None

    for i in range(len(chapters) - 1):
        chapters[i]["end"] = chapters[i + 1]["start"]
    chapters[-1]["end"] = chapters[-1]["start"] + 5000  # fallback 5s

    return chapters

def write_ffmeta(chapters, output_path):
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(";FFMETADATA1\n\n")
        for ch in chapters:
            f.write("[CHAPTER]\n")
            f.write("TIMEBASE=1/1000\n")
            f.write(f"START={ch['start']}\n")
            f.write(f"END={ch['end']}\n")
            f.write(f"title={ch['title']}\n\n")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 xml2ffmeta_noimport.py input.xml output.ffmeta")
        sys.exit(1)

    in_path = sys.argv[1]
    out_path = sys.argv[2]

    chaps = parse_chapters(in_path)
    write_ffmeta(chaps, out_path)
