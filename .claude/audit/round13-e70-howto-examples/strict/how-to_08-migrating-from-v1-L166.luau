--!strict
-- E70 strict (generated) — how-to_08-migrating-from-v1-L166
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_08-migrating-from-v1-L40) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block how-to/08-migrating-from-v1.md:166 ====
-- v1: myStore "color":Tween{ Time = 2 }
local hovered = q.Source(false)
local color = hovered:Compute(function(self: q.StateData<boolean>): Color3
	return if self:Get() then Color3.fromRGB(60, 60, 60) else Color3.fromRGB(35, 35, 35)
end):Apply(q.Animate { Time = 0.2, Style = Enum.EasingStyle.Quad })

-- 값마다 옵션을 다르게 주고 싶으면 Tween을 :Compute 안에서 만든다
local target = q.Source(UDim2.fromScale(0, 0))
local position = target:Compute(function(self: q.StateData<UDim2>): any
	return q.Tween { Value = self:Get(), Time = 0.5, Override = "Cancel" }
end)

local frame = D.Frame { BackgroundColor3 = color, Position = position }
