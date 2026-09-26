#!/usr/bin/env bash
# E27 strict runner — scripts/test.sh 79행의 플래그 셋 그대로(한도 플래그 셋 + 신 솔버 + roblox defs)
cd "$(dirname "$0")"
mise exec -- luau-lsp analyze --flag:LuauSolverV2=true \
	--flag:LuauTarjanChildLimit=160000 \
	--flag:LuauSubtypingIterationLimit=100000 \
	--flag:LuauTypeInferIterationLimit=1000000 \
	--definitions=../../../scripts/roblox-defs/globalTypes.d.luau \
	--ignore "**/luau_packages/**" \
	"$@" 2>&1 | grep -v "^\[INFO\]"
