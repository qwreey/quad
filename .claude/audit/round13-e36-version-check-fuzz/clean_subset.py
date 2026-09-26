#!/usr/bin/env python3
"""Divergence restricted to pairs whose places are all well-formed (ASCII digits < 2^53, words, *, N^)."""
import re, sys
seeds = [36, 37, 38, 39, 40]
sys.argv = sys.argv[:1] + ['6000', '36']
import fuzz, refs, random
OK = re.compile(r'^([0-9]{1,15}|[0-9]{1,15}\^|\*|rc|dev|beta|alpha|RC|rc-1)$')
tot = cl = dv = dvp = 0
for s in seeds:
    fuzz.rng = random.Random(s)
    pairs = fuzz.gen()
    real = fuzz.run_luau(pairs)
    for (a, p), r in zip(pairs, real):
        tot += 1
        parts = []
        for x in (a, p):
            for alt in x.split('|'):
                c, pre = refs.split_build_then_dash(alt)
                parts += c.split('.') + ([] if pre is None else pre.split('.'))
        if all(OK.match(t) for t in parts):
            cl += 1
            dv += refs.ext01(a, p) != r
            dvp += fuzz.cv.matches_pattern(a, p) != r
print('total', tot, 'well-formed subset', cl, 'ext01 diverge', dv, 'python-port diverge', dvp)
