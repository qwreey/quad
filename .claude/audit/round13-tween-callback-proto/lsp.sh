#!/usr/bin/env bash
# run quad-roblox luau-lsp new-solver analyze with test.sh line-79 limit flags; extra files as args
cd /code/Projects/quad/.claude/worktrees/agent-a24a5a5d2d53b36a5
mise exec -- luau-lsp analyze --flag:LuauSolverV2=true \
	--flag:LuauTarjanChildLimit=160000 \
	--flag:LuauSubtypingIterationLimit=100000 \
	--flag:LuauTypeInferIterationLimit=1000000 \
	--definitions=scripts/roblox-defs/globalTypes.d.luau \
	--ignore "**/luau_packages/**" \
	"$@" 2>&1 | grep -v "^\[INFO\]"
