#!/usr/bin/env python3
"""E62 aggregator: parse raw/<tree>-<probe>-r<i>.txt tables; per (probe, section, rowkey, col) collect values
across runs; print median/min for base and head plus ratio head/base (median)."""
import re, sys, glob, os, statistics as st
S = os.path.dirname(os.path.abspath(__file__)); RAW = os.path.join(S, "raw")
num = re.compile(r"^-?\d+(\.\d+)?$")
def parse(path):
    out = {}; sec = "?"; hdr = None
    for line in open(path, encoding="utf-8", errors="replace"):
        line = line.rstrip("\n")
        if line.startswith("==="): sec = line.strip("= ").split(":")[0].split(" —")[0]; hdr = None; continue
        toks = line.split()
        if not toks: continue
        # bench: "B4 :List ... 90.217 ms"
        m = re.match(r"^(B\d+ .*?)\s+(-?\d+\.\d+) ms$", line)
        if m: out[("bench", m.group(1).strip(), "ms")] = float(m.group(2)); continue
        nums = [i for i, t in enumerate(toks) if num.match(t)]
        if not nums: hdr = toks; continue
        # key = leading non-numeric tokens + first numeric (N/d) if first numeric col is a size param
        k0 = [t for t in toks[:nums[0]]]
        keyn = 1 if (hdr and hdr[0] in ("d", "N", "f", "outerN", "propsPerItem")) or (k0 and len(nums) > 1 and toks[nums[0]].isdigit()) else 0
        if hdr and hdr[0] == "d": keyn = 2
        key = " ".join(toks[:nums[0] + keyn]) if keyn else " ".join(k0)
        cols = hdr[len(hdr) - (len(toks) - nums[0] - keyn):] if hdr else None
        for j, t in enumerate(toks[nums[0] + keyn:]):
            if num.match(t):
                cn = cols[j] if cols and j < len(cols) else f"c{j}"
                out[(sec, key, cn)] = float(t)
    return out
data = {}
for f in sorted(glob.glob(os.path.join(RAW, "*-r*.txt"))):
    b = os.path.basename(f)[:-4]; tree, rest = b.split("-", 1); probe, r = rest.rsplit("-r", 1)
    for k, v in parse(f).items(): data.setdefault((probe,) + k, {}).setdefault(tree, []).append(v)
for k in sorted(data):
    d = data[k]; b = d.get("base", []); h = d.get("head", [])
    if not b or not h: continue
    const = len(set(b)) == 1 and len(set(h)) == 1
    mb, mh = st.median(b), st.median(h)
    ratio = (mh / mb) if mb else float("nan")
    tag = "CONST" if const else "VAR"
    print(f"{k[0]:12s} | {k[1][:22]:22s} | {k[2][:40]:40s} | {k[3][:14]:14s} | base med {mb:.6g} min {min(b):.6g} n{len(b)} | head med {mh:.6g} min {min(h):.6g} n{len(h)} | x{ratio:.3f} {tag}")
