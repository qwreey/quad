#!/usr/bin/env bash
# usage: runprobe.sh <probe.luau> [subdir=quad-base/test] [args...] — copies the probe into both
# scratch trees (before/after) and runs it there; output → out/<name>.<before|after>.txt
set -uo pipefail
S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/bundle5-guard
P=$1; SUB=${2:-quad-base/test}; shift; shift || true
name=$(basename "$P" .luau)
mkdir -p "$S/out"
for t in before after; do
  cp "$P" "$S/tree.$t/$SUB/"
  ( cd "$S/tree.$t/$SUB" && luau "$(basename "$P")" -a "$@" ) > "$S/out/$name.$t.txt" 2>&1
  echo "$t exit=$?"
done
