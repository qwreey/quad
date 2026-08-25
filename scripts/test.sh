#!/usr/bin/env bash
# 스모크 테스트 — 리링크를 먼저 돌린다(scripts/relink.sh 주석 참고).
set -euo pipefail
shopt -s nullglob
cd "$(dirname "$0")/.."
./scripts/relink.sh
files=(quad-base/test/smoke.*.luau)
if [ "${#files[@]}" -eq 0 ]; then
	echo "no smoke tests found (quad-base/test/smoke.*.luau)" >&2
	exit 1
fi
fail=0
for f in "${files[@]}"; do
	echo "=== $f"
	luau "$f" || fail=1
done
exit "$fail"
