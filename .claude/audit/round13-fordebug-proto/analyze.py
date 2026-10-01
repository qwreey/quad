#!/usr/bin/env python3
"""Attribute debug warnings in out-probe-on-<tag>.txt to cases and compare behavior with HEAD.
usage: python3 analyze.py <dir>   (reads out-probe-on-HEAD.txt / out-probe-on-proto.txt)"""
import re, sys, collections
d = sys.argv[1] if len(sys.argv) > 1 else '.'
WARN = re.compile(r'^(Ref|PreRef|PostRef|Observer|Effect|Slot|Tag|Attr): found at string key "')

def load(tag):
    return open(f'{d}/out-probe-on-{tag}.txt').read().splitlines()

head, proto = load('HEAD'), load('proto')
# 1. behavior: proto minus warning lines, minus handler listing, must equal HEAD minus listing
def strip(lines):
    out, inD = [], False
    for l in lines:
        if l.startswith('== D.'): inD = True; out.append(l); continue
        if l.startswith('== E.'): inD = False
        if inD: continue
        if WARN.match(l): continue
        out.append(l)
    return out
sh, sp = strip(head), strip(proto)
print('behavior identical to HEAD (warnings and handler listing removed):', sh == sp)
if sh != sp:
    import difflib
    for l in difflib.unified_diff(sh, sp, lineterm='', n=0): print('  ', l)
print('warning lines in HEAD on-run:', sum(1 for l in head if WARN.match(l)))

# 2. attribute proto warnings to the preceding `>> label` (A/A2/A3/C/E) or the section (B)
section, label = None, None
per = collections.OrderedDict()
for l in proto:
    m = re.match(r'^== (\w+)\.', l)
    if m:
        section, label = m.group(1), None
        continue
    if l.startswith('>> '):
        label = l[3:]
        per[(section, label)] = per.get((section, label), [])
        continue
    if WARN.match(l):
        key = (section, label if section != 'B' else '(B section)')
        per.setdefault(key, []).append(l)

by_sec = collections.defaultdict(lambda: [0, 0, 0])  # cases, cases with >=1 warning, warning lines
for (sec, lab), ws in per.items():
    by_sec[sec][0] += 1
    by_sec[sec][1] += 1 if ws else 0
    by_sec[sec][2] += len(ws)
for sec in ['A', 'A2', 'A3', 'B', 'C', 'E']:
    c = by_sec.get(sec)
    if c: print(f'section {sec}: cases {c[0]}, warned {c[1]}, warning lines {c[2]}')
    else: print(f'section {sec}: no labelled cases / no warnings')
print()
print('cases without a warning in A/A2:')
for (sec, lab), ws in per.items():
    if sec in ('A', 'A2') and not ws: print('  ', sec, lab)
print('cases with more than one warning line:')
for (sec, lab), ws in per.items():
    if len(ws) > 1: print('  ', sec, lab, len(ws))
print('A3 / C / E / B detail:')
for (sec, lab), ws in per.items():
    if sec in ('A3', 'C', 'E', 'B'): print('  ', sec, lab, '->', ws if ws else 'none')
