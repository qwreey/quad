#!/usr/bin/env bash
# mkcombo.sh <name> <stateVariant|none> <observerVariant|none> [raw]
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/p-q98
cd $S; n=$1; sv=$2; ov=$3; d=c/$n; rm -rf $d; mkdir -p c; cp -r base $d
[ "$sv" != none ] && cp v/$sv/quad-base/src/State.luau $d/quad-base/src/State.luau
[ "$ov" != none ] && cp obs/$ov.Observer.luau $d/quad-base/src/Observer.luau
if [ "${4:-}" = raw ]; then (cd $d && patch -s -p0 < /code/Projects/quad/.claude/audit/round13-e1b-probe-patches/Raw.owner-chain.diff); fi
A=/code/Projects/quad/.claude/audit
cp $A/round13-e1b-probe.luau $A/round13-e3-probe.luau $A/round13-e3-probe-fuzz.luau $A/round13-e1b-probe-patches/round13-e3-probe-fuzz.counters.luau $A/round13-e1b-probe-patches/probe.e1.reent.modes.luau $A/round13-e1-probe-fuzz/probe.e1.harness.luau $S/probes/*.luau $d/quad-base/test/
