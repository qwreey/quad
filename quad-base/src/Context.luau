--!strict
--[[
	Context — an EXPLICIT, typed value container passed down props (`base/context-plan.md`,
	user direction 2026-09-08). NOT the ambient tree-wide context quad rejected
	(`archive/context-rejected.md`): nothing is looked up through the tree; a
	component receives the bag as a named parameter and reads its own keys.
	The point is the intermediate layer — a shell that does not know the app's
	store schema can forward one `Context` without typing every store.

	Ownership: `_values` is a plain table — the bag holds its Providers and
	values STRONGLY (a Context's lifetime is a lower bound on the Stores in it;
	no weak variant). There is no enumeration surface on purpose: the bag is
	one source of truth, never forked or extended per subtree (user, `base/
	context-plan.md`). Provider identity is per quad-base COPY — a Provider from
	another copy is not `isProvider` here (same as brands, `Brand.luau`).

	  Context()                         -> ctx                (empty bag)
	  Context.Provider<<T>>(name?)      -> Provider<T>        (unique table key; `T` is phantom)
	  ctx:Set(provider, value)          -> ctx                (nil value is an error — absence = not set)
	  ctx:Get(provider)                 -> T                  (ERROR if not set — user: "프로바이더가 필요한데
	                                                           제공 안 하는거면 에러를 내는게 일반적")
	  ctx:Peek(provider)                -> T?                 (nil if not set — the "has it?" probe)

	Keys are table identities (no string collisions across modules); the value
	map is keyed by the Provider table. `Set` MUTATES the bag it is called on
	(chaining returns self) — extending a parent's bag for a subtree is the
	creator's business (copy first). There is deliberately no immutable-clone
	`With`: one bag is the single source of truth, so debugging reads one place
	(`base/context-plan.md` "불변 확장은 만들지 않는다"). Dependency-free leaf, shared across quad instances.
]]

local Brand = require("./Brand")
local Void = require("./Void")
local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")

local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE
local ContextBrand = Brand.ContextBrand
local ProviderBrand = Brand.ProviderBrand
local isProvider = Brand.isProvider
local DispatchHintBrand = Brand.DispatchHintBrand -- `q.Protocols.DispatchHint` (round14 Q161)

local ProviderImpl = {}
ProviderImpl.__index = ProviderImpl
-- 2026-09-15 (25): the contravariant phantom that makes `Provider<T>` invariant — type-only, the value is
-- `Void` read through `__index` (zero per-instance slots, like `RefImpl.__quadRefAccepts`); nothing reads it
ProviderImpl.__quadProviderAccepts = Void
function ProviderImpl.__tostring(self: any): string
	return if self.Name ~= nil then `Provider({self.Name})` else "Provider"
end
-- round14 Q161·Q182 (user decision 2026-10-06): the `q.Protocols.DispatchHint` hook (moved from Dispatch's
-- name branch — round13 E80: the old hint sent it to a numeric slot, which raised `Quad0076` again)
function ProviderImpl.__dispatchHint(_self: any, _key: any): string?
	return "a Provider is not a value for any key: read the value you need out of the Context first"
end

local function Provider(name: string?): any
	if name ~= nil and type(name) ~= "string" then
		Err.errorBeforeNearest(`Quad0035 Context.Provider: name must be a string (got {typeof(name)})`, SURFACE)
	end
	local self = setmetatable({ __quadProvider = true, Name = name }, ProviderImpl)
	ProviderBrand:Register(self)
	DispatchHintBrand:Register(self)
	return table.freeze(self)
end

local ContextImpl = {}
ContextImpl.__index = ContextImpl
ContextImpl.__quadContext = true
function ContextImpl.__tostring(self: any): string
	local n = 0
	for _ in self._values do
		n += 1
	end
	return `Context({n})`
end
-- round14 Q161·Q182: the `q.Protocols.DispatchHint` hook (see ProviderImpl's)
function ContextImpl.__dispatchHint(_self: any, _key: any): string?
	return "a Context is not a value for any key: read the value you need out of it first"
end

local function checkProvider(fnName: string, provider: any)
	if not isProvider(provider) then
		Err.errorBeforeNearest(`Quad0036 Context:{fnName}: key must be a Provider from Context.Provider() (got {typeof(provider)})`, SURFACE)
	end
end

function ContextImpl.Set(self: any, provider: any, value: any): any
	checkProvider("Set", provider)
	if value == nil then
		Err.errorBeforeNearest(`Quad0037 Context:Set: value for {tostring(provider)} must not be nil (absence is "not set")`, SURFACE)
	end
	self._values[provider] = value
	return self
end

function ContextImpl.Get(self: any, provider: any): any
	checkProvider("Get", provider)
	local value = self._values[provider]
	if value == nil then
		Err.errorBeforeNearest(`Quad0038 Context:Get: no value for {tostring(provider)} - the creator of this Context did not :Set it (use :Peek to test)`, SURFACE)
	end
	return value
end

function ContextImpl.Peek(self: any, provider: any): any
	checkProvider("Peek", provider)
	return self._values[provider]
end

local function Context(): any
	local self = setmetatable({ _values = {} }, ContextImpl)
	ContextBrand:Register(self)
	DispatchHintBrand:Register(self)
	return self
end

Err.setFuncLevel(SURFACE, ContextImpl.Set, ContextImpl.Get, ContextImpl.Peek, Provider) -- `H-231`; the local `Context()` builder is a direct call inside `__call` (quad-error usage rule: tag only table-field calls) — the gate (`Quad0255`, round13 Q102) and the SURFACE tag sit on `__call` itself, below

-- callable namespace (the `Tag`/`Attr` idiom — `setmetatable<A, B>` in the types)
local ContextConstructor = setmetatable({ Provider = Provider }, {
	__call = function(_self: any, ...: any)
		-- round13 Q102 (a) (user decision 2026-09-28): `Tag(...)`/`Attr{...}`/`Store{...}` take initial
		-- values, so `q.Context({ [P] = v })` reads naturally - it dropped the table silently and failed
		-- later at `:Get(P)` (Quad0038), far from the cause. The bag is mutable, so the answer is to
		-- `:Set` from outside, not an initializer (user: an initial-table arm is hard to type).
		local n = select("#", ...)
		if n > 0 then
			Err.errorBeforeNearest(`Quad0255 Context: takes no arguments (got {n} argument{if n == 1 then "" else "s"}) - create an empty Context and fill it with ctx:Set(provider, value)`, SURFACE)
		end
		return Context()
	end,
})
Err.setFuncLevel(SURFACE, getmetatable(ContextConstructor :: any).__call) -- Q102: the Tag/Attr `__call` idiom (blame the user's call line)

return { Context = ContextConstructor }
