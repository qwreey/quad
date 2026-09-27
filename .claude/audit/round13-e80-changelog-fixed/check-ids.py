#!/usr/bin/env python3
"""E80: 프로브 출력에 나온 QuadNNNN마다 docs/reference/errors/*.md의 `### QuadNNNN` 절이 있는지, 절의 메시지 줄(백틱)
앞부분(첫 `{`·`…` 전까지)이 실제 문구에 들어 있는지 대조."""
import glob, os, re
here = os.path.dirname(os.path.abspath(__file__))
root = os.path.abspath(os.path.join(here, '../../..'))
seen = {}
for p in glob.glob(os.path.join(here, 'out', '*.txt')):
    if os.path.basename(p) in ('ids.txt',):
        continue
    for line in open(p, encoding='utf-8'):
        for m in re.finditer(r'(Quad\d{4}) ([^\n]*)', line):
            seen.setdefault(m.group(1), m.group(2).strip())
docs = {}
for p in glob.glob(os.path.join(root, 'docs/reference/errors/*.md')):
    txt = open(p, encoding='utf-8').read()
    for m in re.finditer(r'^### (Quad\d{4})\n\n`([^`]*)`', txt, re.M):
        docs[m.group(1)] = (os.path.basename(p), m.group(2))
bad = 0
for qid in sorted(seen):
    msg = seen[qid]
    if qid not in docs:
        print(f'MISSING {qid}: {msg[:120]}'); bad += 1; continue
    f, dmsg = docs[qid]
    head = re.split(r'\{|…|<', dmsg)[0].strip()
    head = head[:60]
    ok = head in msg
    print(f'{"OK  " if ok else "DIFF"} {qid} [{f}] doc="{dmsg[:90]}" | run="{msg[:90]}"')
    bad += 0 if ok else 1
print(f'ids={len(seen)} mismatch/missing={bad}')
