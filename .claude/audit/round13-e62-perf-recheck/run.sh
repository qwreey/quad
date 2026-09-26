#!/bin/bash
# E62 runner: alternate base/head, R rounds; each probe output to raw/<tree>-<probe>-r<i>.txt
S=$(cd "$(dirname "$0")" && pwd); R=${R:-5}
for i in $(seq 1 $R); do
 for t in base head; do
  cd "$S/$t"
  for p in p3-compute p2-slotlist p1-mount p6-gc; do
   s=$(date +%s%N); luau .claude/audit/perf-cli-2026-09-26/$p.luau > "$S/raw/$t-$p-r$i.txt" 2>&1; e=$(date +%s%N)
   echo "$t $p r$i $(( (e-s)/1000000 ))ms" >> "$S/raw/wall.log"
  done
  (cd quad-base && luau -O2 test/bench.slot-bundle.luau > "$S/raw/$t-bench-r$i.txt" 2>&1)
  if [ $i -le 2 ]; then luau .claude/audit/perf-cli-2026-09-26/p2-trace.luau > "$S/raw/$t-p2-trace-r$i.txt" 2>&1; fi
 done
done
echo ALLDONE >> "$S/raw/wall.log"
