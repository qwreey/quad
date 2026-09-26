--!strict
-- quad-free minimal repro. Each `local _xx: string = r` — error = constrained, silent = hole.
type SD<T> = { read __v: T, Get: (self: SD<T>) -> T }

-- (R) non-uniform recursion: returns S<U> (quad's shape)
type S<T> = SD<T> & {
	Compute: <U>(self: SD<T>, fn: (self: SD<T>, previous: U?, ...any) -> U, ...any) -> S<U>,
}
-- (B) no recursion: returns Box<U> (non-recursive container)
type Box<U> = { read v: U }
type NB<T> = SD<T> & {
	Compute: <U>(self: SD<T>, fn: (self: SD<T>, previous: U?, ...any) -> U, ...any) -> Box<U>,
}
-- (P) same as R but previous is non-optional U
type SP<T> = SD<T> & {
	Compute: <U>(self: SD<T>, fn: (self: SD<T>, previous: U, ...any) -> U, ...any) -> SP<U>,
}
-- (N) same as R but no trailing variadics at all
type SN<T> = SD<T> & {
	Compute: <U>(self: SD<T>, fn: (self: SD<T>) -> U) -> SN<U>,
}
-- (O) overloaded (intersection) Compute with recursion
type SO<T> = SD<T> & {
	Compute: (<U>(self: SD<T>, fn: (self: SD<T>) -> U) -> SO<U>) & (<U>(self: SD<T>, fn: (self: SD<T>, previous: U?, ...any) -> U, ...any) -> SO<U>),
}
-- (U) uniform recursion: returns S<T> only
type SUni<T> = SD<T> & {
	Map: (self: SD<T>, fn: (self: SD<T>, previous: T?, ...any) -> T, ...any) -> SUni<T>,
}

local s: S<number> = nil :: any
local nb: NB<number> = nil :: any
local sp: SP<number> = nil :: any
local sn: SN<number> = nil :: any
local so: SO<number> = nil :: any
local su: SUni<number> = nil :: any
local dep: S<number> = nil :: any

-- R axis: params × deps
local r1 = s:Compute(function(x) return x:Get() + 1 end)                                    ; local _r1: string = r1 -- L39
local r2 = s:Compute(function(x) return x:Get() + 1 end, dep)                               ; local _r2: string = r2 -- L40
local r3 = s:Compute(function(x, p) return x:Get() + 1 end, dep)                            ; local _r3: string = r3 -- L41
local r4 = s:Compute(function(x, p, d) return x:Get() + d:Get() end, dep)                   ; local _r4: string = r4 -- L42
local r5 = s:Compute(function(x: SD<number>, p: number?, d: SD<number>): number return x:Get() + d:Get() end, dep) ; local _r5: string = r5 -- L43
local r6: S<number> = s:Compute(function(x) return x:Get() + 1 end)                         ; local _r6: string = r6 -- L44 annotated
-- B axis (no recursion)
local b1 = nb:Compute(function(x) return x:Get() + 1 end)                                   ; local _b1: string = b1 -- L46
local b4 = nb:Compute(function(x, p, d) return x:Get() + d:Get() end, dep)                  ; local _b4: string = b4 -- L47
local _b4v: string = b4.v                                                                                            -- L48
-- P axis (previous non-optional)
local p1 = sp:Compute(function(x) return x:Get() + 1 end)                                   ; local _p1: string = p1 -- L50
local p4 = sp:Compute(function(x, p, d) return x:Get() + d:Get() end, dep)                  ; local _p4: string = p4 -- L51
-- N axis (no variadics)
local n1 = sn:Compute(function(x) return x:Get() + 1 end)                                   ; local _n1: string = n1 -- L53
-- O axis (overloads)
local o1 = so:Compute(function(x) return x:Get() + 1 end)                                   ; local _o1: string = o1 -- L55
local o4 = so:Compute(function(x, p, d) return x:Get() + d:Get() end, dep)                  ; local _o4: string = o4 -- L56
-- U axis (uniform recursion)
local u1 = su:Map(function(x) return x:Get() + 1 end)                                       ; local _u1: string = u1 -- L58
local u4 = su:Map(function(x, p, d) return x:Get() + d:Get() end, dep)                      ; local _u4: string = u4 -- L59
