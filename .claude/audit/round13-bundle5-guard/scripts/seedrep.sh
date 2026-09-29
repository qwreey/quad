#!/usr/bin/env bash
# usage: seedrep.sh <seed> <reps> <mode> — rerun the trace fuzzer up to <seed> <reps> times per tree,
# tally the hash of that seed (order-noise distribution per tree).
set -uo pipefail
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/bundle5-guard
SEED=$1; REPS=$2; MODE=$3
for t in before after; do
  echo "== $t"
  for i in $(seq 1 "$REPS"); do
    ( cd "$S/tree.$t/quad-base/test" && luau b5-trace-fuzz.luau -a "$SEED" "$MODE" ) | grep "^$SEED "
  done | sort | uniq -c
done
