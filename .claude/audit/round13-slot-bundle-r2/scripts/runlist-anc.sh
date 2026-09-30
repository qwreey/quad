#!/usr/bin/env bash
# list fuzzer (seeds 1..2000, plain|rowgrow) + reentrancy fuzzer (anc|unm|excl, seeds 1..6000) on every fuzz copy
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/r2
cd "$S"
for v in ${VARIANTS:-base q74 q76 A Ap}; do
	for mode in plain rowgrow; do
		o="$S/fzout/list.$mode.$v"; mkdir -p "$o"; find "$o" -name '*.txt' -delete
		seq 1 100 2000 | xargs -P 4 -I{} sh -c "cd $S/fz/$v && luau test/fuzz.list.luau -a {} 100 0 $mode </dev/null > $o/{}.txt 2>&1"
	done
	for mode in anc unm excl; do
		o="$S/fzout/reent.$mode.$v"; mkdir -p "$o"; find "$o" -name '*.txt' -delete
		printf '1\n2001\n4001\n' | xargs -P 3 -I{} sh -c "cd $S/fz/$v && luau test/probe.e1.reent.modes.luau -a {} 2000 $mode </dev/null > $o/{}.txt 2>&1"
		awk -v v="$v" -v m="$mode" '/^obsOps/ { f += $6; r += $4; p += $8; s = s " " $10 } END { printf "%s %s (6000 seeds) fails=%d rej0167=%d physBad=%d seeds:%s\n", v, m, f, r, p, s }' "$o"/*.txt
	done
done
