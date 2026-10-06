--!strict
local Quad = require("../quad-roblox/luau_packages/quad_base")
local RobloxModule = require("../quad-roblox/src")
local QuadTypes = require("../quad-roblox/luau_packages/quad_types")
local q = Quad:UseProvider(RobloxModule.QuadRoblox)
type M<T> = QuadTypes.StateMarker<T>
type State<T> = QuadTypes.State<T>
local function out1<T>(_s: M<T> & { read Set: (self: any, value: T) -> any }) end
out1(q.Source(""))
local function out2(_s: { read Set: (self: any, value: string) -> any }) end
out2(q.Source(""))
local function out3(_s: M<string> & { read Set: (self: any, value: string) -> any }) end
out3(q.Source(""))
out3((nil :: any) :: State<string>) -- EXPECT
out3(q.Source(5)) -- EXPECT
