--!strict
-- Mirrors docs/getting-started/01-setup.md §1 verbatim (aliases substituted with
-- relative paths for this scratch check; requires the source tree, NOT luau_packages,
-- so this reflects current quad-base/quad-roblox/quad-types source).
local Quad = require("../../../quad-base/src")
local QuadRoblox = require("../../../quad-roblox/src").QuadRoblox
local QuadTypes = require("../../../quad-types/src")

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
