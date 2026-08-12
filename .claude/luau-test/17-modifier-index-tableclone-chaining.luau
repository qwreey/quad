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
]]

local function genericIndex(_, key)
	return function(selfArg, arg)
		local clone = table.clone(selfArg)
		if type(arg) == "function" then
			clone[key] = arg(selfArg[key])
		else
			clone[key] = arg
		end
		return clone
	end
end

local ModifierMT = { __index = genericIndex }

local function Modifier()
	return setmetatable({}, ModifierMT)
end

-- (A) 필드가 하나도 미리 등록 안 돼 있어도 임의 메소드 이름으로 체이닝되는지
local mod0 = Modifier()
local mod1 = mod0:FontSize(14)
local mod2 = mod1:Round(8)
local mod3 = mod2:FontSize(function(old)
	return old * 1.2
end)

assert(mod1.FontSize == 14, "mod1.FontSize expected 14")
assert(mod2.FontSize == 14 and mod2.Round == 8, "mod2 expected FontSize=14, Round=8")
assert(mod3.FontSize == 14 * 1.2, "mod3 expected FontSize=16.8 (14*1.2)")

-- (B) getmetatable이 매 clone마다 원본과 physically 동일 객체인지
-- (table.clone이 메타테이블을 복사가 아니라 참조로 공유한다는 주장의 핵심 검증)
assert(getmetatable(mod0) == ModifierMT, "mod0 metatable should be ModifierMT")
assert(getmetatable(mod1) == getmetatable(mod0), "mod1 metatable should be same reference as mod0's")
assert(getmetatable(mod2) == getmetatable(mod0), "mod2 metatable should be same reference as mod0's")
assert(getmetatable(mod3) == getmetatable(mod0), "mod3 metatable should be same reference as mod0's")

-- (C) 원본은 절대 mutate 안 됨(immutable 체이닝 보장)
assert(mod0.FontSize == nil, "mod0 must stay untouched (FontSize)")
assert(mod0.Round == nil, "mod0 must stay untouched (Round)")
assert(mod1.Round == nil, "mod1 must stay untouched (Round) -- clone은 앞 단계까지만 반영")

-- (D) 서로 다른 체이닝 경로(형제 분기)가 서로 오염 안 시키는지
local branchA = mod1:Round(4)
local branchB = mod1:Round(100)
assert(branchA.Round == 4 and branchB.Round == 100, "sibling branches must not cross-contaminate")
assert(mod1.Round == nil, "mod1 itself must stay untouched by either branch")

print("17-modifier-index-tableclone-chaining: all checks passed")
