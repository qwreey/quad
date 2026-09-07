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
# [2026-09-07 H-404, 사용자 실측] `function name()` without a prior `local name` is a
# GLOBAL assignment (sugar for `name = function`); luau-analyze only lints it
# (GlobalUsedAsLocal, exit 0), so the gate is here — any such lint fails the run.
analyze_out=$(luau-analyze quad-base/src quad-types/src quad-error/src quad-base/test/spec.*.luau quad-base/test/mock.luau 2>&1) || fail=1
printf '%s\n' "$analyze_out"
if printf '%s' "$analyze_out" | grep -q "GlobalUsedAsLocal"; then echo "FAIL: implicit global function definition (add a forward \`local\` declaration)"; fail=1; fi
# ⚠️ defs 로드는 luau-analyze가 아니라 luau-lsp의 기능이다(이 빌드의
# luau-analyze엔 --defs 옵션 자체가 없음 — 실측). 새 솔버 플래그 필수
# (없으면 quad-types의 type function이 "syntax not supported"로 죽음),
# --ignore로 의존 패키지 사본의 진단은 숨긴다(그쪽은 위 그룹이 원본을 봄).
echo "=== luau-lsp analyze --definitions=scripts/roblox-defs/globalTypes.d.luau quad-roblox/src quad-roblox/test/spec.*.luau"
# LuauTarjanChildLimit: 생성 `export type D`/`DMapper`(31클래스 Param 인스턴스화,
# H-305 d′)가 기본 한도(10000)를 넘어 "Code is too complex"를 낸다 — 실측상
# 40000이면 전 그룹 클린, 1.2s대(성능 무해). 한도 자체의 등재는 typing-limits.
# [2026-09-04 M7 단위 ③] 클래스별 `<Class>Modifier`(재귀 setter 수십 개) + `DModifier`
# 네임스페이스가 더해져 40000으로 다시 넘침 — 160000이면 클린(실측), 시간 무해.
# LuauSubtypingIterationLimit(M10 OnChange, 2026-09-03): 생성 `<Class>OnChange`
# 유니언(클래스당 수십 멤버)에 Color3/string처럼 멤버가 많은 타입의 콜백을
# 대조하면 기본 한도에서 "Code is too complex" — 실측상 5만이면 클린, 10만으로
# 핀(시간 무해, 1.8s대). 다른 한도 플래그 6종은 무효였다(typing-limits 8.7절).
# LuauTypeInferIterationLimit(M7 단위 ④, 2026-09-04): 상위 클래스 Modifier 타입
# (`GuiObjectModifier`류, 하위 `As<Class>` 메소드 수십 개)의 캐스트 자리와 그
# 타입의 팩토리를 `Apply`에 넘기는 자리가 기본 한도(20000)에서 "too complex" —
# 실측상 50만이면 클린, 100만으로 핀(시간 무해, 3.2s대; typing-limits 8.9절).
# LuauSolverConstraintLimit(round20 InstanceShorthand, 2026-09-06): GuiObject 계열 10클래스의
# Param/Modifier에 숏핸드 키 넷을 얹자 `export type D`(UIStroke 자리)가 "too complex" —
# 이번 증상은 이 한도(기본값 작음)가 듣는다(Tarjan·TypeInfer 상향은 무효). 100만이면 클린,
# 시간 무해(1.9s대). 8.8절의 "올리면 지점만 옮겨감"은 재귀 메소드 테이블 유니언 때 얘기 — typing-limits 8.5절.
lsp_out=$(mise exec -- luau-lsp analyze --flag:LuauSolverV2=true \
	--flag:LuauTarjanChildLimit=160000 \
	--flag:LuauSubtypingIterationLimit=100000 \
	--flag:LuauTypeInferIterationLimit=1000000 \
	--flag:LuauSolverConstraintLimit=1000000 \
	--definitions=scripts/roblox-defs/globalTypes.d.luau \
	--ignore "**/luau_packages/**" \
	quad-roblox/src quad-roblox/test/spec.*.luau 2>&1) || fail=1
printf '%s\n' "$lsp_out" | grep -v "^\[INFO\]" || true
if printf '%s' "$lsp_out" | grep -q "GlobalUsedAsLocal"; then echo "FAIL: implicit global function definition (quad-roblox)"; fail=1; fi
for f in "${files[@]}"; do
	echo "=== $f"
	luau "$f" || fail=1
done
exit "$fail"
