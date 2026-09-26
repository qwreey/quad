"""Member/module-key coverage table: dyn = runtime executions of the implementing function (luau --coverage, any caller),
stat = mentions in spec/smoke source (comments stripped; direct use by a spec)."""
import json, re, glob, os, sys
ROOT = '/code/Projects/quad'; A = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
surf = json.load(open(f'{A}/out/surface.json')); fn = json.load(open(f'{A}/out/fn.json'))
def dyn(files, name):
    tot = 0; specs = set(); found = False
    for f in files:
        for k, v in fn.get(f, {}).items():
            if k.split(':', 1)[1] == name:
                found = True; tot += v['count']; specs |= set(v['specs'])
    return (tot, sorted(specs)) if found else (None, [])
B = 'quad-base/src/'; R = 'quad-roblox/src/'
TF = {'State': [B+'State.luau'], 'Source': [B+'Source.luau'], 'Store': [B+'Store.luau'], 'Slot': [B+'Slot/init.luau', B+'Slot/List.luau'],
      'Ref': [B+'Ref/init.luau'], 'Observer': [B+'Observer.luau'], 'Effect': [B+'Effect.luau'], 'Blocker': [B+'Blocker.luau'],
      'Modifier': [B+'Dispatch/Modifier/init.luau'], 'Tag': [B+'Tag.luau'], 'Brand': ['quad-types/src/init.luau'], 'Operator': [B+'Operator.luau'],
      'Relate': [B+'Relate.luau'], 'Backend': [B+'LifetimeHandle.luau', R+'LifetimeHandle.luau', R+'EngineOps.luau', 'quad-base/test/mock.luau'],
      'Attr': [B+'Attr/init.luau'], 'Context': [B+'Context.luau'], 'TimedGate': [B+'Debounce.luau'], 'GateHandle': [B+'State.luau', B+'Debounce.luau'],
      'Handler': [], 'Dispatch': [B+'Dispatch/init.luau'], 'Bookkeeping': [B+'Bookkeeping.luau', B+'Slot/Owner.luau']}
MK = {'New': ([B+'init.luau'], 'New'), 'RunInit': ([B+'init.luau'], 'RunInit'), 'AddPlugin': ([B+'init.luau'], 'AddPlugin'), 'UseProvider': ([B+'init.luau'], 'UseProvider'),
      'Relate': ([B+'Relate.luau'], 'Relate'), 'Ref': ([B+'Ref/init.luau'], 'Ref'), 'PreRef': ([B+'Ref/PreRef.luau'], 'PreRef'), 'PostRef': ([B+'Ref/PostRef.luau'], 'PostRef'),
      'Source': ([B+'Source.luau'], 'Source'), 'Store': ([B+'Store.luau'], 'Store'), 'Effect': ([B+'Effect.luau'], 'Effect'), 'Blocker': ([B+'Blocker.luau'], 'Blocker'),
      'Debounce': ([B+'Debounce.luau'], 'Debounce'), 'Throttle': ([B+'Debounce.luau'], 'Throttle'), 'OnCreated': ([B+'LifecycleHooks.luau'], 'OnCreated'),
      'OnRendered': ([B+'LifecycleHooks.luau'], 'OnRendered'), 'OnDestroyed': ([B+'LifecycleHooks.luau'], 'OnDestroyed'), 'Fallback': ([B+'Fallback.luau'], 'Fallback'),
      'Traceback': ([B+'Fallback.luau'], 'Traceback'), 'Context': ([B+'Context.luau'], '__call'), 'Slot': ([B+'Slot/init.luau'], 'Slot'), 'dispose': ([B+'Slot/init.luau'], 'dispose'),
      'Claim': ([B+'Claim.luau'], 'Claim'), 'newMapperClass': ([B+'Claim.luau'], 'newMapperClass'), 'Tag': ([B+'Tag.luau'], '__call'), 'Modifier': ([B+'Dispatch/Modifier/init.luau'], '__call'),
      'Attr': ([B+'Attr/init.luau'], '__call'), 'AttrKey': ([B+'Attr/Key.luau'], 'AttrKey'),
      'OnChange': ([R+'Handlers/OnChange.luau'], 'OnChange'), 'Out': ([R+'Handlers/OnChange.luau'], 'Out'), 'Animate': ([R+'Animate.luau'], 'Animate'),
      'Tween': ([R+'Tween.luau'], 'Tween'), 'isTween': ([R+'Brand.luau'], 'isTween')}
for k in surf['module_keys_types']:
    if k.startswith('is') and k not in MK: MK[k] = ([B+'Brand.luau'], k)
# static
specfiles = sorted(glob.glob(f'{ROOT}/quad-base/test/spec.*.luau') + glob.glob(f'{ROOT}/quad-base/test/smoke.*.luau') + glob.glob(f'{ROOT}/quad-roblox/test/spec.*.luau'))
def strip(t):
    t = re.sub(r'--\[(=*)\[.*?\]\1\]', '', t, flags=re.S); return re.sub(r'--[^\n]*', '', t)
src = {os.path.basename(f): strip(open(f).read()) for f in specfiles}
def stat(rx):
    c = 0; files = []
    for n, t in src.items():
        k = len(re.findall(rx, t))
        if k: c += k; files.append(n)
    return c, files
rows = []
for k in surf['module_keys_types'] + surf['module_keys_roblox']:
    files, name = MK.get(k, ([], None))
    d, ds = dyn(files, name) if name else (None, [])
    s, sf = stat(rf'\b[A-Za-z_]\w*[.:]{k}\b(?!\s*[:=][^=])') if True else (0, [])
    rows.append({'kind': 'module', 'type': 'q', 'name': k, 'dyn': d, 'dyn_specs': len(ds), 'stat': s, 'stat_files': sf})
for t, ms in surf['members'].items():
    for m in ms:
        d, ds = dyn(TF.get(t, []), m)
        s, sf = stat(rf'[.:]{m}\b')
        rows.append({'kind': 'member', 'type': t, 'name': m, 'dyn': d, 'dyn_specs': len(ds), 'stat': s, 'stat_files': sf})
json.dump(rows, open(f'{A}/out/members.json', 'w'), indent=0)
for r in rows:
    flag = '' 
    if (r['dyn'] in (None, 0)) and r['stat'] == 0: flag = 'UNCOVERED'
    elif r['dyn'] == 0: flag = 'DYN0'
    elif r['stat'] == 0: flag = 'INDIRECT'
    print(f"{r['type']}.{r['name']}\tdyn={r['dyn']}\tspecs={r['dyn_specs']}\tstat={r['stat']}\t{flag}\t{','.join(x.replace('.luau','') for x in r['stat_files'][:4])}")
