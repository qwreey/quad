--!strict
type M = { read tag: "M", Apply: <U>(self: any, factory: (any) -> U) -> U }
local m: M = { tag = "M", Apply = function<U>(self: any, factory: (any) -> U): U return factory(self) end }
local g = function(x: any): string return "s" end
local b: number = m:Apply(g) -- E? named annotated factory
local c: number = m:Apply(function(x: any): string return "s" end) -- E? inline annotated factory
local function Ap<U>(self: any, factory: (any) -> U): U return factory(self) end
local d: number = Ap(m, g) -- E control (free generic fn)
local t = { Ap = Ap }
local e: number = t.Ap(m, g) -- E? generic fn in inferred table
return b, c, d, e
