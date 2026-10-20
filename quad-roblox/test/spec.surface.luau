--!nocheck
--[[
	3.4.0 curried surface — the runtime of `Surface/Runtime.luau` + `Handlers/OnEvent.luau` (plan
	`.claude/research/release-3.4.0-plan.md` 단위 4; canon `research/declaration-surface-plan.md` 5절). The types are
	gated by `scripts/surface-gate.py`; this spec runs the values on the CLI mock (spec.events shims).
	3.4.0 removed the 3.3 shapes (`q.OnChange(name, fn)`, base's `q.Modifier(...)` — now `q.Raw.Modifier`).
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local QuadTypes = require("../luau_packages/quad_types")
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local mock = require("../../quad-base/test/mock")

local SPEC_FILE = "spec.surface.luau"

local W = { Write = "" }
local REFLECTED = {
	TextButton = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W }, { Name = "Visible", Permits = W } },
	Frame = { { Name = "Name", Permits = W }, { Name = "Visible", Permits = W } },
	TextBox = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W } },
}
mock.declareEvents("TextButton", { "MouseButton1Click", "Activated", "MouseLeave" })
mock.declareEvents("Frame", { "MouseEnter", "MouseLeave" })
local gameShim = mock.gameShim(REFLECTED)

local q = Quad.NewModule():UseProvider(QuadRoblox)
;(getfenv(installProperty)).game = gameShim
;(getfenv(installEvent)).game = gameShim
;(getfenv(q.Elem)).Instance = { new = mock.Instance.new }
;(getfenv(q.Elem)).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
q.errorNamespace.setFuncLevel(QuadTypes.ERROR_LEVEL_SURFACE, q.Backend.isInst)

local function expectError(f: () -> (), code: string, label: string)
	local ok, err = pcall(f)
	assert(not ok, label .. ": expected " .. code)
	assert(string.find(tostring(err), code, 1, true) ~= nil, label .. ": wrong error " .. tostring(err))
	mock.assertBlamesUser(err, SPEC_FILE, label)
end

print("=== 1. Elem — 클래스 먼저, 인스턴스 생성 + drive(옛 D와 같은 파이프라인) ===")
do
	local Frame = q.Elem "Frame"
	local TextButton = q.Elem "TextButton"
	local f = Frame { Name = "Root", Visible = false, TextButton { Name = "Child", Text = "hi" } }
	assert(f.ClassName == "Frame" and f.Name == "Root" and f.Visible == false, "props written")
	local child = f:FindFirstChild("Child")
	assert(child ~= nil and child.ClassName == "TextButton" and child.Text == "hi", "array-part child parented")
	expectError(function()
		q.Elem(5)
	end, "Quad0278", "Elem needs a class name string")
	expectError(function()
		q.Elem ""
	end, "Quad0278", "Elem rejects the empty name")
	print("PASS")
end

print()
print("=== 2. Modifier \"Class\" — 타입드 팩토리(As 간선은 Superclass 데이터로 설치 때 등록), base 무타입은 q.Raw.Modifier ===")
do
	local FrameModifier = q.Modifier "Frame"
	local GuiModifier = q.Modifier "GuiObject"
	local m = FrameModifier():Visible(false)
	assert(m.__quadModifier == "Frame", "tagged with its class")
	local g = GuiModifier():Visible(true):AsFrame()
	assert(g.__quadModifier == "Frame", "checked down-cast GuiObject -> Frame through the installed edges")
	-- a class outside the GUI scope (a `q.ForClasses` map) has its edges too
	local bp = q.Modifier "BasePart" ()
	assert(bp:AsPart().__quadModifier == "Part", "BasePart -> Part edge from the Superclass table")
	expectError(function()
		m:AsTextButton()
	end, "Quad0056", "sibling cast still refused")
	local f = q.Elem "Frame" { m, Name = "M" }
	assert(f.Visible == false, "a typed Modifier flattens into the element")
	-- base's untyped constructor and its fields moved to q.Raw.Modifier
	local old = q.Raw.Modifier({ Visible = true })
	assert(old.__quadModifier == true and q.Raw.Modifier().__quadModifier == true, "q.Raw.Modifier() / q.Raw.Modifier({...})")
	assert(q.Raw.Modifier.TypedFactory ~= nil and q.Raw.Modifier.DefineSubtype ~= nil and q.Raw.Modifier.Overridden ~= nil, "its fields")
	expectError(function()
		q.Modifier({ Visible = true })
	end, "Quad0278", "the 3.3 untyped q.Modifier({...}) is refused (the message points at q.Raw.Modifier)")
	expectError(function()
		q.Modifier ""
	end, "Quad0278", "Modifier rejects the empty class name")
	print("PASS")
end

print()
print("=== 3. Spread \"Class\" — 런타임은 q.Raw.Spread 그대로(클래스는 타입에만), 요소에 펼쳐짐 ===")
do
	local FrameSpread = q.Spread "Frame"
	assert(FrameSpread == q.Raw.Spread, "the class stage returns the raw constructor")
	local s = FrameSpread { Name = "FromSpread", Visible = false }
	local f = q.Elem "Frame" { s, Name = "Inline" }
	assert(f.Name == "Inline" and f.Visible == false, "inline wins, the Spread fills the rest")
	expectError(function()
		q.Spread(nil)
	end, "Quad0278", "Spread needs a class name")
	print("PASS")
end

print()
print("=== 4. OnEvent — 배열부 디스크립터, 같은 이벤트 둘 다 연결, 철거 때 끊김, 이벤트 인자 그대로 ===")
do
	local OnEvent = q.OnEvent "Frame"
	local a, b = {}, {}
	local f = q.Elem "Frame" {
		OnEvent "MouseEnter" (function(x, y)
			table.insert(a, x + y)
		end),
		OnEvent "MouseEnter" (function(x)
			table.insert(b, x)
		end),
	}
	f.MouseEnter:Fire(1, 2)
	assert(a[1] == 3 and b[1] == 1, "both descriptors bound, engine args passed as-is")
	assert(q.Bookkeeping.getOffsetAt(f, 3) == 0, "descriptors contribute length 0")
	assert(#f.MouseEnter.connections == 2, "two live connections")
	q.Dispatch.retractFrom(f, 1, 1)
	q.Dispatch.retractFrom(f, 2, 1)
	assert(#f.MouseEnter.connections == 0, "retraction disconnects")
	-- with a Spread: hooks bringing their own handler for the same event both run
	local hookA = q.Spread "Frame" { OnEvent "MouseLeave" (function() table.insert(a, "hookA") end) }
	local hookB = q.Spread "Frame" { OnEvent "MouseLeave" (function() table.insert(a, "hookB") end) }
	local g = q.Elem "Frame" { hookA, hookB }
	g.MouseLeave:Fire()
	assert(table.find(a, "hookA") and table.find(a, "hookB"), "descriptors never collide (unlike hash keys)")
	expectError(function()
		OnEvent "" (function() end)
	end, "Quad0279", "empty event name")
	expectError(function()
		OnEvent "MouseEnter" (5)
	end, "Quad0280", "callback must be a function")
	expectError(function()
		q.OnEvent(false)
	end, "Quad0278", "OnEvent class stage")
	print("PASS")
end

print()
print("=== 5. OnChange·Out 커리 — 클래스 → 이름 → fn/src, 옛 두 인자 꼴은 3.4.0에서 없어졌다 ===")
do
	local seen = {}
	local src = q.Source("a")
	local box = q.Elem "TextBox" {
		Text = src,
		q.OnChange "TextBox" "Text" (function(v)
			table.insert(seen, v)
		end),
		q.Out "TextBox" "Text" (src),
	}
	assert(seen[1] == "a", "initial-value firing through the curried form")
	box.Text = "typed"
	assert(src:Get() == "typed", "Out writes back")
	expectError(function()
		q.OnChange("Name", function() end)
	end, "Quad0281", "the 3.3 two-argument form is refused at the call")
	expectError(function()
		(q.OnChange "TextLabel" :: any)("Text", function() end)
	end, "Quad0281", "a half-migrated two-argument member stage is refused too (the callback would be dropped)")
	assert(q.OnChange "Frame" == q.OnChange "TextLabel", "the member stage does not depend on the class (one function)")
	assert(q.OnEvent "Frame" "MouseEnter" == q.OnEvent "TextButton" "MouseEnter", "the value stage is cached per member name")
	assert(q.Elem "Frame" == q.Elem "Frame", "the Elem stage is cached per class")
	expectError(function()
		q.OnChange "TextBox" "" (function() end)
	end, "Quad0221", "member stage reuses OnChange's name check")
	expectError(function()
		q.Out "TextBox" "Text" (q.Source(1):Compute(function(x) return x end))
	end, "Quad0224", "Out needs a writable Source")
	print("PASS")
end

print()
print("=== 6. Mapper·ForClasses — Mapper \"Class\"(key){…}는 Raw.Mapper(class), ForClasses()는 같은 함수들(타입만 다름) ===")
do
	local desc = q.Mapper "Frame" ("Card") { Visible = true }
	assert(q.isMapperDescriptor(desc), "a mapper descriptor")
	local World = q.ForClasses()
	for _, name in { "Elem", "Modifier", "Spread", "Mapper", "OnChange", "OnEvent", "Out" } do
		assert(World[name] == q[name], name .. ": the same runtime function (only the types differ)")
	end
	assert(World.Modifier "Part" ().__quadModifier == "Part", "a class outside the GUI map")
	assert(Quad.NewModule():UseProvider(QuadRoblox).OnEvent == q.OnEvent, "descriptor stages are module-level (like OnChange)")
	expectError(function()
		World.Modifier({})
	end, "Quad0278", "ForClasses Modifier takes only a class name")
	print("PASS")
end

print()
print("ALL PASS")
