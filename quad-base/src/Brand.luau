--!strict
--[[
	Brand — quad-base's brand INSTANCES and `isX` predicates.
	`.claude/base/brand-plan.md` "구현 — 인스턴스 브랜드" / "`isX` wrapper" sections,
	as-is.

	The factory `Brand()` itself lives in quad-types since 2026-09-07 (user
	decision — a nominal-typing helper with no other behaviour, like an enum;
	`QuadTypes.Brand`): every package makes its own instances from it, so a
	backend (quad-roblox's `TweenBrand`, a future quad-spring's `SpringBrand`)
	needs no quad-base to brand its values. Semantics unchanged: one weak-key
	member set per brand, a value registers itself into the brand(s) it
	belongs to (multi-tagging is the point — `Source` is both `SourceBrand`
	and `EpochBrand`; Observer/Effect are also `BindableBrand`), no reverse lookup (`Brand.get(x) -> tag` was reversed,
	see `archive/brand-shared-registry-reversed.md`).

	Every quad-base brand instance lives in this leaf file (M2 first-unit plan,
	`archive/v2-initial-implementation/m2-implementation-round11-brief.md` §6): `EpochBrand`
	is shared by `Source`/`Ref` (NOT `GateNode` — a GateNode is a State, no
	`Revision`; registering it here would make `EpochMap:Update` never fire —
	`State.luau` header; 5순회 correction), so keeping the instances per type
	module would force a circular require. Each *type* still registers only
	into its own brand at its own construction sites; subtype relations are
	expressed once, in the predicate (`isState`/`isRef` below), never by
	double registration.

	Method names are PascalCase (`:Register`/`:Is`) — renamed from lowercase
	on 2026-09-15 (user decision): once the factory moved to quad-types it became
	a public surface for third-party backends, so the old "base-internal utility"
	reason for lowercase no longer held (`brand-plan.md`).

	`Brand` depends on nothing. In particular there is no `None` special
	case here — `isNone` is `v == None` and lives with `None.luau` (M3).
]]

local QuadTypes = require("../luau_packages/quad_types")

export type Brand = QuadTypes.Brand
local Brand = QuadTypes.Brand

-- Each type owns exactly one brand. The full quad-base list is declared here
-- so that the set of base brands has one source; their `is*` predicates are
-- added with the type. Backend value types brand themselves in their own
-- package (`Tween` → quad-roblox `Brand.luau`, 2026-09-07).
-- Diagnostics name a value by the predicates REGISTERED in the module instance's `BrandPredicates`
-- (`init.luau` registers the public base `is*` fields — 2026-10-01), not by this list.
local ObserverBrand = Brand()
local EffectBrand = Brand()
local TagBrand = Brand()
local AttrBrand = Brand()
local BlockerBrand = Brand()
local ContextBrand = Brand() -- 2026-09-08 `Context`/`Provider` (base/context-plan)
local ProviderBrand = Brand()
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
-- M10 (round16): the attribute single-key objects get their own brand — the
-- group brand (AttrBrand) marks the array-part group VALUE, while this
-- one marks the hash-part KEY objects (`AttrKey "name"` and the group's
-- private per-name keys — both must reach the same AttrKeyFallbackHandler)
local AttrKeyBrand = Brand()
-- [2026-10-01 user decision — internal only, NOT on `q.`] the lifetime-hook capability brand.
-- `bindLifetime`/`unbindLifetime` (`LifetimeHandle.luau`) know no value TYPE: a member of this brand
-- may carry the private hooks `_assertBindable` / `_afterBind(inst)` / `_beforeUnbind()` (each
-- optional — nil = skipped) and MUST carry the boolean `Subscribed` (the global-path arm of the
-- liveness predicate, `H-111`). A capability brand like `EpochBrand`: Observer and Effect each
-- register into it next to their own brand at construction (`research/bindable-hooks-plan.md`).
-- A public registration surface is backlog (same document) — until then only quad-base types join.
local BindableBrand = Brand()
-- [2026-10-06 user decision, round14 Q161·Q182] the first PUBLIC capability (protocol) brand —
-- exposed as `q.Protocols.DispatchHint`. Dispatch-match-failure diagnosis: when a member value sits at a
-- key no handler matches (`Quad0076`), Dispatch calls its `__dispatchHint(key) -> string?` once and uses
-- the returned sentence as the cause (nil → the generic tail); the error position does not change; a
-- throwing hook is undefined (not wrapped). `__` = a public protocol hook quad calls (a contract), `_` =
-- private. A capability brand like `EpochBrand`/`BindableBrand`, so it lives here — one per quad-base
-- copy, the same object on every module instance's `Protocols` table: the base members (Store, Context,
-- Provider, Blocker, AttrKey) are made by copy-level constructors that know no module instance.
local DispatchHintBrand = Brand()

-- Plain identity predicates.
local function isEpoch(x: any): boolean
	return EpochBrand:Is(x)
end
local function isSource(x: any): boolean
	return SourceBrand:Is(x)
end
local function isStore(x: any): boolean
	return StoreBrand:Is(x)
end
local function isObserver(x: any): boolean
	return ObserverBrand:Is(x)
end
local function isEffect(x: any): boolean
	return EffectBrand:Is(x)
end
local function isContext(x: any): boolean
	return ContextBrand:Is(x)
end
local function isProvider(x: any): boolean
	return ProviderBrand:Is(x)
end
local function isBlocker(x: any): boolean
	return BlockerBrand:Is(x)
end
local function isModifier(x: any): boolean
	return ModifierBrand:Is(x)
end
local function isMapperDescriptor(x: any): boolean
	return MapperBrand:Is(x)
end
local function isTag(x: any): boolean
	return TagBrand:Is(x)
end
local function isAttr(x: any): boolean
	return AttrBrand:Is(x)
end
local function isAttrKey(x: any): boolean
	return AttrKeyBrand:Is(x)
end
-- `H-403` (사용자 지시 2026-09-07): lived in 옛 `Slot.luau` (now `Slot/init.luau`) alone while every sibling
-- predicate lives here — moved so the set has one home (`slot-plan.md`: "`isSlot`은
-- `Brand`의"). `Slot/init.luau` re-exposes it on the module like before.
local function isSlot(x: any): boolean
	return SlotBrand:Is(x)
end
-- 3순회 `H-377`: the quad values that are frozen PLAIN tables — no metatable,
-- branded only here. Every `getmetatable(x) == nil` "plain table" gate
-- (Attr/Modifier/Tag/Store — grep `isPlainBranded` for the current set)
-- must exclude them by brand, so the list lives once (a shared pure predicate —
-- conventions "하나의 무언가가 두 일을 하고 있지 않은지 유의한다" allows exactly that).
local function isPlainBranded(x: any): boolean
	return isAttrKey(x) or isMapperDescriptor(x)
end

-- Subtype relations: the more specific predicate is defined first and the
-- wider one is composed on top of it, so the direction of inclusion is
-- visible in the code (`brand-plan.md`).
local function isState(x: any): boolean
	return isSource(x) or StateBrand:Is(x) -- Source structurally satisfies State
end

local function isPreRef(x: any): boolean
	return PreRefBrand:Is(x)
end
local function isPostRef(x: any): boolean
	return PostRefBrand:Is(x)
end
local function isRef(x: any): boolean
	-- PreRef/PostRef reuse the Ref runtime = both are a kind of Ref.
	-- They are exclusive siblings of each other.
	return isPreRef(x) or isPostRef(x) or RefBrand:Is(x)
end

return {
	Brand = Brand,
	MapperBrand = MapperBrand,
	isMapperDescriptor = isMapperDescriptor,

	ObserverBrand = ObserverBrand,
	EffectBrand = EffectBrand,
	TagBrand = TagBrand,
	AttrBrand = AttrBrand,
	BlockerBrand = BlockerBrand,
	ContextBrand = ContextBrand,
	ProviderBrand = ProviderBrand,
	StateBrand = StateBrand,
	SourceBrand = SourceBrand,
	StoreBrand = StoreBrand,
	SlotBrand = SlotBrand,
	RefBrand = RefBrand,
	PreRefBrand = PreRefBrand,
	PostRefBrand = PostRefBrand,
	ModifierBrand = ModifierBrand,
	EpochBrand = EpochBrand,
	AttrKeyBrand = AttrKeyBrand,
	BindableBrand = BindableBrand, -- internal (no `is*` predicate, not re-exported on `q.`)
	DispatchHintBrand = DispatchHintBrand, -- public as `q.Protocols.DispatchHint` (no `is*` predicate)

	isEpoch = isEpoch,
	isSource = isSource,
	isState = isState,
	isStore = isStore,
	isObserver = isObserver,
	isEffect = isEffect,
	isBlocker = isBlocker,
	isContext = isContext,
	isProvider = isProvider,
	isModifier = isModifier,
	isRef = isRef,
	isPreRef = isPreRef,
	isPostRef = isPostRef,
	isTag = isTag,
	isAttr = isAttr,
	isAttrKey = isAttrKey,
	isSlot = isSlot,
	isPlainBranded = isPlainBranded,
}
