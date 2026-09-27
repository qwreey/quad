--!nocheck
-- E72 targeted axes. usage: mise exec -- luau .claude/audit/round13-e72-nested-slot-fuzz/axes.luau -a <axis>
--   cyc   : a :List whose data is computed from a Slot Length/Offset its own contents feed (converging / diverging)
--   det   : Detach of an inner Slot (manual and :List) while Length/Offset observers are live; CRUD / data Set while
--           detached; re-attach; dispose/Add refusal while held
--   q52   : ancestor CRUD from a :List updateFn — first mount via drive (depth 1..3), runtime Add attach (direct
--           parent), later reconcile (no mount walk) — ID, blame line, state after
--   own   : public q.Bookkeeping ops with a Slot ownerKey (getOffsetAt base, unmounted/torn-down Slot)
local E = require("./env")
local I = E.mock.Instance
local args = { ... }
local AXIS = args[1] or "all"
local function leaf(n) local f = I.new("Frame"); f.Name = n or "f"; return f end
local function names(env, t) local o = {}; for _, e in ipairs(env.P(t)) do table.insert(o, e.Name) end; return table.concat(o, ",") end
local function short(err) return (tostring(err):gsub("\n.*", "")):sub(1, 220) end
local function hdr(s) print("\n== " .. s) end

if AXIS == "cyc" or AXIS == "all" then
	hdr("cyc1 converging: seat1 = :List(data = n items, n = min(S2.Offset + 1, 5)), seat2 = S2 (S2.Offset = L.Length)")
	for _, variant in ipairs({ "converge", "diverge" }) do
		local q, env = E.newBase()
		local host = I.new("Frame")
		local S2 = q.Slot({ leaf("s2") })
		local runs = 0
		local data = S2.Offset:Compute(function(self)
			runs += 1
			if runs > 200 then error("E72 guard: 200 recomputes") end
			local n = if variant == "converge" then math.min(self:Get() + 1, 5) else self:Get() + 1
			local t = {}
			for i = 1, n do t[i] = "k" .. i end
			return t
		end)
		local L = q.Slot():List(data, function(ctx)
			if ctx.Item == q.KeyGone then return nil end
			return ctx.Prev or leaf(ctx.Item)
		end, function(x) return x end)
		local ok, err = pcall(q.Dispatch.drive, host, { L, S2 })
		print(variant, "drive ok", ok, if ok then "" else short(err), "| runs", runs, "| L.Length", L.Length:Get(), "S2.Offset", S2.Offset:Get(), "| phys", names(env, host), "| viol", #env.viol)
		if variant == "converge" then
			-- disturb: add a leaf in front of everything via a new seat? use S2 add (after) and L-independent change
			S2:Add(leaf("s2b"))
			print("  after S2:Add", "L.Length", L.Length:Get(), "S2.Offset", S2.Offset:Get(), "phys", names(env, host))
		else
			-- after the guard threw: is the host frozen? try an unrelated CRUD on S2
			local ok2, err2 = pcall(function() S2:Add(leaf("s2b")) end)
			print("  after guard: S2:Add ok", ok2, if ok2 then "" else short(err2), "| S2.Length", S2.Length:Get(), "L.Length", L.Length:Get(), "phys", names(env, host))
		end
	end
	hdr("cyc2: P = Slot{ L }, L:List(data from P.Length) — the nested Slot's own Length feeds its content")
	for _, variant in ipairs({ "converge", "diverge", "diverge-noguard" }) do
		local q, env = E.newBase()
		local host = I.new("Frame")
		local P = q.Slot()
		local runs = 0
		local data = P.Length:Compute(function(self)
			runs += 1
			if variant ~= "diverge-noguard" and runs > 200 then error("E72 guard: 200 recomputes") end
			if variant == "diverge-noguard" and runs > 100000 then error("E72 hard guard 100000") end
			local n = if variant == "converge" then math.min(self:Get() + 1, 4) else self:Get() + 1
			local t = {}
			for i = 1, n do t[i] = "k" .. i end
			return t
		end)
		local L = q.Slot():List(data, function(ctx)
			if ctx.Item == q.KeyGone then return nil end
			return ctx.Prev or leaf(ctx.Item)
		end, function(x) return x end)
		P:Add(L)
		local t0 = os.clock()
		local ok, err = pcall(q.Dispatch.drive, host, { P, "tail" })
		print(variant, "drive ok", ok, if ok then "" else E.id(err) .. " " .. short(err), "| runs", runs, "| P.Length", P.Length:Get(), "L.Length", L.Length:Get(), "| #phys", #env.P(host), string.format("| %.1f ms", (os.clock() - t0) * 1e3))
		if not ok then
			local ok2, err2 = pcall(function() P:Add(leaf("x")) end)
			print("  after: P:Add ok", ok2, if ok2 then "" else short(err2), "| P.Length", P.Length:Get(), "#phys", #env.P(host))
		end
	end
end

if AXIS == "det" or AXIS == "all" then
	hdr("det1: :List element = manual Slot; hide -> Detach while user Length/Offset observers live; CRUD while detached; show")
	local q, env = E.newBase()
	local host = I.new("Frame")
	local hidden = {}
	local made = {}
	local data = q.Source({ "a", "b", "c" })
	local L = q.Slot():List(data, function(ctx)
		if ctx.Item == q.KeyGone then return q.Detach end
		if hidden[ctx.Item] then return q.Detach end
		if ctx.Prev then return ctx.Prev end
		local s = q.Slot({ leaf(ctx.Item .. "1") }); made[ctx.Item] = s; return s
	end, function(x) return x end)
	q.Dispatch.drive(host, { "h0", L, "t0" })
	local b = made.b
	local seenL, seenO = {}, {}
	local o1 = b.Length:Observer(function() table.insert(seenL, b.Length:Get()) end); o1:Subscribe()
	local o2 = b.Offset:Observer(function() table.insert(seenO, b.Offset:Get()) end); o2:Subscribe()
	seenL, seenO = {}, {}
	hidden.b = true; data:Set({ "a", "b", "c" })
	print("hidden b:", names(env, host), "L.Length", L.Length:Get(), "b.L/O", b.Length:Get(), b.Offset:Get(), "notif L", #seenL, "O", #seenO)
	b:Add(leaf("b2")); b:Add(leaf("b0"), 1); b:Remove(2)
	print("CRUD on detached b:", "b.L/O", b.Length:Get(), b.Offset:Get(), "notif L", #seenL, "O", #seenO, "L.Length", L.Length:Get(), "phys", names(env, host))
	print("  Add(b) elsewhere:", select(2, pcall(function() q.Slot():Add(b) end)) and E.id(select(2, pcall(function() q.Slot():Add(b) end))), "| dispose(b):", E.id(select(2, pcall(function() q.dispose(b) end))))
	-- move a (front) while b detached: b's frozen offset must not move
	data:Set({ "c", "a", "b" })
	print("reorder while b hidden:", names(env, host), "b.O", b.Offset:Get(), "notif O", #seenO)
	hidden.b = nil; data:Set({ "c", "a", "b" })
	print("show b:", names(env, host), "b.L/O", b.Length:Get(), b.Offset:Get(), "L.Length", L.Length:Get(), "notif L", table.concat(seenL, ","), "O", table.concat(seenO, ","), "viol", #env.viol, "stale", #env.stale)

	hdr("det2: :List element = nested :List Slot (inner data Source); detach inner, Set inner data while detached, re-show")
	local q2, env2 = E.newBase()
	local host2 = I.new("Frame")
	local hid = {}
	local innerData, inner = {}, {}
	local outerData = q2.Source({ "x", "y" })
	local outer = q2.Slot():List(outerData, function(ctx)
		if ctx.Item == q2.KeyGone then return q2.Detach end
		if hid[ctx.Item] then return q2.Detach end
		if ctx.Prev then return ctx.Prev end
		local d = q2.Source({ ctx.Item .. "1", ctx.Item .. "2" })
		innerData[ctx.Item] = d
		local s = q2.Slot():List(d, function(c2)
			if c2.Item == q2.KeyGone then return nil end
			return c2.Prev or leaf(c2.Item)
		end, function(v) return v end)
		inner[ctx.Item] = s
		return s
	end, function(v) return v end)
	q2.Dispatch.drive(host2, { outer, "tail" })
	print("init", names(env2, host2), "outer.L", outer.Length:Get(), "x.L/O", inner.x.Length:Get(), inner.x.Offset:Get(), "y.O", inner.y.Offset:Get())
	hid.x = true; outerData:Set({ "x", "y" })
	print("x hidden", names(env2, host2), "outer.L", outer.Length:Get(), "y.O", inner.y.Offset:Get())
	innerData.x:Set({ "x3", "x1" })
	print("x data set while detached", "x.L", inner.x.Length:Get(), "#x._elements", #inner.x._elements, "phys", names(env2, host2))
	hid.x = nil; outerData:Set({ "x", "y" })
	print("x shown", names(env2, host2), "outer.L", outer.Length:Get(), "x.L/O", inner.x.Length:Get(), inner.x.Offset:Get(), "y.O", inner.y.Offset:Get(), "viol", #env2.viol, "stale", #env2.stale)
	-- KeyGone Detach then the key returns
	outerData:Set({ "y" })
	innerData.x:Set({ "x9" })
	outerData:Set({ "y", "x" })
	print("x gone->detach, data set, back", names(env2, host2), "outer.L", outer.Length:Get(), "x.L/O", inner.x.Length:Get(), inner.x.Offset:Get(), "viol", #env2.viol, "stale", #env2.stale)
end

if AXIS == "q52" or AXIS == "all" then
	hdr("q52: :List updateFn CRUDs an ancestor")
	local function scenario(label, depth, target, phase)
		-- tree: host{ R } ; R = Slot{ leaf, A1 } ; A1 = Slot{ A2 } ... ; deepest holds L (:List)
		local q, env = E.newBase()
		local host = I.new("Frame")
		local chain = {}
		local armed = (phase == "mount")
		local data = q.Source({ "a" })
		local hitErr
		local L = q.Slot():List(data, function(ctx)
			if ctx.Item == q.KeyGone then return nil end
			if armed then
				armed = false
				local anc = chain[target]
				local ok, err = pcall(function() anc:Add(leaf("intruder")) end) -- LINE_MARK
				hitErr = if ok then "no error" else short(err)
			end
			return ctx.Prev or leaf(ctx.Item)
		end, function(x) return x end)
		if phase ~= "runtimeAdd" then
			local child = L
			for d = depth, 1, -1 do
				child = q.Slot({ leaf("p" .. d), child })
				chain[d] = child
			end
		end
		if phase == "runtimeAdd" then
			-- mount the chain WITHOUT L first, then Add the subtree holding L to chain[depth] at runtime
			local root = q.Slot({ leaf("r") })
			chain = { root }
			local sub = q.Slot({ L })
			q.Dispatch.drive(host, { root })
			armed = true
			local ok, err = pcall(function() root:Add(sub) end)
			print(label, "runtime Add ok", ok, if ok then "" else short(err))
		else
			local ok, err = pcall(q.Dispatch.drive, host, { chain[1], "tail" })
			if phase == "later" then
				armed = true
				data:Set({ "a", "b" })
			end
			print(label, "drive ok", ok, if ok then "" else short(err))
		end
		print("   updateFn CRUD ->", hitErr)
		local lens = {}
		for d = 1, #chain do table.insert(lens, `A{d}.L={chain[d].Length:Get()} mat={tostring(chain[d]._materializing)}`) end
		print("   " .. table.concat(lens, " "), "| L.L", L.Length:Get(), "| phys", names(env, host), "| viol", #env.viol, "stale", #env.stale)
		-- can the ancestor be used afterwards?
		local ok3, err3 = pcall(function() chain[target]:Add(leaf("after")) end)
		print("   later CRUD on that ancestor:", ok3, if ok3 then "" else short(err3))
	end
	scenario("mount depth1 parent", 1, 1, "mount")
	scenario("mount depth3 root", 3, 1, "mount")
	scenario("mount depth3 parent", 3, 3, "mount")
	scenario("runtime Add direct parent", 1, 1, "runtimeAdd")
	scenario("later reconcile depth3 root", 3, 1, "later")
	scenario("later reconcile depth3 parent", 3, 3, "later")
end

if AXIS == "own" or AXIS == "all" then
	hdr("own: public q.Bookkeeping with a Slot ownerKey")
	local q, env = E.newBase()
	local host = I.new("Frame")
	local S = q.Slot({ leaf("a"), q.Slot({ leaf("b") }), leaf("c") })
	q.Dispatch.drive(host, { "h0", "h1", S })
	local BK = q.Bookkeeping
	local function try(label, fn) local ok, r = pcall(fn); print(label, ok, if ok then tostring(r) else short(r)) end
	try("mounted getOffsetAt(S,1)", function() return BK.getOffsetAt(S, 1) end)
	try("mounted getOffsetAt(S,3)", function() return BK.getOffsetAt(S, 3) end)
	try("mounted getOffsetAt(S,4) (N+1)", function() return BK.getOffsetAt(S, 4) end)
	try("mounted getOffsetAt(S,5)", function() return BK.getOffsetAt(S, 5) end)
	-- extract S by unmounting: put S under an unmounted root is impossible while held; use a seat State instead
	local q2, env2 = E.newBase()
	local host2 = I.new("Frame")
	local T = q2.Slot({ leaf("a"), leaf("b") })
	local seat = q2.Source(T)
	q2.Dispatch.drive(host2, { "h0", seat })
	seat:Set(nil)
	local BK2 = q2.Bookkeeping
	local function try2(label, fn) local ok, r = pcall(fn); print(label, ok, if ok then tostring(r) else short(r)) end
	try2("unmounted (frozen Offset=1) getOffsetAt(T,1)", function() return BK2.getOffsetAt(T, 1) end)
	try2("unmounted getOffsetAt(T,2)", function() return BK2.getOffsetAt(T, 2) end)
	local U = q2.Slot({ leaf("u") })
	try2("never-mounted getOffsetAt(U,1)", function() return BK2.getOffsetAt(U, 1) end)
	try2("never-mounted getOffsetAt(U,2)", function() return BK2.getOffsetAt(U, 2) end)
	-- a third-party setLength on a mounted Slot owner (misuse): what does the Slot do with it?
	local q3, env3 = E.newBase()
	local host3 = I.new("Frame")
	local V = q3.Slot({ leaf("v1") })
	q3.Dispatch.drive(host3, { V, "tail" })
	local ok, err = pcall(function() q3.Bookkeeping.setLength(V, 2, 5) end)
	print("3rd-party setLength(V,2,5) on a mounted Slot:", ok, if ok then "" else short(err), "| V.Length", V.Length:Get(), "(elements 1)")
	local ok2, err2 = pcall(function() V:Add(leaf("v2")) end)
	print("  then V:Add:", ok2, if ok2 then "" else short(err2), "| V.Length", V.Length:Get(), "phys", names(env3, host3), "viol", #env3.viol)
end
