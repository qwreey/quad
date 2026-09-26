import sys, glob, collections, re
S = sys.argv[1]
def load(v):
    d = {}
    for f in sorted(glob.glob(f"{S}/out/{v}.*.txt")):
        for line in open(f):
            if not line.startswith("S "): 
                if line.strip(): d.setdefault("__junk", []).append(line.strip())
                continue
            p = line.split()
            seed, step, op = int(p[1]), int(p[2]), p[3]
            kv = dict(x.split("=", 1) for x in p[4:])
            kv["op"] = op
            d[(seed, step)] = kv
    return d
A = sys.argv[2] if len(sys.argv) > 2 else "base"; Bv = sys.argv[3] if len(sys.argv) > 3 else "q76"
a, b = load(A), load(Bv)
print("junk", len(a.get("__junk", [])), len(b.get("__junk", [])), (a.get("__junk") or b.get("__junk") or [""])[:3])
a.pop("__junk", None); b.pop("__junk", None)
assert a.keys() == b.keys(), "step sets differ"
seeds = {k[0] for k in a}
print("seeds", len(seeds), "steps", len(a))
mism = collections.Counter(); first = {}
byop = collections.defaultdict(collections.Counter)
opsum = collections.defaultdict(collections.Counter)
seedsWithStale = collections.Counter()
for k in sorted(a):
    x, y = a[k], b[k]
    op = x["op"]
    byop[op]["steps"] += 1
    for f in ["fin", "upd", "gset", "dset", "err", "tcalls", "tdestroy", "ph", "viol", "stale"]:
        if x[f] != y[f]:
            mism[f] += 1; first.setdefault(f, k)
    for v, r in ((A, x), (Bv, y)):
        byop[op][f"{v}.pat.{r['pat']}"] += 1
        if r["pat"] not in ("noG",) and r["pat"] != "onlyG": pass
        byop[op][f"{v}.desc.{r['desc']}"] += (r["gord"] != "_")
        byop[op][f"{v}.dordDiffers"] += 0
        for o in r["ops"].split(","):
            opsum[v][o[0]] += int(o[1:])
            byop[op][f"{v}.{o[0]}"] += int(o[1:])
        byop[op][f"{v}.stale"] += int(r["stale"])
        byop[op][f"{v}.viol"] += int(r["viol"])
        if int(r["stale"]): seedsWithStale[v] += 1
        if r.get("phok") == "n": byop[op][f"{v}.physWrong"] += 1
        if int(r["old"]) > 0: byop[op][f"{v}.oldAlive>0"] += 1
    if x["gord"] != y["gord"]: byop[op]["gordDiffers"] += 1
    if x["dord"] != y["dord"]: byop[op]["dordDiffers"] += 1
    if x["tdord"] != y["tdord"]: byop[op]["toggleDestroyOrderDiffers"] += 1
    if x["dord"] != y["dord"] and x["gord"] == "_": byop[op]["dordDiffersWithoutGone"] += 1
print("MISMATCH per field (fin=logical final state; ph=physical order; viol/stale=offset-validator counts):", dict(mism), first)
for v in (A, Bv):
    print(v, "steps physWrong", sum(1 for k in (a if v == A else b) if (a if v == A else b)[k].get("phok") == "n"))
print("op totals", {v: dict(c) for v, c in opsum.items()})
print("steps with stale offsets", dict(seedsWithStale))
for op in sorted(byop):
    c = byop[op]
    print(op, dict(sorted(c.items())))
