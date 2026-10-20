#!/usr/bin/env python3
"""[2026-10-20 kit trial] summarise run.py raw outputs.
  summarize.py <variant-root> <out.txt>... [--lines]
Per output: canary NEG/OK (src/ZzCanary.luau one-line markers), kit diagnostics as unique (file, line) — split
src/gallery/test/stories — too-complex unique lines, dependency (non-kit) lines, and a message-kind histogram.
Lint warnings (LocalUnused …) are skipped. --lines lists every unique kit (file:line  first message).
"""
import os, re, sys
from collections import Counter, OrderedDict
pat = re.compile(r"^(?P<f>[^\s(]+)\((?P<l>\d+),(?P<c>\d+)\): (?P<k>TypeError|SyntaxError): (?P<m>.*)$")
args = sys.argv[1:]
show = "--lines" in args
args = [a for a in args if a != "--lines"]
root, outs = args[0], args[1:]


def kind(msg: str) -> str:
    if "too complex" in msg:
        return "too complex"
    for k, r in [
        ("unknown key / missing prop", r"(not found in table|does not have key|Key '.*' is missing|Cannot add property)"),
        ("type mismatch (Expected …)", r"^Expected this to be|^Type .* could not be converted|is not a subtype"),
        ("call arity", r"(expects \d+ argument|Argument count mismatch)"),
        ("ambiguous call", r"is ambiguous"),
        ("cannot call", r"Cannot call"),
        ("unknown require/global", r"(Unknown require|Unknown global|Unknown type)"),
        ("type function", r"[Tt]ype function"),
        ("generic instantiation", r"instantiate"),
    ]:
        if re.search(r, msg):
            return k
    return "other: " + msg[:60]


for o in outs:
    hits = OrderedDict()
    for line in open(o, encoding="utf-8", errors="replace"):
        m = pat.match(line.rstrip("\n"))
        if not m:
            continue
        key = (m["f"], int(m["l"]))
        hits.setdefault(key, []).append(m["m"])
    canary = {k: v for k, v in hits.items() if k[0].endswith("ZzCanary.luau")}
    kit = {k: v for k, v in hits.items() if re.match(r"quad-roblox-(material|devui)/", k[0]) and not k[0].endswith("ZzCanary.luau")}
    dep = {k: v for k, v in hits.items() if k not in canary and k not in kit}
    # canary tally
    cf = None
    for k in hits:
        if k[0].endswith("ZzCanary.luau"):
            cf = k[0]
    tally = ""
    cfs = [os.path.join(root, d, "src/ZzCanary.luau") for d in ("quad-roblox-material", "quad-roblox-devui")]
    for c in cfs:
        rel = os.path.relpath(c, root)
        if not os.path.exists(c) or not any(rel in l for l in [o]) and rel.split("/")[0] not in o and False:
            continue
    kitname = "quad-roblox-material" if "-mat-" in os.path.basename(o) else "quad-roblox-devui"
    crel = f"{kitname}/src/ZzCanary.luau"
    cpath = os.path.join(root, crel)
    if os.path.exists(cpath):
        L = open(cpath).read().split("\n")
        errl = {l for (f, l) in canary}
        nh = nm = oc = on = 0
        for i, t in enumerate(L, 1):
            if t.strip().startswith("--"):
                continue
            if re.search(r"--.*\bNEG\b", t):
                nh += i in errl; nm += i not in errl
            elif re.search(r"--.*\bOK\b", t):
                on += i in errl; oc += i not in errl
        tally = f"canary NEG {nh}/{nh+nm} OK {oc}/{oc+on}"
    parts = Counter()
    for (f, l) in kit:
        parts[f.split("/")[1]] += 1
    tc = sum(1 for v in kit.values() if any("too complex" in x for x in v))
    tcd = sum(1 for v in dep.values() if any("too complex" in x for x in v))
    kinds = Counter(kind(v[0]) for v in kit.values())
    files = len({f for (f, l) in kit})
    print(f"{os.path.basename(o)}: {tally} | kit lines {len(kit)} in {files} files ({dict(parts)}) too-complex lines {tc}"
          f" | dependency lines {len(dep)} (too-complex {tcd})")
    for k, n in kinds.most_common():
        print(f"    {n:4d}  {k}")
    if show:
        for (f, l), v in kit.items():
            print(f"      {f}:{l}  x{len(v)}  {v[0][:230]}")
