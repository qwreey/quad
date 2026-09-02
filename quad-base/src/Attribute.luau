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
local Relate = require("./Relate")
local AttributeKeyModule = require("./AttributeKey")
local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local AttributeBrand = Brand.AttributeBrand
local isAttribute = Brand.isAttribute
local isStore = Brand.isStore
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
				Err.errorBefore(`{ctx}: attribute name "{name}" appears more than once`, SURFACE)
			end
			map[name] = arg[name] -- the declared Source slot (H-79)
		end
	elseif isAttribute(arg) then
		for name, v in pairs(arg:NameMap()) do
			if not overwrite and map[name] ~= nil then
				Err.errorBefore(`{ctx}: attribute name "{name}" appears more than once`, SURFACE)
			end
			map[name] = v
		end
	elseif type(arg) == "table" then
		for rawName, v in pairs(arg :: { [any]: any }) do
			if type(rawName) ~= "string" then
				Err.errorBefore(`{ctx}: plain-table keys must be strings`, SURFACE)
			end
			local name = rawName :: string
			if not overwrite and map[name] ~= nil then
				Err.errorBefore(`{ctx}: attribute name "{name}" appears more than once`, SURFACE)
			end
			map[name] = v
		end
	else
		Err.errorBefore(`{ctx}: arguments must be Stores, Attributes or plain tables`, SURFACE)
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
			Err.errorBefore("Attribute.Merged: arguments must be Attribute values", SURFACE)
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
			Err.errorBefore("Attribute.Overridden: arguments must be Attribute values", SURFACE)
		end
		flattenArg(map, arg, true, "Attribute.Overridden")
	end
	return newAttribute(map)
end

table.freeze(Attribute)

local InitDispatch = require("./Dispatch")

local function Init(quad: any)
	quad.Attribute = Attribute

	quad:RunInit(InitDispatch)
	quad:RunInit(AttributeKeyModule.Init) -- delegation target must exist (idempotent)
	local dispatch: QuadTypes.Dispatch = quad.Dispatch
	local None = quad.None

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
			dispatch.setOffsetSource(inst, k, None)
			dispatch.setLength(inst, k, 0, inst)

			-- `H-41`: position claim FIRST — the same group's second position
			-- must be rejected before any name claim is half-recorded
			local claimed = groupClaimKeys:GetStrong(inst, v)
			if claimed ~= nil and claimed ~= k then
				Err.errorBefore("Attribute: the same group value is placed at two positions of this instance", SURFACE)
			end
			groupClaimKeys:SetStrong(inst, v, k)

			local keys: { [any]: true } = {}
			for name, source in pairs(v:NameMap()) do
				local key = groupKey(v, name)
				dispatch.process(inst, key, source, 1) -- delegate: fresh chain, index 1
				keys[key] = true
			end
			return function(_nextValue: any?, _retracting: boolean)
				-- uniform teardown — survivors are re-registered by the next
				-- process (Dispatch guarantees retractor -> process order);
				-- never calls setAttribute, never calls Dispatch.process
				for key in pairs(keys) do
					dispatch.retractFrom(inst, key, 1)
				end
				-- position claim return — only while it is still ours
				if groupClaimKeys:GetStrong(inst, v) == k then
					groupClaimKeys:SetStrong(inst, v, nil)
				end
			end
		end,
	} :: QuadTypes.Handler)
end

return { Attribute = Attribute, Init = Init }
