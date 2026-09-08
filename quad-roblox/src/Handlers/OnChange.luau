--[[
	OnChange — the `GetPropertyChangedSignal` binding as an ARRAY-PART VALUE:
	`OnChange(propertyName, fn)` returns a descriptor the children array
	carries, like `Tag(...)` and the lifecycle hooks (`base/onchange-plan.md`
	"확정" 절, as-is — the 2026-09-03 reversal from the hash-key form
	`[OnChange "x"] = fn`, `archive/onchange-hash-key-reversed.md`).
	quad-roblox-owned because the signal lookup itself is the logic
	(`architecture.md` "패키지 경계" 분할 기준).

	  Frame {
	      Text = "a",
	      OnChange("Text", function(v: string) ... end),
	      OnChange("Text", function(v) ... end),   -- same name twice is fine
	      State<descriptor>,                        -- reactive via StoreBind
	  }

	Descriptor = frozen `{ Name, Callback }`, branded in a module-local
	weak-key set (Brand.luau's shape — quad-roblox never requires quad-base,
	round14 Q3 (a)). No cache, no equality contract: every call is a fresh
	value, so the same name in two array slots binds twice instead of the
	hash-key form's silent last-wins.

	Handler ("OnChange", NORMAL priority): number key ∧ descriptor value
	(`H-52` key guard). Terminal ⇒ registers its array position (`H-39`) as
	None/0 like TagFallbackHandler — no physical element. process connects
	`inst:GetPropertyChangedSignal(name):Connect(function() fn(inst[name]) end)`
	and the retractor closes over the Connection and disconnects it. The
	array part is driven BEFORE the hash part (`F-4-1`), so the binding is
	live when the same props' property writes land — the "초기값 발화"
	contract (onchange-plan; under Deferred signals that is one delivery per
	write, reading the value at delivery time).

	No `v == nil` case here (`H-27` is moot in this shape — a `None`/`nil`
	array element goes to NoneHandler/NilHandler, never to this handler), no
	same-value dedup (`Connect` is not idempotent — Handlers/Event.luau
	reasoning), no property-membership check (an unknown name raises the
	engine's own error inside process — the generated `OnChangeFn` type
	catches it statically first, D/init.luau).

	Typing lives in the GENERATED file: `PropTypes` (property name → type
	across the D scope — the READ surface `PropTypesRead` since Q19, 2026-09-07),
	`OnChangeFn = <K>(name: K & keyof<PropTypesRead>,
	fn: (index<PropTypesRead, K>) -> ()) -> …` — `RobloxExtension.OnChange`
	carries that type over this untyped runtime (luau-test `30`).
]]

local QuadTypes = require("../../luau_packages/quad_types")
local Types = require("../types")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

export type OnChangeDescriptor = Types.OnChangeDescriptor

-- error namespace of the (first) installing quad — the factory is
-- module-level and only reachable through an installed quad (`q.OnChange`)
local errNS: any = nil

local descriptors = setmetatable({} :: { [any]: true }, { __mode = "k" })

local function isOnChange(x: any): boolean
	return descriptors[x] == true
end

local function OnChange(name: string, fn: (any) -> ()): OnChangeDescriptor
	if type(name) ~= "string" or name == "" then
		-- round3 `H-440` (외부 리뷰 G-10, `H-417` 짝): "" reached `GetPropertyChangedSignal` at dispatch depth
		errNS.errorBeforeNearest("OnChange: property name must be a non-empty string", SURFACE)
	end
	if type(fn) ~= "function" then
		errNS.errorBeforeNearest(`OnChange: callback for "{name}" must be a function (got {typeof(fn)})`, SURFACE)
	end
	local d = table.freeze({ Name = name, Callback = fn })
	descriptors[d] = true
	return (d :: any) :: OnChangeDescriptor
end

local function install(quad: any)
	local dispatch = quad.Dispatch
	if errNS == nil then
		errNS = quad.errorNamespace
		errNS.setFuncLevel(SURFACE, OnChange) -- `H-238`: public factory tagged
	end

	dispatch.addHandler({
		name = "OnChange",
		keyType = "number", -- `H-484`: only number keys can match (isHandlable checks it too)
		isHandlable = function(_inst: any, k: any, v: any): boolean
			return type(k) == "number" and isOnChange(v)
		end,
		priority = dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			-- `H-39`: terminal — no physical element, so the pair is None/0
			dispatch.setEmpty(inst, k, inst)

			local name = v.Name
			local callback = v.Callback :: (any) -> ()
			local connection = inst:GetPropertyChangedSignal(name):Connect(function()
				callback(inst[name])
			end)
			return function(_nextValue: any?, _retracting: boolean)
				connection:Disconnect() -- bookkeeping stays None/0 (Tag idiom)
			end
		end,
	} :: QuadTypes.Handler)
end

return {
	OnChange = OnChange,
	isOnChange = isOnChange,
	install = install,
}
