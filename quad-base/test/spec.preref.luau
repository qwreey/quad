--!strict
--[[
	PreRef / PostRef 값 계약 (M8 단위 ①) — `base/ref-plan.md` "`phase` 옵션 폐기 →
	위치로 표현, `PreRef` 신설" 절 / "`PostRef`" 절 / "타입/판별" 문단,
	`brand-plan.md`(다중 태깅). 런타임은 Ref 그대로 + 브랜드 + 마커 + `_fired`.
	pre-pass·핸들러(fire 시점·`_fired` 소진·가드)는 단위 ②(`spec.refhandlers`).
]]

local Quad = require("../src")
local QuadTypes = require("../luau_packages/quad_types")
local Ref, PreRef, PostRef = Quad.Ref, Quad.PreRef, Quad.PostRef

-- 타입 양성(strict — 본문 실행 없음): `<Self>` 메소드라 체이닝 뒤에도 nominal
-- 마커가 산다(`H-317`); plain Ref는 PreRef 자리에 못 간다(음성은 스크래치 실측)
local function _types()
	local a: QuadTypes.PreRef<number> = PreRef(0):Callback(function() end):Set(1)
	local b: QuadTypes.PostRef<string?> = PostRef(nil :: string?):Wait()
	local c: QuadTypes.Ref<number> = PreRef(0) -- PreRef는 Ref 자리에 들어간다(폭)
	return a, b, c
end

print("=== 1. 브랜드 삼분 — isRef는 셋 다 참, isPreRef/isPostRef는 서로소, Epoch도 그대로 ===")
do
	local r, pre, post = Ref(0), PreRef(0), PostRef(0)
	assert(Quad.isRef(r) and Quad.isRef(pre) and Quad.isRef(post), "isRef covers all three kinds")
	assert(Quad.isPreRef(pre) and not Quad.isPreRef(r) and not Quad.isPreRef(post), "isPreRef only for PreRef")
	assert(Quad.isPostRef(post) and not Quad.isPostRef(r) and not Quad.isPostRef(pre), "isPostRef only for PostRef")
	assert(Quad.isEpoch(pre) and Quad.isEpoch(post), "PreRef/PostRef are Epochs like Ref")
	-- 판별 공식(정본 "타입/판별"): 일반 Ref = isRef ∧ ¬isPreRef ∧ ¬isPostRef
	assert(Quad.isRef(r) and not Quad.isPreRef(r) and not Quad.isPostRef(r), "plain-Ref formula")
	print("PASS")
end

print()
print("=== 2. 런타임은 Ref 그대로 — Value/Set/Callback/Wait, 마커 필드(H-300), _fired 초기 false ===")
do
	local pre = PreRef(nil :: number?)
	local calls, last = 0, nil :: number?
	pre:Callback(function(v)
		calls += 1
		last = v
	end)
	assert(calls == 1 and last == nil, "registration fires once with nil (H-120)")
	pre:Set(5)
	assert(pre.Value == 5 and calls == 2 and last == 5, "Ref semantics unchanged")
	assert((pre :: any).__quadPreRef == true and (pre :: any).__quadPostRef == nil, "PreRef carries its marker only")
	local post = PostRef(1)
	assert((post :: any).__quadPostRef == true and (post :: any).__quadPreRef == nil, "PostRef carries its marker only")
	assert((pre :: any)._fired == false and (post :: any)._fired == false, "one-shot guard starts unfired (unit ② flips it)")
	local co = coroutine.create(function()
		post:Wait()
	end)
	coroutine.resume(co)
	post:Set(2)
	assert(coroutine.status(co) == "dead", "Wait works on a PostRef too")
	print("PASS")
end

print()
print("=== 3. 값 자리 — Modifier 필드는 Ref 계열 전부 거부(modifier-plan 4절, isRef), Source 값은 런타임에선 통과(타입·디스패치 가드 몫) ===")
do
	local q = require("./mock").newQuad()
	for _, v in { q.PreRef(0), q.PostRef(0) } do
		local ok = pcall(function()
			q.Raw.Modifier():X(v)
		end)
		assert(not ok, "Modifier field rejects PreRef/PostRef (handler-layer value, isRef)")
		-- Source/State는 M2 가드가 isModifier만 본다 — `State<Ref>`는 정본이 설계한
		-- 재바인드 경로(ref-plan "Ref의 retract" 절)이고, PreRef/PostRef가 Store 값으로
		-- 오는 것은 타입 차단 + 단위 ②의 FALLBACK 가드 핸들러가 잡는다
		local src = q.Source(v)
		assert(src:Get() == v, "Source holds a PreRef/PostRef at runtime (guarding is the dispatcher's)")
	end
	print("PASS")
end

print()
print("=== ALL PASS ===")
