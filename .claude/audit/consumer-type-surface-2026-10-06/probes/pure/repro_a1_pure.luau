--!strict
-- A1 root, quad-free. Each `idN(x)` call: generic T inferred from an argument of the same alias.
-- Observed (luau-lsp 1.69.0, LuauSolverV2, test.sh limit flags): marked FAIL lines report
-- "No valid instantiation ... T ... at least: number | nil and at most: number".
type W1<T> = { read v: T } & { read f: (T) -> () } -- FAIL: intersection, T co + contra
type W2<T> = { read v: T, read f: (T) -> () } -- ok: same members, one table
type W3<T> = { v: T } & {} -- FAIL: read-write field (invariant) inside an intersection
type W4<T> = { v: T } -- ok
type W5<T> = { read v: T } & { read x: number } -- ok: only covariant T
type W6<T> = { read v: T, read g: (self: any) -> T } & {} -- ok (quad `cov` shape of StateData)
type W7<T> = { read v: T, read g: (self: W7<T>) -> T } & {} -- FAIL (quad StateData shape: self param mentions T)
local w1: W1<number> = (nil :: any)
local w2: W2<number> = (nil :: any)
local w3: W3<number> = (nil :: any)
local w4: W4<number> = (nil :: any)
local w5: W5<number> = (nil :: any)
local w6: W6<number> = (nil :: any)
local w7: W7<number> = (nil :: any)
local function id1<T>(x: W1<T>): W1<T> return x end
local function id2<T>(x: W2<T>): W2<T> return x end
local function id3<T>(x: W3<T>): W3<T> return x end
local function id4<T>(x: W4<T>): W4<T> return x end
local function id5<T>(x: W5<T>): W5<T> return x end
local function id6<T>(x: W6<T>): W6<T> return x end
local function id7<T>(x: W7<T>): W7<T> return x end
local _1 = id1(w1)
local _2 = id2(w2)
local _3 = id3(w3)
local _4 = id4(w4)
local _5 = id5(w5)
local _6 = id6(w6)
local _7 = id7(w7)
