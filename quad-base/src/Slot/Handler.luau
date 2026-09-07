--!strict
--[[
	SlotHandler — the top-level dispatch path for a Slot placed at a children
	array slot (`base/slot-plan.md` "Slot과 Store 바인드의 관계"). base owns the
	reconciliation; the actual Parent ops are the injected native* layer.

	[M6 fork, H6] `register(dispatch, module)` is called by Slot.Init (the
	owning module — `H-278`), after `module._slotInternal` and `module.Dispatch`
	both exist. None.luau's register(dispatch) is the shape precedent.
]]

local QuadTypes = require("../../luau_packages/quad_types")
local Err = require("../ErrorNamespace")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local function register(dispatch: any, module: any)
	local internal = module._slotInternal -- the five-key surface init exposes (not the split's `S`)
	dispatch.addHandler({
		name = "SlotHandler",
		isHandlable = function(_inst: any, k: any, v: any): boolean
			-- `H-52` array-position guard (Tag/Attr handlers do the same):
			-- a Slot at a NAME key must not match — otherwise claim/bindLifetime
			-- commit before Bookkeeping.checkPosition throws an internal error
			-- and the ownership/lifetime bind is orphaned (통합 리뷰 발견)
			return type(k) == "number" and internal.isSlot(v)
		end,
		priority = dispatch.HANDLER_PRIORITY_HIGH,
		process = function(inst: any, k: any, slotValue: any, _index: number): (any?, boolean) -> ()
			-- 6순회 `H-407`: the `H6-19` pre-pass, top-level twin — a destroyed Slot
			-- must fail BEFORE `claimOwnerAt`/`bindLifetime` commit, or the corpse is
			-- owned by `inst` for good (the `H-103` NOOP retractor never releases it)
			if slotValue._destroyed then
				Err.errorBefore("Slot: destroyed Slot cannot be mounted", SURFACE)
			end
			if internal.claimOwnerAt(slotValue, inst, k) then
				module.bindLifetime(inst, slotValue)
				internal.attachSlot(slotValue, inst, inst, k)
			end
			return function(nextValue: any, _retracting: boolean)
				-- nextValue is nil or a Slot the same handler will process (typed)
				if slotValue == nextValue then return end
				internal.unmountSlotTree(slotValue)
				dispatch.setEmpty(inst, k) -- `H-39` (한 본문 — Bookkeeping `setEmpty`)
				module.unbindLifetime(slotValue)
				internal.releaseOwner(slotValue, inst)
			end
		end,
	} :: QuadTypes.Handler)
end

return { register = register }
