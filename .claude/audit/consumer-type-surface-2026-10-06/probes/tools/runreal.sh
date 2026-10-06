#!/bin/bash
# runreal.sh <treeDir> <body>  -- body includes its own header (offset 0)
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad
T=$1; b=$2; name=$(basename $b .luau)
mkdir -p $T/probes; cp $b $T/probes/$name.luau
t0=$(date +%s%N)
$S/lsp.sh $T probes/$name.luau > $T/probes/$name.out
t1=$(date +%s%N)
python3 $S/check.py 0 $b $T/probes/$name.out
echo "  time=$(( (t1-t0)/1000000 ))ms"
