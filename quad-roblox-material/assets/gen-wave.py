#!/usr/bin/env python3
"""WavyProgress textures (pure Python, no deps).

  gen-wave.py single <out.png>   one wavelength, 512x128, full amplitude (the original upload)
  gen-wave.py sheet  <out.png>   amplitude sprite sheet: 24 frames of 512x80 in 2 columns x 12 rows (1024x960)
                                 frame i -> ImageRectOffset (512 * (i // 12), 80 * (i % 12)), ImageRectSize (512, 80)
                                 frame 0 = full amplitude, frame 23 = flat; amplitude(i) = 0.3H * (1 - i / 23) (linear —
                                 ease in time, not in the sheet)

Shape rule (shared by both, and by the cap math in src/Progress/Wavy.luau): one wavelength W wide, height H,
centre line H/2, y(x) = H/2 - A sin(2 pi x / W), stroke width 0.4H, full A = 0.3H; starts at the centre line going UP
at x = 0 and tiles seamlessly in x. White stroke on transparent, anti-aliased by exact distance to the curve.
"""
import math, zlib, struct, sys

def frame(W, H, amp):
    half = 0.4 * H / 2
    cy = H / 2
    S = 8
    pts = [(i / S, cy - amp * math.sin(2 * math.pi * (i / S) / W)) for i in range(-W * S, 2 * W * S)]
    win = int((half + 2) * S)
    out = []
    for y in range(H):
        py = y + 0.5
        row = []
        for x in range(W):
            px = x + 0.5
            c = int((px + W) * S)
            best = 1e9
            for i in range(c - win, c + win + 1):
                qx, qy = pts[i]
                d = (qx - px) ** 2 + (qy - py) ** 2
                if d < best:
                    best = d
            row.append(round(max(0.0, min(1.0, half - math.sqrt(best) + 0.5)) * 255))
        out.append(row)
    return out

def png(path, W, H, alpha):
    raw = b"".join(b"\x00" + b"".join(bytes((255, 255, 255, a)) for a in r) for r in alpha)
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    open(path, "wb").write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))

if __name__ == "__main__":
    mode, out = sys.argv[1], sys.argv[2]
    if mode == "single":
        png(out, 512, 128, frame(512, 128, 0.3 * 128))
    else:
        FW, FH, ROWS, COLS = 512, 80, 12, 2
        N = ROWS * COLS
        sheet = [[0] * (FW * COLS) for _ in range(FH * ROWS)]
        for i in range(N):
            f = frame(FW, FH, 0.3 * FH * (1 - i / (N - 1)))
            ox, oy = FW * (i // ROWS), FH * (i % ROWS)
            for y in range(FH):
                sheet[oy + y][ox:ox + FW] = f[y]
        png(out, FW * COLS, FH * ROWS, sheet)
