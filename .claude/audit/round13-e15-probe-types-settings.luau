--!strict
-- E15 settings module = GS 01 settings module verbatim, relative paths for CLI.
local Quad = require("../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../quad-roblox/src").QuadRoblox
local QuadTypes = require("../../quad-roblox/luau_packages/quad_types")
export type State<T> = QuadTypes.State<T>
export type Source<T> = QuadTypes.Source<T>
export type Slot<T> = QuadTypes.Slot<T>
export type StateData<T> = QuadTypes.StateData<T>
export type Provider<T> = QuadTypes.Provider<T>
export type Context = QuadTypes.Context
export type Ref<T> = QuadTypes.Ref<T>
export type Observer = QuadTypes.Observer
export type Effect = QuadTypes.Effect
return Quad:UseProvider(QuadRoblox)
