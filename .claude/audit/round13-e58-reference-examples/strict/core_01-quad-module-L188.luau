--!strict
-- E58 strict (generated) — core_01-quad-module-L188
-- ==== page prologue core/01-quad-module.md (core_01-quad-module-L13.luau) ====
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require("../../../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../../../quad-roblox/src").QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.Declaration
-- ==== doc block core/01-quad-module.md:188 (line offset marker) ====
q.debug = true -- 동률·덮어쓰기·모르는 옵션 키·Claim 디스크립터 진단을 켠다
