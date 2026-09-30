#!/usr/bin/env bash
# quad-base-local probes (require ./mock) run from fz/<v>; outputs to probes/<probe>.out.txt with a header per variant
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/r2
mkdir -p "$S/probes"
for p in ${PROBES:-probe.bundle.interact probe.bundle.interact2 probe.q111 probe.e19.boundary probe.e19.state-occupant probe.e19.stale-destroywalk probe.q75a.itemloop probe.q75b.gonefirst probe.throwstate}; do
	out="$S/probes/$p.out.txt"; : > "$out"
	for v in ${VARIANTS:-base q74 q76 A Ap}; do
		echo "######## $v" >> "$out"
		(cd "$S/fz/$v" && timeout 300 luau "test/$p.luau" < /dev/null >> "$out" 2>&1; echo "[exit $?]" >> "$out")
	done
done
