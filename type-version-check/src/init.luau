--!strict
--[[
	컴파일 타임 버전 패턴 매칭 — `quad`에 종속되지 않은 범용 유틸.

	**[2026-08-19 신설, quad 저장소 안에 임시로 둠]** 지금은 quad
	워크스페이스의 네 번째 멤버로 두지만, 사용자가 나중에 독립 저장소로
	직접 분리할 예정(`HUMAN_TODO.md` 참고) — 그래서 이 파일 안에 `Quad`류
	quad 전용 이름/타입을 절대 안 섞는다. `quad-types`의
	`CheckedQuad<T, Pattern>`이 이 위에 얹히는 소비자 중 하나일 뿐.

	**패턴 문법**: `.`로 나뉜 각 자리가
	- `"*"` — 와일드카드(뭐든 통과)
	- `"N^"` — 그 자리 값이 숫자로 봤을 때 N **이상**이면 통과(caret)
	- 그 외 — 정확히 같은 문자열이어야 통과

	예: `"3.*.*"`(메이저만 고정), `"3.3^.4^"`(마이너 3 이상 + 패치
	4 이상), `"0.0.0"`(정확히 일치, quad-types의 `CheckedQuad`가 지금
	쓰는 방식).

	**⚠️ `matchesPattern`은 아래 `type function` 안에 통째로 다시
	적혀 있다(중복) — 실측 확인된 제약**: `type function`은 같은 파일의
	바깥 스코프 로컬 함수를 아예 참조 못 한다(`Type function cannot
	reference outer local 'X'`로 컴파일 자체가 실패함). 그래서 순수
	런타임 유틸(아래, 테스트/문서화/일반 사용 목적)과 `type function`
	내부 구현은 로직이 같아도 물리적으로 별개 함수여야 한다 — 하나를
	고치면 반드시 다른 하나도 같이 고칠 것.
]]

local function matchesPattern(actual: string, pattern: string): boolean
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
	리터럴(singleton) 타입이어야 함. 일치하면 트리비얼한 `true` 하나만
	반환하고, 불일치하면 `print`+`types.never`로 사람이 읽을 메시지를
	낸다(`error()`는 쓰지 않음 — `typing-limits.md` §6/`quad-types-plan.md`
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

	-- matchesPattern과 로직 동일 — 위 경고문 참고, 바깥 함수를 못 불러서 복제함
	local function matches(actualStr: string, patternStr: string): boolean
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
