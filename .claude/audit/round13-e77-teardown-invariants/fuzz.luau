--!nocheck
-- E77 property-based teardown fuzzer: random *application* (all subsystems mixed) -> random interaction
-- sequence -> one of seven teardown paths -> global invariants (GC, live connections/timers, error ids,
-- cleanup/hook counts, cross-tree residue vs a pristine canonical trace).
-- usage (repo root): mise exec -- luau .claude/audit/round13-e77-teardown-invariants/fuzz.luau -a <first> <count> [v|q] [mutation]
-- mutations: skipCleanup | holdStrong | noDestroying | tagLeak | keepTimer | none
local H = require("./harness")
local mock = H.mock
local q, D = H.q, H.D
local CS = H.CollectionService
local args = { ... }
local FIRST = tonumber(args[1]) or 1
local COUNT = tonumber(args[2]) or 50
local VERB = args[3] == "v"
local MUT = args[4] or "none"

-- ---------------------------------------------------------------- engine-like handler isolation (E50 idiom)
local handlerErrs = {}
do
	local probe = mock.Instance.new("Frame")
	local SignalMT = getmetatable(probe.Destroying)
	SignalMT.Fire = function(self, ...)
		local snapshot = table.clone(self.connections)
		for i = #snapshot, 1, -1 do
			local conn = snapshot[i]
			if conn.Connected then
				local ok, e = pcall(conn.fn, ...)
				if not ok then table.insert(handlerErrs, e) end
			end
		end
	end
	probe:Destroy()
end
H.setTaskErrHook(function(e) table.insert(handlerErrs, e) end)

-- ---------------------------------------------------------------- mutations (checker detection power)
local strongHold = {}
plainArmed = false
if MUT == "noDestroying" then
	q.Backend.onDestroying = function() return { Disconnect = function() end, Connected = true } end
elseif MUT == "claimedAlways" then
	q.Backend.isClaimed = function() return true end -- H-594 gate disabled: late tween notices reach dead trees
elseif MUT == "plainError" then
	local origAdd = CS.AddTag
	CS.AddTag = function(self, inst, name) -- an engine error with no Quad id (armed only inside fuzz seeds, T2 only)
		if plainArmed and name == "T2" then error("engine rejected tag") end
		return origAdd(self, inst, name)
	end
end
local DEFERRED = args[5] == "deferred"
local deferredQ = {}
if DEFERRED then
	local orig = q.Backend.onDestroying
	q.Backend.onDestroying = function(inst, fn)
		return orig(inst, function(...) table.insert(deferredQ, fn) end)
	end
end
local function flushDeferred()
	while #deferredQ > 0 do
		local fn = table.remove(deferredQ, 1)
		local ok, e = pcall(fn)
		if not ok then table.insert(handlerErrs, e) end
	end
end

-- ---------------------------------------------------------------- rng
local rs = 1
local function nextF() rs = (rs * 1103515245 + 12345) % 2147483648; return rs / 2147483648 end
local function R(n) return math.floor(nextF() * n) + 1 end
local function P(p) return nextF() < p end
local function pick(t) return t[R(#t)] end

-- ---------------------------------------------------------------- error classification
local errStats = { quad = {}, user = 0, noid = {}, total = 0 }
local function classify(e, where)
	local s = tostring(e)
	errStats.total += 1
	local id = s:match("Quad%d%d%d%d")
	if id then errStats.quad[id] = (errStats.quad[id] or 0) + 1; return "quad", id end
	if s:find("boom", 1, true) then errStats.user += 1; return "user" end
	local k = where .. ": " .. H.first(s):gsub("^[^:]*:%d+: ", "")
	errStats.noid[k] = (errStats.noid[k] or 0) + 1
	return "noid"
end

-- ---------------------------------------------------------------- GC helpers (E42 gclib idiom)
local function fullgc()
	local prev = -1
	for i = 1, 12 do
		collectgarbage("collect")
		local c = collectgarbage("count")
		if i >= 3 and math.abs(c - prev) < 0.5 then return c end
		prev = c
	end
	return collectgarbage("count")
end

-- ---------------------------------------------------------------- module-lived "app" globals
local G = {}
G.pulse = q.Source(0)
G.text = q.Source("t")
G.flag = q.Source(true)
G.kill = q.Source(0)
G.blocker = q.Blocker()
G.extSig = mock.newSignal()
G.P1 = q.Context.Provider("Theme")
G.P2 = q.Context.Provider("User")
G.appSlot = q.Slot()
G.appSeat = q.Source(nil)
G.app = D.Frame({ Name = "app", G.appSlot, G.appSeat })
local TAGS = { "T1", "T2", "T3", "T4" }
local ATTRS = { "A1", "A2", "A3", "A4" }
local SEATATTRS = { "B1", "B2", "B3", "B4" }

-- ---------------------------------------------------------------- canonical scripted tree (invariant 5)
-- Uses the same globals / tag names / attr names / providers as the fuzz trees, so residue in any of them shows.
local function canon(qq, DD, GG)
	local out = {}
	local function rec(k, v) table.insert(out, k .. "=" .. tostring(v)) end
	GG.blocker:Off()
	GG.pulse:Set(0); GG.text:Set("c"); GG.flag:Set(true)
	local listSrc = qq.Source({ 1, 2, 3 })
	local bag = qq.Context():Set(GG.P1, qq.Source("theme"))
	local nObs, nEff, nCl, nChange, nWrites, nList, nDeb, nExt = 0, 0, 0, 0, 0, 0, 0, 0
	local pend0 = H.pending()
	local tw0 = #mock.tweenLog
	local f = DD.TextBox({
		Name = "canon",
		Text = GG.text,
		PlaceholderText = bag:Get(GG.P1),
		LayoutOrder = GG.pulse:Apply(GG.blocker),
		ZIndex = GG.pulse:Apply(qq.Debounce({ Time = 1 })),
		Size = GG.pulse:Compute(function(s) return qq.Tween({ Value = s:Get(), Time = 1 }) end),
		qq.Tag("T1"), qq.Tag("T2"),
		qq.Attr({ A1 = GG.pulse }),
		[qq.AttrKey("A2")] = 7,
		qq.OnChange("Text", function() nChange += 1 end),
		GG.pulse:Observer(function() nObs += 1 end),
		GG.pulse:Apply(qq.Throttle({ Time = 1 })):Observer(function() nDeb += 1 end),
		qq.Effect(function()
			nEff += 1
			local c = GG.extSig:Connect(function() nExt += 1 end)
			return function() nCl += 1; c:Disconnect() end
		end, GG.flag),
		DD.Frame({ qq.Tag("T3"), qq.Attr({ A3 = 1 }) }),
		qq.Slot():List(listSrc, function(ctx)
			if ctx.Item == qq.KeyGone then return nil end
			if ctx.Prev then return ctx.Prev end
			nList += 1
			return DD.Frame({ Name = "L" .. ctx.Item, qq.Tag("T4") })
		end),
	})
	local conn = f:GetPropertyChangedSignal("LayoutOrder"):Connect(function() nWrites += 1 end)
	for i = 1, 3 do GG.pulse:Set(i) end
	GG.text:Set("c2"); GG.extSig:Fire(); GG.flag:Set(false); GG.extSig:Fire()
	GG.blocker:On(); GG.pulse:Set(10); GG.blocker:Off()
	f.Text = "ext"
	listSrc:Set({ 3, 4 })
	H.runTask(3)
	rec("obs", nObs); rec("eff", nEff); rec("cl", nCl); rec("chg", nChange); rec("wr", nWrites)
	rec("list", nList); rec("thr", nDeb); rec("ext", nExt); rec("lo", f.LayoutOrder); rec("z", f.ZIndex)
	rec("tags", table.concat(CS:GetTags(f), ","))
	rec("A1", f:GetAttribute("A1")); rec("A2", f:GetAttribute("A2"))
	rec("kids", #f:GetChildren()); rec("tw", #mock.tweenLog - tw0); rec("pend", H.pending() - pend0)
	rec("extconns", #GG.extSig.connections)
	qq.dispose(f)
	flushDeferred()
	conn:Disconnect()
	GG.pulse:Set(99); GG.extSig:Fire(); H.runTask(5)
	rec("postObs", nObs); rec("postCl", nCl); rec("postExt", nExt); rec("pendAfter", H.pending() - pend0)
	rec("extconnsAfter", #GG.extSig.connections)
	return table.concat(out, " ")
end

-- ---------------------------------------------------------------- totals
local T = {
	seeds = 0, nodes = 0, insts = 0, steps = 0,
	inv1 = 0, inv1Kinds = {}, inv1Seeds = {},
	inv2conn = 0, inv2instconn = 0, inv2post = 0, inv2postKinds = {}, inv2timers = 0, inv2tweenConn = 0,
	inv3noid = 0,
	inv4eff = 0, inv4dying = 0, inv4od = 0, inv4tween = 0, inv4notDestroyed = 0,
	inv5 = 0, inv5Samples = {},
	teardowns = {}, tdMissedBy = {}, waveCross = 0, docOrphans = 0, fbThrows = 0,
	tweenCb = { S = 0, C = 0, X = 0 }, cancelledOnReplace = 0,
	effRuns = 0, odHooks = 0, maxNodes = 0,
}
local function bump(t, k, n) t[k] = (t[k] or 0) + (n or 1) end

-- ---------------------------------------------------------------- one seed
local BASE_CANON -- filled at start
local TEARDOWNS = { "dispose", "destroy", "seatNil", "clear", "extractAll", "remove", "fromCallback", "fromEvent", "fromTween", "fromOnChange", "fromCleanup", "fromTimer", "fromOnRendered" }

local function runSeed(seed)
	rs = seed * 7919 + 17; for _ = 1, 5 do nextF() end
	table.clear(handlerErrs)
	mock.resetTweenLog()
	local tracker = setmetatable({}, { __mode = "k" })
	local function track(o, kind) if o ~= nil and type(o) ~= "string" and type(o) ~= "number" and type(o) ~= "boolean" then tracker[o] = kind end return o end
	local seedConnFns = setmetatable({}, { __mode = "k" })
	local phase = "build"
	local nodes = {}
	local pendingDispose = {} -- user-owned values the program disposes after the current step
	local C = { postKinds = {} }
	local function post(kind) if phase == "post" then C.post = (C.post or 0) + 1; bump(C.postKinds, kind) end end
	local function op(label, f, ...)
		local ok, e = pcall(f, ...)
		if not ok then classify(e, label) end
		if DEFERRED then flushDeferred() end
		return ok, e
	end
	-- per-seed context bag with per-seed values (the bag itself is dropped at teardown)
	local themeSrc = track(q.Source("theme" .. seed), "ctxValue")
	local bag = track(q.Context():Set(G.P1, themeSrc):Set(G.P2, { Name = "u" .. seed }), "ctxBag")
	local rootNode
	local killSeen = false
	local rootBox = {}
	local rootFade, rootTimerSrc, rootKillSlot
	local td

	local function cbAction(n)
		local a = n.action
		if a == "set" then G.pulse:Set(G.pulse:Get() + 1)
		elseif a == "read" then local _ = G.text:Get()
		elseif a == "throw" then error("boom" .. n.id) end
	end

	local build -- forward
	local function newNode(depth, class)
		local n = { id = #nodes + 1, depth = depth, class = class, c = { effRun = 0, effCl = 0, effDyingT = 0, od = 0, S = 0, Cm = 0, X = 0 } }
		nodes[n.id] = n
		n.action = pick({ "none", "none", "read", "set", "throw" })
		return n
	end

	local function makeListSlot(n, depth)
		local keys = {}
		for k = 1, R(4) - 1 do keys[k] = k end
		local data = track(q.Source(keys), "Source")
		local owns = P(0.6)
		local detach = P(0.4)
		local byKey = {}
		local slot = q.Slot():List(data, function(ctx)
			if ctx.Item == q.KeyGone then
				if not owns and ctx.Prev then table.insert(pendingDispose, ctx.Prev) end
				if owns and detach then return q.Detach end
				return nil
			end
			if ctx.Prev then return ctx.Prev end
			local ch = build(depth + 1)
			return ch.inst
		end, nil, { OwnsElements = owns })
		track(slot, "Slot")
		table.insert(n.lists, { data = data, owns = owns })
		return slot
	end

	build = function(depth)
		local class = pick({ "Frame", "Frame", "TextButton", "TextLabel", "TextBox" })
		local n = newNode(depth, class)
		n.lists = {}
		local props = { Name = "n" .. n.id }
		local a = {}
		local isText = class ~= "Frame"
		-- properties
		if P(0.4) then props.LayoutOrder = pick({ G.pulse, G.pulse:Compute(function(s) return s:Get() * 2 end), G.pulse:Apply(G.blocker) }) end
		if isText and P(0.6) then
			local r = R(5)
			if r == 1 then props.Text = G.text
			elseif r == 2 then props.Text = bag:Get(G.P1)
			elseif r == 3 then props.Text = track(G.text:Apply(q.Debounce({ Time = pick({ 0.5, 1, 2 }), Leading = P(0.5) })), "gate")
			elseif r == 4 then props.Text = track(G.text:Apply(q.Throttle({ Time = pick({ 0.5, 1 }) })), "gate")
			else n.localText = track(q.Source("x"), "Source"); props.Text = n.localText end
		end
		if P(0.3) then
			n.sizeSrc = track(q.Source(1), "Source")
			if P(0.5) then
				props.Size = n.sizeSrc:Compute(function(s)
					return track(q.Tween({ Value = s:Get(), Time = 1,
						Started = function() n.c.S += 1; T.tweenCb.S += 1; post("tweenStarted") end,
						Completed = function() n.c.Cm += 1; T.tweenCb.C += 1; post("tweenCompleted") end,
						Cancelled = function() n.c.X += 1; T.tweenCb.X += 1; post("tweenCancelled") end }), "tween")
				end)
			else
				props.Size = n.sizeSrc:Apply(q.Animate({ Time = 1 }))
			end
		end
		if class == "TextButton" and P(0.7) then
			local up = n
			props.Activated = function() up.c.act = (up.c.act or 0) + 1; post("event") end
			n.button = true
		end
		if class == "TextBox" then
			if P(0.5) then
				n.outSrc = n.outSrc or track(q.Source("o"), "Source")
				table.insert(a, track(q.Out("Text", n.outSrc), "out"))
			end
			if P(0.5) then table.insert(a, track(q.OnChange("Text", function() post("onchange") end), "onchange")) end
			n.box = true
		end
		-- tag / attr
		if P(0.5) then table.insert(a, q.Tag(pick(TAGS))) end
		if P(0.4) then table.insert(a, q.Attr({ [pick(ATTRS)] = if P(0.5) then G.pulse else n.id })) end
		if P(0.3) then props[q.AttrKey(pick(ATTRS) .. "k")] = n.id end
		-- modifier
		if P(0.3) then table.insert(a, track(q.Modifier({ BackgroundTransparency = 0.5, ZIndex = G.pulse }), "Modifier")) end
		-- refs
		if P(0.3) then local r = track(q.Ref(nil), "Ref"); r:Callback(function() post("ref") end); table.insert(a, r) end
		if P(0.2) then table.insert(a, track(q.PreRef(), "PreRef")) end
		if P(0.2) then table.insert(a, track(q.PostRef(), "PostRef")) end
		-- observer / effect
		if P(0.5) then table.insert(a, track(G.pulse:Observer(function() post("observer") end), "Observer")) end
		if P(0.3) then
			local h = if P(0.5) then q.Ref(nil) else nil
			local fac = if P(0.5) then q.Debounce({ Time = pick({ 0.5, 1 }), Leading = P(0.5), MaxTime = if P(0.5) then 2 else nil, Handle = h })
				else q.Throttle({ Time = pick({ 0.5, 1 }), Leading = P(0.5), Handle = h })
			local ob = track(G.pulse:Apply(fac):Observer(function() post("debObserver") end), "Observer")
			if MUT == "strongSub" then ob:Subscribe() else table.insert(a, ob) end
			if h and P(0.5) then table.insert(a, q.OnDestroyed(function() if h.Value then h.Value:Cancel() end end)) end
		end
		-- State seats holding handles/descriptors (swapped during the run)
		if P(0.25) then
			local r = R(5)
			local mk
			if r == 1 then mk = function() return q.Tag(pick(TAGS)) end
			elseif r == 2 then mk = function() return q.Attr({ [pick(SEATATTRS)] = R(9) }) end
			elseif r == 3 then mk = function() return track(G.pulse:Observer(function() post("seatObserver") end), "Observer") end
			elseif r == 4 then mk = function()
				return track(q.Effect(function()
					n.c.seatEffRun = (n.c.seatEffRun or 0) + 1
					return function() n.c.seatEffCl = (n.c.seatEffCl or 0) + 1 end
				end), "Effect")
			end
			else mk = if isText then function() return track(q.OnChange("Text", function() post("seatOnChange") end), "onchange") end else function() return q.Tag(pick(TAGS)) end end
			n.hseat = track(q.Source(mk()), "Source")
			n.hseatMk = mk
			table.insert(a, n.hseat)
		end
		if P(0.5) then
			n.eff = true
			local ef = q.Effect(function()
				n.c.effRun += 1; T.effRuns += 1
				post("effectFn")
				local fn = function() post("extSig") end
				seedConnFns[fn] = true
				local c = G.extSig:Connect(fn)
				return function(dying)
					n.c.effCl += 1
					if dying then n.c.effDyingT += 1 end
					if MUT ~= "skipCleanup" then c:Disconnect() end
					-- a non-dying cleanup that throws kills the Effect (core/05, E55): no dying cleanup follows
					if not dying and n.action == "throw" and phase ~= "post" then n.c.effKilled = true end
					if phase ~= "post" then cbAction(n) end
				end
			end, G.flag)
			table.insert(a, track(ef, "Effect"))
		end
		-- hooks
		if P(0.3) then table.insert(a, q.OnCreated(function() end)) end
		if P(0.3) then table.insert(a, q.OnRendered(function() end)) end
		if P(0.4) then n.od = true; T.odHooks += 1; table.insert(a, q.OnDestroyed(function() n.c.od += 1; post("onDestroyed"); if phase ~= "post" then cbAction(n) end end)) end
		-- dispose-from-callback trigger: an Observer on G.kill disposes the root (root always, others at random)
		if depth == 1 and td == "fromEvent" then
			table.insert(a, D.TextButton({ Name = "closeBtn", Activated = function() op("disposeInCb", function() q.dispose(rootBox.v) end) end }))
		elseif depth == 1 and td == "fromOnChange" then
			table.insert(a, D.TextBox({ Name = "closeBox", q.OnChange("Text", function(v) if v == "close" then op("disposeInCb", function() q.dispose(rootBox.v) end) end end) }))
		elseif depth == 1 and td == "fromTween" then
			rootFade = q.Source(0)
			props.BackgroundTransparency = rootFade:Compute(function(s)
				local v = s:Get()
				return q.Tween({ Value = v, Time = 0.3, Completed = function() if v == 1 then op("disposeInCb", function() q.dispose(rootBox.v) end) end end })
			end)
		end
		if depth == 1 and td == "fromTimer" then
			-- toast-style auto dismiss: a debounced trigger's Observer (fires from the timer) disposes the root
			rootTimerSrc = q.Source(0)
			table.insert(a, rootTimerSrc:Apply(q.Debounce({ Time = 0.7 })):Observer(function(st)
				if st:Get() == 1 then op("disposeInCb", function() q.dispose(rootBox.v) end) end
			end))
		elseif depth == 1 and td == "fromOnRendered" then
			-- a Slot declared in root's own props; at teardown a self-closing child is Added into it
			rootKillSlot = q.Slot()
			table.insert(a, rootKillSlot)
		end
		if td == "fromCallback" and (depth == 1 or P(0.2)) then
			table.insert(a, G.kill:Observer(function()
				if killSeen and rootBox.v and not mock.isDestroyed(rootBox.v) then op("disposeInCb", function() q.dispose(rootBox.v) end) end
			end))
		end
		-- children
		if depth < 4 then
			local nk = R(3) - (depth >= 3 and 1 or 0)
			for _ = 1, nk do
				local mode = pick({ "static", "static", "slot", "list", "single", "seat", "nested", "fallback" })
				if mode == "static" then table.insert(a, build(depth + 1).inst)
				elseif mode == "slot" then
					local els = {}
					for _ = 1, R(3) - 1 do table.insert(els, build(depth + 1).inst) end
					n.slot = track(q.Slot(els), "Slot"); table.insert(a, n.slot)
					n.slotDepth = depth
				elseif mode == "list" then table.insert(a, makeListSlot(n, depth))
				elseif mode == "single" then
					n.singleSrc = track(q.Source(R(3)), "Source")
					table.insert(a, track(q.Slot():Single(n.singleSrc, function(ctx)
						if ctx.Item == q.KeyGone then return nil end
						return build(depth + 1).inst
					end), "Slot"))
				elseif mode == "seat" then
					n.seat = track(q.Source(build(depth + 1).inst), "Source")
					n.seatDepth = depth
					table.insert(a, n.seat)
				elseif mode == "nested" then
					local inner = track(q.Slot({ build(depth + 1).inst }), "Slot")
					local outer = track(q.Slot({ inner, build(depth + 1).inst }), "Slot")
					table.insert(a, outer)
				elseif mode == "fallback" then
					local Comp = q.Fallback(function(bad)
						if bad then T.fbThrows += 1; error("boom-fb") end
						return build(depth + 1).inst
					end, function() return build(depth + 1).inst end)
					table.insert(a, Comp(P(0.3)))
				end
			end
		end
		for i = #a, 2, -1 do local j = R(i); a[i], a[j] = a[j], a[i] end
		for i, v in a do props[i] = v end
		n.inst = D[class](props)
		track(n.inst, "inst")
		return n
	end

	-- ---------------- build
	plainArmed = true
	td = TEARDOWNS[R(#TEARDOWNS)]
	local ok, e = op("build", function() rootNode = build(1) end)
	if not ok then
		if VERB then print("seed", seed, "build failed", H.first(e)) end
		return
	end
	local root = rootNode.inst
	rootBox.v = root
	T.nodes += #nodes
	if #nodes > T.maxNodes then T.maxNodes = #nodes end
	bump(T.teardowns, td)
	if MUT == "holdStrong" and #nodes >= 2 then table.insert(strongHold, nodes[#nodes].inst) end
	local helper
	if td == "fromCleanup" then
		local armed = false
		helper = D.Frame({ Name = "helper", q.Effect(function()
			local on = G.flag:Get()
			return function(dying) if armed and not dying then op("disposeInCb", function() q.dispose(rootBox.v) end) end end
		end, G.flag) })
		helper.Parent = G.app
		rootBox.arm = function() armed = true end
	end
	-- mount
	if td == "seatNil" then op("mount", function() G.appSeat:Set(root) end)
	elseif td == "clear" or td == "extractAll" or td == "remove" then op("mount", function() G.appSlot:Add(root) end)
	else root.Parent = G.app end

	-- ---------------- interactions
	phase = "run"
	local steps = 10 + R(30)
	T.steps += steps
	local function flushUserOwned()
		while #pendingDispose > 0 do
			local v = table.remove(pendingDispose)
			op("userDispose", function() if not mock.isDestroyed(v) then q.dispose(v) end end)
		end
	end
	for _ = 1, steps do
		local r = R(12)
		local n = nodes[R(#nodes)]
		local alive = n.inst and not mock.isDestroyed(n.inst)
		if r == 1 then op("pulse", function() G.pulse:Set(G.pulse:Get() + 1) end)
		elseif r == 2 then op("text", function() G.text:Set("t" .. R(9)) end)
		elseif r == 3 then op("flag", function() G.flag:Set(not G.flag:Get()) end)
		elseif r == 4 then op("clock", function() H.runTask(pick({ 0.3, 1, 2.5 })) end)
		elseif r == 5 and alive and n.button then op("fire", function() n.inst.Activated:Fire() end)
		elseif r == 6 and alive and n.box then op("extWrite", function() n.inst.Text = "ext" .. R(99) end)
		elseif r == 7 and #n.lists > 0 then
			local L = pick(n.lists)
			local keys = {}
			for k = 1, 5 do if P(0.5) then table.insert(keys, k) end end
			for i = #keys, 2, -1 do local j = R(i); keys[i], keys[j] = keys[j], keys[i] end
			op("listChurn", function() L.data:Set(keys) end)
		elseif r == 8 and n.singleSrc then op("single", function() n.singleSrc:Set(R(3)) end)
		elseif r == 9 and n.seat and alive then
			local old = n.seat:Get()
			local nv
			if P(0.7) then op("buildSeat", function() nv = build(n.seatDepth + 1).inst end) end
			op("seatSwap", function() n.seat:Set(nv) end)
			if old then table.insert(pendingDispose, old) end -- State<Instance?>: the program owns the detached child
		elseif r == 10 and n.hseat and alive and P(0.5) then op("hseatSwap", function() n.hseat:Set(if P(0.3) then nil else n.hseatMk()) end)
		elseif r == 10 then op("blocker", function() if G.blocker.Blocking then G.blocker:Off() else G.blocker:On() end end)
		elseif r == 11 and n.sizeSrc then op("size", function() n.sizeSrc:Set(n.sizeSrc:Get() + 1) end)
		elseif r == 12 and #mock.tweenLog > 0 then
			local tw = pick(mock.tweenLog).tween
			if tw.PlaybackState == "Playing" then op("tweenDone", function() tw:simulateCompleted() end) end
		elseif n.slot and alive then
			local s = n.slot
			if s.Length:Get() > 0 and P(0.5) then
				if P(0.5) then op("slotRemove", function() s:Remove(R(s.Length:Get())) end)
				else local ok2, el = op("slotExtract", function() return s:Extract(R(s.Length:Get())) end); if ok2 and el then table.insert(pendingDispose, el) end end
			else
				op("slotAdd", function() s:Add(build(n.slotDepth + 1).inst) end)
			end
		end
		if n.localText and P(0.2) then op("localText", function() n.localText:Set("l" .. R(9)) end) end
		flushUserOwned()
	end
	if G.blocker.Blocking and P(0.6) then op("blockerOff", function() G.blocker:Off() end) end
	if not G.blocker.Blocking and P(0.2) then op("blockerOn", function() G.blocker:On(); G.pulse:Set(G.pulse:Get() + 1); G.text:Set("blk") end) end

	-- ---------------- teardown
	phase = "wave"
	local t0 = os.clock()
	if td == "dispose" then op("td", function() q.dispose(root) end)
	elseif td == "destroy" then op("td", function() root:Destroy() end)
	elseif td == "seatNil" then op("td", function() G.appSeat:Set(nil) end); op("td2", function() q.dispose(root) end)
	elseif td == "clear" then op("td", function() G.appSlot:Clear() end)
	elseif td == "extractAll" then
		local ok2, els = op("td", function() return G.appSlot:ExtractAll() end)
		if ok2 then for _, el in els do op("td2", function() q.dispose(el) end) end end
	elseif td == "remove" then op("td", function() G.appSlot:Remove(G.appSlot:IndexOf(root)) end)
	elseif td == "fromCallback" then killSeen = true; op("td", function() G.kill:Set(G.kill:Get() + 1) end)
	elseif td == "fromEvent" then op("td", function() root:FindFirstChild("closeBtn").Activated:Fire() end)
	elseif td == "fromOnChange" then op("td", function() root:FindFirstChild("closeBox").Text = "close" end)
	elseif td == "fromTween" then
		op("td", function() rootFade:Set(1) end)
		for _, rec in table.clone(mock.tweenLog) do
			if rec.inst == root and rec.tween.PlaybackState == "Playing" then op("td2", function() rec.tween:simulateCompleted() end) end
		end
	elseif td == "fromTimer" then op("td", function() rootTimerSrc:Set(1) end); op("td2", function() H.runTask(1) end)
	elseif td == "fromOnRendered" then
		-- rebuild-style: a fresh component under the root that disposes the root from its OnRendered
		-- (an earlier version used Dispatch.drive(root, { slot }) here: that re-processes root's numeric position 1 and
		-- retracts whatever the generator put there — cleanup(false)/lost OnDestroyed; harness artifact, see probe)
		op("td", function()
			rootKillSlot:Add(D.Frame({ Name = "selfClose", q.OnRendered(function() q.dispose(rootBox.v) end) }))
		end)
	elseif td == "fromCleanup" then rootBox.arm(); op("td", function() G.flag:Set(not G.flag:Get()) end)
	end
	flushUserOwned()
	C.tdTime = os.clock() - t0
	if helper then op("helperDispose", function() q.dispose(helper) end) end
	if not mock.isDestroyed(root) then T.tdMissed = (T.tdMissed or 0) + 1; bump(T.tdMissedBy, td); if VERB then print("  missed", seed, td, G.blocker.Blocking) end; op("fallbackDispose", function() q.dispose(root) end) end
	phase = "post"

	-- ---------------- post-teardown probes (invariant 2): engine completes tweens, globals move, clock runs
	for _, rec in table.clone(mock.tweenLog) do
		if rec.tween.PlaybackState == "Playing" then op("postTween", function() rec.tween:simulateCompleted() end) end
	end
	op("postPulse", function() G.pulse:Set(G.pulse:Get() + 1) end)
	op("postText", function() G.text:Set("post" .. seed) end)
	op("postFlag", function() G.flag:Set(not G.flag:Get()) end)
	op("postExt", function() G.extSig:Fire() end)
	op("postBlk", function() G.blocker:On(); G.blocker:Off() end)
	op("postTheme", function() themeSrc:Set("post") end)
	op("postClock", function() H.runTask(10) end)

	-- ---------------- invariant checks
	local viol = {}
	-- (2) extSig connections owned by this seed
	local liveSeedConns = 0
	for _, c in G.extSig.connections do if seedConnFns[c.fn] then liveSeedConns += 1 end end
	if liveSeedConns > 0 then T.inv2conn += 1; table.insert(viol, "extConn=" .. liveSeedConns) end
	-- (2) instance signals of every node inst
	local notDestroyed, instConns = 0, 0
	for _, n in nodes do
		if n.inst then
			if not mock.isDestroyed(n.inst) then notDestroyed += 1 end
			instConns += #n.inst.Destroying.connections
			if n.button then instConns += #n.inst.Activated.connections end
		end
	end
	if notDestroyed > 0 then T.inv4notDestroyed += 1; table.insert(viol, "notDestroyed=" .. notDestroyed) end
	if instConns > 0 then T.inv2instconn += 1; table.insert(viol, "instConns=" .. instConns) end
	if (C.post or 0) > 0 then
		T.inv2post += 1
		local ks = {}
		for k, v in C.postKinds do bump(T.inv2postKinds, k, v); table.insert(ks, k .. ":" .. v) end
		table.insert(viol, "postCb{" .. table.concat(ks, ",") .. "}")
	end
	if H.pending() > 0 then T.inv2timers += 1; table.insert(viol, "pendingTimers=" .. H.pending()) end
	local liveTweenConns = 0
	for _, rec in mock.tweenLog do liveTweenConns += #rec.tween.Completed.connections end
	if liveTweenConns > 0 then T.inv2tweenConn += 1; table.insert(viol, "tweenConns=" .. liveTweenConns) end
	-- (4) cleanups / hooks
	local effBad, dyingBad, odBad, twBad = 0, 0, 0, 0
	for _, n in nodes do
		if n.eff then
			if n.c.effRun ~= n.c.effCl then effBad += 1 end
			if n.c.effDyingT ~= (if n.c.effKilled then 0 else 1) then dyingBad += 1; if VERB then print("  dying node", n.id, n.c.effRun, n.c.effCl, n.c.effDyingT, n.c.effKilled) end end
		end
		if n.od and n.c.od ~= 1 then odBad += 1 end
		if (n.c.seatEffRun or 0) ~= (n.c.seatEffCl or 0) then effBad += 1 end
		if n.c.Cm + n.c.X > n.c.S then twBad += 1 end
	end
	if effBad > 0 then T.inv4eff += 1; table.insert(viol, "effRun~=cleanup:" .. effBad) end
	if dyingBad > 0 then T.inv4dying += 1; table.insert(viol, "dyingTrue~=1:" .. dyingBad) end
	if odBad > 0 then T.inv4od += 1; table.insert(viol, "onDestroyed~=1:" .. odBad) end
	if twBad > 0 then T.inv4tween += 1; table.insert(viol, "tweenEnd>Start:" .. twBad) end
	T.insts += #nodes
	-- (1) GC: drop everything this seed holds, clear mock tweenLog (mock limit M2), drain timers
	nodes = nil; rootNode = nil; root = nil; rootBox = nil; rootFade = nil; rootTimerSrc = nil; rootKillSlot = nil; helper = nil; bag = nil; themeSrc = nil; pendingDispose = nil
	for _ in tracker do T.tracked = (T.tracked or 0) + 1 end
	mock.resetTweenLog()
	fullgc()
	local surv, byKind = 0, {}
	for _, kind in tracker do surv += 1; bump(byKind, kind) end
	if surv > 0 then
		T.inv1 += 1
		for k, v in byKind do bump(T.inv1Kinds, k, v) end
		if #T.inv1Seeds < 12 then table.insert(T.inv1Seeds, seed) end
		local ks = {}
		for k, v in byKind do table.insert(ks, k .. ":" .. v) end
		table.sort(ks)
		table.insert(viol, "gcSurvivors{" .. table.concat(ks, ",") .. "}")
	end
	-- (3) errors raised anywhere (ops already classified) + isolated handler errors
	for _, he in handlerErrs do
		local kind = classify(he, "handler")
		if kind == "noid" then T.inv3noid += 1; table.insert(viol, "noidHandlerErr") end
	end
	plainArmed = false
	-- (5) cross-tree residue: pristine canonical trace in the same q
	local ok5, tr = pcall(canon, q, D, G)
	if not ok5 then tr = "CANON-ERR " .. H.first(tr) end
	if tr ~= BASE_CANON then
		T.inv5 += 1
		if #T.inv5Samples < 3 then table.insert(T.inv5Samples, "seed " .. seed .. ": " .. tr) end
		table.insert(viol, "canonDiff")
	end
	T.seeds += 1
	if VERB or (#viol > 0 and T.seeds <= 5000 and MUT == "none" and #viol > 0 and (T.printed or 0) < 25) then
		T.printed = (T.printed or 0) + 1
		print(string.format("seed %d td=%s nodes=%d viol: %s", seed, td, T.insts, table.concat(viol, " ")))
	end
end

-- ---------------------------------------------------------------- baseline canon: same q (pristine) and a fresh module
BASE_CANON = canon(q, D, G)
do
	local q2 = H.Quad.New():UseProvider(H.QuadRoblox)
	q2.Backend.isInst = mock.isMockInstance
	local G2 = {
		pulse = q2.Source(0), text = q2.Source("t"), flag = q2.Source(true), blocker = q2.Blocker(), extSig = mock.newSignal(),
		P1 = q2.Context.Provider("Theme"),
	}
	local ok, fresh = pcall(canon, q2, q2.Declaration, G2)
	print("canon same-q  :", BASE_CANON)
	print("canon fresh-q :", ok and fresh or ("ERR " .. H.first(fresh)))
	print("canon equal   :", ok and fresh == BASE_CANON)
end

local t0 = os.clock()
for s = FIRST, FIRST + COUNT - 1 do runSeed(s) end
local el = os.clock() - t0

local function fmt(t)
	local ks = {}
	for k, v in t do table.insert(ks, k .. "=" .. v) end
	table.sort(ks)
	return table.concat(ks, " ")
end
print(string.format("\n== E77 seeds %d..%d mutation=%s  (%.1fs)", FIRST, FIRST + COUNT - 1, MUT, el))
print(string.format("seeds=%d nodes=%d (max %d/seed) steps=%d", T.seeds, T.nodes, T.maxNodes, T.steps))
print("teardowns:", fmt(T.teardowns))
print("teardown trigger missed (root not destroyed by the path; disposed after):", T.tdMissed or 0, fmt(T.tdMissedBy))
print("tracked objects (pre-GC, total):", T.tracked or 0)
print(string.format("(1) GC survivors: seeds=%d kinds{%s} firstSeeds=%s", T.inv1, fmt(T.inv1Kinds), table.concat(T.inv1Seeds, ",")))
print(string.format("(2) live ext conns seeds=%d | inst signal conns=%d | post-teardown callbacks seeds=%d {%s} | pending timers=%d | live tween Completed conns=%d",
	T.inv2conn, T.inv2instconn, T.inv2post, fmt(T.inv2postKinds), T.inv2timers, T.inv2tweenConn))
print(string.format("(3) errors total=%d user=%d quad{%s} noid-handler seeds=%d", errStats.total, errStats.user, fmt(errStats.quad), T.inv3noid))
for k, v in errStats.noid do print("    noid:", v, k) end
print(string.format("(4) effect run~=cleanup=%d dying~=1=%d onDestroyed~=1=%d tween end>start=%d not-destroyed=%d | effRuns=%d odHooks=%d tweenCb S=%d C=%d X=%d",
	T.inv4eff, T.inv4dying, T.inv4od, T.inv4tween, T.inv4notDestroyed, T.effRuns, T.odHooks, T.tweenCb.S, T.tweenCb.C, T.tweenCb.X))
print(string.format("(5) canon diff seeds=%d", T.inv5))
for _, s in T.inv5Samples do print("   ", s) end
print("fallback throws:", T.fbThrows)
