#!/usr/bin/env python3
"""E73: re-apply each SURVIVED mutant (plus E69's PR10/BK02/BK04/BK06 and the BK02+BK04 / BK04+BK06 pairs),
relink, run probe.e73.luau (quad-base) and probe.e73r.luau (quad-roblox). Usage: probe_survivors.py <worktree>"""
import sys, os, json, subprocess, shutil
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
from mutants import M
import importlib.util
spec = importlib.util.spec_from_file_location("m69", os.path.join(here, "..", "round13-e69-mutation", "mutants.py"))
m69 = importlib.util.module_from_spec(spec); spec.loader.exec_module(m69)
E69 = {m[0]: m for m in m69.M}
wt = os.path.abspath(sys.argv[1])
shutil.copy(os.path.join(here, "probe.e73.luau"), f"{wt}/quad-base/test/probe.e73.luau")
shutil.copy(os.path.join(here, "probe.e73r.luau"), f"{wt}/quad-roblox/test/probe.e73r.luau")
surv = [r["id"] for r in json.load(open(os.path.join(here, "results.json"))) if r["status"] == "SURVIVED"]
byid = {m[0]: m for m in M}
groups = [[i] for i in surv] + [["PR10"], ["BK02"], ["BK04"], ["BK06"], ["BK02", "BK04"], ["BK04", "BK06"], ["ST04"], ["SR05"], ["ST09"]]
def relink(): subprocess.run(["./scripts/relink.sh"], cwd=wt, capture_output=True)
def run(p):
    try:
        r = subprocess.run(["luau", p], cwd=wt, capture_output=True, text=True, timeout=60)
        out = (r.stdout + r.stderr).strip().splitlines()
    except subprocess.TimeoutExpired:
        out = ["TIMEOUT"]
    return [l for l in out if l.startswith("FAIL") or "OK" in l] or out[-3:]
out = {}
for g in groups:
    saved = {}
    for mid in g:
        _, f, line, old, new = byid.get(mid) or E69[mid]
        fp = os.path.join(wt, f)
        if fp not in saved: saved[fp] = open(fp).read()
        lines = open(fp).read().split("\n")
        assert old in lines[line - 1], (mid, lines[line - 1])
        lines[line - 1] = lines[line - 1].replace(old, new, 1) if new is not None else ""
        open(fp, "w").write("\n".join(lines))
    relink()
    res = {"base": run("quad-base/test/probe.e73.luau"), "roblox": run("quad-roblox/test/probe.e73r.luau")}
    for fp, src in saved.items(): open(fp, "w").write(src)
    key = "+".join(g); out[key] = res
    print(key, " | ".join(res["base"] + res["roblox"])[:400], flush=True)
relink()
os.remove(f"{wt}/quad-base/test/probe.e73.luau"); os.remove(f"{wt}/quad-roblox/test/probe.e73r.luau")
json.dump(out, open(os.path.join(here, "probe-results.json"), "w"), ensure_ascii=False, indent=1)
