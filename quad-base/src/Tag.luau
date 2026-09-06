--[[
	Tag — array-part value object + its reference-counted handler (M10, spike
	round16). Canonical: `.claude/base/tag-plan.md` (value shape "값 모양",
	mechanism "메커니즘 — `TagHandler`", placement "패키지 배치"), as-is.

	Value API (immutable clone chaining — every operation returns a clone):
	  Tag(name1, name2, ...) -> tag        -- vararg constructor; Tag() is valid
	  tag:Added(string | {string}) -> Tag  -- clone + add name(s)
	  tag:Removed(string | {string}) -> Tag
	  tag:Contains(name) -> boolean
	  tag:Names() -> iterator<string>
	  tag:Apply(factory) -> U              -- factory(self) sugar (Modifier pattern)
	  Tag.Merged(tag1, tag2, ...) -> Tag   -- lossless set union

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
local NoneModule = require("./Dispatch/None")
local Relate = require("./Relate")
local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local TagBrand = Brand.TagBrand
local isTag = Brand.isTag

local TagImpl = {}
TagImpl.__index = TagImpl

-- names are stored as a set ({[name]: true}) plus nothing else — order is
-- irrelevant to the union semantics and the engine batch call takes a list
local function newTag(names: { [string]: true }): any
	local self = setmetatable({ _names = table.freeze(names) }, TagImpl)
	TagBrand:register(self)
	return table.freeze(self)
end

local function flattenInto(target: { [string]: true }, nameOrList: any)
	if type(nameOrList) == "table" then
		-- 3순회 `H-380`: a `{string}` LIST only (tag-plan "값 모양" — `string | {string}`).
		-- The old `ipairs` walk saw a Tag value / Source / AttributeKey / hash table
		-- as an EMPTY list — `a:Added(Tag("x"))` and `a:Removed(Tag("x"))` were silent
		-- no-ops. Quad values are rejected by metatable or brand; a hash key, a
		-- non-string element, or a nil hole is a validation error like any non-string.
		if getmetatable(nameOrList) ~= nil or Brand.isPlainBranded(nameOrList) then
			Err.errorBeforeNearest("Tag: names must be strings or a {string} list — a quad value is not a name list (combine Tags with Tag.Merged)", SURFACE)
		end
		local count, maxIndex = 0, 0
		for k, name in pairs(nameOrList :: { [any]: any }) do
			if type(k) ~= "number" or k % 1 ~= 0 or k < 1 or type(name) ~= "string" then
				Err.errorBeforeNearest("Tag: names must be strings — a name list is a {string} array", SURFACE)
			end
			count += 1
			if k > maxIndex then maxIndex = k end
			target[name :: string] = true
		end
		if count ~= maxIndex then
			Err.errorBeforeNearest("Tag: names must be strings — a name list cannot have nil holes", SURFACE)
		end
	elseif type(nameOrList) == "string" then
		target[nameOrList] = true
	else
		Err.errorBeforeNearest("Tag: names must be strings", SURFACE)
	end
end

function TagImpl.Added(self: any, nameOrList: any): any
	local names = table.clone(self._names)
	flattenInto(names, nameOrList)
	return newTag(names)
end

function TagImpl.Removed(self: any, nameOrList: any): any
	-- `H-344`: same validation as `Added` — a non-string used to be a silent
	-- no-op and `nil` a VM "table index is nil" blaming this file
	local toRemove: { [string]: true } = {}
	flattenInto(toRemove, nameOrList)
	local names = table.clone(self._names)
	for name in pairs(toRemove) do
		names[name] = nil
	end
	return newTag(names)
end

function TagImpl.Contains(self: any, name: string): boolean
	return self._names[name] == true
end

function TagImpl.Names(self: any): () -> string?
	local name: string? = nil
	return function(): string?
		name = next(self._names, name)
		return name
	end
end

function TagImpl.Apply(self: any, factory: any): any
	return factory(self)
end

-- Callable namespace: Tag(...) constructs, Tag.Merged composes.
local Tag = setmetatable({}, {
	__call = function(_self, ...: string)
		-- vararg stays (static literal call sites — tag-plan "값 모양"); pack
		-- once and reuse the table path of Added via an empty tag
		local names: { [string]: true } = {}
		-- visit every vararg slot (select, not `{...}`+ipairs — a nil hole would
		-- silently drop everything after it; Attribute's __call does the same,
		-- 통합 리뷰 발견). A nil slot is a validation error like any non-string.
		for i = 1, select("#", ...) do
			flattenInto(names, (select(i, ...)))
		end
		return newTag(names)
	end,
})

function Tag.Merged(...: any): any
	local names: { [string]: true } = {}
	for i = 1, select("#", ...) do
		local tag = select(i, ...)
		if not isTag(tag) then
			Err.errorBeforeNearest("Tag.Merged: arguments must be Tag values", SURFACE)
		end
		for name in tag:Names() do
			names[name] = true
		end
	end
	return newTag(names)
end

table.freeze(Tag)

-- `H-238`: public constructors/methods are tagged so argument-validation
-- raises (Nearest — quad-error header: validation blames the caller even
-- when nested in a callback) land on the user's line, not this file. Tagged
-- once at file scope — the tag map lives in the shared namespace (`H-231`).
-- (통합 감사 2라운드 발견 — fork 산출물엔 스텁만 태그돼 있었다.)
for _, fn in
	{ getmetatable(Tag).__call, Tag.Merged, TagImpl.Added, TagImpl.Removed, TagImpl.Contains, TagImpl.Names, TagImpl.Apply } :: { any }
do
	Err.setFuncLevel(fn, SURFACE)
end

--[[
	InitTag(module) — installs the value namespace, the op stubs (when no
	backend filled them yet) and registers TagFallbackHandler on this module
	instance's dispatch. Registries are per module instance (`H-174`/`H-194`).
]]
local function notInstalled(name: string): (...any) -> ...any
	local stub = function(...: any)
		-- errorBefore (outermost), not Nearest: these stubs are reached from
		-- dispatch depth (handler process), so the nearest tagged frame is the
		-- stub itself and Nearest would blame quad internals (`H-272` reasoning)
		Err.errorBefore(
			`quad: {name} is not available — no backend has installed the tag ops `
				.. "(install a provider with quad:UseProvider — a bare Quad.New() has none)",
			SURFACE
		)
	end
	Err.setFuncLevel(stub, SURFACE)
	return stub
end

local InitDispatch = require("./Dispatch")

local function Init(module: any)
	module.Tag = Tag
	if module.addTag == nil then
		module.addTag = notInstalled("addTag")
	end
	if module.removeTag == nil then
		module.removeTag = notInstalled("removeTag")
	end

	module:RunInit(InitDispatch) -- idempotent pull (`H-174` idiom)
	local dispatch: QuadTypes.Dispatch = module.Dispatch

	-- {[inst(weak)] = {[tagName] = {[k]: true}}} — per-name POSITION sets
	-- (tag-plan: holders keyed by position, not Tag identity — the same
	-- immutable Tag object reused at two positions must count twice)
	local tagNameMap = Relate()

	dispatch.addHandler({
		name = "TagFallbackHandler",
		isHandlable = function(_inst: any, k: any, v: any): boolean
			-- `H-52`: the k type check is mandatory, or this FALLBACK guard
			-- against named-slot leakage becomes dead code
			return type(k) == "number" and isTag(v)
		end,
		priority = dispatch.HANDLER_PRIORITY_FALLBACK,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			-- `H-39`: terminal handlers register their array position — a Tag
			-- contributes no physical element, so the pair is None/0
			NoneModule.registerEmptySlot(dispatch, inst, k, inst) -- `H-39` (리뷰 — 한 본문, `None.luau`)

			local added: { string } = {}
			for name in v:Names() do
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
				module.addTag(inst, added) -- batched (web className contract); late read (`H-174`)
			end
			return function(nextValue: any?, _retracting: boolean)
				-- nextValue is nil (plain retract) or a Tag this same handler
				-- is about to reprocess — type guaranteed by the chain contract
				if v == nextValue then
					return -- immutable: same object = same name set, pure skip
				end
				local removed: { string } = {}
				for name in v:Names() do
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
					module.removeTag(inst, removed) -- batched
				end
			end
		end,
	} :: QuadTypes.Handler)
end

return { Tag = Tag, Init = Init }
