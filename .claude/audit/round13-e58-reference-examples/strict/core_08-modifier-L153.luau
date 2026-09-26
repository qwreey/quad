--!strict
-- E58 strict (generated) — core_08-modifier-L153
-- ==== page prologue core/08-modifier.md (core_08-modifier-L18.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.FieldOut<T>` 등)
local D = q.Declaration
-- ==== doc block core/08-modifier.md:153 (line offset marker) ====
local scale = q.Source(1)
local base = D.Modifier.Frame { BackgroundTransparency = 0.5, LayoutOrder = 1 }

local dimmed = base:BackgroundTransparency(0.9)     -- 리터럴
local live = base:LayoutOrder(scale)                -- State 핸들 그대로
local cleared = base:BackgroundTransparency(q.None) -- 명시 해제

-- 변환: 지금 값이 평범한 값이면 그 값이 온다(필드가 없으면 nil)
local bumped = base:LayoutOrder(function(old) return (old :: number) + 1 end)
-- 변환: 지금 값이 State면 :Compute로 이어지고 old는 핸들이다
local doubled = live:LayoutOrder(function(old)
    return (old :: q.StateData<number>):Get() * 2
end)

-- base 는 여전히 0.5 — 전부 새 값이다
