--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration

local flash = q.Source(false)

local btn = D.TextButton({
	Text = flash:Compute(function(f) return if f:Get() then "✨" else "+ 1" end),
})
print(btn)
