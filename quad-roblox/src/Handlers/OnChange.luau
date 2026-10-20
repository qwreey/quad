--!strict
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
	      State<descriptor>,                        -- reactive via StateHandler
	  }

	Descriptor = frozen `{ Name, Callback }`, branded in a module-local
	weak-key set (Brand.luau's shape — quad-roblox never requires quad-base,
	round14 Q3 (a)). No cache, no equality contract: every call is a fresh
	value, so the same name in two array slots binds twice instead of the
	hash-key form's silent last-wins.

	Handler ("OnChange", `NORMAL - 1` — one step below InstanceChild, round10 Q58 (나)): number key ∧ descriptor value
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

-- untagged bodies: the tagged public `OnChange`/`Out` below and the 3.4.0 curried stages (`Surface/Runtime.luau` —
-- a tagged stage calling a tagged factory would blame the stage's line, not the user's) both call these
local function makeOnChange(name: string, fn: (any) -> ()): OnChangeDescriptor
	if type(name) ~= "string" or name == "" then
		-- round3 `H-440` (외부 리뷰 G-10, `H-417` 짝): "" reached `GetPropertyChangedSignal` at dispatch depth
		errNS.errorBeforeNearest("Quad0221 OnChange: property name must be a non-empty string", SURFACE)
	end
	if type(fn) ~= "function" then
		errNS.errorBeforeNearest(`Quad0222 OnChange: callback for "{name}" must be a function (got {typeof(fn)})`, SURFACE)
	end
	local d = table.freeze({ Name = name, Callback = fn })
	descriptors[d] = true
	return (d :: any) :: OnChangeDescriptor
end

-- [2026-09-21 사용자 결정 — `archive/surveys/2026-09-21-upward-flow-plan.md` 8절] `Out(name, src)`: the write-back sugar. A pure
-- factory over `OnChange` — no brand, no handler, nothing here changes. The downward direction stays the
-- ordinary property key (`Text = src`); this is the explicit "out" placed next to it:
--     TextBox { Text = textSrc, Out("Text", textSrc) }
-- `src` must be WRITABLE (a Source — a `:Compute` State has no `Set`; the type carries `Set` so strict
-- rejects it first). Same-value skip is not loop protection (the engine does not fire the changed signal
-- on a same-value re-assignment — `audit/studio-docs-2026-09-10.md` A절) but ECHO protection: the array
-- part connects before the hash part writes, so the initial `Text = src` write reaches this callback with
-- the value `src` already holds, and `Source:Set` emits even for an equal value (`H-68`) — every subscriber
-- of `src` would re-run once per bind. Hence `Source:SetIfChanged` (no write, no emit when `==`).
local isSource: ((any) -> boolean)? = nil
local isState: ((any) -> boolean)? = nil
local function makeOut(name: string, src: any): OnChangeDescriptor
	if type(name) ~= "string" or name == "" then
		errNS.errorBeforeNearest("Quad0223 Out: property name must be a non-empty string", SURFACE)
	end
	if isSource == nil or not isSource(src) then
		local got = if isState ~= nil and isState(src) then "a read-only State (a :Compute result?)" else typeof(src)
		errNS.errorBeforeNearest(`Quad0224 Out: second argument for "{name}" must be a Source to write back into (got {got})`, SURFACE)
	end
	return makeOnChange(name, function(v: any)
		src:SetIfChanged(v) -- the echo skip above (2026-10-01: the opt-in comparing write, same `==`)
	end)
end

local function OnChange(name: string, fn: (any) -> ()): OnChangeDescriptor
	return makeOnChange(name, fn)
end
local function Out(name: string, src: any): OnChangeDescriptor
	return makeOut(name, src)
end

-- [2026-10-06 user decision, round14 Q174 보강 2 (1)] the ONE function the engine's changed signal reaches quad
-- through: it calls the `OnChange` callback (an `Out` callback is one). A write back from there is the engine
-- round trip `docs/reference/core/05` defines as normal (`Text = src` + `Out("Text", src)`; under Immediate
-- signals — and the mock — it runs synchronously inside the property's dispatch), so `install` registers this
-- function as a defined re-entry frame for quad-base's debug feedback check (`Observer.luau` `fedBackDirectly`;
-- read only under `q.debug`). Held in a table field and always called through it (Q174 보강 2 (3)): `-O2`
-- inlines a small local function at its direct call sites, and the frame the check looks for would be gone.
-- [round14 확인 패스 code-review 6] the field call costs one call level even with debug off — kept on purpose: the
-- frame must be the same path always, or `q.debug` turned on after the connection is made would not find it.
local Frames = {}
function Frames.fireOnChange(callback: (any) -> (), inst: any, name: string)
	callback(inst[name])
end

local function install(quad: any)
	local dispatch = quad.Dispatch
	quad._reentryFrames[Frames.fireOnChange] = true
	if errNS == nil then
		errNS = quad.errorNamespace
		errNS.setFuncLevel(SURFACE, OnChange, Out) -- `H-238`: public factories tagged
		isSource = quad.isSource
		isState = quad.isState
	end

	dispatch.addHandler({
		name = "OnChange",
		keyType = "number", -- `H-484`: only number keys can match (isHandlable checks it too)
		isHandlable = function(_inst: any, k: any, v: any): boolean
			return type(k) == "number" and isOnChange(v)
		end,
		-- round10 Q58 (나) (user decision 2026-09-17): one band step below InstanceChild — disjoint
		-- predicates (Instance value vs OnChange marker), offset only to give each its own slot
		-- instead of an undefined-order tie (and the `q.debug` tie line it printed).
		priority = dispatch.HANDLER_PRIORITY_NORMAL - 1,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			-- `H-39`: terminal — no physical element, so the pair is None/0
			quad.Bookkeeping.setEmpty(inst, k, inst)

			local name = v.Name
			local callback = v.Callback :: (any) -> ()
			local connection = inst:GetPropertyChangedSignal(name):Connect(function()
				Frames.fireOnChange(callback, inst, name)
			end)
			return function(_nextValue: any?, _retracting: boolean)
				connection:Disconnect() -- bookkeeping stays None/0 (Tag idiom)
			end
		end,
	} :: QuadTypes.Handler)
end

return {
	OnChange = OnChange,
	Out = Out,
	makeOnChange = makeOnChange, -- untagged (Surface/Runtime.luau)
	makeOut = makeOut,
	isOnChange = isOnChange,
	install = install,
}
