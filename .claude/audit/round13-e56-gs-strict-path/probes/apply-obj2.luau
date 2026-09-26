--!strict
const q = require("../annotated/Quad")
const count = q.Source(0)
-- E: self만 any, state는 핸들 타입
const DE = { __apply = function(self: any, state: q.State<number>): q.State<number> return state:Compute(function(c: q.StateData<number>): number return c:Get() * 2 end) end }
const e: q.State<number> = count:Apply(DE)
-- F: self any, state 무주석, 안쪽 §6
const DF = { __apply = function(self: any, state) return state:Compute(function(c: q.StateData<number>): number return c:Get() * 2 end) end }
const f: q.State<number> = count:Apply(DF)
print(e, f)
