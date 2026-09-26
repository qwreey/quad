--!strict
-- [E56] GS 01 §1 설정 모듈 그대로, 경로만 로컬 — 한 luau_packages 벌(quad-roblox/luau_packages)에서만 require(typing-limits 8.34).
const Quad = require("../../../../../quad-roblox/luau_packages/quad_base")
const QuadRoblox = require("../../../../../quad-roblox/src").QuadRoblox
const QuadTypes = require("../../../../../quad-roblox/luau_packages/quad_types")

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
