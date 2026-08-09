--[[
	검증 대상: 2026-08-09 세션에 "UB, 방어 없음"에서 "즉시 error"로 전환된
	두 규칙이 실제 Luau에서 자연스럽게 짜이는지 (신규 파일 — 이 폴더의
	1차 작성 이후 새로 확정된 내용이라 이걸 검증하는 스크립트가
	없었음):

	A) Modifier 필드에 핸들러 계층 값(Ref/PreRef/Observer/Effect/Slot/
	   Modifier)이 들어오면 제네릭 __index 셋터가 최종 저장 직전에 즉시
	   error. State/Source 값은 여전히 허용.
	B) State/Source 자체의 "확정되는 값"(Source:Set, Store({defaults})
	   생성 시 각 default, State:Compute(fn)의 캐싱 직전)이 Modifier이면
	   즉시 error. Slot/Tag/Attribute/Tween 같은 다른 핸들러 계층 값은
	   여전히 허용(Modifier만의 예외).

	배경: .claude/base/modifier-plan.md "Modifier 필드에 핸들러 계층 값이
	들어오면 즉시 error" 절 + "7. State/Source가 Modifier를 값으로 담는
	것 — 명시적 error로 확정" 절(둘 다 2026-08-09 세션 정정, 이전엔
	"UB, 가능하면 타입으로 막을 것"이었음).

	실행: `luau 11-modifier-illegal-value-error.luau`
]]

-- ===== Brand 흉내 — 실제로는 base/bind-system-plan.md의 Brand 절이 다루는
-- weak-key 레지스트리 기반이지만, 이 스파이크에선 태그 필드로 단순화 =====

local function tag(name)
	return function(t)
		return setmetatable(t or {}, { __index = { __brand = name } })
	end
end

local function brandOf(v)
	if type(v) ~= "table" then
		return nil
	end
	local mt = getmetatable(v)
	return mt and mt.__index and mt.__index.__brand
end

local makeRef = tag("Ref")
local makePreRef = tag("PreRef")
local makeObserver = tag("Observer")
local makeEffect = tag("Effect")
local makeSlot = tag("Slot")

local function isRef(v)
	return brandOf(v) == "Ref"
end
local function isPreRef(v)
	return brandOf(v) == "PreRef"
end
local function isObserver(v)
	return brandOf(v) == "Observer"
end
local function isEffect(v)
	return brandOf(v) == "Effect"
end
local function isSlot(v)
	return brandOf(v) == "Slot"
end

-- ===== Modifier — 제네릭 __index 셋터 + "핸들러 계층 값 즉시 error" 체크 =====

local ModifierBrand = {}
local function isModifier(v)
	return type(v) == "table" and v[ModifierBrand] == true
end
local function isState(v)
	-- Source가 State를 구조적으로 만족(store-semantics.md) — 여기선 둘 다
	-- ".__isStateLike" 태그로 단순화해서 흉내
	return type(v) == "table" and v.__isStateLike == true
end

local function illegalModifierFieldValue(v)
	return isRef(v) or isPreRef(v) or isObserver(v) or isEffect(v) or isSlot(v) or isModifier(v)
end

local function Modifier(initial)
	local self = initial and table.clone(initial) or {}
	self[ModifierBrand] = true
	return setmetatable(self, {
		__index = function(t, key)
			-- 제네릭 setter 합성(modifier-plan.md 4번 절의 __index 트릭)
			return function(selfArg, arg)
				local clone = table.clone(selfArg)
				local value
				if type(arg) == "function" and not isState(selfArg[key]) then
					-- plain 필드 + 함수 인자: 즉시 호출해 값 확정 (State 분기는 이 스파이크에서 생략)
					value = arg(selfArg[key])
				else
					value = arg
				end

				-- 핵심 체크 지점: 최종 저장 직전
				if illegalModifierFieldValue(value) then
					error(
						string.format(
							"Modifier 필드 '%s'에 핸들러 계층 값(%s)을 저장할 수 없음",
							tostring(key),
							tostring(brandOf(value) or (isModifier(value) and "Modifier") or "?")
						)
					)
				end

				clone[key] = value
				return clone
			end
		end,
	})
end

print("=== A. Modifier 필드에 핸들러 계층 값 -> 즉시 error ===")

local mod = Modifier()

local casesA = {
	{ name = "plain 리터럴(허용)", fn = function()
		return mod:FontSize(20)
	end, expectError = false },
	{ name = "State 유사 값(허용)", fn = function()
		return mod:TextColor(setmetatable({ __isStateLike = true }, {}))
	end, expectError = false },
	{ name = "Ref(금지)", fn = function()
		return mod:SomeField(makeRef())
	end, expectError = true },
	{ name = "PreRef(금지)", fn = function()
		return mod:SomeField(makePreRef())
	end, expectError = true },
	{ name = "Observer(금지)", fn = function()
		return mod:SomeField(makeObserver())
	end, expectError = true },
	{ name = "Effect(금지)", fn = function()
		return mod:SomeField(makeEffect())
	end, expectError = true },
	{ name = "Slot(금지)", fn = function()
		return mod:SomeField(makeSlot())
	end, expectError = true },
	{ name = "다른 Modifier(금지)", fn = function()
		return mod:SomeField(Modifier())
	end, expectError = true },
	{
		name = "변환 함수가 Ref를 반환(금지 — 콜백이어도 최종값만 봄)",
		fn = function()
			return mod:SomeField(function(old)
				return makeRef()
			end)
		end,
		expectError = true,
	},
}

for _, case in casesA do
	local ok, err = pcall(case.fn)
	local pass = (ok == not case.expectError)
	print(
		string.format(
			"  [%s] %s: ok=%s expectError=%s %s",
			pass and "PASS" or "FAIL",
			case.name,
			tostring(ok),
			tostring(case.expectError),
			(not ok) and ("(error: " .. tostring(err) .. ")") or ""
		)
	)
end

-- ===== B. State/Source가 확정하는 값이 Modifier면 즉시 error =====

print()
print("=== B. Source:Set / Store 생성 / State:Compute 캐싱 -> Modifier면 즉시 error ===")

local function checkNotModifier(value, where)
	if isModifier(value) then
		error(where .. ": Modifier를 State/Source 값으로 저장할 수 없음")
	end
end

local function Source(default)
	checkNotModifier(default, "Source(default)")
	local self = { __isStateLike = true, value = default }
	function self:Get()
		return self.value
	end
	function self:Set(v)
		checkNotModifier(v, "Source:Set")
		self.value = v
	end
	function self:Compute(fn)
		local derived = { __isStateLike = true, dirty = true }
		function derived:Get()
			if self.dirty then
				local result = fn(self.value)
				checkNotModifier(result, "State:Compute 캐싱")
				derived.cached = result
				derived.dirty = false
			end
			return derived.cached
		end
		return derived
	end
	return self
end

local function Store(defaults)
	local sources = {}
	for k, v in defaults or {} do
		sources[k] = Source(v) -- 여기서도 checkNotModifier가 자연히 걸림
	end
	return sources
end

local casesB = {
	{
		name = "Source(plain 초기값) — 허용",
		fn = function()
			return Source(1)
		end,
		expectError = false,
	},
	{
		name = "Source(Modifier 초기값) — 금지",
		fn = function()
			return Source(Modifier())
		end,
		expectError = true,
	},
	{
		name = "source:Set(plain) — 허용",
		fn = function()
			local s = Source(1)
			s:Set(2)
		end,
		expectError = false,
	},
	{
		name = "source:Set(Modifier) — 금지",
		fn = function()
			local s = Source(1)
			s:Set(Modifier())
		end,
		expectError = true,
	},
	{
		name = "Store({defaults}) 중 하나가 Modifier — 금지",
		fn = function()
			return Store({ Health = 100, Style = Modifier() })
		end,
		expectError = true,
	},
	{
		name = "state:Compute(fn)이 Modifier를 반환 — Get() 호출 시점에 금지",
		fn = function()
			local s = Source(1)
			local derived = s:Compute(function(v)
				return Modifier()
			end)
			derived:Get() -- 캐싱 시점에 걸려야 함
		end,
		expectError = true,
	},
	{
		name = "state:Compute(fn)이 Slot을 반환 — 허용(Modifier만의 예외)",
		fn = function()
			local s = Source(1)
			local derived = s:Compute(function(v)
				return makeSlot()
			end)
			derived:Get()
		end,
		expectError = false,
	},
}

for _, case in casesB do
	local ok, err = pcall(case.fn)
	local pass = (ok == not case.expectError)
	print(
		string.format(
			"  [%s] %s: ok=%s expectError=%s %s",
			pass and "PASS" or "FAIL",
			case.name,
			tostring(ok),
			tostring(case.expectError),
			(not ok) and ("(error: " .. tostring(err) .. ")") or ""
		)
	)
end

--[[
	확인 포인트:
	1. 모든 케이스가 "PASS"로 찍히는가 — FAIL이 있으면 어느 케이스인지,
	   기대와 실제가 어떻게 달랐는지 알려줄 것.
	2. A의 마지막 케이스("변환 함수가 Ref를 반환")처럼 "콜백이 반환한 값"도
	   리터럴과 동일하게 잡히는지 — modifier-plan.md가 명시한 "콜백이냐
	   직접 실행이냐를 구분하지 않고 최종 저장값 하나만 본다"는 원칙의 핵심.
	3. B에서 Slot 같은 "Modifier가 아닌 다른 핸들러 계층 값"은 State/Source에
	   여전히 자유롭게 들어갈 수 있는가(Modifier만의 예외라는 걸 재확인).
	4. 이 스파이크는 Brand/isState를 태그 필드로 단순화한 것 — 실제 구현은
	   base/bind-system-plan.md의 weak-key 레지스트리 기반 Brand를 씀,
	   여기선 그 판별 로직 자체가 아니라 "체크 지점 배치가 실제로 동작하는가"만
	   검증 대상.
]]
