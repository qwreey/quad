--!strict
--[[
	Tag — array-part value object + its reference-counted handler (M10, spike
	round16). Canonical: `.claude/base/tag-plan.md` (value shape "값 모양",
	mechanism "메커니즘 — `TagHandler`", placement "패키지 배치"), as-is.

	Value API (immutable clone chaining — every operation returns a clone).
	`names` everywhere below is `string | Tag | { names }` — a name, another
	Tag (its whole set), or a plain list of those, nested to any depth
	(user decision 2026-09-07, `archive/surveys/2026-09-07-source-layout-plan.md` 3절 (b) —
	*"Tag() 로 초기 부터 잡는게 유리"*; this reverses `H-389`'s strings-only
	constructor and `H-380`'s "a Tag is not a list" rejection — the same
	`flattenInto` door now takes all three, like `Attr(store, attr,
	{ plain })` always did):
	  Tag(...names) -> tag                 -- vararg constructor; Tag() is valid
	  tag:Added(names) -> Tag              -- clone + add name(s)
	  tag:Removed(names) -> Tag
	  tag:Contains(...names) -> boolean     -- all present (vararg; nil is an error)
	  for name in tag do             -- generalized iteration (`__iter`, 2026-09-15; was tag:Names())
	  tag:Apply(factory) -> U              -- factory(self) sugar (Modifier pattern)
	  Tag.Merged(tag1, tag2, ...) -> Tag   -- lossless set union (Tags only — the
	                                          strict spelling of Tag(tag1, tag2, ...))

	Handler (registered by InitTag on each module instance — the `H-278` idiom:
	the module that declares the value owns its handler registration; the
	ROADMAP's older split into Dispatch/Tag.luau + Dispatch/TagFallback.luau
	predates `H-278`, recorded as `H10-1`): the entity actually registered is
	"TagFallbackHandler" at HANDLER_PRIORITY_FALLBACK, wrapping the reference
	count algorithm — addTag wholly in process, removeTag wholly in the
	retractor, per-name holder POSITION sets (`tagNameMap`), batched engine
	calls. Engine ops `addTag`/`removeTag` are backend-injected; quad-base
	installs loud error stubs so the guidance path works before any backend
	loads (tag-plan "패키지 배치" — 재역전 2026-08-18).
]]

local Brand = require("./Brand")
local Relate = require("./Relate")
local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")
local NotInstalled = require("./NotInstalled")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local TagBrand = Brand.TagBrand
local isTag = Brand.isTag

local TagImpl = {}
TagImpl.__index = TagImpl
-- `TagMarker` (quad-types) — the type promises the marker, so the value carries
-- it (`H-300`); read through `__index`, zero per-instance slots. Identity is
-- still the brand (`isTag`) — this field is the input-position type's evidence
-- (user decision 2026-09-07: Tag/Attr/Observer/Effect go marker
-- like State/Slot, typing-limits 8.11).
TagImpl.__quadTag = true
-- `__tostring` (2026-09-08, advisory 권고 1): the name set, sorted (it is a hash set)
function TagImpl.__tostring(self: any): string
	local names = {}
	for name in self._names do
		names[#names + 1] = `"{name}"`
	end
	table.sort(names)
	return `Tag({table.concat(names, ", ")})`
end

-- names are stored as a set ({[name]: true}) plus nothing else — order is
-- irrelevant to the union semantics and the engine batch call takes a list
local function newTag(names: { [string]: true }): any
	local self = setmetatable({ _names = table.freeze(names) }, TagImpl)
	TagBrand:Register(self)
	return table.freeze(self)
end

-- the one gate a name passes on its way into a set (7순회: the two empty-name
-- gates were copies; since the 3절 (b) union every door reaches it through `flattenInto`)
local function addName(target: { [string]: true }, name: string)
	if name == "" then -- `H-417` (외부 리뷰 G-01): an empty name reaches the engine op at dispatch depth
		Err.errorBeforeNearest("Quad0199 Tag: names must be strings — an empty string is not a tag name", SURFACE)
	end
	target[name] = true
end

-- One door for every name-bearing argument (3절 (b), user decision 2026-09-07):
-- a string, a Tag value (its whole name set — `Tag.Merged` is the Tags-only
-- spelling of the same union), or a plain array whose elements are again any
-- of the three (nested lists flatten). Everything else is a validation error
-- with the shape named — a hash key, a nil hole (`H-380`), a non-Tag metatable
-- table, a plain-branded quad value (`H-389`'s messages, minus the "a Tag is
-- not a list" rejection those two rounds added and this decision reverses).
-- The type side is `TagNames = string | { read [number]: TagNames } | TagMarker`
-- (quad-types; `read` indexer because a mutable `{T}` is invariant and would
-- reject a `{Tag | string}` literal — spike 2026-09-07). Hash tables slip past
-- the type (a table without an indexer satisfies an indexer type), so this
-- runtime gate is the one that names them.
local function flattenInto(target: { [string]: true }, v: any, depth: number)
	if type(v) == "string" then
		addName(target, v)
	elseif isTag(v) then
		for name in pairs((v :: any)._names :: { [string]: true }) do
			target[name] = true
		end
	elseif type(v) == "table" then
		if getmetatable(v) ~= nil or Brand.isPlainBranded(v) then
			Err.errorBeforeNearest( -- error-code: inline if
				if Brand.isPlainBranded(v)
					then "Quad0200 Tag: names must be strings, Tags, or a plain {...} list of those (got an AttrKey/Mapper descriptor)"
					else "Quad0237 Tag: names must be strings, Tags, or a plain {...} list of those (got a table with a metatable)",
				SURFACE
			)
		end
		-- [2026-09-16 hunt F] a list that contains itself recursed to a raw stack overflow with
		-- `Brand.luau` on the blame line; every other bad list shape here has a domain message
		-- depth travels as a parameter, not module state — a counter that only reset on error
		-- would drift upward across normal calls (hunt F 재검) and misfire on the 64th
		if depth > 64 then
			Err.errorBeforeNearest("Quad0201 Tag: names must be strings, Tags, or a plain {...} list of those — this list nests deeper than 64 levels (does it contain itself?)", SURFACE)
		end
		local count, maxIndex = 0, 0
		for k, item in pairs(v :: { [any]: any }) do
			if type(k) ~= "number" or k % 1 ~= 0 or k < 1 then
				Err.errorBeforeNearest("Quad0202 Tag: names must be strings, Tags, or a plain {...} list of those — a name list is an array, not a hash table", SURFACE)
			end
			count += 1
			if k > maxIndex then
				maxIndex = k
			end
			flattenInto(target, item, depth + 1)
		end
		if count ~= maxIndex then
			Err.errorBeforeNearest("Quad0203 Tag: names must be strings, Tags, or a plain {...} list of those — a name list cannot have nil holes", SURFACE)
		end
	else
		Err.errorBeforeNearest(`Quad0204 Tag: names must be strings, Tags, or a plain \{...} list of those (got {typeof(v)})`, SURFACE)
	end
end

-- [2026-09-21 사용자 결정 — GS 05장 `:Added` 관용구] A nil ARGUMENT means "nothing to add/remove" — for the
-- constructor's vararg slots, `Added`/`Removed`'s one argument and `Merged`'s slots. A nil HOLE inside a list
-- stays an error (`H-380`): a table cannot hold nil, so `{ cond and "a" or nil, "b" }` silently truncates,
-- while an argument's presence is exact (`select("#")`). This is what makes the immutable idiom
-- `tag:Added(if cond then "Even" else nil)` an EXPRESSION that must be assigned — the alternative, a
-- statement `if cond then tag:Added("Even") end`, drops the returned Tag silently and no type checker
-- catches it (user: "base 자체가 바뀌는게 아닌 새로 생성되므로 = 으로 대입해야한다를 강하게 알려야").
-- `Contains` keeps rejecting nil (`H-468`): asking "is nil a member" is a bug, not an empty choice.
function TagImpl.Added(self: any, nameOrList: any): any
	local names = table.clone(self._names)
	if nameOrList ~= nil then
		flattenInto(names, nameOrList, 1)
	end
	return newTag(names)
end

function TagImpl.Removed(self: any, nameOrList: any): any
	-- `H-344`: same validation as `Added` — a non-string used to be a silent
	-- no-op and `nil` a VM "table index is nil" blaming this file
	local toRemove: { [string]: true } = {}
	if nameOrList ~= nil then
		flattenInto(toRemove, nameOrList, 1)
	end
	local names = table.clone(self._names)
	for name in pairs(toRemove) do
		names[name] = nil
	end
	return newTag(names)
end

-- `H-468` (Gemini 5차 G-20, 사용자 Q32): variadic — every name must be present; a nil
-- (or non-string) argument is an error, never a silent false. Zero names (a dynamic
-- unpack) is allowed and vacuously true.
function TagImpl.Contains(self: any, ...: string): boolean
	local n = select("#", ...)
	for i = 1, n do
		local name = select(i, ...)
		if type(name) ~= "string" then
			Err.errorBeforeNearest(`Quad0205 Tag:Contains: names must be strings (got {typeof(name)} at argument {i})`, SURFACE)
		end
		if self._names[name] ~= true then
			return false
		end
	end
	return true
end

-- [2026-09-15 user decision, public surface (26)] generalized iteration instead of a `:Names()` method —
-- `for name in tag do`. Hands out the frozen set itself (no allocation); `pairs(tag)` bypasses `__iter`
-- and walks the wrapper (Luau superseded `__pairs` with `__iter`) — documented caveat, not supported.
function TagImpl.__iter(self: any)
	return next, self._names
end

function TagImpl.Apply(self: any, factory: any): any
	if type(factory) ~= "function" then
		-- `H-497` (2026-09-08 2차 감사 I-4): sibling `State:Apply` gates; here a non-function
		-- died at the call with `Tag.luau` on the blame line
		Err.errorBeforeNearest(`Quad0206 Tag: Apply factory must be a function (got {typeof(factory)})`, SURFACE)
	end
	return factory(self)
end

-- Callable namespace: Tag(...names) constructs, Tag.Merged composes Tags.
local Tag = setmetatable({}, {
	__call = function(_self, ...: any)
		-- vararg stays (static literal call sites — tag-plan "값 모양"); every slot
		-- goes through the one door, so `Tag(otherTag, "x", { "y", "z" })` works
		local names: { [string]: true } = {}
		-- visit every vararg slot (select, not `{...}`+ipairs — a nil hole would
		-- silently drop everything after it; Attr's __call does the same,
		-- 통합 리뷰 발견). A nil SLOT is "nothing here" (2026-09-21, see `Added`) — the slot count
		-- is exact, so nothing after it is lost; every non-nil slot is validated as before.
		for i = 1, select("#", ...) do
			local v = select(i, ...)
			if v ~= nil then
				flattenInto(names, v, 1)
			end
		end
		return newTag(names)
	end,
})

function Tag.Merged(...: any): any
	local names: { [string]: true } = {}
	for i = 1, select("#", ...) do
		local tag = select(i, ...)
		if tag == nil then
			continue -- nil slot = nothing (2026-09-21, see `Added`)
		end
		if not isTag(tag) then
			Err.errorBeforeNearest("Quad0207 Tag.Merged: arguments must be Tag values", SURFACE)
		end
		flattenInto(names, tag, 1) -- the Tag arm of the one door (round3 §9 `H-461` — was a second spelling via :Names())
	end
	return newTag(names)
end

table.freeze(Tag)

-- `H-238`: public constructors/methods are tagged so argument-validation
-- raises (Nearest — quad-error header: validation blames the caller even
-- when nested in a callback) land on the user's line, not this file. Tagged
-- once at file scope — the tag map lives in the shared namespace (`H-231`).
-- (통합 감사 2라운드 발견 — fork 산출물엔 스텁만 태그돼 있었다.)
Err.setFuncLevel(SURFACE, getmetatable(Tag).__call, Tag.Merged, TagImpl.Added, TagImpl.Removed, TagImpl.Contains, TagImpl.Apply)

--[[
	InitTag(module) — installs the value namespace, the op stubs (when no
	backend filled them yet) and registers TagFallbackHandler on this module
	instance's dispatch. Registries are per module instance (`H-174`/`H-194`).
]]
-- the loud stub factory (`NotInstalled.luau` — one body for the three modules, Q3 ②)
local function notInstalled(name: string): (...any) -> ...any
	return NotInstalled(name, "the tag ops")
end

local InitDispatch = require("./Dispatch")

local function Init(module: any)
	module.Tag = Tag
	if module.Backend.addTag == nil then
		module.Backend.addTag = notInstalled("addTag")
	end
	if module.Backend.removeTag == nil then
		module.Backend.removeTag = notInstalled("removeTag")
	end

	module:RunInit(InitDispatch) -- idempotent pull (`H-174` idiom)
	local dispatch: QuadTypes.Dispatch = module.Dispatch

	-- {[inst(weak)] = {[tagName] = {[k]: true}}} — per-name POSITION sets
	-- (tag-plan: holders keyed by position, not Tag identity — the same
	-- immutable Tag object reused at two positions must count twice)
	local tagNameMap = Relate()

	dispatch.addHandler({
		name = "TagFallbackHandler",
		keyType = "number", -- `H-484`: only number keys can match (isHandlable checks it too)
		isHandlable = function(_inst: any, k: any, v: any): boolean
			-- `H-52`: the k type check is mandatory, or this FALLBACK guard
			-- against named-slot leakage becomes dead code
			return type(k) == "number" and isTag(v)
		end,
		priority = dispatch.HANDLER_PRIORITY_FALLBACK,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			-- `H-39`: terminal handlers register their array position — a Tag
			-- contributes no physical element, so the pair is None/0
			module.Bookkeeping.setEmpty(inst, k, inst) -- `H-39` (한 본문 — Bookkeeping `setEmpty`)

			local added: { string } = {}
			for name in v do
				local holders = tagNameMap:GetStrong(inst, name)
				if holders == nil then
					holders = {}
					tagNameMap:SetStrong(inst, name, holders)
				end
				if next(holders) == nil then
					table.insert(added, name) -- first position to hold this name
				end
				holders[k] = true
			end
			if #added > 0 then
				module.Backend.addTag(inst, added) -- batched (web className contract); late read (`H-174`)
			end
			return function(nextValue: any?, _retracting: boolean)
				-- nextValue is nil (plain retract) or a Tag this same handler
				-- is about to reprocess — type guaranteed by the chain contract
				if v == nextValue then
					return -- immutable: same object = same name set, pure skip
				end
				local removed: { string } = {}
				for name in v do
					if nextValue ~= nil and nextValue:Contains(name) then
						-- survivor: KEEP the holder registration (2026-08-14
						-- 리뷰 정정 — dropping it would make the following
						-- process re-addTag an unchanged name)
						continue
					end
					-- always present (our own process registered it) — cast for the solver
					local holders = tagNameMap:GetStrong(inst, name) :: { [any]: any }
					holders[k] = nil
					if next(holders) == nil then
						table.insert(removed, name)
						-- `H-331` (fable 탐사 2026-09-06): drop the empty holder set —
						-- dynamic names (`Tag("item-" .. id)`) otherwise accumulate one
						-- table per name for the instance's lifetime
						tagNameMap:SetStrong(inst, name, nil)
					end
				end
				if #removed > 0 then
					module.Backend.removeTag(inst, removed) -- batched
				end
			end
		end,
	} :: QuadTypes.Handler)
end

return { Tag = Tag, Init = Init }
