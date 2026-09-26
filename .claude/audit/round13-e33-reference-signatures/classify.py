#!/usr/bin/env python3
"""E33: map probe diagnostics back to doc items; flag 'identical-print' (solver generic-function
subtyping limit: expected/got print the same) vs real mismatch."""
import json, re, sys
probe = sys.argv[1] if len(sys.argv) > 1 else "probe_sigs"
m = json.load(open(f"{probe.replace('probe_sigs','probe')}_map.json" if False else "probe_map.json"))["lines"] if probe == "probe_sigs" else {}
src = open(f"{probe}.luau").read().split("\n")
out = open(f"{probe}.out").read()
res = []
for blk in re.split(r"\n(?=\S+\.luau\()", out):
    mm = re.search(r"\.luau\((\d+),(\d+)\): (\w+): (.*)", blk, re.S)
    if not mm or mm.group(3) in ("FunctionUnused", "LocalUnused"): continue
    ln = int(mm.group(1)); msg = mm.group(4)
    e = re.search(r"Expected this to be\s*\n?\s*'(.*?)'\s*\n?\s*but got\s*\n?\s*'(.*?)'", msg, re.S)
    kind = "mismatch"
    if e and e.group(1) == e.group(2): kind = "identical-print"
    elif e and "TRUNCATED" in msg:
        a = msg.split("but got")
        # compare the untruncated prefix
        kind = "identical-prefix(truncated)" if a[0].split("'")[1][:250] == a[1].split("'")[1][:250] else "mismatch"
    elif "inference failed" in msg: kind = "global"
    res.append((ln, m.get(str(ln)), kind, src[ln-1].strip()[:110], msg.strip().split("\n")[0][:160]))
for r in res: print(*r, sep=" | ")
