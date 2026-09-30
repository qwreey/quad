#!/usr/bin/env bash
# copy results + scripts into the worktree audit folder
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/r2
D=/code/Projects/quad/.claude/worktrees/agent-a1312e370d7cf7b42/.claude/audit/round13-slot-bundle-r2
mkdir -p "$D/probes" "$D/bench" "$D/scripts" "$D/gate"
cp "$S"/probes/*.txt "$D/probes/"
cp "$S"/bench/*.txt "$D/bench/"
cp "$S/bench.summary.txt" "$S/fuzz.e19-q111.summary.txt" "$S/list.compare.txt" "$S/reent.summary.txt" "$D/"
python3 "$S/listcmp.py" > "$D/list.positional-diff.txt"
cp "$S/test.base.txt" "$D/gate/test.sh.HEAD.txt"
cp "$S/test.A.txt" "$D/gate/test.sh.A.txt"
cp "$S/test.Ap.txt" "$D/gate/test.sh.Aprime.txt"
cp "$S"/*.sh "$S"/*.py "$D/scripts/"
