--!nocheck
-- install fn Sets the upstream of a Debounce'd / Throttle'd node: the timer flush must still re-run the handle
local mock = require("./mock")
local q = mock.newQuad()
for _, kind in { "Debounce", "Throttle" } do
	for _, hk in { "Observer", "Effect" } do
		local s = q.Source(0)
		local g = s:Apply(q[kind]({ Time = 0.3 }))
		local seen = {}
		local h
		if hk == "Observer" then
			h = g:Observer(function(st) table.insert(seen, st:Get()); if st:Get() == 0 then s:Set(1) end end)
		else
			h = q.Effect(function() table.insert(seen, g:Get()); if g:Get() == 0 then s:Set(1) end end, g)
		end
		local a = table.concat(seen, ",")
		h:Subscribe()
		local b = table.concat(seen, ",")
		mock.advanceTime(1)
		print(kind, hk, "install", a, "| subscribe", b, "| after timers", table.concat(seen, ","))
		h:Unsubscribe()
	end
end
