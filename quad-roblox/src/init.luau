--[[
	quad-roblox package entry. `QuadRoblox` is the PROVIDER FUNCTION for
	`quad:UseProvider(QuadRoblox)` (`H-305` (d′), 2026-09-02 사용자 확정 —
	스파이크 23이 2026-08-19에 예정해뒀던 그 모양): it version-checks the
	injected quad-base instance AT RUNTIME (`H-306` (a), 사용자 확정 — the
	compile-time `CheckedQuad` wiring here was silently inert: a
	generic-body local annotation is never re-evaluated per call site
	(quad-types-plan trap 2, measured), and NO type position forces the
	check through the `UseProvider` indirection (candidate matrix measured
	same day). One string compare at install — the monorepo pins the exact
	version "0.0.0"; independently published backends would pick a looser
	pattern), lets RobloxFactory mutate the module (ops/handlers), and
	returns the typed extension `RobloxExtension` — so `q.D` is fully typed
	through the `Self & P` intersection with zero casts. The
	one-slot/identity guard lives in `UseProvider` itself, not here.

	Runtime dependencies are quad-types + type-version-check only (both
	small and engine-free) — the module instance arrives as an argument, so
	quad-base is never required here (round14 Q3 (a); tests use it as a dev
	dependency instead).
]]

local QuadTypes = require("./luau_packages/quad_types")
local TypeVersionCheck = require("./luau_packages/type_version_check")
local RobloxFactory = require("@self/RobloxFactory")
local Types = require("@self/types")
local DModule = require("@self/D")

-- 독립 게시 백엔드는 여기만 느슨한 패턴("0.*.*"류)으로 바꾸면 된다
local VERSION_PATTERN = "0.0.0"

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
	local q = quad :: any
	-- surface tag so raises below blame the caller's line (`H-238`)
	q.errorNamespace.setFuncLevel(QuadRoblox, QuadTypes.ERROR_LEVEL_SURFACE)
	-- `H-306` (a): runtime version gate — errors climb to the consumer's
	-- UseProvider line (UseProvider is the outermost tagged frame)
	if type(q.Version) ~= "string" or not TypeVersionCheck.matchesPattern(q.Version, VERSION_PATTERN) then
		q.errorNamespace.errorBefore(
			`quad-roblox requires a quad-base matching version pattern '{VERSION_PATTERN}', got '{tostring(q.Version)}'`,
			QuadTypes.ERROR_LEVEL_SURFACE
		)
	end
	return RobloxFactory(q)
end

return {
	QuadRoblox = QuadRoblox,
}
