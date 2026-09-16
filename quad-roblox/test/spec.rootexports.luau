--!strict
--[[
	Generated root re-exports (2026-09-15, public surface (28) provisional; 2026-09-16 per-class names
	added — docs-review 2-2 / HUMAN_TODO D, generated Declaration = stable surface): `Field<T>`/`FieldOut<T>`
	plus `<Class>Modifier` / `Into<Class>` / `<Class>Elem` — the names how-to 01·05 and specs write.
	Positive only; the body is not executed (spec.modifiertypes convention).
]]

local Quad = require("../luau_packages/quad_base")
local Root = require("../src")

local q = Quad.New():UseProvider(Root.QuadRoblox)

local function _neverCalled()
	local frame = q.Declaration.Modifier.Frame():Visible(true)
	local size: Root.Field<UDim2> = UDim2.new()
	local peeked: Root.FieldOut<UDim2>? = frame:Size(size):Peek<<UDim2>>("Size")
	-- per-class names through the root (2026-09-16): concrete Modifier, ancestor Modifier, Into<Class>, Elem
	local tb: Root.TextButtonModifier = q.Declaration.Modifier.TextButton():Text("hi")
	local gui: Root.GuiObjectModifier = q.Declaration.Modifier.GuiObject():Visible(true)
	local into: Root.IntoTextButton = gui
	local narrowed: Root.TextButtonModifier = into:AsTextButton()
	local elem: Root.FrameElem = tb :: any
	return peeked, tb, narrowed, elem
end

print("=== ALL PASS ===")
