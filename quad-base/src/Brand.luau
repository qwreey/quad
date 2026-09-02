--[[
	Brand — instance brands, one weak-key set per brand.
	`.claude/base/brand-plan.md` "구현 — 인스턴스 브랜드" / "`isX` wrapper" sections,
	as-is.

	`Brand()` makes one brand object holding a weak-key member set; a value
	registers itself into the brand(s) it belongs to (multi-tagging is the
	point — `Source` is both `SourceBrand` and `EpochBrand`). There is no
	reverse lookup (`Brand.get(x) -> tag` was reversed, see
	`archive/brand-shared-registry-reversed.md`).

	Every brand instance lives in this leaf file (M2 first-unit plan,
	`qa-request/m2-implementation-round11-brief.md` §6): `EpochBrand`
	is shared by `Source`/`Ref`/`GateNode`, so keeping the instances per type
	module would force a circular require. Each *type* still registers only
	into its own brand at its own construction sites; subtype relations are
	expressed once, in the predicate (`isState`/`isRef` below), never by
	double registration.

	Method names are lowercase (`:register`/`:is`) on purpose — this is a
	base-internal utility, not a public quad surface (`brand-plan.md`).

	`Brand` depends on nothing. In particular there is no `None` special
	case here — `isNone` is `v == None` and lives with `None.luau` (M3).
]]

export type Brand = {
	register: (self: Brand, x: any) -> (),
	is: (self: Brand, x: any) -> boolean,
}

local function Brand(): Brand
	local members = setmetatable({}, { __mode = "k" }) :: { [any]: true }
	return {
		register = function(_self: Brand, x: any)
			members[x] = true
		end,
		is = function(_self: Brand, x: any): boolean
			return members[x] == true
		end,
	}
end

-- Each type owns exactly one brand. The full list is declared here even for
-- types that arrive in later milestones (`Tag`/`Attribute`/`Tween`/`Slot`)
-- so that the set of brands has one source; their `is*` predicates are added
-- with the type.
local ObserverBrand = Brand()
local EffectBrand = Brand()
local TagBrand = Brand()
local AttributeBrand = Brand()
local TweenBrand = Brand()
local BlockerBrand = Brand()
local StateBrand = Brand()
local SourceBrand = Brand()
local StoreBrand = Brand()
local SlotBrand = Brand()
local RefBrand = Brand()
local PreRefBrand = Brand()
local PostRefBrand = Brand()
local ModifierBrand = Brand()
local EpochBrand = Brand()
local MapperBrand = Brand() -- M5 단위 ④ — Claim의 MapperDescriptor(claim-plan §2)

-- Plain identity predicates.
local function isEpoch(x: any): boolean
	return EpochBrand:is(x)
end
local function isSource(x: any): boolean
	return SourceBrand:is(x)
end
local function isStore(x: any): boolean
	return StoreBrand:is(x)
end
local function isObserver(x: any): boolean
	return ObserverBrand:is(x)
end
local function isEffect(x: any): boolean
	return EffectBrand:is(x)
end
local function isBlocker(x: any): boolean
	return BlockerBrand:is(x)
end
local function isModifier(x: any): boolean
	return ModifierBrand:is(x)
end
local function isMapperDescriptor(x: any): boolean
	return MapperBrand:is(x)
end

-- Subtype relations: the more specific predicate is defined first and the
-- wider one is composed on top of it, so the direction of inclusion is
-- visible in the code (`brand-plan.md`).
local function isState(x: any): boolean
	return isSource(x) or StateBrand:is(x) -- Source structurally satisfies State
end

local function isPreRef(x: any): boolean
	return PreRefBrand:is(x)
end
local function isPostRef(x: any): boolean
	return PostRefBrand:is(x)
end
local function isRef(x: any): boolean
	-- PreRef/PostRef reuse the Ref runtime = both are a kind of Ref.
	-- They are exclusive siblings of each other.
	return isPreRef(x) or isPostRef(x) or RefBrand:is(x)
end

return {
	Brand = Brand,
	MapperBrand = MapperBrand,
	isMapperDescriptor = isMapperDescriptor,

	ObserverBrand = ObserverBrand,
	EffectBrand = EffectBrand,
	TagBrand = TagBrand,
	AttributeBrand = AttributeBrand,
	TweenBrand = TweenBrand,
	BlockerBrand = BlockerBrand,
	StateBrand = StateBrand,
	SourceBrand = SourceBrand,
	StoreBrand = StoreBrand,
	SlotBrand = SlotBrand,
	RefBrand = RefBrand,
	PreRefBrand = PreRefBrand,
	PostRefBrand = PostRefBrand,
	ModifierBrand = ModifierBrand,
	EpochBrand = EpochBrand,

	isEpoch = isEpoch,
	isSource = isSource,
	isState = isState,
	isStore = isStore,
	isObserver = isObserver,
	isEffect = isEffect,
	isBlocker = isBlocker,
	isModifier = isModifier,
	isRef = isRef,
	isPreRef = isPreRef,
	isPostRef = isPostRef,
}
