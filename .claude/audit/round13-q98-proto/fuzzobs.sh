#!/usr/bin/env bash
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/p-q98; cd $S
run1(){ n=$1; sv=$2; ov=$3; raw=${4:-}; ./mkcombo.sh $n $sv $ov $raw; T=c/$n/quad-base/test; o=out/fz_$n; mkdir -p $o
  ( cd $T
    luau round13-e1b-probe.luau > $S/$o/e1b.txt 2>&1
    luau round13-e3-probe.luau > $S/$o/e3.txt 2>&1
    s=$(date +%s.%N); luau round13-e3-probe-fuzz.luau -a 20000 > $S/$o/e3fuzz20000.txt 2>&1; echo "time $(echo "$(date +%s.%N) - $s" | bc)" >> $S/$o/e3fuzz20000.txt
    luau round13-e3-probe-fuzz.counters.luau -a 20000 > $S/$o/e3counters20000.txt 2>&1
    for m in excl unm anc; do luau probe.e1.reent.modes.luau -a 1 2000 $m > $S/$o/e1reent_$m.txt 2>&1; done
    luau q98-yield-fuzz.luau -a 20000 > $S/$o/yield20000.txt 2>&1
  ) ; echo "$n done"; }
run1 none__none none none
run1 none__obsA none obsA_i
run1 none__obsA2 none obsA2_i
run1 q93q98__obsA q93q98 obsA_i
run1 q93q98__obsA2 q93q98 obsA2_i
run1 q93q98b__obsA2 q93q98b obsA2_i
run1 raw__none none none raw
run1 raw__obsA none obsA_i raw
run1 raw__obsA2 none obsA2_i raw
run1 raw_q93q98__obsA2 q93q98 obsA2_i raw
