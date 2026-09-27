local mock = require("./mock")
local q = mock.newQuad()
local Instance = mock.Instance
local fails = {}
local function check(c, m) if not c then table.insert(fails, m) end end
-- P1 (BK16/SE01): descendants of a Slot that sits at a non-zero base offset
do
	local sA, sB, inner = q.Slot(), q.Slot(), q.Slot()
	sA:Add(Instance.new("Frame"))
	local x = Instance.new("Frame"); x.Name = "x"
	inner:Add(x)
	sB:Add(inner)
	local parent = Instance.new("Folder")
	q.Dispatch.drive(parent, { sA, sB })
	check(inner.Offset:Get() == 1, "P1a inner offset at base 1: " .. inner.Offset:Get())
	local y = Instance.new("Frame"); y.Name = "y"
	sB:Add(y, 1) -- insert before inner, physically at parent index 2 (after sA's leaf)
	local ch = parent:GetChildren()
	check(inner.Offset:Get() == 2, "P1b inner offset after insert before it: " .. inner.Offset:Get())
	sA:Add(Instance.new("Frame")) -- sB base 1 -> 2; inner must follow to 3
	check(inner.Offset:Get() == 3, "P1c inner offset follows uncle growth: " .. inner.Offset:Get())
	local z = Instance.new("Frame"); z.Name = "z"
	inner:Add(z, 1)
	check(q.Bookkeeping.getOffsetAt(inner, 1) == 3, "P1d getOffsetAt(inner,1) == 3: " .. q.Bookkeeping.getOffsetAt(inner, 1))
end
-- P2 (EF17/EF18/OB10): same Effect / Observer re-driven at the same position
do
	local inst = Instance.new("Frame")
	local s = q.Source(0)
	local runs, cleans = 0, 0
	local e = q.Effect(function() runs += 1; return function() cleans += 1 end end, s)
	local o = s:Observer(function() end)
	local ok, err = pcall(function()
		q.Dispatch.drive(inst, { e, o })
		q.Dispatch.drive(inst, { e, o })
	end)
	check(ok, "P2a re-drive same Effect/Observer raised: " .. tostring(err))
	check(cleans == 0, "P2b re-drive ran the cleanup: " .. cleans)
	check(not q.Backend.canBound(e) and not q.Backend.canBound(o), "P2c still bound after re-drive")
	s:Set(1)
	check(runs == 2, "P2d effect reruns after re-drive: " .. runs)
end
-- P3 (SW04/SW07): IndexOf after Remove/Replace
do
	local s = q.Slot()
	local a, b, c = Instance.new("Frame"), Instance.new("Frame"), Instance.new("Frame")
	s:Add(a); s:Add(b)
	s:Remove(1)
	check(s:IndexOf(a) == nil, "P3a IndexOf(removed) = " .. tostring(s:IndexOf(a)))
	s:Replace(1, c)
	check(s:IndexOf(b) == nil, "P3b IndexOf(replaced-out) = " .. tostring(s:IndexOf(b)))
end
-- P4 (EF11): Effect:WeakSubscribe twice must raise
do
	local e = q.Effect(function() end)
	e:WeakSubscribe()
	check(not pcall(function() e:WeakSubscribe() end), "P4 double WeakSubscribe did not raise")
end
-- P5 (SL04): duplicate key in :List must raise
do
	local s = q.Slot()
	s:List({ 1, 1 }, function(ctx) return Instance.new("Frame") end, function(item) return item end)
	local ok, err = pcall(function() q.Dispatch.drive(Instance.new("Folder"), { s }) end)
	check(not ok and string.find(tostring(err), "Quad0145") ~= nil, "P5 duplicate key: " .. tostring(err))
end
-- P6 (SL06): UserData round trip
do
	local s = q.Slot()
	local data = q.Source({ "a" })
	local seen
	s:List(data, function(ctx) seen = ctx.UserData; return Instance.new("Frame"), (ctx.UserData or 0) + 1 end, function(item) return item end)
	q.Dispatch.drive(Instance.new("Folder"), { s })
	data:Set({ "a" })
	check(seen == 1, "P6 UserData round trip: " .. tostring(seen))
end
-- P7 (SW14): detached element dropped via nil is destroyed (owned list)
do
	local s = q.Slot()
	local data = q.Source({ "a" })
	local mode = "keep"
	local el
	s:List(data, function(ctx)
		if mode == "keep" then el = el or Instance.new("Frame"); return el end
		if mode == "detach" then return q.Detach end
		return nil
	end, function(item) return item end)
	q.Dispatch.drive(Instance.new("Folder"), { s })
	mode = "detach"; data:Set({ "a" })
	mode = "drop"; data:Set({ "a" })
	check(mock.isDestroyed(el), "P7 detached element not destroyed")
end
-- P8 (OB06): tostring after Unsubscribe
do
	local s = q.Source(0)
	local o = s:Observer(function() end):Subscribe()
	o:Unsubscribe()
	check(tostring(o) == "Observer(unsubscribed)", "P8 tostring after Unsubscribe: " .. tostring(o))
end

-- P9 (SI09): Splice removeCount past the end -> Quad0174
do
	local s = q.Slot(); s:Add(Instance.new("Frame"))
	local ok, err = pcall(function() s:Splice(1, 2) end)
	check(not ok and string.find(tostring(err), "Quad0174") ~= nil, "P9 Splice range error: " .. tostring(err))
end
-- P10 (DI07): process index gap -> Quad0075
do
	local inst = Instance.new("Frame")
	local ok, err = pcall(function() q.Dispatch.process(inst, 1, q.Tag("a"), 2) end)
	check(not ok and string.find(tostring(err), "Quad0075") ~= nil, "P10 gap error: " .. tostring(err))
end
-- P11 (SN01): List updateFn returns an element already mounted in another Slot -> error
do
	local other = q.Slot(); local shared = Instance.new("Frame"); other:Add(shared)
	local s = q.Slot()
	s:List({ 1 }, function() return shared end)
	check(not pcall(function() q.Dispatch.drive(Instance.new("Folder"), { s }) end), "P11 double mount via List did not raise")
end
-- P12 (SN03): releaseOwner with the wrong owner -> Quad0163
do
	local inst, other = Instance.new("Frame"), Instance.new("Frame")
	local el = Instance.new("Frame")
	q.Bookkeeping.claimOwnerAt(el, inst, 1)
	local ok, err = pcall(function() q.Bookkeeping.releaseOwner(el, other) end)
	check(not ok and string.find(tostring(err), "Quad0163") ~= nil, "P12 wrong-owner release: " .. tostring(err))
end
-- P13 (TG08): Tag nesting deeper than 64 -> Quad0201
do
	local t: any = "x"
	for _ = 1, 70 do t = { t } end
	local ok, err = pcall(function() q.Tag(t) end)
	check(not ok and string.find(tostring(err), "Quad0201") ~= nil, "P13 depth gate: " .. tostring(err))
end
-- P14 (DB01): State Time negative -> error at read
do
	local T = q.Source(-0.5)
	local src = q.Source(0)
	local g = src:Apply(q.Debounce({ Time = T }))
	local o = g:Observer(function() end):Subscribe()
	local ok, err = pcall(function() src:Set(1) end)
	check(not ok and string.find(tostring(err), "Quad0039") ~= nil, "P14 negative State Time: " .. tostring(err))
	local _ = o
end
-- P15 (OP03/OP05): Clamp(lo, lo) and Shr on a high-bit number
do
	local s = q.Source(5)
	local ok, v = pcall(function() return s:Apply(q.Operator.Clamp(3, 3)):Get() end)
	check(ok and v == 3, "P15a Clamp(3,3): " .. tostring(v))
	local h = q.Source(0x80000000)
	check(h:Apply(q.Operator.Shr(4)):Get() == 0x08000000, "P15b Shr logical: " .. tostring(h:Apply(q.Operator.Shr(4)):Get()))
end
-- P16 (LH06): unbinding a bound Effect drops its Destroying connection (the old inst's Destroy must not touch it)
do
	local inst = Instance.new("Frame")
	local cleans = 0
	local e = q.Effect(function() return function() cleans += 1 end end)
	q.Dispatch.drive(inst, { e })
	q.Dispatch.drive(inst, { [1] = q.None })
	local c0 = cleans
	e:WeakSubscribe()
	inst:Destroy()
	check(cleans == c0, "P16 destroyed old inst ran the (re-subscribed) Effect's cleanup: " .. c0 .. "->" .. cleans)
	check(e.Subscribed and q.Backend.canExecute(e), "P16b effect still executable after old inst destroyed")
end
-- P17 (SL10/BK10): Length emits once per batch (List reconcile of 5 items)
do
	local s = q.Slot()
	local data = q.Source({})
	s:List(data, function() return Instance.new("Frame") end)
	q.Dispatch.drive(Instance.new("Folder"), { s })
	local n = 0
	local o = s.Length:Observer(function() n += 1 end):Subscribe()
	n = 0
	data:Set({ 1, 2, 3, 4, 5 })
	check(n == 1, "P17 Length emits per reconcile: " .. n)
	local _ = o
end

-- P18 (BK04/BK06): an Offset observer that grows an EARLIER sibling during recompute (rewind path)
do
	local root, A, B, C = q.Slot(), q.Slot(), q.Slot(), q.Slot()
	A:Add(Instance.new("Frame")); B:Add(Instance.new("Frame")); C:Add(Instance.new("Frame"))
	root:Add(A); root:Add(B); root:Add(C)
	local parent = Instance.new("Folder")
	q.Dispatch.drive(parent, { root })
	local fired = false
	local o = C.Offset:Observer(function()
		if not fired and C.Offset:Get() == 3 then fired = true; A:Add(Instance.new("Frame")) end
	end):Subscribe()
	B:Add(Instance.new("Frame")) -- C: 2 -> 3, whose observer grows A (position 1) mid-recompute
	check(fired, "P18 observer fired")
	check(B.Offset:Get() == A.Length:Get(), "P18a B.Offset " .. B.Offset:Get() .. " vs A.Length " .. A.Length:Get())
	check(C.Offset:Get() == A.Length:Get() + B.Length:Get(), "P18b C.Offset " .. C.Offset:Get())
	check(root.Length:Get() == 5 and #parent:GetChildren() == 5, "P18c root Length " .. root.Length:Get())
	local _ = o
end
-- P19 (DI10): a same-handler re-drive whose process throws must not leave the old retractor armed
do
	local calls = 0
	local fail = false
	q.Dispatch.addHandler({
		name = "E69Probe", keyType = "string", priority = q.Dispatch.HANDLER_PRIORITY_HIGH + 7,
		isHandlable = function(_i, k) return k == "E69Probe" end,
		process = function(_i, _k, _v, _idx)
			if fail then error("boom") end
			return function() calls += 1 end
		end,
	})
	local inst = Instance.new("Frame")
	q.Dispatch.process(inst, "E69Probe", 1, 1)
	fail = true
	pcall(function() q.Dispatch.process(inst, "E69Probe", 2, 1) end)
	q.Dispatch.retractFrom(inst, "E69Probe", 1)
	check(calls == 1, "P19 old retractor calls: " .. calls)
end

if #fails == 0 then print("PROBE ALL OK") else for _, f in fails do print("FAIL " .. f) end end
