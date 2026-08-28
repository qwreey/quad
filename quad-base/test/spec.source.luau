--[[
	Source 계약 — `.claude/base/source-state-plan.md` "Source는 독립 공개 프리미티브로 격상" /
	"`Source:Set(v)`는 동일값이어도 항상 갱신하고 emit한다" / "`:Emit()`" / "따름정리 — Modifier",
	`.claude/base/modifier-plan.md` 7번, `.claude/base/brand-plan.md`(다중 태깅).
]]

local Quad = require("../src")
local Brand = require("../src/Brand")
local QuadTypes = require("../roblox_packages/quad_types")

type Source<T> = QuadTypes.Source<T>

local Source = Quad.Source

print("=== 1. 생성 — 값, Revision 0, SourceBrand+EpochBrand 다중 태깅, StateBrand엔 미등록 ===")
do
	local s = Source(5)
	assert(s:Get() == 5, "default is the value")
	assert(s.Revision == 0, "initial revision")
	assert(Quad.isSource(s) and Quad.isEpoch(s), "Source is both Source and Epoch")
	assert(Quad.isState(s), "isState passes a Source by composition")
	assert(Brand.StateBrand:is(s) == false, "…but it is NOT registered in StateBrand (predicate composition, not double registration)")
	assert(not Quad.isRef(s) and not Quad.isStore(s), "nothing else")
	local n: Source<number?> = Source(nil :: number?)
	assert(n:Get() == nil, "Source(nil) holds nil")
	print("PASS")
end

print()
print("=== 2. :Set — 값 갱신 + 리비전 감소 랩 + self 반환; 동일값도 항상 (H-68) ===")
do
	local s = Source(1 :: any)
	assert(s:Set(2) == s, "Set returns self")
	assert(s:Get() == 2 and s.Revision == 4294967295, "value moved, revision wrapped from 0")
	local r1 = s.Revision
	s:Set(2) -- same value
	assert(s.Revision ~= r1, "same value still bumps the revision")
	local t = {}
	s:Set(t :: any)
	assert(s:Get() == t, "Get returns the live reference")
	print("PASS")
end

print()
print("=== 3. :Emit — 값은 그대로, 리비전만 갱신, self 반환 ===")
do
	local s = Source({ n = 1 })
	local rev = s.Revision
	s:Get().n = 2
	assert(s:Emit() == s and s.Revision ~= rev and s:Get().n == 2, "Emit bumps revision without touching the value")
	print("PASS")
end

print()
print("=== 4. Modifier 가드 — 생성자와 Set 둘 다, level 2 ===")
do
	local mod = {}
	Brand.ModifierBrand:register(mod)
	local ok, err = pcall(function()
		Source(mod :: any)
	end)
	assert(not ok and string.find(tostring(err), "Modifier", 1, true) ~= nil, "constructor rejects: " .. tostring(err))
	assert(string.find(tostring(err), "spec.source.luau", 1, true) ~= nil, "level 2 points at the caller")
	local s = Source(1)
	local ok2, err2 = pcall(function()
		s:Set(mod :: any)
	end)
	assert(not ok2 and string.find(tostring(err2), "Modifier", 1, true) ~= nil, "Set rejects: " .. tostring(err2))
	assert(s:Get() == 1, "value untouched after the rejected Set")
	print("PASS")
end

print()
print("=== 5. State 메소드 위임 — Source에서 With/Compute/Apply가 바로 됨 ===")
do
	local s = Source(3)
	local doubled: QuadTypes.State<number> = s:Compute(function(x): number
		return x:Get() * 2
	end)
	assert(doubled:Get() == 6, "Compute through a Source")
	local w: QuadTypes.State<number> = s:With(Source(0))
	assert(w:Get() == 3, "With passes self's value through")
	local applied = s:Apply(function(st: QuadTypes.StateData<number>): number
		return st:Get() + 1
	end)
	assert(applied == 4, "Apply(fn) is just fn(self)")
	print("PASS")
end

print()
print("=== 6. 인스턴스별 팩토리 (H-174) — 다른 New()의 Source는 다른 임플, 브랜드는 공유 ===")
do
	local other = Quad.New()
	local a, b = Quad.Source(1), other.Source(1)
	assert(getmetatable(a :: any) ~= getmetatable(b :: any), "each quad instance has its own Source impl")
	assert(Quad.isSource(b) and other.isSource(a), "brands are shared leaf modules")
	print("PASS")
end

print()
print("=== ALL PASS ===")
