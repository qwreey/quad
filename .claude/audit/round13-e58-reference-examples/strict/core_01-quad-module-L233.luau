--!strict
-- E58 strict (generated) — core_01-quad-module-L233
-- ==== page prologue core/01-quad-module.md (core_01-quad-module-L13.luau) ====
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require("../../../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../../../quad-roblox/src").QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.Declaration
-- ==== doc block core/01-quad-module.md:233 (line offset marker) ====
local Impl = {}
Impl.__index = Impl
Impl._moduleIdentity = q.moduleIdentity -- 값마다가 아니라 메타테이블에 한 번

local function assertOwn(value)
	if value._moduleIdentity ~= q.moduleIdentity then
		error("MyPlugin: value belongs to another quad instance", 2)
	end
end
