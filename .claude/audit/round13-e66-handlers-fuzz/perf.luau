--!nocheck
-- E66 perf shape: µs per State emit for each handler seat (mock; relative shape only)
local E = require("./env")
local N = 20000
local function bench(name, setup)
	local q = E.newProv(); local D = q.Declaration
	local step = setup(q, D)
	for i = 1, 200 do step(i) end
	local t0 = os.clock()
	for i = 1, N do step(i) end
	print(string.format("%-34s %.2f us/emit", name, (os.clock() - t0) / N * 1e6))
end
bench("baseline Source:Set (no seat)", function(q) local s = q.Source(0); return function(i) s:Set(i) end end)
bench("Property Text (plain, new value)", function(q, D) local s = q.Source("a"); D.TextButton({ Text = s }); return function(i) s:Set(i % 2 == 0 and "a" or "b") end end)
bench("Property Text (same value)", function(q, D) local s = q.Source("a"); D.TextButton({ Text = s }); return function() s:Set("a") end end)
local fns = {}; for i = 1, 2 do fns[i] = function() return i end end
bench("Event Activated (alternate fn)", function(q, D) local s = q.Source(fns[1]); D.TextButton({ Activated = s }); return function(i) s:Set(fns[i % 2 + 1]) end end)
bench("Event Activated (same fn)", function(q, D) local s = q.Source(fns[1]); D.TextButton({ Activated = s }); return function() s:Set(fns[1]) end end)
bench("OnChange swap (new descriptor)", function(q, D) local s = q.Source(q.None); D.TextButton({ s }); return function(i) s:Set(q.OnChange("Text", fns[i % 2 + 1])) end end)
bench("InstanceChild swap (2 kids)", function(q, D) local a, b = D.Frame({}), D.Frame({}); local s = q.Source(a); D.Frame({ s }); return function(i) s:Set(i % 2 == 0 and a or b) end end)
bench("InstanceChild same kid (dedup)", function(q, D) local a = D.Frame({}); local s = q.Source(a); D.Frame({ s }); return function() s:Set(a) end end)
bench("Shorthand UIScale number", function(q, D) local s = q.Source(1); D.Frame({ UIScale = s }); return function(i) s:Set(i % 3 + 1) end end)
bench("Shorthand UIScale nil<->number", function(q, D) local s = q.Source(1); D.Frame({ UIScale = s }); return function(i) s:Set(if i % 2 == 0 then nil else 2) end end)
-- many seats on one signal: cost of one Disconnect with k siblings (mock Disconnect is table.find: O(k))
for _, k in { 1, 100, 1000 } do
	bench("OnChange swap with " .. k .. " sibling conns", function(q, D)
		local t = D.TextButton({}); local sig = t:GetPropertyChangedSignal("Text")
		for _ = 1, k do sig:Connect(function() end) end
		local s = q.Source(q.None); q.Dispatch.process(t, 1, s, 1)
		return function(i) s:Set(q.OnChange("Text", fns[i % 2 + 1])) end
	end)
end
