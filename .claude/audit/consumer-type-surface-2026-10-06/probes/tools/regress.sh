#!/bin/bash
# regress.sh <treeDir> <outDir>
T=$1; O=$2; mkdir -p $O; cd $T
mise trust -q mise.toml >/dev/null 2>&1
FL="--flag:LuauSolverV2=true --flag:LuauTarjanChildLimit=160000 --flag:LuauSubtypingIterationLimit=100000 --flag:LuauTypeInferIterationLimit=1000000"
tm() { local t0=$(date +%s%N); "$@"; local t1=$(date +%s%N); echo "$(( (t1-t0)/1000000 ))" > $O/_t; }
cnt() { grep -cE ': (TypeError|SyntaxError)' "$1"; }
tm bash -c "mise exec -- luau-analyze quad-base/src quad-types/src quad-error/src quad-base/test/spec.*.luau quad-base/test/mock.luau > $O/g1.txt 2>&1"; echo "g1 luau-analyze(engine-agnostic): $(grep -cE 'TypeError|SyntaxError' $O/g1.txt) err, $(cat $O/_t)ms"
tm bash -c "mise exec -- luau-lsp analyze --flag:LuauSolverV2=true --platform=standard --ignore '**/luau_packages/**' quad-base/src quad-types/src quad-error/src type-version-check/src quad-base/test/spec.*.luau quad-base/test/mock.luau 2>&1 | grep -v '^\[INFO\]' > $O/g2.txt"; echo "g2 luau-lsp new solver (engine-agnostic): $(cnt $O/g2.txt) err, $(cat $O/_t)ms"
tm bash -c "mise exec -- luau-lsp analyze $FL --definitions=scripts/roblox-defs/globalTypes.d.luau --ignore '**/luau_packages/**' quad-roblox/src quad-roblox/test/spec.*.luau 2>&1 | grep -v '^\[INFO\]' > $O/g3.txt"; echo "g3 luau-lsp roblox group: $(cnt $O/g3.txt) err, $(cat $O/_t)ms"
for K in quad-roblox-devui quad-roblox-material; do
tm bash -c "mise exec -- luau-lsp analyze $FL --definitions=scripts/roblox-defs/globalTypes.d.luau --ignore '**/luau_packages/**' --ignore '$K/test/support/**' $K/src $K/test $K/stories 2>&1 | grep -v '^\[INFO\]' > $O/$K.txt"; echo "$K strict: $(cnt $O/$K.txt) err, $(cat $O/_t)ms"; done
cd .claude/audit/round13-e56-gs-strict-path
for d in bare annotated minimal workaround howto01; do
tm bash -c "mise exec -- luau-lsp analyze $FL --definitions=../../../scripts/roblox-defs/globalTypes.d.luau --ignore '**/luau_packages/**' $d 2>&1 | grep -v '^\[INFO\]' > $O/e56-$d.txt"; echo "e56 $d: $(cnt $O/e56-$d.txt) err-lines, $(cat $O/_t)ms"; done
