--!strict
-- 8.13 inline error depends on the RECEIVER: Source (known) vs unannotated Compute result (error-type).
local Setup = require("./_setup")
local QT = require("../../../quad-roblox/luau_packages/quad_types")
local q = Setup.q
local D = q.Declaration
local n = q.Source(1)
local doubled = n:Compute(function(s) return s:Get() * 2 end)                     -- 1 param, no dep
local total = n:Compute(function(s, previous, d) return s:Get() + d:Get() end, doubled) -- GS19 shape
local typed: QT.State<number> = n:Compute(function(s) return s:Get() * 2 end)       -- annotated

local a = D.TextLabel({ Text = n:Compute(function(s) return tostring(s:Get()) end) })       -- L12 receiver Source
local b = D.TextLabel({ Text = doubled:Compute(function(s) return tostring(s:Get()) end) }) -- L13 receiver 1-param result
local c = D.TextLabel({ Text = total:Compute(function(s) return tostring(s:Get()) end) })   -- L14 receiver GS19 result
local d = D.TextLabel({ Text = typed:Compute(function(s) return tostring(s:Get()) end) })   -- L15 receiver annotated
-- wrong value types (should be rejected: Text wants string)
local e = D.TextLabel({ Text = doubled })   -- L17 State<number>? no — error-type → passes?
local f = D.TextLabel({ Text = typed })     -- L18 State<number> into Text → expect error
print(a, b, c, d, e, f)
