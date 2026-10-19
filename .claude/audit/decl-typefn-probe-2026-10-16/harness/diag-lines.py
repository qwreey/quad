#!/usr/bin/env python3
"""[2026-10-19] Summarise `run-cli.sh` output per source line: `file:line  count  first-message-line`.

  harness/run-cli.sh sync <file> | harness/diag-lines.py [--src <file>]

With --src, every line carrying a `-- NEG` / `-- should error` tag is listed with HIT/MISS, and
every line carrying `-- OK` is listed with CLEAN/NOISE — so a run reads as a NEG/OK tally
(one-line markers only; multi-line markers produced 0-hit traps in round 1).
"""
import re
import sys
from collections import OrderedDict

args = sys.argv[1:]
src = None
if args[:1] == ["--src"]:
    src = args[1]
pat = re.compile(r"^(?P<f>[^\s(]+)\((?P<l>\d+),(?P<c>\d+)\): (?P<m>.*)$")
hits = OrderedDict()
# lint warnings (LocalUnused, …) are not type results — counted, not listed
LINT = re.compile(r"^(?!TypeError|SyntaxError)[A-Z][A-Za-z]+: ")
lints = 0
tc = 0
cur = None
for raw in sys.stdin:
    line = raw.rstrip("\n")
    m = pat.match(line)
    if m and LINT.match(m["m"]):
        cur = None
        lints += 1
        continue
    if m:
        key = (m["f"], int(m["l"]))
        msg = m["m"]
        if "too complex" in msg:
            tc += 1
        e = hits.setdefault(key, [0, msg, None])
        e[0] += 1
        cur = e
    elif cur is not None and cur[2] is None and line.strip():
        cur[2] = line.strip()
for (f, l), (n, msg, nxt) in hits.items():
    tail = (" | " + nxt[:160]) if nxt else ""
    print(f"{f.split('/')[-1]}:{l}  x{n}  {msg[:200]}{tail}")
print(f"# lines with diagnostics: {len(hits)}  too-complex: {tc}  (lint warnings skipped: {lints})")
if src:
    lines = open(src).read().split("\n")
    errlines = {l for (f, l) in hits if f.endswith(src.split('/')[-1])}
    neg_hit = neg_miss = ok_clean = ok_noise = 0
    for i, t in enumerate(lines, 1):
        if t.strip().startswith("--"):
            continue
        if re.search(r"--.*\b(NEG|should error)", t):
            ok = i in errlines
            neg_hit += ok
            neg_miss += not ok
            print(f"  NEG L{i}: {'HIT ' if ok else 'MISS'}  {t.strip()[:110]}")
        elif re.search(r"--.*\bOK\b", t):
            bad = i in errlines
            ok_noise += bad
            ok_clean += not bad
            if bad:
                print(f"  OK  L{i}: NOISE {t.strip()[:110]}")
    print(f"# NEG {neg_hit}/{neg_hit + neg_miss}  OK clean {ok_clean}/{ok_clean + ok_noise}")
