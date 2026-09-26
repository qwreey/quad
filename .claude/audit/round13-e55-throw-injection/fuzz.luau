--!nocheck
-- E55 throw-injection fuzzer: one random component tree, one op sequence, run twice —
-- control (no throw) and inject (ONE user callback throws once, site/time random). After the
-- sequence a fixed "heal" input runs in both; the final snapshots are diffed. Every diff is
-- labelled with the thrown site and bucketed; `EXPECT` (below) holds the buckets the docs
-- promise (taint of the thrown site itself), everything else is reported as residue.
-- usage: luau fuzz.luau -a <firstSeed> <count> [v|q] [iso|raw] [site]
local H = require("./harness")
local mockM = require("../../../quad-base/test/mock")
local q, D = H.q, H.D
local CS = H.CollectionService
local args = { ... }
local FIRST = tonumber(args[1]) or 1
local COUNT = tonumber(args[2]) or 100
local VERBOSE = args[3] == "v"
local ISO = args[4] ~= "raw"
local ONLY = args[5]
if ONLY == "-" then ONLY = nil end
local MUT = args[6] -- detection-power mutations: noRecover (a thrown Compute never recovers) | obsStops (an Observer that threw stops firing)
if MUT == "noRecover" then
	local Impl = getmetatable(q.Source(1):Compute(function() return 1 end))
	local orig = Impl._recompute
	Impl._recompute = function(self)
		if self._mutDead then error("mutDead") end
		local ok, e = pcall(orig, self)
		if not ok then self._mutDead = true; error(e, 0) end
	end
elseif MUT == "obsStops" then
	local o = q.Source(1):Observer(function() end)
	local Impl = getmetatable(o)
	local orig = Impl._receive
	Impl._receive = function(self, from)
		if self._running then return end -- a thrown fn leaves _running up: mutant stops firing it
		return orig(self, from)
	end
end

local stack = {}
local through = {} -- list of {site, owner} frames a throw passed through (this run)
local function harvest(level)
	for i = #stack, level + 1, -1 do
		table.insert(through, stack[i])
		stack[i] = nil
	end
end

-- engine-like handler isolation (Roblox runs each connected handler separately; mock Fire does not)
local handlerErrs = {}
do
	local probe = mockM.Instance.new("Frame")
	local SignalMT = getmetatable(probe.Destroying)
	if ISO then
		SignalMT.Fire = function(self, ...)
			local snapshot = table.clone(self.connections)
			for i = #snapshot, 1, -1 do
				local conn = snapshot[i]
				if conn.Connected then
					local lvl = #stack
					local ok, e = pcall(conn.fn, ...)
					if not ok then table.insert(handlerErrs, H.first(e)); harvest(lvl) end
				end
			end
		end
	end
	probe:Destroy()
end

local rs = 1
local function nextF()
	rs = (rs * 1103515245 + 12345) % 2147483648
	return rs / 2147483648
end
local function R(n) return math.floor(nextF() * n) + 1 end
local function P(p) return nextF() < p end

local SITES = {
	"compute1", "compute2", "computeTag", "computeTween", "observer", "observer2", "effectFn", "cleanup",
	"updateFn", "keyFn", "updateFnLate", "keyFnLate", "offsetSub", "lengthSub", "refCb", "preRefCb",
	"postRefCb", "onCreated", "onRendered", "onDestroyed", "tweenStarted", "tweenCompleted",
	"tweenCancelled", "onChange", "txtObs", "debObs", "modFn",
}

-- ── injection ────────────────────────────────────────────────────────
local INJ = { armed = false, site = nil, skip = 0, fired = false, firedOp = nil, pre = nil, owner = nil }
local curOp = 0
local calls = {}
local function W(site, fn, owner)
	return function(...)
		calls[site] = (calls[site] or 0) + 1
		if INJ.armed and INJ.site == site then
			if INJ.skip > 0 then
				INJ.skip -= 1
			else
				INJ.armed = false
				INJ.fired = true
				INJ.firedOp = curOp
				INJ.owner = owner
				table.insert(through, { site, owner, true })
				if INJ.pre then INJ.pre() end
				error("INJ:" .. site, 0)
			end
		end
		local n = #stack + 1
		stack[n] = { site, owner }
		local r = table.pack(fn(...))
		harvest(n) -- frames above ours that threw and were caught below us (engine isolation)
		stack[n] = nil
		return table.unpack(r, 1, r.n)
	end
end

local function norm(e)
	local s = H.first(e)
	s = s:gsub("^[^:]*%.luau:%d+: ", "")
	local code = s:match("^(Quad%d%d%d%d)")
	if code then return code end
	if s:match("^INJ:") then return s end
	return s:sub(1, 60)
end

-- ── scenario ─────────────────────────────────────────────────────────
local function genScenario()
	local sc = { feat = {}, ops = {} }
	sc.items0 = {}
	for i = 1, R(4) do sc.items0[i] = i end
	sc.s1n = R(3) - 1
	for _, f in { "tween", "observer", "effect", "tag", "attr", "ref", "preRef", "postRef", "hooks", "deb", "text", "inner", "mod" } do
		sc.feat[f] = P(0.7)
	end
	local n = 20 + R(31) - 1
	local seq = 0
	for i = 1, n do
		local r = R(17)
		seq += 1
		local op
		if r == 1 or r == 2 then op = { "setA", seq }
		elseif r == 3 then op = { "setB", seq }
		elseif r == 4 or r == 5 then
			local items, pool = {}, { 1, 2, 3, 4, 5, 6 }
			for _ = 1, R(5) - 1 do local j = R(#pool); table.insert(items, table.remove(pool, j)) end
			op = { "setItems", items }
		elseif r == 6 then op = { "toggle" }
		elseif r == 7 then op = { "setTxt", "t" .. seq }
		elseif r == 8 then op = { "type", R(6), "u" .. seq }
		elseif r == 9 then op = { "advance", ({ 0.1, 0.2, 0.35, 0.5, 1 })[R(5)] }
		elseif r == 10 then op = { "complete" }
		elseif r == 11 then op = { "s1Add", "m" .. seq }
		elseif r == 12 then op = { "s1Remove", R(3) }
		elseif r == 13 then op = { "s3Add", "x" .. seq }
		elseif r == 14 then op = { "s3Remove", R(2) }
		elseif r == 15 then op = { "late", "late" .. seq }
		elseif r == 16 then op = { "read" }
		else op = { "setA", seq } end
		sc.ops[i] = op
	end
	sc.armAt = R(n)
	sc.site = ONLY or SITES[R(#SITES)]
	sc.skip = R(3) - 1
	return sc
end

local function build(sc)
	local Rr = { tr = {}, top = {}, late = {} }
	local F = sc.feat
	Rr.A = q.Source(1)
	Rr.B = q.Source(1)
	Rr.flag = q.Source(false)
	Rr.txt = q.Source("t0")
	Rr.items = q.Source(table.clone(sc.items0))
	Rr.C1 = Rr.A:Compute(W("compute1", function(s) return s:Get() * 2 end))
	Rr.C2 = Rr.C1:Compute(W("compute2", function(s, _prev, b) return s:Get() + b:Get() end), Rr.B)
	Rr.tagState = Rr.flag:Compute(W("computeTag", function(s) return if s:Get() then q.Tag("on") else q.Tag("off") end))

	local function trOf(name) local t = Rr.tr[name]; if not t then t = {}; Rr.tr[name] = t end return t end

	local function Comp(key, idx)
		local name = "c" .. tostring(key)
		local tr = {}
		Rr.tr[name] = tr
		local function WC(site, fn) return W(site, fn, name) end
		tr.index = idx
		local props = { Name = name, LayoutOrder = idx }
		if F.tween then
			props.BackgroundTransparency = Rr.C2:Compute(WC("computeTween", function(s)
				return q.Tween({ Value = (s:Get() % 10) / 10, Time = 1,
					Started = WC("tweenStarted", function() tr.st = (tr.st or 0) + 1 end),
					Completed = WC("tweenCompleted", function() tr.co = (tr.co or 0) + 1 end),
					Cancelled = WC("tweenCancelled", function() tr.ca = (tr.ca or 0) + 1 end),
				})
			end))
		end
		if F.observer then
			tr.obsH = Rr.C1:Observer(WC("observer", function(s) tr.obs = s:Get() end))
			props[#props + 1] = tr.obsH
		end
		if F.effect then
			tr.effH = q.Effect(WC("effectFn", function()
				tr.eff = Rr.C2:Get()
				tr.runs = (tr.runs or 0) + 1
				return WC("cleanup", function(dying)
					tr.cleans = (tr.cleans or 0) + 1
					if dying then tr.dying = (tr.dying or 0) + 1 end
				end)
			end), Rr.C2)
			props[#props + 1] = tr.effH
		end
		if F.tag then props[#props + 1] = Rr.tagState end
		if F.attr then props[#props + 1] = q.Attr({ hp = Rr.C2 }) end
		if F.ref then
			local ref = q.Ref(nil)
			ref:Callback(WC("refCb", function(v) tr.ref = v and v.Name or "nil" end))
			props[#props + 1] = ref
		end
		if F.preRef then
			local pr = q.PreRef(nil)
			pr:Callback(WC("preRefCb", function(v) tr.pre = v and v.Name or "nil" end))
			props[#props + 1] = pr
		end
		if F.postRef then
			local po = q.PostRef(nil)
			po:Callback(WC("postRefCb", function(v) tr.post = v and v.Name or "nil" end))
			props[#props + 1] = po
		end
		if F.hooks then
			props[#props + 1] = q.OnCreated(WC("onCreated", function(inst) tr.oc1 = inst.Name end))
			props[#props + 1] = q.OnRendered(WC("onRendered", function(inst) tr.or1 = inst.Name end))
			props[#props + 1] = q.OnDestroyed(WC("onDestroyed", function() tr.od = (tr.od or 0) + 1 end))
		end
		if F.deb then
			props[#props + 1] = Rr.C1:Apply(q.Debounce({ Time = 0.3 })):Observer(WC("debObs", function(s) tr.deb = s:Get() end))
		end
		if F.text then
			props[#props + 1] = D.TextBox({ Name = "tb", Text = Rr.txt, q.Out("Text", Rr.txt),
				q.OnChange("Text", WC("onChange", function(v) tr.chg = v end)) })
		end
		if F.inner then
			props[#props + 1] = D.Frame({ Name = name .. "_in",
				Rr.C2:Observer(WC("observer2", function(s) tr.obs2 = s:Get() end)) })
		end
		if F.mod then
			-- Modifier function field on a State path: a Compute-like transform
			props[#props + 1] = D.Modifier.Frame():ZIndex(Rr.B):ZIndex(WC("modFn", function(s) return s:Get() % 50 + 1 end))
		end
		return D.Frame(props)
	end
	Rr.Comp = Comp

	Rr.S1 = q.Slot()
	for i = 1, sc.s1n do Rr.S1:Add(Comp("m0" .. i, i)) end
	Rr.S2 = q.Slot():List(Rr.items, W("updateFn", function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Prev then
			local t = Rr.tr["c" .. ctx.Item]
			if t then t.index = ctx.Index end
			ctx.Prev.LayoutOrder = ctx.Index
			return ctx.Prev
		end
		return Comp(ctx.Item, ctx.Index)
	end), W("keyFn", function(item) return item end))
	Rr.S3 = q.Slot({ D.Frame({ Name = "s3a" }) })
	Rr.root = D.Frame({
		Name = "root",
		D.Frame({ Name = "static1" }),
		Rr.S1,
		Rr.S2,
		Rr.S3,
		Rr.S3.Offset:Observer(W("offsetSub", function(s) Rr.top.off3 = s:Get() end, "root")),
		Rr.S2.Length:Observer(W("lengthSub", function(s) Rr.top.len2 = s:Get() end, "root")),
		Rr.txt:Observer(W("txtObs", function(s) Rr.top.txt = s:Get() end, "root")),
	})
	Rr.lateList = function(name)
		local sl = q.Slot():List(Rr.items, W("updateFnLate", function(ctx)
			if ctx.Item == q.KeyGone then return nil end
			if ctx.Prev then return ctx.Prev end
			return D.Frame({ Name = "L" .. ctx.Item })
		end, name), W("keyFnLate", function(item) return item end, name))
		Rr.late[name] = sl
		local fr = D.Frame({ Name = name, sl })
		Rr.lateFrame = Rr.lateFrame or {}
		Rr.lateFrame[name] = fr
		Rr.S1:Add(fr)
	end
	return Rr
end

local function findComp(Rr, want)
	-- the want-th TextBox among live comps (sorted by name)
	local list = {}
	local function walk(inst)
		for _, c in inst:GetChildren() do
			if c.Name == "tb" then table.insert(list, c) end
			walk(c)
		end
	end
	walk(Rr.root)
	table.sort(list, function(a, b) return a.Parent.Name < b.Parent.Name end)
	if #list == 0 then return nil end
	return list[(want - 1) % #list + 1]
end

local function runOp(Rr, op)
	local k = op[1]
	if k == "setA" then Rr.A:Set(op[2])
	elseif k == "setB" then Rr.B:Set(op[2])
	elseif k == "setItems" then Rr.items:Set(table.clone(op[2]))
	elseif k == "toggle" then Rr.flag:Set(not Rr.flag:Get())
	elseif k == "setTxt" then Rr.txt:Set(op[2])
	elseif k == "type" then
		local tb = findComp(Rr, op[2])
		if tb then tb.Text = op[3] end
	elseif k == "advance" then H.runTask(op[2])
	elseif k == "complete" then
		for _, e in mockM.tweenLog do
			if e.tween.PlaybackState == "Playing" then e.tween:simulateCompleted() end
		end
	elseif k == "s1Add" then Rr.S1:Add(Rr.Comp(op[2], 0))
	elseif k == "s1Remove" then
		if Rr.S1.Length:Get() >= op[2] then Rr.S1:Remove(op[2]) end
	elseif k == "s3Add" then Rr.S3:Add(D.Frame({ Name = op[2] }))
	elseif k == "s3Remove" then
		if Rr.S3.Length:Get() >= op[2] then Rr.S3:Remove(op[2]) end
	elseif k == "late" then Rr.lateList(op[2])
	elseif k == "read" then local _ = Rr.C2:Get()
	end
end

local function heal(Rr, errs)
	local steps = {
		function() Rr.A:Set(9001) end,
		function() Rr.B:Set(9002) end,
		function() Rr.flag:Set(not Rr.flag:Get()) end,
		function() Rr.flag:Set(not Rr.flag:Get()) end,
		function() Rr.items:Set({ 6, 2, 5 }) end,
		function() Rr.items:Set({ 2, 6, 3, 1 }) end,
		function() Rr.txt:Set("heal") end,
		function() H.runTask(10) end,
		function()
			for _, e in mockM.tweenLog do
				if e.tween.PlaybackState == "Playing" then e.tween:simulateCompleted() end
			end
		end,
		function() Rr.S3:Add(D.Frame({ Name = "healS3" })) end,
	}
	for i, f in steps do
		local ok, e = pcall(f)
		harvest(0)
		if not ok then errs["heal" .. i] = norm(e) end
	end
end

local function gv(st)
	local ok, v = pcall(function() return st:Get() end)
	if ok then return v end
	return "ERR:" .. norm(v)
end

local HEAL_ITEMS = { 2, 6, 3, 1 }
-- model after heal: A=9001 B=9002 items=HEAL_ITEMS txt="heal"
local function checkInvariants(Rr, fails)
	local function F(key, owner, detail) table.insert(fails, { key = key, owner = owner, detail = detail }) end
	local C1, C2 = 18002, 27004
	if gv(Rr.C1) ~= C1 then F("v.C1", "root", tostring(gv(Rr.C1))) end
	if gv(Rr.C2) ~= C2 then F("v.C2", "root", tostring(gv(Rr.C2))) end
	local flag = gv(Rr.flag)
	local wantTag = if flag then "on" else "off"
	local l1, l2, l3 = gv(Rr.S1.Length), gv(Rr.S2.Length), gv(Rr.S3.Length)
	local o1, o2, o3 = gv(Rr.S1.Offset), gv(Rr.S2.Offset), gv(Rr.S3.Offset)
	if l2 ~= #HEAL_ITEMS then F("S2.Length", "root", tostring(l2)) end
	-- actual S1 element count via the public reader
	local n1 = 0
	pcall(function() while Rr.S1:Get(n1 + 1) ~= nil do n1 += 1 end end)
	if l1 ~= n1 then F("S1.Length~elements", "root", ("%s vs %d"):format(tostring(l1), n1)) end
	if o1 ~= 1 then F("S1.Offset", "root", tostring(o1)) end
	if type(o2) == "number" and type(l1) == "number" and o2 ~= o1 + l1 then F("S2.Offset", "root", ("%s want %s"):format(tostring(o2), tostring(o1 + l1))) end
	if type(o3) == "number" and type(o2) == "number" and o3 ~= o2 + #HEAL_ITEMS then F("S3.Offset", "root", ("%s want %s"):format(tostring(o3), tostring(o2 + #HEAL_ITEMS))) end
	if Rr.top.len2 ~= l2 then F("top.len2", "root", ("%s vs %s"):format(tostring(Rr.top.len2), tostring(l2))) end
	if Rr.top.off3 ~= o3 then F("top.off3", "root", ("%s vs %s"):format(tostring(Rr.top.off3), tostring(o3))) end
	if Rr.top.txt ~= "heal" then F("top.txt", "root", tostring(Rr.top.txt)) end
	if gv(Rr.txt) ~= "heal" then F("v.txt", "root", tostring(gv(Rr.txt))) end
	for nm, sl in Rr.late do
		local fr = Rr.lateFrame and Rr.lateFrame[nm]
		if not (fr and fr.Parent == Rr.root) then continue end
		local ll = gv(sl.Length)
		if ll ~= #HEAL_ITEMS then F("late.Length", nm, tostring(ll)) end
	end
	-- S2 contents
	local want = {}
	for p, k in HEAL_ITEMS do want["c" .. k] = p end
	local seen = {}
	for i = 1, 12 do
		local ok, el = pcall(function() return Rr.S2:Get(i) end)
		if ok and el ~= nil then
			seen[el.Name] = i
			if want[el.Name] ~= i then F("S2.order", el.Name, ("at %d"):format(i)) end
		end
	end
	for nm in want do if not seen[nm] then F("S2.missing", nm, "") end end
	-- per live comp
	local live = {}
	local function walk(inst)
		for _, c in inst:GetChildren() do
			if Rr.tr[c.Name] and c.ClassName == "Frame" then live[c.Name] = c end
			walk(c)
		end
	end
	walk(Rr.root)
	for name, inst in live do
		local tr = Rr.tr[name]
		local feat = Rr.feat
		if feat.observer and tr.obs ~= C1 then F("comp.obs", name, tostring(tr.obs)) end
		if feat.inner and tr.obs2 ~= C2 then F("comp.obs2", name, tostring(tr.obs2)) end
		if feat.effect and tr.eff ~= C2 then F("comp.eff", name, tostring(tr.eff)) end
		if feat.effect and (tr.runs or 0) - (tr.cleans or 0) ~= 1 then F("comp.effBalance", name, ("%s/%s"):format(tostring(tr.runs), tostring(tr.cleans))) end
		if feat.deb and tr.deb ~= C1 then F("comp.deb", name, tostring(tr.deb)) end
		if feat.mod and inst.ZIndex ~= 9002 % 50 + 1 then F("comp.Z", name, tostring(inst.ZIndex)) end
		if feat.attr and inst:GetAttribute("hp") ~= C2 then F("comp.attr", name, tostring(inst:GetAttribute("hp"))) end
		if feat.tag then
			local tags = CS:GetTags(inst)
			table.sort(tags)
			if table.concat(tags, ",") ~= wantTag then F("comp.tags", name, table.concat(tags, ",")) end
		end
		if feat.text then
			local tb = inst:FindFirstChild("tb")
			if not tb or tb.Text ~= "heal" then F("comp.tbText", name, tostring(tb and tb.Text)) end
			if tr.chg ~= "heal" then F("comp.onChange", name, tostring(tr.chg)) end
		end
		if feat.tween then
			local st, co, ca = tr.st or 0, tr.co or 0, tr.ca or 0
			if st ~= co + ca then F("comp.tweenPair", name, ("%d/%d/%d"):format(st, co, ca)) end
			if st == 0 then F("comp.tweenNone", name, "") end
		end
		if feat.hooks then
			if tr.oc1 == nil then F("comp.onCreated", name, "") end
			if tr.or1 ~= name then F("comp.onRendered", name, tostring(tr.or1)) end
		end
		if feat.ref and tr.ref ~= "Frame" and tr.ref ~= name then F("comp.ref", name, tostring(tr.ref)) end
		if feat.postRef and tr.post ~= name then F("comp.postRef", name, tostring(tr.post)) end
		if want[name] then
			if tr.index ~= want[name] then F("comp.index", name, tostring(tr.index)) end
			if inst.LayoutOrder ~= want[name] then F("comp.LO", name, tostring(inst.LayoutOrder)) end
		end
	end
	return live
end

local function checkTeardown(Rr, live, fails)
	local function F(key, owner, detail) table.insert(fails, { key = key, owner = owner, detail = detail }) end
	for name in live do
		local tr = Rr.tr[name]
		if Rr.feat.hooks and tr.od ~= 1 then F("td.onDestroyed", name, tostring(tr.od)) end
		if Rr.feat.effect then
			if (tr.runs or 0) ~= (tr.cleans or 0) then F("td.effBalance", name, ("%s/%s"):format(tostring(tr.runs), tostring(tr.cleans))) end
			if tr.dying ~= 1 then F("td.dying", name, tostring(tr.dying)) end
		end
		if Rr.feat.tween then
			local st, co, ca = tr.st or 0, tr.co or 0, tr.ca or 0
			if st ~= co + ca then F("td.tweenPair", name, ("%d/%d/%d"):format(st, co, ca)) end
		end
	end
end

-- immediate (right after the op that threw) promised state
local function immediate(Rr, sc, out)
	local site, owner = sc.site, INJ.owner
	local tr = owner and Rr.tr[owner]
	local function rec(k) out[k] = true end
	if site == "compute1" then rec("imm.C1=" .. tostring(gv(Rr.C1)):sub(1, 12))
	elseif site == "compute2" then rec("imm.C2=" .. tostring(gv(Rr.C2)):sub(1, 12))
	elseif site == "computeTag" then rec("imm.tag=" .. tostring(gv(Rr.tagState)):sub(1, 12))
	elseif (site == "observer") and tr and tr.obsH then
		local ok, e = pcall(function() tr.obsH:WeakSubscribe() end)
		rec("imm.obsWeakSub=" .. (ok and "ok" or norm(e)))
	elseif (site == "effectFn" or site == "cleanup") and tr and tr.effH then
		local ok, e = pcall(function() tr.effH:WeakSubscribe() end)
		rec("imm.effWeakSub=" .. (ok and "ok" or norm(e)))
	end
end

-- ── one run ──────────────────────────────────────────────────────────
local function runOnce(sc, inject)
	mockM.resetTweenLog()
	INJ.armed = false; INJ.fired = false; INJ.firedOp = nil; INJ.site = sc.site; INJ.skip = sc.skip; INJ.pre = nil; INJ.owner = nil
	table.clear(handlerErrs)
	table.clear(through)
	table.clear(stack)
	curOp = 0
	local Rr = build(sc)
	Rr.feat = sc.feat
	local info = { opErrs = {}, imm = {}, where = nil }
	for i, op in sc.ops do
		curOp = i
		if inject and i == sc.armAt then INJ.armed = true end
		local before = #handlerErrs
		local wasFired = INJ.fired
		local ok, e = pcall(runOp, Rr, op)
		if not ok then
			local m = norm(e)
			if not m:match("^INJ:") then table.insert(info.opErrs, ("op%d %s: %s"):format(i, op[1], m)) end
		end
		harvest(0)
		for j = before + 1, #handlerErrs do
			local m = norm(handlerErrs[j])
			if not m:match("^INJ:") then table.insert(info.opErrs, ("op%d %s h: %s"):format(i, op[1], m)) end
		end
		if INJ.fired and not wasFired then
			info.where = (not ok and norm(e):match("^INJ:")) and ("op:" .. op[1]) or "handler:" .. op[1]
			if ok then
				-- swallowed by a signal boundary (engine isolation) or thrown from a place that did not reach the op
				local caught = false
				for j = before + 1, #handlerErrs do if norm(handlerErrs[j]):match("^INJ:") then caught = true end end
				info.where = (caught and "handler:" or "scheduler:") .. op[1]
			end
			immediate(Rr, sc, info.imm)
		end
	end
	INJ.armed = false
	curOp = #sc.ops + 1
	local healErrs = {}
	heal(Rr, healErrs)
	local fails = {}
	local live = checkInvariants(Rr, fails)
	for k, v in healErrs do table.insert(fails, { key = "healErr." .. v, owner = "root", detail = k }) end
	local before = #handlerErrs
	local okd, ed = pcall(function() Rr.root:Destroy() end)
	if not okd then table.insert(fails, { key = "teardownErr." .. norm(ed), owner = "root", detail = "" }) end
	H.runTask(10)
	harvest(0)
	info.through = table.clone(through)
	for j = before + 1, #handlerErrs do
		local m = norm(handlerErrs[j])
		table.insert(fails, { key = "teardownHandlerErr." .. m, owner = "root", detail = "" })
	end
	checkTeardown(Rr, live, fails)
	return fails, info, Rr
end

local RULES = {
	effectFn = { "comp.eff", "comp.effBalance", "td.dying", "td.effBalance", own = true },
	cleanup = { "comp.eff", "comp.effBalance", "td.dying", "td.effBalance", own = true },
	updateFn = { "S2.Length", "S3.Offset", "S2.order", "S2.missing", "comp.index", "comp.LO" },
	updateFnLate = { "late.Length", own = true },
	keyFnLate = { "late.Length", own = true },
	offsetSub = { "S2.Offset", "S3.Offset", "top.off3" },
	tweenStarted = { "comp.tweenPair", "td.tweenPair", own = true },
	tweenCompleted = { "comp.tweenPair", "td.tweenPair", own = true },
	tweenCancelled = { "comp.tweenPair", "td.tweenPair", own = true },
}
local function explain(f, thr)
	for _, fr in thr do
		local r = RULES[fr[1]]
		if r and table.find(r, f.key) and (not r.own or fr[2] == f.owner) then return fr[1] end
	end
	return nil
end

local totals = { seeds = 0, fired = 0, failSeeds = 0, ctrlFailSeeds = 0, bySite = {}, byBucket = {}, examples = {}, where = {}, imm = {}, ctrlBuckets = {}, ctrlEx = {}, secondary = {}, thr = {} }
local function bump(t, k, n) t[k] = (t[k] or 0) + (n or 1) end

for seed = FIRST, FIRST + COUNT - 1 do
	rs = seed * 7919 + 17; for _ = 1, 5 do nextF() end
	local sc = genScenario()
	totals.seeds += 1
	local ok1, cf, cinfo = pcall(runOnce, sc, false)
	if not ok1 then print(("seed %d: control run crashed: %s"):format(seed, norm(cf))); continue end
	if #cf > 0 then
		totals.ctrlFailSeeds += 1
		for _, f in cf do
			bump(totals.ctrlBuckets, f.key)
			totals.ctrlEx[f.key] = totals.ctrlEx[f.key] or ("seed %d %s %s"):format(seed, f.owner, f.detail)
		end
	end
	local ok2, fails, info = pcall(runOnce, sc, true)
	if not ok2 then print(("seed %d: inject run crashed: %s"):format(seed, norm(fails))); continue end
	local st = totals.bySite[sc.site] or { seeds = 0, fired = 0, fail = 0 }
	totals.bySite[sc.site] = st
	st.seeds += 1
	if not INJ.fired then continue end
	totals.fired += 1
	st.fired += 1
	bump(totals.where, sc.site .. " @ " .. tostring(info.where):gsub(":.*", ""))
	for k in info.imm do bump(totals.imm, sc.site .. " " .. k) end
	do
		local seenT = {}
		for _, fr in info.through do
			if not fr[3] and not seenT[fr[1]] then seenT[fr[1]] = true; bump(totals.thr, sc.site .. " thru " .. fr[1]) end
		end
	end
	-- subtract control failures (model noise) by key+owner
	local cset = {}
	for _, f in cf do cset[f.key .. "|" .. f.owner] = true end
	local extra = {}
	for _, f in fails do if not cset[f.key .. "|" .. f.owner] then table.insert(extra, f) end end
	local cerr = {}
	for _, m in cinfo.opErrs do cerr[m] = true end
	local secondary = nil
	for _, m in info.opErrs do if not cerr[m] then secondary = secondary or m:match(": (.*)$") end end
	if secondary then bump(totals.secondary, sc.site .. " -> " .. secondary) end
	if #extra > 0 then
		totals.failSeeds += 1
		st.fail += 1
		local seenB = {}
		for _, f in extra do
			local rel = if f.owner == INJ.owner then "victim" elseif f.owner == "root" then "root" else "other"
			if secondary then rel = "casc:" .. rel end
			local ex = explain(f, info.through)
			local b = ("%s %s | %s | %s"):format(ex and "  doc" or "UNEX", sc.site, f.key, rel) .. (ex and (" <- " .. ex) or "")
			if not seenB[b] then
				seenB[b] = true
				bump(totals.byBucket, b)
				totals.examples[b] = totals.examples[b] or ("seed %d arm %d/%d fired op%s(%s) skip %d owner %s: %s %s"):format(
					seed, sc.armAt, #sc.ops, tostring(INJ.firedOp), tostring(info.where), sc.skip, tostring(INJ.owner), f.owner, f.detail)
			end
		end
		if VERBOSE then
			print(("seed %d site %s arm %d fired op%s where %s owner %s"):format(seed, sc.site, sc.armAt, tostring(INJ.firedOp), tostring(info.where), tostring(INJ.owner)))
			for _, f in extra do print("   ", f.key, f.owner, f.detail) end
			local ol = {}
			for i, op in sc.ops do ol[i] = i .. ":" .. op[1] .. (op[2] ~= nil and ("(" .. (type(op[2]) == "table" and table.concat(op[2], ",") or tostring(op[2])) .. ")") or "") end
			print("    ops: " .. table.concat(ol, " "))
			print("    feat: " .. (function() local t = {} for k, v in sc.feat do if v then table.insert(t, k) end end table.sort(t) return table.concat(t, ",") end)())
			for _, m in info.opErrs do print("    injErr: " .. m) end
			for _, m in cinfo.opErrs do print("    ctlErr: " .. m) end
		end
	end
end

print(("== seeds=%d fired=%d failSeeds=%d ctrlFailSeeds=%d iso=%s"):format(totals.seeds, totals.fired, totals.failSeeds, totals.ctrlFailSeeds, tostring(ISO)))
local function dump(title, t, ex)
	print("-- " .. title)
	local ks = {}
	for k in t do table.insert(ks, k) end
	table.sort(ks)
	for _, k in ks do
		print(("  %-58s %5d%s"):format(k, t[k], ex and ex[k] and ("   e.g. " .. ex[k]) or ""))
	end
end
local sites = {}
for s, st in totals.bySite do sites[s] = ("seeds %d fired %d failSeeds %d"):format(st.seeds, st.fired, st.fail) end
do
	print("-- sites")
	local ks = {}
	for k in sites do table.insert(ks, k) end
	table.sort(ks)
	for _, k in ks do print(("  %-16s %s"):format(k, sites[k])) end
end
dump("where the throw surfaced", totals.where)
dump("immediate state", totals.imm)
dump("control-run model failures (should be empty)", totals.ctrlBuckets, totals.ctrlEx)
dump("secondary (cascade) errors in inject run", totals.secondary)
dump("user frames a throw passed through (site thru frame)", totals.thr)
dump("inject-only failures", totals.byBucket, totals.examples)
