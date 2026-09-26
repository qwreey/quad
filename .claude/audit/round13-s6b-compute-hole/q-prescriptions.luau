--!strict
-- (5) prescription candidates on the GS19 shape. Each followed by the same two probes:
--   `local _: string = tX`        (is the binding constrained?)
--   `local _: string = tX:Get()`  (is Get() constrained?)
local Setup = require("./_setup")
local QT = require("../../../quad-roblox/luau_packages/quad_types")
local q = Setup.q
local n = q.Source(1)
local doubled: QT.State<number> = n:Compute(function(s) return s:Get() * 2 end)

-- P0 as-is (GS19:59)
local t0 = n:Compute(function(s, previous, d) return s:Get() + d:Get() end, doubled)
local _0a: string = t0 ; local _0b: string = t0:Get()                                  -- L13
-- P1 parameter annotation (d)
local t1 = n:Compute(function(s, previous, d: QT.StateData<number>) return s:Get() + d:Get() end, doubled)
local _1a: string = t1 ; local _1b: string = t1:Get()                                  -- L16
-- P2 return annotation
local t2 = n:Compute(function(s, previous, d): number return s:Get() + d:Get() end, doubled)
local _2a: string = t2 ; local _2b: string = t2:Get()                                  -- L19
-- P3 :Depend (dep moved; body closes over doubled)
local t3 = n:Depend(doubled):Compute(function(s) return s:Get() + doubled:Get() end)
local _3a: string = t3 ; local _3b: string = t3:Get()                                  -- L22
-- P4 binding annotation (§1① rule)
local t4: QT.State<number> = n:Compute(function(s, previous, d) return s:Get() + d:Get() end, doubled)
local _4a: string = t4 ; local _4b: string = t4:Get()                                  -- L25
-- P4 does not check the RHS (§1): wrong binding type passes?
local t4bad: QT.State<string> = n:Compute(function(s, previous, d) return s:Get() + d:Get() end, doubled) -- L27
-- P5 closure read instead of dep param (dep still passed)
local t5 = n:Compute(function(s) return s:Get() + doubled:Get() end, doubled)
local _5a: string = t5 ; local _5b: string = t5:Get()                                  -- L30
-- downstream from P4: inline Compute on annotated receiver in wrong slot
local D = q.Declaration
local lbl = D.TextLabel({ Text = t4 })                                                 -- L33 State<number> in Text
print(_0a,_0b,_1a,_1b,_2a,_2b,_3a,_3b,_4a,_4b,t4bad,_5a,_5b,lbl)
