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

local function register(dispatch: any, module: any)
	local S = module._slotInternal
	dispatch.addHandler({
		name = "SlotHandler",
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return S.isSlot(v)
		end,
		priority = dispatch.HANDLER_PRIORITY_HIGH,
		process = function(inst: any, k: any, slotValue: any, _index: number): (any?, boolean) -> ()
			if S.claimOwnerAt(slotValue, inst, k) then
				module.bindLifetime(inst, slotValue)
				S.attachSlot(slotValue, inst, inst, k)
			end
			return function(nextValue: any, _retracting: boolean)
				-- nextValue is nil or a Slot the same handler will process (typed)
				if slotValue == nextValue then return end
				S.unmountSlotTree(slotValue)
				dispatch.setOffsetSource(inst, k, module.None)
				dispatch.setLength(inst, k, 0)
				module.unbindLifetime(slotValue)
				S.releaseOwner(slotValue, inst)
			end
		end,
	} :: QuadTypes.Handler)
end

return { register = register }
