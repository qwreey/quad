#!/usr/bin/env bash
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/p-q98; cd $S
: > out/matrix.txt
for sv in none q93 q98 q93q98 q98b q93q98b; do for ov in none obsA obsA2; do
  n="${sv}__${ov}"; ./mkcombo.sh $n $sv $ov
  r=$(./run.sh $S/c/$n $S/out/spec_$n 2>&1 | tail -3 | tr '\n' ' ')
  same=$(diff -rq out/base out/spec_$n >/dev/null && echo identical || echo DIFF)
  echo "$n | $r | vs base: $same" >> out/matrix.txt
done; done
echo done >> out/matrix.txt
