#!/usr/bin/env python3
"""Differential: the CheckVersion type function (compile time) vs matchesPattern (runtime) on a fuzz sample.
Writes typefn_cases.luau, runs luau-analyze, maps errors back by line."""
import os, re, subprocess, sys, random
K = int(sys.argv[1]) if len(sys.argv) > 1 else 600
sys.argv = [sys.argv[0], '6000', '36']
import fuzz, repros  # repros prints its table; harmless

HERE = fuzz.HERE
pairs = [(a, p) for a, p in fuzz.gen() if a.isascii() and p.isascii()]
random.Random(7).shuffle(pairs)
pairs = pairs[:K] + [(a, p) for _, a, p in repros.CASES if a.isascii() and p.isascii()]
real = fuzz.run_luau(pairs)
CH = 40
os.makedirs(os.path.join(HERE, 'typefn_cases'), exist_ok=True)
bad = set(); other = []
for c0 in range(0, len(pairs), CH):
    lines = ['--!strict', 'local TVC = require("../../../../type-version-check/src")']
    for a, p in pairs[c0:c0 + CH]:
        lines.append('local _: TVC.CheckVersion<%s, %s> = true' % (fuzz.luau_lit(a), fuzz.luau_lit(p)))
    fn = 'typefn_cases/chunk%04d.luau' % (c0 // CH)
    open(os.path.join(HERE, fn), 'w').write('\n'.join(lines) + '\n')
    out = subprocess.run(['luau-analyze', fn], capture_output=True, text=True, cwd=HERE)
    for l in (out.stdout + out.stderr).splitlines():
        m = re.match(r'^\.?/?' + re.escape(fn) + r'\((\d+),\d+\): TypeError: Expected this to be unreachable', l)
        if m:
            bad.add(c0 + int(m.group(1)) - 3)
        elif l.strip():
            other.append(l)
diff = []
for i, ((a, p), r) in enumerate(zip(pairs, real)):
    tf = i not in bad
    if tf != r:
        diff.append((a, p, r, tf))
print('typefn sample', len(pairs), 'diverge', len(diff), 'real_true', sum(1 for r in real if r is True))
for d in diff[:20]:
    print('  DIFF', d)
print('non-location output lines:', len(other), other[:5])
