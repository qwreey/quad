-- E73 item 2c: differential fuzz for E69's ST04 / SR05 / ST09 (claimed equivalent).
-- Random State graphs (Source → Compute/Gate chains, multi-dep), random op sequences
-- (Set incl. same value, Get, gate emit true/false/nil), Compute fns that Set re-entrantly, observer fire counts,
-- one trace line per seed. The driver diffs the output of the original and each mutant.
local mock = require("./mock")
local SEEDS = 2000
local out = {}
for seed = 1, SEEDS do
	math.randomseed(seed)
	local q = mock.newQuad()
	local trace = {}
	local function rec(s) trace[#trace + 1] = s end
	local sources, nodes, emits, gateHolding = {}, {}, {}, {}
	for i = 1, math.random(2, 5) do
		local s = q.Source(math.random(0, 3)); sources[i] = s; nodes[#nodes + 1] = s
	end
	for i = 1, math.random(3, 12) do
		local kind = math.random(1, 3)
		local a = nodes[math.random(1, #nodes)]
		if kind == 3 then
			local gi = #emits + 1
			local mode = math.random(1, 3) -- 1 hold, 2 pass-through, 3 pass every other
			local cnt = 0
			nodes[#nodes + 1] = a:Gate(function(emit)
				emits[gi] = emit
				return function()
					cnt += 1
					if mode == 2 or (mode == 3 and cnt % 2 == 0) then emit() end
				end
			end)
		elseif kind == 2 then
			local b = nodes[math.random(1, #nodes)]
			local c = math.random(0, 2)
			nodes[#nodes + 1] = a:Compute(function(x, _p, y) return (x:Get() + y:Get() * 2 + c) % 7 end, b)
		else
			local c = math.random(0, 3)
			local side = if math.random(1, 3) == 1 then sources[math.random(1, #sources)] else nil
			local runs = 0
			nodes[#nodes + 1] = a:Compute(function(x)
				runs += 1
				local v = (x:Get() * 3 + c) % 5
				if side ~= nil and runs % 3 == 1 then side:Set((runs + c) % 4) end -- reentrant Set inside fn
				return v
			end)
		end
	end
	-- observers only COUNT (no Get, no Set): subscriber iteration order is a hash order that varies
	-- between processes, so anything order-dependent is kept out of the trace (baseline must be stable)
	local counts, keep = {}, {}
	for i = 1, math.random(1, 5) do
		local n = nodes[math.random(1, #nodes)]
		counts[i] = 0
		local o = n:Observer(function() counts[i] += 1 end)
		o:Subscribe()
		keep[#keep + 1] = o
	end
	local function snap()
		local t = {}
		for i = 1, #counts do t[i] = counts[i] end
		rec("c" .. table.concat(t, "."))
	end
	for _ = 1, 60 do
		local r = math.random(1, 10)
		local ok, e = pcall(function()
			if r <= 4 then
				sources[math.random(1, #sources)]:Set(math.random(0, 3))
			elseif r <= 7 then
				local k = math.random(1, #nodes)
				rec("g" .. k .. "=" .. tostring(nodes[k]:Get()))
			elseif #emits > 0 then
				local em = emits[math.random(1, #emits)]
				local c = math.random(1, 3)
				rec("e" .. tostring(em(if c == 1 then true elseif c == 2 then false else nil)))
			end
		end)
		if not ok then rec("ERR " .. (string.match(tostring(e), "Quad%d+") or tostring(e))) end
		snap()
	end
	for k = 1, #nodes do rec("f" .. k .. "=" .. tostring(nodes[k]:Get())) end
	out[#out + 1] = seed .. " " .. table.concat(trace, ",")
	local _ = keep
end
print(table.concat(out, "\n"))
