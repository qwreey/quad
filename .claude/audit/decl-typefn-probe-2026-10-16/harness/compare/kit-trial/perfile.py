#!/usr/bin/env python3
"""[2026-10-20 kit trial] cold per-file cost: one run-cli.sh process per file (the file plus everything it requires),
sequential (conventions.md memory rules — run-cli.sh carries choom 1000 + prlimit 3 GiB).
  perfile.py <variant-dir> <mode> <out.tsv> <file...>
TSV: file  wall_s  maxrss_MiB  kit_diag_lines_in_file  too_complex_any
"""
import os, re, subprocess, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
RUN = os.path.join(HERE, "..", "..", "run-cli.sh")
d, mode, outf, *files = sys.argv[1:]
with open(outf, "w") as fo:
    for f in files:
        t0 = time.time()
        p = subprocess.Popen([RUN, mode, "--ignore", "**/luau_packages/**", f], cwd=d, stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT, text=True)
        out = p.stdout.read()
        _, _, ru = os.wait4(p.pid, 0)
        wall = time.time() - t0
        own = {l.split(":")[0] for l in out.splitlines() if l.startswith(f + "(") and re.search(r": (TypeError|SyntaxError)", l)}
        lines = {re.match(r"^[^(]+\((\d+)", l).group(1) for l in out.splitlines() if l.startswith(f + "(") and re.search(r": (TypeError|SyntaxError)", l)}
        fo.write(f"{f}\t{wall:.3f}\t{ru.ru_maxrss // 1024}\t{len(lines)}\t{out.count('too complex')}\n")
        fo.flush()
