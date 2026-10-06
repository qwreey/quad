#!/bin/bash
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad
v=$1; b=$2
name=run_$(basename $v .txt)_$(basename $b .luau)
{ echo '--!strict'; cat $v; } > $S/tree/probes/_hdr.tmp
off=$(wc -l < $S/tree/probes/_hdr.tmp)
cat $S/tree/probes/_hdr.tmp $b > $S/tree/probes/$name.luau
t0=$(date +%s%N)
$S/lsp.sh $S/tree probes/$name.luau > $S/tree/probes/$name.out
t1=$(date +%s%N)
python3 $S/check.py $off $b $S/tree/probes/$name.out
echo "  time=$(( (t1-t0)/1000000 ))ms"
