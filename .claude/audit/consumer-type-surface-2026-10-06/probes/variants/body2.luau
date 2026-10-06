local mk: <T>(v: T) -> Source<T> = (nil :: any)
local c1: State<number> = mk(1)
local _a1 = (function<T>(x: State<T>): State<T> return x end)(c1)
local function idS<T>(x: Source<T>): Source<T> return x end
local _a1s = idS(mk(1))
type RadioProps<T> = { Value: Source<T>, Option: T }
local function Radio<T>(_p: RadioProps<T>) end
Radio({ Value = mk("a"), Option = "b" })
Radio({ Value = mk("a"), Option = 1 }) -- EXPECT
type ComboProps<T> = { Value: State<T>, Options: { T } }
local function Combo<T>(_p: ComboProps<T>) end
Combo({ Value = mk(1), Options = { 1, 2 } })
Combo({ Value = mk(1), Options = { "x" } }) -- EXPECT
local function takesState(_v: State<number | string>) end
takesState(mk(1))
local function takesStr(_v: State<string>) end
takesStr(mk(1)) -- EXPECT
local function takesSrcWide(_v: Source<number | string>) end
takesSrcWide(mk(1)) -- EXPECT
local s = mk(5)
s:Set(6)
s:Set("x") -- EXPECT
local d2: State<number> = s:Compute(function(self) return self:Get() + 1 end)
local _gs: string = d2:Get() -- EXPECT
local ap: string = s:Apply(function(st) return tostring(st:Get()) end)
local _ = ap
local blocker: { On: (any) -> (), __apply: (self: any, state: any) -> any } = (nil :: any)
local gated: State<number> = s:Apply(blocker)
local _ = gated
local asSD: StateData<number> = s
local _ = asSD
local _o = s:Observer(function(t) local _n: number = t:Get() end)
local _o2 = s:Observer(function(t) local _n: string = t:Get() end) -- EXPECT
local apBad: number = s:Apply(function(st) return tostring(st:Get()) end) -- EXPECT
local _ = apBad
local d3: State<string> = s:Compute(function(self) return self:Get() + 1 end) -- EXPECT
local _ = d3
local dep: State<number> = s:Depend(c1)
local depBad: State<string> = s:Depend(c1) -- EXPECT
local _ = dep; local _ = depBad
local function genericUse<T>(x: State<T>, f: (T) -> string): State<string>
	return x:Compute(function(self) return f(self:Get()) end)
end
local _gu = genericUse(s, function(n: number) return tostring(n) end)
local _guBad = genericUse(s, function(n: string) return n end) -- EXPECT
local srcAsState: State<number | string> = s
local _ = srcAsState
