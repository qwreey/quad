--!strict
-- Per-operator: does :Apply(factory) leave the binding constrained without annotation?
-- Pattern: `local w: <deliberately wrong type> = r` / `r:Get()` -- error = constrained (safe),
-- silent = hole (needs binding annotation). q105-check scratch, not repo source.
local Setup = require("./_setup")
local q = Setup.q
local Op = q.Operator

-- same-T operators (T is preserved)
local n = q.Source(0)
local rSum = n:Apply(Op.Sum(10))
local wSum: string = rSum
local rClamp = n:Apply(Op.Clamp(0, 10))
local wClamp: string = rClamp
local flags = q.Source(0)
local rBand = flags:Apply(Op.Band(0b1010))
local wBand: string = rBand
local rShl = flags:Apply(Op.Shl(2))
local wShl: string = rShl
local vis = q.Source(true)
local rNot = vis:Apply(Op.Not)
local wNot: string = rNot

-- T-changing operators
local optName = q.Source("x" :: string?)
local rAlt = optName:Apply(Op.Alternative("Guest"))
local wAlt: number = rAlt
local theme = q.Source({ Primary = "blue" })
local rIdx = theme:Apply(Op.Indexed<<string>>("Primary"))
local wIdx: number = rIdx

print(wSum, wClamp, wBand, wShl, wNot, wAlt, wIdx)
