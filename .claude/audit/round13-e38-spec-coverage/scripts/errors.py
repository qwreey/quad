"""Error-ID assertion classes from the patched spec run logs (out/logs/*.txt):
 @@QERR = thrown by quad (src `error` shim), @@PC = a spec-level pcall/xpcall returned false with that message,
 @@FIND = a spec-level string.find/match SUCCEEDED on a string carrying that id.
 MSG = message asserted, FAIL = only failure asserted (reached spec pcall, no successful find), TRIG = thrown but never
 reached a spec pcall as that id (swallowed/rethrown inside quad or mock), NONE = never thrown by any spec."""
import re, glob, os, json, subprocess, collections
ROOT = '/code/Projects/quad'; A = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ids = sorted(set(re.findall(r'^### (Quad\d{4})', ''.join(open(f).read() for f in glob.glob(f'{ROOT}/docs/reference/errors/*.md')), re.M)))
where = {}
for f in glob.glob(f'{ROOT}/quad-*/src/**/*.luau', recursive=True) + glob.glob(f'{ROOT}/type-version-check/src/**/*.luau', recursive=True):
    for i, l in enumerate(open(f), 1):
        for m in re.findall(r'Quad\d{4}', l):
            where.setdefault(m, []).append(f'{os.path.relpath(f, ROOT)}:{i}')
doc = {}
for f in glob.glob(f'{ROOT}/docs/reference/errors/*.md'):
    for i, l in enumerate(open(f), 1):
        m = re.match(r'^### (Quad\d{4})', l)
        if m: doc[m.group(1)] = f'{os.path.basename(f)}:{i}' + (' (폐기)' if '폐기' in l else '')
thrown, pc, found = (collections.defaultdict(set) for _ in range(3))
for f in glob.glob(f'{A}/out/logs/*.txt'):
    s = os.path.basename(f)[:-4]
    for l in open(f):
        if l.startswith('@@QERR'):
            for m in re.findall(r'Quad\d{4}', l)[:1]: thrown[m].add(s)
        elif l.startswith('@@PC'):
            for m in re.findall(r'Quad\d{4}', l): pc[m].add(s)
        elif l.startswith('@@FIND'):
            found[l.split('\t')[1]].add(s)
rows = []
for i in ids:
    st = 'MSG' if found[i] else 'FAIL' if pc[i] else 'TRIG' if thrown[i] else 'NONE'
    rows.append({'id': i, 'class': st, 'doc': doc.get(i), 'src': where.get(i, []), 'thrown_in': sorted(thrown[i]), 'pcall_in': sorted(pc[i]), 'find_in': sorted(found[i])})
json.dump(rows, open(f'{A}/out/errors.json', 'w'), indent=0)
c = collections.Counter(r['class'] for r in rows); print(len(ids), dict(c))
for r in rows:
    if r['class'] != 'MSG': print(r['id'], r['class'], r['doc'], r['src'][:2], r['thrown_in'][:3], r['pcall_in'][:2])
