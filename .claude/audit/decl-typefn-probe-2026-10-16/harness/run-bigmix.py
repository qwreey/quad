#!/usr/bin/env python3
"""[2026-10-20 3.4.0 unit 0] run-bigmix.py <mode> <file>: one run-cli.sh process, prints time / child max RSS / too complex /
NEG lines caught (of the planted 8 at the end) / other diagnostics (non-Unused)."""
import sys, subprocess, time, resource, pathlib, re
mode, f = sys.argv[1], sys.argv[2]
here = pathlib.Path(__file__).parent
src = pathlib.Path(f).read_text().splitlines()
neg_lines = {i + 1 for i, l in enumerate(src) if "-- NEG" in l}
t = time.time()
r = subprocess.run([str(here / "run-cli.sh"), mode, f], capture_output=True, text=True)
dt = time.time() - t
rss = resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss // 1024
diag = [l for l in (r.stdout + r.stderr).splitlines() if "Unused" not in l and re.search(r"\(\d+,\d+\)", l)]
lines = {int(re.search(r"\((\d+),", l).group(1)) for l in diag}
tc = sum("too complex" in l.lower() for l in diag)
caught = len(neg_lines & lines)
other = sorted(lines - neg_lines)
print(f"{mode} {pathlib.Path(f).name}: {dt:.2f}s {rss}MiB too_complex={tc} NEG {caught}/{len(neg_lines)} other_lines={other[:12]}{'…' if len(other)>12 else ''}")
