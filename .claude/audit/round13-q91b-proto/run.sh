#!/usr/bin/env bash
# usage: run.sh <Q91_ON> <MODE> <Q82> [probe-only]
S=$(dirname "$0"); P=$S/quad-roblox/src/Handlers/Property.luau
sed -i -E "s/^local Q91_ON = .*/local Q91_ON = $1/; s/^local TEARDOWN_MODE = .*/local TEARDOWN_MODE = \"$2\"/; s/^local Q82_GATE = .*/local Q82_GATE = $3/" $P
cd $S/quad-roblox
echo "##### Q91=$1 MODE=$2 Q82=$3"
if [ -z "$4" ]; then
fails=""
for f in test/spec.*.luau; do out=$(luau $f 2>&1); if ! printf '%s' "$out" | grep -q "ALL PASS"; then fails="$fails $(basename $f):$(printf '%s' "$out" | grep -m1 -iE 'error|assert|fail' | cut -c1-200)"; fi; done
echo "specs(quad-roblox) fails:${fails:- none}"
fi
luau test/probe.q91b.luau
luau test/probe.q91teardown.luau
