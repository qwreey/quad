#!/usr/bin/env bash
# test.sh subset: relink + analyze (3 groups, same flags) + smoke/spec. Exit code = verdict.
set -uo pipefail
shopt -s nullglob
cd "$(dirname "$0")"
./scripts/relink.sh >/dev/null 2>&1
fail=0
out=$(luau-analyze quad-base/src quad-types/src quad-error/src quad-base/test/spec.*.luau quad-base/test/mock.luau 2>&1) || { fail=1; echo "ANALYZE FAIL"; printf '%s\n' "$out"; }
out=$(mise exec -- luau-lsp analyze --flag:LuauSolverV2=true --platform=standard --ignore "**/luau_packages/**" quad-base/src quad-types/src quad-error/src type-version-check/src quad-base/test/spec.*.luau quad-base/test/mock.luau 2>&1) || { fail=1; echo "NEWSOLVER FAIL"; printf '%s\n' "$out" | grep -v '^\[INFO\]'; }
out=$(mise exec -- luau-lsp analyze --flag:LuauSolverV2=true --flag:LuauTarjanChildLimit=160000 --flag:LuauSubtypingIterationLimit=100000 --flag:LuauTypeInferIterationLimit=1000000 --definitions=scripts/roblox-defs/globalTypes.d.luau --ignore "**/luau_packages/**" quad-roblox/src quad-roblox/test/spec.*.luau 2>&1) || { fail=1; echo "ROBLOX LSP FAIL"; printf '%s\n' "$out" | grep -v '^\[INFO\]'; }
n=0
for f in quad-base/test/smoke.*.luau quad-base/test/spec.*.luau quad-roblox/test/spec.*.luau; do
  n=$((n+1))
  o=$(luau "$f" 2>&1) || { fail=1; echo "SPEC FAIL $f"; printf '%s\n' "$o" | tail -15; }
done
echo "files run: $n  fail=$fail"
exit $fail
