#!/usr/bin/env bash
# E31: run every mock runner and strict check in this folder; prints a per-file summary.
cd "$(dirname "$0")"
ROOT=../../..
for f in run-*.luau; do
  out=$(luau "$f" 2>&1); rc=$?
  printf '=== %s (exit %d)\n%s\n' "$f" "$rc" "$out"
done > mock.log
( cd "$ROOT" && mise exec -- luau-lsp analyze --flag:LuauSolverV2=true \
  --flag:LuauTarjanChildLimit=160000 --flag:LuauSubtypingIterationLimit=100000 \
  --flag:LuauTypeInferIterationLimit=1000000 \
  --definitions=scripts/roblox-defs/globalTypes.d.luau --ignore "**/luau_packages/**" \
  .claude/audit/round13-e31-skill-walkthrough/strict-*.luau 2>&1 | grep -v '^\[INFO\]' ) > strict.log
grep -c "" strict.log
