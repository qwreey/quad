--!strict
--[[
	PostRef — a `Ref` with a construction-time fire contract (M8 단위 ①; canon
	`.claude/base/ref-plan.md` "`PostRef`" 절). SAME runtime as `Ref` (`.Value`/
	`:Set`/`:Callback`/`:Wait` …), plus:
	  - the `PostRefBrand` brand on top of `RefBrand`/`EpochBrand` (multi-tagging —
	    `isRef` is true for all three kinds, `isPostRef` only for this one,
	    `brand-plan.md`), and the H-300 marker `__quadPostRef` for the
	    nominal type `QuadTypes.PostRef<T>`;
	  - `_fired = false` — the one-shot guard the dispatch pre-pass (unit ②)
	    flips when it consumes the slot; a fired PostRef placed again errors
	    there (stale `.Value` would silently re-fire callbacks — canon
	    "PreRef는 '취소'라는 개념이 없다").
	Timing: fires AFTER this instance's array part (children, subtrees) and hash
	part (properties, events) are all done. Parent attachment is NOT part of
	the contract either way (M8 brief §0 Q6, user) — only "all children are
	attached".
	Children-array literal item ONLY — Modifier fields / Source / Store values
	are rejected by the types and by the FALLBACK guard handler (unit ②).
]]

local Brand = require("../Brand")
local QuadTypes = require("../../luau_packages/quad_types")
local Err = require("../ErrorNamespace")
local tagged = require("../Ref")._tagged
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

export type PostRef<T> = QuadTypes.PostRef<T>

local function PostRef<T>(default: T): PostRef<T>
	return tagged(default, Brand.PostRefBrand, "__quadPostRef") :: PostRef<T>
end

Err.setFuncLevel(SURFACE, PostRef) -- `H-231`

return PostRef
