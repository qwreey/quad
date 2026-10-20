#!/usr/bin/env python3
"""[2026-10-20 kit trial] pf-stats.py <tsv>... — median / p90 / max wall and RSS per perfile.py TSV, plus files whose own lines carry diagnostics and runs with any too-complex."""
import statistics, sys
for p in sys.argv[1:]:
    rows = [l.rstrip("\n").split("\t") for l in open(p) if l.strip()]
    w = sorted(float(r[1]) for r in rows); m = sorted(int(r[2]) for r in rows)
    q = lambda a, f: a[min(len(a) - 1, int(f * len(a)))]
    diag = sum(1 for r in rows if int(r[3]) > 0); tc = sum(1 for r in rows if int(r[4]) > 0)
    top = sorted(rows, key=lambda r: -float(r[1]))[:3]
    print(f"{p.split('/')[-1]:18s} n={len(rows)} wall med {statistics.median(w):.2f}s p90 {q(w,.9):.2f}s max {w[-1]:.2f}s sum {sum(w):.0f}s | RSS med {statistics.median(m)} p90 {q(m,.9)} max {m[-1]} MiB | files w/ own diag {diag} | runs w/ too-complex {tc} | slowest " + ", ".join(f"{r[0].split('/',1)[1]} {float(r[1]):.2f}" for r in top))
