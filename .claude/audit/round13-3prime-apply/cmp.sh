#!/usr/bin/env bash
# usage: cmp.sh <labelA> <labelB> — diffs every probe output (ms timings stripped)
O=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs3p/out
T=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs3p/.cmp
A=$1; B=$2
for f in debounce effnest e3 osc throw q109 q110 e79 e20-a e20-b e20-c e20-c2b e20-c3 e20-d e20-d3 e20-e e20-g e20-h e1b; do
  [ -f "$O/$A/$f.txt" ] && [ -f "$O/$B/$f.txt" ] || continue
  sed -E 's/\(-?[0-9.]+ ?ms\)//g; s/[0-9.]+ ?ms//g' "$O/$A/$f.txt" > $T.a
  sed -E 's/\(-?[0-9.]+ ?ms\)//g; s/[0-9.]+ ?ms//g' "$O/$B/$f.txt" > $T.b
  if ! cmp -s $T.a $T.b; then echo "## $f"; diff $T.a $T.b | head -40; fi
done
