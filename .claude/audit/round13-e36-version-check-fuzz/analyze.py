#!/usr/bin/env python3
"""Recompute divergences with token attribution and shrink one repro per (predicate, token) class."""
import json, os, re, sys, collections
seed_n = int(sys.argv[1]) if len(sys.argv) > 1 else 6000
seed = int(sys.argv[2]) if len(sys.argv) > 2 else 36
sys.argv = [sys.argv[0], str(seed_n), str(seed)]
import fuzz, refs


def tok(a, p):
    toks = set()
    for s in (a, p):
        s = s.split('+', 1)[0]
        for part in re.split(r'[.|-]', s):
            t = part.rstrip('^')
            if t != '' and refs.numeric(t, 'luau') is not None and refs.numeric(t, 'digits') is None:
                toks.add(repr(t))
            elif refs.numeric(t, 'digits') is not None and len(t) >= 16:
                toks.add('<16+ digits>')
    return ', '.join(sorted(toks)) or '<none>'


pairs = fuzz.gen()
real = fuzz.run_luau(pairs)
res = {}
for name, fn in fuzz.PREDS.items():
    by = collections.defaultdict(list)
    for (a, p), r in zip(pairs, real):
        ref = fn(a, p)
        if ref != r:
            key = tok(a, p) if not name.startswith('rbx') else 'real=%s ref=%s' % (r, ref)
            by[key].append((a, p, r, ref))
    res[name] = by
    print('==', name, sum(len(v) for v in by.values()))
    for k, v in sorted(by.items(), key=lambda kv: -len(kv[1])):
        v.sort(key=lambda t: len(t[0]) + len(t[1]))
        a, p, r, ref = v[0]
        diff = lambda x, y: (lambda rr: isinstance(rr, bool) and rr != fn(x, y))(fuzz.run_luau([(x, y)])[0])
        ma, mp = fuzz.shrink(a, p, diff)
        print('  %4d  %-28s shortest=(%r, %r)  shrunk=(%r, %r) real=%s ref=%s' % (
            len(v), k, a, p, ma, mp, fuzz.run_luau([(ma, mp)])[0], fn(ma, mp)))
