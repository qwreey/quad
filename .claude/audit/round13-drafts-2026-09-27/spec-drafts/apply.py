#!/usr/bin/env python3
"""Apply spec-drafts/*.additions.luau into a worktree: insert before the LAST `print("=== ALL PASS ===")` of the target.
New whole files (spec-drafts/new.<name>.luau) are copied as <pkg>/test/<name>.luau. Usage: apply.py <drafts> <worktree>"""
import sys, os, glob, subprocess
drafts, wt = sys.argv[1], sys.argv[2]
subprocess.run(["git", "checkout", "--", "quad-base/test", "quad-roblox/test"], cwd=wt)
for f in sorted(glob.glob(f"{drafts}/*.additions.luau")):
    name = os.path.basename(f).replace(".additions.luau", ".luau")
    tgt = next(p for p in (f"{wt}/quad-base/test/{name}", f"{wt}/quad-roblox/test/{name}") if os.path.exists(p))
    src = open(tgt).read(); add = open(f).read()
    i = max(src.rfind('print("=== ALL PASS ===")'), src.rfind('print("ALL PASS")')); assert i >= 0, tgt
    j = src.rfind("print()\n", 0, i)
    if j >= 0 and src[j:i].strip() == "print()": i = j
    open(tgt, "w").write(src[:i] + add.rstrip("\n") + "\n\n" + src[i:])
    print("applied", name)
