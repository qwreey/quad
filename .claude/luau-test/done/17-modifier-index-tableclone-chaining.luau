--[[
	검증 대상: Modifier의 "제네릭 __index + table.clone" 트릭 — 클래스별
	런타임 코드 없이 하나의 제네릭 __index만으로 임의 필드 setter 체이닝이
	실제로 동작하는지, 그리고 table.clone이 매 단계 메타테이블을 복사가
	아니라 참조로 유지해 체이닝이 안 끊기는지.

	배경: .claude/base/modifier-plan.md "런타임은 클래스별 코드 없이 base에
	딱 하나만 있으면 됨" 절 + "`table.clone`의 정확한 동작 — 확인됨"
	절(2026-08-12 열일곱 번째 세션) — 사용자가 설명한 메커니즘(원본 키를
	네이티브 슬롯 단위로 얕은 복사 + 메타테이블은 복사가 아니라
	getmetatable/setmetatable로 참조 공유)을 실제 코드로 재현.
	`research/pre-implementation-audit.md` 1-11 해소 근거.

	실행: `luau 17-modifier-index-tableclone-chaining.luau`

	기대 결과: 아래 모든 assert가 통과 — 특히 (B) 메타테이블이 매 clone마다
	원본과 물리적으로 동일 객체인지(참조 공유 확인), (C) 원본이 각 체이닝
	단계에서 전혀 mutate 안 됐는지(immutable 보장), (D) 서로 다른 체이닝
	경로(형제 분기)가 서로 오염 안 시키는지가 핵심.

	[2026-08-13 수정] 1차 작성본은 필드 값을 self 최상위 테이블에 리터럴
	키(`clone.FontSize = 14`)로 직접 저장했는데, 이러면 Lua/Luau 의미상
	`__index` 메타메소드는 rawget이 실패할 때만 불림 — 한 번 `FontSize`가
	설정된 뒤 같은 필드를 `mod:FontSize(fn)`으로 다시 호출하면
	`mod.FontSize`가 __index를 안 거치고 저장된 raw 값(숫자)을 그대로
	돌려줘서 `(그 숫자)(mod, fn)`로 콜 시도 -> "attempt to call a number
	value" 크래시(설계가 명시적으로 요구하는 "이미 값이 있는 필드를 변환
	함수로 다시 감싸는" 용례, modifier-plan.md 4번 절의 "이전 값을 바탕으로
	계산" + 3번 절 "상위 TextStyle을 상속해 타이틀만 1.2배 키우는" 예시가
	정확히 이 패턴). base가 "그러니 __index가 **어떤 key가 오든**"이라고
	쓴 건 바로 이 재호출 케이스까지 포함한다는 뜻 — 즉 필드 값은 self의
	리터럴 키가 아니라 **항상 __index를 거치도록 별도 프라이빗 저장소**에
	둬야 함(literal key로 직접 저장하는 건 스파이크 코드의 버그였지 설계의
	결함이 아님, "Getter는 만들지 않기로 확정"이라 dot-access로 raw 값을
	직접 읽는 것도 애초에 계약에 없었음 — 아래 `fieldOf` 헬퍼로만 검증용
	읽기를 함). 이 프라이빗 저장소 자체도 `table.clone`이 얕은 복사라
	원본과 같은 내부 테이블을 그대로 참조하게 되므로, setter가 내부
	필드 테이블도 별도로 `table.clone`해야 원본이 안 섞임 — 아래 구현 참고.
]]

-- 필드 저장소 전용 프라이빗 키(유일 테이블 identity) — 사용자 필드 이름과
-- 절대 충돌 안 함, 11번 스파이크의 ModifierBrand와 같은 패턴.
local FieldsKey = {}

local function genericIndex(_, key)
	return function(selfArg, arg)
		local oldFields = selfArg[FieldsKey]
		-- 내부 필드 테이블도 얕은 복사 -- 안 하면 clone과 원본이 같은
		-- 내부 테이블을 계속 공유해서 새 필드를 쓰는 순간 원본도 오염됨.
		local newFields = table.clone(oldFields)

		local old = oldFields[key]
		local value
		if type(arg) == "function" then
			value = arg(old)
		else
			value = arg
		end
		newFields[key] = value

		local clone = table.clone(selfArg)
		clone[FieldsKey] = newFields
		return clone
	end
end

local ModifierMT = { __index = genericIndex }

local function Modifier()
	return setmetatable({ [FieldsKey] = {} }, ModifierMT)
end

-- 검증 전용 헬퍼(Modifier의 공개 API 아님 -- 설계상 dot-access getter는
-- 없음, "Getter는 만들지 않기로 확정" 문서 그대로).
local function fieldOf(mod, key)
	return mod[FieldsKey][key]
end

-- (A) 필드가 하나도 미리 등록 안 돼 있어도 임의 메소드 이름으로 체이닝되는지
-- + 이미 값이 채워진 필드를 다시 변환 함수로 감싸도(mod2:FontSize(fn))
--   __index가 여전히 잡아주는지(핵심 재현 시나리오)
local mod0 = Modifier()
local mod1 = mod0:FontSize(14)
local mod2 = mod1:Round(8)
local mod3 = mod2:FontSize(function(old)
	return old * 1.2
end)

assert(fieldOf(mod1, "FontSize") == 14, "mod1.FontSize expected 14")
assert(fieldOf(mod2, "FontSize") == 14 and fieldOf(mod2, "Round") == 8, "mod2 expected FontSize=14, Round=8")
assert(fieldOf(mod3, "FontSize") == 14 * 1.2, "mod3 expected FontSize=16.8 (14*1.2)")
assert(fieldOf(mod3, "Round") == 8, "mod3 must keep Round=8 unchanged by the FontSize re-chain")

-- (B) getmetatable이 매 clone마다 원본과 physically 동일 객체인지
-- (table.clone이 메타테이블을 복사가 아니라 참조로 공유한다는 주장의 핵심 검증)
assert(getmetatable(mod0) == ModifierMT, "mod0 metatable should be ModifierMT")
assert(getmetatable(mod1) == getmetatable(mod0), "mod1 metatable should be same reference as mod0's")
assert(getmetatable(mod2) == getmetatable(mod0), "mod2 metatable should be same reference as mod0's")
assert(getmetatable(mod3) == getmetatable(mod0), "mod3 metatable should be same reference as mod0's")

-- (C) 원본은 절대 mutate 안 됨(immutable 체이닝 보장)
assert(fieldOf(mod0, "FontSize") == nil, "mod0 must stay untouched (FontSize)")
assert(fieldOf(mod0, "Round") == nil, "mod0 must stay untouched (Round)")
assert(fieldOf(mod1, "Round") == nil, "mod1 must stay untouched (Round) -- clone은 앞 단계까지만 반영")
assert(fieldOf(mod2, "FontSize") == 14, "mod2 must keep pre-rechain FontSize=14 untouched by mod3's re-chain")

-- (D) 서로 다른 체이닝 경로(형제 분기)가 서로 오염 안 시키는지
local branchA = mod1:Round(4)
local branchB = mod1:Round(100)
assert(fieldOf(branchA, "Round") == 4 and fieldOf(branchB, "Round") == 100, "sibling branches must not cross-contaminate")
assert(fieldOf(mod1, "Round") == nil, "mod1 itself must stay untouched by either branch")

-- (E) 이미 값이 있는 필드를 같은 분기에서 세 번, 네 번 계속 재호출해도
-- 매번 __index가 잡아주는지(단발성 재현이 아니라 임의 깊이에서 안정적인지)
local deep = mod1
for i = 1, 5 do
	deep = deep:Round(function(old)
		return (old or 0) + i
	end)
end
assert(fieldOf(deep, "Round") == 1 + 2 + 3 + 4 + 5, "repeated re-chaining on the same field must accumulate correctly")

print("17-modifier-index-tableclone-chaining: all checks passed")
