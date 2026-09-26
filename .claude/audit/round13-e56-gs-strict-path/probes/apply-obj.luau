--!strict
const q = require("../annotated/Quad")
const count = q.Source(0)
-- A: 문서 그대로(무주석)
const DA = { __apply = function(self, state) return state:Compute(function(c) return c:Get() * 2 end) end }
const a = count:Apply(DA)
-- B: 안쪽 콜백만 §6 주석
const DB = { __apply = function(self, state) return state:Compute(function(c: q.StateData<number>): number return c:Get() * 2 end) end }
const b: q.State<number> = count:Apply(DB)
-- C: state를 q.State<number>로(“넘겨받는 핸들의 타입”)
const DC = { __apply = function(self, state: q.State<number>): q.State<number> return state:Compute(function(c: q.StateData<number>): number return c:Get() * 2 end) end }
const c: q.State<number> = count:Apply(DC)
-- D: self·state를 any로
const DD = { __apply = function(self: any, state: any): any return state:Compute(function(x: q.StateData<number>): number return x:Get() * 2 end) end }
const d: q.State<number> = count:Apply(DD)
print(a, b, c, d)
