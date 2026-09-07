--[[
	Brand — quad-roblox's brand instances and predicates (2026-09-07, user
	decision: the factory `Brand()` lives in quad-types so each package brands
	its own value types without quad-base — `base/brand-plan.md`; quad-base's
	`Brand.luau` is the same shape for the base types).

	`TweenBrand`/`isTween` came here with `Tween.luau` (tween-plan "패키지
	경계" — the option vocabulary is Roblox's, so the value type is a backend
	value). `isTween` is also installed on the module instance (Tween.luau's
	install) — the `is<Brand>` module field IS the provider-brand contract
	(round3 §4 Q27, 2026-09-08): quad-base's match-failure diagnostic scans the
	module for such fields, no registration op.
]]

local QuadTypes = require("../luau_packages/quad_types")

local TweenBrand = QuadTypes.Brand()

local function isTween(x: any): boolean
	return TweenBrand:is(x)
end

return {
	TweenBrand = TweenBrand,
	isTween = isTween,
}
