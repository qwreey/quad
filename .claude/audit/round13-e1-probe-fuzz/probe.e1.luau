--!nocheck
local H = require("./probe.e1.harness")
local q, Instance, Slot, dispatch = H.q, H.Instance, H.Slot, H.dispatch
local leaves, names, nm = H.leaves, H.names, H.nm

local sid
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
	local holder = q.Source(R)
	local rMounted = true
	dispatch.drive(parent, { "L", holder, "M", R2, "T" })
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
		if rMounted then for _, e in ipairs(leaves(R)) do table.insert(exp, nm(e)) end end
		table.insert(exp, "M")
		for _, e in ipairs(leaves(R2)) do table.insert(exp, nm(e)) end
		table.insert(exp, "T")
		local got = names(H.P(parent))
		local want = table.concat(exp, ",")
		local problems = {}
		if got ~= want then table.insert(problems, `phys {got} ~= expected {want}`) end
		for _, v in ipairs(H.violations) do table.insert(problems, v) end
		-- mock children count
		if #parent:GetChildren() ~= #exp then table.insert(problems, `mock children {#parent:GetChildren()} ~= {#exp}`) end
		local physList = {}
		table.insert(physList, "L")
		if rMounted then for _, e in ipairs(leaves(R)) do table.insert(physList, e) end end
		table.insert(physList, "M")
		for _, e in ipairs(leaves(R2)) do table.insert(physList, e) end
		-- logical order (not phys) for Offset checks
		if rMounted and R.Offset:Get() ~= 1 then table.insert(problems, `R Offset {R.Offset:Get()} ~= 1`) end
		local rl = if rMounted then #leaves(R) else 0
		if R2.Offset:Get() ~= 2 + rl then table.insert(problems, `R2 Offset {R2.Offset:Get()} ~= {2 + rl}`) end
		for _, root in (if rMounted then { R, R2 } else { R2 }) do
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
		if #problems > 0 then
			print(`seed {seed} step {step} op {op}:`)
			for _, p in problems do print("   ", p) end
			print("  log:", table.concat(log, " | "))
			return false
		end
		return true
	end
	if not check(0, "init") then return false end
	for step = 1, steps do
		local slots = {}
		for _, root in { R, R2 } do for _, s in allSlots(root) do table.insert(slots, s) end end
		for _, p in pool do if q.isSlot(p) and not p._destroyed then for _, s in allSlots(p) do table.insert(slots, s) end end end
		if math.random(15) == 1 then
			rMounted = not rMounted
			holder:Set(if rMounted then R else nil)
			table.insert(log, if rMounted then "MOUNT" else "UNMOUNT")
			if not check(step, "toggle") then return false end
			continue
		end
		local s = slots[math.random(#slots)]
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
			if not (m:find("Quad0173") or m:find("Quad0170") or m:find("Quad0171") or m:find("Quad0172") or m:find("Quad0242") or m:find("Quad0169")) then
				print(`seed {seed} step {step} {desc} ERROR: {m}`)
				print("  log:", table.concat(log, " | "))
				return false
			end
			desc = desc .. "(rejected)"
			-- rejected element might have been pulled from the pool; drop it
		end
		table.insert(log, sid(s) .. ":" .. desc)
		if not check(step, desc) then return false end
	end
	return true
end

local fails = 0
local from, to = seed, seed + (tonumber((select(2, ...))) or 200) - 1
for sd = from, to do
	if not run(sd, 120) then fails += 1; if fails >= 3 then break end end
end
print("fails", fails)
