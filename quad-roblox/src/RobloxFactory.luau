--[[
	RobloxFactory(module) — mutates a quad-base module instance into the
	Roblox backend: installs the lifetime primitives + `nativeClaim`
	(LifetimeHandle.luau) and the M5 engine ops (EngineOps.luau).

	Guard is the `_initializedBy` string marker — a PUBLIC one-slot contract
	distinct from quad-base's internal `RunInit` idempotence
	(`base/module-lifecycle-plan.md`): calling the same factory again is a
	no-op, a different factory having filled the slot is an error (a module
	cannot serve two backends).
]]

local QuadTypes = require("../luau_packages/quad_types")
local installLifetime = require("./LifetimeHandle")
local installEngineOps = require("./EngineOps")
local InitD = require("./D")

local function RobloxFactory(module: any): any
	-- tag before any raise below — without the surface tag the error walker
	-- falls back to the raise site and blames this file (`H-238`)
	module.errorNamespace.setFuncLevel(RobloxFactory, QuadTypes.ERROR_LEVEL_SURFACE)
	if module._initializedBy == "roblox" then
		return module -- same factory called again = no-op
	end
	if module._initializedBy ~= nil then
		-- errorBefore (outermost surface) so both direct calls and the
		-- QuadRoblox entry blame the user's line (`H-272` precedent)
		module.errorNamespace.errorBefore(
			`Quad module already initialized by '{module._initializedBy}'`,
			QuadTypes.ERROR_LEVEL_SURFACE
		)
	end
	module._initializedBy = "roblox"

	installLifetime(module)
	installEngineOps(module)
	-- `H-299` (①, 뒤집기 가능): `D`의 획득 경로는 코퍼스에 미지정이었다 —
	-- 백엔드가 모듈 필드를 설치하는 기존 채널(op들과 같은 자리) 그대로
	-- `module.D`로 노출한다. 사용법: `local D = quad.D`.
	module.D = InitD(module)
	return module
end

return RobloxFactory
