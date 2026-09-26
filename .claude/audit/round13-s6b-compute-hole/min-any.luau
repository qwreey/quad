--!strict
-- Second effect, isolated on a NON-recursive return (Box<U>) so §1 is out of the picture:
-- does the trailing-dep parameter (typed from `...any`) make U = any?
type SD<T> = { read __v: T, Get: (self: SD<T>) -> T }
type Box<U> = { read v: U }
type NB<T> = SD<T> & {
	Compute: <U>(self: SD<T>, fn: (self: SD<T>, previous: U?, ...any) -> U, ...any) -> Box<U>,
}
local nb: NB<number> = nil :: any
local dep: SD<number> = nil :: any
local b1 = nb:Compute(function(x) return x:Get() + 1 end)                        ; local _1: string = b1.v -- L11 1p, no dep
local b2 = nb:Compute(function(x) return x:Get() + 1 end, dep)                   ; local _2: string = b2.v -- L12 1p, dep
local b3 = nb:Compute(function(x, p) return x:Get() + 1 end, dep)                ; local _3: string = b3.v -- L13 2p, dep
local b4 = nb:Compute(function(x, p, d) return x:Get() + 1 end, dep)             ; local _4: string = b4.v -- L14 3p, dep unused
local b5 = nb:Compute(function(x, p, d) return x:Get() + d:Get() end, dep)       ; local _5: string = b5.v -- L15 3p, dep used in return
local b6 = nb:Compute(function(x, p, d: SD<number>) return x:Get() + d:Get() end, dep) ; local _6: string = b6.v -- L16 d annotated
local b7 = nb:Compute(function(x, p, d): number return x:Get() + d:Get() end, dep) ; local _7: string = b7.v -- L17 return annotated
local b8 = nb:Compute(function(x, p, d) return tostring(d:Get()) end, dep)      ; local _8: number = b8.v -- L18 d used, tostring
local b9 = nb:Compute(function(x) return x:Get() + (dep :: any):Get() end)      ; local _9: string = b9.v -- L19 no param, any operand
local b10 = nb:Compute(function(x, p) return (p or 0) + 1 end)                   ; local _10: string = b10.v -- L20 prev used
local b11 = nb:Compute(function(x, p, d) local v = d:Get(); return x:Get() + 1 end, dep) ; local _11: string = b11.v -- L21 d used, not in return
