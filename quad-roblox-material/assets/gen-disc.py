#!/usr/bin/env python3
"""Ripple disc (pure Python, no deps): gen-disc.py <out.png> -> 1024x1024, a white disc of radius 511.5 centred in the
image, transparent outside, anti-aliased by exact distance (1 px ramp). Used with ImageRectOffset/ImageRectSize to draw
the part of a ripple circle that falls inside the host rectangle (an exact cut circle, never past the host's edges)."""
import math, zlib, struct, sys
N = 1024
R = N / 2 - 0.5
c = N / 2
rows = []
for y in range(N):
    dy = y + 0.5 - c
    row = bytearray(b"\x00")
    for x in range(N):
        dx = x + 0.5 - c
        a = max(0.0, min(1.0, R - math.hypot(dx, dy) + 0.5))
        row += bytes((255, 255, 255, round(a * 255)))
    rows.append(bytes(row))
def chunk(t, d):
    return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
open(sys.argv[1], "wb").write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", N, N, 8, 6, 0, 0, 0))
    + chunk(b"IDAT", zlib.compress(b"".join(rows), 9)) + chunk(b"IEND", b""))
