--!nocheck
local E = require("./env")
local S, mock = E.S, E.mock
local function run(title, fn)
	print(("="):rep(90)); print(title)
	for _, m in { "imm", "def" } do
		S.reset(m); S.childAdded = true
		local q = E.newProv()
		local lines = {}
		local function out(s) table.insert(lines, s) end
		local ok, err = pcall(fn, q, out, m)
		if not ok then out("THREW: " .. tostring(err):gsub("\n.*", ""):sub(1, 110)) end
		if #S.errors > 0 then out("listener errors: " .. table.concat(S.errors, " | "):sub(1, 110)) end
		print(("  [%s] %s"):format(m, table.concat(lines, "\n         ")))
	end
end
local function names(host) local o = {} for _, c in host:GetChildren() do table.insert(o, c.Name) end return table.concat(o, ",") end
local function dump(q, slot)
	local o = {}
	for i, e in slot._elements do table.insert(o, (if q.isSlot(e) then "slot" else tostring(e.Name)) .. "@" .. tostring(q.Bookkeeping.getOffsetAt(slot, i))) end
	return table.concat(o, " ")
end
-- callback isolates its own error the way the engine isolates a listener's (records the id)
local function guarded(out, fn) return function(...) local ok, err = pcall(fn, ...) if not ok then out("callback error: " .. (tostring(err):match("Quad%d+") or tostring(err):sub(1, 60))) end end end
run("(N1) rawAdd: slot{inner{p,q}} ; b OnChange Parent → slot:Add(c, 1) ; slot:Add(b)", function(q, out)
	local D = q.Declaration
	local slot
	local armed = true
	local b = D.Frame({ Name = "b", q.OnChange("Parent", guarded(out, function(p) if armed and p ~= nil then armed = false; slot:Add(D.Frame({ Name = "c" }), 1) end end)) })
	slot = q.Slot({ q.Slot({ D.Frame({ Name = "p" }), D.Frame({ Name = "q" }) }) })
	local host = D.Frame({ Name = "host", slot }); S.flush()
	slot:Add(b); S.flush()
	out(("elements=[%s] Length=%s children=%d"):format(dump(q, slot), tostring(slot.Length:Get()), #host:GetChildren()))
end)
run("(N2) Replace: slot{inner{p,q}, b, d}; b OnChange Parent nil → slot:Add(c, 1); slot:Replace(2, e)", function(q, out)
	local D = q.Declaration
	local slot
	local armed = false
	local b = D.Frame({ Name = "b", q.OnChange("Parent", guarded(out, function(p) if armed and p == nil then armed = false; slot:Add(D.Frame({ Name = "c" }), 1) end end)) })
	slot = q.Slot({ q.Slot({ D.Frame({ Name = "p" }), D.Frame({ Name = "q" }) }), b, D.Frame({ Name = "d" }) })
	local host = D.Frame({ Name = "host", slot }); S.flush(); armed = true
	slot:Replace(2, D.Frame({ Name = "e" })); S.flush()
	out(("elements=[%s] Length=%s children=%d"):format(dump(q, slot), tostring(slot.Length:Get()), #host:GetChildren()))
end)
run("(N3) Remove: slot{a,b,d}; b OnChange Parent nil → slot:Remove(1); slot:Remove(2)", function(q, out)
	local D = q.Declaration
	local slot
	local armed = false
	local b = D.Frame({ Name = "b", q.OnChange("Parent", guarded(out, function(p) if armed and p == nil then armed = false; slot:Remove(1) end end)) })
	slot = q.Slot({ D.Frame({ Name = "a" }), b, D.Frame({ Name = "d" }) })
	local host = D.Frame({ Name = "host", slot }); S.flush(); armed = true
	slot:Remove(2); S.flush()
	out(("elements=[%s] Length=%s children=[%s]"):format(dump(q, slot), tostring(slot.Length:Get()), names(host)))
end)
run("(N4) Remove: slot{a,b,d}; b OnChange Parent nil → slot:Clear(); slot:Remove(2)", function(q, out)
	local D = q.Declaration
	local slot
	local armed = false
	local b = D.Frame({ Name = "b", q.OnChange("Parent", guarded(out, function(p) if armed and p == nil then armed = false; slot:Clear() end end)) })
	slot = q.Slot({ D.Frame({ Name = "a" }), b, D.Frame({ Name = "d" }) })
	local host = D.Frame({ Name = "host", slot }); S.flush(); armed = true
	slot:Remove(2); S.flush()
	out(("elements=[%s] Length=%s children=[%s]"):format(dump(q, slot), tostring(slot.Length:Get()), names(host)))
end)
run("(N5) destroy nested: outer{a, inner{x}}; x OnChange Parent nil → inner:Add(y); outer:Remove(2)", function(q, out)
	local D = q.Declaration
	local inner
	local armed = false
	local y = D.Frame({ Name = "y" })
	local x = D.Frame({ Name = "x", q.OnChange("Parent", guarded(out, function(p) if armed and p == nil then armed = false; inner:Add(y) end end)) })
	inner = q.Slot({ x })
	local outer = q.Slot({ D.Frame({ Name = "a" }), inner })
	local host = D.Frame({ Name = "host", outer }); S.flush(); armed = true
	outer:Remove(2); S.flush()
	out(("outer=[%s] Length=%s children=[%s] y.claimed=%s"):format(dump(q, outer), tostring(outer.Length:Get()), names(host), tostring(q.Backend.isClaimed(y))))
end)
