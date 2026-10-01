--!nocheck
local Quad = require("../src")
local mock = require("./mock")
local quad = Quad.New()
mock.installLifetime(quad)
local Source, Effect = quad.Source, quad.Effect
local function run(kind)
	local dist = {}
	for trial = 1, 200 do
		local s = Source(0)
		local pad = {}
		for i = 1, trial % 7 do pad[i] = s:Observer(function() end):Subscribe() end
		local c = s:Compute(function(h) return h:Get() * 10 end)
		local seen = {}
		local a = c:Observer(function(t, _, from)
			if from ~= nil and t:Get() == 10 then s:Set(2) end
		end):Subscribe()
		local b
		if kind == "observer" then
			b = c:Observer(function(t, _, from) if from ~= nil then table.insert(seen, t:Get()) end end):Subscribe()
		else
			local first = true
			b = Effect(function() if first then first = false return end table.insert(seen, c:Get()) end, c):Subscribe()
		end
		s:Set(1)
		local key = table.concat(seen, ",")
		dist[key] = (dist[key] or 0) + 1
		a:Unsubscribe(); b:Unsubscribe()
		for _, p in pad do p:Unsubscribe() end
	end
	local parts = {}
	for k, n in dist do table.insert(parts, "[" .. k .. "]x" .. n) end
	table.sort(parts)
	print(kind, table.concat(parts, "  "))
end
run("observer")
run("effect")
