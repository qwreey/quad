--!nocheck
-- round13 E20 probe C2b — re-arm by BIND (drive) mid-wave of a handle holding an older change: runs per wave (200 trials)
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance
local q = mock.newQuad()
for _, kind in { "Observer", "Effect" } do
	local counts, vals = {}, {}
	for t = 1, 200 do
		local src = q.Source(0)
		local sibRuns, seen = 0, {}
		local pad = {}
		for i = 1, t % 7 do pad[i] = src:Observer(function() end):Subscribe() end
		local sib
		if kind == "Observer" then sib = src:Observer(function(s) sibRuns += 1; table.insert(seen, s:Get()) end)
		else sib = q.Effect(function() sibRuns += 1; table.insert(seen, src:Get()) end, src) end
		local host1 = Instance.new("Frame"); q.Dispatch.drive(host1, { sib }); host1:Destroy() -- a detached/reused row
		src:Set(1) -- held
		local a = src:Observer(function(_, _, from) if from ~= nil and src:Get() == 2 then q.Dispatch.drive(Instance.new("Frame"), { sib }) end end):Subscribe()
		sibRuns = 0; table.clear(seen)
		src:Set(2)
		counts[sibRuns] = (counts[sibRuns] or 0) + 1
		vals[table.concat(seen, ",")] = true
		a:Unsubscribe(); for _, p in pad do p:Unsubscribe() end
	end
	local ks = {} for k in vals do table.insert(ks, "[" .. k .. "]") end
	for k, v in counts do print(kind, "ran", k, "times in one wave:", v, "trials; values seen", table.concat(ks, " ")) end
end
