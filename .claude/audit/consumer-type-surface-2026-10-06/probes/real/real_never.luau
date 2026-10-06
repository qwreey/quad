--!strict
local Quad = require("../quad-roblox/luau_packages/quad_base")
local RobloxModule = require("../quad-roblox/src")
local QuadTypes = require("../quad-roblox/luau_packages/quad_types")
local q = Quad:UseProvider(RobloxModule.QuadRoblox)
type State<T> = QuadTypes.State<T>
type Source<T> = QuadTypes.Source<T>
type RN<T> = { read __quadState: true, read __quadStateValue: T, read Get: (self: never) -> T }
type WN<T> = { read __quadState: true, read __quadStateValue: T, read Get: (self: never) -> T, read Set: (self: never, v: T) -> any }
local c1: State<number> = q.Source(1)
local function r<T>(x: RN<T>): T return ((x :: any) :: State<T>):Get() end
local _1: number = r(c1)
local _1b: string = r(c1) -- EXPECT
local function enumR(_v: RN<EnumItem>) end
enumR(q.Source(Enum.EasingStyle.Quad))
enumR(q.Source(1)) -- EXPECT
type Props<T> = { read Value: WN<T>, read Option: T, read OnChange: ((T) -> ())? }
local function Radio<T>(p: Props<T>) local v = (p.Value :: any) :: Source<T>; v:Set(p.Option) end
Radio({ Value = q.Source("a"), Option = "b", OnChange = function(_s: string) end })
Radio({ Value = q.Source("a"), Option = 1 }) -- EXPECT
Radio({ Value = c1, Option = 1 }) -- EXPECT
type CProps<T> = { read Value: RN<T>, read Options: { T }, read OnChange: ((T) -> ())? }
local function Combo<T>(_p: CProps<T>) end
Combo({ Value = q.Source(1), Options = { 1, 2 }, OnChange = function(_n: number) end })
Combo({ Value = q.Source(1), Options = { "x" } }) -- EXPECT
local D = q.Declaration
local function lbl(v: RN<string>) return D.TextLabel({ Text = v }) end
local _l = lbl(q.Source("x"))
