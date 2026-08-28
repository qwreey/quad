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
	  reserved name. Both are user input → `error(..., 2)`, English.
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
local QuadTypes = require("../roblox_packages/quad_types")

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
		if RESERVED[name] then
			error(`Store: "{name}" is a reserved store key`, 2)
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
		for name in pairs(self) do
			names[#names + 1] = name
		end
		return names
	end

	local function Store(defaults: any?): any
		local self = table.clone(defaults or {}) -- `or {}`: `Store<<{}>>()` is valid (`H-83`)
		for name, value in pairs(self) do
			if RESERVED[name :: any] then
				error(`Store: "{tostring(name)}" is a reserved store key`, 2)
			end
			if not isSource(value) then
				error(`Store: default for "{tostring(name)}" is not a Source (got {typeof(value)})`, 2)
			end
		end
		setmetatable(self, Impl)
		StoreBrand:register(self)
		return self
	end

	module.Store = Store
end

return Init
