--!nocheck
-- descendant / nested / throw probes for Q186
local mock = require("./mock")
local q = mock.newQuad()
local function F(n) local f = mock.Instance.new("Frame"); f.Name = n; return f end
local function names(inst) local t = {} for _, c in inst:GetChildren() do table.insert(t, c.Name) end table.sort(t) return table.concat(t, ",") end
local function onParent(inst, when, fn)
	local rec = { err = nil, fired = false }
	inst:GetPropertyChangedSignal("Parent"):Connect(function()
		if rec.fired or (inst.Parent ~= nil) ~= (when == "in") then return end
		rec.fired = true
		local ok, err = pcall(fn); if not ok then rec.err = tostring(err) end
	end)
	return rec
end
local function leaves(slot, acc) local out = acc or {} for _, e in slot._elements do if q.isSlot(e) then leaves(e, out) else table.insert(out, e.Name) end end return out end
local function flags(...) local t = {} for _, s in {...} do table.insert(t, tostring(s._materializing)) end return table.concat(t, "/") end

-- P1 nested sibling window inside child's window; ancestors stay flagged; pending runs at the outer end
do
	local host = mock.Instance.new("Frame")
	local c, d = q.Slot({ F("p") }), q.Slot({ F("s") })
	local a = q.Slot({ c, d }); local t = q.Slot({ a })
	q.Dispatch.drive(host, { t })
	local log = {}
	local b = F("b"); local e = F("e")
	onParent(e, "in", function()
		table.insert(log, "inner-flags:" .. flags(a, t))
		a:WhenIdle(function() table.insert(log, "idle-a(inner)") end)
	end)
	onParent(b, "in", function()
		a:WhenIdle(function() table.insert(log, "idle-a(outer)") end)
		d:Add(e) -- sibling window nested
		table.insert(log, "after-sibling-flags:" .. flags(c, d, a, t))
	end)
	c:Add(b)
	print("P1", table.concat(log, " | "), "end flags", flags(c, d, a, t), names(host))
end

-- P2 descendant before / after in the ancestor window
for _, where in { "before", "after" } do
	local host = mock.Instance.new("Frame")
	local g = q.Slot({ F("g1") })
	local c = if where == "before" then q.Slot({ g, F("z") }) else q.Slot({ F("z"), g })
	local t = q.Slot({ c }); q.Dispatch.drive(host, { t })
	local b = F("b")
	local rec = onParent(b, "in", function() g:Add(F("gx")) end)
	local ok, err = pcall(function() c:Add(b, if where == "before" then 2 else 3) end)
	print("P2", where, ok, err, rec.err, table.concat(leaves(t), ","), "Len", t.Length:Get(), c.Length:Get(), g.Length:Get(), "host", names(host))
end

-- P3 throw in callback uncaught -> flags
do
	local host = mock.Instance.new("Frame")
	local c = q.Slot({ F("p") }); local a = q.Slot({ c, F("z") }); local t = q.Slot({ a })
	q.Dispatch.drive(host, { t })
	local b = F("b")
	b:GetPropertyChangedSignal("Parent"):Connect(function() error("boom") end)
	print("P3", pcall(function() c:Add(b) end))
	print("P3 flags", flags(c, a, t))
	local sib = q.Slot({ F("s") })
	print("P3 add to a", pcall(function() a:Add(F("n")) end))
end

-- P4 callback flips a :Single state that removes the window's own Slot (raw layer) -> flags
do
	local host = mock.Instance.new("Frame")
	local c = q.Slot({ F("p") })
	local st = q.Source(c)
	local a = q.Slot():Single(st, nil, { OwnsElements = false })
	local t = q.Slot({ a }); q.Dispatch.drive(host, { t })
	local b = F("b")
	onParent(b, "in", function() st:Set(nil) end)
	print("P4", pcall(function() c:Add(b) end))
	print("P4 flags", flags(c, a, t), "len t", t.Length:Get(), names(host))
end
