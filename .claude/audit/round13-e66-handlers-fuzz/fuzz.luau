--!nocheck
-- E66 differential fuzzer: quad-roblox handlers (Event / OnChange / InstanceChild / InstanceShorthand / Property)
-- as connection + property-write bookkeeping, vs an independent reference model.
-- mutants: evdedup | retractkeeps | shdestroy | propdedup | evnilkeeps | hashfirst
-- usage (repo root):  mise exec -- luau .claude/audit/round13-e66-handlers-fuzz/fuzz.luau -a <seeds> <start> [mutant] [v]
-- Model rules (doc line / code line each encodes):
--  M1 Event seat: effective fn -> exactly one live connection on inst[k] whose fn IS that value
--     (roblox/02-d.md:133-136; Event.luau:81). nil/None -> zero connections (02-d:134; Event.luau:75-76).
--  M2 every Event (re-)process mints a NEW connection, even for the same fn — no dedup (02-d:136; Event.luau:29-32)
--  M3 non-function at an Event seat -> Quad0218; the seat ends empty (old retracted first — dispatch R5/R6)
--  M4 retractFrom(inst,k,1) disconnects (Event.luau:82-84; OnChange.luau:221-223)
--  M5 OnChange seat: one connection on GetPropertyChangedSignal(Name) per seat holding a descriptor; same
--     descriptor/name in two seats = two connections (05-onchange.md:83-84); each write delivers inst[Name]
--  M6 array part before hash part on drive (05-onchange.md:76-78, F-4-1)
--  M7 InstanceChild: child.Parent = host while seated; swap/retract -> Parent nil, not destroyed (InstanceChild.luau:82-90);
--     same child re-emitted -> no detach (H-154 dedup, :86-88)
--  M8 Property plain value: every emit writes, same value included (02-d.md:112 "발행될 때마다 다시 쓴다"; Property.luau:336)
--     None -> writes nil (02-d.md:114). retract leaves the value (Property retractor non-tween no-op)
--  M9 Shorthand UIScale: number -> managed child `_quad_scale` exists, Scale written every emit; nil/None destroys it
--     (02-d.md:323); retractFrom leaves it (Void, H-135)
--  M10 host Destroy: every engine connection gone; StoreBind observers unbound -> later Set touches nothing
--     (StoreBind bindLifetime); descendants (seated children, managed child) destroyed
local E = require("./env")
local RNG = require("./rng")
local args = { ... }
local SEEDS = tonumber(args[1]) or 200
local START = tonumber(args[2]) or 1
local MUT = args[3] ~= "v" and args[3] or nil
local VERBOSE = args[3] == "v" or args[4] == "v"

local EVENTS = { "Activated", "MouseEnter" }
local DESCNAMES = { "Text", "Visible" }
local stats = { seeds = 0, ops = 0, diffs = 0, errs = {}, opsBy = {}, fires = 0, deliveries = 0, conns = 0 }
local samples = {}
local function bump(t, k) t[k] = (t[k] or 0) + 1 end

local function runSeed(seed)
	local rng = RNG.new(seed)
	local q = E.newProv()
	local D = q.Declaration
	local None = q.None
	local diffs = {}
	local function diff(msg) table.insert(diffs, msg) end

	-- ── value pools ──
	local fnId, nextFn = {}, 0
	local cblog = {} -- list of "fnId" (events) or "d<id>=<val>" (onchange)
	local function newFn()
		nextFn += 1
		local id = nextFn
		local f = function() table.insert(cblog, "f" .. id) end
		fnId[f] = id
		return f
	end
	local descId, nextD = {}, 0
	local function newDesc(name)
		nextD += 1
		local id = nextD
		local inst -- filled lazily: callback receives value
		local d = q.OnChange(name, function(v) table.insert(cblog, "d" .. id .. "=" .. tostring(v)) end)
		descId[d] = { id = id, name = name }
		return d
	end
	local fns = { newFn(), newFn() }
	local function pickFn() if rng:NextNumber() < 0.5 then local f = newFn(); table.insert(fns, f); return f end return fns[rng:NextInteger(1, #fns)] end

	-- Sources by domain
	local srcs = {} -- { s, dom, val }
	local function mkSrc(dom, v) local s = q.Source(v); local r = { s = s, dom = dom, val = v, n = #srcs + 1 }; table.insert(srcs, r); return r end
	for _ = 1, 2 do mkSrc("ev", fns[1]) end
	mkSrc("desc", None); mkSrc("desc", None)
	mkSrc("text", "t0")
	mkSrc("scale", 1)

	-- ── instances ──
	local insts = {} -- slot -> rec
	local SEATS = { "Activated", "MouseEnter", "Text", "UIScale", 1, 2, 3 }
	local function seatDom(k)
		if k == "Activated" or k == "MouseEnter" then return "ev" end
		if k == "Text" then return "text" end
		if k == "UIScale" then return "scale" end
		return (k == 3) and "child" or "desc"
	end
	-- model seat: { eff = value|nil, bound = srcRec|nil, epoch = n }
	local function newRec(inst)
		local rec = { inst = inst, alive = true, seats = {}, text = nil, textWrites = 0, extWrites = 0, managed = nil,
			children = { inst and nil }, lastConn = {}, epoch = {} }
		for _, k in SEATS do rec.seats[k] = { eff = nil, bound = nil }; rec.epoch[k] = 0 end
		rec.kids = { D.Frame({ Name = "k1" }), D.Frame({ Name = "k2" }) } -- seat 3 exclusive children
		return rec
	end
	local function attachCounter(rec)
		rec.inst:GetPropertyChangedSignal("Text"):Connect(function() rec.textWrites += 1 end)
	end
	-- seat-3 child sources are per instance (exclusive children)
	local function childSrc(rec)
		if rec.csrc == nil then rec.csrc = mkSrc("child", nil); rec.csrc.owner = rec end
		return rec.csrc
	end

	local function unwrapNone(v) if v == None then return nil end return v end

	-- model: apply effective value v at seat k of rec (after StoreBind unwrap); returns expected error id or nil
	local function mTextWrite(rec, v)
		rec.text = v
		-- OnChange Text seats fire with the new value
		for _, k in { 1, 2 } do
			local d = rec.seats[k].eff
			if d ~= nil and descId[d] and descId[d].name == "Text" then
				table.insert(rec.expectLog, "d" .. descId[d].id .. "=" .. tostring(v))
			end
		end
	end
	local function mApply(rec, k, v)
		local seat = rec.seats[k]
		local dom = seatDom(k)
		v = unwrapNone(v)
		if dom == "ev" then
			if v ~= nil and type(v) ~= "function" then seat.eff = nil; return "Quad0218" end
			if MUT == "evnilkeeps" and v == nil then return nil end
			if MUT == "evdedup" and v ~= nil and v == seat.eff then return nil end
			seat.eff = v
			if v ~= nil then rec.epoch[k] += 1 end
		elseif dom == "desc" then
			seat.eff = v
		elseif dom == "text" then
			seat.eff = v
			if MUT ~= "propdedup" or v ~= rec.text or rec.textWrites == 0 then
				rec.expectWrites += 1
				mTextWrite(rec, v)
			end
		elseif dom == "scale" then
			seat.eff = v
			if v == nil then
				rec.managed = nil
			else
				rec.managed = v
				rec.scaleProcessed = true
			end
		elseif dom == "child" then
			seat.eff = v
		end
		return nil
	end
	local function mRetract(rec, k)
		local seat = rec.seats[k]
		seat.bound = nil
		local dom = seatDom(k)
		if dom == "ev" then if MUT ~= "retractkeeps" then seat.eff = nil end
		elseif dom == "desc" or dom == "child" then seat.eff = nil
		elseif dom == "scale" then seat.eff = nil; if MUT == "shdestroy" then rec.managed = nil end
		elseif dom == "text" then seat.eff = nil end
	end

	-- ── checks ──
	local function check(tag)
		for slot, rec in insts do
			local inst = rec.inst
			local pfx = tag .. " i" .. slot .. " "
			if rec.alive then
				for _, ev in EVENTS do
					local conns = inst[ev].connections
					local eff = rec.seats[ev].eff
					local want = eff ~= nil and 1 or 0
					if #conns ~= want then diff(pfx .. ev .. " conns " .. #conns .. " want " .. want)
					elseif want == 1 then
						if conns[1].fn ~= eff then diff(pfx .. ev .. " fn f" .. tostring(fnId[conns[1].fn]) .. " want f" .. tostring(fnId[eff])) end
						local prev = rec.lastConn[ev]
						if prev ~= nil and prev.epoch == rec.epoch[ev] and prev.conn ~= conns[1] then diff(pfx .. ev .. " conn changed without re-process") end
						if prev ~= nil and prev.epoch ~= rec.epoch[ev] and prev.conn == conns[1] then diff(pfx .. ev .. " conn NOT renewed on re-process") end
						rec.lastConn[ev] = { epoch = rec.epoch[ev], conn = conns[1] }
					end
					stats.conns += #conns
				end
				for _, nm in DESCNAMES do
					local want = 0
					for _, k in { 1, 2 } do local d = rec.seats[k].eff; if d ~= nil and descId[d].name == nm then want += 1 end end
					local got = #inst:GetPropertyChangedSignal(nm).connections - (nm == "Text" and 1 or 0)
					if got ~= want then diff(pfx .. "OnChange " .. nm .. " conns " .. got .. " want " .. want) end
				end
				-- children
				local wantKids = {}
				local c = rec.seats[3].eff
				if c ~= nil then wantKids[c] = true end
				local mc = inst:FindFirstChild("_quad_scale")
				for _, ch in inst:GetChildren() do
					if ch.Name ~= "_quad_scale" and not wantKids[ch] then diff(pfx .. "unexpected child " .. ch.Name) end
				end
				if c ~= nil and c.Parent ~= inst then diff(pfx .. "seat3 child not parented") end
				for _, kid in rec.kids do
					if kid ~= c and kid.Parent ~= nil then diff(pfx .. "kid " .. kid.Name .. " not detached") end
					if E.mock.isDestroyed(kid) then diff(pfx .. "kid destroyed while host alive") end
				end
				if (rec.managed ~= nil) ~= (mc ~= nil) then diff(pfx .. "managed child exists=" .. tostring(mc ~= nil) .. " want " .. tostring(rec.managed ~= nil))
				elseif mc ~= nil and mc.Scale ~= rec.managed then diff(pfx .. "Scale " .. tostring(mc.Scale) .. " want " .. tostring(rec.managed)) end
				if #inst:GetChildren() > (c and 1 or 0) + (mc and 1 or 0) then diff(pfx .. "extra children " .. #inst:GetChildren()) end
				-- property
				if rec.textWrites ~= rec.expectWrites + rec.extWrites then diff(pfx .. "Text writes " .. rec.textWrites .. " want " .. (rec.expectWrites + rec.extWrites)) end
				if rec.expectWrites > 0 and inst.Text ~= rec.text then diff(pfx .. "Text " .. tostring(inst.Text) .. " want " .. tostring(rec.text)) end
			else
				for _, ev in EVENTS do if #inst[ev].connections ~= 0 then diff(pfx .. "dead " .. ev .. " conns " .. #inst[ev].connections) end end
				for _, nm in DESCNAMES do if #inst:GetPropertyChangedSignal(nm).connections ~= 0 then diff(pfx .. "dead OnChange conns") end end
			end
		end
		-- callback log
		local want = {}
		for _, rec in insts do for _, x in rec.expectLog do table.insert(want, x) end; table.clear(rec.expectLog) end
		table.sort(want); local got = table.clone(cblog); table.sort(got); table.clear(cblog)
		if table.concat(want, ",") ~= table.concat(got, ",") then diff(tag .. " callbacks got [" .. table.concat(got, ",") .. "] want [" .. table.concat(want, ",") .. "]") end
	end

	local function newInstAt(slot, props, mprops)
		local ok, inst = pcall(function() return D.TextButton(props) end)
		if not ok then diff("create raised " .. E.id(inst)); return end
		local rec = mprops.rec
		rec.inst = inst
		insts[slot] = rec
		attachCounter(rec)
	end

	-- bind model for a seat to a src
	local function mBind(rec, k, sr)
		for _, other in srcs do if other.binds then other.binds[rec] = other.binds[rec] end end
		rec.seats[k].bound = sr
		sr.binds = sr.binds or {}
		sr.binds[rec] = sr.binds[rec] or {}
		sr.binds[rec][k] = true
		return mApply(rec, k, sr.val)
	end
	local function mUnbindSeat(rec, k)
		local b = rec.seats[k].bound
		if b and b.binds and b.binds[rec] then b.binds[rec][k] = nil end
		rec.seats[k].bound = nil
	end

	-- value for a seat (direct process); returns runtime value, and model thunk
	local function pickValue(rec, k)
		local dom = seatDom(k)
		local r = rng:NextNumber()
		local sr
		if r < 0.3 then
			-- bind a Source of that domain
			local cands = {}
			for _, s in srcs do if s.dom == dom and (dom ~= "child" or s.owner == rec) then table.insert(cands, s) end end
			if dom == "child" then table.insert(cands, childSrc(rec)) end
			sr = cands[rng:NextInteger(1, #cands)]
			return sr.s, sr
		end
		if r < 0.42 then return None end
		if r < 0.5 and type(k) == "string" then return nil end
		if dom == "ev" then
			if rng:NextNumber() < 0.08 then return 5 end
			return pickFn()
		elseif dom == "desc" then return newDesc(DESCNAMES[rng:NextInteger(1, 2)])
		elseif dom == "text" then return "v" .. rng:NextInteger(1, 3)
		elseif dom == "scale" then return rng:NextInteger(1, 3)
		else return rec.kids[rng:NextInteger(1, 2)] end
	end

	local function srcValue(sr)
		local dom = sr.dom
		local r = rng:NextNumber()
		if r < 0.15 then return None end
		if r < 0.25 and dom ~= "desc" then return nil end
		if dom == "ev" then return pickFn()
		elseif dom == "desc" then return newDesc(DESCNAMES[rng:NextInteger(1, 2)])
		elseif dom == "text" then return "s" .. rng:NextInteger(1, 3)
		elseif dom == "scale" then return rng:NextInteger(1, 3)
		else local owner = sr.owner; return owner.kids[rng:NextInteger(1, 2)] end
	end

	local NINST = rng:NextInteger(2, 3)
	for slot = 1, NINST do
		local rec = newRec(nil); rec.expectLog = {}; rec.expectWrites = 0
		newInstAt(slot, { None, None, None }, { rec = rec })
	end
	check("init")

	local nops = rng:NextInteger(20, 60)
	for step = 1, nops do
		stats.ops += 1
		local slot = rng:NextInteger(1, NINST)
		local rec = insts[slot]
		local r = rng:NextNumber()
		local tag = "s" .. seed .. "#" .. step
		local op
		if r < 0.40 and rec.alive then
			op = "process"
			local k = SEATS[rng:NextInteger(1, #SEATS)]
			local v, sr = pickValue(rec, k)
			-- model: dispatch replaces the seat (R5/R6) — any binding ends
			mUnbindSeat(rec, k)
			local wantErr
			if sr then wantErr = mBind(rec, k, sr) else wantErr = mApply(rec, k, v) end
			local ok, e = pcall(q.Dispatch.process, rec.inst, k, v, 1)
			local gotErr = (not ok) and E.id(e) or nil
			if gotErr then bump(stats.errs, gotErr) end
			if gotErr ~= wantErr then diff(tag .. " process " .. tostring(k) .. " err " .. tostring(gotErr) .. " want " .. tostring(wantErr)) end
			if wantErr then mUnbindSeat(rec, k); rec.seats[k].eff = nil end
		elseif r < 0.52 and rec.alive then
			op = "retract"
			local k = SEATS[rng:NextInteger(1, #SEATS)]
			mUnbindSeat(rec, k); mRetract(rec, k)
			local ok, e = pcall(q.Dispatch.retractFrom, rec.inst, k, 1)
			if not ok then diff(tag .. " retract raised " .. E.id(e)) end
		elseif r < 0.75 then
			op = "set"
			local sr = srcs[rng:NextInteger(1, #srcs)]
			local v = srcValue(sr)
			sr.val = v
			for brec, ks in (sr.binds or {}) do
				if brec.alive then for k in ks do mApply(brec, k, v) end end
			end
			local ok, e = pcall(function() sr.s:Set(v) end)
			if not ok then diff(tag .. " Set raised " .. E.id(e)) end
		elseif r < 0.85 and rec.alive then
			op = "fire"
			local ev = EVENTS[rng:NextInteger(1, 2)]
			local eff = rec.seats[ev].eff
			if eff ~= nil then table.insert(rec.expectLog, "f" .. fnId[eff]) end
			stats.fires += 1
			local ok, e = pcall(function() rec.inst[ev]:Fire() end)
			if not ok then diff(tag .. " fire raised " .. E.id(e)) end
		elseif r < 0.93 and rec.alive then
			op = "extwrite"
			local nm = DESCNAMES[rng:NextInteger(1, 2)]
			local v = if nm == "Text" then ("x" .. rng:NextInteger(1, 3)) else (rng:NextNumber() < 0.5)
			if nm == "Text" then rec.extWrites += 1; rec.text = v; rec.hadExt = true end
			for _, k in { 1, 2 } do
				local d = rec.seats[k].eff
				if d ~= nil and descId[d].name == nm then table.insert(rec.expectLog, "d" .. descId[d].id .. "=" .. tostring(v)) end
			end
			stats.deliveries += 1
			rec.inst[nm] = v
		elseif r < 0.97 and rec.alive then
			op = "destroy"
			rec.inst:Destroy()
			rec.alive = false
			-- model: all seats unbound (lifetime), all effects gone
			for _, k in SEATS do rec.seats[k].bound = nil end
			for _, s in srcs do if s.binds then s.binds[rec] = nil end end
		elseif not rec.alive then
			op = "rebuild"
			local nrec = newRec(nil); nrec.expectLog = {}; nrec.expectWrites = 0
			-- random declarative props: array part first (M6), then hash
			local props = {}
			local order = {}
			for _, k in { 1, 2, 3, "Activated", "Text", "UIScale", "MouseEnter" } do
				if rng:NextNumber() < 0.6 then
					local v, sr = pickValue(nrec, k)
					if type(k) == "number" and v == nil then v = None end
					if type(k) == "string" and v == nil then v = None end
					if seatDom(k) == "ev" and v == 5 then v = pickFn() end
					props[k] = v
					table.insert(order, { k = k, v = v, sr = sr })
				elseif type(k) == "number" then
					props[k] = None; table.insert(order, { k = k, v = None })
				end
			end
			-- apply model (array before hash — order list is already array-first)
			if MUT == "hashfirst" then
				table.sort(order, function(a, b) return (type(a.k) == "string" and 0 or 1) < (type(b.k) == "string" and 0 or 1) end)
			end
			for _, o in order do
				if o.sr then mBind(nrec, o.k, o.sr) else mApply(nrec, o.k, o.v) end
			end
			-- the counter connects AFTER creation in newInstAt: writes during creation are not counted
			local preWrites = nrec.expectWrites
			newInstAt(slot, props, { rec = nrec })
			nrec.expectWrites -= preWrites
			-- expected log for creation-time deliveries stays (callbacks fire during drive)
			insts[slot] = nrec
			NINST = NINST
		else
			op = "noop"
		end
		bump(stats.opsBy, op)
		check(tag .. " " .. op)
		if #diffs > 0 then break end
	end
	-- teardown: destroy all and verify zero connections
	for _, rec in insts do if rec.alive then rec.inst:Destroy(); rec.alive = false end end
	for _, s in srcs do if s.dom ~= "child" then pcall(function() s.s:Set(s.dom == "ev" and pickFn() or None) end) end end
	check("s" .. seed .. " teardown")
	stats.seeds += 1
	if #diffs > 0 then
		stats.diffs += 1
		if #samples < 5 then table.insert(samples, diffs[1]) end
		if VERBOSE then for _, d in diffs do print(d) end end
	end
end

local t0 = os.clock()
for seed = START, START + SEEDS - 1 do runSeed(seed) end
print(string.format("E66 fuzz mutant=%s seeds=%d..%d ops=%d fires=%d extwrites=%d conn-samples=%d diffSeeds=%d time=%.1fs",
	tostring(MUT), START, START + SEEDS - 1, stats.ops, stats.fires, stats.deliveries, stats.conns, stats.diffs, os.clock() - t0))
local ks = {}; for k, n in stats.opsBy do table.insert(ks, k .. "=" .. n) end; table.sort(ks); print("ops: " .. table.concat(ks, " "))
local es = {}; for k, n in stats.errs do table.insert(es, k .. "=" .. n) end; table.sort(es); print("errors: " .. table.concat(es, " "))
for _, s in samples do print("sample: " .. s) end
