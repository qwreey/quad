--!strict
local q = require("./round13-e15-probe-types-settings")
local D = q.Declaration
local s = q.Source("")
local ds: q.State<string> = s:Apply(q.Debounce { Time = 0.3 })
local _o1 = ds:Observer(function(t) local v = t:Get(); print(#v) end)          -- I1 standalone observer on annotated State
local _f1 = D.Frame { ds:Observer(function(t) local v = t:Get(); print(#v) end) } -- I2 same at array slot
local _f2 = D.Frame { s:Observer(function(t) local v = t:Get(); print(#v) end) }  -- I3 Source at array slot
local cs: q.State<string> = s:Compute(function(x) return x:Get() end)
local _f3 = D.Frame { cs:Observer(function(t) local v = t:Get(); print(#v) end) } -- I4 annotated Compute State at array slot
local _f4 = D.Frame { q.OnRendered<<Frame>>(function(inst) print(#inst:GetChildren()) end) } -- I5
local _f5 = D.Frame { q.OnRendered<<Frame>>(function(inst) print(inst.Name) end) } -- I6
local _f6 = D.Frame { q.OnCreated<<Frame>>(function(inst) print(#inst:GetChildren()) end) } -- I7
local _r = q.OnRendered<<Frame>>(function(inst) print(#inst:GetChildren()) end) -- I8 standalone
