"""Merge lcov outputs of `luau --coverage` across all spec runs; normalize package-copy paths to repo paths.
out: fn.json  {file: {"line:name": {"count": n, "specs": [..]}}}, lines.json {file: {line: count}}"""
import os, re, sys, json, glob, collections
covdir, outdir = sys.argv[1], sys.argv[2]
def norm(p):
    p = re.sub(r'^.*/e38/repo/', '', p)
    m = re.search(r'luau_packages/\.pesde/qwreey\+(\w+)/[^/]+/\1/(src/.*)$', p)
    if m:
        pkg = {'quad_base': 'quad-base', 'quad_types': 'quad-types', 'quad_error': 'quad-error', 'type_version_check': 'type-version-check'}[m.group(1)]
        return f'{pkg}/{m.group(2)}'
    return p
fn = collections.defaultdict(lambda: collections.defaultdict(lambda: {'count': 0, 'specs': set()}))
lines = collections.defaultdict(lambda: collections.defaultdict(int))
for f in sorted(glob.glob(os.path.join(covdir, '*', 'coverage.out'))):
    spec = os.path.basename(os.path.dirname(f))
    sf = None; fnl = {}
    for ln in open(f):
        ln = ln.rstrip('\n')
        if ln.startswith('SF:'): sf = norm(ln[3:]); fnl = {}
        elif ln.startswith('FN:'):
            a, name = ln[3:].split(',', 1); fnl[name] = int(a)
        elif ln.startswith('FNDA:'):
            c, name = ln[5:].split(',', 1)
            k = f'{fnl.get(name, 0)}:{name.split(":")[0]}'
            e = fn[sf][k]; e['count'] += int(c)
            if int(c) > 0: e['specs'].add(spec)
        elif ln.startswith('DA:'):
            l, c = ln[3:].split(','); lines[sf][int(l)] += int(c)
json.dump({f: {k: {'count': v['count'], 'specs': sorted(v['specs'])} for k, v in d.items()} for f, d in fn.items()}, open(os.path.join(outdir, 'fn.json'), 'w'), indent=0)
json.dump(lines, open(os.path.join(outdir, 'lines.json'), 'w'))
tot = sum(len(d) for f, d in fn.items() if '/src/' in f and not f.startswith('quad-roblox/src/Declaration'))
zero = [(f, k) for f, d in fn.items() if '/src/' in f for k, v in d.items() if v['count'] == 0]
print('src functions', tot, 'never called', len(zero))
