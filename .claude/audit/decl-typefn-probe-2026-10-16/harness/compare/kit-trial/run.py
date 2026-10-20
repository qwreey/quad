#!/usr/bin/env python3
"""[2026-10-20 kit trial] run run-cli.sh <mode> over a kit-trial variant tree, one process at a time.
  run.py <variant-dir> <mode> <outfile> <target...>
Wall time and max RSS (wait4 rusage of this run's subtree). Ignores mirror the kits' test/run.sh strict pass:
luau_packages, test/support, gallery/*.client.luau. Raw output → <outfile>, one summary line → stdout.
"""
import os, subprocess, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
RUN = os.path.join(HERE, "..", "..", "run-cli.sh")
d, mode, outf, *targets = sys.argv[1:]
args = [RUN, mode, "--ignore", "**/luau_packages/**", "--ignore", "*/test/support/**",
        "--ignore", "*/gallery/*.client.luau", *targets]
t0 = time.time()
p = subprocess.Popen(args, cwd=d, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
out = p.stdout.read()
_, status, ru = os.wait4(p.pid, 0)
wall = time.time() - t0
open(outf, "w").write(out)
te = sum(1 for l in out.splitlines() if ": TypeError" in l)
tc = out.count("too complex")
print(f"{os.path.basename(outf)} mode={mode} wall={wall:.2f}s maxrss={ru.ru_maxrss // 1024}MiB TypeError-lines={te} tooComplex={tc} exit={os.waitstatus_to_exitcode(status)}", flush=True)
