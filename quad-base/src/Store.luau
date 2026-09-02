--[[
	Store — a named bag of Sources, explicitly initialised.
	`.claude/base/store-plan.md` "Store = Source들의 이름 붙은 모음 (명시적
	초기화)" and "타입 추론 문제 — `store.key`(dot-access)를 1급 경로로
	확정" (`store:Of<<T>>(name)`), as-is.

	  local store = quad.Store<<{ hp: Source<number> }>>({ hp = Source(100) })
	  store.hp:Get()          -- plain record field → the Source itself
	  store:Of<<T>>(name)     -- the ONLY dynamic-key door; creates on first use
	  store:Names()           -- keys at this moment (declared + created by Of)

	- The shadow table IS the store (`H-153`): `table.clone(defaults or {})`
	  becomes the object; methods live in `__index`, so `Names()` does not
	  count them and `store.key` stays a plain field.
	- Constructor validation, one pass over `defaults` (`H-122` + `H-153`):
	  every value must pass `isSource` (whitelist — raw values would be
	  accepted silently and die at the first `:Get()`), and no key may be a
	  reserved name. Both are user input → `Err.errorBeforeNearest(…, SURFACE)` (`H-231` walker), English.
	- `RESERVED` here is the runtime single source of the reserved names;
	  the type function `CheckReservedKeys` in quad-types carries a copy —
	  rename both together. `__reservedCheck` is a phantom (type-only) field.
	- `isModifier` is NOT checked here — the `Source` constructor does it,
	  which covers the `Of` path too (`modifier-plan.md` 7번).
	- Nothing lets an externally made Source be inserted later; `Of` is the
	  one lazy spot left, and it is explicit about giving up type safety.

	Assembly (`H-174`): `InitStore(module)` — `Of` creates values through
	`module.Source`, read at call time; the init pulls `InitSource` in itself
	(`RunInit` is idempotent), so `New()` order is irrelevant.
]]

local Brand = require("./Brand")
local InitSource = require("./Source")
local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

export type Store<T> = QuadTypes.Store<T>

local StoreBrand = Brand.StoreBrand
local isSource = Brand.isSource

-- Runtime single source of the reserved names (`H-153`). Mirror: quad-types
-- `CheckReservedKeys`. `__reservedCheck` cannot be derived from `__index`
-- because it is a phantom field.
local RESERVED = { Of = true, Names = true, __reservedCheck = true }

local function Init(module: any)
	module:RunInit(InitSource) -- `Of` needs `module.Source`; pull it in ourselves (idempotent)
	local Impl = {}
	Impl.__index = Impl

	-- Dynamic keys only: the type cannot stop a computed name, so the runtime does.
	function Impl.Of(self: any, name: string): any
		if type(name) ~= "string" then
			-- `H-201`: `Of` exists precisely for computed names — a nil/number name
			-- must not pass (nil died at `self[name] =` with an internal frame after
			-- already allocating a Source; a number silently broke `Names(): { string }`).
			Err.errorBeforeNearest(`Store: Of name must be a string (got {typeof(name)})`, SURFACE)
		end
		if RESERVED[name] then
			Err.errorBeforeNearest(`Store: "{name}" is a reserved store key`, SURFACE)
		end
		local src = rawget(self, name) -- shadow = the store itself; never go through `__index`
		if src == nil then
			src = module.Source(nil) -- == Source() — read lazily, not captured
			self[name] = src
		end
		return src
	end

	function Impl.Names(self: any): { string }
		local names = {}
		for name in self do
			names[#names + 1] = name
		end
		return names
	end

	local function Store(defaults: any?): any
		-- `H-204`: validate the bag itself before cloning it — a non-table died
		-- inside `table.clone`, and a bare Source (forgot the wrapping table) got
		-- pairs-walked into an error naming a Source-internal field.
		if defaults ~= nil then
			if type(defaults) ~= "table" then
				Err.errorBeforeNearest(`Store: defaults must be a table of Sources (got {typeof(defaults)})`, SURFACE)
			end
			if getmetatable(defaults) ~= nil then
				Err.errorBeforeNearest("Store: defaults must be a plain table without a metatable (a bare Source instead of { name = Source }?)", SURFACE)
			end
		end
		local self = table.clone(defaults or {}) -- `or {}`: `Store<<{}>>()` is valid (`H-83`)
		for name, value in self do
			if RESERVED[name :: any] then
				Err.errorBeforeNearest(`Store: "{tostring(name)}" is a reserved store key`, SURFACE)
			end
			if not isSource(value) then
				Err.errorBeforeNearest(`Store: default for "{tostring(name)}" is not a Source (got {typeof(value)})`, SURFACE)
			end
		end
		setmetatable(self, Impl)
		StoreBrand:register(self)
		return self
	end

	-- `H-231`: public surface joins the shared error-namespace tag layer
	for _, fn in { Impl.Of, Impl.Names, Store } do
		Err.setFuncLevel(fn, SURFACE)
	end

	module.Store = Store
end

return Init
