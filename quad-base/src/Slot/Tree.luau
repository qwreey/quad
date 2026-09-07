--!strict
--[[
	Slot/Tree.luau — the mount/unmount/destroy tree walks: makeBaseObserver,
	materializeSlotTree / markMountedTree / mountSlotTree / attachSlot (the attach
	3-family) and teardownTree / unmountSlotTree / destroySlotTree, plus
	releaseSugarWrapper.

	Installed by `Slot/init.luau` with `(S, module)` (see its header for the split
	and the `S` protocol). Behaviour and comments are the moved originals — the
	in-file order is the original one (releaseSugarWrapper before teardownTree).
]]

return function(S: any, module: any)
	local BK = S.BK
	local None = S.None
	local isSlot = S.isSlot
	local bindLifetime = S.bindLifetime
	local unbindLifetime = S.unbindLifetime
	local Err = S.Err
	local SURFACE = S.SURFACE

	-- forward decls (mutual recursion)
	-- ⚠️ Forward declarations for the mutually recursive tree functions below —
	-- every bare `function name(...)` further down MUST be listed here: without a
	-- prior `local`, `function name()` is sugar for a GLOBAL assignment (사용자
	-- 실측 2026-09-07, `H-404`). `scripts/test.sh` fails on luau-analyze's
	-- GlobalUsedAsLocal lint so a missing name here cannot slip through.
	local materializeSlotTree, mountSlotTree, markMountedTree, attachSlot, destroySlotTree, unmountSlotTree, teardownTree

	-- ── attach 3-family ────────────────────────────────────────────────
	local function makeBaseObserver(slot: any): any
		return slot.Offset:Observer(function()
			if slot._physicalTarget == nil then return end -- unmaterialized: swallow the install fire
			local bk = BK.getBookkeeping(slot)
			bk.offsetCacheValidUpTo, bk.offsetSetUpTo = 0, 0 -- base changed → all
			S.maybeRecompute(slot, bk)
		end)
	end

	function materializeSlotTree(slot: any, physicalTarget: any, ownerKey: any, position: number)
		if slot._destroyed then Err.errorBefore("Slot: destroyed Slot cannot be mounted", SURFACE) end
		slot._physicalTarget = physicalTarget

		local blocker = BK.getBlocker(slot)
		blocker:On()
		slot._baseObserver._rerunRequired = false
		bindLifetime(physicalTarget, slot._baseObserver)
		BK.setOffsetSource(ownerKey, position, slot.Offset)

		local remountingList = slot._listed and slot._listActivated
		if slot._listed and not slot._listActivated then
			slot:_activateList(physicalTarget) -- initial population — rawAdd registers each slot
		else
			if slot._listed then
				slot:_activateList(physicalTarget) -- remount: anchor only
			end
			for i, element in ipairs(slot._elements) do
				if isSlot(element) then
					materializeSlotTree(element, physicalTarget, slot, i)
				else
					BK.setOffsetSource(slot, i, None)
					BK.setLength(slot, i, 1, physicalTarget, element)
				end
			end
		end
		blocker:OffWithoutEmit()
		S.maybeRecompute(slot, BK.getBookkeeping(slot)) -- the batch gate just opened; only the reentry gate can still hold
		if remountingList and slot._listObserver then
			bindLifetime(physicalTarget, slot._listObserver)
		end
		BK.setLength(ownerKey, position, slot.Length, physicalTarget, slot)
	end

	-- Mounting is two halves (`H6-9` (b), user decision 2026-09-03): the FLAG
	-- walk (recursive `_mounted`/`_mountedInst`) and ONE physical op for the
	-- whole subtree's flattened leaves — never one op per leaf. rawSplice uses
	-- the halves separately to fold several new subtrees into its single op.
	function markMountedTree(slot: any, physicalTarget: any)
		slot._mounted = true
		slot._mountedInst = physicalTarget
		for _, element in ipairs(slot._elements) do
			if isSlot(element) then markMountedTree(element, physicalTarget) end
		end
	end

	function mountSlotTree(slot: any, physicalTarget: any)
		module.nativeInsert(physicalTarget, slot.Offset:Get(), S.collectLeaves(slot))
		markMountedTree(slot, physicalTarget)
	end

	function attachSlot(slot: any, physicalTarget: any, ownerKey: any, position: number, mount: boolean?)
		materializeSlotTree(slot, physicalTarget, ownerKey, position)
		if mount ~= false then
			mountSlotTree(slot, physicalTarget)
		end
	end

	-- releaseSugarWrapper — `H6-12` (b), user decision 2026-09-03 (*"래퍼라서
	-- 문제 되는 부분인지라, 그 부분만 좁게 해결"*). A wrapper Slot minted by
	-- wrapElement (`_wrapped ~= nil`) is discarded the moment it leaves its
	-- outer Slot as an element: the user gets the State back and a re-Add
	-- mints a fresh wrapper. So it must not keep owning the user's instance —
	-- otherwise the next Add(state)/dispose(inst) fails "already mounted"
	-- until GC clears the weak record (the nondeterminism slot-plan forbids).
	-- Portal unmount (State<Slot> swap) and user-made Owned=false lists keep
	-- ownership exactly as before — they are real Slots the user still holds.
	local function releaseSugarWrapper(wrapper: any)
		for _, element in ipairs(wrapper._elements) do
			S.releaseOwner(element, wrapper)
		end
	end

	-- ── destroy / unmount trees ────────────────────────────────────────
	-- Unmounting is two halves, mirroring mounting (`H6-9` (b)): teardownTree
	-- is the LOGICAL half (observers unbound, flags + position bookkeeping
	-- reset, recursively, no physical op); unmountSlotTree adds ONE
	-- nativeExtract of the subtree's flattened leaves. rawSplice calls the
	-- logical half only and folds the leaves into its single op.
	function teardownTree(slot: any)
		for _, element in ipairs(slot._elements) do
			if isSlot(element) then teardownTree(element) end
		end
		local bk = BK.getBookkeeping(slot)
		for _, observer in pairs(bk.observers) do
			unbindLifetime(observer)
		end
		if slot._listObserver then unbindLifetime(slot._listObserver) end
		if slot._detachCleanup then unbindLifetime(slot._detachCleanup) end
		unbindLifetime(slot._baseObserver)
		slot._mounted, slot._mountedInst = false, nil
		slot._physicalTarget = nil
		-- round15 `H6-19` (통합 리뷰 재현): restore the UNMATERIALIZED invariant.
		-- Position bookkeeping (lengthList/sourceList/observers/N + offset cache)
		-- is rebuilt from scratch by the next materializeSlotTree, and CRUD while
		-- unmounted maintains only _elements/indexOfElement — a stale `N` from the
		-- old mount would make the next recompute walk positions that no longer
		-- exist (inflated Length, wrong sibling offsets). `bk` itself, its
		-- indexOfElement and recomputeBlocker survive (`H-232` remount contract).
		bk.lengthList, bk.sourceList, bk.observers, bk.N = {}, {}, {}, nil
		bk.offsetCache = {}
		bk.offsetCacheValidUpTo, bk.offsetSetUpTo = 0, 0
	end

	function unmountSlotTree(slot: any)
		if slot._mounted then
			module.nativeExtract(slot._mountedInst, slot.Offset:Get(), S.collectLeaves(slot))
		end
		teardownTree(slot)
	end

	function destroySlotTree(slot: any)
		if slot._destroyed then return end
		if slot._owned == false then
			unmountSlotTree(slot)
			-- a sugar wrapper asked to die leaves its user's instance alive AND
			-- unclaimed (`H6-12` (b)); a user-made Owned=false list keeps its claims
			if slot._wrapped ~= nil then releaseSugarWrapper(slot) end
			return
		end
		-- Q14 (a) (사용자 결정 2026-09-07): release ownership in BOTH loops — an `Owned = false`
		-- element Slot survives `destroySlotTree` (unmount-only branch above) and kept a dead
		-- `elementOwner` forever ("already mounted elsewhere" on its next Add). Destroyed
		-- elements do not care (weak registry). The C-4 exemption assumed every element dies.
		for _, element in ipairs(slot._elements) do
			S.releaseOwner(element, slot)
			S.destroyElement(element)
		end
		if slot._detached then
			for key, element in pairs(slot._detached) do
				S.releaseOwner(element, slot)
				S.destroyElement(element)
				slot._detached[key] = nil
			end
		end
		if slot._detachCleanup then
			unbindLifetime(slot._detachCleanup)
			slot._detachCleanup = nil
		end
		if slot._listObserver then unbindLifetime(slot._listObserver) end
		unbindLifetime(slot._baseObserver)
		local bk = BK.getBookkeeping(slot)
		for _, observer in pairs(bk.observers) do
			unbindLifetime(observer)
		end
		slot._mounted, slot._mountedInst = false, nil
		slot._physicalTarget = nil
		slot._destroyed = true
	end

	S.makeBaseObserver = makeBaseObserver
	S.materializeSlotTree = materializeSlotTree
	S.markMountedTree = markMountedTree
	S.mountSlotTree = mountSlotTree
	S.attachSlot = attachSlot
	S.releaseSugarWrapper = releaseSugarWrapper
	S.teardownTree = teardownTree
	S.unmountSlotTree = unmountSlotTree
	S.destroySlotTree = destroySlotTree
end
