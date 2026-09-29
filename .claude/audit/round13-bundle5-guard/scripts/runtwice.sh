#!/usr/bin/env bash
# usage: runtwice.sh <probe.luau> <subdir> <outname> <args...>
# Runs the probe twice in the BEFORE tree (noise check) and once in the AFTER tree.
# Output → out/<outname>.before1.txt, .before2.txt, .after.txt
set -uo pipefail
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/bundle5-guard
P=$1; SUB=$2; NAME=$3; shift 3
for t in before after; do cp "$P" "$S/tree.$t/$SUB/"; done
b=$(basename "$P")
( cd "$S/tree.before/$SUB" && luau "$b" -a "$@" ) > "$S/out/$NAME.before1.txt" 2>&1; echo "before1 exit=$?"
( cd "$S/tree.before/$SUB" && luau "$b" -a "$@" ) > "$S/out/$NAME.before2.txt" 2>&1; echo "before2 exit=$?"
( cd "$S/tree.after/$SUB" && luau "$b" -a "$@" ) > "$S/out/$NAME.after.txt" 2>&1; echo "after exit=$?"
cd "$S/out"
echo "noise (before1 vs before2) differing seeds: $(diff <(grep -v "^raw error" "$NAME.before1.txt") <(grep -v "^raw error" "$NAME.before2.txt") | grep -c "^<")"
echo "guard (before1 vs after)   differing seeds: $(diff <(grep -v "^raw error" "$NAME.before1.txt") <(grep -v "^raw error" "$NAME.after.txt") | grep -c "^<")"
tail -n 2 "$NAME.before1.txt"; tail -n 2 "$NAME.after.txt"
