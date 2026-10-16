#!/usr/bin/env python3
"""Q6: time each generated cost file under each mode, one process at a time (conventions.md memory
rules — run-cli.sh applies choom 1000 + prlimit 3 GiB). Wall time and child max RSS via getrusage.
  cost-run.py <dir> <mode...>
"""
import os, resource, subprocess, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
d = sys.argv[1]
for f in sorted(os.listdir(d)):
    if not f.endswith(".luau"):
        continue
    for m in sys.argv[2:]:
        t0 = time.time()
        p = subprocess.Popen([os.path.join(HERE, "run-cli.sh"), m, f], cwd=d, stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT, text=True)
        out = p.stdout.read()
        _, _, ru = os.wait4(p.pid, 0)  # rusage of this run's subtree only
        wall = time.time() - t0
        rss = ru.ru_maxrss  # KiB — largest process in the subtree (the analyzer)
        te = sum(1 for l in out.splitlines() if l.startswith(f) and "TypeError" in l)
        lines = open(os.path.join(d, f)).read().splitlines()
        neg = [i + 1 for i, l in enumerate(lines) if l.endswith("-- NEG")]
        caught = sum(1 for n in neg if f"{f}({n}," in out)
        tc = out.count("too complex")
        print(f"{f:34s} {m:7s} wall={wall:6.2f}s maxrss={rss // 1024:5d}MiB typeErrors(in file)={te} NEG caught={caught}/{len(neg)} tooComplex(any)={tc}", flush=True)
