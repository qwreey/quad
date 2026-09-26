#!/usr/bin/env bash
# usage: runfuzz.sh <variant> <tag> <from> <count> <flags>
set -u
D=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/p-q111
v=$1; tag=$2; from=$3; count=$4; flags=${5:-}
mkdir -p $D/fz/$v.$tag
seq $from 100 $((from+count-1)) | xargs -P 4 -I{} sh -c "cd $D/$v && luau test/fuzz.q111.luau -a {} 100 0 '$flags' </dev/null | grep '^R' > $D/fz/$v.$tag/{}.txt 2>&1"
cat $D/fz/$v.$tag/*.txt | awk '{ if ($3=="ok") print "ok"; else print $0 }' | sort | uniq -c
