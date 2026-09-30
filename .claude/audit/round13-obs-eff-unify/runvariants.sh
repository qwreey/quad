#!/usr/bin/env bash
# runs runall.sh for each variant in turn (installing it first); leaves Unest installed
SCR=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs-eff-unify
for v in "$@"; do
  bash $SCR/setv.sh $v
  bash $SCR/runall.sh $v 3000
done
bash $SCR/setv.sh Unest
