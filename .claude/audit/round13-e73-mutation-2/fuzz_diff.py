#!/usr/bin/env python3
"""Run fuzz.e73.luau on the original and on each of E69's ST04/SR05/ST09 (and ST04+SR05); diff per seed.
Usage: fuzz_diff.py <worktree>"""
import sys, os, subprocess, shutil, importlib.util, json
here = os.path.dirname(os.path.abspath(__file__)); wt = os.path.abspath(sys.argv[1])
spec = importlib.util.spec_from_file_location("m69", os.path.join(here, "..", "round13-e69-mutation", "mutants.py"))
m69 = importlib.util.module_from_spec(spec); spec.loader.exec_module(m69); E69 = {m[0]: m for m in m69.M}
dst = f"{wt}/quad-base/test/fuzz.e73.luau"; shutil.copy(os.path.join(here, "fuzz.e73.luau"), dst)
def run():
    r = subprocess.run(["luau", "quad-base/test/fuzz.e73.luau"], cwd=wt, capture_output=True, text=True, timeout=600)
    assert r.returncode == 0, r.stderr[-500:]
    return r.stdout.strip().split("\n")
# subscriber iteration is a hash order that can differ between processes: run the baseline 5x and keep
# only the seeds whose trace is identical every time ("stable"); mutants are compared on those only
runs = [run() for _ in range(5)]
base = runs[0]
stable = [i for i in range(len(base)) if all(r[i] == base[i] for r in runs)]
res = {"seeds": len(base), "stable_seeds": len(stable), "errors_in_baseline": sum("ERR" in l for l in base)}
for g in (["ST04"], ["SR05"], ["ST09"], ["ST04", "SR05"]):
    saved = {}
    for mid in g:
        _, f, line, old, new = E69[mid]; fp = os.path.join(wt, f)
        saved.setdefault(fp, open(fp).read())
        L = open(fp).read().split("\n"); assert old in L[line - 1]; L[line - 1] = L[line - 1].replace(old, new, 1) if new is not None else ""
        open(fp, "w").write("\n".join(L))
    gots = [run() for _ in range(3)]
    for fp, s in saved.items(): open(fp, "w").write(s)
    # a seed counts only if the mutant differs from the stable baseline in all 3 mutant runs
    diff = [i + 1 for i in stable if all(g[i] != base[i] for g in gots)]
    got = gots[0]
    res["+".join(g)] = {"differing_seeds": len(diff), "first": diff[:10],
                        "example": [base[diff[0] - 1][:300], got[diff[0] - 1][:300]] if diff else None}
    print("+".join(g), len(diff), diff[:10], flush=True)
os.remove(dst)
json.dump(res, open(os.path.join(here, "fuzz-results.json"), "w"), ensure_ascii=False, indent=1)
print(res["seeds"], "seeds,", res["stable_seeds"], "stable; baseline trace lines with ERR:", res["errors_in_baseline"])
