--!nocheck
-- p-q76b differential fuzzer for Slot:List reconcile (Q76 A1+A1b vs base).
-- Run from <copy>/quad-base:  luau test/fuzz.list.luau -a <fromSeed> <count> [verboseSeed]
-- Needs the scratch-only probe hook `module._probeOwner = elementOwner` (Slot/init.luau), identical in every copy.
-- Emits one line per step:
--   S <seed> <step> <finalHash> <nonGoneUpdHash> <goneSetHash> <goneOrd> <pattern> <descOk> <destroySetHash> <destroyOrdHash> <physOps> <aliveOldAtFirstNew> <viol> <known> <err>
local mock = require("./mock")
local Instance = mock.Instance

-- 32-bit FNV-1a
local function H(s: string): string
	local h = 2166136261
	for i = 1, #s do
		h = bit32.bxor(h, string.byte(s, i))
		h = (h * 16777619) % 4294967296
	end
	return string.format("%08x", h)
end

local function nm(e) return if e == nil then "nil" else e.Name end

local function newEnv()
	local q = mock.newQuad()
	local phys = setmetatable({}, { __mode = "k" })
	local env = { q = q, phys = phys, violations = {}, known = {}, oplog = {}, counts = {} }
	local function P(t) local l = phys[t]; if not l then l = {}; phys[t] = l end; return l end
	env.P = P
	local function viol(msg) table.insert(env.violations, msg) end
	local function count(k) env.counts[k] = (env.counts[k] or 0) + 1 end
	local function checkBlock(t, off, els, op)
		local l = P(t)
		for k, e in ipairs(els) do
			if l[off + k] ~= e then
				viol(`{op}: expected {nm(e)} at phys[{off + k}] got {nm(l[off + k])}`)
				return false
			end
		end
		return true
	end
	local function removeBlock(t, off, els, op)
		local l = P(t)
		local first = els[1] and table.find(l, els[1])
		if first and first - 1 ~= off then
			local contiguous = true
			for k, e in ipairs(els) do if l[first + k - 1] ~= e then contiguous = false end end
			if contiguous then
				-- stale offset (Q75 class) — record separately, apply at the real place
				table.insert(env.known, `stale {op}: passed {off}, actual {first - 1} ({nm(els[1])})`)
				for _ = 1, #els do table.remove(l, first) end
				return
			end
		end
		if not checkBlock(t, off, els, op) then
			for _, e in ipairs(els) do local i = table.find(l, e); if i then table.remove(l, i) end end
			return
		end
		for _ = 1, #els do table.remove(l, off + 1) end
	end
	local function insertBlock(t, off, els, op)
		local l = P(t)
		if off < 0 or off > #l then viol(`{op}: offset {off} out of [0,{#l}]`); off = math.clamp(off, 0, #l) end
		for k, e in ipairs(els) do table.insert(l, off + k, e) end
	end
	local function lognames(tag, els) for _, e in els do table.insert(env.oplog, tag .. nm(e)) end end
	local B = q.Backend
	B.nativeInsert = function(t, off, els) count("I"); lognames("I", els); insertBlock(t, off, els, "insert"); for _, e in els do e.Parent = t end end
	B.nativeExtract = function(t, off, els, new)
		count("X"); lognames("X", els)
		removeBlock(t, off, els, "extract"); for _, e in els do e.Parent = nil end
		if new then lognames("I", new); insertBlock(t, off, new, "extract/new"); for _, e in new do e.Parent = t end end
	end
	B.nativeRemove = function(t, off, els, new)
		count("R"); lognames("R", els)
		removeBlock(t, off, els, "remove"); for _, e in els do e:Destroy() end
		if new then lognames("I", new); insertBlock(t, off, new, "remove/new"); for _, e in new do e.Parent = t end end
	end
	B.nativeMove = function(t, fo, els, to)
		count("M")
		-- the to-offset is checked against the physical list AFTER removal (the E1 harness' reading)
		removeBlock(t, fo, els, "move"); insertBlock(t, to, els, "move/to")
	end
	B.nativeSwap = function(t, oa, ea, ob, eb)
		count("W")
		local okA = checkBlock(t, oa, ea, "swapA"); local okB = checkBlock(t, ob, eb, "swapB")
		local l = P(t)
		if not (okA and okB) then return end
		local before = table.move(l, 1, oa, 1, {})
		local mid = table.move(l, oa + #ea + 1, ob, 1, {})
		local after = table.move(l, ob + #eb + 1, #l, 1, {})
		local out = {}
		for _, x in before do table.insert(out, x) end
		for _, x in eb do table.insert(out, x) end
		for _, x in mid do table.insert(out, x) end
		for _, x in ea do table.insert(out, x) end
		for _, x in after do table.insert(out, x) end
		phys[t] = out
	end
	B.nativeDispose = function(e)
		count("D"); table.insert(env.oplog, "D" .. nm(e))
		for _, l in pairs(phys) do local i = table.find(l, e); if i then table.remove(l, i) end end
		e:Destroy()
	end
	q.Dispatch.addHandler({
		name = "ProbeLeaf",
		isHandlable = function(_i, k, v) return type(k) == "number" and type(v) == "string" end,
		priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(inst, k, v, _index)
			local f = Instance.new("Frame"); f.Name = v
			q.Bookkeeping.setOffsetSource(inst, k, q.None)
			B.nativeInsert(inst, q.Bookkeeping.getOffsetAt(inst, k), { f })
			q.Bookkeeping.setLength(inst, k, 1)
			return q.Void
		end,
	})
	return env
end

local KINDS = { "frame", "slot", "state", "nil" }

local function run(seed, verbose)
	local curStep = 0
	local growN = {}
	math.randomseed(seed)
	local env = newEnv()
	local q = env.q
	local owner = q._probeOwner
	local parent = Instance.new("Folder"); parent.Name = "P"
	local owns = math.random(3) ~= 1 -- ~1/3 seeds OwnsElements=false
	local N0 = math.random(1, 200)
	local steps = math.random(1, 50)
	local nextId = 0
	local function newItem()
		nextId += 1
		local r = math.random(10)
		return { id = nextId, kind = if r <= 6 then "frame" elseif r <= 8 then "slot" elseif r == 9 then "state" else "nil" }
	end
	local init = {}
	for i = 1, N0 do init[i] = newItem() end
	local data = q.Source(init)
	local made = {} -- key -> { kind, value, gen, dead }
	local gens = {}
	local detachOnGone = {}
	local calls = {}
	local destroyLog = {}
	local liveOldAtFirstNew = -1
	local goneThisStep = {} -- key -> element (to count "still alive old ones" at first update call)
	local function mkFrame(name)
		local f = Instance.new("Frame"); f.Name = name
		f.Destroying:Connect(function() table.insert(destroyLog, name) end)
		return f
	end
	local function updateFn(ctx)
		local item = ctx.Item
		if item == q.KeyGone then
			table.insert(calls, "G" .. tostring(ctx.UserData))
			return (if detachOnGone[ctx.UserData] then q.Detach else nil), ctx.UserData
		end
		local key = item.id
		table.insert(calls, "U" .. key)
		if liveOldAtFirstNew < 0 then
			-- how many to-be-gone elements are still undestroyed & parented when the first item call happens
			local n = 0
			for _, v in goneThisStep do
				local inst = if q.isSlot(v) then (v._elements[1]) elseif q.isState(v) then v:Get() else v
				if inst ~= nil and not mock.isDestroyed(inst) and inst.Parent ~= nil then n += 1 end
			end
			liveOldAtFirstNew = n
		end
		local kind = item.kind
		local m = made[key]
		if kind == "nil" then return nil, key end
		if m and m.kind == kind and not m.dead then
			if MODE == "rowgrow" and kind == "slot" and ctx.Prev == m.value then
				local r = (key + curStep) % 3
				if r == 0 then
					growN[key] = (growN[key] or 0) + 1
					m.value:Add(mkFrame(`k{key}a{growN[key]}`))
				elseif r == 1 and #m.value._elements > 0 then
					m.value:Remove(#m.value._elements)
				end
			end
			return m.value, key
		end
		gens[key] = (gens[key] or 0) + 1
		local g = gens[key]
		local base = `k{key}g{g}`
		local v
		if kind == "frame" then
			v = mkFrame(base)
		elseif kind == "slot" then
			local fs = {}
			for j = 1, (key * 7 + g) % 3 do table.insert(fs, mkFrame(`{base}s{j}`)) end
			v = q.Slot(fs)
		else
			v = q.Source(mkFrame(base .. "st"))
		end
		made[key] = { kind = kind, value = v }
		return v, key
	end
	local root = q.Slot()
	local holder = q.Source(root)
	root:List(data, updateFn, function(item) return item.id end, if owns then nil else { OwnsElements = false })
	q.Dispatch.drive(parent, { "L", holder, "T" })
	local isMounted = true

	local function leafNames(s, out)
		for _, e in ipairs(s._elements) do
			if q.isSlot(e) and e._wrapped == nil then out[#out + 1] = "["; leafNames(e, out); out[#out + 1] = "]"
			elseif q.isSlot(e) then out[#out + 1] = "T(" .. nm(e._wrapped:Get()) .. ")"
			else out[#out + 1] = nm(e) end
		end
		return out
	end
	local function ownerTag(x)
		local o = owner:GetWeak(x, "__owner")
		if o == nil then return "-" elseif o == root then return "R" elseif o == parent then return "P" else return "?" end
	end
	local function digest()
		local parts = {}
		-- raw order + per-element owner + nested Length/Offset
		local raw = {}
		for i, e in ipairs(root._elements) do
			local d
			if q.isSlot(e) then
				d = (if e._wrapped then "T" else "S") .. table.concat(leafNames(e, {}), ",") .. `|L{e.Length:Get()}O{e.Offset:Get()}`
			else d = nm(e) end
			raw[i] = d .. "#" .. ownerTag(e)
		end
		table.insert(parts, "raw=" .. table.concat(raw, ";"))
		table.insert(parts, `root L{root.Length:Get()} O{root.Offset:Get()}`)
		local det = {}
		if root._detached then for k, e in pairs(root._detached) do table.insert(det, `{k}:{if q.isSlot(e) and e._wrapped then "T" .. nm(e._wrapped:Get()) elseif q.isSlot(e) then "S" else nm(e)}#{ownerTag(e)}`) end end
		table.sort(det)
		table.insert(parts, "det=" .. table.concat(det, ","))
		-- key -> element identity and liveness for every key ever made
		local ks = {}
		for k in made do table.insert(ks, k) end
		table.sort(ks)
		local kv = {}
		for _, k in ks do
			local v = made[k].value
			local dead
			if q.isSlot(v) then dead = v._destroyed and "d" or "a"
			elseif q.isState(v) then dead = mock.isDestroyed(v:Get()) and "d" or "a"
			else dead = mock.isDestroyed(v) and "d" or "a" end
			local label = if q.isSlot(v) then "S" elseif q.isState(v) then "T" .. nm(v:Get()) else nm(v)
			table.insert(kv, `{k}={label}{dead}{ownerTag(v)}`)
		end
		table.insert(parts, "keys=" .. table.concat(kv, ","))
		table.insert(parts, "kids=" .. #parent:GetChildren())
		local ph = {}
		for i, e in ipairs(env.P(parent)) do ph[i] = nm(e) end
		local exp = { "L" }
		if isMounted then
			local function lv(sl) for _, e in ipairs(sl._elements) do if q.isSlot(e) and e._wrapped then table.insert(exp, nm(e._wrapped:Get())) elseif q.isSlot(e) then lv(e) else table.insert(exp, nm(e)) end end end
			lv(root)
		end
		table.insert(exp, "T")
		local phs = table.concat(ph, ",")
		return table.concat(parts, " "), phs, (if phs == table.concat(exp, ",") then "y" else "n")
	end

	for step = 1, steps do
		curStep = step
		-- ── choose the next list (RNG only here, never in callbacks) ──
		local cur = data:Get()
		local nxt = table.clone(cur)
		local op = math.random(12)
		local opname
		if op <= 2 then
			opname = "ins"
			for _ = 1, math.random(1, 5) do table.insert(nxt, math.random(#nxt + 1), newItem()) end
		elseif op <= 4 then
			opname = "del"
			for _ = 1, math.random(1, math.max(1, math.floor(#nxt / 3))) do if #nxt > 0 then table.remove(nxt, math.random(#nxt)) end end
		elseif op <= 6 then
			opname = "move"
			for _ = 1, math.random(1, 4) do if #nxt > 1 then local it = table.remove(nxt, math.random(#nxt)); table.insert(nxt, math.random(#nxt + 1), it) end end
		elseif op == 7 then
			opname = "replace"
			nxt = {}
			for i = 1, math.random(0, 200) do nxt[i] = newItem() end
		elseif op == 8 then
			opname = "reverse"
			local r = {}
			for i = #nxt, 1, -1 do r[#r + 1] = nxt[i] end
			nxt = r
		elseif op == 9 then
			opname = "kind"
			for _ = 1, math.random(1, 4) do if #nxt > 0 then local i = math.random(#nxt); nxt[i] = { id = nxt[i].id, kind = KINDS[math.random(4)] } end end
		elseif op == 10 then
			opname = "revive" -- bring back previously gone keys (hits the detached revival path)
			local present = {}
			for _, it in nxt do present[it.id] = true end
			for _ = 1, math.random(1, 4) do
				local id = math.random(math.max(1, nextId))
				if not present[id] and made[id] then present[id] = true; table.insert(nxt, math.random(#nxt + 1), { id = id, kind = made[id].kind }) end
			end
		elseif op == 11 then
			opname = "mix"
			for _ = 1, math.random(1, 3) do if #nxt > 0 then table.remove(nxt, math.random(#nxt)) end end
			for _ = 1, math.random(1, 3) do table.insert(nxt, math.random(#nxt + 1), newItem()) end
			for _ = 1, math.random(0, 3) do if #nxt > 1 then local a, b = math.random(#nxt), math.random(#nxt); nxt[a], nxt[b] = nxt[b], nxt[a] end end
		else
			opname = "partreplace" -- replace a contiguous run with new keys
			if #nxt > 0 then
				local a = math.random(#nxt); local b = math.random(a, #nxt)
				for i = a, b do nxt[i] = newItem() end
			end
		end
		for id = 1, nextId do detachOnGone[id] = math.random(3) == 1 end
		local toggle = math.random(15) == 1
		-- pre-step raw index of each gone key (for the descending-order check)
		local nextSet = {}
		for _, it in nxt do nextSet[it.id] = true end
		local preIdx = {}
		table.clear(goneThisStep)
		for _, it in cur do
			if not nextSet[it.id] and made[it.id] and it.kind ~= "nil" then
				local v = made[it.id].value
				for i, e in ipairs(root._elements) do
					if e == v or (q.isSlot(e) and e._wrapped == v) then preIdx[it.id] = i; goneThisStep[it.id] = v; break end
				end
			end
		end
		table.clear(calls); table.clear(destroyLog); table.clear(env.oplog); table.clear(env.counts)
		table.clear(env.violations); table.clear(env.known)
		liveOldAtFirstNew = -1
		local ok, err = pcall(function() data:Set(nxt) end)
		local errs = if ok then "-" else string.gsub(tostring(err), "%s+", "_")
		-- ── observations ──
		local nonGone, gone = {}, {}
		local firstU, lastG, firstG, lastU = nil, nil, nil, nil
		for i, c in calls do
			if string.sub(c, 1, 1) == "G" then
				table.insert(gone, string.sub(c, 2)); firstG = firstG or i; lastG = i
			else table.insert(nonGone, c); firstU = firstU or i; lastU = i end
		end
		local pattern = if #gone == 0 then "noG" elseif #nonGone == 0 then "onlyG"
			elseif lastG < firstU then "GU" elseif lastU < firstG then "UG" else "mixed"
		-- descending by pre-step raw index (keys without an index — detached/nil kind — are 0)
		local descOk = "y"
		for i = 2, #gone do
			local a, b = preIdx[tonumber(gone[i - 1])] or 0, preIdx[tonumber(gone[i])] or 0
			if a < b then descOk = "n" break end
		end
		local sortedGone = table.clone(gone); table.sort(sortedGone)
		local sortedDestroy = table.clone(destroyLog); table.sort(sortedDestroy)
		local ops = {}
		for _, k in { "I", "X", "R", "M", "W", "D" } do table.insert(ops, k .. (env.counts[k] or 0)) end
		local dordPre = H(table.concat(destroyLog, "."))
		local ncalls, ndestroy = #calls, #destroyLog
		if toggle then
			isMounted = not isMounted
			local ok2, e2 = pcall(function() holder:Set(if isMounted then root else nil) end)
			if not ok2 then errs ..= "|toggle:" .. string.gsub(tostring(e2), "%s+", "_") end
		end
		-- mark dead
		for _, m in made do
			local v = m.value
			if q.isSlot(v) then if v._destroyed then m.dead = true end
			elseif q.isState(v) then if mock.isDestroyed(v:Get()) then m.dead = true end
			elseif mock.isDestroyed(v) then m.dead = true end
		end
		local d, phs, physOk = digest()
		local goneOrd = if #gone <= 12 then table.concat(gone, ".") else ("#" .. #gone .. ":" .. H(table.concat(gone, ".")))
		if goneOrd == "" then goneOrd = "_" end
		print(`S {seed} {step} {opname} own={owns and 1 or 0} tg={toggle and 1 or 0} fin={H(d)} ph={H(phs)} phok={physOk} upd={H(table.concat(nonGone, "."))} gset={H(table.concat(sortedGone, "."))} gord={goneOrd} pat={pattern} desc={descOk} dset={H(table.concat(sortedDestroy, "."))} dord={dordPre} tcalls={#calls - ncalls} tdestroy={#destroyLog - ndestroy} tdord={H(table.concat(destroyLog, ".", ndestroy + 1))} ops={table.concat(ops, ",")} old={liveOldAtFirstNew} viol={#env.violations} stale={#env.known} stk={(function() local c = {} for _, m in env.known do local k = string.match(m, "^stale (%S+):") or "?"; c[k] = (c[k] or 0) + 1 end local t = {} for k, n in c do t[#t+1] = k .. n end table.sort(t) return if #t == 0 then "_" else table.concat(t, ",") end)()} err={errs}`)
		if verbose then
			print("   list:", (function() local t = {} for _, it in nxt do t[#t+1] = it.id .. string.sub(it.kind, 1, 1) end return table.concat(t, " ") end)())
			print("   calls:", table.concat(calls, " "))
			print("   destroy:", table.concat(destroyLog, " "))
			print("   oplog:", table.concat(env.oplog, " "))
			for _, v in env.violations do print("   VIOL", v) end
			for _, v in env.known do print("   STALE", v) end
			print("   digest:", d)
		end
	end
end

local args = { ... }
local from = tonumber(args[1]) or 1
local cnt = tonumber(args[2]) or 100
local verboseSeed = tonumber(args[3])
MODE = args[4] or "plain"
for sd = from, from + cnt - 1 do
	run(sd, sd == verboseSeed)
end
