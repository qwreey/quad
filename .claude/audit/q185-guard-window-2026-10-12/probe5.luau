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

local function flat(q, slot, acc)
	acc = acc or {}
	for _, e in slot._elements do if q.isSlot(e) then flat(q, e, acc) else table.insert(acc, e.Name) end end
	return acc
end
run("(N6) inner:Add(b) plain; b OnChange Parent → outer:Add(c, 1) (ancestor, front)", function(q, out)
	local D = q.Declaration
	local outer
	local armed = true
	local b = D.Frame({ Name = "b", q.OnChange("Parent", guarded(out, function(p) if armed and p ~= nil then armed = false; outer:Add(D.Frame({ Name = "c" }), 1) end end)) })
	local inner = q.Slot({ D.Frame({ Name = "p" }) })
	outer = q.Slot({ D.Frame({ Name = "a" }), inner, D.Frame({ Name = "z" }) })
	local host = D.Frame({ Name = "host", outer }); S.flush()
	inner:Add(b); S.flush()
	out(("leaves=[%s] outer.Length=%s inner.Length=%s inner.Offset=%s children=%d"):format(table.concat(flat(q, outer), ","), tostring(outer.Length:Get()), tostring(inner.Length:Get()), tostring(inner.Offset:Get()), #host:GetChildren()))
end)
run("(N7) inner:Remove(1) plain; x OnChange Parent nil → outer:Add(c, 1) (ancestor, front)", function(q, out)
	local D = q.Declaration
	local outer
	local armed = false
	local x = D.Frame({ Name = "x", q.OnChange("Parent", guarded(out, function(p) if armed and p == nil then armed = false; outer:Add(D.Frame({ Name = "c" }), 1) end end)) })
	local inner = q.Slot({ x, D.Frame({ Name = "p" }) })
	outer = q.Slot({ D.Frame({ Name = "a" }), inner, D.Frame({ Name = "z" }) })
	local host = D.Frame({ Name = "host", outer }); S.flush(); armed = true
	inner:Remove(1); S.flush()
	out(("leaves=[%s] outer.Length=%s inner.Length=%s inner.Offset=%s children=%d"):format(table.concat(flat(q, outer), ","), tostring(outer.Length:Get()), tostring(inner.Length:Get()), tostring(inner.Offset:Get()), #host:GetChildren()))
end)
run("(N8) outer:Add(inner{x}); x OnChange Parent → other:Add(y) (unrelated Slot)", function(q, out)
	local D = q.Declaration
	local other = q.Slot({})
	local host2 = D.Frame({ Name = "host2", other })
	local armed = true
	local x = D.Frame({ Name = "x", q.OnChange("Parent", guarded(out, function(p) if armed and p ~= nil then armed = false; other:Add(D.Frame({ Name = "y" })) end end)) })
	local inner = q.Slot({ x })
	local outer = q.Slot({ D.Frame({ Name = "a" }) })
	local host = D.Frame({ Name = "host", outer }); S.flush()
	outer:Add(inner); S.flush()
	out(("outer.Length=%s other.Length=%s host2 children=%d"):format(tostring(outer.Length:Get()), tostring(other.Length:Get()), #host2:GetChildren()))
end)
run("(N9) outer:Add(inner{x}); x OnChange Parent → inner:Add(y) (the arriving Slot)", function(q, out)
	local D = q.Declaration
	local inner
	local armed = true
	local x = D.Frame({ Name = "x", q.OnChange("Parent", guarded(out, function(p) if armed and p ~= nil then armed = false; inner:Add(D.Frame({ Name = "y" })) end end)) })
	inner = q.Slot({ x })
	local outer = q.Slot({ D.Frame({ Name = "a" }) })
	local host = D.Frame({ Name = "host", outer }); S.flush()
	outer:Add(inner); S.flush()
	out(("outer.Length=%s inner.Length=%s children=%d"):format(tostring(outer.Length:Get()), tostring(inner.Length:Get()), #host:GetChildren()))
end)
