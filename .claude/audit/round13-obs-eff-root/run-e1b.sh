#!/usr/bin/env bash
# usage: run-e1b.sh <label> [cap]
W=/code/Projects/quad/.claude/worktrees/agent-a44a4548414d6d6dd
SCR=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs-eff-root
L=$1; CAP=${2:-100}; mkdir -p $SCR/out/$L
cd $W && ./scripts/relink.sh >/dev/null 2>&1
A=$W/.claude/audit
{ head -n 1 $A/round13-e1b-probe.luau; echo "do local P = (require(\"../src/Observer\") :: any).PROBE; if P then P.cap = $CAP end end"; tail -n +2 $A/round13-e1b-probe.luau; } > $W/quad-base/test/xr_e1b.luau
cd $W/quad-base/test
timeout 120 luau xr_e1b.luau > $SCR/out/$L/e1b.txt 2>&1
echo "exit $?"
rm -f xr_e1b.luau
cat $SCR/out/$L/e1b.txt
