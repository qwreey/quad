#!/usr/bin/env bash
# usage: specout.sh <outdir> — run AFTER ./scripts/test.sh (relinked copies). Records per-file
# stdout+stderr+exit of every smoke/spec so before/after can be diffed byte for byte.
set -uo pipefail
O=$1; mkdir -p "$O"
cd /code/Projects/quad/.claude/worktrees/agent-a54c27f3275bd7cf8
for f in quad-base/test/smoke.*.luau quad-base/test/spec.*.luau quad-roblox/test/spec.*.luau; do
  b=${f//\//_}
  mise exec -- luau "$f" > "$O/$b.out" 2>&1
  echo "exit=$?" >> "$O/$b.out"
done
echo done
