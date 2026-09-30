#!/usr/bin/env bash
# final pass after the Observer pre-fn Sync micro-opt; leaves Unest2 installed
SCR=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs-eff-unify
W=/code/Projects/quad/.claude/worktrees/agent-a57474fa822e253a8
for v in U2 Unest2; do
  bash $SCR/setv.sh $v
  bash $SCR/runall.sh ${v}f 3000
  bash $SCR/e1b.sh ${v}f
  cd $W && ./scripts/test.sh > $SCR/testsh.${v}f.txt 2>&1; echo "test.sh $v exit $?"
done
bash $SCR/setv.sh Unest2
echo ALLDONE
