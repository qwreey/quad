--!strict
local Quad = require("../quad-roblox/luau_packages/quad_base")
local RobloxModule = require("../quad-roblox/src")
local QuadTypes = require("../quad-roblox/luau_packages/quad_types")
local q = Quad:UseProvider(RobloxModule.QuadRoblox)
type State<T> = QuadTypes.State<T>
type StateData<T> = QuadTypes.StateData<T>
type V1<T> = { read __quadState: true, read __quadStateValue: T, read Get: (self: StateData<T>) -> T }
local D = q.Declaration
local c1: State<number> = q.Source(1)
local function v1<T>(x: V1<T>): T return x:Get() end
local _a: number = v1(c1)
local _b: number = v1(q.Source(1))
local function enumV1(_v: V1<EnumItem>) end
enumV1(q.Source(Enum.EasingStyle.Quad))
local function sd<T>(x: StateData<T>): T return x:Get() end
local _c: number = sd(q.Source(1))
local function enumSD(_v: StateData<EnumItem>) end
enumSD(q.Source(Enum.EasingStyle.Quad))
local function lblSD(v: StateData<string>) return D.TextLabel({ Text = v }) end
local _l = lblSD(q.Source("x"))
local function showSD<T>(v: StateData<T>) return D.TextLabel({ Text = q.Source(""):Depend(v):Compute(function(_s: StateData<string>) return tostring(v:Get()) end) }) end
local _sh = showSD(q.Source(3))
