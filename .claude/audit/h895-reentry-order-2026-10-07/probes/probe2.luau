--!nocheck
local E = require("./env")
local S, mock = E.S, E.mock
local MODES = { "imm", "def" }
local function run(title, fn)
	print(("="):rep(90)); print(title)
	for _, m in MODES do
		S.reset(m); S.childAdded = true
		local q = E.newProv()
		local lines = {}
		local function out(s) table.insert(lines, s) end
		local ok, err = pcall(fn, q, out, m)
		if not ok then out("THREW: " .. tostring(err):gsub("\n.*", "")) end
		if #S.errors > 0 then out("listener errors: " .. table.concat(S.errors, " | ")) end
		print(("  [%s] %s"):format(m, table.concat(lines, "\n         ")))
	end
end
local function corners(host)
	local o = {}
	for _, c in host:GetChildren() do
		if c.ClassName == "UICorner" then table.insert(o, tostring(c.CornerRadius and c.CornerRadius.Offset)) end
	end
	return #o, table.concat(o, ",")
end
run("(IS) UICorner = src (nil→8); host ChildAdded → src:Set(16)", function(q, out)
	local src = q.Source(nil); local armed = false
	local host = q.Declaration.Frame({ UICorner = src, ChildAdded = function(c) if armed then armed = false; src:Set(16) end end })
	S.flush(); armed = true
	src:Set(8); S.flush()
	local n, w = corners(host)
	out(("after: corners=%d [%s] src=%s"):format(n, w, tostring(src:Get())))
	src:Set(nil); S.flush()
	n, w = corners(host)
	out(("after src:Set(nil): corners=%d [%s]"):format(n, w))
	src:Set(4); S.flush()
	n, w = corners(host)
	out(("after src:Set(4): corners=%d [%s]"):format(n, w))
end)
local function names(host)
	local o = {}
	for _, c in host:GetChildren() do table.insert(o, c.Name) end
	return table.concat(o, ",")
end
run("(SL) Slot rawAdd: element OnChange('Parent') → slot:Add(other) (Parent write precedes setLength)", function(q, out)
	local D = q.Declaration
	local slot = q.Slot({ D.Frame({ Name = "a" }) })
	local host = D.Frame({ Name = "host", slot })
	S.flush()
	local armed = true
	local b = D.Frame({ Name = "b", q.OnChange("Parent", function(p) if armed and p ~= nil then armed = false; slot:Add(D.Frame({ Name = "c" })) end end) })
	S.flush()
	slot:Add(b); S.flush()
	out(("children=[%s] Length=%s"):format(names(host), tostring(slot.Length:Get())))
	slot:Add(D.Frame({ Name = "d" }), 1); S.flush()
	out(("after Add(d,1): children=[%s] Length=%s"):format(names(host), tostring(slot.Length:Get())))
	slot:Clear(); S.flush()
	out(("after Clear: children=[%s] Length=%s"):format(names(host), tostring(slot.Length:Get())))
end)
run("(SL2) offsets after nested Add from element's OnChange('Parent')", function(q, out)
	local D = q.Declaration
	local slot = q.Slot({ D.Frame({ Name = "a" }) })
	local host = D.Frame({ Name = "host", slot })
	S.flush()
	local armed = true
	local b = D.Frame({ Name = "b", q.OnChange("Parent", function(p) if armed and p ~= nil then armed = false; slot:Add(D.Frame({ Name = "c" })) end end) })
	S.flush()
	slot:Add(b); S.flush()
	local o = {}
	for i, e in slot._elements do table.insert(o, e.Name .. "@" .. tostring(q.Bookkeeping.getOffsetAt(slot, i))) end
	out(("elements=[%s] Length=%s"):format(table.concat(o, " "), tostring(slot.Length:Get())))
	slot:Add(D.Frame({ Name = "d" }), 1); S.flush()
	o = {}
	for i, e in slot._elements do table.insert(o, e.Name .. "@" .. tostring(q.Bookkeeping.getOffsetAt(slot, i))) end
	out(("after Add(d,1) elements=[%s] Length=%s"):format(table.concat(o, " "), tostring(slot.Length:Get())))
end)
run("(IC) host Frame{ cs }, cs:Set(B) where B has OnChange('Parent') → cs:Set(C)", function(q, out)
	local D = q.Declaration
	local A = D.Frame({ Name = "A" })
	local cs = q.Source(A)
	local host = D.Frame({ Name = "host", cs })
	S.flush()
	local C = D.Frame({ Name = "C" })
	local armed = false
	local B = D.Frame({ Name = "B", q.OnChange("Parent", function(p) if armed and p ~= nil then armed = false; cs:Set(C) end end) })
	S.flush(); armed = true
	cs:Set(B); S.flush()
	out(("children=[%s] cs=%s"):format(names(host), cs:Get().Name))
	cs:Set(nil); S.flush()
	out(("after cs:Set(nil): children=[%s]"):format(names(host)))
	local ok, err = pcall(function() q.dispose(C) end)
	out(("q.dispose(C): %s"):format(ok and "ok" or tostring(err):match("Quad%d+") or tostring(err):sub(1,80)))
end)
run("(SL3) materialize walk: unmounted slot{a, b(OnChange Parent → slot:Add(c))} then host Frame{slot}", function(q, out)
	local D = q.Declaration
	local slot
	local armed = true
	local b = D.Frame({ Name = "b", q.OnChange("Parent", function(p) if armed and p ~= nil then armed = false; slot:Add(D.Frame({ Name = "c" })) end end) })
	slot = q.Slot({ D.Frame({ Name = "a" }), b })
	local host = D.Frame({ Name = "host", slot })
	S.flush()
	local o = {}
	for i, e in slot._elements do table.insert(o, e.Name .. "@" .. tostring(q.Bookkeeping.getOffsetAt(slot, i))) end
	out(("elements=[%s] Length=%s children=[%s]"):format(table.concat(o, " "), tostring(slot.Length:Get()), names(host)))
end)
run("(SL4) Slot:Replace / nested slot element: b inside inner slot, OnChange Parent → outer:Add(c)", function(q, out)
	local D = q.Declaration
	local outer = q.Slot({ D.Frame({ Name = "a" }) })
	local host = D.Frame({ Name = "host", outer })
	S.flush()
	local armed = true
	local b = D.Frame({ Name = "b", q.OnChange("Parent", function(p) if armed and p ~= nil then armed = false; outer:Add(D.Frame({ Name = "c" }), 2) end end) })
	local inner = q.Slot({ b })
	outer:Add(inner); S.flush()
	local o = {}
	for i, e in outer._elements do table.insert(o, (e.Name or "slot") .. "@" .. tostring(q.Bookkeeping.getOffsetAt(outer, i))) end
	out(("outer=[%s] Length=%s children=[%s]"):format(table.concat(o, " "), tostring(outer.Length:Get()), names(host)))
end)
run("(SL5) unmount: host Frame{ ss }, ss = Source(slot{a,b}); b OnChange Parent nil → slot:Add(c); ss:Set(nil)", function(q, out)
	local D = q.Declaration
	local slot
	local armed = false
	local b = D.Frame({ Name = "b", q.OnChange("Parent", function(p) if armed and p == nil then armed = false; slot:Add(D.Frame({ Name = "c" })) end end) })
	slot = q.Slot({ D.Frame({ Name = "a" }), b })
	local ss = q.Source(slot)
	local host = D.Frame({ Name = "host", ss })
	S.flush(); armed = true
	ss:Set(nil); S.flush()
	local o = {}
	for i, e in slot._elements do table.insert(o, e.Name) end
	out(("slot elements=[%s] mounted=%s host children=[%s]"):format(table.concat(o, ","), tostring(slot._mounted), names(host)))
	local host2 = D.Frame({ Name = "host2", slot }); S.flush()
	out(("remount host2 children=[%s] host children=[%s] Length=%s"):format(names(host2), names(host), tostring(slot.Length:Get())))
end)
for _, op in { "Extract", "Remove" } do
run("(SL6-" .. op .. ") slot{a,b,d} mounted; b OnChange Parent nil → slot:Add(c, 1); slot:" .. op .. "(2)", function(q, out)
	local D = q.Declaration
	local slot
	local armed = false
	local b = D.Frame({ Name = "b", q.OnChange("Parent", function(p) if armed and p == nil then armed = false; slot:Add(D.Frame({ Name = "c" }), 1) end end) })
	slot = q.Slot({ D.Frame({ Name = "a" }), b, D.Frame({ Name = "d" }) })
	local host = D.Frame({ Name = "host", slot })
	S.flush(); armed = true
	local ok, err = pcall(function() slot[op](slot, 2) end)
	if not ok then out("op threw: " .. tostring(err):sub(1, 120)) end
	S.flush()
	local o = {}
	for i, e in slot._elements do table.insert(o, e.Name .. "@" .. tostring(q.Bookkeeping.getOffsetAt(slot, i))) end
	out(("elements=[%s] Length=%s children=[%s] IndexOf(b)=%s"):format(table.concat(o, " "), tostring(slot.Length:Get()), names(host), tostring(slot:IndexOf(b))))
end)
end
local function dump(q, slot)
	local o = {}
	for i, e in slot._elements do table.insert(o, (if q.isSlot and q.isSlot(e) then "slot" else tostring(e.Name)) .. "@" .. tostring(q.Bookkeeping.getOffsetAt(slot, i))) end
	return table.concat(o, " ")
end
run("(SL7) Replace(2, e): old b OnChange Parent nil → slot:Add(c, 1)", function(q, out)
	local D = q.Declaration
	local slot
	local armed = false
	local b = D.Frame({ Name = "b", q.OnChange("Parent", function(p) if armed and p == nil then armed = false; slot:Add(D.Frame({ Name = "c" }), 1) end end) })
	slot = q.Slot({ D.Frame({ Name = "a" }), b, D.Frame({ Name = "d" }) })
	local host = D.Frame({ Name = "host", slot })
	S.flush(); armed = true
	slot:Replace(2, D.Frame({ Name = "e" })); S.flush()
	out(("elements=[%s] Length=%s children=[%s]"):format(dump(q, slot), tostring(slot.Length:Get()), names(host)))
	slot:Add(D.Frame({ Name = "z" })); S.flush()
	out(("after Add(z): elements=[%s] Length=%s"):format(dump(q, slot), tostring(slot.Length:Get())))
end)
run("(SL8) Splice(2,0, inner{x}) where x OnChange Parent → inner:Add(y)", function(q, out)
	local D = q.Declaration
	local inner
	local armed = true
	local x = D.Frame({ Name = "x", q.OnChange("Parent", function(p) if armed and p ~= nil then armed = false; inner:Add(D.Frame({ Name = "y" })) end end) })
	inner = q.Slot({ x })
	local slot = q.Slot({ D.Frame({ Name = "a" }) })
	local host = D.Frame({ Name = "host", slot })
	S.flush()
	local ok, err = pcall(function() slot:Splice(2, 0, inner) end)
	if not ok then out("threw: " .. tostring(err):sub(1, 100)) end
	S.flush()
	out(("inner Length=%s outer Length=%s children=[%s]"):format(tostring(inner.Length:Get()), tostring(slot.Length:Get()), names(host)))
end)
