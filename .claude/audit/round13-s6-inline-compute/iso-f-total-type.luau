--!strict
local Setup = require("./_setup")
local q = Setup.q
local n = q.Source(1)
local doubled = n:Compute(function(s) return s:Get() * 2 end)
local calls = 0
local total = n:Compute(function(s, previous, d)
	calls += 1
	return s:Get() + d:Get()
end, doubled)
local x: string = total  -- deliberately wrong to reveal inferred type of `total`
print(x)
