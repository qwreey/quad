--!strict
local Quad = require("../quad-roblox/luau_packages/quad_base")
local RobloxModule = require("../quad-roblox/src")
local QuadTypes = require("../quad-roblox/luau_packages/quad_types")
local q = Quad:UseProvider(RobloxModule.QuadRoblox)
type State<T> = QuadTypes.State<T>
local n = q.Source(1)
local ok1: State<number> = n:Apply(q.Operator.Sum(1))
local bad1: State<string> = n:Apply(q.Operator.Sum(1)) -- EXPECT
local f = function(st: State<number>): string return tostring(st:Get()) end
local ok2: string = n:Apply(f)
local bad2: number = n:Apply(f) -- EXPECT
local b = q.Blocker()
local ok3: State<number> = n:Apply(b)
local ok4: State<number> = n:Apply(q.Debounce({ Time = 0.1 }))
local _ = ok1; local _ = bad1; local _ = ok2; local _ = bad2; local _ = ok3; local _ = ok4
