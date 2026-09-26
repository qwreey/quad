#!/bin/bash
# show.sh <cand> <TAG> [maxlines]
d=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/q87
ln=$(python3 -c "print(eval(open('$d/$1.lines').read())['$2'])")
awk -v ln="$ln" 'match($0,/probe\.q87\.[^(]*\(([0-9]+),/,m){p=(m[1]==ln)} p' $d/$1.out | grep -v '^\[INFO' | cut -c1-${4:-500} | head -${3:-30}
