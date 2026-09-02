--[[
	AttributeKey — the single-key attribute primitive + its name-claim handler
	(M10, spike round16). Canonical: `.claude/base/attribute-plan.md` ("단일
	키", "동등성", "메커니즘, `None`, 반환 클로저", "이름 소유권"), as-is.

	  AttributeKey(name) -> key            -- per-name weak cache: same name =
	                                       -- same object while anything holds it
	  StringAttribute / NumberAttribute / BooleanAttribute
	                                       -- scalar convenience family — SAME
	                                       -- cache, runtime-identical objects
	                                       -- (the generic parameter is purely
	                                       -- static; engine-specific families
	                                       -- like Color3Attribute live in the
	                                       -- backend's D layer, not here)

	Handler ("AttributeKeyFallbackHandler", FALLBACK priority, registered by
	InitAttributeKey — `H-278` idiom, see Tag.luau header): matches on the KEY
	being an AttributeKey object (hash part; v may be anything including nil).
	process = unconditional `setAttribute(inst, key.Name, v)` + the name claim
	(`nameClaims`: (inst, name) -> owning key object; a different key claiming
	the same name is an immediate error). The retractor NEVER calls
	setAttribute — it only returns the claim, and only when this key still
	owns it ("내가 실제로 물러날 때만").

	`_newUncachedKey(name)` is the group delegation's private key factory
	(attribute-plan "이름 소유권" 1번 — group keys must be DISTINCT objects
	from the public cached key so cross-owner retraction is structurally
	impossible). Internal only — never exposed on the module surface.
]]

local Brand = require("./Brand")
local Relate = require("./Relate")
local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local AttributeKeyBrand = Brand.AttributeKeyBrand
local isAttributeKey = Brand.isAttributeKey

local function newKeyObject(name: string): any
	local key = table.freeze({ Name = name })
	AttributeKeyBrand:register(key)
	return key
end

-- Public path: per-name weak cache (values weak — alive while anything holds
-- the key; a fully retracted name falls out and a later call mints a fresh
-- object nobody can compare against, which is fine — attribute-plan "동등성").
local cache = setmetatable({} :: { [string]: any }, { __mode = "v" })

local function AttributeKey(name: string): any
	if type(name) ~= "string" then
		Err.errorBeforeNearest("AttributeKey: name must be a string", SURFACE)
	end
	local cached = cache[name]
	if cached ~= nil then
		return cached
	end
	local key = newKeyObject(name)
	cache[name] = key
	return key
end
-- `H-238`: public constructor tagged (aliases share the same function object)
Err.setFuncLevel(AttributeKey, SURFACE)

local module = {
	AttributeKey = AttributeKey,
	-- runtime-identical aliases (same cache, same objects) — the generic/type
	-- distinction is purely static (attribute-plan "동등성" 1번 bullet)
	StringAttribute = AttributeKey,
	NumberAttribute = AttributeKey,
	BooleanAttribute = AttributeKey,
	_newUncachedKey = newKeyObject, -- group delegation only (private)
}

local function notInstalled(name: string): (...any) -> ...any
	local stub = function(...: any)
		-- errorBefore (outermost), not Nearest: these stubs are reached from
		-- dispatch depth (handler process), so the nearest tagged frame is the
		-- stub itself and Nearest would blame quad internals (`H-272` reasoning)
		Err.errorBefore(
			`quad: {name} is not available — no backend has installed the attribute op `
				.. "(quad-roblox does this in M10; tests use mock.installTagAttributeOps)",
			SURFACE
		)
	end
	Err.setFuncLevel(stub, SURFACE)
	return stub
end

local InitDispatch = require("./Dispatch")

function module.Init(quad: any)
	quad.AttributeKey = AttributeKey
	quad.StringAttribute = AttributeKey
	quad.NumberAttribute = AttributeKey
	quad.BooleanAttribute = AttributeKey
	if quad.setAttribute == nil then
		quad.setAttribute = notInstalled("setAttribute")
	end

	quad:RunInit(InitDispatch)
	local dispatch: QuadTypes.Dispatch = quad.Dispatch

	-- (inst(weak), name) -> the key object currently claiming that name.
	-- Strong values: the claim must outlive GC pressure while bound; released
	-- explicitly by the retractor (attribute-plan "이름 소유권" 2번).
	local nameClaims = Relate()

	dispatch.addHandler({
		name = "AttributeKeyFallbackHandler",
		isHandlable = function(_inst: any, k: any, _v: any): boolean
			-- KEY-matched: hash-part nil belongs to the key's own handler
			-- (None.luau header) — v is deliberately not inspected
			return isAttributeKey(k)
		end,
		priority = dispatch.HANDLER_PRIORITY_FALLBACK,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			local cur = nameClaims:GetStrong(inst, k.Name)
			if cur ~= nil and cur ~= k then
				-- domain-language error (attribute-plan "에러 메시지는 도메인
				-- 언어로"); outermost blame so the user's line is charged even
				-- through group delegation (`H-272` reasoning)
				Err.errorBefore(`attribute "{k.Name}" is already bound by another owner`, SURFACE)
			end
			nameClaims:SetStrong(inst, k.Name, k)

			quad.setAttribute(inst, k.Name, v) -- unconditional, nil included (late read `H-174`)

			return function(_nextValue: any?, _retracting: boolean)
				-- no engine side effect — claim return only, and only while we
				-- still own it (checklist 4번: "내가 실제로 물러날 때만")
				if nameClaims:GetStrong(inst, k.Name) == k then
					nameClaims:SetStrong(inst, k.Name, nil)
				end
			end
		end,
	} :: QuadTypes.Handler)
end

return module
