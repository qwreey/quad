--!strict
-- E33: the core/06 :Single claim "Source<string?> 로 Slot<Instance>를 updateFn으로 매핑해 모는 모양이 그대로 타입 검사를 통과"
local QT = require("../../../quad-roblox/luau_packages/quad_types")
local q: QT.Quad = nil :: any
local inst: Instance = nil :: any
local sl = q.Slot<<Instance>>()
local name: QT.Source<string?> = q.Source<<string?>>(nil)
sl:Single(name, function(ctx) return inst end) -- V1 doc claim, unannotated lambda
local v: string? = nil
sl:Single(v, function(ctx) return inst end) -- V2 plain value
type Ctx = { Item: string | QT.KeyGone, Index: number, Offset: QT.State<number>, Prev: QT.SlotItem<Instance>?, UserData: nil? }
local function upd(ctx: Ctx): (any, nil) return inst, nil end
sl:Single(name, upd) -- V3 named, fully annotated
sl:List({ "a" }, function(ctx) return inst end) -- V4 :List control (same lambda)
local _l: QT.Slot<Instance> = sl

-- (appended) V5: spec.slottypes form — ctx Item = any
type CtxAny = { Item: any, Index: number, Offset: QT.State<number>, Prev: QT.SlotItem<Instance>?, UserData: nil? }
sl:Single(name, function(ctx: CtxAny): (any, nil) return inst, nil end) -- V5 passes?
-- V6: typed ctx Item = string, returns annotated
sl:Single(name, function(ctx: Ctx): (any, nil) return inst, nil end) -- V6
-- V7: explicit type args <<string, nil>>
sl:Single<<string, nil>>(name, function(ctx) return inst, nil end) -- V7
return nil
