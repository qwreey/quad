#!/usr/bin/env bash
# usage: run.sh <variantdir> <outdir>  — sync embedded quad_base copy, run all specs + analyzers, record per-file output
set -uo pipefail
V=$1; O=$2; mkdir -p "$O"; cd "$V"
EMB=quad-roblox/luau_packages/.pesde/qwreey+quad_base/3.2.0/quad_base/src
rm -rf "$EMB"; cp -r quad-base/src "$EMB"
fail=0
analyze_out=$(luau-analyze quad-base/src quad-types/src quad-error/src quad-base/test/spec.*.luau quad-base/test/mock.luau 2>&1) || { fail=1; echo "ANALYZE FAIL"; }
printf '%s\n' "$analyze_out" > "$O/analyze.txt"
ns=$(luau-lsp analyze --flag:LuauSolverV2=true --platform=standard --ignore "**/luau_packages/**" quad-base/src quad-types/src quad-error/src type-version-check/src quad-base/test/spec.*.luau quad-base/test/mock.luau 2>&1) || { fail=1; echo "NEWSOLVER FAIL"; }
printf '%s\n' "$ns" | grep -v '^\[INFO\]' > "$O/newsolver.txt"
lsp=$(luau-lsp analyze --flag:LuauSolverV2=true --flag:LuauTarjanChildLimit=160000 --flag:LuauSubtypingIterationLimit=100000 --flag:LuauTypeInferIterationLimit=1000000 --definitions=scripts/roblox-defs/globalTypes.d.luau --ignore "**/luau_packages/**" quad-roblox/src quad-roblox/test/spec.*.luau 2>&1) || { fail=1; echo "ROBLOX LSP FAIL"; }
printf '%s\n' "$lsp" | grep -v '^\[INFO\]' > "$O/robloxlsp.txt"
n=0; nf=0
for f in quad-base/test/smoke.*.luau quad-base/test/spec.*.luau quad-roblox/test/spec.*.luau; do
  n=$((n+1)); b=$(echo "$f" | tr / _)
  if ! luau "$f" > "$O/$b.out" 2>&1; then nf=$((nf+1)); fail=1; echo "FAIL $f"; fi
done
echo "files=$n failed=$nf fail=$fail"
