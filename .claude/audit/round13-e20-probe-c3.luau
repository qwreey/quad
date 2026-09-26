--!nocheck
-- round13 E20 probe C3 — Observer self-Set nested-wave recursion depth vs Effect flat loop; install-time Rerun/Set while unbound.
local mock = require("../../quad-base/test/mock")
local q = mock.newQuad()
local function E(f, ...)
	local ok, err = pcall(f, ...)
	if ok then return "ok" end
	local s = tostring(err)
	return (s:match("Quad%d+[^\n]*") or s:sub(1, 100))
end
for _, N in { 100, 1000, 5000, 20000, 100000 } do
	local src = q.Source(0)
	local maxDepth, depth = 0, 0
	local o = src:Observer(function(t, _, from)
		if from == nil then return end
		depth += 1
		if depth > maxDepth then maxDepth = depth end
		if t:Get() < N then t:Set(t:Get() + 1) end
		depth -= 1
	end):Subscribe()
	local r = E(function() src:Set(1) end)
	print(string.format("   N=%d Observer: %s maxDepth=%d final=%d running-after=%s", N, r, maxDepth, src:Get(), tostring(o._running)))
end
print("== install-time: fn Sets its own dep once / calls self:Rerun() once, while unbound")
do
	local src = q.Source(0)
	local runs, cl = 0, {}
	local eff = q.Effect(function()
		runs += 1
		if src:Get() == 0 then src:Set(1) end
		return function(d) table.insert(cl, tostring(d)) end
	end, src)
	print("   dep Set in install fn: runs before bind =", runs, "cleanups =", table.concat(cl, ","), "rerunRequired =", eff._rerunRequired)
	eff:Subscribe()
	print("   after Subscribe runs =", runs)
	local runs2 = 0
	local eff2
	eff2 = q.Effect(function(self) runs2 += 1; if runs2 == 1 then self:Rerun() end end)
	print("   self:Rerun() in install fn: runs before bind =", runs2, "rerunRequired =", eff2._rerunRequired)
	local runs3 = 0
	local eff3 = q.Effect(function() runs3 += 1 end)
	eff3:Rerun()
	print("   control: Rerun() outside fn on an unbound Effect: runs =", runs3, "rerunRequired =", eff3._rerunRequired)
end
