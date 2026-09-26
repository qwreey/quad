--!nocheck
local H = require("./probe.e1.harness")
local q, Instance, Slot, dispatch = H.q, H.Instance, H.Slot, H.dispatch
local leaves, names, nm = H.leaves, H.names, H.nm

local function run(seed, steps, owns)
	math.randomseed(seed)
	table.clear(H.violations)
	local parent = Instance.new("Folder")
	local data = q.Source({})
	local detachOnGone = {}
	local kinds = {} -- key -> kind this cycle
	local made = {} -- key -> {kind, value}
	local calls = {}
	local function updateFn(ctx)
		local item = ctx.Item
		if item == q.KeyGone then
			return (if detachOnGone[ctx.UserData] then q.Detach else nil), ctx.UserData
		end
		local key = item.id
		local kind = item.kind
		local m = made[key]
		if kind == "nil" then return nil, key end
		if m and m.kind == kind and not m.dead then return m.value, key end
		local v
		if kind == "frame" then
			v = Instance.new("Frame"); v.Name = "k" .. key
		elseif kind == "slot" then
			local fs = {}
			for j = 1, math.random(0, 2) do local f = Instance.new("Frame"); f.Name = `k{key}s{j}`; table.insert(fs, f) end
			v = Slot(fs)
		elseif kind == "state" then
			local f = Instance.new("Frame"); f.Name = "k" .. key .. "st"
			v = q.Source(f)
		end
		made[key] = { kind = kind, value = v }
		return v, key
	end
	local root = Slot()
	root:List(data, updateFn, function(item) return item.id end, if owns == false then { OwnsElements = false } else nil)
	dispatch.drive(parent, { "L", root, "T" })
	local log = {}
	local function expected()
		local exp = { "L" }
		for _, item in ipairs(data:Get()) do
			local m = made[item.id]
			if item.kind ~= "nil" and m then
				local v = m.value
				if q.isSlot(v) then for _, e in ipairs(leaves(v)) do table.insert(exp, nm(e)) end
				elseif q.isState(v) then table.insert(exp, nm(v:Get()))
				else table.insert(exp, nm(v)) end
			end
		end
		table.insert(exp, "T")
		return table.concat(exp, ",")
	end
	for step = 1, steps do
		local cur = data:Get()
		local nextList = {}
		local present = {}
		for _, it in ipairs(cur) do if math.random(5) > 1 then table.insert(nextList, { id = it.id, kind = if math.random(4) == 1 then ({ "frame", "slot", "nil", "state" })[math.random(4)] else it.kind }) ; present[it.id] = true end end
		for _ = 1, math.random(0, 2) do
			local id = math.random(12)
			if not present[id] then present[id] = true; table.insert(nextList, math.random(#nextList + 1), { id = id, kind = ({ "frame", "slot", "nil", "state" })[math.random(4)] }) end
		end
		-- shuffle a bit
		for _ = 1, math.random(0, 2) do
			if #nextList > 1 then local a, b = math.random(#nextList), math.random(#nextList); nextList[a], nextList[b] = nextList[b], nextList[a] end
		end
		for id = 1, 12 do detachOnGone[id] = math.random(2) == 1 end
		-- if element got destroyed (gone w/o detach) mark dead
		local desc = {}
		for _, it in nextList do table.insert(desc, `{it.id}{string.sub(it.kind, 1, 2)}`) end
		table.insert(log, table.concat(desc, " "))
		local ok, err = pcall(function() data:Set(nextList) end)
		if not ok then print(`seed {seed} step {step} ERROR {err}`); print("  log:", table.concat(log, " | ")); return false end
		-- mark dead: elements destroyed
		for key, m in made do
			local v = m.value
			if q.isSlot(v) and v._destroyed then m.dead = true
			elseif not q.isSlot(v) and not q.isState(v) and H.mock.isDestroyed(v) then m.dead = true
			elseif q.isState(v) and H.mock.isDestroyed(v:Get()) then m.dead = true end
		end
		local got = names(H.P(parent))
		local want = expected()
		local problems = {}
		if got ~= want then table.insert(problems, `phys {got} ~= {want}`) end
		for _, v in H.violations do table.insert(problems, v) end
		local nl = #leaves(root)
		if root.Length:Get() ~= nl then table.insert(problems, `Length {root.Length:Get()} ~= {nl}`) end
		if #parent:GetChildren() ~= #string.split(want, ",") then table.insert(problems, `mock children {#parent:GetChildren()} ~= {#string.split(want, ",")}`) end
		if #problems > 0 then
			print(`seed {seed} step {step} owns={tostring(owns)}:`)
			for _, p in problems do print("   ", p) end
			print("  log:", table.concat(log, " | "))
			return false
		end
	end
	return true
end

local a, n = ...
local from = tonumber(a) or 1
local cnt = tonumber(n) or 200
local fails = 0
for sd = from, from + cnt - 1 do
	for _, owns in { true, false } do
		if not run(sd, 40, owns) then fails += 1 end
	end
	if fails >= 3 then break end
end
print("fails", fails)
