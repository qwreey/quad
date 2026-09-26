--!strict
-- E33: minimal Slot:Single + updateFn lambda (isolated from other probes)
local QT = require("../../../quad-roblox/luau_packages/quad_types")
local q: QT.Quad = nil :: any
local frame: Instance = nil :: any
local sl = q.Slot<<Instance>>()
local s1: QT.Source<number> = q.Source(1)
sl:Single(s1, function(ctx) return frame end) -- A
sl:Single(s1, function(ctx) return frame, nil end) -- A2
sl:Single(s1, function(ctx: any) return frame end) -- A3 annotated
return nil
