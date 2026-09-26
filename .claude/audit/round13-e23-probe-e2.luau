--!nocheck
-- round13 E23 E2 — is the same-wave write sequence (stale-branch value exposure) order-dependent?
local H = require("./round13-e15-probe-setup")
local q, D = H.q, H.D
local dist = {}
for trial = 1, 300 do
	local src = q.Source(1)
	local pad = {}
	for i = 1, trial % 7 do pad[i] = src:Compute(function(s) return s:Get() end) end -- perturb _subs layout
	local a = src:Compute(function(s) return "a" .. s:Get() end)
	local b = src:Compute(function(s) return "b" .. s:Get() end)
	local outer = src:Compute(function(s) return if s:Get() % 2 == 1 then a else b end)
	local l = D.TextLabel { Text = outer }
	local seq = {}
	l:GetPropertyChangedSignal("Text"):Connect(function() table.insert(seq, l.Text) end)
	src:Set(2)
	local key = table.concat(seq, ",")
	dist[key] = (dist[key] or 0) + 1
	-- also check an Observer on the StoreBind-bound values (sanity: final)
	assert(l.Text == "b2")
end
for k, v in dist do print(k, v) end
-- Observer-level: does an Observer on `outer` see consistency? (outer:Get() while Text shows a2)
local src = q.Source(1)
local a = src:Compute(function(s) return "a" .. s:Get() end)
local b = src:Compute(function(s) return "b" .. s:Get() end)
local outer = src:Compute(function(s) return if s:Get() % 2 == 1 then a else b end)
local l = D.TextLabel { Text = outer }
l:GetPropertyChangedSignal("Text"):Connect(function() print("  write", l.Text, "outer:Get()==b", outer:Get() == b) end)
src:Set(2)
