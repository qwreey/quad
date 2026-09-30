#!/usr/bin/env bash
# second pass: full battery for the no-seed variants, capped e1b for all six; leaves Unest2 installed
SCR=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs-eff-unify
for v in U2 Unest2; do
  bash $SCR/setv.sh $v
  bash $SCR/runall.sh $v 3000
done
for v in HEAD D123 U Unest U2 Unest2; do
  bash $SCR/setv.sh $v
  bash $SCR/e1b.sh $v
  echo "e1b $v"
done
bash $SCR/setv.sh Unest2
echo ALLDONE
