--[[
	PreRef — a `Ref` with a construction-time fire contract (M8 단위 ①; canon
	`.claude/base/ref-plan.md` "`phase` 옵션 폐기 → 위치로 표현, `PreRef` 신설" 절). SAME runtime as `Ref` (`.Value`/
	`:Set`/`:Callback`/`:Wait` …), plus:
	  - the `PreRefBrand` brand on top of `RefBrand`/`EpochBrand` (multi-tagging —
	    `isRef` is true for all three kinds, `isPreRef` only for this one,
	    `brand-plan.md`), and the H-300 marker `__quadPreRef` for the
	    nominal type `QuadTypes.PreRef<T>`;
	  - `_fired = false` — the one-shot guard the dispatch pre-pass (unit ②)
	    flips when it consumes the slot; a fired PreRef placed again errors
	    there (stale `.Value` would silently re-fire callbacks — canon
	    "PreRef는 '취소'라는 개념이 없다").
	Timing: fires BEFORE anything else happens to the instance — the pre-pass
	hoists every PreRef regardless of its array position (relative order among
	PreRefs = array index order).
	Children-array literal item ONLY — Modifier fields / Source / Store values
	are rejected by the types and by the FALLBACK guard handler (unit ②).
]]

local Brand = require("../Brand")
local QuadTypes = require("../../luau_packages/quad_types")
local Err = require("../ErrorNamespace")
local tagged = require("../Ref")._tagged
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

export type PreRef<T> = QuadTypes.PreRef<T>

local function PreRef<T>(default: T): PreRef<T>
	return tagged(default, Brand.PreRefBrand, "__quadPreRef") :: PreRef<T>
end

Err.setFuncLevel(SURFACE, PreRef) -- `H-231`

return PreRef
