--!strict
-- E58 strict (generated) — roblox_06-tween-animate-L127
-- ==== page prologue roblox/06-tween-animate.md (roblox_06-tween-animate-L20.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local RobloxModule = require("../../../../quad-roblox/src") -- `Tween<T>` 타입
local D = q.Declaration
-- ==== doc block roblox/06-tween-animate.md:127 (line offset marker) ====
local FADE = q.Tween({ Value = 0, Time = 0.15 })

local a = FADE:Mapped(function(v: number): number return 1 end)  -- Time = 0.15 유지
local b = FADE:Mapped(function(v: number): number return 0.5 end)
