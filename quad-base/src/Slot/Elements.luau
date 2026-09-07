--!strict
--[[
	Slot/Elements.luau — per-element helpers: destroyElement (the one "this
	element dies" body), wrapElement (the element-type whitelist gate +
	State→wrapper-Slot), unwrapElement, and the collectLeaves/leavesOf flatteners.

	Installed by `Slot/init.luau` with `(S, module)` (see its header for the split
	and the `S` protocol). Behaviour and comments are the moved originals.
]]

return function(S: any, module: any)
	local isSlot = S.isSlot
	local isState = S.isState
	local isInst = S.isInst
	local None = S.None
	local SURFACE = S.SURFACE

	-- One body for "this element dies": a nested Slot goes through destroySlotTree (recursion),
	-- anything else through the backend's dispose — round3 `H-451` folded the hand copies that
	-- `H-393`/Q14 kept catching one at a time (destroySlotTree loops, releaseElement, detach cleanup).
	local function destroyElement(element: any)
		if isSlot(element) then S.destroySlotTree(element) else module.nativeDispose(element) end
	end

	-- wrap: element-type whitelist gate (H-40) + State→wrapper-Slot. raw* only
	-- ever see already-wrapped physical elements. `raise` is the error depth
	-- the CALLER picks (2순회 `H-375`, checklist 0): `prepareElements` (direct
	-- public CRUD / `Slot{}`) passes `errorBeforeNearest` so a CRUD call made
	-- inside a reactive callback blames its own line, not the `:Set` that ran
	-- the callback; `settle` (reconcile depth) passes `errorBefore`.
	local function wrapElement(v: any, raise: (string, any) -> ()): any
		if isSlot(v) then
			-- round15 `H6-19`: a destroyed Slot must fail HERE (pre-pass), not
			-- inside attachSlot after the array/ownership mutation — otherwise
			-- Splice's batch gate is left On by the raise (통합 리뷰 재현).
			if v._destroyed then
				raise("Slot: destroyed Slot cannot be an element", SURFACE)
			end
			return v
		end
		if not isState(v) then
			if module.isRef(v) or module.isPreRef(v) or module.isPostRef(v)
				or module.isObserver(v) or module.isEffect(v) or module.isModifier(v) then
				raise("Slot: handler-layer values (Ref/PreRef/PostRef/Observer/Effect/Modifier) cannot be elements", SURFACE)
			end
			if v == nil or v == None then
				raise("Slot: nil/None cannot be an element — only actually mountable values", SURFACE)
			end
			if not isInst(v) then
				raise("Slot: this backend cannot mount this value", SURFACE)
			end
			return v
		end
		local sub = S.Slot()
		sub:Single(v, nil, { Owned = false })
		sub._wrapped = v
		return sub
	end

	local function unwrapElement(el: any): any
		if el == nil then return nil end
		if isSlot(el) then return el._wrapped or el end
		return el
	end

	-- collectLeaves(slot, out?) — flatten the physical leaves a nested Slot
	-- occupies, in order (`H-29`). The native* layer requires "the elements
	-- that leave/move are passed as an array"; a nested-Slot element has no
	-- such array of its own, so reposition/extract paths build it here.
	local function collectLeaves(slot: any, out: { any }?): { any }
		local acc: { any } = out or {}
		for _, element in ipairs(slot._elements) do
			if isSlot(element) then collectLeaves(element, acc)
			else table.insert(acc, element) end
		end
		return acc
	end

	-- leavesOf(element): the array a native* op receives for ONE _elements
	-- entry — the element itself, or its flattened leaves if it is a Slot.
	local function leavesOf(element: any): { any }
		return if isSlot(element) then collectLeaves(element) else { element }
	end

	S.destroyElement = destroyElement
	S.wrapElement = wrapElement
	S.unwrapElement = unwrapElement
	S.collectLeaves = collectLeaves
	S.leavesOf = leavesOf
end
