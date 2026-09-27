#!/usr/bin/env python3
"""Re-apply each SURVIVED mutant and run probe.e69.luau (copied into <wt>/quad-base/test/) against it."""
import sys, os, json, subprocess, shutil
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
from mutants import M
wt = os.path.abspath(sys.argv[1])
shutil.copy(os.path.join(here, "probe.e69.luau"), f"{wt}/quad-base/test/probe.e69.luau")
surv = {r["id"] for r in json.load(open(os.path.join(here, "results.json"))) if r["status"] == "SURVIVED"}
out = {}
for mid, f, line, old, new in M:
    if mid not in surv: continue
    fp = os.path.join(wt, f); src = open(fp).read(); lines = src.split("\n")
    lines[line - 1] = lines[line - 1].replace(old, new, 1) if new is not None else ""
    open(fp, "w").write("\n".join(lines))
    p = subprocess.run(["luau", "quad-base/test/probe.e69.luau"], cwd=wt, capture_output=True, text=True, timeout=60)
    open(fp, "w").write(src)
    res = (p.stdout + p.stderr).strip().splitlines()
    res = [l for l in res if l.startswith("FAIL") or "OK" in l] or res[-3:]
    out[mid] = res
    print(mid, " | ".join(res)[:300], flush=True)
os.remove(f"{wt}/quad-base/test/probe.e69.luau")
json.dump(out, open(os.path.join(here, "probe-results.json"), "w"), ensure_ascii=False, indent=1)
