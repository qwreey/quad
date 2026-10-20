#!/usr/bin/env python3
"""[2026-10-20 kit trial] neg-tally.py <injected.json> <run-output.txt> [--miss] — how many injected ZZNEG lines got a diagnostic."""
import json, re, sys
inj = json.load(open(sys.argv[1]))
errs = set()
for l in open(sys.argv[2], encoding="utf-8", errors="replace"):
    m = re.match(r"^([^\s(]+)\((\d+),\d+\): (TypeError|SyntaxError)", l)
    if m:
        errs.add((m.group(1), int(m.group(2))))
miss = [x for x in inj if (x[0], x[1]) not in errs]
parts = {}
for f, l in inj:
    k = f.split("/")[1]
    h, t = parts.get(k, (0, 0))
    parts[k] = (h + ((f, l) in errs), t + 1)
print(f"{sys.argv[2].split('/')[-1]}: ZZNEG hit {len(inj) - len(miss)}/{len(inj)}  " + "  ".join(f"{k} {h}/{t}" for k, (h, t) in sorted(parts.items())))
if "--miss" in sys.argv:
    for f, l in miss:
        print("   MISS", f, l)
