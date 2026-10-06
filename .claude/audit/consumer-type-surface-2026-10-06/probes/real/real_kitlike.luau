--!strict
local Quad = require("../quad-roblox/luau_packages/quad_base")
local RobloxModule = require("../quad-roblox/src")
local QuadTypes = require("../quad-roblox/luau_packages/quad_types")
local q = Quad:UseProvider(RobloxModule.QuadRoblox)
type State<T> = QuadTypes.State<T>
type StateData<T> = QuadTypes.StateData<T>
type Source<T> = QuadTypes.Source<T>
local D = q.Declaration
-- flat writable view (candidate (b) shape, name provisional)
type SourceView<T> = {
	read __quadState: true, read __quadStateValue: T,
	read Get: (self: any) -> T,
	read Set: (self: any, v: T) -> any,
	read Compute: <U>(self: any, fn: (self: StateData<T>, previous: U?, ...any) -> U, ...any) -> State<U>,
}
type Props1<T> = { read Value: Source<T>, read Option: T, read OnChange: ((option: T) -> ())? }
type Props2<T> = { read Value: SourceView<T>, read Option: T, read OnChange: ((option: T) -> ())? }
type Props3<T> = { read Value: State<T>, read Options: { T } }
local function Radio1<T>(p: Props1<T>): TextButton
	local sel: State<boolean> = p.Value:Compute(function(self) return self:Get() == p.Option end)
	return D.TextButton({ Visible = sel })
end
local function Radio2<T>(p: Props2<T>): TextButton
	local sel: State<boolean> = p.Value:Compute(function(self) return self:Get() == p.Option end)
	p.Value:Set(p.Option)
	return D.TextButton({ Visible = sel })
end
local function Combo3<T>(p: Props3<T>): Frame
	local _ = p
	return D.Frame({})
end
type Scheme = "Dark" | "Light"
local scheme = q.Source("Dark" :: Scheme)
local _1 = Radio1({ Value = scheme, Option = "Light" })
local _2 = Radio2({ Value = scheme, Option = "Light" })
local _2b = Radio2({ Value = scheme, Option = "Blue" }) -- EXPECT
local _2c = Radio2({ Value = scheme:Compute(function(self: StateData<Scheme>) return self:Get() end) :: State<Scheme>, Option = "Light" }) -- EXPECT
local _3 = Combo3({ Value = q.Source(Enum.EasingStyle.Quad), Options = { Enum.EasingStyle.Quad, Enum.EasingStyle.Linear } })
local _1x = Radio1<<Scheme>>({ Value = scheme, Option = "Light" })
