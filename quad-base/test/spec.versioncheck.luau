--!strict
--[[
	`type-version-check` 계약 — 런타임 `matchesPattern`과 그 복제본인
	`export type function CheckVersion`의 패턴 판정(`type-version-check/src/init.luau`
	머리 주석 "패턴 문법" 절이 소스). **[2026-09-15]** `|` 대안·꼬리 유무 일치·프리릴리즈 자리 `*`/`^`로
	재정의 — 옛 2절(꼬리 무시)·3절(꼬리엔 와일드카드 안 먹음)·5절 일부는 뒤집혔다.

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

print("=== 1. core 자리 — 정확 일치 / 와일드카드 / 사전식 caret ===")
do
	expect("0.0.0", "0.0.0", true)
	expect("9.9.9", "0.0.0", false)
	expect("3.1.4", "3.*.*", true)
	expect("4.1.4", "3.*.*", false)
	expect("3.3.4", "3.3^.4^", true)
	expect("3.4.9", "3.3^.4^", true)
	expect("3.2.9", "3.3^.4^", false)
	expect("3.3.3", "3.3^.4^", false)
	-- [2026-09-15 사용자 결정] caret은 사전식 하한 — 앞 caret 자리가 최솟값을 넘으면 뒤 자리는 보지 않는다
	expect("3.4.0", "3.3^.4^", true) -- 옛 자리별 독립 판정에선 false(패치 0 < 4)
	expect("3.3.0", "3.2^.1^", true)
	expect("3.2.0", "3.2^.1^", false)
	expect("3.2.1", "3.2^.1^", true)
	expect("4.0.0", "3^.2^.0^", true)
	expect("4.0.0", "3.2^.0^", false) -- caret 없는 앞 자리는 여전히 정확 일치(메이저 고정)
	expect("3.9.0", "3.2^.0", true) -- 넘은 뒤엔 뒤의 정확 자리도 무시
	-- 자리 개수가 다르면 불일치, 숫자가 아닌 자리에 caret도 불일치
	expect("3.1.0", "3.1", false)
	expect("3.1", "3.1.0", false)
	expect("3.x.0", "3.1^.0", false)
	print("PASS")
end

print()
print("=== 2. [2026-09-15 사용자 결정] 프리릴리즈와 릴리즈는 섞이지 않는다 — 꼬리 유무가 같아야 한다(옛 2026-09-10 '무시' 규칙 철회) ===")
do
	expect("3.1.0-rc.1", "3.1.0", false)
	expect("3.1.0-rc.1", "3.*.*", false) -- 느슨한 패턴도 rc를 받지 않는다(사용자: 나쁠 것 없음)
	expect("3.0.1-dev.3", "3.0.0^", false)
	expect("3.1.0", "3.1.0-rc.1", false) -- 꼬리 있는 패턴은 릴리즈를 받지 않는다
	-- rc도 받고 싶은 쪽은 `|`로 꼬리 달린 대안을 더한다
	expect("3.1.0-rc.1", "3.1.0|3.1.0-rc.*", true)
	expect("3.1.0", "3.1.0|3.1.0-rc.*", true)
	print("PASS")
end

print()
print("=== 3. [2026-09-15] 프리릴리즈 자리 — 글자는 정확 일치, 숫자는 `*`/사전식 `^`, core와 따로 판정 ===")
do
	expect("3.1.0-rc.1", "3.1.0-rc.1", true)
	expect("3.1.0-rc.2", "3.1.0-rc.1", false)
	expect("3.1.0-rc.2", "3.1.0-rc.1^", true)
	expect("3.1.0-rc.0", "3.1.0-rc.1^", false)
	expect("3.1.0-beta.5", "3.1.0-rc.1^", false) -- 글자 자리는 크고 작음을 따지지 않는다
	expect("3.1.0-rc.1", "3.1.0-rc.*", true) -- 옛 규칙(꼬리엔 `*`/`^` 안 먹음)에선 false
	expect("3.1.0-rc.1", "3.1.0-rc^.1", false) -- 숫자가 아닌 자리의 caret은 불일치
	expect("3.1.0-rc.1", "3.1.0-*", false) -- 자리 개수 불일치
	expect("3.1.0-rc.2.1", "3.1.0-rc.2^", false) -- 자리 개수 불일치(사용자 결정)
	-- 첫 `-`만 구분자 — 프리릴리즈 안의 `-`는 문자열의 일부
	expect("3.0.0-rc-1", "3.0.0-rc-1", true)
	expect("3.0.0-rc-1", "3.0.0-rc", false)
	-- core에서 넘어도 prerelease는 따로 본다(사용자: rc를 적는 쪽은 앞이 확정 버전인 걸 안다)
	expect("3.4.0-rc.0", "3.3^.0^-rc.1^", false)
	expect("3.4.0-rc.2", "3.3^.0^-rc.1^", true)
	expect("3.2.0-rc.5", "3.3^.0^-rc.1^", false)
	-- 프리릴리즈 bump가 쓰는 정확 패턴(check-version.py) — 그 rc만
	expect("3.3.0-rc.2", "3.3.0-rc.2", true)
	expect("3.4.0-rc.2", "3.3.0-rc.2", false)
	print("PASS")
end

print()
print("=== 4. [2026-09-15 사용자 설계] `|` 대안 — 하나라도 맞으면 통과(메이저 여럿과 호환되는 소비자) ===")
do
	expect("3.5.1", "3.2^.0^|4.0^.0^", true)
	expect("4.1.0", "3.2^.0^|4.0^.0^", true)
	expect("5.0.0", "3.2^.0^|4.0^.0^", false) -- 새 메이저는 소비자가 확인한 뒤 `|5.0^.0^`를 더한다
	expect("3.1.9", "3.2^.0^|4.0^.0^", false)
	expect("3.3.0-rc.1", "3.3.0|3.3.0-rc.1^", true)
	expect("3.4.0-rc.2", "3.3.0|3.3.0-rc.1^", false) -- 3.3.0의 rc와 3.4.0의 rc는 구분된다
	expect("3.2.0", "3.2.0|", true) -- 빈 대안은 아무것도 안 맞을 뿐
	expect("3.2.0", "|", false)
	print("PASS")
end

print()
print("=== 5. build(`+` 뒤)는 양쪽 다 항상 무시 ===")
do
	expect("3.0.0+build.5", "3.0.0", true)
	expect("3.0.0-rc.1+build.5", "3.0.0-rc.1", true)
	expect("3.0.0", "3.0.0+build.5", true)
	expect("3.0.0+build.5", "3.0.0+other.9", true)
	-- `+`를 먼저 자르므로 build 안의 `-`는 프리릴리즈 구분자가 아니다
	expect("3.0.0+build-7", "3.0.0", true)
	expect("3.0.0+build-7", "3.0.0-build-7", false)
	expect("4.0.0+b", "3.2^.0^|4.0^.0^+ignored", true) -- 대안마다 build를 자른다
	print("PASS")
end

print()
print("=== 6. 깨진 입력은 그대로 false(별도 방어 없음) ===")
do
	expect("", "3.0.0", false)
	expect("3.0.0", "", false)
	expect("-", "3.0.0", false)
	expect("-", "", false) -- actual만 빈 꼬리가 있다 — 꼬리 유무 불일치(옛 규칙에선 true)
	expect("3.0.0-", "3.0.0", false) -- 빈 꼬리도 "꼬리가 있다"(옛 규칙에선 무시돼 true)
	expect("3.0.0", "3.0.0-", false)
	expect("3.0.0-", "3.0.0-", true)
	print("PASS")
end

print()
print("=== 7. 컴파일 타임 CheckVersion — 같은 규칙(양성만, luau-analyze가 실제로 평가) ===")
do
	-- 인스턴스화 자리에서 실제로 해석돼야 평가된다(luau-test `23`의 함정 2)
	local _core: TypeVersionCheck.CheckVersion<"0.0.0", "0.0.0"> = true
	local _glob: TypeVersionCheck.CheckVersion<"3.1.4", "3.*.*"> = true
	local _caret: TypeVersionCheck.CheckVersion<"3.4.0", "3.3^.4^"> = true
	local _preExact: TypeVersionCheck.CheckVersion<"3.1.0-rc.1", "3.1.0-rc.1"> = true
	local _preCaret: TypeVersionCheck.CheckVersion<"3.1.0-rc.2", "3.1.0-rc.1^"> = true
	local _alt: TypeVersionCheck.CheckVersion<"4.1.0", "3.2^.0^|4.0^.0^"> = true
	local _build: TypeVersionCheck.CheckVersion<"3.0.0+build.5", "3.0.0"> = true
	assert(_core and _glob and _caret and _preExact and _preCaret and _alt and _build, "type-level cases carry a trivial `true`")
	print("PASS")
end

print()
print("=== ALL PASS ===")
