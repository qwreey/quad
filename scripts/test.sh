#!/usr/bin/env bash
# 테스트 — 리링크를 먼저 돌린다(scripts/relink.sh 주석 참고). smoke.* = M1 스모크, spec.* = 모듈 계약 테스트.
set -euo pipefail
shopt -s nullglob
cd "$(dirname "$0")/.."
./scripts/relink.sh
files=(quad-base/test/smoke.*.luau quad-base/test/spec.*.luau quad-roblox/test/spec.*.luau)
if [ "${#files[@]}" -eq 0 ]; then
	echo "no tests found (quad-base/test/{smoke,spec}.*.luau, quad-roblox/test/spec.*.luau)" >&2
	exit 1
fi
fail=0
# 타입 검사 — relink 뒤라 심볼릭 링크 때문에 조용히 통과하는 "거짓 클린"이 없다.
# smoke.*는 M1 임시 스모크라 제외(느슨하게 쓰였음) — src와 spec/mock만 strict로 본다.
echo "=== luau-analyze quad-base/src quad-roblox/src quad-types/src quad-error/src quad-base/test/spec.*.luau quad-roblox/test/spec.*.luau quad-base/test/mock.luau"
luau-analyze quad-base/src quad-roblox/src quad-types/src quad-error/src quad-base/test/spec.*.luau quad-roblox/test/spec.*.luau quad-base/test/mock.luau || fail=1
for f in "${files[@]}"; do
	echo "=== $f"
	luau "$f" || fail=1
done
exit "$fail"
