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
# 생성 산출물 게이트(M5 단위 ②) — Parent 필드는 덤프 층에서 제외돼야 한다
# (H-142/Q5 (a); CLI Luau엔 io가 없어 spec이 못 보므로 여기서 커밋 산출물을 직접 봄)
if grep -q "	Parent:" quad-roblox/src/D/init.luau; then
	echo "gen-d gate: Parent field leaked into generated D" >&2
	fail=1
fi
if ! grep -q "GENERATED FILE" quad-roblox/src/D/init.luau; then
	echo "gen-d gate: generated banner missing" >&2
	fail=1
fi
# 타입 검사 — relink 뒤라 심볼릭 링크 때문에 조용히 통과하는 "거짓 클린"이 없다.
# smoke.*는 M1 임시 스모크라 제외(느슨하게 쓰였음) — src와 spec/mock만 strict로 본다.
# 두 그룹으로 나눔(M5 단위 ②): quad-base·quad-types·quad-error는 **defs 없이**
# 돌아야 한다(엔진 무관 보장 — Roblox 전역을 쓰면 여기서 걸린다). quad-roblox는
# Roblox 타입(TweenInfo/Enum/Instance…)을 쓰므로 핀 고정된 globalTypes defs로 본다
# (scripts/roblox-defs/ — luau-lsp 버전은 mise.toml 핀과 맞출 것).
echo "=== luau-analyze (engine-agnostic) quad-base/src quad-types/src quad-error/src quad-base/test/spec.*.luau quad-base/test/mock.luau"
luau-analyze quad-base/src quad-types/src quad-error/src quad-base/test/spec.*.luau quad-base/test/mock.luau || fail=1
# ⚠️ defs 로드는 luau-analyze가 아니라 luau-lsp의 기능이다(이 빌드의
# luau-analyze엔 --defs 옵션 자체가 없음 — 실측). 새 솔버 플래그 필수
# (없으면 quad-types의 type function이 "syntax not supported"로 죽음),
# --ignore로 의존 패키지 사본의 진단은 숨긴다(그쪽은 위 그룹이 원본을 봄).
echo "=== luau-lsp analyze --definitions=scripts/roblox-defs/globalTypes.d.luau quad-roblox/src quad-roblox/test/spec.*.luau"
# LuauTarjanChildLimit: 생성 `export type D`/`DMapper`(31클래스 Param 인스턴스화,
# H-305 d′)가 기본 한도(10000)를 넘어 "Code is too complex"를 낸다 — 실측상
# 40000이면 전 그룹 클린, 1.2s대(성능 무해). 한도 자체의 등재는 typing-limits.
lsp_out=$(mise exec -- luau-lsp analyze --flag:LuauSolverV2=true \
	--flag:LuauTarjanChildLimit=40000 \
	--definitions=scripts/roblox-defs/globalTypes.d.luau \
	--ignore "**/luau_packages/**" \
	quad-roblox/src quad-roblox/test/spec.*.luau 2>&1) || fail=1
printf '%s\n' "$lsp_out" | grep -v "^\[INFO\]" || true
for f in "${files[@]}"; do
	echo "=== $f"
	luau "$f" || fail=1
done
exit "$fail"
