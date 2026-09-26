import re,sys
v=sys.argv[1]
SC="/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/q87"
lines=open(f"{SC}/qr_{v}/test/probe.q87.base_qOut.luau").read().split("\n")
per={};tot=0;other=[]
for l in open(f"{SC}/{v}.probe.out"):
    m=re.match(r"test/probe\.q87\.base_qOut\.luau\((\d+),\d+\): (.*)",l)
    if not m:
        if re.match(r"\S+\(\d+,\d+\)",l): other.append(l.strip())
        continue
    tot+=1
    t=re.search(r"#(\w+)",lines[int(m.group(1))-1]); k=t.group(1) if t else "L"+m.group(1)
    per.setdefault(k,[]).append(m.group(2))
print("total",tot, " ".join(f"{k}:{len(per[k])}" for k in sorted(per)))
for k in sorted(per):
    if not k.startswith("N"): print("  ",k,per[k][0][:200])
for o in other[:5]: print("  other:",o[:200])
