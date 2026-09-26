--!strict
-- E58 strict (generated) — roblox_06-tween-animate-L61
-- ==== page prologue roblox/06-tween-animate.md (roblox_06-tween-animate-L20.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local RobloxModule = require("../../../../quad-roblox/src") -- `Tween<T>` 타입
local D = q.Declaration
-- ==== doc block roblox/06-tween-animate.md:61 (line offset marker) ====
local open = q.Source(false)

local size = open:Compute(function(self: q.StateData<boolean>): RobloxModule.Tween<UDim2>
	return q.Tween({
		Value = if self:Get() then UDim2.fromOffset(320, 200) else UDim2.fromOffset(320, 0),
		Time = 0.25,
		Style = Enum.EasingStyle.Quart,
		Direction = Enum.EasingDirection.Out,
		Override = "Finish",
	})
end)

local panel = D.Frame({ Size = size })
