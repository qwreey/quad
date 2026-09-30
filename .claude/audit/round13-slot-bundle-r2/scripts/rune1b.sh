#!/usr/bin/env bash
# e1b probe minus C3x (oscillating graph — no fixed point; with the Q73 install loop and no cap it never ends)
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/r2
out="$S/probes/e1b.noc3x.out.txt"; : > "$out"
for v in ${VARIANTS:-base q74 q76 A Ap}; do
	sed 's/^T("C3x", function()/local _c3x = (function()/' "$S/base/.claude/audit/round13-e1b-probe.luau" > "$S/fz/$v/test/xr_e1b_noc3x.luau"
	echo "######## $v" >> "$out"
	(cd "$S/fz/$v" && timeout 300 luau test/xr_e1b_noc3x.luau < /dev/null >> "$out" 2>&1; echo "[exit $?]" >> "$out")
done
