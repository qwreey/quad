#!/usr/bin/env bash
# usage: spike-q126/timetest.sh <tag>  — runs test.sh, records exit code and wall time; also times the quad-roblox luau-lsp group alone (3 runs)
set -uo pipefail
cd "$(dirname "$0")/.."
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/q126-spike
tag="$1"
t0=$(date +%s.%N)
./scripts/test.sh > "$S/test-$tag.log" 2>&1
rc=$?
t1=$(date +%s.%N)
python3 -c "print('test.sh exit=$rc wall=%.2fs' % ($t1 - $t0))"
for i in 1 2 3; do
	a=$(date +%s.%N)
	mise exec -- luau-lsp analyze --flag:LuauSolverV2=true \
		--flag:LuauTarjanChildLimit=160000 \
		--flag:LuauSubtypingIterationLimit=100000 \
		--flag:LuauTypeInferIterationLimit=1000000 \
		--definitions=scripts/roblox-defs/globalTypes.d.luau \
		--ignore "**/luau_packages/**" \
		quad-roblox/src quad-roblox/test/spec.*.luau > "$S/lsp-$tag-$i.log" 2>&1
	r=$?
	b=$(date +%s.%N)
	python3 -c "print('roblox lsp group run $i exit=$r %.2fs' % ($b - $a))"
done
