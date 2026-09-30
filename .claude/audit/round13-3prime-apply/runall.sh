#!/usr/bin/env bash
# usage: runall.sh <label> [fuzzN] — runs round13 probes + obs-eff probes against the worktree's CURRENT quad-base/src
set -uo pipefail
W=/code/Projects/quad/.claude/worktrees/obs3p
SCR=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs3p
L=$1; N=${2:-3000}; O=$SCR/out/$L; mkdir -p $O
A=$W/.claude/audit; T=$W/quad-base/test
cd $W && ./scripts/relink.sh >/dev/null 2>&1
{ head -n 1 $A/round13-e1b-probe.luau; echo "do local P = (require(\"../src/Observer\") :: any).PROBE; if P then P.cap = 100 end end"; tail -n +2 $A/round13-e1b-probe.luau; } > $T/xr_e1b.luau
cp $A/round13-e3-probe.luau $T/xr_e3.luau
cp $A/round13-e3-probe-fuzz.luau $T/xr_e3fuzz.luau
cp $A/round13-e1b-probe-patches/round13-e3-probe-fuzz.counters.luau $T/xr_e3counters.luau
cp $A/round13-e1b-probe-patches/probe.e1.reent.modes.luau $T/xr_e1reent.luau
cp $A/round13-e1-probe-fuzz/probe.e1.harness.luau $T/probe.e1.harness.luau
cp $A/round13-q98-proto/osc-probe.luau $T/xr_osc.luau
cp $A/round13-q98-proto/throw-install.luau $T/xr_throw.luau
cp $SCR/xprobe-obseff.luau $T/xr_obseff.luau
cp $SCR/probe-debounce.luau $T/xr_deb.luau
cp $SCR/probe-effnest.luau $T/xr_effnest.luau
if [ -f $SCR/uprobe.luau ]; then cp $SCR/uprobe.luau $T/xr_u.luau; fi
mkdir -p $W/xaudit
cp $A/round13-q109-proto/q109-probe.luau $A/round13-q109-proto/q110-probe.luau $W/xaudit/
cd $T
timeout 300 luau xr_obseff.luau > $O/obseff.txt 2>&1
timeout 300 luau xr_deb.luau > $O/debounce.txt 2>&1
timeout 300 luau xr_effnest.luau > $O/effnest.txt 2>&1
if [ -f xr_u.luau ]; then timeout 300 luau xr_u.luau > $O/uprobe.txt 2>&1; fi
timeout 300 luau xr_e1b.luau > $O/e1b.txt 2>&1
timeout 300 luau xr_e3.luau > $O/e3.txt 2>&1
timeout 900 luau xr_e3fuzz.luau -a $N > $O/e3fuzz.txt 2>&1
timeout 900 luau xr_e3counters.luau -a $N > $O/e3counters.txt 2>&1
for m in excl unm anc; do timeout 900 luau xr_e1reent.luau -a 1 2000 $m > $O/e1reent_$m.txt 2>&1; done
timeout 300 luau xr_osc.luau > $O/osc.txt 2>&1
timeout 300 luau xr_throw.luau > $O/throw.txt 2>&1
cd $W/xaudit
timeout 300 luau q109-probe.luau > $O/q109.txt 2>&1
timeout 300 luau q110-probe.luau > $O/q110.txt 2>&1
cd $A
for p in a b c c2b c3 d d3 e g h; do timeout 300 luau round13-e20-probe-$p.luau > $O/e20-$p.txt 2>&1; done
cd $W
timeout 300 luau .claude/audit/round13-e79-deferred-signals/probe.luau > $O/e79.txt 2>&1
rm -f $T/xr_*.luau $T/probe.e1.harness.luau
rm -rf $W/xaudit
echo "done $L"
