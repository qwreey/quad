#!/usr/bin/env python3
# E21: skeleton — every QuadNNNN id with its source location, enclosing raise call (if any) and level fn.
import os, re, sys, json
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../../scripts'))
import importlib.util
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..'))
spec = importlib.util.spec_from_file_location('ec', os.path.join(ROOT, 'scripts/error-codes.py'))
ec = importlib.util.module_from_spec(spec); spec.loader.exec_module(ec)
sites, ids = ec.scan()
bysite = {(s['file'], s['line']): s for s in sites}
out = []
for k in sorted(ids):
    for w in ids[k]:
        f, ln = w.rsplit(':', 1); ln = int(ln)
        # find raise site on same line or the nearest site within 3 lines before
        s = None
        for d in range(0, 4):
            s = bysite.get((f, ln - d))
            if s: break
        lines = open(os.path.join(ROOT, f), encoding='utf-8').read().split('\n')
        out.append({'id': k, 'loc': w, 'call': s['call'] if s else '(helper/string)', 'site': f"{s['file']}:{s['line']}" if s else None,
                    'text': lines[ln - 1].strip()[:200]})
json.dump(out, open(os.path.join(os.path.dirname(__file__), 'skeleton.json'), 'w'), ensure_ascii=False, indent=1)
for o in out:
    print(f"{o['id']}\t{o['loc']}\t{o['call']}\t{o['text'][:150]}")
print(len(out), 'ids;', len(sites), 'sites', file=sys.stderr)
