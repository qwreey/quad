-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require("@game/ReplicatedStorage/roblox_packages/quad_base")
local QuadRoblox = require("@game/ReplicatedStorage/roblox_packages/quad_roblox").QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.Declaration
