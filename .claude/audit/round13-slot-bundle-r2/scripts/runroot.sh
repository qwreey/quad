#!/usr/bin/env bash
# root-level probes (round13-e15-probe-setup based: q113/q114/E23; E72 probe-q75) on every full copy
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/r2
mkdir -p "$S/probes"
: > "$S/probes/probe.q113.out.txt"; : > "$S/probes/probe.q114.out.txt"; : > "$S/probes/probe-q75.out.txt"; : > "$S/probes/e23.dist.3runs.txt"
for v in ${VARIANTS:-base q74 q76 A Ap}; do
	cd "$S/$v"
	cp .claude/audit/round13-q113-proto/probe.q113.luau .claude/audit/round13-q113-proto/probe.q114.luau .claude/audit/
	for p in q113 q114; do
		echo "######## $v" >> "$S/probes/probe.$p.out.txt"
		timeout 300 luau ".claude/audit/probe.$p.luau" < /dev/null >> "$S/probes/probe.$p.out.txt" 2>&1; echo "[exit $?]" >> "$S/probes/probe.$p.out.txt"
	done
	echo "######## $v" >> "$S/probes/probe-q75.out.txt"
	timeout 300 luau .claude/audit/round13-e72-nested-slot-fuzz/probe-q75.luau < /dev/null >> "$S/probes/probe-q75.out.txt" 2>&1; echo "[exit $?]" >> "$S/probes/probe-q75.out.txt"
	for e in e2 e3 e4; do
		echo "## $v $e" >> "$S/probes/e23.dist.3runs.txt"
		for r in 1 2 3; do
			timeout 300 luau ".claude/audit/round13-e23-probe-$e.luau" < /dev/null 2>&1 | sed "s/^/  r$r /" >> "$S/probes/e23.dist.3runs.txt"
		done
	done
done
