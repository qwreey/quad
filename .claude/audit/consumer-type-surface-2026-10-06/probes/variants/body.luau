export type StateMarker<T> = { read __quadState: true, read __quadStateValue: T }
local mk: <T>(v: T) -> Source<T> = (nil :: any)
local c1: State<number> = mk(1)
-- A1
local function id<T>(x: State<T>): State<T> return x end
local _a1 = id(c1)
local function idS<T>(x: Source<T>): Source<T> return x end
local _a1s = idS(mk(1))
local function idSD<T>(x: StateData<T>): StateData<T> return x end
local _a1d = idSD(c1)
local function idL<T>(x: State<{ T }>): State<{ T }> return x end
local _a1l = idL(mk({ 1, 2 }))
-- A2 analog: covariance on read-only State param
local function takesState(_v: State<number | string>) end
takesState(mk(1))
local function takesStr(_v: State<string>) end
takesStr(mk(1)) -- EXPECT
local function takesSrcWide(_v: Source<number | string>) end
takesSrcWide(mk(1)) -- EXPECT (Source must stay invariant)
-- ordinary use (unannotated callbacks must still infer)
local s = mk(5)
s:Set(6)
s:Set("x") -- EXPECT
local d2: State<number> = s:Compute(function(self) return self:Get() + 1 end)
local _g: number = d2:Get()
local _gs: string = d2:Get() -- EXPECT
local d3: State<number> = s:Compute(function(self, prev) return (prev or 0) + self:Get() end)
local _o = s:Observer(function(t) local _n: number = t:Get() end)
local _o2 = s:Observer(function(t) local _n: string = t:Get() end) -- EXPECT
local ap: string = s:Apply(function(st) return tostring(st:Get()) end)
local _ = ap
local dep: State<number> = s:Depend(c1)
local _ = dep
local asState: State<number> = s
local _ = asState
local asSD: StateData<number> = s
local _ = asSD
local asMarker: StateMarker<number | string> = s
local _ = asMarker
-- generic body use
local function useG<T>(x: State<T>): T
	local _d: State<string> = x:Compute(function(self) return tostring(self:Get()) end)
	return x:Get()
end
local _n: number = useG(c1)
-- F1 analog: inline Compute inside a table passed to a function
local function takesRec(_r: { Text: string | StateMarker<string> }) end
takesRec({ Text = s:Compute(function(self) return tostring(self:Get()) end) })
takesRec({ Text = s:Compute(function(self: StateData<number>) return tostring(self:Get()) end) })
local _ = d3
