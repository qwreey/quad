#!/usr/bin/env bash
# Run every smoke/spec of the patched scratch copy under `luau --coverage`, one cwd per file.
# usage: run_cov.sh <copy-root> <outdir>
set -u
R=$1; O=$2; mkdir -p "$O/cov" "$O/log"
fail=0
for f in "$R"/quad-base/test/smoke.*.luau "$R"/quad-base/test/spec.*.luau "$R"/quad-roblox/test/spec.*.luau; do
  n=$(basename "$f" .luau); d="$O/cov/$n"; mkdir -p "$d"
  (cd "$d" && luau --coverage "$f" > "$O/log/$n.txt" 2>&1); rc=$?
  echo "$n $rc" >> "$O/exit.txt"; [ $rc -ne 0 ] && fail=1
done
exit $fail
