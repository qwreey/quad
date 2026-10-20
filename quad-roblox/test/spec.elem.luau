--[[
	3.4.0 element constructors — the runtime contract of `q.Elem "Class"` (`Surface/Runtime.luau`; until 3.3 this file
	was spec.d, the generated `Declaration`'s structure contract). The typed side (which names exist, scope rules,
	Parent / read-only refusals) is the type functions' and is gated by `scripts/surface-gate.py`.
	Plan `.claude/research/release-3.4.0-plan.md` 단위 6.
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local QuadTypes = require("../luau_packages/quad_types")
-- mock에선 quad를 만들지 않는 헬퍼만 빌린다(사본 혼입 주의 — spec.robloxfactory 헤더)
local mock = require("../../quad-base/test/mock")
local q: any = Quad.NewModule():UseProvider(QuadRoblox)
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

print("=== 1. 설치 — 클래스 먼저 생성자 일곱 + ForClasses, 전부 SURFACE 태그, 갓 만든 단계도 태그 ===")
do
	for _, name in { "Elem", "Modifier", "Spread", "Mapper", "OnChange", "OnEvent", "Out", "ForClasses" } do
		assert(type(q[name]) == "function", name .. " installed")
		assert(q.errorNamespace.getFuncLevel(q[name]) == SURFACE, name .. " tagged")
	end
	assert(q.Declaration == nil, "the 3.3 generated Declaration is gone")
	-- a stage made for any class name (the type surface decides which names are valid — the runtime takes a string)
	assert(q.errorNamespace.getFuncLevel(q.Elem "SomeOutOfScopeClass") == SURFACE, "fresh stage is tagged (H-238)")
	print("PASS")
end

print()
print("=== 2. Modifier 간선 — 설치 때 Superclass 표 전부(스코프 밖 조상까지), TypedFactory dedup ===")
do
	local gui = q.Modifier "GuiObject"
	assert(gui():Visible(true):AsTextLabel().__quadModifier == "TextLabel", "checked descent on a GUI chain")
	assert(q.Modifier "Instance" ().__quadModifier == "Instance", "the chain root has a constructor too")
	assert(q.Modifier "Frame" == q.Raw.Modifier.TypedFactory("Frame"), "TypedFactory dedup: same name, same ctor")
	assert(q.Modifier "PVInstance" ():AsPart().__quadModifier == "Part", "a non-GUI chain (q.ForClasses classes) has its edges")
	print("PASS")
end

print()
print("=== 3. 파이프라인 CLI e2e — getfenv 주입으로 ① 생성 + ② nativeClaim 실주행, 스코프 밖 클래스도 같은 길 ===")
do
	-- the stage reads the global `Instance` lazily — injecting a mock into the runtime module's env runs the pipeline
	getfenv(q.Elem :: any).Instance = { new = mock.Instance.new }
	local frame = q.Elem "Frame" {} :: any
	assert(mock.isMockInstance(frame) and frame.ClassName == "Frame", "① 물리 생성 완주(mock)")
	local ok, err = pcall(function()
		q.Backend.nativeClaim(frame)
	end)
	assert(not ok and string.find(tostring(err), "already claimed", 1, true) ~= nil, "② Elem이 nativeClaim을 이미 걸었다: " .. tostring(err))
	local part = q.Elem "Part" {} :: any
	assert(mock.isMockInstance(part) and part.ClassName == "Part", "a class outside the GUI map runs the same pipeline")
	print("PASS")
end

print()
print("=== ALL PASS ===")
