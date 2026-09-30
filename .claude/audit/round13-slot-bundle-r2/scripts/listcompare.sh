#!/usr/bin/env bash
# stage list fuzzer outputs in the layout round13-q76b-proto/compare.py expects (out/<mode><variant>.<n>.txt), then compare
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/r2
C="$S/lcmp"; mkdir -p "$C/out"; find "$C/out" -name '*.txt' -delete
for mode in plain rowgrow; do
	for v in base q74 q76 A Ap; do
		for f in "$S/fzout/list.$mode.$v"/*.txt; do ln -s "$f" "$C/out/$mode$v.$(basename "$f")"; done
	done
done
for mode in plain rowgrow; do
	for pair in "base A" "base q76" "q76 A" "A Ap" "base q74"; do
		set -- $pair
		echo "== $mode $1 vs $2"
		python3 "$S/base/.claude/audit/round13-q76b-proto/compare.py" "$C" "$mode$1" "$mode$2" 2>&1 | head -8
	done
done
