#!/usr/bin/env bash
# bench.slot-bundle.luau, -O2, 3 runs per variant, sequential (nothing else running)
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/r2
mkdir -p "$S/bench"
for r in 1 2 3; do
	for v in base q74 q76 A Ap; do
		(cd "$S/fz/$v" && luau -O2 test/bench.slot-bundle.luau < /dev/null > "$S/bench/$v.$r.txt" 2>&1)
	done
done
