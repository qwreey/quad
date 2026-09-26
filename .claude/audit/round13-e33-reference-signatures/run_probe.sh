#!/usr/bin/env bash
# E33 — run a probe with the exact flag set of scripts/test.sh line 79 (quad-roblox group)
cd "$(dirname "$0")/../../.." || exit 1
mise exec -- luau-lsp analyze --flag:LuauSolverV2=true \
	--flag:LuauTarjanChildLimit=160000 \
	--flag:LuauSubtypingIterationLimit=100000 \
	--flag:LuauTypeInferIterationLimit=1000000 \
	--definitions=scripts/roblox-defs/globalTypes.d.luau \
	--ignore "**/luau_packages/**" \
	".claude/audit/round13-e33-reference-signatures/$1" 2>&1 | grep -v "^\[INFO\]"
