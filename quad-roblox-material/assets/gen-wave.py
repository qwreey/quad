#!/usr/bin/env python3
"""WavyProgress textures (pure Python, no deps).

  gen-wave.py single <out.png>   one wavelength, 512x128, full amplitude (the original upload)
  gen-wave.py sheet  <out.png>   amplitude sprite sheet, 1024x1024: 24 frames of 480x64 (one wavelength each) in
                                 2 columns x 12 rows, COLUMN-major, spread over the whole 1024 with gutters:
                                 frame i -> ImageRectOffset (512 * (i // 12) + 16, 85 * (i % 12) + 10), ImageRectSize (480, 64)
                                 GUTTERS (user Studio check 2026-10-07: cells packed edge to edge showed specks at the
                                 frame ends — texture filtering samples the neighbour cell): 16 px left/right of each
                                 frame hold the SAME wave continued periodically (a sample past the edge reads the right
                                 pixel), 10 px above / 11 px below are transparent (the stroke touches the frame's top and
                                 bottom at full amplitude). Gutters this wide because the frame is drawn ~6-8x smaller
                                 than it is stored (a 10 px bar) — at that scale the engine samples a coarser mip level,
                                 whose texels reach several source pixels past the frame edge.
                                 The stroke is drawn for a 4:1 DISPLAY aspect (the default Wavelength 40 x height 10):
                                 the 480x64 frame is stretched anisotropically on screen, so the stroke is shaped in that
                                 space (u = x * 256 / 480) to keep its width even on the slopes.
                                 frame 0 = full amplitude, frame 23 = flat; amplitude(i) = 0.3H * (1 - i / 23) (linear —
                                 ease in time, not in the sheet)

Shape rule (shared by both, and by the cap math in src/Progress/Wavy.luau): one wavelength W wide, height H,
centre line H/2, y(x) = H/2 - A sin(2 pi x / W), stroke width 0.4H, full A = 0.3H; starts at the centre line going UP
at x = 0 and tiles seamlessly in x. White stroke on transparent, anti-aliased by exact distance to the curve.
"""
import math, zlib, struct, sys

def frame(W, H, amp, x0=0, w_out=None, shape_w=None):
    # shape_w: the wavelength the stroke is DESIGNED at (default W). A frame stored at W px but shown stretched to an
    # aspect of shape_w : H must draw its stroke in that display space, or the anisotropic stretch thins the stroke on
    # the slopes — so distances are measured with x mapped to u = x * shape_w / W.
    Wv = shape_w or W
    k = Wv / W
    half = 0.4 * H / 2
    cy = H / 2
    S = 8
    pts = [(i / S, cy - amp * math.sin(2 * math.pi * (i / S) / Wv)) for i in range(-Wv * S, 2 * Wv * S)]
    win = int((half + 2) * S)
    out = []
    for y in range(H):
        py = y + 0.5
        row = []
        for x in range(x0, x0 + (w_out or W)):
            pu = (x + 0.5) * k
            c = int((pu + Wv) * S)
            best = 1e9
            for i in range(c - win, c + win + 1):
                qx, qy = pts[i]
                d = (qx - pu) ** 2 + (qy - py) ** 2
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
        FW, FH, ROWS, COLS = 480, 64, 12, 2
        PX, PY, PADX, PADY = 512, 85, 16, 10
        N = ROWS * COLS
        sheet = [[0] * 1024 for _ in range(1024)]
        for i in range(N):
            f = frame(FW, FH, 0.3 * FH * (1 - i / (N - 1)), -PADX, FW + 2 * PADX, 4 * FH)
            ox, oy = PX * (i // ROWS), PY * (i % ROWS) + PADY
            for y in range(FH):
                sheet[oy + y][ox:ox + FW + 2 * PADX] = f[y]
        png(out, 1024, 1024, sheet)
