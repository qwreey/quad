--[[
	ObserverEffectLeafHandler + the two dynamic-path guards (M3 unit 4).
	Sources, as-is:
	  - `source-state-plan.md` "Observer/Effect Leaf dedup" — the handler
	    pseudocode (H-39 position registration, `old ~= v` dedup via a weak
	    Relate (`H-71`), swap-retract runs the Effect's cleanup (`H-57`)).
	  - `source-state-plan.md` / `effect-plan.md` "동적 경로 가드" — the two
	    FALLBACK guards (k-agnostic match, error message carries typeof(k) —
	    2026-08-18 user requirement, message text verbatim). FALLBACK so a
	    backend can override the named-slot meaning with a plain-priority
	    handler; the leaf handler itself is dispatch skeleton and sits in the
	    HIGH band ("`HANDLER_PRIORITY_FALLBACK` — 최하위 밴드" 절 names `Leaf`
	    alongside StoreBind/NoneHandler as NOT-fallback).

	The guards raise via the outermost surface scan (`errorBefore`) — same
	reasoning as the match-failure path (`H-219`): the mistake is the user's
	props shape, and the nearest tagged frame here is the guard itself (its
	caller is Dispatch internals, not user code), so nearest-blame would point
	inward. Outermost climbs through process/drive to the user's entry.
]]

local Relate = require("../Relate")
local Void = require("../Void")
local Brand = require("../Brand")
local Err = require("../ErrorNamespace")
local None = require("./None").None
local QuadTypes = require("../../luau_packages/quad_types")

local module = {}

-- Called by InitDispatch once per module instance (same shape as
-- None.register, `H-253`/`H-259`). Needs `module` too: bindLifetime/
-- unbindLifetime are backend-installed later, so they are read off the module
-- at call time, never captured.
function module.register(dispatch: QuadTypes.Dispatch, quad: any)
	-- (inst, k) -> last bound value. Weak value (`H-71`): the observer's fn
	-- may capture inst, so a strong slot would back-reference the weak key
	-- and leak; v is strongly held by gchold while bound, so the entry cannot
	-- fall out early during the window dedup actually matters in.
	local relate = Relate()

	dispatch.addHandler({
		name = "ObserverEffectLeafHandler",
		isHandlable = function(_inst: any, k: any, v: any): boolean
			-- k type check is mandatory — without it this handler outmatches
			-- the named-slot guards below and they become dead code
			return type(k) == "number" and (Brand.isObserver(v) or Brand.isEffect(v))
		end,
		priority = dispatch.HANDLER_PRIORITY_HIGH,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			-- `H-39`: terminal handlers register their array position — this
			-- leaf contributes no physical element, so the pair is None/0.
			-- Constant length → no element argument (Q3), anchor defaults to
			-- the ownerKey itself (C-4 — only Slot owners pass it).
			dispatch.setOffsetSource(inst, k, None)
			dispatch.setLength(inst, k, 0)

			local old = relate:GetWeak(inst, k) -- read Weak to match the SetWeak write (`H-71`)
			if old ~= v then
				quad.bindLifetime(inst, v)
			end
			relate:SetWeak(inst, k, v)
			return function(nextValue: any?)
				if nextValue ~= v then
					quad.unbindLifetime(v)
					-- `H-57`: value-swap retract is destruction-equivalent for
					-- an Effect (it never comes back) — consume its cleanup.
					if Brand.isEffect(v) then
						v:_consumeCleanup()
					end
					-- Clear only when we actually stand down — unconditional
					-- clearing would kill the dedup on spurious re-emits
					-- (nextValue == v), the exact RefLeafHandler bug.
					if relate:GetWeak(inst, k) == v then
						relate:SetWeak(inst, k, nil)
					end
				end
			end
		end,
	})

	-- The two named-slot guards: an Observer/Effect that flows into a hash
	-- key (a type-bypass bug like `MyThing = someObserver`) must fail with a
	-- message the user can tell apart from "provider not initialized".
	dispatch.addHandler({
		name = "ObserverDynamicPathGuard",
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return Brand.isObserver(v)
		end,
		priority = dispatch.HANDLER_PRIORITY_FALLBACK,
		process = function(_inst: any, k: any, _v: any, _index: number): (any?, boolean) -> ()
			Err.errorBefore(`Ref/Observer binding should be array index item, but got {typeof(k)}`, QuadTypes.ERROR_LEVEL_SURFACE)
			return Void -- unreachable; keeps the contract type
		end,
	})
	dispatch.addHandler({
		name = "EffectDynamicPathGuard",
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return Brand.isEffect(v)
		end,
		priority = dispatch.HANDLER_PRIORITY_FALLBACK,
		process = function(_inst: any, k: any, _v: any, _index: number): (any?, boolean) -> ()
			Err.errorBefore(`Effect binding should be array index item, but got {typeof(k)}`, QuadTypes.ERROR_LEVEL_SURFACE)
			return Void -- unreachable; keeps the contract type
		end,
	})
end

return module
