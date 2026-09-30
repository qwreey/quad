#!/usr/bin/env bash
# larger fuzz on whatever is installed; label arg
SCR=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs3p
W=/code/Projects/quad/.claude/worktrees/obs3p
A=$W/.claude/audit; T=$W/quad-base/test; L=$1; O=$SCR/out/$L; mkdir -p $O
cd $W && ./scripts/relink.sh >/dev/null 2>&1
cp $A/round13-e3-probe-fuzz.luau $T/xr_e3fuzz.luau
cp $A/round13-e1b-probe-patches/round13-e3-probe-fuzz.counters.luau $T/xr_e3counters.luau
cp $A/round13-e1b-probe-patches/probe.e1.reent.modes.luau $T/xr_e1reent.luau
cp $A/round13-e1-probe-fuzz/probe.e1.harness.luau $T/probe.e1.harness.luau
cd $T
luau xr_e3fuzz.luau -a 20000 > $O/e3fuzz20000.txt 2>&1
luau xr_e3counters.luau -a 20000 > $O/e3counters20000.txt 2>&1
for m in excl unm; do luau xr_e1reent.luau -a 1 6000 $m > $O/e1reent6000_$m.txt 2>&1; done
rm -f $T/xr_*.luau $T/probe.e1.harness.luau
tail -n 1 $O/e3fuzz20000.txt; tail -n 1 $O/e3counters20000.txt
for m in excl unm; do tail -n 1 $O/e1reent6000_$m.txt | cut -c1-200; done
