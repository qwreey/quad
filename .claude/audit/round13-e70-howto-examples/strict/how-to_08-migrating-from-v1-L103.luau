--!strict
-- E70 strict (generated) — how-to_08-migrating-from-v1-L103
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_08-migrating-from-v1-L40) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block how-to/08-migrating-from-v1.md:103 ====
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.KeyGone`·`QuadTypes.SlotItem<T>`)

local width = q.Source(200)
local topbar = q.Source(60)

-- v1: myStore "width,topbar":With(function(w, tb) ... end)
local size = width:Compute(function(
	self: q.StateData<number>,
	_prev: UDim2?,
	tb: q.StateData<number>
): UDim2
	return UDim2.fromOffset(self:Get(), tb:Get())
end, topbar)

local frame = D.Frame { Size = size }
