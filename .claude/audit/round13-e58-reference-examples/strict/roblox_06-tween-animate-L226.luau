--!strict
-- E58 strict (generated) — roblox_06-tween-animate-L226
-- ==== page prologue roblox/06-tween-animate.md (roblox_06-tween-animate-L20.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local RobloxModule = require("../../../../quad-roblox/src") -- `Tween<T>` 타입
local D = q.Declaration
-- ==== doc block roblox/06-tween-animate.md:226 (line offset marker) ====
-- 첫 값은 즉시 10, 그다음 Set부터 애니메이션
local size = q.Source(q.Tween({ Value = 10, Time = 0.3 }))
local box = D.Frame({ BackgroundTransparency = size })
