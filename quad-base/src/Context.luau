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
	creator's business (copy first); an immutable-clone `With` is an open item
	(`question.md`). Dependency-free leaf, shared across quad instances.
]]

local Brand = require("./Brand")
local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")

local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE
local ContextBrand = Brand.ContextBrand
local ProviderBrand = Brand.ProviderBrand
local isProvider = Brand.isProvider

local ProviderImpl = {}
ProviderImpl.__index = ProviderImpl
function ProviderImpl.__tostring(self: any): string
	return if self.Name ~= nil then `Provider({self.Name})` else "Provider"
end

local function Provider(name: string?): any
	if name ~= nil and type(name) ~= "string" then
		Err.errorBeforeNearest(`Context.Provider: name must be a string (got {typeof(name)})`, SURFACE)
	end
	local self = setmetatable({ __quadProvider = true, Name = name }, ProviderImpl)
	ProviderBrand:register(self)
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

local function checkProvider(fnName: string, provider: any)
	if not isProvider(provider) then
		Err.errorBeforeNearest(`Context:{fnName}: key must be a Provider from Context.Provider() (got {typeof(provider)})`, SURFACE)
	end
end

function ContextImpl.Set(self: any, provider: any, value: any): any
	checkProvider("Set", provider)
	if value == nil then
		Err.errorBeforeNearest(`Context:Set: value for {tostring(provider)} must not be nil (absence is "not set")`, SURFACE)
	end
	self._values[provider] = value
	return self
end

function ContextImpl.Get(self: any, provider: any): any
	checkProvider("Get", provider)
	local value = self._values[provider]
	if value == nil then
		Err.errorBeforeNearest(`Context:Get: no value for {tostring(provider)} — the creator of this Context did not :Set it (use :Peek to test)`, SURFACE)
	end
	return value
end

function ContextImpl.Peek(self: any, provider: any): any
	checkProvider("Peek", provider)
	return self._values[provider]
end

local function Context(): any
	local self = setmetatable({ _values = {} }, ContextImpl)
	ContextBrand:register(self)
	return self
end

Err.setFuncLevel(SURFACE, ContextImpl.Set, ContextImpl.Get, ContextImpl.Peek, Provider) -- `H-231`; `Context` itself is a local direct call inside `__call` (quad-error usage rule: tag only table-field calls) and has no gate

-- callable namespace (the `Tag`/`Attr` idiom — `setmetatable<A, B>` in the types)
local ContextConstructor = setmetatable({ Provider = Provider }, {
	__call = function(_self: any)
		return Context()
	end,
})

return { Context = ContextConstructor }
