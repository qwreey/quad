--!strict
--[[
	quad-roblox root type names (3.4.0 — `research/declaration-naming-table.md` 5절): one generic per axis, the class is
	the type argument. Positive only; the body is not executed (spec.modifiertypes convention). Negatives live in the
	surface gate fixture (`test/surface/cases.luau`). Until 3.3 this file pinned the generated per-class names
	(`FrameModifier`, `IntoFrame`, `FrameElem`, `Field`).
]]

local Quad = require("../luau_packages/quad_base")
local Root = require("../src")

local q = Quad.NewModule():UseProvider(Root.QuadRoblox)

local function _neverCalled()
	local frame = q.Modifier "Frame" ():Visible(true)
	local size: Root.ModifierField<UDim2> = UDim2.new()
	local peeked = frame:Size(size):Peek<<UDim2>>("Size")
	local stored: Root.ModifierFieldOut<UDim2>? = nil
	local tb: Root.Modifier<TextButton> = q.Modifier "TextButton" ():Text("hi")
	local gui: Root.Modifier<GuiObject> = q.Modifier "GuiObject" ():Visible(true)
	-- an input position takes the marker: same class or an ancestor
	local into: Root.ModifierInto<TextButton> = gui
	local into2: Root.ModifierInto<TextButton> = tb
	local narrowed: Root.Modifier<TextButton> = gui:AsTextButton()
	local spread: Root.Spread<Frame> = q.Spread "Frame" { Visible = true }
	local spreadIn: Root.SpreadInto<Frame> = q.Spread "GuiObject" { ZIndex = 2 }
	local props: Root.Props<Frame> = { Size = UDim2.new(), spread, into :: any }
	local hash: Root.PropsHashPart<TextLabel> = { Text = "x" }
	local item: Root.PropsArrayItem<Frame> = q.Elem "TextLabel" {}
	local ctor: Root.ElemCtor<Frame> = q.Elem "Frame"
	local made: Frame = ctor(props)
	local mprops: Root.MapperProps<Frame> = { Visible = true }
	local size2: index<Root.PropertyMap<Frame>, "Size"> = UDim2.new()
	local changed: Root.OnChangeDescriptor<"Size"> = q.OnChange "Frame" "Size" (function(_v: UDim2) end)
	local entered: Root.OnEventDescriptor<"MouseEnter"> = q.OnEvent "Frame" "MouseEnter" (function(_x: number, _y: number) end)
	return peeked, stored, into, into2, narrowed, spreadIn, hash, item, made, mprops, size2, changed, entered
end

print("=== ALL PASS ===")
