--!nocheck
-- minimal: a gate on a long-lived "hot" upstream outlives its destroyed host for as long as the upstream
-- keeps emitting faster than Time (Debounce restarts the window; Throttle reopens it on every pass).
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D
for _, kind in { "Debounce", "Throttle" } do
	local hot = q.Source(0)
	local tr = G.tracker("k")
	for i = 1, 1000 do
		local g = hot:Apply(q[kind] { Time = 1 })
		local f = D.Frame { LayoutOrder = g }
		tr.add(g, "gate")
		f:Destroy()
		hot:Set(hot:Get() + 1) -- the upstream emits in the same frame the host dies (per-frame source)
	end
	local out = {}
	for sec = 1, 60 do
		for _ = 1, 10 do hot:Set(hot:Get() + 1); H.runTask(0.1) end -- 10 Hz upstream
		if sec % 20 == 0 then table.insert(out, "t=" .. sec .. "s:" .. tr.count()) end
	end
	H.runTask(3)
	table.insert(out, "quiet 3s:" .. tr.count())
	print(`[{kind} Time=1, 1000 hosts destroyed, 10 Hz upstream] alive gates: {table.concat(out, " ")}`)
end
