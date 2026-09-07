--[[
	AttrKey — the single-key attribute primitive + its name-claim handler
	(M10, spike round16; 옛 `Attribute/Key.luau` — the 2026-09-08 `Attr` rename,
	see init.luau's header). Canonical: `.claude/base/attribute-plan.md` ("단일
	키", "동등성", "메커니즘, `None`, 반환 클로저", "이름 소유권"), as-is.

	  AttrKey(name) -> key            -- per-name weak cache: same name =
	                                       -- same object while anything holds it

	[2026-09-03 사용자 확정] AttrKey is the UNTYPED primitive (`[AttrKey
	"x"] = v` — the value's type is not checked, "타입이 몰라도 되는 존재");
	the typed scalar family `StringAttr(name, value)` etc. is array-part
	SUGAR over the group (`Attr({ [name] = value })`) and lives in
	Attr/init.luau — the old aliases (`StringAttr = AttrKey`) are
	gone. Use AttrKey directly for value types the family does not cover
	(engine-specific: Color3, UDim2, Instance …); the backend's setAttr is
	what validates the value then.

	Handler ("AttrKeyFallbackHandler", FALLBACK priority, registered by
	InitAttrKey — `H-278` idiom, see Tag.luau header): matches on the KEY
	being an AttrKey object (hash part; v may be anything including nil).
	process = unconditional `setAttr(inst, key.Name, v)` + the name claim
	(`nameClaims`: (inst, name) -> owning key object; a different key claiming
	the same name is an immediate error). The retractor NEVER calls
	setAttr — it only returns the claim, and only when this key still
	owns it ("내가 실제로 물러날 때만").

	`_newUncachedKey(name)` is the group delegation's private key factory
	(attribute-plan "이름 소유권" 1번 — group keys must be DISTINCT objects
	from the public cached key so cross-owner retraction is structurally
	impossible). Internal only — never exposed on the module surface.
]]

local Brand = require("../Brand")
local Relate = require("../Relate")
local QuadTypes = require("../../luau_packages/quad_types")
local Err = require("../ErrorNamespace")
local NotInstalled = require("../NotInstalled")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local AttrKeyBrand = Brand.AttrKeyBrand
local isAttrKey = Brand.isAttrKey

local function newKeyObject(name: string): any
	local key = table.freeze({ Name = name })
	AttrKeyBrand:register(key)
	return key
end

-- Public path: per-name weak cache (values weak — alive while anything holds
-- the key; a fully retracted name falls out and a later call mints a fresh
-- object nobody can compare against, which is fine — attribute-plan "동등성").
local cache = setmetatable({} :: { [string]: any }, { __mode = "v" })

local function AttrKey(name: string): any
	if type(name) ~= "string" or name == "" then -- `H-417`: an empty name is not an attribute name either
		Err.errorBeforeNearest("AttrKey: name must be a non-empty string", SURFACE)
	end
	local cached = cache[name]
	if cached ~= nil then
		return cached
	end
	local key = newKeyObject(name)
	cache[name] = key
	return key
end
-- `H-238`: public constructor tagged (the scalar sugar family lives in
-- Attr/init.luau and tags itself there)
Err.setFuncLevel(SURFACE, AttrKey)

local module = {
	AttrKey = AttrKey,
	_newUncachedKey = newKeyObject, -- group delegation only (private)
}

-- the loud stub factory (`NotInstalled.luau` — one body for the three modules, Q3 ②)
local function notInstalled(name: string): (...any) -> ...any
	return NotInstalled(name, "the attribute op")
end

local InitDispatch = require("../Dispatch")

function module.Init(quad: any)
	quad.AttrKey = AttrKey
	if quad.setAttr == nil then
		quad.setAttr = notInstalled("setAttr")
	end

	quad:RunInit(InitDispatch)
	local dispatch: QuadTypes.Dispatch = quad.Dispatch

	-- (inst(weak), name) -> the key object currently claiming that name.
	-- Strong values: the claim must outlive GC pressure while bound; released
	-- explicitly by the retractor (attribute-plan "이름 소유권" 2번).
	local nameClaims = Relate()

	dispatch.addHandler({
		name = "AttrKeyFallbackHandler",
		isHandlable = function(_inst: any, k: any, _v: any): boolean
			-- KEY-matched: hash-part nil belongs to the key's own handler
			-- (None.luau header) — v is deliberately not inspected
			return isAttrKey(k)
		end,
		priority = dispatch.HANDLER_PRIORITY_FALLBACK,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			local cur = nameClaims:GetStrong(inst, k.Name)
			if cur ~= nil and cur ~= k then
				-- domain-language error (attribute-plan "에러 메시지는 도메인
				-- 언어로"); outermost blame so the user's line is charged even
				-- through group delegation (`H-272` reasoning)
				Err.errorBefore(`AttrKey: attribute "{k.Name}" is already bound by another owner`, SURFACE)
			end
			nameClaims:SetStrong(inst, k.Name, k)

			quad.setAttr(inst, k.Name, v) -- unconditional, nil included (late read `H-174`)

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
