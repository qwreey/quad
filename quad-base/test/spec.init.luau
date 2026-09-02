--[[
	`Quad` 탑레벨 값 존재 확인 — `quad-types`의 `Quad` 타입과 `New()`가 실제로 싣는 값의
	드리프트(`ROADMAP.md` M2 `H-80`/`H-25` 부류)를 타입 검사 아래에서 잡는다.
	`init.luau`의 `{...} :: Quad` 캐스트는 빠진 필드를 안 잡으므로(실측) 이 런타임 확인이
	유일한 가드다 — 그래서 `smoke.*`(analyze 제외)가 아니라 `spec.*`에 둔다.
]]

local Quad = require("../src")
local mock = require("./mock")
local QuadTypes = require("../luau_packages/quad_types")

type Quad = QuadTypes.Quad

print("=== 1. New()마다 M2 첫 단위 탑레벨 값이 실려 있음 ===")
do
	local m: Quad = Quad.New()
	assert(type(m.Relate) == "function" and type(m.Void) == "function" and type(m.Ref) == "function", "Relate/Void/Ref constructors")
	assert(type(m.Source) == "function" and type(m.Store) == "function", "Source/Store constructors (unit 2, per instance)")
	assert(type(m.Effect) == "function" and m.Effect ~= Quad.Effect, "Effect constructor (unit 3, per instance)")
	assert(type(m.Blocker) == "function" and m.Blocker == Quad.Blocker, "Blocker constructor (unit 4, shared leaf)")
	assert(type(m.onDestroying) == "function", "onDestroying engine-op stub")
	assert(m.Source ~= Quad.Source, "Source is an instance-level factory (H-174), not a shared leaf")
	local predicates: { (any) -> boolean } = {
		m.isEpoch, m.isSource, m.isState, m.isStore, m.isObserver, m.isEffect,
		m.isBlocker, m.isModifier, m.isRef, m.isPreRef, m.isPostRef,
	}
	for i, p in predicates do
		assert(type(p) == "function", "predicate #" .. i .. " must be a function")
		assert(p({}) == false, "predicate #" .. i .. " is false for an unregistered table")
	end
	assert(type(m.bindLifetime) == "function" and type(m.unbindLifetime) == "function", "lifetime stubs")
	assert(type(m.canBound) == "function" and type(m.canExecute) == "function", "lifetime stubs")
	assert(m.Void == Quad.Void and m.Ref == Quad.Ref and m.Relate == Quad.Relate, "leaf modules are shared across instances")
	print("PASS")
end

print()
print("=== 2. [H-181] New() 인스턴스는 참조를 놓으면 수거된다 — 임플을 모듈 비공개 필드에 두므로 순환이 자기완결 ===")
do
	local collectgarbage = (_G :: any).collectgarbage :: () -> ()
	local weak = setmetatable({}, { __mode = "v" }) :: { any }
	local function make()
		local q = Quad.New()
		mock.installLifetime(q)
		local s = q.Source(1)
		q.Effect(function() end, s):Subscribe() -- 강한 레지스트리까지 채워도 인스턴스째 죽어야 한다
		weak[1] = q
	end
	make()
	collectgarbage()
	collectgarbage()
	assert(weak[1] == nil, "a dropped quad instance is collected (no module-keyed weak map pinning it)")
	print("PASS")
end

print()
print("=== ALL PASS ===")
