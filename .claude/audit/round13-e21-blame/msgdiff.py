#!/usr/bin/env python3
# E21 (4): source message template vs docs/reference/errors template, char-level.
import os, re, json, difflib
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..'))
sk = json.load(open(os.path.join(os.path.dirname(__file__), 'skeleton.json')))
# docs
docs = {}
for f in sorted(os.listdir(os.path.join(ROOT, 'docs/reference/errors'))):
    L = open(os.path.join(ROOT, 'docs/reference/errors', f), encoding='utf-8').read().split('\n')
    for i, l in enumerate(L):
        m = re.match(r'^###\s+`?(Quad\d{4})', l)
        if m:
            j = i + 1
            while j < len(L) and not L[j].strip(): j += 1
            line = L[j]
            mm = re.match(r'^`(.*)`(.*)$', line)
            when = ''
            for k in range(j, min(j + 12, len(L))):
                if L[k].startswith('- **언제**'): when = L[k][len('- **언제**: '):]; break
            docs[m.group(1)] = {'file': f, 'raw': line, 'tmpl': re.sub(r'`\s*—\s*`quad-[^`]*`\s*$', '', line).strip('`'), 'when': when}

def src_template(entry):
    f, ln = entry['loc'].rsplit(':', 1); ln = int(ln)
    text = open(os.path.join(ROOT, f), encoding='utf-8').read()
    lines = text.split('\n')
    off = sum(len(x) + 1 for x in lines[:ln - 1])
    k = text.find(entry['id'], off)
    # find opening quote before id
    q = k - 1
    quote = text[q]
    pieces = []
    i = k
    while True:
        j = i
        depth = 0
        while j < len(text):
            c = text[j]
            if c == '\\': j += 2; continue
            if quote == '`' and c == '{': depth += 1
            elif quote == '`' and c == '}': depth -= 1
            elif c == quote and depth == 0: break
            j += 1
        pieces.append(text[i:j])
        rest = text[j + 1:]
        m = re.match(r'\s*\.\.\s*(["`])', rest)
        if m:
            quote = m.group(1); i = j + 1 + m.end(); continue
        m = re.match(r'\s*\.\.\s*([^,\)\n]+)', rest)
        if m:
            pieces.append('{' + m.group(1).strip() + '}')
        break
    s = ''.join(pieces)
    return s[len(entry['id']) + 1:] if s.startswith(entry['id']) else s

rows = []
for e in sk:
    st = src_template(e)
    d = docs.get(e['id'])
    dt = d['tmpl'] if d else None
    same = dt == st
    rows.append({'id': e['id'], 'src': st, 'doc': dt, 'same': same, 'when': d['when'] if d else None, 'docfile': d['file'] if d else None})
json.dump(rows, open(os.path.join(os.path.dirname(__file__), 'msgdiff.json'), 'w'), ensure_ascii=False, indent=1)
n = 0
for r in rows:
    if not r['same']:
        n += 1
        print(f"== {r['id']} ({r['docfile']})\n  SRC: {r['src']}\n  DOC: {r['doc']}")
print('differ:', n, 'of', len(rows))
