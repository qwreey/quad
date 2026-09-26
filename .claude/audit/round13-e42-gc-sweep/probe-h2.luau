--!nocheck
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D
local hot = q.Source(0)
local function run(kind, N)
	local tr = G.tracker("k")
	for i = 1, N do
		local g = hot:Apply((kind == "D" and q.Debounce or q.Throttle) { Time = 1 })
		local f = D.Frame { LayoutOrder = g }
		tr.add(g, "gate"); tr.add(f, "inst")
		f:Destroy()
	end
	local line = {}
	for step = 1, 40 do
		hot:Set(hot:Get() + 1)
		H.runTask(0.5)
		if step % 10 == 0 then local n, by = tr.fmt(); table.insert(line, string.format("t=%.0fs:%d{%s}", step * 0.5, n, by)) end
	end
	H.runTask(5)
	local n, by = tr.fmt()
	table.insert(line, "after upstream quiet 5s:" .. n)
	print(string.format("[h8 %s, hot upstream emits every 0.5s, N=%d gates on destroyed insts] %s", kind, N, table.concat(line, " ")))
end
run("D", 1000)
run("T", 1000)
-- control: no Debounce, plain Compute on the hot upstream
local tr = G.tracker("k")
for i = 1, 1000 do local c = hot:Compute(function(s) return s:Get() end); local f = D.Frame { LayoutOrder = c }; tr.add(c, "c"); f:Destroy() end
for step = 1, 10 do hot:Set(hot:Get() + 1) end
print("[h8 control Compute on hot upstream] residue", tr.count())
