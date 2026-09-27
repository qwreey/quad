# Merge luau --coverage lcov outputs (cov/*.out, one per spec run from the worktree) into per-file line coverage.
import glob, re, collections, json, sys
hit = collections.defaultdict(dict)
def norm(p):
    p = p.lstrip("./")
    p = re.sub(r"^.*?luau_packages/(?:\.pesde/[^/]+/[^/]+/)?quad_base/", "quad-base/", p)
    p = re.sub(r"^.*?luau_packages/(?:\.pesde/[^/]+/[^/]+/)?quad_types/", "quad-types/", p)
    p = re.sub(r"^quad-(base|roblox)/test/\.\./\.\./", "", p)
    p = re.sub(r"^quad-(base|roblox)/test/\.\./", r"quad-\1/", p)
    return p
for f in glob.glob("cov/*.out"):
    sf = None
    for line in open(f):
        if line.startswith("SF:"): sf = norm(line[3:].strip())
        elif line.startswith("DA:"):
            n, c = line[3:].split(",")[:2]; n = int(n); c = int(c)
            hit[sf][n] = max(hit[sf].get(n, 0), c)
rows = []
for sf, d in hit.items():
    if "/src/" not in sf or sf.startswith("quad-types") : continue
    tot = len(d); cov = sum(1 for v in d.values() if v > 0)
    rows.append((sf, tot, cov))
for sf, tot, cov in sorted(rows, key=lambda r: r[2]/max(r[1],1)):
    print(f"{cov/max(tot,1)*100:5.1f}% {cov:4}/{tot:<4} {sf}")
json.dump({k: {str(n): c for n, c in v.items()} for k, v in hit.items()}, open("cov-merged.json", "w"))
