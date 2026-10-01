#!/usr/bin/env bash
# usage (from a tree root): .claude/audit/round13-fordebug-proto/run-fuzz.sh <tag>
# same reduced sizes as round13-q135-priority (E64 base/prov 2000 each, E66 3000); q.debug stays false
set -u
tag="${1:?tag}"
dir=.claude/audit/round13-fordebug-proto
./scripts/relink.sh >/dev/null 2>&1
run() {
	local name="$1"; shift
	( ulimit -v 4000000; timeout 300 mise exec -- luau "$@" > "$dir/out-fuzz-$name-$tag.txt" 2>&1 )
	echo "$name exit $?"
}
run e64-base .claude/audit/round13-e64-dispatch-fuzz/fuzz.luau -a base 2000 1
run e64-prov .claude/audit/round13-e64-dispatch-fuzz/fuzz.luau -a prov 2000 1
run e66 .claude/audit/round13-e66-handlers-fuzz/fuzz.luau -a 3000 1
