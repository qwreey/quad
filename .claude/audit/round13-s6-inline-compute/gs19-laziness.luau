--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration

local n = q.Source(1)
local doubled = n:Compute(function(s) return s:Get() * 2 end)
local calls = 0
local total = n:Compute(function(s, previous, d)
	calls += 1
	return s:Get() + d:Get()
end, doubled)

local label = D.TextLabel({ Text = total:Compute(function(s) return tostring(s:Get()) end) })
print(calls, label.Text)
