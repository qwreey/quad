--[[
	Modifier — the immutable, clone-chained property bag (M7 단위 ①). Canon:
	`.claude/base/modifier-plan.md` 3·4·4-1·8·9·2-1절, as-is; Luau mechanics
	measured by `luau-test/done/17` (generic `__index` + `table.clone`,
	private `FieldsKey` store, sibling branches never cross-contaminate).

	  Modifier(...) -> mod                    -- [H-310, 사용자 확정 2026-09-04]
	                                          --   each arg: a Modifier or a plain
	                                          --   { field = value } table; later
	                                          --   args override field-wise
	                                          --   (Overridden semantics); no args
	                                          --   = empty (Modifier() == Modifier({}))
	  mod:AnyField(value) -> mod'             -- literal: clone + overwrite
	  mod:AnyField(function(old) … end)       -- transform: plain → old raw;
	                                          --   State → old:Compute(fn) (4-1)
	  mod:AnyField(nil)                       -- field ABSENT in mod' (2-1 M-5)
	  mod:AnyField(None)                      -- field = None (the only unsetter)
	  mod:Peek(key) -> FieldOut<T>?                -- raw, never :Get() (quad-types: T | State<T> | None | nil — T is the
	                                          --   field's whole value algebra; quad-roblox puts X | Tween<X> there)
	  mod:Apply(factory) -> factory(mod)      -- pure call sugar, no contract
	  Modifier.Overridden(a, b, …) / a:Overridden(b, …)
	                                          -- field-wise, later wins, no
	                                          --   State/function branching
	                                          --   (values are already baked)

	Class tags + casts (M7 단위 ④, 2026-09-04 — modifier-plan 11절, user design;
	one job per function — user rule):
	  Modifier.TypedFactory(name) -> ctor     -- name a modifier CLASS (any engine
	                                          --   class, component, or virtual
	                                          --   object — base owns the registry,
	                                          --   the provider is just its first
	                                          --   client) and get its tagged
	                                          --   constructor (same shape as
	                                          --   Modifier(...), tag = name). Knows
	                                          --   nothing about relations. Dedup:
	                                          --   same name → same ctor
	  Modifier.DefineSubtype(parent, subtype) -- register ONE edge subtype ⊂ parent
	                                          --   (both names become known). A
	                                          --   subtype may get several parents
	                                          --   (interfaces / multiple parents —
	                                          --   fields are just present-or-absent,
	                                          --   so nothing can conflict). Dedup:
	                                          --   same edge → no-op. Only a cycle
	                                          --   is refused
	  mod:As<Name>() -> mod'                  -- CHECKED downcast: Name must be
	                                          --   known and mod's tag must be
	                                          --   untyped (true), Name itself, or
	                                          --   an ancestor of Name (union over
	                                          --   every parent path); else error
	  mod:As() / mod:As(name) -> mod'         -- UNCHECKED: no arg = self as-is
	                                          --   (type-only cast); name = retag
	                                          --   with existence check only
	Every `As%u` key is reserved for casts — it can never become a field setter
	(a typo `AsTextLabl` errors instead of silently minting a field). Tags live
	in the `__quadModifier` literal (H-300 marker): `true` for untyped, the
	class name for tagged values — the generated per-class types declare the
	same literal, so the tag the type promises IS the tag the value carries.

	Runtime is ONE generic `__index` (no per-class code): reserved methods
	(`Apply`/`Peek`/`Overridden`/`As`) → cast prefix → any other key yields a
	setter closure. Field values live in a private table under the `FieldsKey`
	identity — NEVER as literal keys of self (a stored raw value would shadow
	`__index` on the next `mod:X(fn)` call and blow up with "attempt to call a
	number value" — the canon ⚠️ block). Every setter clones BOTH the outer
	table and the fields table (shallow `table.clone`).

	Handler-layer values (Ref/PreRef/PostRef/Observer/Effect/Slot/Modifier)
	reaching a field — literal or returned by a transform — raise immediately
	(4절 정정, 2026-08-09). State/Source pass (4-1). `State<Ref>`-style inner
	contents are documented UB, not inspected. The mirror guard (a Modifier as
	a State/Source VALUE) lives in Source.luau/State.luau since M2 (7절).

	flatten (단위 ②, "flatten의 정확한 형태" 절 as-is; `H-312`: a Modifier at a
	hash key is rejected first): in-place, reverse
	`for` over the array part (later modifier wins because "already set →
	skip" is first-writer-wins), inline hash keys — including inline `None` —
	always win, each consumed slot becomes the `ProcessedModifier` sentinel
	(no holes → array order kept). `Dispatch.drive` owns the call as its
	first pre-pass (round17 §0 Q4 (a)) — `New` ③ and `Claim` both get it
	through drive. `ProcessedModifierHandler` (Dispatch/Modifier/Handler.luau)
	catches the sentinel and registers None/0 bookkeeping. flatten never
	looks at tags — a tag only ever gates `As<Name>()`.
]]

local Brand = require("../Brand")
local QuadTypes = require("../../luau_packages/quad_types")
local Err = require("../ErrorNamespace")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local ModifierBrand = Brand.ModifierBrand
local isModifier = Brand.isModifier
local isState = Brand.isState
local isRef = Brand.isRef -- covers PreRef/PostRef (Brand.luau predicate)
local isObserver = Brand.isObserver
local isEffect = Brand.isEffect
local isPlainBranded = Brand.isPlainBranded -- `H-377`: AttrKey/MapperDescriptor carry no metatable

-- private field store key — a unique table identity, can never collide with a
-- user field name (spike 17 / spike 11 idiom)
local FieldsKey = table.freeze({})

local function isHandlerLayerValue(v: any): boolean
	return isRef(v) or isObserver(v) or isEffect(v) or Brand.isSlot(v) or isModifier(v)
end

local ModifierMT = {}
-- `__tostring` (2026-09-08, advisory 권고 1): class tag + field count. `rawget` — ModifierMT.__index
-- is the setter/gate metamethod, and a print must not go through it.
function ModifierMT.__tostring(self: any): string
	local tag = rawget(self, "__quadModifier")
	local n = 0
	for _ in rawget(self, FieldsKey) do
		n += 1
	end
	return `Modifier{if tag == true then "" else `<{tostring(tag)}>`}({n} fields)`
end

-- `tag`: `true` (untyped) or a Defined class name. Fields may arrive already
-- frozen (retag path) — `table.freeze` raises on a frozen table.
local function newModifier(fields: { [any]: any }, tag: any): any
	if not table.isfrozen(fields) then
		table.freeze(fields)
	end
	-- `__quadModifier`: type MARKER (H-300 idiom) — the backend children union
	-- admits a class-tagged marker `{ read __quadModifier: "<Class>" | … }` per
	-- class (unit ④; the recursive per-class table types themselves blow the
	-- solver — unit ③). A literal key, so it never reaches `__index`.
	local mod = setmetatable({ [FieldsKey] = fields, __quadModifier = tag }, ModifierMT)
	ModifierBrand:register(mod)
	return table.freeze(mod)
end

-- ── class registry (TypedFactory / DefineSubtype / As) ─────────────────────
-- known names + parent SETS (a subtype may have several parents). Module-level
-- like Brand/None: two coexisting quad-base copies get separate registries
-- (documented copy-split).
local known: { [string]: true } = {}
local parents: { [string]: { [string]: true } } = {}
local constructors: { [string]: any } = {}

-- is `ancestor` reachable from `name` upward (or equal)? Union over every
-- parent path; `seen` guards the walk (cycles are refused at registration,
-- but a bounded walk costs nothing).
local function isAncestorOrSelf(ancestor: string, name: string): boolean
	if ancestor == name then
		return true
	end
	local seen: { [string]: true } = {}
	local stack = { name }
	while #stack > 0 do
		local node = table.remove(stack) :: string
		for parent in parents[node] or {} do
			if parent == ancestor then
				return true
			end
			if not seen[parent] then
				seen[parent] = true
				table.insert(stack, parent)
			end
		end
	end
	return false
end

local function retag(mod: any, tag: any): any
	return newModifier(mod[FieldsKey], tag)
end

-- reserved methods (checked before the cast prefix and the generic setter —
-- 8절 "구현 시 주의")
local methods = {}

function methods.Peek(self: any, key: any): any
	if type(key) ~= "string" or key == "" then
		-- `H-469` (Gemini 5차 G-21, 사용자 Q32): the setter path refuses these keys (`H-448`) —
		-- Peek used to answer nil for them as if the field were absent
		Err.errorBeforeNearest(`Modifier:Peek: key must be a non-empty string (got {if key == "" then '""' else typeof(key)})`, SURFACE)
	end
	return self[FieldsKey][key] -- raw: State handle stays a handle, None stays None
end

function methods.Apply(self: any, factory: (any) -> any): any
	return factory(self) -- nothing more, nothing less (8절)
end

-- mod:As() — unchecked cast (11절): the "go somewhere D does not know" path.
-- No name: the value itself (a type-level cast only, tag untouched — nothing
-- to retag to). A name: retag after an EXISTENCE check (typo guard), no
-- ancestry check — that is what the checked `As<Name>()` is for.
function methods.As(self: any, name: any): any
	if name == nil then
		return self
	end
	if type(name) ~= "string" then
		Err.errorBeforeNearest(`Modifier:As: name must be a class name string (got {typeof(name)})`, SURFACE)
	end
	if not known[name] then
		Err.errorBeforeNearest(`Modifier: unknown modifier class "{name}" — Modifier.TypedFactory/DefineSubtype it first`, SURFACE)
	end
	return retag(self, name)
end

-- Modifier.Overridden(a, b, ...) — later argument wins field by field. Colon
-- form `a:Overridden(b)` is the same function (self becomes the first arg).
-- The result is untyped (tag `true`): the inputs may carry different tags and
-- the merge does not pick one — retag with `As<Name>()` if a class is wanted.
local function Overridden(...: any): any
	local n = select("#", ...)
	if n == 0 then
		Err.errorBeforeNearest("Modifier.Overridden: expects at least one Modifier", SURFACE)
	end
	local merged: { [any]: any } = {}
	for i = 1, n do
		local arg = select(i, ...)
		if not isModifier(arg) then
			Err.errorBeforeNearest(`Modifier.Overridden: argument #{i} is not a Modifier (got {typeof(arg)})`, SURFACE)
		end
		for k, v in arg[FieldsKey] do
			merged[k] = v -- baked values only — no State/function branching (9절)
		end
	end
	return newModifier(merged, true)
end
methods.Overridden = Overridden

-- checked downcast — `mod:As<Name>()`. Unlike the setters (fresh closure per
-- `__index`, `H-250`), cast closures are CACHED per target name and tagged
-- SURFACE, so the error contract is the stack worker (`errorBeforeNearest` —
-- the destination, not a hand-counted level, `H-231`; review finding). The
-- cache is bounded by the distinct `As<Name>` keys the code base spells.
local castClosures: { [string]: (any) -> any } = {}

local function castClosure(target: string): (any) -> any
	local cached = castClosures[target]
	if cached ~= nil then
		return cached
	end
	local closure = function(selfArg: any): any
		if not known[target] then
			Err.errorBeforeNearest(`Modifier: unknown modifier class "{target}" — Modifier.TypedFactory/DefineSubtype it first (or use :As(name) for an unchecked cast)`, SURFACE)
		end
		local tag = selfArg.__quadModifier
		if tag ~= true and tag ~= target and not isAncestorOrSelf(tag, target) then
			Err.errorBeforeNearest(`Modifier: cannot cast a "{tag}" modifier to "{target}" — not an ancestor (use :As(name) to force)`, SURFACE)
		end
		return retag(selfArg, target)
	end
	Err.setFuncLevel(SURFACE, closure)
	castClosures[target] = closure
	return closure
end

-- generic setter synthesis — the whole per-field runtime (4절)
function ModifierMT.__index(_self: any, key: any): any
	local method = methods[key]
	if method ~= nil then
		return method
	end
	if type(key) == "string" and string.match(key, "^As%u") ~= nil then
		-- reserved cast prefix (11절): `As` + UpperCamel is never a field.
		-- `AspectRatio`-style names (lowercase after `As`) stay setters; the
		-- generator refuses to emit a property that matches the prefix.
		return castClosure(string.sub(key, 3))
	end
	if type(key) ~= "string" then
		-- Q11 (a) (사용자 결정 2026-09-07): the generic setter mirrors `construct`'s key rule
		-- (`H-310` — the two creation paths must not drift): only string keys become setters;
		-- `construct` in turn refuses the keys this path can never make into setters (`H-448`).
		-- Non-string keys (AttrKey/MapperDescriptor) go in the props table directly.
		Err.errorBeforeNearest("Modifier: setter keys must be strings (got " .. typeof(key) .. ") — put a non-string key in the props table itself (Frame { [key] = value })", SURFACE)
	end
	return function(selfArg: any, arg: any): any
		local oldFields = selfArg[FieldsKey]
		local old = oldFields[key]
		local value: any
		if type(arg) == "function" then
			local transform = arg :: (any) -> any
			if isState(old) then
				value = old:Compute(transform) -- 4-1: derived State, reactivity kept
			else
				value = transform(old) -- plain: current raw value, called now
			end
		else
			value = arg -- literal (a State literal replaces the whole field; nil = absent)
		end
		if isHandlerLayerValue(value) then
			-- level 2 = the user's `mod:Field(...)` line (the closure is not
			-- table-reached, so no tag — `H-250`)
			error(`Modifier: field "{tostring(key)}" cannot hold a handler-layer value (Ref/Observer/Effect/Slot/Modifier)`, 2)
		end
		local newFields = table.clone(oldFields)
		newFields[key] = value
		return newModifier(newFields, selfArg.__quadModifier) -- setters keep the tag
	end
end

-- Modifier(a, b, ...) — `H-310` (사용자 확정: the SHAPE — each argument is a
-- Modifier or a plain `{ field = value }` table, fields merge in order, later
-- wins like Overridden, `Modifier()` == `Modifier({})`). The validation
-- rules below are AGENT additions (round17 `H-310` row, vetoable):
--   - a "field table" is a metatable-less plain table — any other quad
--     object (Source/State/Ref/None …) is rejected instead of having its
--     internals merged as fields (review finding); 3순회 `H-377`: brands are
--     not metatables, so the plain-branded values (AttrKey — its `Name`
--     merged as a field and silently RENAMED the instance; MapperDescriptor)
--     are excluded by `Brand.isPlainBranded` (shared with Attr/Tag);
--   - keys must be field names (strings);
--   - values take the setter's handler-layer check, and a FUNCTION value is
--     rejected: the setter reads a function as a transform (4절), and
--     storing it raw here would make the two construction paths diverge
--     silently — use `mod:Field(fn)` for transforms.
local function isPlainFieldTable(arg: any): boolean
	-- 4순회 `H-390`: `not isState / not isHandlerLayerValue` were dead after the
	-- metatable check (every one of those values carries a metatable) — the same
	-- shape as Attr's gate now
	return type(arg) == "table" and getmetatable(arg) == nil and not isPlainBranded(arg)
end

-- shared by `Modifier(...)` (tag true) and every TypedFactory constructor (tag =
-- class name) — one merge body, the tag is the only difference
local function construct(tag: any, ...: any): any
	local merged: { [any]: any } = {}
	for i = 1, select("#", ...) do
		local arg = select(i, ...)
		if isModifier(arg) then
			for k, v in arg[FieldsKey] do
				merged[k] = v
			end
		elseif isPlainFieldTable(arg) then
			for k, v in arg :: { [any]: any } do
				if type(k) ~= "string" or k == "" then
					Err.errorBeforeNearest(`Modifier: initial-field table keys must be non-empty field names (got {if k == "" then '""' else typeof(k)} at argument #{i})`, SURFACE)
				end
				-- round3 `H-448`: the same keys the setter path can never produce — a cast-prefix
				-- name (`AsTextLabl` — the header's typo case) or a reserved method name would land
				-- as a field here and be unreachable through `mod:X(...)`
				if methods[k] ~= nil then
					Err.errorBeforeNearest(`Modifier: field "{k}" collides with a reserved Modifier method`, SURFACE)
				end
				if string.match(k, "^As%u") ~= nil then
					Err.errorBeforeNearest(`Modifier: field "{k}" matches the reserved cast prefix As<Class> — casts are methods, not fields`, SURFACE)
				end
				if type(v) == "function" then
					Err.errorBeforeNearest(`Modifier: field "{k}" in an initial-field table cannot be a function — use mod:{k}(fn) for a transform`, SURFACE)
				end
				if isHandlerLayerValue(v) then
					Err.errorBeforeNearest(`Modifier: field "{k}" cannot hold a handler-layer value (Ref/Observer/Effect/Slot/Modifier)`, SURFACE)
				end
				merged[k] = v
			end
		else
			Err.errorBeforeNearest(`Modifier: argument #{i} must be a Modifier or a plain field table (got {typeof(arg)})`, SURFACE)
		end
	end
	return newModifier(merged, tag)
end

local function checkName(fn: string, what: string, name: any)
	if type(name) ~= "string" or name == "" then
		Err.errorBeforeNearest(`Modifier.{fn}: {what} must be a non-empty class name string (got {typeof(name)})`, SURFACE)
	end
end

-- Modifier.TypedFactory(name) -> ctor (11절, user design 2026-09-04): ONE job —
-- make `name` known and return its tagged constructor. A PUBLIC base API: the
-- provider registers its engine classes through it at UseProvider and
-- component authors register theirs the same way (a `MaterialButtonModifier`
-- with custom fields is as first-class as `FrameModifier`). Dedup: the same
-- name always returns the same constructor (two modules may both ask).
local function TypedFactory(name: any): any
	checkName("TypedFactory", "name", name)
	local existing = constructors[name]
	if existing ~= nil then
		return existing
	end
	known[name] = true
	local ctor = function(...: any): any
		return construct(name, ...)
	end
	Err.setFuncLevel(SURFACE, ctor) -- `H-238`: the user's `D.Modifier.Frame(...)` line is blamed
	constructors[name] = ctor
	return ctor
end

-- Modifier.DefineSubtype(parent, subtype) (11절): ONE job — register the edge
-- `subtype ⊂ parent`. Both names become known (so order of registration is
-- free), a subtype may collect several parents (interfaces / multiple
-- inheritance — modifier fields are present-or-absent, nothing conflicts),
-- the same edge twice is a no-op, and only a cycle is refused.
local function DefineSubtype(parent: any, subtype: any)
	checkName("DefineSubtype", "parent", parent)
	checkName("DefineSubtype", "subtype", subtype)
	if parent == subtype or isAncestorOrSelf(subtype, parent) then
		Err.errorBeforeNearest(`Modifier.DefineSubtype: "{subtype}" ⊂ "{parent}" would make a cycle`, SURFACE)
	end
	known[parent] = true
	known[subtype] = true
	local set = parents[subtype]
	if set == nil then
		set = {}
		parents[subtype] = set
	end
	set[parent] = true
end

local Modifier = setmetatable({ Overridden = Overridden, TypedFactory = TypedFactory, DefineSubtype = DefineSubtype }, {
	__call = function(_self: any, ...: any): any
		return construct(true, ...)
	end,
})
table.freeze(Modifier)

-- `H-238`: public surface tagged (Overridden is reached both as
-- Modifier.Overridden and as the colon method — same function object)
Err.setFuncLevel(
	SURFACE,
	getmetatable(Modifier).__call,
	Overridden,
	TypedFactory,
	DefineSubtype,
	methods.As,
	methods.Apply, -- 6순회 `H-410`: list drift — every public method
	methods.Peek,
	ModifierMT.__index -- Q11: the non-string-key error is raised from the metamethod itself
)

-- internal sentinel that fills a consumed array slot (never user-facing —
-- `Processed*` idiom, same frozen+named shape as `None`)
local ProcessedModifier = require("./None").sentinel("ProcessedModifier")

-- flatten(input) -> input — canon pseudocode 1:1 (modifier-plan "flatten의
-- 정확한 형태"). Mutates and returns the same table.
local function flatten(input: { [any]: any }): { [any]: any }
	-- `H-312` (사용자 확정 2026-09-04): a Modifier at a HASH key is a misuse —
	-- there is nothing to merge it into, and letting it through hands the
	-- key's handler a raw table (engine error blamed inside quad). Reject
	-- here, before any slot is consumed. errorBefore: flatten runs inside
	-- the tagged `drive`, so the OUTERMOST tagged frame's caller (the
	-- user's `D.Frame{}` / `drive` line) is charged (`H-272` reasoning).
	-- Walk the HASH part only (review: a full pass would visit the array part
	-- twice on every drive): `next` continued from the last array key skips
	-- the hole-free array part; sparse numeric keys live in the hash part and
	-- are caught too (a Modifier at `[5]` beyond `#input` is not consumed).
	local n = #input
	local k: any = if n > 0 then n else nil
	while true do
		local v: any
		k, v = next(input, k)
		if k == nil then
			break
		end
		if isModifier(v) then
			Err.errorBefore(`Modifier: a Modifier cannot be a value of key "{tostring(k)}" — place it in the array part`, SURFACE)
		end
	end
	for i = n, 1, -1 do -- ⚠️ reverse: the LAST modifier must write first
		local value = input[i]
		if not isModifier(value) then
			continue
		end
		input[i] = ProcessedModifier -- consume the slot, keep the array hole-free
		for key, modValue in value[FieldsKey] do
			if input[key] ~= nil then
				-- already taken — an inline key (present before this loop, `None`
				-- included) or a later modifier (visited earlier) wins
				continue
			end
			input[key] = modValue
		end
	end
	return input
end

return {
	Modifier = Modifier,
	flatten = flatten,
	ProcessedModifier = ProcessedModifier,
	_FieldsKey = FieldsKey, -- specs only (private)
}
