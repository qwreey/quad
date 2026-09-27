#!/usr/bin/env python3
"""E69 mutation driver. Usage: run_mutants.py <worktree> [ids...]
Applies one mutant at a time to a pristine copy, relinks (quad-base -> quad-roblox luau_packages copy),
runs every smoke/spec file (timeout 30s, 8 parallel), records killers, restores the file."""
import sys, os, subprocess, glob, json, time, concurrent.futures as cf
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mutants import M

wt = os.path.abspath(sys.argv[1])
only = set(sys.argv[2:])
specs = sorted(glob.glob(f"{wt}/quad-base/test/smoke.*.luau")) + sorted(glob.glob(f"{wt}/quad-base/test/spec.*.luau")) + sorted(glob.glob(f"{wt}/quad-roblox/test/spec.*.luau"))

def run_spec(path):
    t = time.time()
    try:
        p = subprocess.run(["luau", path], cwd=wt, capture_output=True, text=True, timeout=30)
        out = p.stdout + p.stderr
        ok = p.returncode == 0 and "ALL PASS" in out
        return path, ok, out[-600:], time.time() - t
    except subprocess.TimeoutExpired:
        return path, False, "TIMEOUT", time.time() - t

def run_all():
    with cf.ThreadPoolExecutor(8) as ex:
        return list(ex.map(run_spec, specs))

def relink():
    subprocess.run(["./scripts/relink.sh"], cwd=wt, capture_output=True)

results = []
relink()
base = run_all()
assert all(ok for _, ok, _, _ in base), [p for p, ok, _, _ in base if not ok]
for mid, f, line, old, new in M:
    if only and mid not in only:
        continue
    fp = os.path.join(wt, f)
    src = open(fp).read()
    lines = src.split("\n")
    L = lines[line - 1]
    if old not in L:
        results.append({"id": mid, "file": f, "line": line, "status": "BADSITE", "old": old})
        print(mid, "BADSITE", repr(L[:120])); continue
    lines[line - 1] = L.replace(old, new, 1) if new is not None else ""
    open(fp, "w").write("\n".join(lines))
    cp = subprocess.run(["luau-compile", "--null", fp], capture_output=True, text=True)
    if cp.returncode != 0:
        open(fp, "w").write(src)
        results.append({"id": mid, "file": f, "line": line, "old": old, "new": new, "orig": L.strip(), "status": "UNCOMPILABLE", "killers": [], "sample": (cp.stdout + cp.stderr)[-300:]})
        print(mid, "UNCOMPILABLE", flush=True); continue
    relink()
    t = time.time()
    res = run_all()
    dt = time.time() - t
    open(fp, "w").write(src)
    failing = [os.path.relpath(p, wt) for p, ok, _, _ in res if not ok]
    status = "KILLED" if failing else "SURVIVED"
    sample = next((o for p, ok, o, _ in res if not ok), "")
    results.append({"id": mid, "file": f, "line": line, "old": old, "new": new, "orig": L.strip(), "status": status, "killers": failing, "sample": sample[-300:], "secs": round(dt, 2)})
    print(mid, status, len(failing), f"{dt:.1f}s", flush=True)
relink()
json.dump(results, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "results.json" if not only else "results-partial.json"), "w"), ensure_ascii=False, indent=1)
