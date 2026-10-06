--!strict
local Quad = require("../quad-roblox/luau_packages/quad_base")
local RobloxModule = require("../quad-roblox/src")
local QuadTypes = require("../quad-roblox/luau_packages/quad_types")
local q = Quad:UseProvider(RobloxModule.QuadRoblox)
local D = q.Declaration
type State<T> = QuadTypes.State<T>
type StateData<T> = QuadTypes.StateData<T>
type Source<T> = QuadTypes.Source<T>
local num = q.Source(1)
local str = q.Source("a")
local _n1 = D.TextLabel({ Text = num }) -- EXPECT
local _n2 = D.Frame({ Size = num }) -- EXPECT
local _p1 = D.TextLabel({ Text = str })
local _p2 = D.Frame({ Size = q.Source(UDim2.new()) })
num:Set("x") -- EXPECT
local _n3: number = str:Get() -- EXPECT
local function takesSrcWide(_v: Source<number | string>) end
takesSrcWide(num) -- EXPECT
local function takesSD(_v: StateData<string>) end
takesSD(num) -- EXPECT
local _o = num:Observer(function(t) local _x: string = t:Get() end) -- EXPECT
local _c: State<string> = num:Compute(function(self) local _x: string = self:Get(); return "" end) -- EXPECT
local sl = q.Slot<<Instance>>()
sl:Add(num) -- EXPECT
sl:Add(q.Source(D.Frame({})))
local _e = q.Effect(function() local _x: string = num:Get() end, num) -- EXPECT
local derived: State<number> = num:Compute(function(self) return self:Get() * 2 end)
local _n4 = D.TextLabel({ Text = derived }) -- EXPECT
local _p3 = D.Frame({ Visible = num:Compute(function(self: StateData<number>) return self:Get() > 0 end) })
local _n5 = D.Frame({ Visible = num:Compute(function(self: StateData<number>) return self:Get() end) }) -- EXPECT
local st: Source<number> = num
st:SetIfChanged(true) -- EXPECT
local bad: Source<string> = num -- EXPECT
local _ = bad
local okWide: State<number | string> = num
local _ = okWide
