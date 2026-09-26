#!/usr/bin/env bash
# usage: gate.sh <variant-root>  — test.sh minus relink/gen-d/doc-coverage/type-surface/check-version (repo-only gates)
cd "$1" || exit 2
shopt -s nullglob
fail=0; nf=0; ff=0
for f in quad-base/test/smoke.*.luau quad-base/test/spec.*.luau quad-roblox/test/spec.*.luau; do
	nf=$((nf+1))
	if ! out=$(timeout 300 luau "$f" 2>&1); then ff=$((ff+1)); fail=1; echo "FAIL $f"; printf '%s\n' "$out" | grep -iv "^ok\|pass" | tail -5; fi
done
echo "specs+smoke: $nf files, $ff fail"
a=$(luau-analyze quad-base/src quad-types/src quad-error/src quad-base/test/spec.*.luau quad-base/test/mock.luau 2>&1); ae=$?
printf '%s\n' "$a" | grep -v "^$" | head -20; echo "luau-analyze exit $ae"; [ $ae -ne 0 ] && fail=1
n=$(mise exec -C /code/Projects/quad -- luau-lsp analyze --flag:LuauSolverV2=true --platform=standard --ignore "**/luau_packages/**" quad-base/src quad-types/src quad-error/src type-version-check/src quad-base/test/spec.*.luau quad-base/test/mock.luau 2>&1); ne=$?
printf '%s\n' "$n" | grep -v "^\[INFO\]" | head -20; echo "luau-lsp new-solver (engine-agnostic) exit $ne"; [ $ne -ne 0 ] && fail=1
l=$(mise exec -C /code/Projects/quad -- luau-lsp analyze --flag:LuauSolverV2=true --flag:LuauTarjanChildLimit=160000 --flag:LuauSubtypingIterationLimit=100000 --flag:LuauTypeInferIterationLimit=1000000 --definitions=scripts/roblox-defs/globalTypes.d.luau --ignore "**/luau_packages/**" quad-roblox/src quad-roblox/test/spec.*.luau 2>&1); le=$?
printf '%s\n' "$l" | grep -v "^\[INFO\]" | head -20; echo "luau-lsp roblox exit $le"; [ $le -ne 0 ] && fail=1
python3 scripts/error-codes.py check 2>&1 | tail -3; [ ${PIPESTATUS[0]} -ne 0 ] && fail=1
echo "GATE exit $fail"
exit $fail
