--!nocheck
local H = require("./harness")
local q, D, None = H.q, H.D, H.None
local mock = require("../../../quad-base/test/mock")
local function try(label, f)
	local ok, r = pcall(f)
	print(label, ok and "ok" or "ERR", ok and tostring(r) or H.first(r))
end
-- (a) GC: modifier with State field kept alive, instance destroyed → collectable?
do
	local s = q.Source(1)
	local m = q.Modifier{ ZIndex = s }
	local weak = setmetatable({}, { __mode = "v" })
	do local f = D.Frame{ m }; weak[1] = f; f:Destroy() end
	for _ = 1, 5 do collectgarbage("collect") end
	print("A1 destroyed inst collected while Modifier+Source alive:", weak[1] == nil)
	local weak2 = setmetatable({}, { __mode = "v" })
	do local f = D.Frame{ m }; weak2[1] = f end -- not destroyed, dropped
	for _ = 1, 5 do collectgarbage("collect") end
	print("A2 undestroyed dropped inst collected:", weak2[1] == nil)
	local weakm = setmetatable({}, { __mode = "v" })
	do local m2 = q.Modifier{ ZIndex = s }:ZIndex(function(o) return o:Get() + 1 end); weakm[1] = m2; local f = D.Frame{ m2 }; f:Destroy() end
	for _ = 1, 5 do collectgarbage("collect") end
	print("A3 derived-field modifier collected after inst destroyed:", weakm[1] == nil)
end
-- (b) transform throw: plain → original untouched
do
	local base = q.Modifier{ ZIndex = 1 }
	local ok = pcall(function() return base:ZIndex(function() error("x") end) end)
	print("B1 plain throw at setter:", not ok, "base still", base:Peek("ZIndex"))
	local s = q.Source(1)
	local ok2, m = pcall(function() return q.Modifier{ ZIndex = s }:ZIndex(function() error("lazy") end) end)
	print("B2 State throw at setter?", not ok2, "(false = lazy, deferred to mount)")
	try("B2 mount", function() return D.Frame{ m }.ZIndex end)
	try("B3 transform returns Ref on State field (roblox/03:146 says throws at setter)", function()
		local m3 = q.Modifier{ ZIndex = s }:ZIndex(function() return q.Ref() end)
		local f = D.Frame{ m3 }
		return "setter+mount ok, ZIndex holds " .. tostring(f.ZIndex)
	end)
	try("B4 transform returns Observer on State field", function()
		local m3 = q.Modifier{ ZIndex = s }:ZIndex(function(o) return q.Observer(o) end)
		local f = D.Frame{ m3 }
		return "ok, ZIndex holds " .. tostring(f.ZIndex)
	end)
	try("B5 transform returns Modifier on State field", function()
		local m3 = q.Modifier{ ZIndex = s }:ZIndex(function() return q.Modifier() end)
		return "setter ok; mount: " .. tostring(select(2, pcall(function() return D.Frame{ m3 } end)))
	end)
	try("B6 transform returns Ref on plain field", function() return q.Modifier{ ZIndex = 1 }:ZIndex(function() return q.Ref() end) end)
end
-- (c) no Merged on Modifier; overlap never errors
try("C1 q.Modifier.Merged", function() return tostring(rawget(q.Modifier, "Merged")) end)
try("C2 overlap same value via ctor", function() return tostring(q.Modifier({ ZIndex = 1 }, { ZIndex = 1 })) end)
try("C3 overlap None/nil via Overridden", function() return tostring(q.Modifier{ ZIndex = None }:Overridden(q.Modifier{ ZIndex = None })) end)
try("C4 mod:Merged(x) becomes a FIELD setter", function() local m = q.Modifier():Merged(q.Modifier()) end)
try("C5 mod:Merged(1) field then mount", function() return D.Frame{ q.Modifier():Merged(1) } end)
-- (d) chain setter takes State (E31 GAP-3)
do
	local s = q.Source(3); local f = D.Frame{ D.Modifier.Frame():ZIndex(s) }; s:Set(4)
	print("D1 chain setter State reactive:", f.ZIndex == 4)
end
-- (e) numeric keys / value objects in fields
try("E1 table numeric key", function() return q.Modifier{ [1] = 1 } end)
try("E2 setter numeric key", function() local m = q.Modifier(); return m[1](m, 1) end)
try("E3 Tag as field value (no gate)", function() return tostring(q.Modifier{ Foo = q.Tag("a") }) end)
try("E4 Attr as field value (no gate)", function() return tostring(q.Modifier():Foo(q.Attr{ a = 1 })) end)
try("E5 Tag field mount", function() return D.Frame{ q.Modifier{ Name = q.Tag("a") } }.Name end)
try("E6 Tween as ctor-table value", function() return tostring(q.Modifier{ ZIndex = q.Tween{ Value = 2 } }) end)
-- two modifiers in array + Tag at numeric key of the props (not the modifier) — ordering preserved
do
	local f = D.Frame{ q.Modifier{ ZIndex = 1 }, q.Tag("t1"), q.Modifier{ ZIndex = 2 }, q.Tag("t2") }
	print("E7 array mix: ZIndex", f.ZIndex, "tags", table.concat(H.CollectionService:GetTags(f), ","))
end
-- (f) tostring/brand
for _, m in { q.Modifier{ ZIndex = 1 }, D.Modifier.Frame{ ZIndex = 1 }, D.Modifier.Frame():ZIndex(1), D.Modifier.Frame{ ZIndex = 1 }:Overridden(D.Modifier.TextButton{}), q.Modifier.Overridden(D.Modifier.Frame()), D.Modifier.GuiObject():AsFrame(), D.Modifier.TextButton():As("Frame"), D.Modifier.TextButton():As() } do
	print("F", tostring(m), q.isModifier(m), m.__quadModifier, table.isfrozen(m))
end
-- typed ctor retags a sibling-class modifier without ancestry check
try("G1 D.Modifier.Frame(TextButtonModifier) → tag", function() return D.Modifier.Frame(D.Modifier.TextButton{ TextSize = 3 }).__quadModifier end)
try("G2 D.Modifier.TextButton(FrameModifier):AsTextButton", function() return tostring(D.Modifier.TextButton(D.Modifier.Frame{})) end)
try("G3 checked AsTextButton on Frame tag", function() return D.Modifier.Frame{}:AsTextButton() end)
-- event setter transform fires handler at setter time
do
	local n = 0
	local m = q.Modifier():Activated(function() n += 1 end)
	print("H1 event-name setter calls fn at setter time:", n, "field", m:Peek("Activated"))
end
-- Alternative as a transform
try("I1 Alternative on plain field", function() return q.Modifier{ ZIndex = 1 }:ZIndex(q.Operator.Alternative(5)) end)
do
	local sn = q.Source(nil)
	local m = q.Modifier{ ZIndex = sn }:ZIndex(q.Operator.Alternative(5))
	local st = m:Peek("ZIndex")
	print("I2 Alternative on State field: Peek:Get() is", tostring(st:Get()), "(State-of-State)")
	local f = D.Frame{ m }; local a = f.ZIndex; sn:Set(7); print("I2 mount", a, "->", f.ZIndex)
end
