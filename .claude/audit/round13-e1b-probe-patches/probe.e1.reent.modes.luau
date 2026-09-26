--!nocheck
-- E1-2 variant of round13-e1-probe-fuzz/probe.e1.reent.luau: 3rd arg mode = excl (original) | unm (allow CRUD of unmounted new subtrees → Q73) | anc (also ancestors → Q74); needs ./probe.e1.harness; counts all fail seeds + Quad0167 rejections
local H = require("./probe.e1.harness")
local q, Instance, Slot, dispatch = H.q, H.Instance, H.Slot, H.dispatch
local leaves, names, nm = H.leaves, H.names, H.nm

local sid
local curOp
local preDump
EXCL_ANC = (select(3, ...)) ~= "anc"
EXCL_UNMOUNTED = (select(3, ...)) ~= "anc" and (select(3, ...)) ~= "unm"
FAILSEEDS = {}
REJ167 = 0
OBSOPS = 0
physBad = 0
local seed = tonumber((...)) or 1
local verbose = false
local function run(seed, steps)
	math.randomseed(seed)
	table.clear(H.violations)
	local parent = Instance.new("Folder")
	local R, R2 = Slot(), Slot()
	local counter = 0
	local function frame() counter += 1; local f = Instance.new("Frame"); f.Name = "f" .. counter; return f end
	R:Add(frame()); R2:Add(frame())
	dispatch.drive(parent, { "L", R, "M", R2, "T" })
	local pool = {} -- extracted alive elements
	local ids, nid = {}, 0
	function sid(s) if not ids[s] then nid += 1; ids[s] = "S" .. nid end; return ids[s] end
	sid(R); sid(R2)
	local log = {}
	local function allSlots(s, out)
		out = out or {}
		table.insert(out, s)
		for _, e in ipairs(s._elements) do if q.isSlot(e) then allSlots(e, out) end end
		return out
	end
	local function check(step, op)
		local exp = { "L" }
		for _, e in ipairs(leaves(R)) do table.insert(exp, nm(e)) end
		table.insert(exp, "M")
		for _, e in ipairs(leaves(R2)) do table.insert(exp, nm(e)) end
		table.insert(exp, "T")
		local got = names(H.P(parent))
		local want = table.concat(exp, ",")
		local problems = {}
		if got ~= want then physBad += 1 end
		table.clear(H.violations); table.clear(H.known)

		-- mock children count
		if #parent:GetChildren() ~= #exp then
			local inExp = {}
			for _, x in exp do inExp[x] = true end
			local extra = {}
			for _, c in parent:GetChildren() do if not inExp[c.Name] then table.insert(extra, c.Name) end end
			table.insert(problems, `mock children {#parent:GetChildren()} ~= {#exp}; extra: {table.concat(extra, ",")}`)
		end
		local physList = {}
		table.insert(physList, "L")
		for _, e in ipairs(leaves(R)) do table.insert(physList, e) end
		table.insert(physList, "M")
		for _, e in ipairs(leaves(R2)) do table.insert(physList, e) end
		-- logical order (not phys) for Offset checks
		if R.Offset:Get() ~= 1 then table.insert(problems, `R Offset {R.Offset:Get()} ~= 1`) end
		if R2.Offset:Get() ~= 2 + #leaves(R) then table.insert(problems, `R2 Offset {R2.Offset:Get()} ~= {2 + #leaves(R)}`) end
		for _, root in { R, R2 } do
			for _, s in allSlots(root) do
				local lv = leaves(s)
				if s._mounted ~= true or s._mountedInst ~= parent then table.insert(problems, `slot {sid(s)} _mounted={tostring(s._mounted)} inst ok={tostring(s._mountedInst == parent)}`) end
				if s.Length:Get() ~= #lv then table.insert(problems, `LOGICAL slot {sid(s)} Length {s.Length:Get()} ~= leaves {#lv}`) end
				if #lv > 0 then
					local pos = table.find(physList, lv[1])
					if pos and s.Offset:Get() ~= pos - 1 then table.insert(problems, `LOGICAL slot {sid(s)} Offset {s.Offset:Get()} ~= {pos - 1} (first leaf {nm(lv[1])})`) end
				end
			end
		end
		do
			local byName = {}
			for _, c in parent:GetChildren() do byName[c.Name] = c end
			local rebuilt = {}
			for _, x in physList do table.insert(rebuilt, if type(x) == "string" then byName[x] else x) end
			table.insert(rebuilt, byName.T)
			H.phys[parent] = rebuilt
		end
		if #problems > 0 then
			print(`seed {seed} step {step} op {op}:`)
			for _, p in problems do print("   ", p) end
			print("  pre:", preDump)
			print("  last:", log[#log])
			return false
		end
		return true
	end
	if not check(0, "init") then return false end
	local function elementOwnerOf(c)
		for _, root in { R, R2 } do for _, x in allSlots(root) do for _, e in ipairs(x._elements) do if e == c then return x end end end end
		return nil
	end
	local budget = 0
	local obsLog = {}
	local function reentrant(sl, which)
		return function()
			if budget <= 0 then return end
			budget -= 1
			local slots = {}
			for _, root in { R, R2 } do for _, x in allSlots(root) do table.insert(slots, x) end end
			local t = slots[math.random(#slots)]
			if EXCL_ANC then
				local anc = {}
				local c = curOp
				while c do anc[c] = true; c = elementOwnerOf(c) end
				if anc[t] then return end
			end
			if EXCL_UNMOUNTED then
				local c2 = t
				while c2 do if not c2._mounted then return end; c2 = elementOwnerOf(c2) end
			end
			local n = #t._elements
			local ok, e = pcall(function()
				local c = math.random(3)
				if c == 1 then t:Add(frame(), math.random(n + 1)); table.insert(obsLog, `[{sid(sl)}.{which}]` .. sid(t) .. ":oAdd")
				elseif c == 2 and n > 0 then t:Remove(math.random(n)); table.insert(obsLog, `[{sid(sl)}.{which}]` .. sid(t) .. ":oRemove")
				elseif n > 1 then t:Move(math.random(n), math.random(n)); table.insert(obsLog, `[{sid(sl)}.{which}]` .. sid(t) .. ":oMove") end
			end)
			OBSOPS += 1
			if not ok and string.find(tostring(e), "Quad0167", 1, true) then REJ167 += 1 end
			if not ok then table.insert(obsLog, "oERR " .. tostring(e):sub(1, 120)) end
		end
	end
	local observers = {}
	local function watch(sl)
		if observers[sl] then return end
		observers[sl] = { sl.Length:Observer(reentrant(sl, "Len")), sl.Offset:Observer(reentrant(sl, "Off")) }
		for _, o in observers[sl] do o:Subscribe() end
	end
	watch(R); watch(R2)
	for step = 1, steps do
		local slots = {}
		for _, root in { R, R2 } do for _, s in allSlots(root) do table.insert(slots, s) end end
		local s = slots[math.random(#slots)]
		curOp = s
		local function dump(x) local parts = {} for _, e in ipairs(x._elements) do table.insert(parts, if q.isSlot(e) then dump(e) else nm(e)) end return sid(x) .. "[" .. table.concat(parts, " ") .. "]" end
		preDump = dump(R) .. " " .. dump(R2)
		for _, x in slots do watch(x) end
		budget = math.random(0, 2)
		table.clear(obsLog)
		local n = #s._elements
		local r = math.random(12)
		local desc
		local function newEl()
			local c = math.random(4)
			if c == 1 and #pool > 0 then
				return table.remove(pool, math.random(#pool))
			elseif c == 2 then
				local ns = Slot()
				for _ = 1, math.random(0, 2) do ns:Add(frame()) end
				return ns
			end
			return frame()
		end
		local function dsc(e) return if q.isSlot(e) then `{sid(e)}[{names(leaves(e))}]` else nm(e) end
		local ok, err = pcall(function()
			if r <= 3 then
				local e = newEl(); local idx = math.random(n + 1)
				desc = `Add({dsc(e)},{idx})`
				s:Add(e, idx)
			elseif r == 4 and n > 0 then
				local i = math.random(n); desc = `Remove({i})`; s:Remove(i)
			elseif r == 5 and n > 0 then
				local i = math.random(n); desc = `Extract({i})`
				table.insert(pool, s:Extract(i))
			elseif r == 6 and n > 0 then
				local i = math.random(n); local e = newEl(); desc = `Extract({i},{dsc(e)})`
				table.insert(pool, s:Extract(i, e))
			elseif r == 7 and n > 0 then
				local i = math.random(n); local e = newEl(); desc = `Replace({i},{dsc(e)})`
				s:Replace(i, e)
			elseif r == 8 and n > 0 then
				local a, b = math.random(n), math.random(n); desc = `Move({a},{b})`; s:Move(a, b)
			elseif r == 9 and n > 0 then
				local a, b = math.random(n), math.random(n); desc = `Swap({a},{b})`; s:Swap(a, b)
			elseif r == 10 then
				local idx = math.random(n + 1); local rc = math.random(0, n + 1 - idx)
				local els = {}
				for _ = 1, math.random(0, 2) do table.insert(els, newEl()) end
				local ds = {}; for i, e in els do ds[i] = dsc(e) end
				desc = `Splice({idx},{rc},{table.concat(ds, ";")})`
				for _, x in s:Splice(idx, rc, table.unpack(els)) do table.insert(pool, x) end
			elseif r == 11 and n > 0 and math.random(3) == 1 then
				desc = "Clear"; s:Clear()
			elseif r == 12 and n > 0 and math.random(3) == 1 then
				desc = "ExtractAll"; for _, x in s:ExtractAll() do table.insert(pool, x) end
			else
				desc = "noop"
			end
		end)
		if not ok then
			local m = tostring(err)
			if not (m:find("Quad0173") or m:find("Quad0170") or m:find("Quad0171") or m:find("Quad0172") or m:find("Quad0242") or m:find("Quad0169") or m:find("Quad0165")) then
				print(`seed {seed} step {step} {desc} ERROR: {m}`)
				print("  log:", table.concat(log, " | "))
				return false
			end
			desc = desc .. "(rejected)"
			-- rejected element might have been pulled from the pool; drop it
		end
		table.insert(log, sid(s) .. ":" .. desc .. (if #obsLog > 0 then "{" .. table.concat(obsLog, ",") .. "}" else ""))
		if not check(step, desc) then return false end
	end
	return true
end

local fails = 0
local from, to = seed, seed + (tonumber((select(2, ...))) or 200) - 1
for sd = from, to do
	if not run(sd, 120) then fails += 1; table.insert(FAILSEEDS, sd) end
end
print("obsOps", OBSOPS, "rej0167", REJ167, "fails", fails, "physBad", physBad, "seeds", table.concat(FAILSEEDS, ","))
