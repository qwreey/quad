-- E73 discriminating probe (quad-base, mock backend). Not a spec. Copied into quad-base/test/ by probe_survivors.py.
local mock = require("./mock")
local q = mock.newQuad()
local Instance = mock.Instance
local BK = q.Bookkeeping
local fails = {}
local function check(c, m) if not c then table.insert(fails, m) end end
local function errOf(f) local ok, e = pcall(f); return if ok then "<no error>" else tostring(e) end

-- PBK (item 2b — E69 BK02/BK04): a length Compute behind a CLOSED gate is dirty without any
-- observer firing, so recompute's getOffsetAt is the first reader and its fn runs there.
do
	local inst = Instance.new("Frame")
	local hold = function(_emit) return function() end end -- gate that never forwards
	local S1, d2, d = q.Source(1), q.Source(10), q.Source(100)
	local armed2, armed = false, false
	local L2 = d2:Gate(hold):Compute(function(x)
		if armed2 then armed2 = false; S1:Set(S1:Get() + 5) end -- lowers position 1 mid-fill
		return x:Get()
	end)
	local L = d:Gate(hold):Compute(function(x)
		if armed then armed = false; d2:Set(d2:Get() + 1); armed2 = true end -- dirties L2 silently
		return x:Get()
	end)
	local OF2, OF4 = q.Source(-1), q.Source(-1)
	BK.setOffsetSource(inst, 1, q.None); BK.setLength(inst, 1, S1)
	BK.setOffsetSource(inst, 2, OF2); BK.setLength(inst, 2, L2)
	BK.setOffsetSource(inst, 3, q.None); BK.setLength(inst, 3, L)
	BK.setOffsetSource(inst, 4, OF4); BK.setLength(inst, 4, 0)
	check(OF2:Get() == 1 and OF4:Get() == 111, "PBK0 setup " .. OF2:Get() .. "/" .. OF4:Get())
	armed = true
	d:Set(200) -- silent: gate holds, L's length observer does not fire
	S1:Set(2) -- trigger: recompute; L runs at contribution(3), L2 runs inside getOffsetAt(4) and Sets S1 := 7
	check(S1:Get() == 7, "PBK1 side effect ran: S1 = " .. S1:Get())
	check(OF2:Get() == 7, "PBK2 OF2 re-published after rewind (BK04/BK02): " .. OF2:Get())
	check(OF4:Get() == 7 + 11 + 200, "PBK3 OF4 = 218 (BK02): " .. OF4:Get())
	check(BK.getOffsetAt(inst, 4) == 218, "PBK4 getOffsetAt(4) = 218: " .. BK.getOffsetAt(inst, 4))
	check(BK.getOffsetAt(inst, 2) == 7, "PBK5 getOffsetAt(2) = 7: " .. BK.getOffsetAt(inst, 2))
end

-- PBK-b: BK02 alone through the public getOffsetAt under a held batch blocker
do
	local inst = Instance.new("Frame")
	local hold = function(_emit) return function() end end
	local S1, d = q.Source(1), q.Source(100)
	local armed = false
	local L = d:Gate(hold):Compute(function(x)
		if armed then armed = false; S1:Set(S1:Get() + 5) end
		return x:Get()
	end)
	BK.setOffsetSource(inst, 1, q.None); BK.setLength(inst, 1, S1)
	BK.setOffsetSource(inst, 2, q.None); BK.setLength(inst, 2, L)
	BK.setOffsetSource(inst, 3, q.None); BK.setLength(inst, 3, 0)
	local batch = BK.getBlocker(inst)
	batch:On()
	armed = true
	d:Set(200)
	local got = BK.getOffsetAt(inst, 3)
	check(got == 6 + 200, "PBKb getOffsetAt(3) after in-fill lowering = 206: " .. got)
	batch:Off()
	check(BK.getOffsetAt(inst, 3) == 206, "PBKb2 after batch close: " .. BK.getOffsetAt(inst, 3))
end

-- PSH03: a disposed (destroyed) Slot mounted through a numeric key
do
	local s = q.Slot()
	q.dispose(s)
	local e = errOf(function() q.Dispatch.drive(Instance.new("Folder"), { s }) end)
	check(string.find(e, "Quad0140", 1, true) ~= nil, "PSH03 destroyed Slot mount: " .. e)
end

-- PSH05/PSH06: the same Slot re-driven at the same position is a no-op
do
	local s = q.Slot()
	local a = Instance.new("Frame"); a.Name = "a"
	s:Add(a)
	local parent = Instance.new("Folder")
	local lead = q.Slot(); lead:Add(Instance.new("Frame"))
	local inserts = 0
	local orig = q.Backend.nativeInsert
	q.Backend.nativeInsert = function(...) inserts += 1; return orig(...) end
	q.Dispatch.drive(parent, { lead, s })
	local before = inserts
	local e = errOf(function() q.Dispatch.drive(parent, { lead, s }) end)
	check(e == "<no error>", "PSH05a re-drive raised: " .. e)
	check(inserts == before, "PSH05b re-drive re-inserted elements: " .. (inserts - before))
	check(#parent:GetChildren() == 2, "PSH05c children after re-drive: " .. #parent:GetChildren())
	local b = Instance.new("Frame"); b.Name = "b"
	s:Add(b)
	local ch = parent:GetChildren()
	check(#ch == 3 and ch[3] == b and s.Offset:Get() == 1 and s.Length:Get() == 2, "PSH05d state after add: n=" .. #ch .. " off=" .. s.Offset:Get() .. " len=" .. s.Length:Get())
	q.Backend.nativeInsert = orig
end

-- PSH08: a State<Slot|nil> going nil — the following Slot's offset collapses
do
	local s1, s2 = q.Slot(), q.Slot()
	s1:Add(Instance.new("Frame")); s1:Add(Instance.new("Frame"))
	s2:Add(Instance.new("Frame"))
	local src = q.Source(s1)
	local parent = Instance.new("Folder")
	q.Dispatch.drive(parent, { src, s2 })
	check(s2.Offset:Get() == 2, "PSH08a s2 offset 2: " .. s2.Offset:Get())
	src:Set(q.None)
	check(s2.Offset:Get() == 0, "PSH08b s2 offset 0 after nil: " .. s2.Offset:Get())
	local s3 = q.Slot(); s3:Add(Instance.new("Frame"))
	src:Set(s3)
	check(s2.Offset:Get() == 1, "PSH08c s2 offset 1 after swap: " .. s2.Offset:Get())
end

-- PSH01/02: a Slot at a non-positive-integer numeric key through the raw process surface
do
	local e = errOf(function() q.Dispatch.process(Instance.new("Folder"), 1.5, q.Slot(), 1) end)
	check(string.find(e, "Quad0141", 1, true) ~= nil, "PSH02 fractional key: " .. e)
	local e0 = errOf(function() q.Dispatch.process(Instance.new("Folder"), 0, q.Slot(), 1) end)
	check(string.find(e0, "Quad0141", 1, true) ~= nil, "PSH01 zero key: " .. e0)
	local ed = errOf(function() q.Dispatch.drive(Instance.new("Folder"), { [1.5] = q.Slot() }) end)
	check(string.find(ed, "Quad0141", 1, true) == nil, "PSH01d drive fractional key is gated before handlers: " .. ed)
end

-- PEL02/PEL04: Slot element error codes
do
	local e = errOf(function() q.Slot():Add(q.Modifier()) end)
	check(string.find(e, "Quad0238", 1, true) ~= nil, "PEL02 Modifier element: " .. e)
	local e2 = errOf(function() q.Slot():Add(q.None) end)
	check(string.find(e2, "Quad0239", 1, true) ~= nil, "PEL04 None element: " .. e2)
end

-- PFB05: Traceback's trace starts at the throw site, not the handler
do
	local tr
	q.Traceback(function() error("boom") end, function(_e, t) tr = t end)()
	local first = string.match(tr, "^[^\n]*") or ""
	check(string.find(first, "Fallback", 1, true) == nil, "PFB05 trace first frame: " .. first)
end

-- PST04 (item 2c — E69 ST04 refuted): a Compute behind an every-other gate whose fn Sets its own upstream once
-- (the `H-198` reentrant-Set case); without the pre-fn stamp a later Get runs fn one extra time
do
	local s = q.Source(3)
	local cnt = 0
	local g = s:Gate(function(emit) return function() cnt += 1; if cnt % 2 == 0 then emit() end end end)
	local runs = 0
	local n = g:Compute(function(x) runs += 1; local v = (x:Get() * 3) % 5; if runs == 1 then s:Set(1) end; return v end)
	s:Set(0); s:Set(3)
	check(n:Get() == 3, "PST04a first read")
	s:Set(0); s:Set(1)
	check(n:Get() == 3 and runs == 3, "PST04 fn runs after the reentrant generation: " .. runs)
end

-- PST09 (item 2c — E69 ST09 refuted): gate over gate — a batch the lower gate already delivered (its emit map
-- was synced at flush) must be swallowed when the upper gate re-delivers it: no duplicate notification
do
	local s = q.Source(1)
	local e1, e2
	local g1 = s:Gate(function(emit) e1 = emit; return function() end end)
	local g2 = g1:Gate(function(emit) e2 = emit; return function() end end)
	local seen = {}
	local o = g2:Observer(function(t) table.insert(seen, t:Get()) end); o:Subscribe()
	g1:Get(); s:Set(2); e2(true); g1:Get()
	e1(); e2(true)
	s:Set(2); e1(true); s:Set(1); e2(true)
	g2:Get()
	e1(); e1(false)
	check(e2() == false, "PST09a lower gate reports nothing pending")
	check(#seen == 3 and seen[3] == 1, "PST09 notifications " .. table.concat(seen, "/"))
end

if #fails == 0 then print("PROBE ALL OK") else for _, f in fails do print("FAIL " .. f) end end
