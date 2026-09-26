#!/usr/bin/env bash
# usage: run.sh <label>  — sync quad-base/src into roblox's nested copy, then analyze + all specs
set -u
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/p-gates
cd $S
NB=quad-roblox/luau_packages/.pesde/qwreey+quad_base/3.2.0/quad_base/src
rm -rf $NB && cp -r quad-base/src $NB
fail=0
echo "=== luau-analyze"
out=$(luau-analyze quad-base/src quad-types/src quad-error/src quad-base/test/spec.*.luau quad-base/test/mock.luau 2>&1) || fail=1
echo "$out" | tail -5
echo "=== luau-lsp new solver (engine-agnostic)"
out=$(mise exec -C /code/Projects/quad -- luau-lsp analyze --flag:LuauSolverV2=true --platform=standard --ignore "**/luau_packages/**" quad-base/src quad-types/src quad-error/src type-version-check/src quad-base/test/spec.*.luau quad-base/test/mock.luau 2>&1) || fail=1
echo "$out" | grep -v "^\[INFO\]" | tail -5
echo "=== luau-lsp roblox"
out=$(mise exec -C /code/Projects/quad -- luau-lsp analyze --flag:LuauSolverV2=true --flag:LuauTarjanChildLimit=160000 --flag:LuauSubtypingIterationLimit=100000 --flag:LuauTypeInferIterationLimit=1000000 --definitions=scripts/roblox-defs/globalTypes.d.luau --ignore "**/luau_packages/**" quad-roblox/src quad-roblox/test/spec.*.luau 2>&1) || fail=1
echo "$out" | grep -v "^\[INFO\]" | tail -5
n=0; bad=""
for f in quad-base/test/smoke.*.luau quad-base/test/spec.*.luau quad-roblox/test/spec.*.luau; do
  n=$((n+1))
  if ! o=$(luau "$f" 2>&1); then fail=1; bad="$bad $f"; echo "--- FAIL $f"; echo "$o" | tail -8; fi
done
echo "specs run: $n  failed:${bad:- none}"
echo "exit=$fail"
exit $fail
