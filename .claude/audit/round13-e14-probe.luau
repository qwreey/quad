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

print("== A1 nested / composition ==")
try("Modifier(Modifier{...})", function() print(" ", fields(q.Modifier(q.Modifier({ Size = 1 }), { Visible = true }))) end)
try("Modifier({ Modifier{} }) numeric key", function() q.Modifier({ q.Modifier({ Size = 1 }) }) end)
try("Modifier{ X = Modifier{} }", function() q.Modifier({ X = q.Modifier({ Size = 1 }) }) end)
try("setter literal Modifier", function() q.Modifier():X(q.Modifier()) end)
try("Overridden(untyped, typed)", function() local r = q.Modifier.Overridden(q.Modifier({ Size = 1 }), D.Modifier.Frame({ Size = 2 })); print("  tag", r.__quadModifier, fields(r)) end)

print("== A2 constructor table vs setter vs transform ==")
do
	local seen
	local m = q.Modifier({ LayoutOrder = 1 }):LayoutOrder(function(old) seen = old; return old + 1 end)
	print("  transform saw", seen, "->", fields(m))
	local m2 = q.Modifier({ LayoutOrder = q.None }):LayoutOrder(function(old) seen = old; return 5 end)
	print("  transform on None saw", seen == q.None and "None" or tostring(seen), "->", fields(m2))
end

print("== A3 transform return kinds (plain old) ==")
local kinds = {
	{ "State", function() return q.Source(1) end },
	{ "Slot", function() return q.Slot() end },
	{ "Ref", function() return q.Ref() end },
	{ "Tag", function() return q.Tag("a") end },
	{ "Attr", function() return q.Attr({ A = 1 }) end },
	{ "AttrKey", function() return q.AttrKey("A") end },
	{ "Modifier", function() return q.Modifier() end },
	{ "MapperDesc", function() return D.Mapper.Frame(D.Mapper.Root)({}) end },
	{ "OnChange", function() return q.OnChange("Size", function() end) end },
	{ "Out", function() return q.Out("Size", q.Source(1)) end },
	{ "Blocker", function() return q.Blocker() end },
	{ "Tween", function() return q.Tween({ Value = 1, Time = 1 }) end },
	{ "None", function() return q.None end },
	{ "function", function() return function() end end },
}
for _, k in kinds do
	local name, mk = k[1], k[2]
	local okMake, v = pcall(mk)
	if not okMake then print("  (make " .. name .. " failed: " .. first(v) .. ")") continue end
	local ok, res = pcall(function() return q.Modifier():Foo(function() return v end) end)
	local ok2 = pcall(function() return q.Modifier():Foo(v) end)
	local ok3, e3 = pcall(function() return q.Modifier({ Foo = v }) end)
	print(("  %-10s transform:%s literal:%s ctor:%s"):format(name, ok and "stored" or ("ERR " .. first(res):sub(1, 60)), ok2 and "stored" or "ERR", ok3 and "stored" or ("ERR " .. first(e3):sub(1, 40))))
end

print("== A4 those values at a Modifier field, driven onto a Frame (key Size) ==")
for _, k in kinds do
	local name, mk = k[1], k[2]
	local okMake, v = pcall(mk)
	if not okMake then continue end
	local okM, mod = pcall(function() return q.Modifier():Size(v) end)
	if not okM then continue end
	local okD, e = pcall(function() return D.Frame({ mod }) end)
	local okI, e2 = pcall(function() return D.Frame({ Size = v }) end)
	print(("  %-10s via Modifier:%s | inline:%s"):format(name, okD and "OK" or ("ERR " .. first(e):sub(1, 90)), okI and "OK" or ("ERR " .. first(e2):sub(1, 60))))
end

print("== A5 Tag / Attr through a Modifier field (non-property key) ==")
try("Modifier{ Tags = Tag('x') } on Frame", function()
	local f = D.Frame({ q.Modifier():Tags(q.Tag("x")) })
	print("  tags:", table.concat(mock.getTags(f), ","))
end)
try("Modifier Attrs = Attr{A=1}", function()
	local f = D.Frame({ q.Modifier():Attrs(q.Attr({ A = 1 })) })
	print("  attr A:", mock.getAttributes(f).A)
end)
try("inline Tags = Tag('x')", function()
	local f = D.Frame({ Tags = q.Tag("x") })
	print("  tags:", table.concat(mock.getTags(f), ","))
end)

print("== A6 setter names colliding ==")
local calls = 0
try("mod:Activated(fn) (transform runs now?)", function()
	local m = q.Modifier():Activated(function() calls += 1 end)
	print("  calls at construction:", calls, "fields:", fields(m))
	local b = D.TextButton({ m })
	b.Activated:Fire()
	print("  calls after fire:", calls)
end)
try("mod:Parent(inst) construct", function() return q.Modifier():Parent(mock.Instance.new("Frame")) end)
try("mod:Parent(inst) drive", function() D.Frame({ q.Modifier():Parent(mock.Instance.new("Frame")) }) end)
try("Modifier{Parent=inst} construct", function() return q.Modifier({ Parent = mock.Instance.new("Frame") }) end)
try("mod:Get() silent?", function() local m = q.Modifier({ Size = 1 }); local r = m:Get(); print("  Get returned", r, fields(r)) end)
try("mod:Compute(fn) silent?", function() local n = 0; local m = q.Modifier({ Size = 1 }):Compute(function(x) n += 1; return x end); print("  fn ran", n, fields(m)) end)
try("mod:Destroy()", function() local r = q.Modifier({ Size = 1 }):Destroy(); print("  ->", tostring(r)) end)
try("mod:IsA('Frame') then drive", function() D.Frame({ q.Modifier():IsA("Frame") }) end)
try("mod.__apply", function() print("  ", q.Modifier().__apply) end)
try("mod:__foo(1)", function() q.Modifier():__foo(1) end)
try("Modifier{ UICorner = 4 } shorthand", function() local f = D.Frame({ q.Modifier({ UICorner = 4 }) }); print("  children", #f:GetChildren()) end)
try("Modifier{ Name = 'x' }", function() local f = D.Frame({ q.Modifier({ Name = "N" }) }); print("  name", f.Name) end)

print("== B1 __apply / Apply with sugar ==")
try("mod:Apply(q.Animate{Time=1})", function() local r = q.Modifier({ Size = 1 }):Apply(q.Animate({ Time = 1 })); print("  ->", tostring(r), q.isState(r)) end)
try("mod:Apply(q.Blocker())", function() q.Modifier():Apply(q.Blocker()) end)
try("state:Apply(mod)", function() q.Source(1):Apply(q.Modifier()) end)
try("mod:Apply(q.Operator.Not)", function() local r = q.Modifier():Apply(q.Operator.Not); print("  ->", tostring(r)) end)
try("Modifier field = src:Apply(Animate)", function()
	mock.resetTweenLog()
	local s = q.Source(UDim2 and 1 or 1)
	local m = q.Modifier():BackgroundTransparency(s:Apply(q.Animate({ Time = 0.3 })))
	local f = D.Frame({ m })
	s:Set(0.5)
	print("  tweens", #mock.tweenLog, "BT", f.BackgroundTransparency)
end)
try("Modifier Size = Out(...)", function() local src = q.Source(1); D.Frame({ q.Modifier({ Size = q.Out("Size", src) }) }) end)
try("Modifier Foo = OnChange(...)", function() D.Frame({ q.Modifier({ Foo = q.OnChange("Size", function() end) }) }) end)

print("== B2 field State switching kinds ==")
do
	local s = q.Source(0.2)
	local f = D.Frame({ q.Modifier({ BackgroundTransparency = s }) })
	for _, step in {
		{ "nil", nil }, { "None", q.None }, { "0.4", 0.4 }, { "Tween", q.Tween({ Value = 0.9, Time = 1 }) }, { "0.1", 0.1 },
		{ "string", "x" }, { "Modifier", q.Modifier() }, { "Tag", q.Tag("t") }, { "function", function() end }, { "0.3", 0.3 },
	} do
		local ok, e = pcall(function() s:Set(step[2]) end)
		print(("  Set %-8s %s BT=%s"):format(step[1], ok and "ok " or ("ERR " .. first(e):sub(1, 70)), tostring(f.BackgroundTransparency)))
	end
	print("  tags on f:", table.concat(mock.getTags(f), ","))
end

print("== B3 reuse after Destroy / shared Compute via setter transform ==")
do
	local s = q.Source(1)
	local base = q.Modifier({ LayoutOrder = s })
	local derived = base:LayoutOrder(function(old) return old:Get() * 10 end)
	local a = D.Frame({ derived })
	s:Set(2)
	print("  a", a.LayoutOrder)
	a:Destroy()
	local b = D.Frame({ derived })
	s:Set(3)
	print("  b", b.LayoutOrder, "a(destroyed)", a.LayoutOrder)
	local c = D.Frame({ derived })
	s:Set(4)
	print("  b", b.LayoutOrder, "c", c.LayoutOrder)
	q.dispose(b)
	s:Set(5)
	print("  after dispose(b): c", c.LayoutOrder, "b", b.LayoutOrder)
end

print("== B4 props table reuse after flatten (in-place mutation) ==")
do
	local m1 = q.Modifier({ BackgroundTransparency = 0.1 })
	local m2 = q.Modifier({ BackgroundTransparency = 0.9 })
	local t = { m1, Name = "P" }
	local f1 = D.Frame(t)
	t[1] = m2
	local f2 = D.Frame(t)
	print("  f1", f1.BackgroundTransparency, "f2 (m2 wanted 0.9)", f2.BackgroundTransparency)
end

print("== B5 component boundary: one Modifier to two children ==")
do
	local s = q.Source(1)
	local mod = D.Modifier.Frame({ ZIndex = s })
	local function Comp(props)
		return D.Frame({ D.Frame({ props.Modifier or q.None, Name = "A" }), D.Frame({ props.Modifier or q.None, Name = "B" }) })
	end
	local root = Comp({ Modifier = mod })
	s:Set(7)
	local k = root:GetChildren()
	print("  children", #k, k[1].ZIndex, k[2].ZIndex)
	local r2 = Comp({})
	print("  without modifier children", #r2:GetChildren())
end

print("== B6 typed factory constructor merges foreign-class Modifier ==")
try("D.Modifier.Frame(D.Modifier.TextLabel{Text='x'})", function()
	local m = D.Modifier.Frame(D.Modifier.TextLabel({ Text = "x" }))
	print("  tag", m.__quadModifier, fields(m))
	D.Frame({ m })
end)
try("D.Modifier.GuiObject(D.Modifier.Frame{Style=...}) onto TextLabel", function()
	local m = D.Modifier.GuiObject(D.Modifier.Frame({ Style = "Custom" }))
	print("  tag", m.__quadModifier)
	D.TextLabel({ m })
end)
try("frameMod:AsTextLabel() (checked, sibling)", function() D.Modifier.Frame():AsTextLabel() end)
try("Overridden(frameMod, labelMod) onto Frame", function() D.Frame({ q.Modifier.Overridden(D.Modifier.Frame({ ZIndex = 1 }), D.Modifier.TextLabel({ Text = "x" })) }) end)

print("== B7 flatten with None / false inline ==")
do
	local f = D.Frame({ q.Modifier({ Visible = true }), Visible = false })
	print("  inline false wins:", f.Visible)
	local g = D.Frame({ q.None, q.Modifier({ ZIndex = 3 }) })
	print("  None at [1] then mod:", g.ZIndex)
end
print("done")
