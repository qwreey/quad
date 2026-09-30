import os, re, glob
S = os.path.dirname(os.path.abspath(__file__))
V = ["base", "q74", "q76", "A", "Ap"]
old = {}
for l in open(f"{S}/base/.claude/audit/round13-slot-bundle/bench.summary.txt").readlines()[1:]:
    m = re.match(r"(.{60,70}?)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)", l)
    if m:
        old[m.group(1).strip()[:50]] = (float(m.group(2)), float(m.group(6)))
res, order = {}, []
for v in V:
    for f in glob.glob(f"{S}/bench/{v}.*.txt"):
        for l in open(f):
            m = re.match(r"(.*?)\s+([\d.]+) ms$", l.rstrip())
            if not m:
                continue
            k = m.group(1).strip()
            if k not in order:
                order.append(k)
            res.setdefault(k, {}).setdefault(v, []).append(float(m.group(2)))
print(f"{'case (min of 3 runs, ms, -O2)':66s}" + "".join(f"{v:>10s}" for v in V) + "    A/base  Ap/base | old base  old bundle  old bundle/base")
for k in order:
    mins = {v: min(res[k].get(v, [float('nan')])) for v in V}
    o = old.get(k[:50])
    os_ = f" | {o[0]:8.3f}  {o[1]:10.3f}  {o[1]/o[0]:.2f}x" if o else " | (none)"
    print(f"{k[:66]:66s}" + "".join(f"{mins[v]:10.3f}" for v in V) + f"    {mins['A']/mins['base']:.2f}x   {mins['Ap']/mins['base']:.2f}x" + os_)
