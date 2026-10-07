#!/usr/bin/env python3
"""CircularProgress arc pieces (pure Python, no deps) — binary-decomposed arcs, user design 2026-10-07.

  gen-arc.py <out.png>   960x960 sheet, 36 cells of 160x160 in 6 columns x 6 rows, COLUMN-major:
                         cell i -> ImageRectOffset (160 * (i // 6), 160 * (i % 6)), ImageRectSize (160, 160)
                         i = thickness_index * 9 + angle_index
                         thickness_index 0..3 -> stroke / cell = 0.05, 0.10, 0.15, 0.20 (thin, M3 default 4/40, thick, extra)
                         angle_index 0..8    -> nominal arc A = 1, 2, 4, ..., 256 degrees

Each cell: a ring whose OUTER edge touches the cell edge (minus 1 px for anti-aliasing), centred, so an ImageLabel of
Size = the indicator diameter draws the ring at that diameter and `Rotation` turns the piece about the centre (no clip
needed). The arc starts at 12 o'clock and runs CLOCKWISE for A + OVERLAP degrees: OVERLAP = 2 degrees is drawn past
the nominal end so pieces laid end to end overlap and never show a hairline seam; the overhang past the last piece is
covered by the round end cap (2 degrees x radius < stroke / 2 for every thickness). Ends are flat (radial) cuts — the
round ends are separate round Frames. White on transparent, anti-aliased by 4x4 supersampling.
Use in src/Progress/Circular.luau: an arc of span S is built from the binary pieces of S - OVERLAP (not S), so the last
piece's overhang ends exactly at the nominal end and the cap sits on a flat cut — a cap does not cover the CORNERS of a
cut 2 degrees past its centre (up to ~1 px on a 200 px thin ring); a closed ring uses 360 and laps its own start.
"""
import math, zlib, struct, sys

C = 160
THICK = [0.05, 0.10, 0.15, 0.20]
ANGLES = [1 << k for k in range(9)]
OVERLAP = 2.0
SS = 4

def cell(t_ratio, angle):
    t = t_ratio * C
    ro = C / 2 - 1
    ri = ro - t
    span = math.radians(angle + OVERLAP)
    out = []
    for y in range(C):
        row = []
        for x in range(C):
            hit = 0
            for sy in range(SS):
                for sx in range(SS):
                    px = x + (sx + 0.5) / SS - C / 2
                    py = y + (sy + 0.5) / SS - C / 2
                    r = math.hypot(px, py)
                    if ri <= r <= ro:
                        th = math.atan2(px, -py)  # 0 at 12 o'clock, clockwise positive
                        if th < 0:
                            th += 2 * math.pi
                        if th <= span:
                            hit += 1
            row.append(round(hit * 255 / (SS * SS)))
        out.append(row)
    return out

def png(path, W, H, alpha):
    raw = b"".join(b"\x00" + b"".join(bytes((255, 255, 255, a)) for a in r) for r in alpha)
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    open(path, "wb").write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))

if __name__ == "__main__":
    sheet = [[0] * (C * 6) for _ in range(C * 6)]
    i = 0
    for t in THICK:
        for a in ANGLES:
            f = cell(t, a)
            ox, oy = C * (i // 6), C * (i % 6)
            for y in range(C):
                sheet[oy + y][ox:ox + C] = f[y]
            i += 1
    png(sys.argv[1], C * 6, C * 6, sheet)
