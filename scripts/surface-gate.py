#!/usr/bin/env python3
"""surface-gate.py — the 3.4.0 typed-surface gate (`.claude/research/release-3.4.0-plan.md` 단위 2), run by test.sh.

1. NEG/OK fixture: `quad-roblox/test/surface/cases.luau` is analyzed with the repo-pinned luau-lsp + defs (the same
   flags as test.sh's quad-roblox pass). Every line marked `-- NEG` must carry a diagnostic, and no other line may
   (a type checker that gave up — "too complex" — would pass the OK lines silently, so NEG lines are the proof that
   the surface is alive).
2. Class surfaces: a throwaway `quad-roblox/test/surface/_brief.luau` (written from `Surface/Data.luau`'s ModClassMap,
   removed after) prints one `[BRIEF]` line per class; a class whose write surface came out empty (a type function
   cannot pcall — one bad member makes the class `never`) fails.
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FLAGS = ["--flag:LuauSolverV2=true", "--flag:LuauTarjanChildLimit=160000",
         "--flag:LuauSubtypingIterationLimit=100000", "--flag:LuauTypeInferIterationLimit=1000000"]


def analyze(rel):
    cmd = ["mise", "exec", "--", "luau-lsp", "analyze", *FLAGS, "--platform=roblox",
           "--definitions=@roblox=scripts/roblox-defs/globalTypes.d.luau", rel]
    r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    return r.stdout + r.stderr


def fixture():
    rel = "quad-roblox/test/surface/cases.luau"
    src = (ROOT / rel).read_text().splitlines()
    neg = {i + 1 for i, l in enumerate(src) if re.search(r"--\s*NEG\b", l)}
    out = analyze(rel)
    hit = set()
    for m in re.finditer(r"cases\.luau\((\d+),\d+\): (\w+):", out):
        if m.group(2) not in ("LocalUnused", "FunctionUnused"):
            hit.add(int(m.group(1)))
    missed = sorted(neg - hit)
    extra = sorted(hit - neg)
    ok = not missed and not extra and "too complex" not in out.lower()
    print(f"surface-gate fixture: NEG {len(neg & hit)}/{len(neg)}" + (f", missed {missed}" if missed else "")
          + (f", unexpected diagnostics on {extra}" if extra else "") + (", TOO COMPLEX" if "too complex" in out.lower() else ""))
    if extra:
        for l in out.splitlines():
            m = re.search(r"cases\.luau\((\d+),", l)
            if m and int(m.group(1)) in extra:
                print("   ", l[:220])
    return ok


def brief():
    data = (ROOT / "quad-roblox/src/Surface/Data.luau").read_text()
    blk = re.search(r"export type ModClassMap = \{\n(.*?)^\}", data, re.S | re.M).group(1)
    classes = re.findall(r"^\t(\w+):", blk, re.M)
    rel = "quad-roblox/test/surface/_brief.luau"
    path = ROOT / rel
    path.write_text("--!strict\n-- throwaway (scripts/surface-gate.py)\nlocal Surface = require(\"../../src/Surface\")\n"
                    f"type _All = Surface.SurfaceBrief<{' | '.join(classes)}>\nreturn {{}}\n")
    try:
        out = analyze(rel)
    finally:
        path.unlink()
    lines = [l for l in out.splitlines() if "[BRIEF]" in l]
    bad = []
    count = 0
    for l in lines:
        for entry in l.split("[BRIEF] ", 1)[1].split("; "):
            count += 1
            m = re.match(r"(\w+) (\d+)/(\d+)/(\d+) r(\d+)", entry)
            if not m or int(m.group(2)) == 0:
                bad.append(entry)
    errs = [l for l in out.splitlines() if re.search(r"brief\.luau\(\d+,\d+\): TypeError", l) and "[BRIEF]" not in l]
    print(f"surface-gate classes: {count} class surfaces" + (f", EMPTY {bad}" if bad else "") + (f", {len(errs)} type errors" if errs else ""))
    for e in errs[:5]:
        print("   ", e[:220])
    return count == len(classes) and not bad and not errs


ok = fixture()
ok = brief() and ok
sys.exit(0 if ok else 1)
