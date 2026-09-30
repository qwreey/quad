#!/usr/bin/env bash
# interleaved bench: HEAD / D123 / U / Unest, 5 rounds each, -O2; leaves Unest installed
SCR=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs-eff-unify
W=/code/Projects/quad/.claude/worktrees/agent-a57474fa822e253a8
OUT=$SCR/bench.raw; : > $OUT
cd $W && ./scripts/relink.sh >/dev/null 2>&1
cp $SCR/bench-obseff.luau $W/quad-base/test/xr_bench.luau
for r in 1 2 3 4 5; do
  for v in HEAD D123 U2 Unest2; do
    bash $SCR/setv.sh $v >/dev/null
    cd $W/quad-base/test && echo "$v $(luau -O2 xr_bench.luau)" >> $OUT
  done
done
rm -f $W/quad-base/test/xr_bench.luau
bash $SCR/setv.sh Unest2
python3 - "$OUT" <<'EOF'
import sys, collections
d = collections.defaultdict(lambda: collections.defaultdict(list))
for line in open(sys.argv[1]):
    v, *kv = line.split()
    for p in kv:
        k, x = p.split('='); d[k][v].append(float(x))
vs = ("HEAD", "D123", "U2", "Unest2")
print(f"{'row':34s}", "  ".join(f"{v:>8s}" for v in vs))
for k in d:
    print(f"{k:34s}", "  ".join(f"{min(d[k][v]):8.3f}" for v in vs))
EOF
