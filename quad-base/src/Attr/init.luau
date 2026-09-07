--[[
	Attr — the GROUP value object + its delegating handler (M10, spike
	round16). [2026-09-08 user decision] `Attribute` → `Attr` across the
	surface (옛 `Attribute/init.luau`; `AttrKey`, `StringAttr`…, engine op
	`setAttr`): quad's Attr is engine-agnostic on its face, and the fact that it
	binds to a Roblox Attribute is the backend's implementation detail
	(`research/source-layout-plan.md` 8절). Canonical: `.claude/base/attribute-plan.md` ("그룹
	`Attr(...)`", "메커니즘 — 그룹 전용 키로 단일 키 경로에 위임",
	"이름 소유권"), as-is.

	  Attr(store1, store2, ..., {plain = tbl})  -- flatten to one name map;
	                                                 -- overlapping names: LAST
	                                                 -- argument wins (constructor
	                                                 -- policy == Overridden)
	  Attr.Merged(a, b, ...)     -- compose Attr values; overlap = error
	  Attr.Overridden(a, b, ...) -- compose; overlap = last silently wins
	  attr:NameMap() -> {[string]: any}  -- flattened name -> Source/State/raw
	  StringAttr(name, value) / NumberAttr / BooleanAttr
	                                  -- [2026-09-03 사용자 확정] typed scalar
	                                  -- SUGAR: a single-entry group
	                                  -- (`Attr({ [name] = value })`) —
	                                  -- no handler of its own; raw values are
	                                  -- type-checked here (the family knows
	                                  -- its type — AttrKey does not),
	                                  -- State/None pass through untouched

	plain-table values may be raw T or State<T>/Source<T> — they all flow down
	the single-key path where StoreBind unwraps (4라운드 명시). Store args are
	flattened via `store:Names()` (`H-79` — explicit initialization made the
	declared key set knowable).

	Handler ("AttrGroupFallbackHandler", FALLBACK, registered by
	InitAttr — `H-278` idiom): per-name PRIVATE keys (`groupKey(v, name)`,
	memoized per group value object x name, minted through AttrKey's
	`_newUncachedKey` so they are distinct from the public cached key —
	cross-owner retraction structurally impossible), `groupClaimKeys` position
	claim BEFORE any name claim (`H-41`), delegation via
	`Dispatch.process(inst, key, source, 1)`, retractor = retractFrom on every
	delegated key + position claim return. The retractor never calls
	setAttr (values persist until an explicit None/nil — user-confirmed).

	GC contract (2026-08-25 `/code-review`): the group value object is an
	INTERNAL KEY of `groupClaimKeys` and of the `groupKeys` memo — internal
	Relate keys are always strong, so a group value must never back-reference
	an inst (attribute-plan "GC 계약").
]]

local Brand = require("./Brand")
local Relate = require("./Relate")
local AttrKeyModule = require("@self/Key")
local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local AttrBrand = Brand.AttrBrand
local isAttr = Brand.isAttr
local isStore = Brand.isStore
local isState = Brand.isState
local isPlainBranded = Brand.isPlainBranded -- `H-377`: AttrKey/MapperDescriptor — plain tables branded, no metatable
local None = require("./Dispatch/None").None -- `isNone` is `v == None` (None.luau header)
local newUncachedKey = AttrKeyModule._newUncachedKey

local AttrImpl = {}
AttrImpl.__index = AttrImpl
-- `AttrMarker` (quad-types) — the type promises the marker, so the value carries it
-- (`H-300`); read through `__index`, zero per-instance slots. Identity stays the brand —
-- the field is the input-position type's evidence (user decision 2026-09-07: Tag/
-- Attr/Observer/EffectHandle go marker like State/Slot, typing-limits 8.11).
AttrImpl.__quadAttr = true
-- `__tostring` (2026-09-08, advisory 권고 1): the attribute names, sorted. (`AttrKey` stays without
-- one on purpose — it is a metatable-less plain branded table, `Brand.isPlainBranded`.)
function AttrImpl.__tostring(self: any): string
	local names = {}
	for name in self._nameMap do
		names[#names + 1] = name
	end
	table.sort(names)
	return `Attr\{{table.concat(names, ", ")}}`
end

local function newAttribute(nameMap: { [string]: any }): any
	local self = setmetatable({ _nameMap = table.freeze(nameMap) }, AttrImpl)
	AttrBrand:register(self)
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
			if name == "" then
				Err.errorBeforeNearest(`{ctx}: attribute name cannot be empty`, SURFACE) -- round3 `H-443` (G-13, Store gate's twin)
			end
			if not overwrite and map[name] ~= nil then
				Err.errorBeforeNearest(`{ctx}: attribute name "{name}" appears more than once`, SURFACE)
			end
			map[name] = arg[name] -- the declared Source slot (H-79)
		end
	elseif isAttr(arg) then
		for name, v in pairs(arg:NameMap()) do
			if not overwrite and map[name] ~= nil then
				Err.errorBeforeNearest(`{ctx}: attribute name "{name}" appears more than once`, SURFACE)
			end
			map[name] = v
		end
	elseif type(arg) == "table" and getmetatable(arg) == nil and not isPlainBranded(arg) then
		-- `H-345`: "plain" is enforced — a Source/Ref/Tag/... (any quad value
		-- carrying a metatable) would otherwise be flattened field by field
		-- (`_value`, `Revision`, ...), the `H-310` accident Modifier already closed.
		-- `H-368` (1순회): brands are weak-key registries, not metatables, so the
		-- metatable-LESS quad values (`Brand.isPlainBranded` — `H-377`) are
		-- excluded by brand; quad-roblox's metatable-less descriptors (OnChange
		-- `{ Name, Callback }`) fall to the function-value check below — an
		-- attribute value is raw T or State<T>, never a function (attribute-plan
		-- "그룹 `Attr(...)`"; the engine cannot store one, and through THIS
		-- group path it used to raise inside `setAttr` at dispatch depth).
		-- Scope: the group constructor only — the raw `[AttrKey] = v` key
		-- path stays untyped by design (`Attr/Key.luau` header, §4 Q4's family).
		for rawName, v in pairs(arg :: { [any]: any }) do
			if type(rawName) ~= "string" or rawName == "" then -- `H-421`: `""` reached setAttr at dispatch depth
				Err.errorBeforeNearest(`{ctx}: plain-table keys must be non-empty strings`, SURFACE)
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
		Err.errorBeforeNearest(`{ctx}: arguments must be Stores, Attr values or plain tables`, SURFACE)
	end
end

local Attr = setmetatable({}, {
	__call = function(_self, ...: any)
		local map: { [string]: any } = {}
		for i = 1, select("#", ...) do
			-- constructor overlap policy: last argument wins (== Overridden;
			-- 4라운드 명시 — use Attr.Merged to make overlap an error)
			flattenArg(map, select(i, ...), true, "Attr")
		end
		return newAttribute(map)
	end,
})

function Attr.Merged(...: any): any
	local map: { [string]: any } = {}
	for i = 1, select("#", ...) do
		local arg = select(i, ...)
		if not isAttr(arg) then
			Err.errorBeforeNearest("Attr.Merged: arguments must be Attr values", SURFACE)
		end
		flattenArg(map, arg, false, "Attr.Merged")
	end
	return newAttribute(map)
end

function Attr.Overridden(...: any): any
	local map: { [string]: any } = {}
	for i = 1, select("#", ...) do
		local arg = select(i, ...)
		if not isAttr(arg) then
			Err.errorBeforeNearest("Attr.Overridden: arguments must be Attr values", SURFACE)
		end
		flattenArg(map, arg, true, "Attr.Overridden")
	end
	return newAttribute(map)
end

table.freeze(Attr)

-- Typed scalar sugar family — one-entry groups. `luaType` is the raw-value
-- check; a State/Source (StoreBind unwraps it downstream) or `None` (delete)
-- passes through. `nil` is rejected here: a plain table cannot hold it, so
-- the entry would silently vanish — the user must say `None`.
local function scalarSugar(fnName: string, luaType: string): (string, any) -> any
	local function sugar(name: string, value: any): any
		if type(name) ~= "string" or name == "" then -- `H-421`
			Err.errorBeforeNearest(`{fnName}: name must be a non-empty string`, SURFACE)
		end
		if value == nil then
			Err.errorBeforeNearest(`{fnName}: value of "{name}" must not be nil — use None to delete`, SURFACE)
		end
		if not isState(value) and value ~= None and type(value) ~= luaType then
			Err.errorBeforeNearest(`{fnName}: value of "{name}" must be a {luaType}, State or None (got {typeof(value)})`, SURFACE)
		end
		return newAttribute({ [name] = value })
	end
	Err.setFuncLevel(SURFACE, sugar)
	return sugar
end

local StringAttr = scalarSugar("StringAttr", "string")
local NumberAttr = scalarSugar("NumberAttr", "number")
local BooleanAttr = scalarSugar("BooleanAttr", "boolean")

-- `H-238`: tag the public surface (see Tag.luau — same reasoning; the
-- handler-process raises below stay errorBefore, dispatch depth `H10-2`)
Err.setFuncLevel(SURFACE, getmetatable(Attr).__call, Attr.Merged, Attr.Overridden, AttrImpl.NameMap) -- `H-410`

local InitDispatch = require("./Dispatch")

local function Init(quad: any)
	quad.Attr = Attr
	quad.StringAttr = StringAttr
	quad.NumberAttr = NumberAttr
	quad.BooleanAttr = BooleanAttr

	quad:RunInit(InitDispatch)
	quad:RunInit(AttrKeyModule.Init) -- delegation target must exist (idempotent)
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
		name = "AttrGroupFallbackHandler",
		isHandlable = function(_inst: any, k: any, v: any): boolean
			-- `H-52`: k type check mandatory (array-part only)
			return type(k) == "number" and isAttr(v)
		end,
		priority = dispatch.HANDLER_PRIORITY_FALLBACK,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			-- `H-39`: terminal bookkeeping — the group contributes no element
			dispatch.setEmpty(inst, k, inst) -- `H-39` (한 본문 — Bookkeeping `setEmpty`)

			-- `H-41`: position claim FIRST — the same group's second position
			-- must be rejected before any name claim is half-recorded
			local claimed = groupClaimKeys:GetStrong(inst, v)
			if claimed ~= nil and claimed ~= k then
				Err.errorBefore("Attr: the same group value is placed at two positions of this instance", SURFACE)
			end
			-- `H-154` dedup (통합 리뷰, `H10-8`): the retractor below skips
			-- teardown when the SAME immutable group is re-emitted, and it also
			-- leaves our position claim in place — so "already claimed by this
			-- very position" at entry means exactly that re-emission. Skip the
			-- delegation loop then: the per-name chains are still live, and
			-- re-delegating would re-run K unconditional setAttr calls
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
				-- never calls setAttr, never calls Dispatch.process.
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
	Attr = Attr,
	StringAttr = StringAttr,
	NumberAttr = NumberAttr,
	BooleanAttr = BooleanAttr,
	Init = Init,
}
