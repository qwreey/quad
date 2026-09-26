--!strict
-- E33: Slot:Single with a State argument — does inference find Item?
local QT = require("../../../quad-roblox/luau_packages/quad_types")
local QRmod = require("../../../quad-roblox/src")
local q: QT.Quad & QRmod.RobloxExtension = nil :: any
local frame: Frame = nil :: any
local sl = q.Slot<<Instance>>()
local s1: QT.Source<number> = q.Source(1)
local s2: QT.Source<number?> = q.Source<<number?>>(nil)
local d1: QT.State<number> = s1:Compute(function(self) return self:Get() end)
-- A: Source<number> + updateFn
sl:Single(s1, function(ctx) return frame end) -- A
-- B: Source<number?> + updateFn
sl:Single(s2, function(ctx) return frame end) -- B
-- C: derived State<number> + updateFn
sl:Single(d1, function(ctx) return frame end) -- C
-- D: Source<number> without updateFn
sl:Single(s1) -- D
-- E: plain value + updateFn
sl:Single(5, function(ctx) return frame end) -- E
-- F: explicit instantiation
sl:Single<<number, nil>>(s1, function(ctx) return frame end) -- F
-- G: List with State data
local arr: QT.Source<{ number }> = q.Source({ 1, 2 })
sl:List(arr, function(ctx) return frame end) -- G
-- H: Out with a derived State (doc: rejected by type)
local _h = q.Out("Size", s1:Compute(function() return UDim2.new() end)) -- H
local c2: QT.State<UDim2> = s1:Compute(function() return UDim2.new() end)
local _h2 = q.Out("Size", c2) -- H2
local _h3 = q.Out("Size", q.Source(1)) -- H3 (wrong value type)
return nil
