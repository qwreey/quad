#!/usr/bin/env bash
# usage: e1b.sh <label> — e1b probe with the C3x oscillator replaced by a capped copy (loop variants spin forever there: UB)
W=/code/Projects/quad/.claude/worktrees/agent-a57474fa822e253a8
SCR=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs-eff-unify
A=$W/.claude/audit; T=$W/quad-base/test; L=$1; mkdir -p $SCR/out/$L
cd $W && ./scripts/relink.sh >/dev/null 2>&1
{ sed -n '1,85p' $A/round13-e1b-probe.luau; echo 'print("[C3x oscillator] skipped here — see c3x line below")'; sed -n '101,$p' $A/round13-e1b-probe.luau; } > $T/xr_e1b.luau
cd $T
timeout 300 luau xr_e1b.luau > $SCR/out/$L/e1b.txt 2>&1
echo "exit $?" >> $SCR/out/$L/e1b.txt
rm -f xr_e1b.luau
