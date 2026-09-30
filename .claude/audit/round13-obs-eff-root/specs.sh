#!/usr/bin/env bash
# runs every quad-base spec/smoke quickly (no analyzers), prints failures
W=/code/Projects/quad/.claude/worktrees/agent-a44a4548414d6d6dd
SCR=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs-eff-root
cd $W && ./scripts/relink.sh >/dev/null 2>&1
cd $W/quad-base/test
nf=0
for f in smoke.*.luau spec.*.luau; do
  if ! luau "$f" > $SCR/.spec.out 2>&1; then nf=$((nf+1)); echo "FAIL $f"; grep -m3 -E 'error|assert|stack|failed|:[0-9]+:' $SCR/.spec.out | cut -c1-240; fi
done
echo "quad-base failures: $nf"
