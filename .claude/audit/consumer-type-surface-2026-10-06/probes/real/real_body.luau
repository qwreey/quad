--!strict
local Quad = require("../quad-roblox/luau_packages/quad_base")
local RobloxModule = require("../quad-roblox/src")
local QuadTypes = require("../quad-roblox/luau_packages/quad_types")
local q = Quad:UseProvider(RobloxModule.QuadRoblox)
local D = q.Declaration
type State<T> = QuadTypes.State<T>
type StateData<T> = QuadTypes.StateData<T>
type Source<T> = QuadTypes.Source<T>
type Slot<T> = QuadTypes.Slot<T>

local c1: State<number> = q.Source(1)
-- A1
local function id<T>(x: State<T>): State<T> return x end
local _a1 = id(c1)
local function idS<T>(x: Source<T>): Source<T> return x end
local _a1s = idS(q.Source(1))
local function idL<T>(x: State<{ T }>): State<{ T }> return x end
local _a1l = idL(q.Source({ 1, 2 }))
-- A2
local function takesEnum(_v: State<EnumItem>) end
takesEnum(q.Source(Enum.EasingStyle.Quad))
local function takesStr(_v: State<string>) end
takesStr(q.Source(1)) -- EXPECT
local function takesSrcWide(_v: Source<EnumItem>) end
takesSrcWide(q.Source(Enum.EasingStyle.Quad)) -- EXPECT
-- F1
local src = q.Source(1)
local _l1 = D.TextLabel({ Text = src:Compute(function(self) return `{self:Get()}` end) })
local _l2 = D.TextLabel({ Text = src:Compute(function(self: StateData<number>) return `{self:Get()}` end) })
local _l3 = D.TextLabel({ Text = src:Compute(function(self) return self:Get() end) }) -- EXPECT
-- A5b
local _r1 = q.PreRef(nil :: Frame?):Callback(function(inst) local _ = inst end)
local _r2 = q.PreRef(nil :: Frame?):Callback(function(inst: Frame?) local _ = inst end)
local _r3 = q.PreRef(nil :: Frame?):Callback(function(inst) if inst then inst.Visible = true end end)
local _r4 = q.PreRef(nil :: Frame?):Callback(function(inst, ref) if inst then inst.Visible = ref.Value ~= nil end end)
local _r5 = q.PostRef(nil :: Frame?):Callback(function(inst) if inst then inst.Visible = true end end)
local rr = q.Ref(nil :: Frame?)
rr:Callback(function(inst) if inst then inst.Visible = true end end)
-- generic list keyFn (A1 family)
local function listOf<T>(data: State<{ T }>, key: (T) -> string): Slot<Instance>
	local sl = q.Slot<<Instance>>()
	sl:List(data, function(ctx) return D.TextLabel({ Text = "x" }) end, key)
	return sl
end
local _s = listOf(q.Source({ "a" }), function(s: string) return s end)
-- ordinary
local s = q.Source(5)
s:Set(6)
s:Set("x") -- EXPECT
local d2: State<number> = s:Compute(function(self) return self:Get() + 1 end)
local _g: number = d2:Get()
local _gs: string = d2:Get() -- EXPECT
local _o = s:Observer(function(t) local _n: number = t:Get() end)
-- A5b inline in children
local _f1 = D.Frame({ q.PreRef(nil :: Frame?):Callback(function(inst) if inst then inst.Visible = true end end) })
local _f2 = D.Frame({ q.PreRef(nil :: Frame?):Callback(function(inst: Frame?) if inst then inst.Visible = true end end) })
local _f3 = D.Frame({ q.PreRef(nil :: Frame?):Callback(function(inst) local _ = inst end) })
-- Observer inline in children (8.30 cousin)
local _f4 = D.Frame({ src:Observer(function(t) local _n: number = t:Get() end) })
-- F1 negative: inline Compute returning number into Text must still fail
local _l4 = D.TextLabel({ Text = src:Compute(function(self) return self:Get() + 1 end) }) -- EXPECT
-- keyFn consumer prescription
local function listOf2<T>(data: State<{ T }>, key: (T, number) -> string): Slot<Instance>
	local sl = q.Slot<<Instance>>()
	sl:List(data, function(_ctx) return D.TextLabel({ Text = "x" }) end, key)
	return sl
end
local _s2 = listOf2(q.Source({ "a" }), function(s: string) return s end)
-- generic components (library author)
type RadioProps<T> = { Value: Source<T>, Option: T }
local function Radio<T>(props: RadioProps<T>): Frame
	local _sel: State<boolean> = props.Value:Compute(function(self) return self:Get() == props.Option end)
	return D.Frame({})
end
local _rad = Radio({ Value = q.Source("a"), Option = "b" })
local _radBad = Radio({ Value = q.Source("a"), Option = 1 }) -- EXPECT
type ComboProps<T> = { Value: State<T>, Options: { T } }
local function Combo<T>(props: ComboProps<T>): Frame
	local _ = props
	return D.Frame({})
end
local _cmb = Combo({ Value = q.Source(Enum.EasingStyle.Quad), Options = { Enum.EasingStyle.Quad, Enum.EasingStyle.Linear } })
local function show<T>(st: State<T>): State<string>
	return st:Compute(function(self) return tostring(self:Get()) end)
end
local _sh = show(q.Source(3))
local _shd = show(src:Compute(function(self: StateData<number>) return self:Get() * 2 end))
