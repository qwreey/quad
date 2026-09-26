#!/bin/sh
# usage: ./run.sh file.luau ...  — runs luau-lsp (test.sh 79-line flags) and luau-analyze 0.734 (default new solver)
cd /code/Projects/quad
for f in "$@"; do
  p=.claude/audit/round13-s6b-compute-hole/$f
  echo "=== $f [luau-lsp 1.69.0]"
  mise exec -- luau-lsp analyze --flag:LuauSolverV2=true \
	--flag:LuauTarjanChildLimit=160000 \
	--flag:LuauSubtypingIterationLimit=100000 \
	--flag:LuauTypeInferIterationLimit=1000000 \
	--definitions=scripts/roblox-defs/globalTypes.d.luau \
	--ignore "**/luau_packages/**" "$p" 2>&1 | grep -v '^$'
  echo "=== $f [luau-analyze 0.734]"
  mise exec -- luau-analyze "$p" 2>&1 | grep -v '^$'
done
