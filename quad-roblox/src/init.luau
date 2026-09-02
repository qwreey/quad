--[[
	quad-roblox package entry. `QuadRoblox(quad)` version-checks the injected
	quad-base instance at compile time (`CheckedQuad<T, Pattern>`,
	`quad-types` — the monorepo pins the exact version "0.0.0"; independently
	published backends would pick a looser pattern) and hands it to
	RobloxFactory for backend installation.

	Runtime dependency is quad-types only — the module instance arrives as an
	argument, so quad-base is never required here (round14 Q3 (a); tests use
	it as a dev dependency instead).

	Later M5 units extend this export table (`D`, `Claim`).
]]

local QuadTypes = require("./luau_packages/quad_types")
local RobloxFactory = require("@self/RobloxFactory")
local Types = require("@self/types")

-- 공개 타입 재익스포트(ROADMAP M5 배너 — 몰아두는 단일 파일은 types.luau).
-- 생성된 <Class>Param<E> 전량(개수는 dump/api-surface.json이 소스)의
-- 재익스포트 표면은 단위 ⑤의 `H-25`(quad-types
-- 갱신 몫) 확인 때 같이 정한다 — 지금 손으로 나열하면 "전량 생성" 계약과
-- 어긋난 채 유지보수 부채가 된다.
export type Tween<T> = Types.Tween<T>
export type NewChild = Types.NewChild

local function QuadRoblox<T>(quad: T): T
	-- virtual-field version check — referencing the field is what evaluates it
	local checked: QuadTypes.CheckedQuad<T, "0.0.0"> = quad :: any
	local _forceCheck = checked.__versionCheck
	-- surface tag so raises below blame the caller's line (`H-238`)
	;(quad :: any).errorNamespace.setFuncLevel(QuadRoblox, QuadTypes.ERROR_LEVEL_SURFACE)
	return RobloxFactory(quad :: any) :: any
end

return {
	QuadRoblox = QuadRoblox,
}
