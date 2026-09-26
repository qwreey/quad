--!nocheck
-- E51 main differential fuzzer: Tag refcount + Attr name ownership vs a reference model.
-- usage: luau fuzz.luau -a <seeds> <start> [verbose]
local H = require("./harness")
local RNG = require("./rng")
local mock, Instance = H.mock, H.Instance
local args = { ... }
local SEEDS = tonumber(args[1]) or 200
local START = tonumber(args[2]) or 1
local VERBOSE = args[3] == "v"
local NC = args[4] == "nc" -- collision-free mode: groups only use names not owned by another owner
local MUT = args[5] -- model mutant id (detection-power check)

local TAGN = { "a", "b", "c", "d", "e" }
local ATTRN = { "X", "Y", "Z", "W" }

local function setOf(list) local s = {} for _, n in list do s[n] = true end return s end
local function keys(s) local t = {} for k in s do table.insert(t, k) end table.sort(t) return t end
local function eqSet(a, b) for k in a do if not b[k] then return false end end for k in b do if not a[k] then return false end end return true end
local function fmtAttrs(m) local t = {} for k, v in m do table.insert(t, k .. "=" .. tostring(v)) end table.sort(t) return table.concat(t, ",") end

local stats = { seeds = 0, steps = 0, collisions = 0, diffs = 0, destroys = 0, tagCalls = 0, attrCalls = 0, reemit = 0, tainted = 0 }
local diffSamples = {}

local function runSeed(seed)
	local rng = RNG.new(seed)
	local log = {}
	local rawlog = {}
	local q = H.newQ(rawlog)
	local None = q.None
	local instId = setmetatable({}, { __mode = "k" })
	local taintedLines = 0
	-- wrap the mock ops so each log line carries its instance (tainted instances are filtered out)
	for _, op in { "addTag", "removeTag", "setAttr" } do
		local orig = q.Backend[op]
		q.Backend[op] = function(inst, ...)
			local before = #rawlog
			orig(inst, ...)
			for i = before + 1, #rawlog do
				local I = instId[inst]
				if I and I.tainted then taintedLines += 1 stats.zombie = (stats.zombie or 0) + 1
				else table.insert(log, rawlog[i]) end
			end
		end
	end
	local trace = {}
	local function T(s) table.insert(trace, s) end
	local failed = nil
	local function fail(msg) if not failed then failed = msg end end

	-- inner value sources (shared across instances): model value
	local inner = {}
	for j = 1, 3 do inner[j] = { src = q.Source(rng:NextInteger(1, 3)), subs = {} } inner[j].val = inner[j].src:Get() end
	local function effective(v) if v == None then return nil end return v end

	-- random Tag via one of the construction doors; returns obj, modelSet
	local sharedTags = {}
	local function randNames(maxn)
		local l = {} for _, n in TAGN do if rng:NextNumber() < 0.35 then table.insert(l, n) end end
		return l
	end
	local function randTag()
		local r = rng:NextInteger(1, 7)
		if r == 1 then local l = randNames() return q.Tag(table.unpack(l)), setOf(l), "Tag(...)"
		elseif r == 2 then local l = randNames() return q.Tag(l), setOf(l), "Tag{list}"
		elseif r == 3 then local a, b = randNames(), randNames() local s = setOf(a) for _, n in b do s[n] = true end
			return q.Tag.Merged(q.Tag(a), nil, q.Tag(b)), s, "Merged"
		elseif r == 4 then local a = randNames() local extra = if rng:NextNumber() < 0.5 then TAGN[rng:NextInteger(1, 5)] else nil
			local s = setOf(a) if extra then s[extra] = true end return q.Tag(a):Added(extra), s, "Added"
		elseif r == 5 then local a = randNames() local rm = TAGN[rng:NextInteger(1, 5)] local s = setOf(a) s[rm] = nil
			return q.Tag(a):Removed(rm), s, "Removed"
		elseif r == 6 then local a = randNames() local b = randNames() local s = setOf(a) for _, n in b do s[n] = true end
			return q.Tag(q.Tag(a), nil, b), s, "Tag(tag,nil,list)"
		else
			if #sharedTags > 0 and rng:NextNumber() < 0.7 then local st = sharedTags[rng:NextInteger(1, #sharedTags)] return st.obj, table.clone(st.set), "shared" end
			local l = randNames() local o = q.Tag(l) table.insert(sharedTags, { obj = o, set = setOf(l) }) return o, setOf(l), "shared-new"
		end
	end
	local sharedGroups = {}
	-- random group; returns obj, model entries {[name]=spec} spec={raw=v}|{none}|{inner=j}
	local function randEntryVal()
		local r = rng:NextNumber()
		if r < 0.5 then local v = rng:NextInteger(1, 9) return v, { raw = v }
		elseif r < 0.65 then return None, { raw = None }
		else local j = rng:NextInteger(1, #inner) return inner[j].src, { inner = j } end
	end
	local function randGroup(allowed, I, k)
		local AN = ATTRN
		if allowed then AN = {} for _, n in ATTRN do if allowed[n] then table.insert(AN, n) end end end
		local ATTRN = AN
		local r = rng:NextInteger(1, 5)
		if #ATTRN == 0 then return q.Attr({}), {}, "Attr{}-empty" end
		if r == 1 or r == 2 then
			local t, m = {}, {}
			for _, n in ATTRN do if rng:NextNumber() < 0.3 then local v, s = randEntryVal() t[n] = v m[n] = s end end
			return q.Attr(t), m, "Attr{}"
		elseif r == 3 then
			local n = ATTRN[rng:NextInteger(1, #ATTRN)]
			local v, s = randEntryVal()
			if s.raw ~= nil and s.raw ~= None then return q.NumberAttr(n, v), { [n] = s }, "NumberAttr" end
			return q.NumberAttr(n, v), { [n] = s }, "NumberAttr"
		elseif r == 4 then
			local t1, m = {}, {}
			local t2 = {}
			for _, n in ATTRN do if rng:NextNumber() < 0.3 then local v, s = randEntryVal() t1[n] = v m[n] = s end end
			for _, n in ATTRN do if rng:NextNumber() < 0.3 then local v, s = randEntryVal() t2[n] = v m[n] = s end end
			return q.Attr.Overridden(q.Attr(t1), q.Attr(t2)), m, "Overridden"
		else
			if #sharedGroups > 0 and rng:NextNumber() < 0.6 then
				local sg = sharedGroups[rng:NextInteger(1, #sharedGroups)]
				local okShare = true
				if allowed then
					for n in sg.m do if not allowed[n] then okShare = false end end
					if I.gpos and I.gpos[sg.obj] ~= nil and I.gpos[sg.obj] ~= k then okShare = false end
				end
				if okShare then return sg.obj, sg.m, "sharedG" end
			end
			local t, m = {}, {}
			for _, n in ATTRN do if rng:NextNumber() < 0.3 then local v, s = randEntryVal() t[n] = v m[n] = s end end
			local o = q.Attr(t) table.insert(sharedGroups, { obj = o, m = m }) return o, m, "sharedG-new"
		end
	end
	local function randPosValue(I, k)
		local allowed = nil
		if NC and I then
			allowed = {}
			for _, n in ATTRN do local o = I.owner[n] if o == nil or (o.kind == "pos" and o.k == k) then allowed[n] = true end end
		end
		local r = rng:NextNumber()
		if r < 0.5 then local o, s, how = randTag() return { kind = "tag", obj = o, set = s, how = how }
		elseif r < 0.62 then return { kind = "empty", obj = nil, how = "nil" }
		elseif r < 0.7 then return { kind = "empty", obj = None, how = "None" }
		else local o, m, how = randGroup(allowed, I, k) return { kind = "group", obj = o, m = m, how = how } end
	end

	-- instances
	local insts = {}
	local nInst = rng:NextInteger(1, 3)
	for i = 1, nInst do
		local I = { id = i, inst = Instance.new("Frame"), pos = {}, holders = {}, owner = {}, attrs = {}, destroyed = false, tainted = false, hash = {} }
		insts[i] = I
		instId[I.inst] = I
	end

	-- model helpers ---------------------------------------------------------
	local expectLog = {}
	local function E(s) table.insert(expectLog, s) end
	local function valueOfSpec(spec)
		if spec.inner then return effective(inner[spec.inner].val) end
		return effective(spec.raw)
	end
	-- release a position's current value (retract)
	local function retractPos(I, k, nextVal)
		local cur = I.pos[k]
		if cur.kind == "tag" then
			if nextVal and nextVal.kind == "tag" and nextVal.obj == cur.obj then return "skip" end
			local removed = {}
			for n in cur.set do
				if MUT ~= "m2" and nextVal and nextVal.kind == "tag" and nextVal.set[n] then continue end
				I.holders[n][k] = nil
				if MUT == "m1" then I.holders[n] = {} end
				if next(I.holders[n]) == nil then I.holders[n] = nil table.insert(removed, n) end
			end
			if #removed > 0 then table.sort(removed) E("removeTag:" .. table.concat(removed, ",")) end
		elseif cur.kind == "group" then
			if MUT ~= "m3" and nextVal and nextVal.kind == "group" and nextVal.obj == cur.obj then return "skip" end
			if I.gpos and I.gpos[cur.obj] == k then I.gpos[cur.obj] = nil end
			for n, spec in cur.m do
				local o = I.owner[n]
				if o and o.kind == "pos" and o.k == k and o.obj == cur.obj then I.owner[n] = nil end
				if spec.inner then inner[spec.inner].subs[I.id .. ":" .. k .. ":" .. n] = nil end
			end
		end
	end
	-- returns collision name or nil
	local function processPos(I, k, val, wasSkip)
		if val.kind == "tag" then
			if wasSkip then return end
			local added = {}
			for n in val.set do
				if I.holders[n] == nil then I.holders[n] = {} end
				if next(I.holders[n]) == nil then table.insert(added, n) end
				I.holders[n][k] = true
			end
			if #added > 0 then table.sort(added) E("addTag:" .. table.concat(added, ",")) end
		elseif val.kind == "group" then
			if wasSkip then return end
			I.gpos = I.gpos or {}
			if I.gpos[val.obj] ~= nil and I.gpos[val.obj] ~= k then return "#Quad0016" end
			I.gpos[val.obj] = k
			-- follow the real pairs order of the NameMap for partial-collision prediction
			for n in pairs(val.obj:NameMap()) do
				local spec = val.m[n]
				if spec == nil then fail("model/NameMap mismatch name " .. n) return end
				local o = I.owner[n]
				if MUT == "m4" and o and o.kind == "hash" then o = nil end
				if o and not (o.kind == "pos" and o.k == k and o.obj == val.obj) then
					return n
				end
				I.owner[n] = { kind = "pos", k = k, obj = val.obj }
				local v = valueOfSpec(spec)
				I.attrs[n] = v
				E("setAttr:" .. n .. "=" .. tostring(v))
				if spec.inner then inner[spec.inner].subs[I.id .. ":" .. k .. ":" .. n] = { I = I, n = n } end
			end
		end
	end

	-- initial drive --------------------------------------------------------
	for _, I in insts do
		local props = {}
		local P = rng:NextInteger(2, 6)
		I.P = P
		for k = 1, P do
			local val = randPosValue()
			I.pos[k] = { kind = "empty", obj = nil }
			I.src = I.src or {}
			I.src[k] = q.Source(val.obj)
			props[k] = I.src[k]
			-- predict via same retract/process path from empty
			local c = processPos(I, k, val, false)
			if c then
				-- avoid initial collisions: replace with empty
				-- undo partial: simplest — rebuild: we re-roll as empty and restart model for this inst
				val = { kind = "empty", obj = nil }
				I.src[k] = q.Source(nil)
				props[k] = I.src[k]
				-- rollback partial ownership / attrs / expected log set by this group
				-- (recompute from scratch below)
				I.rebuild = true
			end
			I.pos[k] = val
		end
		if I.rebuild then
			-- recompute model from scratch with the final values
			I.holders, I.owner, I.attrs = {}, {}, {}
			for key in inner[1].subs do end
			for j = 1, #inner do for sk in inner[j].subs do if string.sub(sk, 1, #tostring(I.id) + 1) == I.id .. ":" then inner[j].subs[sk] = nil end end end
			-- drop expected log lines produced so far for this inst: rebuild log from scratch
			I.rebuild = nil
			local saved = expectLog
			expectLog = {}
			for k = 1, P do local v = I.pos[k] I.pos[k] = { kind = "empty" } local c = processPos(I, k, v, false) assert(not c) I.pos[k] = v end
			local mine = expectLog
			expectLog = saved
			-- remove this inst's previous (discarded) lines: we reset global expectLog per inst below
			I.driveLog = mine
		end
		-- hash AttrKey entries on names not owned
		for _, n in ATTRN do
			if I.owner[n] == nil and rng:NextNumber() < 0.3 then
				local r = rng:NextNumber()
				local v = if r < 0.7 then rng:NextInteger(1, 9) elseif r < 0.85 then None else nil
				local s = q.Source(v)
				I.hash[n] = s
				props[q.AttrKey(n)] = s
			end
		end
		I.props = props
	end
	-- recompute expected drive log per inst deterministically: reset model and replay array then hash
	expectLog = {}
	for _, I in insts do
		table.clear(log)
		local finals = I.pos
		I.pos, I.holders, I.owner, I.attrs, I.gpos = {}, {}, {}, {}, {}
		for j = 1, #inner do for sk in inner[j].subs do if string.sub(sk, 1, #tostring(I.id) + 1) == I.id .. ":" then inner[j].subs[sk] = nil end end end
		expectLog = {}
		for k = 1, I.P do I.pos[k] = { kind = "empty" } local c = processPos(I, k, finals[k], false) assert(not c, "drive collision") I.pos[k] = finals[k] end
		local hashExp = {}
		for n, s in I.hash do
			I.owner[n] = { kind = "hash" }
			I.attrs[n] = effective(s:Get())
			table.insert(hashExp, "setAttr:" .. n .. "=" .. tostring(effective(s:Get())))
		end
		for _, l in hashExp do E(l) end
		local ok, err = pcall(q.Dispatch.drive, I.inst, I.props)
		if not ok then fail("drive threw: " .. tostring(err)) end
		T("drive inst" .. I.id)
		-- compare multiset (hash order not specified)
		local a, b = table.clone(log), table.clone(expectLog)
		table.sort(a) table.sort(b)
		if table.concat(a, "|") ~= table.concat(b, "|") then fail("drive log inst" .. I.id .. " got=" .. table.concat(log, " ") .. " exp=" .. table.concat(expectLog, " ")) end
	end

	local function check(label)
		for _, I in insts do
			if I.tainted then continue end
			local tags = setOf(mock.getTags(I.inst))
			local exp = {}
			for n, h in I.holders do if next(h) then exp[n] = true end end
			if not I.destroyed and not eqSet(tags, exp) then fail(label .. ": inst" .. I.id .. " tags got={" .. table.concat(keys(tags), ",") .. "} exp={" .. table.concat(keys(exp), ",") .. "}") end
			local attrs = mock.getAttributes(I.inst)
			if fmtAttrs(attrs) ~= fmtAttrs(I.attrs) then fail(label .. ": inst" .. I.id .. " attrs got={" .. fmtAttrs(attrs) .. "} exp={" .. fmtAttrs(I.attrs) .. "}") end
		end
	end
	check("after drive")

	local nOps = rng:NextInteger(20, 60)
	for step = 1, nOps do
		if failed then break end
		stats.steps += 1
		table.clear(log)
		expectLog = {}
		local I = insts[rng:NextInteger(1, #insts)]
		if I.tainted then continue end
		local r = rng:NextNumber()
		local expectErr = nil
		local action, desc
		local frozenTags = I.destroyed and setOf(mock.getTags(I.inst)) or nil
		if r < 0.55 then
			local k = rng:NextInteger(1, I.P)
			local val
			if rng:NextNumber() < 0.12 then val = I.pos[k] stats.reemit += 1 else val = randPosValue(I, k) end
			desc = "pos" .. k .. " <- " .. val.kind .. "(" .. (val.how or "same") .. ")" .. (val.set and ("{" .. table.concat(keys(val.set), ",") .. "}") or "") .. (val.m and ("{" .. table.concat(keys(val.m), ",") .. "}") or "")
			if not I.destroyed and not I.tainted then
				local sk = retractPos(I, k, val)
				local c = processPos(I, k, val, sk == "skip")
				if c then expectErr = c end
				I.pos[k] = val
			end
			local src = I.src[k]
			action = function() src:Set(val.obj) end
		elseif r < 0.75 then
			local j = rng:NextInteger(1, #inner)
			local rr = rng:NextNumber()
			local v = if rr < 0.7 then rng:NextInteger(1, 9) elseif rr < 0.85 then None else nil
			desc = "inner" .. j .. " <- " .. tostring(v)
			inner[j].val = v
			-- every live subscription writes
			for sk, sub in inner[j].subs do
				if not sub.I.destroyed and not sub.I.tainted then
					sub.I.attrs[sub.n] = effective(v)
					E("setAttr:" .. sub.n .. "=" .. tostring(effective(v)))
				end
			end
			action = function() inner[j].src:Set(v) end
		elseif r < 0.93 then
			local names = keys(I.hash)
			if #names == 0 then continue end
			local n = names[rng:NextInteger(1, #names)]
			local rr = rng:NextNumber()
			local v = if rr < 0.7 then rng:NextInteger(1, 9) elseif rr < 0.85 then None else nil
			desc = "hash " .. n .. " <- " .. tostring(v)
			if not I.destroyed and not I.tainted then
				I.attrs[n] = effective(v)
				E("setAttr:" .. n .. "=" .. tostring(effective(v)))
			end
			action = function() I.hash[n]:Set(v) end
		else
			if I.destroyed then continue end
			desc = "destroy inst" .. I.id
			stats.destroys += 1
			action = function() I.inst:Destroy() end
			I.destroyed = true
		end
		T(string.format("s%d inst%d %s", step, I.id, desc))
		local ok, err = pcall(action)
		if expectErr then
			stats.collisions += 1
			local want = if expectErr == "#Quad0016" then "Quad0016" else "Quad0002"
			stats[want] = (stats[want] or 0) + 1
			if ok then fail("expected " .. want .. " on " .. expectErr .. " but no error")
			elseif H.idOf(err) ~= want then fail("expected " .. want .. " got " .. tostring(err)) end
			-- the colliding step's own lines are compared (partial writes before the collision name are predicted)
			stats.tainted += 1
			I.taintNext = true
		elseif not ok then
			fail("unexpected error: " .. tostring(err))
		end
		-- ignore log lines for tainted/destroyed? No: compare everything (destroyed insts must emit nothing)
		local a, b = table.clone(log), table.clone(expectLog)
		for _, l in a do if string.sub(l, 1, 3) == "set" then stats.attrCalls += 1 else stats.tagCalls += 1 end end
		table.sort(a) table.sort(b)
		if table.concat(a, "|") ~= table.concat(b, "|") then fail("log got=" .. table.concat(log, " ") .. " exp=" .. table.concat(expectLog, " ")) end
		-- ordering: within one step every removeTag precedes every addTag
		local sawAdd = false
		for _, l in log do if string.sub(l, 1, 6) == "addTag" then sawAdd = true elseif string.sub(l, 1, 9) == "removeTag" and sawAdd then fail("removeTag after addTag in one step: " .. table.concat(log, " ")) end end
		if I.taintNext then I.tainted = true I.taintNext = nil end
		if frozenTags and not eqSet(frozenTags, setOf(mock.getTags(I.inst))) then fail("destroyed inst tags changed") end
		check("after s" .. step)
	end
	stats.seeds += 1
	if failed then
		stats.diffs += 1
		if #diffSamples < 8 then table.insert(diffSamples, { seed = seed, msg = failed, trace = trace }) end
	end
end

for seed = START, START + SEEDS - 1 do
	local ok, err = pcall(runSeed, seed)
	if not ok then stats.diffs += 1 if #diffSamples < 8 then table.insert(diffSamples, { seed = seed, msg = "HARNESS: " .. tostring(err), trace = {} }) end end
end
print("Quad0002:", stats.Quad0002 or 0, "Quad0016:", stats.Quad0016 or 0)
print("zombie lines from tainted insts (orphan subscriptions after Quad0002):", stats.zombie or 0)
print(string.format("seeds=%d steps=%d collisions(expected Quad0002)=%d tainted=%d destroys=%d reemit=%d tagCalls=%d attrCalls=%d DIFFS=%d",
	stats.seeds, stats.steps, stats.collisions, stats.tainted, stats.destroys, stats.reemit, stats.tagCalls, stats.attrCalls, stats.diffs))
for _, d in diffSamples do
	print("--- seed " .. d.seed .. ": " .. d.msg)
	if VERBOSE then for _, t in d.trace do print("   " .. t) end end
end
