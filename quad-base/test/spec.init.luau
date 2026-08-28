--[[
	`Quad` 탑레벨 값 존재 확인 — `quad-types`의 `Quad` 타입과 `New()`가 실제로 싣는 값의
	드리프트(`ROADMAP.md` M2 `H-80`/`H-25` 부류)를 타입 검사 아래에서 잡는다.
	`init.luau`의 `{...} :: Quad` 캐스트는 빠진 필드를 안 잡으므로(실측) 이 런타임 확인이
	유일한 가드다 — 그래서 `smoke.*`(analyze 제외)가 아니라 `spec.*`에 둔다.
]]

local Quad = require("../src")
local QuadTypes = require("../roblox_packages/quad_types")

type Quad = QuadTypes.Quad

print("=== 1. New()마다 M2 첫 단위 탑레벨 값이 실려 있음 ===")
do
	local m: Quad = Quad.New()
	assert(type(m.Relate) == "function" and type(m.Void) == "function" and type(m.Ref) == "function", "Relate/Void/Ref constructors")
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
print("=== ALL PASS ===")
