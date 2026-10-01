#!/usr/bin/env bash
# usage (from a tree root): .claude/audit/round13-fordebug-proto/run-probe.sh <tag>
# writes out-probe-{off,on}-<tag>.txt next to this script (in the tree it is run from)
set -u
tag="${1:?tag}"
dir=.claude/audit/round13-fordebug-proto
./scripts/relink.sh >/dev/null 2>&1
for mode in off on; do
	( ulimit -v 4000000; timeout 300 mise exec -- luau "$dir/probe.luau" -a "$mode" > "$dir/out-probe-$mode-$tag.txt" 2>&1 )
	echo "probe $mode exit $?"
done
