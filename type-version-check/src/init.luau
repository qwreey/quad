--!strict
--[[
	컴파일 타임 버전 패턴 매칭 — `quad`에 종속되지 않은 범용 유틸.

	**[2026-08-19 신설, quad 저장소 안에 임시로 둠]** 지금은 quad
	워크스페이스의 네 번째 멤버로 두지만, 사용자가 나중에 독립 저장소로
	직접 분리할 예정(`HUMAN_TODO.md` 참고) — 그래서 이 파일 안에 `Quad`류
	quad 전용 이름/타입을 절대 안 섞는다. `quad-types`의
	`CheckedQuad<T, Pattern>`이 이 위에 얹히는 소비자 중 하나일 뿐.

	**패턴 문법**: 양쪽 문자열을 SemVer 2.0.0의
	`<core>[-<prerelease>][+<build>]`로 먼저 가른 뒤, **core**만 `.`로
	나눠 자리별로 본다. 각 자리가
	- `"*"` — 와일드카드(뭐든 통과)
	- `"N^"` — 그 자리 값이 숫자로 봤을 때 N **이상**이면 통과(caret)
	- 그 외 — 정확히 같은 문자열이어야 통과

	예: `"3.*.*"`(메이저만 고정), `"3.3^.4^"`(마이너 3 이상 + 패치
	4 이상), `"0.0.0"`(정확히 일치, quad-types의 `CheckedQuad`가 지금
	쓰는 방식).

	**[2026-09-10 신설] 프리릴리즈/빌드 꼬리**(`3.1.0-rc.1`,
	`3.0.1-dev.3+build.7`류 중간 빌드용):
	- **build(`+` 뒤)는 양쪽 다 항상 무시**한다 — SemVer도 우선순위
	  비교에서 무시한다. `+`를 먼저 자르므로 `3.0.0+build-7`의 `-`는
	  프리릴리즈 구분자가 아니다.
	- **패턴에 프리릴리즈가 없으면 actual의 프리릴리즈는 무시**한다 —
	  `"3.0^"`류 느슨한 패턴은 rc 빌드도 통과(알파/rc 빌드는 base와
	  백엔드가 같이 나가므로 이게 실용적).
	- **패턴에 프리릴리즈가 있으면 actual의 프리릴리즈와 문자열이 정확히
	  같아야** 한다 — `"3.1.0-rc.1"`은 `rc.1`만 통과하고 `rc.2`나
	  꼬리 없는 `3.1.0`은 막힌다. 첫 `-`만 구분자라 `rc-1`처럼 `-`가
	  더 있어도 통째로 한 문자열로 본다.
	- 프리릴리즈 자리엔 `*`/`^`가 안 먹는다 — 문자열 그대로 비교한다
	  (와일드카드/caret은 core 자리 전용). **이건 이 변경이 유일하게
	  좁힌 방향**이다 — 예전엔 꼬리도 그냥 `.` 분할에 섞여서
	  `"3.1.0-rc.*"`가 `3.1.0-rc.1`을 통과시켰지만 이제 안 통과한다.
	- `""`나 `"-"`처럼 깨진 입력에 별도 방어를 두지 않는다 — 자리 개수나
	  프리릴리즈가 어긋나 자연히 false로 떨어진다. 다만 **꼬리가 비어
	  있는 것("`3.0.0-`")은 "프리릴리즈가 없다"가 아니라 "빈 프리릴리즈가
	  있다"** — 패턴에 프리릴리즈가 없으면 다른 꼬리와 똑같이 무시되고
	  (`("3.0.0-", "3.0.0")`은 통과), 패턴 쪽이 `"3.0.0-"`이면 actual도
	  빈 프리릴리즈여야 한다. 두 뜻을 한 값에 겹치지 않으려고 "꼬리 없음"은
	  `nil`, "빈 꼬리"는 `""`로 갈라 둔 결과다.

	**⚠️ `matchesPattern`은 아래 `type function` 안에 통째로 다시
	적혀 있다(중복) — 실측 확인된 제약**: `type function`은 같은 파일의
	바깥 스코프 로컬 함수를 아예 참조 못 한다(`Type function cannot
	reference outer local 'X'`로 컴파일 자체가 실패함). 그래서 순수
	런타임 유틸(아래, 테스트/문서화/일반 사용 목적)과 `type function`
	내부 구현은 로직이 같아도 물리적으로 별개 함수여야 한다 — 하나를
	고치면 반드시 다른 하나도 같이 고칠 것. **[2026-09-10] 꼬리를
	가르는 `splitTail`도 같은 이유로 두 벌**이다(런타임 로컬 하나 +
	`type function` 안 중첩 하나).
]]

-- SemVer 2.0.0 `<core>[-<prerelease>][+<build>]` — build를 **먼저** 잘라내고
-- (그래야 `3.0.0+build-7`의 `-`가 프리릴리즈로 안 읽힌다) 남은 앞부분의 첫 `-`
-- 뒤를 프리릴리즈로 본다. 꼬리가 없으면 nil(빈 문자열이 아니다 — `"3.0.0-"`은
-- "빈 프리릴리즈가 있다"로 남아 규칙 3/4가 안 뭉개진다).
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

local function matchesPattern(actual: string, pattern: string): boolean
	local actualCore, actualPrerelease = splitTail(actual)
	local patternCore, patternPrerelease = splitTail(pattern)
	-- 패턴에 프리릴리즈가 없으면 actual 쪽 꼬리는 무시, 있으면 정확 일치
	if patternPrerelease ~= nil and actualPrerelease ~= patternPrerelease then
		return false
	end

	local actualParts = string.split(actualCore, ".")
	local patternParts = string.split(patternCore, ".")
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
		else
			if actualPart ~= patternPart then
				return false
			end
		end
	end

	return true
end

--[[
	`CheckVersion<Actual, Pattern>` — `Actual`/`Pattern` 둘 다 문자열
	리터럴(singleton) 타입이어야 함. 판정 규칙은 위 "패턴 문법"과 완전히
	같다(core 자리별 `*`/`N^`/정확 일치 + **[2026-09-10]** build 무시,
	패턴에 프리릴리즈가 있을 때만 프리릴리즈 정확 일치). 일치하면
	트리비얼한 `true` 하나만 반환하고, 불일치하면 `print`+`types.never`로
	사람이 읽을 메시지를 낸다(`error()`는 쓰지 않음 — `typing-limits.md` §6/`quad-types-plan.md`
	참고, type function 안에서 `error()`를 쓰면 "type function 자체가
	실패함"으로 판정돼 버려짐).

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
	local actualOk, actualValue = pcall(function()
		return actual:value()
	end)
	if not actualOk or type(actualValue) ~= "string" then
		print("type-version-check: expected a string literal type for the actual version")
		return types.never
	end

	local patternOk, patternValue = pcall(function()
		return pattern:value()
	end)
	if not patternOk or type(patternValue) ~= "string" then
		print("type-version-check: expected a string literal type for the version pattern")
		return types.never
	end

	-- splitTail/matchesPattern과 로직 동일 — 위 경고문 참고, 바깥 함수를 못 불러서 복제함
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

	local function matches(actualStr: string, patternStr: string): boolean
		local actualCore, actualPrerelease = splitTail(actualStr)
		local patternCore, patternPrerelease = splitTail(patternStr)
		if patternPrerelease ~= nil and actualPrerelease ~= patternPrerelease then
			return false
		end
		local actualParts = string.split(actualCore, ".")
		local patternParts = string.split(patternCore, ".")
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
			else
				if actualPart ~= patternPart then
					return false
				end
			end
		end
		return true
	end

	if not matches(actualValue :: string, patternValue :: string) then
		print(`type-version-check: version "{actualValue}" does not match pattern "{patternValue}"`)
		return types.never
	end

	return types.singleton(true)
end

return {
	matchesPattern = matchesPattern,
}
