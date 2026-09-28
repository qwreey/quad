--!strict
--[[
	Brand — quad-roblox's brand instances and predicates (2026-09-07, user
	decision: the factory `Brand()` lives in quad-types so each package brands
	its own value types without quad-base — `base/brand-plan.md`; quad-base's
	`Brand.luau` is the same shape for the base types).

	`TweenBrand`/`isTween` came here with `Tween.luau` (tween-plan "패키지
	경계" — the option vocabulary is Roblox's, so the value type is a backend
	value). `isTween` is also installed on the module instance (Tween.luau's
	install) — the `is<Brand>` module field is the provider-brand contract
	(round3 §4 Q27, 2026-09-08), and [2026-09-28 round13 Q106] the predicate is
	registered in `QuadTypes.BrandPredicates` (below): quad-base's diagnostic scans
	the module's `is*` fields and trusts only registered ones (no Dispatch op).
]]

local QuadTypes = require("../luau_packages/quad_types")

local TweenBrand = QuadTypes.Brand()

local function isTween(x: any): boolean
	return TweenBrand:Is(x)
end
-- round13 Q106 (user decision 2026-09-28): a provider's brand predicate registers itself so quad-base's
-- diagnostic scan of `is<Brand>` module fields recognizes it (unregistered `is*` helpers are ignored)
QuadTypes.BrandPredicates:Register(isTween)

return {
	TweenBrand = TweenBrand,
	isTween = isTween,
}
