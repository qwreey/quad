--!strict
-- round13 E25 type probe. `-- E:` expects an error on that line, `-- OK:` none.
-- Run: mise exec -- luau-lsp analyze --flag:LuauSolverV2=true --flag:LuauTarjanChildLimit=160000 \
--   --flag:LuauSubtypingIterationLimit=100000 --flag:LuauTypeInferIterationLimit=1000000 \
--   --definitions=scripts/roblox-defs/globalTypes.d.luau --ignore "**/luau_packages/**" .claude/audit/round13-e25-probe-types.luau
local q = require("./round13-e14-types-settings")
local D = q.Declaration

local function _T()
	local _1 = D.Frame({ Parent = Instance.new("Folder") }) -- E:T1 Parent
	local _2 = D.Frame({ AbsoluteSize = Vector2.new() }) -- E:T2 read-only
	local _3 = D.Frame({ ClassName = "x" }) -- E:T3 read-only ClassName
	local _4 = D.Frame({ size = UDim2.new() }) -- E:T4 lowercase
	local _5 = D.Frame({ archivable = false }) -- E:T5 dropped lowercase alias
	local _6 = D.Frame({ Draggable = true }) -- E:T6 dropped Deprecated
	local _7 = D.TextLabel({ Font = Enum.Font.Gotham }) -- OK:T7 Hidden kept
	local _8 = D.TextLabel({ FontSize = Enum.FontSize.Size14, TextWrap = true }) -- OK:T8 Deprecated kept
	local _9 = D.TextLabel({ Font = Enum.Font.Gotham, FontFace = Font.new("x") }) -- OK:T9 alias pair both typed
	local _10 = D.Frame({ Transparency = 0.5 }) -- OK:T10 Hidden kept (GuiObject)
	local _11 = D.UIStroke({ Transparency = 0.5 }) -- OK:T11 UIStroke.Transparency (real, non-legacy)
	local _12 = D.Folder({ UICorner = 8 }) -- E:T12 shorthand on non-GuiObject
	local _13 = D.Frame({ DragBegin = function() end }) -- E:T13 dropped Deprecated event
	local _14 = D.Frame({ Changed = function(_p: string) end }) -- OK:T14 Changed event
	local _15 = D.Frame({ MouseEnter = 5 }) -- E:T15 event non-function
	local _16 = D.Frame({ MouseEnter = q.Source(function(_x: number, _y: number) end) }) -- OK:T16 State<fn>
	local _17 = D.Frame({ MouseEnter = q.Tween({ Value = 1 }) }) -- E:T17 Tween on event
	local _18 = D.Frame({ Name = "x", Archivable = false }) -- OK:T18 Instance props
	local _19 = D.TextLabel({ Transparency = q.Tween({ Value = 1 }) }) -- OK:T19 Tween arm on legacy number
	local _20 = D.TextLabel({ FontSize = q.Tween({ Value = Enum.FontSize.Size14 }) }) -- E:T20 Tween arm on enum legacy
	local _21 = D.Modifier.TextLabel():Font(Enum.Font.Gotham) -- OK:T21 legacy Modifier setter
	local _22 = D.Modifier.Frame():Draggable(true) -- E:T22 dropped legacy setter
	local _23 = q.OnChange("className", function(_v: string) end) -- E:T23 dropped read alias
	local _24 = q.OnChange("AbsoluteSize", function(_v: Vector2) end) -- OK:T24 read surface
	local _25 = q.OnChange("Font", function(_v: Enum.Font) end) -- OK:T25 legacy on read surface (write props are part of PropTypesRead)
	local _26 = D.Camera({ CFrame = CFrame.new() }) -- OK:T26 Camera
	local _27 = D.Camera({ CoordinateFrame = CFrame.new() }) -- E:T27 dropped legacy alias
	local _28 = D.Camera({ focus = CFrame.new() }) -- E:T28 dropped lowercase
	local _29 = D.TextBox({ ReturnKeyType = Enum.ReturnKeyType.Done }) -- E:T29 Hidden (non-allowlisted)
	local _30 = D.Frame({ ["Pivot Offset"] = CFrame.new() }) -- E:T30 NotScriptable with space
end
return nil
