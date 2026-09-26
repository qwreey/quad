--!strict
-- E14 settings module (simulates GS 01 settings module; relative paths for CLI)
local Quad = require("../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../quad-roblox/src").QuadRoblox
local QuadTypes = require("../../quad-roblox/luau_packages/quad_types")
export type State<T> = QuadTypes.State<T>
export type Source<T> = QuadTypes.Source<T>
export type Slot<T> = QuadTypes.Slot<T>
export type StateData<T> = QuadTypes.StateData<T>
export type Ref<T> = QuadTypes.Ref<T>
return Quad:UseProvider(QuadRoblox)
