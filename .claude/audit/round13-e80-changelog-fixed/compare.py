#!/usr/bin/env python3
"""E80: HEAD(out/*.txt)와 3.2.0(out/320/*.txt)의 [PASS]/[FAIL]/[CRASH] 줄을 라벨별로 맞대어 out/compare.tsv로.
3.2.0에서 FAIL(또는 그 절이 CRASH)이고 HEAD에서 PASS면 '고쳐짐'(프로브가 버그를 구별함)."""
import glob, os, re
here = os.path.dirname(os.path.abspath(__file__))
def parse(p):
    res = {}; order = []; crash_after = None
    if not os.path.exists(p): return res, order
    for line in open(p, encoding='utf-8'):
        m = re.match(r'^\[(PASS|FAIL)\] (\S+(?: [^—]*?)?)\s*(?:—|$)', line)
        if m:
            lab = m.group(2).strip(); res[lab] = m.group(1); order.append(lab)
        elif line.startswith('--- '):
            order.append('#' + line.strip())
        elif line.startswith('[CRASH]'):
            res['#crash:' + str(len(order))] = line.strip()[:160]; order.append('#crash:' + str(len(order)))
    return res, order
rows = []
for p in sorted(glob.glob(os.path.join(here, 'out', '*.txt'))):
    k = os.path.basename(p)[:-4]
    if k in ('ids', 'strict-f45', 'compare'): continue
    h, ho = parse(p); o, oo = parse(os.path.join(here, 'out', '320', k + '.txt'))
    crashes = [v for kk, v in o.items() if kk.startswith('#crash')]
    for lab in ho:
        if lab.startswith('#'): continue
        hv = h.get(lab); ov = o.get(lab, 'ABSENT(절 크래시)')
        verdict = 'fixed' if hv == 'PASS' and ov != 'PASS' else ('same' if hv == ov else ('REGRESS' if hv != 'PASS' else '?'))
        rows.append((k, lab, hv, ov, verdict))
with open(os.path.join(here, 'out', 'compare.tsv'), 'w', encoding='utf-8') as f:
    f.write('probe\tlabel\tHEAD\t3.2.0\tverdict\n')
    for r in rows: f.write('\t'.join(r) + '\n')
for r in rows: print('\t'.join(r))
