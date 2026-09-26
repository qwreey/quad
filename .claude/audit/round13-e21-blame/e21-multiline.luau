--!nocheck
-- round13 E21 — two-line variants: the value is PRODUCED on line P (inside updateFn/Compute/State) and the
-- mount/Set that makes quad look at it is on line T. Verdict: P (producer line), T (trigger line), LEAF.
local H = require("../round13-e15-probe-setup")
local q, D, mock = H.q, H.D, H.mock
local M = D.Mapper
local THIS = "round13-e21-blame/e21-multiline.luau"
local function L() return debug.info(2, "l") end
local function F() return D.Frame {} end
local function nop() end
local function foreign(c) return mock.Instance.foreign(c or "Frame") end
local P, T = 0, 0
local function check(id, label, fn)
	P, T = 0, 0
	local ok, err = pcall(fn)
	local s = tostring(err)
	local file, line = string.match(s, "^([^\n]-):(%d+): ")
	local got = string.match(s, "Quad%d%d%d%d") or "-"
	local v
	if ok then v = "NO-RAISE"
	elseif not file then v = "NOPREFIX"
	elseif string.find(file, THIS, 1, true) then
		local ln = tonumber(line)
		v = if ln == P then "PRODUCER" elseif ln == T then "TRIGGER" else ("USER-OTHER:" .. line)
	else v = "LEAF:" .. (string.match(file, "src/(.*)$") or file) .. ":" .. line end
	print(table.concat({ "M", id, label, v, got, string.format("P=%d T=%d", P, T), (string.gsub(string.gsub(s, "\n", " "), "|", "¦")) }, "|"))
end

check("Quad0238", "List updateFn returns Ref, mount", function()
	local sl = q.Slot()
	sl:List({ 1 }, function() P = L(); return q.Ref() end)
	T = L(); D.Frame { sl }
end)
check("Quad0238", "List updateFn returns Ref, data:Set", function()
	local d = q.Source({})
	local sl = q.Slot()
	sl:List(d, function() P = L(); return q.Ref() end)
	D.Frame { sl }
	T = L(); d:Set({ 1 })
end)
check("Quad0240", "List updateFn returns 5, mount", function()
	local sl = q.Slot()
	sl:List({ 1 }, function() P = L(); return 5 end)
	T = L(); D.Frame { sl }
end)
check("Quad0241", "List updateFn returns foreign, mount", function()
	local sl = q.Slot()
	sl:List({ 1 }, function() P = L(); return foreign() end)
	T = L(); D.Frame { sl }
end)
check("Quad0242", "List updateFn returns disposed Slot, mount", function()
	local dd = q.Slot(); q.dispose(dd)
	local sl = q.Slot()
	sl:List({ 1 }, function() P = L(); return dd end)
	T = L(); D.Frame { sl }
end)
check("Quad0156", "List updateFn returns mounted element, mount", function()
	local c = F(); D.Frame { c }
	local sl = q.Slot()
	sl:List({ 1 }, function() P = L(); return c end)
	T = L(); D.Frame { sl }
end)
check("Quad0240", "Single State →5, Set", function()
	local st = q.Source(nil)
	local sl = q.Slot()
	sl:Single(st)
	D.Frame { sl }
	T = L(); st:Set(5)
end)
check("Quad0240", "Slot State element →5, Set", function()
	local st = q.Source(F())
	local sl = q.Slot({ st })
	D.Frame { sl }
	T = L(); st:Set(5)
end)
check("Quad0219", "static State child →foreign, Set", function()
	local st = q.Source(F())
	D.Frame { st }
	T = L(); st:Set(foreign())
end)
check("Quad0022", "getOffsetAt far inside updateFn, mount", function()
	local sl = q.Slot()
	sl:List({ 1 }, function() P = L(); q.Bookkeeping.getOffsetAt(F(), 9); return F() end)
	T = L(); D.Frame { sl }
end)
check("Quad0033", "Claim(5) inside updateFn, mount", function()
	local sl = q.Slot()
	sl:List({ 1 }, function() P = L(); q.Claim(5, M.Frame(M.Root)({})); return F() end)
	T = L(); D.Frame { sl }
end)
check("Quad0199", "Tag('') inside updateFn, mount", function()
	local sl = q.Slot()
	sl:List({ 1 }, function() P = L(); q.Tag(""); return F() end)
	T = L(); D.Frame { sl }
end)
check("Quad0199", "Tag('') in Compute, mount", function()
	local s = q.Source(0)
	local c = s:Compute(function() P = L(); return q.Tag("") end)
	T = L(); D.Frame { c }
end)
check("Quad0243", "Tween in Compute, mount", function()
	local s = q.Source(0)
	local c = s:Compute(function(h) P = L(); return q.Tween({ Value = h:Get(), Time = "x" }) end)
	T = L(); D.Frame { BackgroundTransparency = c }
end)
check("Quad0167", "ancestor CRUD in nested updateFn, mount", function()
	local outer = q.Slot(); local inner = q.Slot()
	inner:List({ 1 }, function() P = L(); outer:Add(F()); return F() end)
	outer:Add(inner)
	T = L(); D.Frame { outer }
end)
check("Quad0144", "keyFn nil (keyFn on its own line)", function()
	local sl = q.Slot()
	sl:List({ 1 }, F, function() P = L(); return nil end)
	T = L(); D.Frame { sl }
end)
check("Quad0147", "KeyGone returns element, data:Set", function()
	local d = q.Source({ 1 })
	local sl = q.Slot()
	sl:List(d, function(ctx) if ctx.Item == q.KeyGone then P = L(); return F() end return F() end)
	D.Frame { sl }
	T = L(); d:Set({})
end)
check("Quad0086", "Effect returns 5, mount", function()
	local e = q.Effect(function() P = L(); return 5 end)
	T = L(); D.Frame { e }
end)
check("Quad0120", "Operator nil arg via mount", function()
	local src = q.Source(1):Apply(q.Operator.Sum(q.Source(nil)))
	T = L(); D.Frame { BackgroundTransparency = src }
end)
check("Quad0184", "cycle, mount (Get inside fn)", function()
	local a
	a = q.Source(1):Compute(function() P = L(); return a:Get() end)
	T = L(); D.Frame { BackgroundTransparency = a }
end)
check("Quad0184", "throw then same-gen mount (Q88)", function()
	local c = q.Source(1):Compute(function() error("boom") end)
	pcall(function() c:Get() end)
	T = L(); D.Frame { BackgroundTransparency = c }
end)
check("Quad0184", "throw then same-gen Animate read (Q88)", function()
	local c = q.Source(1):Compute(function() error("boom") end)
	pcall(function() c:Get() end)
	T = L(); D.Frame { BackgroundTransparency = c:Apply(q.Animate({ Time = 1 })) }
end)
check("Quad0184", "throw then same-gen Operator read (Q88)", function()
	local c = q.Source(1):Compute(function() error("boom") end)
	pcall(function() c:Get() end)
	T = L(); q.Source(1):Apply(q.Operator.Sum(c)):Get()
end)
check("Quad0184", "throw then same-gen List data read (Q88)", function()
	local c = q.Source(1):Compute(function(h) if h:Get() == 1 then error("boom") end return {} end)
	pcall(function() c:Get() end)
	local sl = q.Slot(); sl:List(c, F)
	T = L(); D.Frame { sl }
end)
check("Quad0184", "throw then same-gen Tag State read", function()
	local c = q.Source(1):Compute(function(h) if h:Get() == 1 then error("boom") end return q.Tag("a") end)
	pcall(function() c:Get() end)
	T = L(); D.Frame { c }
end)
check("Quad0184", "throw then same-gen Debounce Time read", function()
	local t = q.Source(1):Compute(function(h) if h:Get() == 1 then error("boom") end return 0.1 end)
	local s = q.Source(1)
	local g = s:Apply(q.Debounce({ Time = t }))
	D.Frame { BackgroundTransparency = g }
	pcall(function() t:Get() end)
	T = L(); s:Set(2)
end)
check("Quad0184", "throw then same-gen setLength State read", function()
	local n = q.Source(1):Compute(function(h) if h:Get() == 1 then error("boom") end return 0 end)
	pcall(function() n:Get() end)
	local f = F(); q.Bookkeeping.setOffsetSource(f, 1, q.None)
	T = L(); q.Bookkeeping.setLength(f, 1, n)
end)
check("Quad0184", "throw then same-gen Attr State read", function()
	local c = q.Source(1):Compute(function(h) if h:Get() == 1 then error("boom") end return "x" end)
	pcall(function() c:Get() end)
	T = L(); D.Frame { q.Attr({ a = c }) }
end)
check("Quad0184", "throw then same-gen Out src? / OnChange", function()
	local c = q.Source(1):Compute(function(h) if h:Get() == 1 then error("boom") end return "x" end)
	pcall(function() c:Get() end)
	T = L(); D.TextLabel { Text = c }
end)
check("Quad0184", "throw then same-gen Effect dep read", function()
	local c = q.Source(1):Compute(function(h) if h:Get() == 1 then error("boom") end return 1 end)
	pcall(function() c:Get() end)
	T = L(); D.Frame { q.Effect(nop, c) }
end)
check("Quad0184", "throw then same-gen Slot Single read", function()
	local c = q.Source(1):Compute(function(h) if h:Get() == 1 then error("boom") end return nil end)
	pcall(function() c:Get() end)
	local sl = q.Slot(); sl:Single(c)
	T = L(); D.Frame { sl }
end)
check("Quad0184", "throw then same-gen State child read", function()
	local c = q.Source(1):Compute(function(h) if h:Get() == 1 then error("boom") end return nil end)
	pcall(function() c:Get() end)
	T = L(); D.Frame { c }
end)
check("Quad0184", "throw then same-gen Gate upstream read", function()
	local c = q.Source(1):Compute(function(h) if h:Get() == 1 then error("boom") end return 1 end)
	pcall(function() c:Get() end)
	T = L(); c:Gate(function(emit) return function() emit() end end):Get()
end)

local function thrown(v) local c = q.Source(1):Compute(function(h) if h:Get() == 1 then error("boom") end return v end); pcall(function() c:Get() end); return c end
check("Quad0184", "same-gen: Animate option State (Time)", function()
	local c = thrown(0.1)
	local s = q.Source(0)
	D.Frame { BackgroundTransparency = s:Apply(q.Animate({ Time = c })) }
	T = L(); s:Set(1)
end)
check("Quad0184", "same-gen: Operator Apply target", function()
	local c = thrown(1)
	T = L(); c:Apply(q.Operator.Sum(1)):Get()
end)
check("Quad0184", "same-gen: Operator Clamp bound", function()
	local c = thrown(1)
	T = L(); q.Source(1):Apply(q.Operator.Clamp(0, c)):Get()
end)
check("Quad0184", "same-gen: Operator Alternative default", function()
	local c = thrown(1)
	T = L(); q.Source(nil):Apply(q.Operator.Alternative(c)):Get()
end)
check("Quad0184", "same-gen: Operator Indexed target", function()
	local c = thrown({ a = 1 })
	T = L(); c:Apply(q.Operator.Indexed("a")):Get()
end)
check("Quad0184", "same-gen: Operator Not target", function()
	local c = thrown(true)
	T = L(); c:Apply(q.Operator.Not):Get()
end)
check("Quad0184", "same-gen: Depend upstream then Get", function()
	local c = thrown(1)
	T = L(); q.Source(1):Depend(c):Get()
end)
check("Quad0184", "same-gen: Compute with trailing dep then Get", function()
	local c = thrown(1)
	T = L(); q.Source(1):Compute(function(h) return h:Get() end, c):Get()
end)
check("Quad0184", "same-gen: List install on mounted Slot", function()
	local c = thrown({})
	local sl = q.Slot(); D.Frame { sl }
	T = L(); sl:List(c, F)
end)
check("Quad0184", "same-gen: Slot State element mount", function()
	local c = thrown(nil)
	local sl = q.Slot({ c })
	T = L(); D.Frame { sl }
end)
check("Quad0184", "same-gen: Slot:Add(State) on mounted Slot", function()
	local c = thrown(nil)
	local sl = q.Slot(); D.Frame { sl }
	T = L(); sl:Add(c)
end)
check("Quad0184", "same-gen: Debounce MaxTime read", function()
	local m = thrown(1)
	local s = q.Source(1)
	D.Frame { BackgroundTransparency = s:Apply(q.Debounce({ Time = 0.1, MaxTime = m })) }
	T = L(); s:Set(2)
end)
check("Quad0184", "same-gen: Tween Mapped? Out src", function()
	local c = thrown("x")
	T = L(); D.TextBox { q.Out("Text", q.Source("a")), Text = c }
end)
check("Quad0184", "same-gen: Event handler State", function()
	local c = thrown(nop)
	T = L(); D.TextButton { Activated = c }
end)
check("Quad0184", "same-gen: Attr group State<Attr>", function()
	local c = thrown(q.Attr({ a = 1 }))
	T = L(); D.Frame { c }
end)
check("Quad0184", "same-gen: AttrKey value State", function()
	local c = thrown(1)
	T = L(); D.Frame { [q.AttrKey("k")] = c }
end)
check("Quad0184", "same-gen: Context? Store Of", function()
	local c = thrown(1)
	T = L(); q.Store({ a = q.Source(1) }).a:Set(c)
end)
check("Quad0184", "same-gen: Observer on thrown (subscribe runs fn)", function()
	local c = thrown(1)
	T = L(); c:Observer(nop):Subscribe()
end)
check("Quad0184", "same-gen: Blocker gate Apply read", function()
	local c = thrown(1)
	T = L(); c:Apply(q.Blocker()):Get()
end)
check("Quad0184", "same-gen: Debounce Apply read", function()
	local c = thrown(1)
	T = L(); c:Apply(q.Debounce({ Time = 1 })):Get()
end)
print("DONE2")
