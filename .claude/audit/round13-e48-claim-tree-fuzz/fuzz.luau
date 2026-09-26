--!nocheck
-- E48 main differential fuzzer: random prefab tree × random descriptor tree → pcall(q.Claim) vs model.
-- usage: luau fuzz.luau -a <seeds> [startSeed]
local H = require("./harness")
local Model = require(({...})[4] or "./model")
local Random = require("./rng")
local Instance, idOf = H.Instance, H.idOf

local args = { ... }
local N = tonumber(args[1]) or 2000
local START = tonumber(args[2]) or 1
local VERBOSE = args[3] == "v"

local q = H.newQ()
if args[3] == "debug" then q.debug = true; local p0 = print; print = function(...) local s = table.concat({...}, " ") if not s:match("^Claim:") then p0(...) end end end
local M = q.Declaration.Mapper
local D = q.Declaration
local MapPart = q.newMapperClass("Part")

local CLASSES = { "Frame", "TextLabel", "ImageLabel", "TextButton", "ScrollingFrame", "Folder", "Part" }
local NAMES = { "A", "B", "C", "D", "E", "F", "G" }
local function mapperOf(cls)
	if cls == "Part" then return MapPart end
	return M[cls]
end
local function propOf(cls, rng)
	-- one class-valid property + value per class (Folder: Name is not written — rename breaks lookups)
	if cls == "TextLabel" or cls == "TextButton" then return "Text", "t" .. rng:NextInteger(1, 1e6) end
	if cls == "Part" then return "Anchored", rng:NextNumber() < 0.5 end
	if cls == "Folder" then return nil end
	return "BackgroundTransparency", rng:NextInteger(1, 1e6) / 1e6
end

local firedPool = {} -- descriptors consumed by earlier successful Claims (for cross-Claim reuse)

local stats = { seeds = 0, ok = 0, fail = {}, diffs = 0, dup = 0, preclaimed = 0, cases = {} }
local diffs = {}

local function snapshot(nodes)
	local s = {}
	for _, n in nodes do
		local inst = n.inst
		s[n] = {
			claimed = q.Backend.isClaimed(inst),
			parent = inst.Parent,
			bt = rawget(inst, "x") or inst.BackgroundTransparency,
			text = inst.Text,
			anch = inst.Anchored,
			nch = #n.children,
		}
	end
	return s
end

local function runSeed(seed)
	local rng = Random.new(seed)
	local all = {}
	local mirrorNodes = {}
	-- prefab
	local function mk(depth, cls)
		cls = cls or CLASSES[rng:NextInteger(1, #CLASSES)]
		local inst = Instance.new(cls)
		local node = { cls = cls, name = cls, children = {}, inst = inst, preclaimed = false }
		table.insert(all, node)
		if depth < 4 then
			local k = rng:NextInteger(0, depth == 1 and 6 or 4)
			for _ = 1, k do
				local c = mk(depth + 1)
				c.name = NAMES[rng:NextInteger(1, depth == 1 and #NAMES or 4)]
				c.inst.Name = c.name
				c.inst.Parent = inst
				table.insert(node.children, c)
			end
		end
		return node
	end
	local root = mk(1, CLASSES[rng:NextInteger(1, 5)])
	-- pre-claim some nodes (earlier Claim / nativeClaim) — a D-made child too
	for _, n in all do
		if n ~= root and rng:NextNumber() < 0.04 then
			q.Backend.nativeClaim(n.inst)
			n.preclaimed = true
		end
	end
	if rng:NextNumber() < 0.03 then q.Backend.nativeClaim(root.inst); root.preclaimed = true end
	if rng:NextNumber() < 0.1 and root.cls ~= "Part" then
		-- a Declaration-made (born-claimed) child parked in the template
		local name = NAMES[rng:NextInteger(1, #NAMES)]
		local inst = D.New("Frame")({ Name = name })
		inst.Parent = root.inst
		local n = { cls = "Frame", name = name, children = {}, inst = inst, preclaimed = true }
		table.insert(root.children, n)
		table.insert(all, n)
	end
	local descs = {}
	-- descriptor tree over the prefab
	local function mkD(node, isRoot)
		local d = { cls = node.cls, key = isRoot and q.MapperRoot or node.name, items = {} }
		if not isRoot then
			local r = rng:NextNumber()
			if r < 0.04 then d.key = "Zmissing"
			elseif r < 0.09 then
				local other = CLASSES[rng:NextInteger(1, #CLASSES)]
				d.cls = other
			end
		end
		local pool = table.clone(node.children)
		-- shuffle
		for i = #pool, 2, -1 do local j = rng:NextInteger(1, i); pool[i], pool[j] = pool[j], pool[i] end
		local take = rng:NextInteger(0, #pool)
		for i = 1, take do
			local c = pool[i]
			if c.preclaimed and rng:NextNumber() < 0.5 then continue end
			table.insert(d.items, { kind = "map", d = mkD(c, false) })
			if rng:NextNumber() < 0.15 and node.cls ~= "Part" then table.insert(d.items, { kind = "new" }) end
			if rng:NextNumber() < 0.08 then table.insert(d.items, { kind = "none" }) end
		end
		if #d.items > 0 and rng:NextNumber() < 0.03 then
			-- same descriptor object at a second slot (R3, errors/06:22)
			local src = d.items[rng:NextInteger(1, #d.items)]
			if src.kind == "map" then table.insert(d.items, { kind = "map", d = src.d }) end
		end
		if #node.children > 0 and rng:NextNumber() < 0.03 then
			-- a SECOND descriptor for an already-mapped key (R4)
			local c = node.children[rng:NextInteger(1, #node.children)]
			table.insert(d.items, { kind = "map", d = { cls = c.cls, key = c.name, items = {} } })
		end
		if rng:NextNumber() < 0.01 and #firedPool > 0 then
			local fd = firedPool[rng:NextInteger(1, #firedPool)]
			table.insert(d.items, { kind = "map", d = { cls = fd._className, key = fd._key, items = {}, preFired = true, real = fd } })
		end
		if #node.children > 0 and rng:NextNumber() < 0.02 then
			-- a descriptor at a non-positive-integer key (R7) — last, since the hash part is walked after the array part
			local c = node.children[rng:NextInteger(1, #node.children)]
			table.insert(d.items, { kind = "badkey", d = { cls = c.cls, key = c.name, items = {} }, key = ({ 0, -1, 1.5 })[rng:NextInteger(1, 3)] })
		end
		if rng:NextNumber() < 0.01 then d.propsNonTable = true end
		table.insert(descs, d)
		return d
	end
	local rootD = mkD(root, true)
	if rng:NextNumber() < 0.02 then rootD.preFired = true end
	if rng:NextNumber() < 0.05 then rootD.key = "KeyedRoot" end -- root key is ignored (roblox/04 debug note, Claim.luau G-4)

	-- build real descriptors bottom-up; values recorded for drive checks
	local built = {}
	local function build(d)
		if built[d] then return built[d] end
		if d.real then built[d] = d.real; return d.real end
		local p = {}
		local n = 0
		d.expect = {}
		for _, it in d.items do
			n += 1
			if it.kind == "map" then p[n] = build(it.d)
			elseif it.kind == "new" then p[n] = D.New("TextLabel")({ Name = "NEW" }); it.inst = p[n]
			elseif it.kind == "none" then p[n] = q.None
			elseif it.kind == "badkey" then n -= 1; p[it.key] = build(it.d) end
		end
		local prop, val = propOf(d.cls, rng)
		if prop then p[prop] = val; d.expect[prop] = val end
		local mk = (d.cls == "Part" or d.cls == "?") and MapPart or (M[d.cls] or q.newMapperClass(d.cls))
		local desc = mk(d.key)(d.propsNonTable and "notatable" or p)
		d.propsTable = p
		built[d] = desc
		return desc
	end
	local rootDesc = build(rootD)
	if rootD.preFired then
		-- consume it through a throwaway successful Claim of a fresh prefab (a real one-shot burn)
		local tmp = Instance.new(root.cls)
		local ok = pcall(q.Claim, tmp, rootDesc)
		if not ok then rootD.preFired = false end -- props could not be driven on tmp (never: same class)
	end

	local expected = Model.run(root, rootD)
	local before = snapshot(all)
	local ok, err = pcall(q.Claim, root.inst, rootDesc)
	stats.seeds += 1
	if expected.dupTouched then stats.dup += 1 end
	local function diff(msg)
		stats.diffs += 1
		if #diffs < 40 then table.insert(diffs, `seed {seed}: {msg}`) end
	end
	if rootD.preFired then
		-- rootDesc already burned by the throwaway Claim — its props now hold the TMP's... skip drive checks
	end
	if ok ~= expected.ok then
		diff(`outcome ok={ok} err={ok and "-" or idOf(err)} model={expected.ok and "ok" or expected.id}`)
		return
	end
	if not ok then
		local id = idOf(err)
		stats.fail[id] = (stats.fail[id] or 0) + 1
		if id ~= expected.id then diff(`id {id} model {expected.id}`) return end
		-- R9: nothing changed
		local after = snapshot(all)
		for n, b in before do
			local a = after[n]
			if a.claimed ~= b.claimed then diff(`fail left claim change on {n.name}`) end
			if a.bt ~= b.bt or a.text ~= b.text or a.anch ~= b.anch then diff(`fail left props on {n.name}`) end
			if a.parent ~= b.parent then diff(`fail moved {n.name}`) end
			if #n.inst:GetChildren() ~= b.nch then end
		end
		for _, d in descs do
			local desc = built[d]
			if desc and not d.preFired and desc._fired then diff("fail consumed a descriptor") end
		end
		-- idempotent retry
		local ok2, err2 = pcall(q.Claim, root.inst, rootDesc)
		if ok2 or idOf(err2) ~= id then diff(`retry changed outcome: {ok2 and "ok" or idOf(err2)}`) end
		-- clean retry: fresh valid descriptors that avoid pre-claimed / missing parts must succeed
		if not root.preclaimed then
			local function clean(node, isRoot)
				local items = {}
				local used = {}
				for _, c in node.children do
					if not c.preclaimed and not used[c.name] then
						-- first child with this name only (dup names are UB)
						local first
						for _, cc in node.children do if cc.name == c.name then first = cc break end end
						if first == c then used[c.name] = true; table.insert(items, clean(c, false)) end
					end
				end
				local mk = node.cls == "Part" and MapPart or M[node.cls]
				return mk(isRoot and q.MapperRoot or node.name)(items)
			end
			local ok3, err3 = pcall(q.Claim, root.inst, clean(root, true))
			if not ok3 then diff(`clean retry after {id} failed: {idOf(err3)}`) end
		end
		return
	end
	stats.ok += 1
	-- R10 success checks
	local claimedSet = {}
	for _, n in expected.claimed do claimedSet[n] = true end
	for _, n in all do
		local isC = q.Backend.isClaimed(n.inst)
		local want = claimedSet[n] or before[n].claimed
		if isC ~= want then diff(`claimed({n.name}/{n.cls}) = {isC}, want {want}`) end
	end
	for d, node in expected.mapping do
		for prop, val in d.expect do
			if node.inst[prop] ~= val then diff(`prop {prop} on {node.name} = {tostring(node.inst[prop])}, want {tostring(val)}`) end
		end
		-- R10 array slot replaced in place; bookkeeping offsets = prefix sum of lengths
		local off = 0
		for i, it in d.items do
			local v = d.propsTable[i]
			if it.kind == "map" then
				if v ~= expected.mapping[it.d].inst then diff(`slot {i} not replaced by its Instance`) end
			elseif it.kind == "new" then
				if v.Parent ~= node.inst then diff("new child not parented") end
			end
			local got = q.Bookkeeping.getOffsetAt(node.inst, i)
			if got ~= off then diff(`offset at {i} under {node.name} = {got}, want {off}`) end
			off += (it.kind == "none") and 0 or 1
		end
		if not built[d]._fired then diff("descriptor not consumed after success") end
		table.insert(firedPool, built[d])
		if node.inst.Parent ~= (node == root and nil or node.inst.Parent) then end
	end
	-- R11: reuse after success → 0027; R5: re-Claim of the root with a fresh descriptor → 0029
	local okR, errR = pcall(q.Claim, Instance.new(root.cls), rootDesc)
	if okR or idOf(errR) ~= "Quad0027" then diff(`reuse after success: {okR and "ok" or idOf(errR)}`) end
	local okS, errS = pcall(q.Claim, root.inst, mapperOf(root.cls)(q.MapperRoot)({}))
	if okS or idOf(errS) ~= "Quad0029" then diff(`re-Claim root: {okS and "ok" or idOf(errS)}`) end
end

local t0 = os.clock()
for s = START, START + N - 1 do
	local okRun, e = pcall(runSeed, s)
	if not okRun then
		stats.diffs += 1
		table.insert(diffs, `seed {s}: harness error {tostring(e)}`)
	end
end
print(`seeds {stats.seeds} ok {stats.ok} diffs {stats.diffs} dupTouched {stats.dup} time {string.format("%.2f", os.clock() - t0)}s`)
local ids = {}
for id, c in stats.fail do table.insert(ids, `{id}={c}`) end
table.sort(ids)
print("fail ids: " .. table.concat(ids, " "))
for _, d in diffs do print("  " .. d) end
