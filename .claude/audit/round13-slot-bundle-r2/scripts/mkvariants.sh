#!/usr/bin/env bash
# build q74-only and q76-only full copies + fuzz copies from the base copy
set -e
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/r2
cd "$S"
cp -r base q74
cp -r base q76
(cd q74 && patch -p0 --no-backup-if-mismatch < .claude/audit/round13-e1b-probe-patches/Raw.owner-chain.diff)
(cd q76 && patch -p0 --no-backup-if-mismatch < .claude/audit/round13-q76-proto/List.keygone-first-descending.diff)
for v in q74 q76; do
	cp -r "$v/quad-base/src/." "$v/quad-roblox/luau_packages/.pesde/qwreey+quad_base/3.2.0/quad_base/src/"
	diff -rq "$v/quad-base/src" "$v/quad-roblox/luau_packages/.pesde/qwreey+quad_base/3.2.0/quad_base/src" && echo "$v synced"
	cp -r "$v/quad-base" "fz/$v"
	cp fz/base/test/*.luau "fz/$v/test/"
	(cd "fz/$v" && patch -p1 --no-backup-if-mismatch < ../../base/.claude/audit/round13-q111-proto/HOOKS.scratch-probe.diff)
done
