--!strict
local Quad = require("../quad-roblox/luau_packages/quad_base")
local RobloxModule = require("../quad-roblox/src")
local QuadTypes = require("../quad-roblox/luau_packages/quad_types")
local q = Quad:UseProvider(RobloxModule.QuadRoblox)
type State<T> = QuadTypes.State<T>
type StateMarker<T> = QuadTypes.StateMarker<T>
type CProps<T> = { Value: StateMarker<T>, Options: { T }, OnChange: ((T) -> ())? }
local function Combo<T>(p: CProps<T>)
	local v = (p.Value :: any) :: State<T>
	local _label: State<string> = v:Compute(function(self) return tostring(self:Get()) end)
end
Combo({ Value = q.Source(1), Options = { 1, 2 }, OnChange = function(_n: number) end })
Combo({ Value = q.Source(1), Options = { "x" } }) -- EXPECT
local function takesEnum(_v: StateMarker<EnumItem>) end
takesEnum(q.Source(Enum.EasingStyle.Quad))
local function show<T>(st: StateMarker<T>): State<string>
	return ((st :: any) :: State<T>):Compute(function(self) return tostring(self:Get()) end)
end
local _s = show(q.Source(3))
local _s2 = show(q.Source(3):Compute(function(self: QuadTypes.StateData<number>) return self:Get() end))
