--!strict
--[[
	컴파일 타임 버전 패턴 매칭 — `quad`에 종속되지 않은 범용 유틸.

	**[2026-08-19 신설, quad 저장소 안에 임시로 둠]** 지금은 quad
	워크스페이스의 네 번째 멤버로 두지만, 사용자가 나중에 독립 저장소로
	직접 분리할 예정(`HUMAN_TODO.md` 참고) — 그래서 이 파일 안에 `Quad`류
	quad 전용 이름/타입을 절대 안 섞는다. `quad-types`의
	`CheckedQuad<T, Pattern>`이 이 위에 얹히는 소비자 중 하나일 뿐.

	**패턴 문법 — [2026-09-15 사용자 설계로 재정의]**:
	1. **`|`로 먼저 나눈다** — 대안(OR). 하나라도 맞으면 통과. 메이저 여럿과
	   호환되는 소비자용: `"3.2^.0^|4.0^.0^"`(3.2.0 이상의 3.x, 또는 4.x).
	   `|`를 맨 앞에 두는 이유(사용자): 뒤에 두면 `3|4.0^.0^`의 `0^`가
	   어느 메이저에 걸리는지 안 읽힌다. `|`가 없으면 대안 하나 — 옛 패턴은
	   전부 그대로 문법상 유효하다.
	2. 대안마다(그리고 actual도) SemVer 2.0.0 `<core>[-<prerelease>][+<build>]`로
	   가른다 — **build(`+` 뒤)를 먼저 잘라 버리고**(양쪽 다 항상 무시;
	   `3.0.0+build-7`의 `-`는 프리릴리즈 구분자가 아니다), 남은 앞부분을
	   **첫 `-`에서만** 나눈다(프리릴리즈 식별자 안의 `-`는 문자열의 일부 —
	   `rc-1`). 꼬리가 없으면 `nil`, 빈 꼬리(`"3.0.0-"`)는 `""`.
	3. **프리릴리즈 꼬리의 있고 없음은 양쪽이 같아야 한다** — 꼬리 없는
	   패턴(`"3.*.*"` 포함)은 rc 빌드를 받지 않고, 꼬리 있는 패턴은 릴리즈를
	   받지 않는다. 사용자: *"프리릴리즈와 릴리즈 요소를 섞는건 안 되도록"*,
	   *"beta 든 rc 든 처리 도구는 한 곳에 있고, 그걸 쓸지 말지가 처리자
	   측"* — rc도 받고 싶은 쪽은 `|`로 꼬리 달린 대안을 더한다
	   (`"3.3.0|3.3.0-rc.1^"`). **옛 규칙(2026-09-10 "패턴에 꼬리가 없으면
	   actual 꼬리는 무시")을 되돌린 유일한 좁힘.**
	4. core와 prerelease를 각각 `.`로 나눠 **따로** 판정한다(자리 개수가
	   다르면 불일치). 자리마다:
	   - `"*"` — 뭐든 통과
	   - `"N^"` — 숫자로 N 이상. **사전식 하한**: N보다 **크면 그 구간
	     (core 또는 prerelease)의 뒤 자리는 보지 않고 통과**, 같으면 다음
	     자리로(`"3.3^.4^"`는 3.4.0을 받는다). 숫자가 아닌 자리엔 안 먹는다.
	   - 그 외 — 정확히 같은 문자열(프리릴리즈의 `rc`/`beta` 같은 글자 자리가
	     여기 해당 — 크고 작음을 따지지 않는다)
	   core에서 넘었다고 prerelease를 건너뛰지 않는다 — 사용자: *"rc 를 적을
	   땐 기본적으로 선행 부분이 확정 버전인걸 아는 경우"*. 그래서
	   `"3.3^.0^-rc.1^"`은 `3.4.0-rc.0`을 받지 않는다(구간을 가르려면 `|`).

	예: `"3.*.*"`(메이저 3의 릴리즈), `"3.2^.0^"`(메이저 3 안에서 3.2.0
	이상), `"3.2^.0^|4.0^.0^"`(두 메이저), `"3.3.0-rc.2"`(그 rc만),
	`"3.3.0-rc.1^"`(3.3.0의 rc.1 이후 rc), `"0.0.0"`(정확히 일치, quad-types의
	`CheckedQuad`가 지금 쓰는 방식). 깨진 입력(`""`, `"-"`, 빈 대안)에 별도
	방어는 없다 — 자리 개수·꼬리 유무가 어긋나 자연히 false로 떨어진다.

	**⚠️ 판정 로직은 아래 `type function` 안에 통째로 다시 적혀 있다(중복) —
	실측 확인된 제약**: `type function`은 같은 파일의 바깥 스코프 로컬 함수를
	아예 참조 못 한다(`Type function cannot reference outer local 'X'`로
	컴파일 자체가 실패함). 그래서 런타임 유틸과 `type function` 내부 구현은
	로직이 같아도 물리적으로 별개 함수여야 한다 — 하나를 고치면 반드시 다른
	하나도(그리고 `scripts/check-version.py`의 Python 포트도) 같이 고칠 것.
]]

-- `<core>[-<prerelease>][+<build>]` — build를 **먼저** 잘라내고 남은 앞부분의 첫 `-`
-- 뒤를 프리릴리즈로 본다. 꼬리가 없으면 nil(빈 문자열이 아니다 — `"3.0.0-"`은
-- "빈 프리릴리즈가 있다"로 남는다).
local function splitTail(version: string): (string, string?)
	local core = version
	local plusIndex = string.find(core, "+", 1, true)
	if plusIndex ~= nil then
		core = string.sub(core, 1, plusIndex - 1)
	end
	local dashIndex = string.find(core, "-", 1, true)
	if dashIndex ~= nil then
		return string.sub(core, 1, dashIndex - 1), string.sub(core, dashIndex + 1)
	end
	return core, nil
end

-- 한 구간(core 또는 prerelease)의 `.` 자리 판정 — `*` / 사전식 `N^` / 정확 일치
local function matchesPlaces(actual: string, pattern: string): boolean
	local actualParts = string.split(actual, ".")
	local patternParts = string.split(pattern, ".")
	if #actualParts ~= #patternParts then
		return false
	end
	for i, patternPart in patternParts do
		local actualPart = actualParts[i]
		if patternPart == "*" then
			continue
		end
		if string.sub(patternPart, -1) == "^" then
			local minValue = tonumber(string.sub(patternPart, 1, -2))
			local actualNumber = tonumber(actualPart)
			if minValue == nil or actualNumber == nil or actualNumber < minValue then
				return false
			end
			if actualNumber > minValue then
				return true -- lexicographic floor: the rest of this section is ignored
			end
		elseif actualPart ~= patternPart then
			return false
		end
	end
	return true
end

local function matchesAlternative(actual: string, pattern: string): boolean
	local actualCore, actualPrerelease = splitTail(actual)
	local patternCore, patternPrerelease = splitTail(pattern)
	if (actualPrerelease == nil) ~= (patternPrerelease == nil) then
		return false -- prerelease and release never mix
	end
	if not matchesPlaces(actualCore, patternCore) then
		return false
	end
	if patternPrerelease ~= nil and actualPrerelease ~= nil then
		return matchesPlaces(actualPrerelease, patternPrerelease)
	end
	return true
end

local function matchesPattern(actual: string, pattern: string): boolean
	for _, alternative in string.split(pattern, "|") do
		if matchesAlternative(actual, alternative) then
			return true
		end
	end
	return false
end

--[[
	`CheckVersion<Actual, Pattern>` — `Actual`/`Pattern` 둘 다 문자열
	리터럴(singleton) 타입이어야 함. 판정 규칙은 위 "패턴 문법"과 완전히
	같다. 일치하면 트리비얼한 `true` 하나만 반환하고, 불일치하면
	`print`+`types.never`로 사람이 읽을 메시지를 낸다(`error()`는 쓰지 않음 —
	`typing-limits.md` §6/`quad-types-plan.md` 참고, type function 안에서 `error()`를
	쓰면 "type function 자체가 실패함"으로 판정돼 버려짐).

	**⚠️ 이 type function이 반환하는 값은 절대 원본 타입을 담지 않는다** —
	`Actual`/`Pattern`을 그대로도, 재구성해서도 반환하지 않고 트리비얼한
	`true`만 반환한다. 소비자는 이 결과를 원본과 절대 안 섞이는 별도
	필드로만 노출할 것 — `type function`을 거친 값에 제네릭 self
	메소드(`AddPlugin<Self,P>`류)를 나중에 부르면 조용히 깨지는 게 실측
	확인됐기 때문(`typing-limits.md` §6). 예시는 `quad-types`의
	`CheckedQuad<T, Pattern>` 구현 참고.
]]
-- selene: allow(undefined_variable) — `types`는 `type function` 블록 안에서만
-- 주입되는 특수 전역(quad-types/src/init.luau와 같은 이유의 오탐).
export type function CheckVersion(actual: type, pattern: type): type
	-- [2026-09-10] no `pcall` here: it is not available inside type functions — the new solver
	-- reported `Unknown global 'pcall'` and then skipped evaluating this function entirely, so
	-- a wrong pattern produced no diagnostic. `tag` + `:value()` is the supported way to probe.
	local actualValue = if actual.tag == "singleton" then actual:value() else nil
	if type(actualValue) ~= "string" then
		print("type-version-check: expected a string literal type for the actual version")
		return types.never
	end

	local patternValue = if pattern.tag == "singleton" then pattern:value() else nil
	if type(patternValue) ~= "string" then
		print("type-version-check: expected a string literal type for the version pattern")
		return types.never
	end

	-- splitTail/matchesPlaces/matchesAlternative/matchesPattern과 로직 동일 — 위 경고문 참고, 바깥 함수를 못 불러서 복제함
	local function splitTail(version: string): (string, string?)
		local core = version
		local plusIndex = string.find(core, "+", 1, true)
		if plusIndex ~= nil then
			core = string.sub(core, 1, plusIndex - 1)
		end
		local dashIndex = string.find(core, "-", 1, true)
		if dashIndex ~= nil then
			return string.sub(core, 1, dashIndex - 1), string.sub(core, dashIndex + 1)
		end
		return core, nil
	end

	local function matchesPlaces(actualStr: string, patternStr: string): boolean
		local actualParts = string.split(actualStr, ".")
		local patternParts = string.split(patternStr, ".")
		if #actualParts ~= #patternParts then
			return false
		end
		for i, patternPart in patternParts do
			local actualPart = actualParts[i]
			if patternPart == "*" then
				continue
			end
			if string.sub(patternPart, -1) == "^" then
				local minValue = tonumber(string.sub(patternPart, 1, -2))
				local actualNumber = tonumber(actualPart)
				if minValue == nil or actualNumber == nil or actualNumber < minValue then
					return false
				end
				if actualNumber > minValue then
					return true
				end
			elseif actualPart ~= patternPart then
				return false
			end
		end
		return true
	end

	local function matchesAlternative(actualStr: string, patternStr: string): boolean
		local actualCore, actualPrerelease = splitTail(actualStr)
		local patternCore, patternPrerelease = splitTail(patternStr)
		if (actualPrerelease == nil) ~= (patternPrerelease == nil) then
			return false
		end
		if not matchesPlaces(actualCore, patternCore) then
			return false
		end
		if patternPrerelease ~= nil and actualPrerelease ~= nil then
			return matchesPlaces(actualPrerelease, patternPrerelease)
		end
		return true
	end

	local matched = false
	for _, alternative in string.split(patternValue :: string, "|") do
		if matchesAlternative(actualValue :: string, alternative) then
			matched = true
			break
		end
	end

	if not matched then
		print(`type-version-check: version "{actualValue}" does not match pattern "{patternValue}"`)
		return types.never
	end

	return types.singleton(true)
end

-- [2026-09-16] Priming: an exported type function that its own module never instantiates is not
-- exported when `LuauDoNotExportBrokenTypeFunction` is on (luau-lsp `analyze` enables every FFlag by
-- default; the flag is off in Luau's defaults and in Roblox's synced values today, so editors were
-- fine — but it may ship). One instantiation here opens the function for consumers with any
-- arguments (`typing-limits.md` 8.18 정정·8.22). Not exported on purpose — a local alias primes
-- just as well (measured), and an exported one would become a public name.
type _Prime = CheckVersion<"0.0.0", "0.*.*">

return {
	matchesPattern = matchesPattern,
}
