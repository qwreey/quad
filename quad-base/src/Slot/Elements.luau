--!strict
--[[
	Slot/Elements.luau — per-element helpers: destroyElement (the one "this
	element dies" body), wrapElement (the element-type whitelist gate +
	State→wrapper-Slot), unwrapElement, and the collectLeaves/leavesOf flatteners.

	Installed by `Slot/init.luau` with `(S, module)` (see its header for the split
	and the `S` protocol). Behaviour and comments are the moved originals.
]]

local Types = require("./types")
local ModuleIdentity = require("../ModuleIdentity") -- round10 H-537: cross-instance door for Slot/State elements

return function(S: Types.SlotInternal, module: any)

	-- One body for "this element dies": a nested Slot goes through destroySlotTree (recursion),
	-- anything else through the backend's dispose — round3 `H-451` folded the hand copies that
	-- `H-393`/Q14 kept catching one at a time (destroySlotTree loops, releaseElement, detach cleanup).
	local function destroyElement(element: any)
		if S.isSlot(element) then S.destroySlotTree(element) else module.Backend.nativeDispose(element) end
	end

	-- wrap: element-type whitelist gate (H-40) + State→wrapper-Slot. raw* only
	-- ever see already-wrapped physical elements. `raise` is the error depth
	-- the CALLER picks (2순회 `H-375`, checklist 0): `prepareElements` (direct
	-- public CRUD / `Slot{}`) passes `errorBeforeNearest` so a CRUD call made
	-- inside a reactive callback blames its own line, not the `:Set` that ran
	-- the callback; `settle` (reconcile depth) passes `errorBefore`.
	-- [2026-09-16 hunt A] the raw-value gate, shared by wrapElement (raw elements) and
	-- prepareElements (the CURRENT value of a State element) — every arm must fail in the
	-- pre-pass, before rawAdd/rawReplace touch anything (`H-30`/`H-31`, slot-plan "검증을
	-- 선행 패스로"). Before this the isInst/handler-layer/destroyed arms of a State's
	-- occupant were checked inside the wrapper's reconcile — after the insert (ghost
	-- element, Blocker left On; unmounted Slots did not raise at all until drive).
	local function checkRawElement(v: any, raise: (string, any) -> ())
		if module.isRef(v) or module.isPreRef(v) or module.isPostRef(v)
			or module.isObserver(v) or module.isEffect(v) or module.isModifier(v) then
			raise("Slot: handler-layer values (Ref/PreRef/PostRef/Observer/Effect/Modifier) cannot be elements", S.SURFACE)
		end
		if v == nil or v == S.None then
			raise("Slot: nil/None cannot be an element — only actually mountable values", S.SURFACE)
		end
		if not module.Backend.isInst(v) then
			raise("Slot: this backend cannot mount this value", S.SURFACE)
		end
		-- [2026-09-16 사용자 결정 — question.md §2] a foreign element (made outside quad, never
		-- claimed) is rejected here rather than silently accepted: Add only did elementOwner
		-- bookkeeping, so an unclaimed element had no death tracking and any leaf binding on it
		-- died later at bindLifetime (`H-290`). Auto-claiming on Add was rejected as magic —
		-- the user takes ownership first with `Claim` (or builds it with the Declaration).
		if not module.Backend.isClaimed(v) then
			raise("Slot: this element is not claimed by quad — build it with the Declaration or take it over with Claim first", S.SURFACE)
		end
	end
	S.checkRawElement = checkRawElement

	local function wrapElement(v: any, raise: (string, any) -> ()): any
		-- round10 H-537 (code-review 보강): the cross-instance door for Slot/State elements lives HERE so all
		-- three arrivals (CRUD pre-pass, :List reconcile, wrapper Single) pass it once
		if S.isSlot(v) or S.isState(v) then
			ModuleIdentity.assertOwnAtCall(module, v, "Slot")
		end
		if S.isSlot(v) then
			-- round15 `H6-19`: a destroyed Slot must fail HERE (pre-pass), not
			-- inside attachSlot after the array/ownership mutation — otherwise
			-- Splice's batch gate is left On by the raise (통합 리뷰 재현).
			if v._destroyed then
				raise("Slot: destroyed Slot cannot be an element", S.SURFACE)
			end
			return v
		end
		if not S.isState(v) then
			checkRawElement(v, raise)
			return v
		end
		local sub = S.Slot()
		sub:Single(v, nil, { OwnsElements = false })
		sub._wrapped = v
		return sub
	end

	local function unwrapElement(el: any): any
		if el == nil then return nil end
		if S.isSlot(el) then return el._wrapped or el end
		return el
	end

	-- collectLeaves(slot, out?) — flatten the physical leaves a nested Slot
	-- occupies, in order (`H-29`). The native* layer requires "the elements
	-- that leave/move are passed as an array"; a nested-Slot element has no
	-- such array of its own, so reposition/extract paths build it here.
	local function collectLeaves(slot: any, out: { any }?): { any }
		local acc: { any } = out or {}
		for _, element in ipairs(slot._elements) do
			if S.isSlot(element) then collectLeaves(element, acc)
			else table.insert(acc, element) end
		end
		return acc
	end

	-- leavesOf(element): the array a native* op receives for ONE _elements
	-- entry — the element itself, or its flattened leaves if it is a Slot.
	local function leavesOf(element: any): { any }
		return if S.isSlot(element) then collectLeaves(element) else { element }
	end

	S.destroyElement = destroyElement
	S.wrapElement = wrapElement
	S.unwrapElement = unwrapElement
	S.collectLeaves = collectLeaves
	S.leavesOf = leavesOf
end
