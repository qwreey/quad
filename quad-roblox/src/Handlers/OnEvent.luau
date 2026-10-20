--!strict
--[[
	OnEvent — an engine event binding as an ARRAY-PART VALUE (3.4.0): `q.OnEvent "Frame" "MouseEnter" (fn)` returns a
	descriptor the children array carries, the event twin of `OnChange` (same shape, same handler idiom — this file
	mirrors `Handlers/OnChange.luau`; the hash-key form `MouseEnter = fn` stays and is `Handlers/Event.luau`).
	Canon: `.claude/research/declaration-surface-plan.md` 5절 (OnEvent 디스크립터); plan `release-3.4.0-plan.md` 단위 4.

	Why a descriptor beside the hash key: several bindings of the same event in one element (a hook's `MouseLeave`
	and the element's own) — hash keys collide (a Spread keeps the first one in place), descriptors never do: every
	call is a fresh value and binds once per array slot.

	Descriptor = frozen `{ Event, Callback }` in a module-local weak-key set (quad-roblox never requires quad-base).
	Handler ("OnEvent", `NORMAL - 2` — below OnChange's `NORMAL - 1`, disjoint predicates, own slot instead of a tie;
	round10 Q58 (나) idiom): number key ∧ descriptor → `inst[event]:Connect(callback)`, retractor disconnects. Terminal,
	`setEmpty` like OnChange. An unknown event name raises the engine's own error inside process (the typed surface
	rejects it first).
]]

local QuadTypes = require("../../luau_packages/quad_types")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local errNS: any = nil

local descriptors = setmetatable({} :: { [any]: true }, { __mode = "k" })

local function isOnEvent(x: any): boolean
	return descriptors[x] == true
end

-- untagged on purpose: only the tagged curried stage in `Surface/Runtime.luau` calls it (a tagged stage calling a
-- tagged factory would blame the stage's line)
local function OnEvent(name: any, fn: any): any
	if type(name) ~= "string" or name == "" then
		errNS.errorBeforeNearest("Quad0279 OnEvent: event name must be a non-empty string", SURFACE)
	end
	if type(fn) ~= "function" then
		errNS.errorBeforeNearest(`Quad0280 OnEvent: callback for "{name}" must be a function (got {typeof(fn)})`, SURFACE)
	end
	local d = table.freeze({ Event = name, Callback = fn, __quadEvent = name })
	descriptors[d] = true
	return d
end

local function install(quad: any)
	local dispatch = quad.Dispatch
	if errNS == nil then
		errNS = quad.errorNamespace
	end
	dispatch.addHandler({
		name = "OnEvent",
		keyType = "number",
		isHandlable = function(_inst: any, k: any, v: any): boolean
			return type(k) == "number" and isOnEvent(v)
		end,
		priority = dispatch.HANDLER_PRIORITY_NORMAL - 2,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			quad.Bookkeeping.setEmpty(inst, k, inst) -- terminal: no physical element (`H-39`)
			local connection = inst[v.Event]:Connect(v.Callback)
			return function(_nextValue: any?, _retracting: boolean)
				connection:Disconnect()
			end
		end,
	} :: QuadTypes.Handler)
end

return {
	OnEvent = OnEvent,
	isOnEvent = isOnEvent,
	install = install,
}
