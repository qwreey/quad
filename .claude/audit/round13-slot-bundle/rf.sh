#!/usr/bin/env bash
# rf.sh <variant> <fuzzer> <tag> <from> <count> <flags>
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/p-slot-bundle
v=$1; fz=$2; tag=$3; from=$4; count=$5; flags=${6:-}
o=$S/fzout/$fz.$tag.$v; rm -rf $o; mkdir -p $o
seq $from 100 $((from+count-1)) | xargs -P 4 -I{} sh -c "cd $S/fz/$v && luau test/$fz.luau -a {} 100 0 '$flags' </dev/null > $o/{}.txt 2>&1"
cat $o/*.txt | grep '^R' | awk '{ if ($3=="ok") print "ok"; else { $1="";$2=""; print $0 } }' | sort | uniq -c | sed "s/^/$v $fz.$tag: /"
