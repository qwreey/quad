#!/usr/bin/env python3
"""E76: re-run exactly the 48 real-gap mutants (E69 27 + E73 21) against the augmented specs.
Same logic as E69/E73 run_mutants.py (one mutant, luau-compile, relink, all smoke/spec files, restore). Usage: run48.py <wt> <out.json>"""
import sys, os, subprocess, glob, json, time, importlib.util, concurrent.futures as cf
A = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..") + "/"
def load(p):
    s = importlib.util.spec_from_file_location("m" + str(abs(hash(p))), p); m = importlib.util.module_from_spec(s); s.loader.exec_module(m); return {x[0]: x for x in m.M}
m69, m73 = load(A + "round13-e69-mutation/mutants.py"), load(A + "round13-e73-mutation-2/mutants.py")
IDS69 = "EF17 EF18 EF11 OB06 DI07 DI10 SW04 SW07 SW14 SL04 SL06 SL10 BK10 SN01 SN03 BK16 SE01 SI09 TG08 DB01 OP03 OP05 PR10 BK02 BK04 ST04 ST09".split()
IDS73 = "LR03 LR06 LR08 LR10 LR12 LR13 CL06 CL07 CL15 CL16 CL17 SH05 SH06 SH03 EL02 EL04 SH01 SH02 EO12 FB05 DC02".split()
M = [("E69", m69[i]) for i in IDS69] + [("E73", m73[i]) for i in IDS73]
assert len(M) == 48
wt = os.path.abspath(sys.argv[1]); out = sys.argv[2]
specs = sorted(glob.glob(f"{wt}/quad-base/test/smoke.*.luau")) + sorted(glob.glob(f"{wt}/quad-base/test/spec.*.luau")) + sorted(glob.glob(f"{wt}/quad-roblox/test/spec.*.luau"))
def run_spec(path):
    try:
        p = subprocess.run(["luau", path], cwd=wt, capture_output=True, text=True, timeout=30)
        o = p.stdout + p.stderr
        return path, p.returncode == 0 and "ALL PASS" in o, o[-400:]
    except subprocess.TimeoutExpired:
        return path, False, "TIMEOUT"
def run_all():
    with cf.ThreadPoolExecutor(8) as ex: return list(ex.map(run_spec, specs))
def relink(): subprocess.run(["./scripts/relink.sh"], cwd=wt, capture_output=True)
relink(); base = run_all()
assert all(ok for _, ok, _ in base), [p for p, ok, _ in base if not ok]
res = []
for rnd, (mid, f, line, old, new) in M:
    fp = os.path.join(wt, f); src = open(fp).read(); lines = src.split("\n")
    assert old in lines[line - 1], (mid, lines[line - 1])
    lines[line - 1] = lines[line - 1].replace(old, new, 1) if new is not None else ""
    open(fp, "w").write("\n".join(lines))
    cp = subprocess.run(["luau-compile", "--null", fp], capture_output=True, text=True)
    if cp.returncode != 0:
        open(fp, "w").write(src); res.append({"id": mid, "round": rnd, "status": "UNCOMPILABLE"}); continue
    relink(); r = run_all(); open(fp, "w").write(src)
    failing = [os.path.relpath(p, wt) for p, ok, _ in r if not ok]
    sample = next((o for p, ok, o in r if not ok), "")
    st = "KILLED" if failing else "SURVIVED"
    res.append({"id": mid, "round": rnd, "file": f, "line": line, "status": st, "killers": failing, "sample": sample[-300:]})
    print(mid, st, ",".join(os.path.basename(k) for k in failing), flush=True)
relink()
json.dump(res, open(out, "w"), ensure_ascii=False, indent=1)
print("KILLED", sum(r["status"] == "KILLED" for r in res), "/", len(res))
