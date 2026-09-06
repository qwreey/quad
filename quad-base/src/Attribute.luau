--[[
	Attribute — the GROUP value object + its delegating handler (M10, spike
	round16). Canonical: `.claude/base/attribute-plan.md` ("그룹
	`Attribute(...)`", "메커니즘 — 그룹 전용 키로 단일 키 경로에 위임",
	"이름 소유권"), as-is.

	  Attribute(store1, store2, ..., {plain = tbl})  -- flatten to one name map;
	                                                 -- overlapping names: LAST
	                                                 -- argument wins (constructor
	                                                 -- policy == Overridden)
	  Attribute.Merged(a, b, ...)     -- compose Attribute values; overlap = error
	  Attribute.Overridden(a, b, ...) -- compose; overlap = last silently wins
	  attr:NameMap() -> {[string]: any}  -- flattened name -> Source/State/raw
	  StringAttribute(name, value) / NumberAttribute / BooleanAttribute
	                                  -- [2026-09-03 사용자 확정] typed scalar
	                                  -- SUGAR: a single-entry group
	                                  -- (`Attribute({ [name] = value })`) —
	                                  -- no handler of its own; raw values are
	                                  -- type-checked here (the family knows
	                                  -- its type — AttributeKey does not),
	                                  -- State/None pass through untouched

	plain-table values may be raw T or State<T>/Source<T> — they all flow down
	the single-key path where StoreBind unwraps (4라운드 명시). Store args are
	flattened via `store:Names()` (`H-79` — explicit initialization made the
	declared key set knowable).

	Handler ("AttributeGroupFallbackHandler", FALLBACK, registered by
	InitAttribute — `H-278` idiom): per-name PRIVATE keys (`groupKey(v, name)`,
	memoized per group value object x name, minted through AttributeKey's
	`_newUncachedKey` so they are distinct from the public cached key —
	cross-owner retraction structurally impossible), `groupClaimKeys` position
	claim BEFORE any name claim (`H-41`), delegation via
	`Dispatch.process(inst, key, source, 1)`, retractor = retractFrom on every
	delegated key + position claim return. The retractor never calls
	setAttribute (values persist until an explicit None/nil — user-confirmed).

	GC contract (2026-08-25 `/code-review`): the group value object is an
	INTERNAL KEY of `groupClaimKeys` and of the `groupKeys` memo — internal
	Relate keys are always strong, so a group value must never back-reference
	an inst (attribute-plan "GC 계약").
]]

local Brand = require("./Brand")
local NoneModule = require("./Dispatch/None")
local Relate = require("./Relate")
local AttributeKeyModule = require("./AttributeKey")
local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local AttributeBrand = Brand.AttributeBrand
local isAttribute = Brand.isAttribute
local isStore = Brand.isStore
local isState = Brand.isState
local isAttributeKey = Brand.isAttributeKey
local isMapperDescriptor = Brand.isMapperDescriptor
local None = require("./Dispatch/None").None -- `isNone` is `v == None` (None.luau header)
local newUncachedKey = AttributeKeyModule._newUncachedKey

local AttrImpl = {}
AttrImpl.__index = AttrImpl

local function newAttribute(nameMap: { [string]: any }): any
	local self = setmetatable({ _nameMap = table.freeze(nameMap) }, AttrImpl)
	AttributeBrand:register(self)
	return table.freeze(self)
end

function AttrImpl.NameMap(self: any): { [string]: any }
	return self._nameMap
end

-- Flatten one constructor argument into the map. Later writes win at the
-- CALLER's discretion (constructor/Overridden pass overwrite=true; Merged
-- passes false and errors on overlap).
local function flattenArg(map: { [string]: any }, arg: any, overwrite: boolean, ctx: string)
	if isStore(arg) then
		for _, name in ipairs(arg:Names()) do
			if not overwrite and map[name] ~= nil then
				Err.errorBeforeNearest(`{ctx}: attribute name "{name}" appears more than once`, SURFACE)
			end
			map[name] = arg[name] -- the declared Source slot (H-79)
		end
	elseif isAttribute(arg) then
		for name, v in pairs(arg:NameMap()) do
			if not overwrite and map[name] ~= nil then
				Err.errorBeforeNearest(`{ctx}: attribute name "{name}" appears more than once`, SURFACE)
			end
			map[name] = v
		end
	elseif type(arg) == "table" and getmetatable(arg) == nil and not isAttributeKey(arg) and not isMapperDescriptor(arg) then
		-- `H-345`: "plain" is enforced — a Source/Ref/Tag/... (any quad value
		-- carrying a metatable) would otherwise be flattened field by field
		-- (`_value`, `Revision`, ...), the `H-310` accident Modifier already closed.
		-- `H-368` (1순회): brands are weak-key registries, not metatables, so the
		-- metatable-LESS quad values base can name (AttributeKey, MapperDescriptor —
		-- frozen plain tables) are excluded by brand; quad-roblox's metatable-less
		-- descriptors (OnChange `{ Name, Callback }`) fall to the function-value
		-- check below — an attribute value is raw T or State<T>, never a function
		-- (attribute-plan "그룹 `Attribute(...)`"; the engine cannot store one, and
		-- letting it through raised inside `setAttribute` at dispatch depth).
		for rawName, v in pairs(arg :: { [any]: any }) do
			if type(rawName) ~= "string" then
				Err.errorBeforeNearest(`{ctx}: plain-table keys must be strings`, SURFACE)
			end
			local name = rawName :: string
			if type(v) == "function" then
				Err.errorBeforeNearest(`{ctx}: attribute "{name}" cannot be a function — attribute values are raw values or State`, SURFACE)
			end
			if not overwrite and map[name] ~= nil then
				Err.errorBeforeNearest(`{ctx}: attribute name "{name}" appears more than once`, SURFACE)
			end
			map[name] = v
		end
	else
		Err.errorBeforeNearest(`{ctx}: arguments must be Stores, Attributes or plain tables`, SURFACE)
	end
end

local Attribute = setmetatable({}, {
	__call = function(_self, ...: any)
		local map: { [string]: any } = {}
		for i = 1, select("#", ...) do
			-- constructor overlap policy: last argument wins (== Overridden;
			-- 4라운드 명시 — use Attribute.Merged to make overlap an error)
			flattenArg(map, select(i, ...), true, "Attribute")
		end
		return newAttribute(map)
	end,
})

function Attribute.Merged(...: any): any
	local map: { [string]: any } = {}
	for i = 1, select("#", ...) do
		local arg = select(i, ...)
		if not isAttribute(arg) then
			Err.errorBeforeNearest("Attribute.Merged: arguments must be Attribute values", SURFACE)
		end
		flattenArg(map, arg, false, "Attribute.Merged")
	end
	return newAttribute(map)
end

function Attribute.Overridden(...: any): any
	local map: { [string]: any } = {}
	for i = 1, select("#", ...) do
		local arg = select(i, ...)
		if not isAttribute(arg) then
			Err.errorBeforeNearest("Attribute.Overridden: arguments must be Attribute values", SURFACE)
		end
		flattenArg(map, arg, true, "Attribute.Overridden")
	end
	return newAttribute(map)
end

table.freeze(Attribute)

-- Typed scalar sugar family — one-entry groups. `luaType` is the raw-value
-- check; a State/Source (StoreBind unwraps it downstream) or `None` (delete)
-- passes through. `nil` is rejected here: a plain table cannot hold it, so
-- the entry would silently vanish — the user must say `None`.
local function scalarSugar(fnName: string, luaType: string): (string, any) -> any
	local function sugar(name: string, value: any): any
		if type(name) ~= "string" then
			Err.errorBeforeNearest(`{fnName}: name must be a string`, SURFACE)
		end
		if value == nil then
			Err.errorBeforeNearest(`{fnName}("{name}"): value must not be nil — use None to delete`, SURFACE)
		end
		if not isState(value) and value ~= None and type(value) ~= luaType then
			Err.errorBeforeNearest(`{fnName}("{name}"): value must be a {luaType} (or State/None), got {typeof(value)}`, SURFACE)
		end
		return newAttribute({ [name] = value })
	end
	Err.setFuncLevel(sugar, SURFACE)
	return sugar
end

local StringAttribute = scalarSugar("StringAttribute", "string")
local NumberAttribute = scalarSugar("NumberAttribute", "number")
local BooleanAttribute = scalarSugar("BooleanAttribute", "boolean")

-- `H-238`: tag the public surface (see Tag.luau — same reasoning; the
-- handler-process raises below stay errorBefore, dispatch depth `H10-2`)
for _, fn in { getmetatable(Attribute).__call, Attribute.Merged, Attribute.Overridden } :: { any } do
	Err.setFuncLevel(fn, SURFACE)
end

local InitDispatch = require("./Dispatch")

local function Init(quad: any)
	quad.Attribute = Attribute
	quad.StringAttribute = StringAttribute
	quad.NumberAttribute = NumberAttribute
	quad.BooleanAttribute = BooleanAttribute

	quad:RunInit(InitDispatch)
	quad:RunInit(AttributeKeyModule.Init) -- delegation target must exist (idempotent)
	local dispatch: QuadTypes.Dispatch = quad.Dispatch

	-- group value object(weak) -> {[name] = private key} — memoized so a
	-- reprocessed group delegates through the SAME key objects and the name
	-- claim never collides with itself
	local groupKeys = Relate()
	-- (inst(weak), groupValue) -> k — position claim: the same group object at
	-- two positions of one instance is an immediate error (`AT-1`/`H-41`)
	local groupClaimKeys = Relate()

	local function groupKey(v: any, name: string): any
		local key = groupKeys:GetStrong(v, name)
		if key == nil then
			key = newUncachedKey(name)
			groupKeys:SetStrong(v, name, key)
		end
		return key
	end

	dispatch.addHandler({
		name = "AttributeGroupFallbackHandler",
		isHandlable = function(_inst: any, k: any, v: any): boolean
			-- `H-52`: k type check mandatory (array-part only)
			return type(k) == "number" and isAttribute(v)
		end,
		priority = dispatch.HANDLER_PRIORITY_FALLBACK,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			-- `H-39`: terminal bookkeeping — the group contributes no element
			NoneModule.registerEmptySlot(dispatch, inst, k, inst) -- `H-39` (리뷰 — 한 본문, `None.luau`)

			-- `H-41`: position claim FIRST — the same group's second position
			-- must be rejected before any name claim is half-recorded
			local claimed = groupClaimKeys:GetStrong(inst, v)
			if claimed ~= nil and claimed ~= k then
				Err.errorBefore("Attribute: the same group value is placed at two positions of this instance", SURFACE)
			end
			-- `H-154` dedup (통합 리뷰, `H10-8`): the retractor below skips
			-- teardown when the SAME immutable group is re-emitted, and it also
			-- leaves our position claim in place — so "already claimed by this
			-- very position" at entry means exactly that re-emission. Skip the
			-- delegation loop then: the per-name chains are still live, and
			-- re-delegating would re-run K unconditional setAttribute calls
			-- (TagFallbackHandler's holder check is the same idea).
			local reemit = claimed == k
			groupClaimKeys:SetStrong(inst, v, k)

			if not reemit then
				for name, source in pairs(v:NameMap()) do
					dispatch.process(inst, groupKey(v, name), source, 1) -- delegate: fresh chain, index 1
				end
			end
			return function(nextValue: any?, _retracting: boolean)
				if v == nextValue then
					return -- immutable: same object = same name map, pure skip
				end
				-- uniform teardown — survivors are re-registered by the next
				-- process (Dispatch guarantees retractor -> process order);
				-- never calls setAttribute, never calls Dispatch.process.
				-- Keys are recomputed from the memoized groupKey (no captured
				-- table — the re-emit path returns an equivalent retractor).
				for name in pairs(v:NameMap()) do
					dispatch.retractFrom(inst, groupKey(v, name), 1)
				end
				-- position claim return — only while it is still ours
				if groupClaimKeys:GetStrong(inst, v) == k then
					groupClaimKeys:SetStrong(inst, v, nil)
				end
			end
		end,
	} :: QuadTypes.Handler)
end

return {
	Attribute = Attribute,
	StringAttribute = StringAttribute,
	NumberAttribute = NumberAttribute,
	BooleanAttribute = BooleanAttribute,
	Init = Init,
}
