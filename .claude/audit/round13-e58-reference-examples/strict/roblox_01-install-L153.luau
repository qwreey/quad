--!strict
-- E58 strict (generated) — roblox_01-install-L153
-- ==== page prologue roblox/01-install.md (roblox_01-install-L20.luau) ====
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require("../../../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../../../quad-roblox/src").QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.Declaration
-- ==== doc block roblox/01-install.md:153 (line offset marker) ====
local RobloxModule = require("../../../../quad-roblox/src")
local fade: RobloxModule.Tween<number> = q.Tween({ Value = 0, Time = 0.2 })
