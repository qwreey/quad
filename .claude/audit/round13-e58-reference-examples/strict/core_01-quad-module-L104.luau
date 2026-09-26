--!strict
-- E58 strict (generated) — core_01-quad-module-L104
-- ==== page prologue core/01-quad-module.md (core_01-quad-module-L13.luau) ====
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require("../../../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../../../quad-roblox/src").QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.Declaration
-- ==== doc block core/01-quad-module.md:104 (line offset marker) ====
local function doublePlugin(_self)
	return {
		Double = function(_selfArg, v: number)
			return v * 2
		end,
	}
end

local m = Quad.New():AddPlugin(doublePlugin)
print(m:Double(21)) --> 42
