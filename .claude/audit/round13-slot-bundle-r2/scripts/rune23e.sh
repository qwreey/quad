#!/usr/bin/env bash
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/r2
out="$S/probes/probe-e23e.out.txt"; : > "$out"
for v in ${VARIANTS:-base q74 q76 A Ap}; do
	cd "$S/$v"
	echo "######## $v" >> "$out"
	timeout 300 luau .claude/audit/round13-e23-probe-e.luau < /dev/null >> "$out" 2>&1; echo "[exit $?]" >> "$out"
done
