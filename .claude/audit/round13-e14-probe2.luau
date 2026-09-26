--!nocheck
-- round13 E14 probe (scratch) — Modifier factory / setter chain / __apply / typed factory.
-- Run from repo root: `luau .claude/audit/round13-e14-probe.luau` (after ./scripts/relink.sh).
local Quad = require("../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../quad-roblox/src").QuadRoblox
local installProperty = require("../../quad-roblox/src/Handlers/Property")
local installEvent = require("../../quad-roblox/src/Handlers/Event")
local installShorthand = require("../../quad-roblox/src/Handlers/InstanceShorthand")
local installEngineOps = require("../../quad-roblox/src/EngineOps")
local mock = require("../../quad-base/test/mock")

local W = { Write = "" }
local function props(...)
	local t = {}
	for _, n in { ... } do table.insert(t, { Name = n, Permits = W }) end
	return t
end
local REFLECTED = {
	Frame = props("Name", "Size", "Visible", "BackgroundTransparency", "LayoutOrder", "ZIndex", "BackgroundColor3", "BorderSizePixel", "Style", "Position"),
	TextButton = props("Name", "Text", "Visible", "Size", "TextSize", "BackgroundColor3", "TextColor3", "BorderSizePixel", "ZIndex", "Position", "FontFace", "BackgroundTransparency"),
	TextLabel = props("Name", "Text", "Visible", "Size", "TextSize", "TextColor3", "BackgroundTransparency", "ZIndex"),
	UICorner = props("Name", "CornerRadius"),
}
mock.declareEvents("TextButton", { "Activated", "MouseEnter", "MouseButton1Click" })
mock.declareEvents("Frame", { "Changed", "MouseEnter" })
local gameShim = mock.gameShim(REFLECTED)
local q = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty)).game = gameShim
;(getfenv(installProperty)).TweenInfo = mock.tweenInfoShim
;(getfenv(installProperty)).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" }, PlaybackState = { Completed = "Completed", Cancelled = "Cancelled" } }
;(getfenv(installEvent)).game = gameShim
;(getfenv(installEngineOps)).game = gameShim
;(getfenv(q.Declaration.New)).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
local D = q.Declaration
local UDIM_MT = { __eq = function(a, b) return a.Scale == b.Scale and a.Offset == b.Offset end }
UDim = { new = function(s, o) return setmetatable({ Scale = s, Offset = o }, UDIM_MT) end }
;(getfenv(installShorthand)).UDim = UDim

local function first(err) return (tostring(err):gsub("\n.*", "")) end
local function try(label, fn)
	local ok, err = pcall(fn)
	print(label, ok and "OK" or ("ERR: " .. first(err)))
	return ok, err
end
local FK = require("../../quad-roblox/luau_packages/.pesde/qwreey+quad_base/3.2.0/quad_base/src/Dispatch/Modifier")._FieldsKey
local function fields(m)
	local out = {}
	for k, v in m[FK] do table.insert(out, k .. "=" .. (if q.isState(v) then "<State>" elseif v == q.None then "None" else tostring(v))) end
	table.sort(out)
	return table.concat(out, ",")
end
REFLECTED.TextButton = props("Name", "Text", "Visible", "Size", "TextSize", "BackgroundColor3", "TextColor3", "BorderSizePixel", "ZIndex", "Position", "FontFace", "BackgroundTransparency", "LayoutOrder")
REFLECTED.TextLabel = props("Name", "Text", "Visible", "Size", "TextSize", "TextColor3", "BackgroundTransparency", "ZIndex", "Position", "FontFace", "TextXAlignment")
Color3 = { fromRGB = function(r, g, b) return ("rgb(%d,%d,%d)"):format(r, g, b) end }
UDim2 = { fromOffset = function(x, y) return ("off(%s,%s)"):format(x, y) end, fromScale = function(x, y) return ("sc(%s,%s)"):format(x, y) end, new = function(a, b, c, d) return ("u(%s,%s,%s,%s)"):format(a, b, c, d) end }
Enum = { Font = { GothamBold = "GothamBold" }, FrameStyle = { Custom = "Custom" } }
Font = { fromEnum = function(e) return "font:" .. tostring(e) end }

print("== S1 transform over State old: nil / throw / Modifier / function ==")
do
	local src = q.Source(1)
	local base = q.Modifier({ LayoutOrder = src })
	local absentPlain = q.Modifier({ LayoutOrder = 1 }):LayoutOrder(function() return nil end)
	local viaState = base:LayoutOrder(function() return nil end)
	print("  plain->nil fields:", fields(absentPlain), "| state->nil fields:", fields(viaState))
	local f = D.Frame({ q.Modifier({ LayoutOrder = 9 }), viaState })
	print("  earlier mod LayoutOrder=9, later state->nil mod: LayoutOrder =", f.LayoutOrder)
	local g = D.Frame({ q.Modifier({ LayoutOrder = 9 }), absentPlain })
	print("  earlier mod 9, later plain->nil (absent): LayoutOrder =", g.LayoutOrder)
	local throwing = base:LayoutOrder(function(old) if old:Get() > 1 then error("boom") end return old:Get() end)
	try("  drive throwing-state transform (ok at 1)", function() D.Frame({ throwing }) end)
	try("  Set(2) -> transform throws", function() src:Set(2) end)
	src:Set(1)
	local modRet = base:LayoutOrder(function() return q.Modifier() end)
	try("  construct state->Modifier", function() return modRet end)
	try("  drive state->Modifier", function() D.Frame({ modRet }) end)
	local refRet = base:LayoutOrder(function() return q.Ref() end)
	try("  drive state->Ref (documented UB)", function() D.Frame({ refRet }) end)
	local evt = q.Modifier({ Activated = q.Source(function() print("    first handler") end) }):Activated(function(old)
		return function() print("    wrapped handler") end
	end)
	try("  state-old transform returning function -> event", function() local b = D.TextButton({ evt }); b.Activated:Fire() end)
end

print("== S2 Apply with factories returning non-Modifier / Peek odd keys ==")
try("mod:Apply(returns number)", function() print("  ->", q.Modifier():Apply(function() return 5 end)) end)
try("mod:Peek('AsFrame')", function() print("  ->", q.Modifier({}):Peek("AsFrame")) end)
try("mod:Peek('__x')", function() print("  ->", q.Modifier({}):Peek("__x")) end)
try("mod:Peek('Peek')", function() print("  ->", q.Modifier({}):Peek("Peek")) end)

print("== S3 custom class ==")
try("TypedFactory('Card') + DefineSubtype('Clickable','Card') + As", function()
	local Card = q.Modifier.TypedFactory("Card")
	q.Modifier.TypedFactory("Clickable")
	q.Modifier.DefineSubtype("Clickable", "Card")
	local raised = Card({ Elevation = 2 })
	print("  raised", tostring(raised), raised:Peek("Elevation"))
	local c = q.Modifier.TypedFactory("Clickable")({}):AsCard()
	print("  clickable->card", tostring(c))
end)
try("TypedFactory('Frame') same ctor as D.Modifier.Frame", function() print("  same:", q.Modifier.TypedFactory("Frame") == D.Modifier.Frame) end)
try("DefineSubtype('Frame','GuiObject') (reverse edge -> cycle)", function() q.Modifier.DefineSubtype("Frame", "GuiObject") end)
try("DefineSubtype('Frame','TextLabel') (new edge Frame->TextLabel allowed?)", function()
	q.Modifier.DefineSubtype("Frame", "TextLabel")
	local m = D.Modifier.Frame({ ZIndex = 1 }):AsTextLabel()
	print("  frame->textlabel now:", tostring(m))
end)

print("== D1 docs core/08 examples ==")
try("08 flatten example", function()
	local base = q.Modifier({ BackgroundTransparency = 1 })
	local accent = q.Modifier({ BackgroundTransparency = 0.5 })
	local box = D.Frame({ base, accent, Name = "Box" })
	print("  box BT", box.BackgroundTransparency, box.Name)
end)
try("08 constructor example", function()
	local card = q.Modifier({ BackgroundTransparency = 0.2, BorderSizePixel = 0 })
	local wide = q.Modifier(card, { Size = UDim2.fromScale(1, 0.4) })
	local panel = D.Frame({ wide })
	print("  panel", panel.BackgroundTransparency, panel.BorderSizePixel, panel.Size)
end)
try("08 setter example", function()
	local scale = q.Source(1)
	local base = D.Modifier.Frame({ BackgroundTransparency = 0.5, LayoutOrder = 1 })
	local dimmed = base:BackgroundTransparency(0.9)
	local live = base:LayoutOrder(scale)
	local cleared = base:BackgroundTransparency(q.None)
	local bumped = base:LayoutOrder(function(old) return old + 1 end)
	local doubled = live:LayoutOrder(function(old) return old:Get() * 2 end)
	print("  dimmed", dimmed:Peek("BackgroundTransparency"), "cleared None?", cleared:Peek("BackgroundTransparency") == q.None, "bumped", bumped:Peek("LayoutOrder"))
	local f = D.Frame({ doubled }); scale:Set(3); print("  doubled drive", f.LayoutOrder, "base BT", base:Peek("BackgroundTransparency"))
end)
try("08 Peek example", function()
	local size = q.Source(UDim2.fromOffset(100, 40))
	local mod = q.Modifier({ Size = size, Visible = true })
	print("  ", mod:Peek("Size") == size, mod:Peek("Visible"), mod:Peek("Text"))
end)
try("08 Apply example", function()
	local function rounded(mod) return mod:BorderSizePixel(0):BackgroundTransparency(0.1) end
	local styled = q.Modifier():Apply(rounded)
	print("  ", fields(styled))
end)
try("08 Overridden example", function()
	local theme = q.Modifier({ BackgroundTransparency = 0.2 })
	local danger = q.Modifier({ BackgroundTransparency = 0 })
	print("  ", q.Modifier.Overridden(theme, danger):Peek("BackgroundTransparency"), theme:Overridden(danger):Peek("BackgroundTransparency"))
end)
try("08 As<Class> example", function()
	local common = D.Modifier.GuiObject():Visible(true)
	local button = common:AsTextButton()
	print("  ", tostring(button))
end)

print("== D2 docs roblox/03 examples ==")
try("03 builder/table/card", function()
	local base = D.Modifier.GuiObject():Size(UDim2.fromOffset(160, 40)):BackgroundColor3(Color3.fromRGB(60, 130, 255)):Visible(true)
	local boxed = D.Modifier.Frame({ BackgroundTransparency = 0.5 }, { Visible = false })
	local card = D.Frame({ boxed, D.Modifier.Frame():ZIndex(2) })
	print("  card", card.BackgroundTransparency, card.Visible, card.ZIndex, tostring(base))
end)
try("03 bumped", function()
	local bumped = D.Modifier.Frame():ZIndex(2):ZIndex(function(old) if type(old) == "number" then return old + 1 end return 1 end)
	print("  ", bumped:Peek("ZIndex"))
end)
try("03 AsTextLabel/AsFrame", function()
	local base = D.Modifier.GuiObject():Visible(true)
	local label = base:AsTextLabel():Text("제목"):TextSize(20)
	local frame = base:AsFrame():Style(Enum.FrameStyle.Custom)
	print("  ", tostring(label), tostring(frame))
end)
try("03 As() forms", function()
	local forced = D.Modifier.GuiObject():As()
	local retagged = D.Modifier.TextLabel():As("Frame")
	print("  ", tostring(forced), tostring(retagged))
end)
try("03 Themed", function()
	local function Themed(props)
		return D.TextButton({ if props.Modifier then props.Modifier:AsTextButton() else q.None, Text = props.Text or "" })
	end
	local a = Themed({ Modifier = D.Modifier.GuiObject():ZIndex(2), Text = "a" })
	local b = Themed({ Modifier = D.Modifier.TextButton():TextSize(18) })
	local c = Themed({ Text = "c" })
	print("  ", a.ZIndex, a.Text, b.TextSize, c.Text)
end)
try("03 Boldify", function()
	local Boldify = function(mod) return mod:TextSize(20) end
	local bold = D.Modifier.TextButton():Text("go"):Apply(Boldify)
	print("  ", fields(bold))
end)

print("== D3 GS 10 ==")
try("GS10 §1-§4", function()
	local CardStyle = D.Modifier.Frame({ BackgroundColor3 = Color3.fromRGB(35, 35, 42), BorderSizePixel = 0 })
	local card = D.Frame({ CardStyle, Size = UDim2.fromOffset(240, 160), UICorner = 12 })
	print("  card", card.BackgroundColor3, card.BorderSizePixel, #card:GetChildren())
	local hot = q.Source(false)
	local CardStyle2 = D.Modifier.Frame({
		BackgroundColor3 = hot:Compute(function(h) return if h:Get() then Color3.fromRGB(240, 60, 60) else Color3.fromRGB(35, 35, 42) end),
		BorderSizePixel = 0,
	})
	local card2 = D.Frame({ CardStyle2, Size = UDim2.fromOffset(240, 160), UICorner = 12 })
	hot:Set(true)
	print("  card2", card2.BackgroundColor3)
	local base = D.Modifier.TextButton({ TextSize = 16 })
	local big = base:TextSize(24)
	print("  base/big", base:Peek("TextSize"), big:Peek("TextSize"))
	local function accent(color)
		return D.Modifier.TextButton({ BackgroundColor3 = color, TextColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0 })
	end
	local button = D.TextButton({ accent(Color3.fromRGB(0, 162, 255)), Text = "+ 1" })
	local accentColor = q.Source(Color3.fromRGB(0, 162, 255))
	local button2 = D.TextButton({ accent(accentColor), Text = "+ 1" })
	accentColor:Set(Color3.fromRGB(240, 60, 60))
	print("  button", button.BackgroundColor3, "button2", button2.BackgroundColor3)
	local okS, eS = pcall(function() q.Source(D.Modifier.Frame()) end)
	print("  Source(Modifier):", first(eS))
	local function emphasis(size) return function(mod) return mod:TextSize(size):TextColor3(Color3.fromRGB(255, 230, 120)) end end
	local title = D.Modifier.TextLabel({ BackgroundTransparency = 1 }):Apply(emphasis(24))
	local label = D.TextLabel({ title, Text = "카운터" })
	print("  label", label.TextSize, label.TextColor3, label.BackgroundTransparency)
end)

print("== D4 how-to 01 CustomButton / how-to 05 ThemedButton ==")
try("how-to 01", function()
	local function CustomButton(props)
		local baseStyle = D.Modifier.TextButton({ Size = UDim2.fromOffset(140, 40), BackgroundColor3 = Color3.fromRGB(0, 140, 240), TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 16 })
		return D.TextButton({ baseStyle, props.Modifier or q.None, props.Ref or q.None, Text = props.Text, MouseButton1Click = props.OnClick, UICorner = 8 })
	end
	local b1 = CustomButton({ Text = "확인", OnClick = function() end })
	local b2 = CustomButton({ Text = "삭제", OnClick = function() end, Modifier = D.Modifier.TextButton({ BackgroundColor3 = Color3.fromRGB(240, 60, 60), Size = UDim2.fromOffset(100, 36) }) })
	print("  b1", b1.BackgroundColor3, b1.Size, "b2", b2.BackgroundColor3, b2.Size, b2.TextColor3, b2.TextSize)
end)
try("how-to 05", function()
	local isDark = q.Source(true)
	local Tokens = { Accent = isDark:Compute(function(d) return if d:Get() then "dark-accent" else "light-accent" end) }
	local Styles = { Button = D.Modifier.TextButton():Size(UDim2.new(0, 120, 0, 40)):BackgroundColor3(Tokens.Accent):BorderSizePixel(0) }
	local function ThemedButton(props)
		local effective = if props.Modifier then q.Modifier.Overridden(Styles.Button, props.Modifier:AsTextButton()) else Styles.Button
		return D.TextButton({ effective, Text = props.Text or "", TextColor3 = Color3.fromRGB(255, 255, 255), FontFace = Font.fromEnum(Enum.Font.GothamBold), TextSize = 14, Activated = function() props.OnClick() end })
	end
	local t1 = ThemedButton({ Text = "a", OnClick = function() end })
	local t2 = ThemedButton({ Text = "b", OnClick = function() end, Modifier = D.Modifier.TextButton():Position(UDim2.new(0, 20, 1, -60)):Size(UDim2.new(0, 140, 0, 38)) })
	isDark:Set(false)
	print("  t1", t1.Size, t1.BackgroundColor3, "t2", t2.Size, t2.Position, t2.BackgroundColor3)
end)
print("done")
