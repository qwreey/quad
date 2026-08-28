--[[ Brand 계약 — `.claude/base/brand-plan.md` "구현 — 인스턴스 브랜드" / "`isX` wrapper" ]]

local Brand = require("../src/Brand")
local Quad = require("../src")

-- strict 모드에서 `collectgarbage`는 선언 안 된 전역 — 표준 luau CLI엔 있다(Roblox엔 없음)
local collectgarbage = (_G :: any).collectgarbage :: () -> ()
print("=== 1. register/is — 등록한 값만 통과 ===")
do
	local b = Brand.Brand()
	local x, y = {}, {}
	b:register(x)
	assert(b:is(x) == true, "registered value must pass")
	assert(b:is(y) == false, "unregistered value must not pass")
	assert(b:is(nil) == false and b:is(1) == false and b:is("s") == false, "non-table values are never members")
	print("PASS")
end

print()
print("=== 2. 다중 태깅 — 한 값이 여러 브랜드에 동시에 ===")
do
	local a, b = Brand.Brand(), Brand.Brand()
	local x = {}
	a:register(x)
	b:register(x)
	assert(a:is(x) and b:is(x), "a value may belong to several brands at once")
	print("PASS")
end

print()
print("=== 3. 브랜드 간 독립 — 한 브랜드 등록이 다른 브랜드에 안 샘 ===")
do
	local a, b = Brand.Brand(), Brand.Brand()
	local x = {}
	a:register(x)
	assert(b:is(x) == false, "registration must not leak across brands")
	print("PASS")
end

print()
print("=== 4. weak-key — 등록만으로는 값이 살아남지 않음 ===")
do
	local b = Brand.Brand()
	local weak = setmetatable({}, { __mode = "v" })
	do
		local x = {}
		b:register(x)
		weak[1] = x
	end
	collectgarbage()
	collectgarbage()
	assert(weak[1] == nil, "brand membership must not keep the value alive")
	print("PASS")
end

print()
print("=== 5. isRef 계층 — PreRef/PostRef는 Ref의 한 종류, 서로는 배타 ===")
do
	local pre, post, plain = {}, {}, {}
	Brand.PreRefBrand:register(pre)
	Brand.PostRefBrand:register(post)
	Brand.RefBrand:register(plain)

	assert(Brand.isRef(pre) and Brand.isRef(post) and Brand.isRef(plain), "isRef passes {Ref, PreRef, PostRef}")
	assert(Brand.isPreRef(pre) and not Brand.isPreRef(post) and not Brand.isPreRef(plain), "isPreRef is the most specific identity")
	assert(Brand.isPostRef(post) and not Brand.isPostRef(pre) and not Brand.isPostRef(plain), "isPostRef is the most specific identity")
	-- Leaf 매치 핸들러가 쓰는 좁힘(`isRef(v) and not isPreRef(v) and not isPostRef(v)`)
	local function isPlainRef(v)
		return Brand.isRef(v) and not Brand.isPreRef(v) and not Brand.isPostRef(v)
	end
	assert(isPlainRef(plain) and not isPlainRef(pre) and not isPlainRef(post), "plain-Ref narrowing")
	print("PASS")
end

print()
print("=== 6. isState 계층 — Source는 State를 구조적으로 만족 ===")
do
	local src, st = {}, {}
	Brand.SourceBrand:register(src)
	Brand.StateBrand:register(st)
	assert(Brand.isState(src) and Brand.isState(st), "isState passes both")
	assert(Brand.isSource(src) and not Brand.isSource(st), "isSource is the narrower one")
	print("PASS")
end

print()
print("=== 7. 단순 항등 술어 + Quad 탑레벨 재export ===")
do
	local pairsToCheck: { { brand: Brand.Brand, name: string } } = {
		{ brand = Brand.EpochBrand, name = "isEpoch" },
		{ brand = Brand.StoreBrand, name = "isStore" },
		{ brand = Brand.ObserverBrand, name = "isObserver" },
		{ brand = Brand.EffectBrand, name = "isEffect" },
		{ brand = Brand.BlockerBrand, name = "isBlocker" },
		{ brand = Brand.ModifierBrand, name = "isModifier" },
	}
	for _, pair in pairsToCheck do
		local brand, name = pair.brand, pair.name
		local x = {}
		assert((Quad :: any)[name] == (Brand :: any)[name], name .. " must be re-exported on Quad as the same function")
		assert((Brand :: any)[name](x) == false, name .. " false before registration")
		brand:register(x)
		assert((Brand :: any)[name](x) == true, name .. " true after registration")
	end
	print("PASS")
end

print()
print("=== ALL PASS ===")
