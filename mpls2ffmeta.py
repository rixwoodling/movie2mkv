import sys
import struct
import os

def read_mpls_file(path):
    #print(f"[read_mpls_file] Reading binary from: {path}")
    with open(path, 'rb') as f:
        data = f.read()
    #print(f"[read_mpls_file] Read {len(data)} bytes.")
    return data

def find_mark_entries(data):
    print("[find_mark_entries] Scanning for possible PlaylistMark entries...")

    entries = []
    i = 0
    while i + 12 <= len(data):
        chunk = data[i:i + 12]
        mark_type = chunk[0]

        # Check for plausible PlaylistMark entry
        if mark_type == 0x01:
            timestamp = struct.unpack(">I", chunk[4:8])[0]
            entries.append((i, chunk, timestamp))
        i += 1

    print(f"[find_mark_entries] Found {len(entries)} potential mark entries.")
    for i, (offset, chunk, timestamp) in enumerate(entries):
        print(f"[entry {i}] offset=0x{offset:04x}, timestamp={timestamp} ({timestamp // 90000:.2f} sec)")

    return entries

def filter_valid_chapter_ticks(entries, min_spacing_ms=1000, min_offset=0x02ed):
    print("[filter_valid_chapter_ticks] Filtering potential marks...")

    # Keep entries after offset
    filtered = [(o, t) for o, _, t in entries if o >= min_offset]

    # Sort by timestamp
    filtered.sort(key=lambda x: x[1])

    ticks = []
    last_tick = -1

    for offset, timestamp in filtered:
        ms = timestamp // 90
        if last_tick == -1 or ms - last_tick >= min_spacing_ms:
            ticks.append(timestamp)
            last_tick = ms

    print(f"[filter_valid_chapter_ticks] Retained {len(ticks)} ticks with spacing ≥ {min_spacing_ms}ms.")
    return ticks

def write_ticks_to_file(ticks, input_path):
    base = os.path.splitext(input_path)[0]
    output_path = f"{base}.txt"
    print(f"[write_ticks_to_file] Writing {len(ticks)} ticks to: {output_path}")

    with open(output_path, "w") as f:
        for tick in ticks:
            f.write(f"{tick}\n")

def write_ffmeta(ticks, input_path):
    base = os.path.splitext(input_path)[0]
    output_path = f"{base}.ffmeta"
    print(f"[write_ffmeta] Writing ffmeta to: {output_path}")

    with open(output_path, "w") as f:
        f.write(";FFMETADATA1\n\n")

        for i in range(len(ticks)):
            start = ticks[i] // 90
            end = ticks[i + 1] // 90 if i + 1 < len(ticks) else start + 1000
            f.write("[CHAPTER]\n")
            f.write("TIMEBASE=1/1000\n")
            f.write(f"START={start}\n")
            f.write(f"END={end}\n")
            f.write(f"title=Chapter {i+1:02}\n\n")

if __name__ == "__main__":
    input_path = sys.argv[1]
    data = read_mpls_file(input_path)
    entries = find_mark_entries(data)
    ticks = filter_valid_chapter_ticks(entries, min_spacing_ms=1000, min_offset=0x02ed)
    #write_ticks_to_file(ticks, input_path)
    write_ffmeta(ticks, input_path)
