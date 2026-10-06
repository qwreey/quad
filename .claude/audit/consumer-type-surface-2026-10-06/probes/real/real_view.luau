--!strict
local Quad = require("../quad-roblox/luau_packages/quad_base")
local RobloxModule = require("../quad-roblox/src")
local QuadTypes = require("../quad-roblox/luau_packages/quad_types")
local q = Quad:UseProvider(RobloxModule.QuadRoblox)
type State<T> = QuadTypes.State<T>
type StateData<T> = QuadTypes.StateData<T>
type Source<T> = QuadTypes.Source<T>
-- read-only covariant views
type ViewAny<T> = { read __quadState: true, read __quadStateValue: T, read Get: (self: any) -> T }
type ViewNever<T> = { read __quadState: true, read __quadStateValue: T, read Get: (self: never) -> T }
-- writable views
type WAny<T> = { read __quadState: true, read __quadStateValue: T, read Get: (self: any) -> T, read Set: (self: any, v: T) -> any }
type WNever<T> = { read __quadState: true, read __quadStateValue: T, read Get: (self: never) -> T, read Set: (self: never, v: T) -> any }
local c1: State<number> = q.Source(1)
local function vA<T>(x: ViewAny<T>): T return x:Get() end
local _1: number = vA(c1)
local _1s: number = vA(q.Source(1))
local _1d: number = vA(c1:Compute(function(self: StateData<number>) return self:Get() end))
local _1bad: string = vA(c1) -- EXPECT
local function vN<T>(x: ViewNever<T>): T return x:Get() end
local _2: number = vN(c1)
local function takeEnumV(_v: ViewAny<EnumItem>) end
takeEnumV(q.Source(Enum.EasingStyle.Quad))
takeEnumV(q.Source(1)) -- EXPECT
local function wA<T>(x: WAny<T>, v: T) x:Set(v) end
wA(q.Source("a"), "b")
wA(q.Source("a"), 1) -- EXPECT
wA(c1, 1) -- EXPECT
local function wN<T>(x: WNever<T>, v: T) local _ = x; local _ = v end
wN(q.Source("a"), "b")
type RadioProps<T> = { Value: WAny<T>, Option: T }
local function Radio<T>(_p: RadioProps<T>) end
Radio({ Value = q.Source("a"), Option = "b" })
Radio({ Value = q.Source("a"), Option = 1 }) -- EXPECT
type ComboProps<T> = { Value: ViewAny<T>, Options: { T } }
local function Combo<T>(_p: ComboProps<T>) end
Combo({ Value = q.Source(Enum.EasingStyle.Quad), Options = { Enum.EasingStyle.Quad } })
-- view into quad input slots (marker) -- views must still be usable as State input
local D = q.Declaration
local function lbl(v: ViewAny<string>) return D.TextLabel({ Text = v }) end
local _l = lbl(q.Source("x"))
-- marker for comparison
type M<T> = QuadTypes.StateMarker<T>
local function mk<T>(x: M<T>): M<T> return x end
local _m = mk(c1)
