--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration

local FADE = q.Tween({ Value = 0, Time = 0.15 })

local label = D.TextLabel({
	TextTransparency = FADE:Mapped(function(v: number): number return 1 end),
})
print(label)
