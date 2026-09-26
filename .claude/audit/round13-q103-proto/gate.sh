#!/bin/bash
# usage: gate.sh <dir> <label> <extra files...>
cd "$1"; shift; label=$1; shift
s=$(date +%s.%N)
out=$(luau-lsp analyze --flag:LuauSolverV2=true \
	--flag:LuauTarjanChildLimit=160000 \
	--flag:LuauSubtypingIterationLimit=100000 \
	--flag:LuauTypeInferIterationLimit=1000000 \
	--definitions=scripts/roblox-defs/globalTypes.d.luau \
	--ignore "**/luau_packages/**" \
	quad-roblox/src quad-roblox/test/spec.*.luau "$@" 2>&1)
e=$(date +%s.%N)
n=$(printf '%s\n' "$out" | grep -v "^\[INFO\]" | grep -c "TypeError\|SyntaxError\|Error")
printf '%s %.2f diag=%d\n' "$label" "$(python3 -c "print($e-$s)")" "$n"
printf '%s\n' "$out" | grep -v "^\[INFO\]" > /tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/out-$label.txt
