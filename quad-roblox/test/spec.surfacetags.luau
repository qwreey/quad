--!strict
--[[
	quad-roblox's half of the public-surface tagging check (round15 `H-905`; the walker and the base half:
	`quad-base/test/spec.surfacetags.luau`). The module after `UseProvider(QuadRoblox)` — the class-first
	surface, `q.Raw.*`, `Tween`/`Animate` — and a Tween value's methods all carry the SURFACE tag. The exempt
	list is the base one: nothing quad-roblox adds is exempt.
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
-- mock에선 quad를 만들지 않는 헬퍼만 빌린다(사본 혼입 주의 — spec.robloxfactory 헤더)
local mock = require("../../quad-base/test/mock")
local q: any = Quad.NewModule():UseProvider(QuadRoblox)

local exempt: { [string]: boolean } = {
	["q.Relate"] = true,
	["q.Void"] = true,
	["q.NewModule"] = true,
	["q.BrandPredicates.Is"] = true,
	["q.BrandPredicates.Register"] = true,
	["q.Protocols.DispatchHint.Is"] = true,
	["q.Protocols.DispatchHint.Register"] = true,
	["q.errorNamespace"] = true,
	["q.Backend"] = true,
}
for k in next, q do
	if type(k) == "string" and string.sub(k, 1, 2) == "is" then
		exempt["q." .. k] = true
	end
end

print("=== 1. 프로바이더 설치 뒤 모듈 표면과 Tween 메소드가 전부 SURFACE 태그 ===")
do
	local untagged = mock.untaggedSurface(q, { Tween = q.Tween({ Value = 1 }) }, exempt)
	assert(#untagged == 0, "untagged public functions (add them to their setFuncLevel call): " .. table.concat(untagged, ", "))
	print("PASS")
end
