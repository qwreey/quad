--!strict
-- quad real types: each case `local _: string = rN` — an error means rN is constrained (good);
-- no error means rN is unconstrained (hole). Error text reveals the inferred type.
local Setup = require("./_setup")
local QT = require("../../../quad-roblox/luau_packages/quad_types")
local q = Setup.q
local n = q.Source(1)
local doubled = n:Compute(function(s) return s:Get() * 2 end)

-- A: 1 param, no dep
local rA = n:Compute(function(s) return s:Get() + 1 end)
local _A: string = rA                                          -- L11
-- B: 1 param, 1 dep (dep unused)
local rB = n:Compute(function(s) return s:Get() + 1 end, doubled)
local _B: string = rB                                          -- L14
-- C: 2 params (s, prev), 1 dep, prev unused
local rC = n:Compute(function(s, prev) return s:Get() + 1 end, doubled)
local _C: string = rC                                          -- L17
-- D: 3 params (s, prev, d), 1 dep, d used (GS19 shape)
local rD = n:Compute(function(s, prev, d) return s:Get() + d:Get() end, doubled)
local _D: string = rD                                          -- L20
-- E: 3 params, d unused
local rE = n:Compute(function(s, prev, d) return s:Get() + 1 end, doubled)
local _E: string = rE                                          -- L23
-- F: 2 params (s, prev), no dep
local rF = n:Compute(function(s, prev) return s:Get() + 1 end)
local _F: string = rF                                          -- L26
-- G: 3 params, NO dep passed, d used
local rG = n:Compute(function(s, prev, d) return s:Get() + d:Get() end)
local _G: string = rG                                          -- L29
-- H: 1 param + closure over doubled (no dep param), dep passed
local rH = n:Compute(function(s) return s:Get() + doubled:Get() end, doubled)
local _H: string = rH                                          -- L32
-- I: 3 params, d annotated
local rI = n:Compute(function(s, prev, d: QT.StateData<number>) return s:Get() + d:Get() end, doubled)
local _I: string = rI                                          -- L35
-- J: 3 params, return annotated
local rJ = n:Compute(function(s, prev, d): number return s:Get() + d:Get() end, doubled)
local _J: string = rJ                                          -- L38
-- K: 3 params, d used but result not via d: d:Get() used elsewhere
local rK = n:Compute(function(s, prev, d) local _ = d:Get(); return s:Get() + 1 end, doubled)
local _K: string = rK                                          -- L41
-- L: 2 deps, 4 params, all used
local rL = n:Compute(function(s, prev, d, e) return s:Get() + d:Get() + e:Get() end, doubled, doubled)
local _L: string = rL                                          -- L44
-- M: 3 params, d used as `d:Get() + s:Get()` (any on left)
local rM = n:Compute(function(s, prev, d) return d:Get() + s:Get() end, doubled)
local _M: string = rM                                          -- L47
-- N: 1 param, dep passed, closure `+ (doubled :: any):Get()` (explicit any operand)
local rN = n:Compute(function(s) return s:Get() + (doubled :: any):Get() end)
local _N: string = rN                                          -- L50
-- O: string-returning with d
local rO = n:Compute(function(s, prev, d) return tostring(d:Get()) end, doubled)
local _O: string = rO                                          -- L53
-- controls: annotated binding (§1① prescription)
local rP: QT.State<number> = n:Compute(function(s, prev, d) return s:Get() + d:Get() end, doubled)
local _P: string = rP                                          -- L56 expect error
local _P2: string = rP:Get()                                   -- L57 expect error
-- downstream of unannotated: Get() + 1, wrong assignment, :Compute chain
local _D2: string = rD:Get() + 1                               -- L59
local rD3 = rD:Compute(function(s) return tostring(s:Get()) end)
local _D3: number = rD3                                        -- L61
local _A2: string = rA:Get()                                   -- L62 (1-param no-dep)
-- source receiver direct
local _S: string = n:Get()                                     -- L64 expect error
