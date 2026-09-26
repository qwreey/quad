--!nocheck
-- E55: Debounce "leading lost once" caveat (sugar/03:47) — control vs throwing downstream, several spacings.
local H = require("./harness")
local q = H.q
for _, kind in { "Debounce", "Throttle" } do
	for _, gap in { 0.5, 1.0, 2.0 } do
		local rows = {}
		for _, throw in { false, true } do
			local a = q.Source(0)
			local g = a:Apply(q[kind]({ Time = 0.3, Leading = true }))
			local seen = {}
			local o = g:Observer(function(s)
				local v = s:Get()
				table.insert(seen, v)
				if throw and v == 2 then error("deb-down") end
			end):Subscribe()
			table.clear(seen)
			local t = {}
			a:Set(1); a:Set(2)
			H.runTask(gap) -- 2 passes as trailing (throws in the throw run)
			a:Set(3)
			t[#t + 1] = "afterSet3=" .. table.concat(seen, ",")
			H.runTask(gap)
			a:Set(4)
			t[#t + 1] = "afterSet4=" .. table.concat(seen, ",")
			H.runTask(gap)
			t[#t + 1] = "end=" .. table.concat(seen, ",")
			o:Unsubscribe()
			rows[throw] = table.concat(t, "  ")
		end
		print(("%-8s gap %.1f  control: %s\n                 throw:   %s"):format(kind, gap, rows[false], rows[true]))
	end
end
