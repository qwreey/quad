#!/usr/bin/env python3
"""Differential fuzz: type-version-check matchesPattern (Luau, real) vs doc-transcribed refs (refs.py)
and vs the Python port in scripts/check-version.py.  Usage: python3 fuzz.py [N] [seed]"""
import importlib.util, json, os, random, subprocess, sys, collections
import refs

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '../../..'))
spec = importlib.util.spec_from_file_location('cv', os.path.join(ROOT, 'scripts/check-version.py'))
cv = importlib.util.module_from_spec(spec); spec.loader.exec_module(cv)

N = int(sys.argv[1]) if len(sys.argv) > 1 else 6000
rng = random.Random(int(sys.argv[2]) if len(sys.argv) > 2 else 36)

NUMS = ['0', '1', '2', '3', '4', '9', '10', '12', '03', '007', '00', '4294967296', '99999999999999999999',
        '99999999999999999998', '9007199254740993', '9007199254740992']
ODD = ['', ' 3', '3 ', '+3', '0x10', '16', '1e2', '100', 'inf', 'nan', '3_0', '٣', 'x', 'rc', '*x', '^', '3^^', '-', 'a-b']
WORDS = ['rc', 'dev', 'beta', 'alpha', 'rc-1', 'RC']


def num():
    return rng.choice(NUMS) if rng.random() < 0.85 else rng.choice(ODD)


def place_actual(word_ok):
    r = rng.random()
    if word_ok and r < 0.3:
        return rng.choice(WORDS)
    return num()


def section_actual(k, word_ok):
    return '.'.join(place_actual(word_ok) for _ in range(k))


def derive_place(x):
    r = rng.random()
    if r < 0.3:
        return x
    if r < 0.5:
        return '*'
    if r < 0.85:
        d = refs.numeric(x, 'digits')
        if d is not None:
            return str(max(0, d + rng.choice([-2, -1, 0, 0, 1, 2]))) + '^'
        return rng.choice([x + '^', '^', '0^'])
    return rng.choice(['*', num() + '^', num(), rng.choice(WORDS)])


def section_pattern(sec):
    return '.'.join(derive_place(x) for x in sec.split('.'))


def version():
    k = rng.choice([1, 2, 3, 3, 3, 3, 4, 5])
    core = section_actual(k, False)
    pre = None
    if rng.random() < 0.4:
        pre = section_actual(rng.choice([1, 2, 2, 3]), True) if rng.random() < 0.9 else ''
    build = ('+' + rng.choice(['build.7', 'b-1', 'x+y', '', 'meta'])) if rng.random() < 0.25 else ''
    return core + ('' if pre is None else '-' + pre) + build, core, pre


def pattern_for(core, pre):
    alts = []
    for _ in range(rng.choice([1, 1, 1, 2, 3])):
        c = core
        if rng.random() < 0.15:  # perturb place count
            c = c + '.0' if rng.random() < 0.5 else '.'.join(c.split('.')[:-1])
        pc = section_pattern(c)
        p = pre
        if rng.random() < 0.15:
            p = None if p is not None else rng.choice(['rc.1', 'dev.3', '*', 'rc.*', 'rc.1^', '^'])
        pp = None if p is None else section_pattern(p)
        b = ('+' + rng.choice(['b', 'x-y'])) if rng.random() < 0.15 else ''
        alts.append(pc + ('' if pp is None else '-' + pp) + b)
    return '|'.join(alts)


def luau_lit(s):
    return '"' + ''.join(ch if (ch.isascii() and ch.isalnum()) or ch in '.^*+-|_ ' else ''.join('\\%d' % b for b in ch.encode()) for ch in s) + '"'


def run_luau(pairs):
    with open(os.path.join(HERE, 'cases.luau'), 'w') as f:
        f.write('return {\n' + ''.join('{%s,%s},\n' % (luau_lit(a), luau_lit(p)) for a, p in pairs) + '}\n')
    out = subprocess.run(['luau', os.path.join(HERE, 'runner.luau')], capture_output=True, text=True, cwd=HERE)
    if out.returncode != 0:
        sys.exit(out.stderr)
    lines = out.stdout.rstrip('\n').split('\n')
    assert len(lines) == len(pairs), (len(lines), len(pairs))
    return [l == '1' if l in ('0', '1') else l for l in lines]


def gen():
    pairs = []
    for _ in range(N):
        v, core, pre = version()
        if rng.random() < 0.15:  # fully random pattern, unrelated to v
            _, c2, p2 = version()
            p = pattern_for(c2, p2)
        else:
            p = pattern_for(core, pre)
        pairs.append((v, p))
    return pairs


PREDS = {
    'ext01 (extend/01 = source header = README; core/01 defers)': lambda a, p: refs.ext01(a, p),
    'rbx01 (roblox/01 literal: whole-string . split)': lambda a, p: refs.rbx01(a, p),
    'python port (scripts/check-version.py)': lambda a, p: cv.matches_pattern(a, p),
}


def cause(a, p, real):
    """Attribute a divergence between real and ext01 to one knob."""
    if refs.ext01(a, p, num='luau') == real:
        return 'numeric parse (digits vs Luau tonumber)'
    if refs.ext01(a, p, caret_bad_n='exact') == real:
        return 'N^ with non-numeric N'
    if refs.ext01(a, p, num='luau', caret_bad_n='exact') == real:
        return 'numeric parse + non-numeric N'
    return 'UNEXPLAINED'


def shrink(a, p, differs):
    changed = True
    while changed:
        changed = False
        for which in (0, 1):
            s = (a, p)[which]
            for i in range(len(s)):
                t = s[:i] + s[i + 1:]
                na, np_ = (t, p) if which == 0 else (a, t)
                if differs(na, np_):
                    a, p = na, np_
                    changed = True
                    break
            if changed:
                break
    return a, p


def main():
    pairs = gen()
    real = run_luau(pairs)
    errors = [(pr, r) for pr, r in zip(pairs, real) if not isinstance(r, bool)]
    report = {'pairs': len(pairs), 'real_true': sum(1 for r in real if r is True), 'raised': len(errors), 'preds': {}}
    for name, fn in PREDS.items():
        diffs = [(a, p, r, fn(a, p)) for (a, p), r in zip(pairs, real) if isinstance(r, bool) and fn(a, p) != r]
        by = collections.defaultdict(list)
        for a, p, r, ref in diffs:
            key = cause(a, p, r) if name.startswith('ext01') else ('real=%s ref=%s' % (r, ref))
            by[key].append((a, p, r, ref))
        report['preds'][name] = {'agree': len(pairs) - len(errors) - len(diffs), 'diverge': len(diffs),
                                 'classes': {k: {'count': len(v), 'examples': v[:4]} for k, v in by.items()}}
    # minimal repros: shrink the shortest example of each class against the real impl (one batch per round)
    json.dump(report, open(os.path.join(HERE, 'results.json'), 'w'), ensure_ascii=False, indent=1)
    print(json.dumps({k: (v if k != 'preds' else {n: {'agree': d['agree'], 'diverge': d['diverge'],
          'classes': {c: x['count'] for c, x in d['classes'].items()}} for n, d in v.items()}) for k, v in report.items()},
          ensure_ascii=False, indent=1))
    if errors:
        print('RAISED', errors[:5])


if __name__ == '__main__':
    main()
