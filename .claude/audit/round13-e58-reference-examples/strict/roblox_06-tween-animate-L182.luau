--!strict
-- E58 strict (generated) — roblox_06-tween-animate-L182
-- ==== page prologue roblox/06-tween-animate.md (roblox_06-tween-animate-L20.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local RobloxModule = require("../../../../quad-roblox/src") -- `Tween<T>` 타입
local D = q.Declaration
-- ==== doc block roblox/06-tween-animate.md:182 (line offset marker) ====
local alpha = q.Source(0)
local animated = alpha:Apply(q.Animate({ Time = 0.3, Style = Enum.EasingStyle.Quad }))

local reduceMotion = q.Source(false)
local guarded = alpha:Apply(q.Animate({
	Time = 0.3,
	CanAnimate = reduceMotion:Compute(function(self: q.StateData<boolean>): boolean
		return not self:Get()
	end),
}))

local box = D.Frame({ BackgroundTransparency = animated })
