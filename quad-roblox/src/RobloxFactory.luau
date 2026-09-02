--[[
	RobloxFactory(module) — mutates a quad-base module instance into the
	Roblox backend: installs the lifetime primitives + `nativeClaim`
	(LifetimeHandle.luau) and the M5 engine ops (EngineOps.luau), then
	returns the typed extension (`RobloxExtension` — `D`) for the
	`UseProvider` merge.

	No guard here (`H-305` (d′), 2026-09-02): the old `_initializedBy`
	string marker could not tell two COPIES of quad-roblox apart (a second
	copy — even a different version — read "roblox" and silently no-op'd;
	user diagnosis). The one-slot contract now lives in quad-base's
	`UseProvider` as an fn-identity lock — same fn re-install is an
	idempotent no-op (require caching gives the same identity in the normal
	case), any different identity errors loudly. Install ONLY through
	`quad:UseProvider(QuadRoblox)`; a direct `RobloxFactory(module)` call
	bypasses the lock and the extension merge (unsupported).
]]

local installLifetime = require("./LifetimeHandle")
local installEngineOps = require("./EngineOps")
local InitD = require("./D")
local installPropertyHandler = require("./Handlers/Property")
local installInstanceChildHandler = require("./Handlers/InstanceChild")

local function RobloxFactory(module: any): any
	installLifetime(module)
	installEngineOps(module)
	-- backend-owned handlers (M5 단위 ③ — Property/InstanceChild;
	-- Event/OnChange/Slot은 각 마일스톤에서 합류)
	installPropertyHandler(module)
	installInstanceChildHandler(module)
	-- `H-299` → `H-305` (d′): `D`는 module.D 직접 대입이 아니라
	-- `UseProvider`의 확장 병합으로 실린다 — 반환 테이블이 그 확장이고,
	-- `RobloxExtension` 타입(init.luau)이 이 모양의 정본. 사용법은 동일:
	-- `local D = quad.D`(병합 후) 또는 반환 교집합에서 바로 `q.D`.
	return { D = InitD(module) }
end

return RobloxFactory
