--[[
	quad-roblox package entry. `QuadRoblox` is the PROVIDER FUNCTION for
	`quad:UseProvider(QuadRoblox)` (`H-305` (d′), 2026-09-02 사용자 확정 —
	스파이크 23이 2026-08-19에 예정해뒀던 그 모양): it version-checks the
	injected quad-base instance at compile time (`CheckedQuad<T, Pattern>`,
	`quad-types` — the monorepo pins the exact version "0.0.0"; independently
	published backends would pick a looser pattern), lets RobloxFactory
	mutate the module (ops/handlers), and returns the typed extension
	`RobloxExtension` — so `q.D` is fully typed through the `Self & P`
	intersection with zero casts. The one-slot/identity guard lives in
	`UseProvider` itself, not here.

	Runtime dependency is quad-types only — the module instance arrives as an
	argument, so quad-base is never required here (round14 Q3 (a); tests use
	it as a dev dependency instead).
]]

local QuadTypes = require("./luau_packages/quad_types")
local RobloxFactory = require("@self/RobloxFactory")
local Types = require("@self/types")
local DModule = require("@self/D")

-- 공개 타입 재익스포트(ROADMAP M5 배너 — 몰아두는 단일 파일은 types.luau).
-- `D`/`DMapper`/`<Class>Param<E>` 전량은 생성 파일(src/D)이 소스라 여기선
-- 네임스페이스 타입 둘만 재익스포트 — 개별 Param이 필요한 소비자는
-- 생성 모듈에서 직접 가져간다(손 나열은 "전량 생성" 계약과 충돌, `H-305`).
export type Tween<T> = Types.Tween<T>
export type NewChild = Types.NewChild
export type D = DModule.D
export type DMapper = DModule.DMapper
export type RobloxExtension = { D: DModule.D }

local function QuadRoblox<T>(quad: T): RobloxExtension
	-- virtual-field version check — referencing the field is what evaluates it
	local checked: QuadTypes.CheckedQuad<T, "0.0.0"> = quad :: any
	local _forceCheck = checked.__versionCheck
	-- surface tag so raises below blame the caller's line (`H-238`)
	;(quad :: any).errorNamespace.setFuncLevel(QuadRoblox, QuadTypes.ERROR_LEVEL_SURFACE)
	return RobloxFactory(quad :: any)
end

return {
	QuadRoblox = QuadRoblox,
}
