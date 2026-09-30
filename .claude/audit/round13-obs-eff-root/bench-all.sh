#!/usr/bin/env bash
# interleaved bench: base / P1b / P3E(obs P3 + effect P3E), 5 rounds each, -O2
SCR=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs-eff-root
W=/code/Projects/quad/.claude/worktrees/agent-a44a4548414d6d6dd
OUT=$SCR/bench.raw; : > $OUT
setv() {
  case $1 in
    base) git -C $W show HEAD:quad-base/src/Observer.luau > $W/quad-base/src/Observer.luau; git -C $W show HEAD:quad-base/src/Effect.luau > $W/quad-base/src/Effect.luau;;
    P1b) cp $SCR/Observer.P1b.luau $W/quad-base/src/Observer.luau; git -C $W show HEAD:quad-base/src/Effect.luau > $W/quad-base/src/Effect.luau;;
    P3Ea) cp $SCR/Observer.P3.luau $W/quad-base/src/Observer.luau; cp $SCR/Effect.P3Ea.luau $W/quad-base/src/Effect.luau;;
    P3E) cp $SCR/Observer.P3.luau $W/quad-base/src/Observer.luau; cp $SCR/Effect.P3E.luau $W/quad-base/src/Effect.luau;;
  esac
}
cp $SCR/bench-obseff.luau $W/quad-base/test/xr_bench.luau
for r in 1 2 3 4 5; do
  for v in base P1b P3E P3Ea; do
    setv $v
    cd $W/quad-base/test && echo "$v $(luau -O2 xr_bench.luau)" >> $OUT
  done
done
rm -f $W/quad-base/test/xr_bench.luau
setv P3Ea
python3 - "$OUT" <<'EOF'
import sys, collections
d = collections.defaultdict(lambda: collections.defaultdict(list))
for line in open(sys.argv[1]):
    v, *kv = line.split()
    for p in kv:
        k, x = p.split('='); d[k][v].append(float(x))
for k in d:
    print(f"{k:36s}", "  ".join(f"{v}={min(d[k][v]):.3f}us" for v in ("base","P1b","P3E","P3Ea")))
EOF
