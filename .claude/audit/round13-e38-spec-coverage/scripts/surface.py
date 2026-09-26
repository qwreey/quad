"""Public surface extraction — reuses scripts/doc-coverage.py (imported, not modified)."""
import importlib.util, json, os, re, sys
ROOT = '/code/Projects/quad'
spec = importlib.util.spec_from_file_location('dc', os.path.join(ROOT, 'scripts/doc-coverage.py'))
dc = importlib.util.module_from_spec(spec); spec.loader.exec_module(dc)
types = open(dc.TYPES).read(); rbx = open(dc.RBX).read()
mk_types = [f for f in dc.block_fields(types, r'^export type Quad = \{') if f not in dc.INJECTED]
mk_rbx = dc.block_fields(rbx, r'^export type RobloxExtension = \{')
members = {}
for t in dc.MEMBER_TYPES:
    fs = dc.block_fields(types, rf'^export type {t}(?:<[^>]*>)? = (?:[^\n{{]*)\{{')
    if fs: members[t] = fs
out = {'module_keys_types': mk_types, 'module_keys_roblox': mk_rbx, 'members': members, 'injected': sorted(dc.INJECTED)}
json.dump(out, open(sys.argv[1], 'w'), indent=1)
print(len(mk_types), len(mk_rbx), sum(len(v) for v in members.values()))
for t, v in members.items(): print(t, v)
print(mk_types); print(mk_rbx)
