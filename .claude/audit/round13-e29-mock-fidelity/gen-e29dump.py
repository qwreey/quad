# E29: emit a Luau table of the dump's write/read/event surface for the instrumented mock variant.
# usage: python3 gen-e29dump.py <out.luau>   (run from repo root; out goes next to the COPIED mock)
import json, sys
d = json.load(open('quad-roblox/dump/api-surface.json'))
out = ["return {"]
for cn, c in sorted(d['classes'].items()):
    out.append(f'  ["{cn}"] = {{ w = {{')
    out += [f'    ["{p["name"]}"] = "{p["type"]}",' for p in c['props']]
    out.append('  }, r = {')
    out += [f'    ["{p["name"]}"] = "{p["type"]}",' for p in c['readProps']]
    out.append('  }, e = {')
    out += [f'    ["{p["name"]}"] = true,' for p in c['events']]
    out.append('  } },')
drop = {}
for x in d['dropped']:
    if '.' in x:
        cn, rest = x.split('.', 1)
        drop.setdefault(cn, []).append((rest.split(':')[0].split(' ')[0], rest))
out.append('  __dropped = {')
for cn, l in drop.items():
    out.append(f'    ["{cn}"] = {{')
    out += [f'      ["{nm}"] = {json.dumps(rest)},' for nm, rest in l]
    out.append('    },')
out.append('  },')
out.append("}")
open(sys.argv[1], "w").write("\n".join(out))
