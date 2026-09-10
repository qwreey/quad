--!strict
--[[
	`type-version-check` 계약 — 런타임 `matchesPattern`과 그 복제본인
	`export type function CheckVersion`의 패턴 판정(`type-version-check/src/init.luau`
	머리 주석 "패턴 문법" 절이 소스).

	**왜 quad-base/test에 두나**: `type-version-check`는 엔진 무관 패키지고
	자기 test 디렉토리가 없다(워크스페이스 멤버 중 test를 가진 건 quad-base와
	quad-roblox뿐). 그런데 `scripts/test.sh`의 두 검사 그룹 중 **컴파일 타임
	`CheckVersion`이 실제로 평가되는 건 quad-base 쪽(`luau-analyze`)뿐이다** —
	quad-roblox 그룹이 쓰는 `luau-lsp analyze`는 `type function` 본문의
	`pcall`을 "Unknown global"로 보고 그 type function을 아예 평가하지 않는다
	(2026-09-10 실측: 틀린 버전을 넣어도 진단이 안 뜬다). 그래서 타입 층
	케이스가 vacuous해지지 않도록 여기 둔다. 소스는 워크스페이스 멤버라
	`../../type-version-check/src`로 직접 require한다(spec.*가 이미 쓰는
	크로스 멤버 상대 경로 관례 — quad-roblox/test가 mock을 그렇게 집는다).

	**[2026-09-10] 회귀 확인**: 이 파일 이전엔 `matchesPattern` 스펙이 아예
	없어서, 옛 본문(HEAD)과 새 본문에 actual 14 × pattern 14를 전부 먹여
	직접 대조했다 — 달라진 196분의 23은 **전부 한쪽에 `-`나 `+` 꼬리가 있는
	쌍**이고, 꼬리 없는 순수 core 쌍의 판정은 하나도 안 변했다. 방향도 하나만
	빼고 전부 넓어지는 쪽(false → true)이며, 유일하게 좁아진 건
	`("3.1.0-rc.1", "3.1.0-rc.*")` 꼴 — 아래 3절에 케이스로 박아 뒀다.

	음성 케이스(불일치)는 타입 층에 둘 수 없다 — `types.never`가 곧 진단이라
	검사 게이트를 깨뜨린다. 아래 타입 케이스는 양성만이고, 음성이 실제로
	무는지는 스크래치로 확인했다(`CheckVersion<"0.0.0", "9.9.9">` →
	`TypeError: type-version-check: version "0.0.0" does not match pattern "9.9.9"`).
]]

local TypeVersionCheck = require("../../type-version-check/src")
local matchesPattern = TypeVersionCheck.matchesPattern

local function expect(actual: string, pattern: string, want: boolean)
	local got = matchesPattern(actual, pattern)
	assert(got == want, `matchesPattern("{actual}", "{pattern}") = {tostring(got)}, expected {tostring(want)}`)
end

print("=== 1. core 자리 — 정확 일치 / 와일드카드 / caret(기존 계약) ===")
do
	expect("0.0.0", "0.0.0", true)
	expect("9.9.9", "0.0.0", false)
	expect("3.1.4", "3.*.*", true)
	expect("4.1.4", "3.*.*", false)
	expect("3.3.4", "3.3^.4^", true)
	expect("3.4.9", "3.3^.4^", true)
	expect("3.2.9", "3.3^.4^", false)
	expect("3.3.3", "3.3^.4^", false)
	-- 자리 개수가 다르면 불일치(기존 의미 유지), 숫자가 아닌 자리에 caret도 불일치
	expect("3.1.0", "3.1", false)
	expect("3.1", "3.1.0", false)
	expect("3.x.0", "3.1^.0", false)
	print("PASS")
end

print()
print("=== 2. [2026-09-10] 패턴에 프리릴리즈가 없으면 actual의 프리릴리즈는 무시 ===")
do
	expect("3.1.0-rc.1", "3.1.0", true)
	expect("3.1.0-rc.1", "3.1.0^", true) -- caret은 core 자리에만 걸린다
	expect("3.1.0-rc.1", "3.*.*", true)
	expect("3.0.1-dev.3", "3.0.0^", true)
	-- 꼬리를 뗀 core는 그대로 자리 개수 규칙을 탄다
	expect("3.1.0-rc.1", "3.1^", false)
	expect("3.1.0-rc.1", "4.*.*", false)
	print("PASS")
end

print()
print("=== 3. [2026-09-10] 패턴에 프리릴리즈가 있으면 정확 일치 ===")
do
	expect("3.1.0-rc.1", "3.1.0-rc.1", true)
	expect("3.1.0-rc.2", "3.1.0-rc.1", false)
	expect("3.0.0", "3.0.0-rc.1", false) -- 꼬리 없는 릴리즈는 프리릴리즈 패턴에 안 맞는다
	expect("3.1.0-rc.1", "3.1.0-rc.1", true)
	-- 첫 `-`만 구분자 — 프리릴리즈 안의 `-`는 문자열의 일부
	expect("3.0.0-rc-1", "3.0.0-rc-1", true)
	expect("3.0.0-rc-1", "3.0.0-rc", false)
	-- 프리릴리즈 자리엔 와일드카드/caret이 안 먹는다(문자열 그대로 비교).
	-- ⚠️ 이번 변경이 유일하게 **좁힌** 방향 — 꼬리를 안 가르던 예전 로직에선
	-- `"3.1.0-rc.*"`가 `.` 분할 4자리째의 `*`로 통과했다(true → false).
	expect("3.1.0-rc.1", "3.1.0-*", false)
	expect("3.1.0-rc.1", "3.1.0-rc.*", false)
	expect("3.1.0-rc.1", "3.1.0-rc.^", false)
	-- core 규칙은 프리릴리즈가 있어도 그대로 적용된다
	expect("3.4.0-rc.1", "3.3^.0-rc.1", true)
	expect("3.2.0-rc.1", "3.3^.0-rc.1", false)
	print("PASS")
end

print()
print("=== 4. [2026-09-10] build(`+` 뒤)는 양쪽 다 항상 무시 ===")
do
	expect("3.0.0+build.5", "3.0.0", true)
	expect("3.0.0-rc.1+build.5", "3.0.0-rc.1", true)
	expect("3.0.0", "3.0.0+build.5", true)
	expect("3.0.0+build.5", "3.0.0+other.9", true)
	-- `+`를 먼저 자르므로 build 안의 `-`는 프리릴리즈 구분자가 아니다
	expect("3.0.0+build-7", "3.0.0", true)
	expect("3.0.0+build-7", "3.0.0-build-7", false)
	print("PASS")
end

print()
print("=== 5. 깨진 입력은 그대로 false(별도 방어 없음) ===")
do
	expect("", "3.0.0", false)
	expect("3.0.0", "", false)
	expect("-", "3.0.0", false)
	expect("-", "", true) -- 둘 다 core가 빈 문자열 한 자리 — 예전에도 지금도 방어하지 않는 자리
	expect("3.0.0-", "3.0.0", true) -- 빈 프리릴리즈도 "꼬리가 있다"로 취급 — 패턴에 없으니 무시
	expect("3.0.0", "3.0.0-", false) -- 패턴의 빈 프리릴리즈는 actual의 빈 프리릴리즈만 통과
	expect("3.0.0-", "3.0.0-", true)
	print("PASS")
end

print()
print("=== 6. 컴파일 타임 CheckVersion — 같은 규칙(양성만, luau-analyze가 실제로 평가) ===")
do
	-- 인스턴스화 자리에서 실제로 해석돼야 평가된다(luau-test `23`의 함정 2)
	local _core: TypeVersionCheck.CheckVersion<"0.0.0", "0.0.0"> = true
	local _glob: TypeVersionCheck.CheckVersion<"3.1.4", "3.*.*"> = true
	local _caret: TypeVersionCheck.CheckVersion<"3.4.9", "3.3^.4^"> = true
	local _preIgnored: TypeVersionCheck.CheckVersion<"3.1.0-rc.1", "3.1.0"> = true
	local _preExact: TypeVersionCheck.CheckVersion<"3.1.0-rc.1", "3.1.0-rc.1"> = true
	local _build: TypeVersionCheck.CheckVersion<"3.0.0+build.5", "3.0.0"> = true
	local _both: TypeVersionCheck.CheckVersion<"3.0.0-rc.1+build.5", "3.0.0-rc.1"> = true
	assert(_core and _glob and _caret and _preIgnored and _preExact and _build and _both, "type-level cases carry a trivial `true`")
	print("PASS")
end

print()
print("=== ALL PASS ===")
