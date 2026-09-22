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

local Types = require("./types")

return function(S: Types.SlotInternal, module: any)

	-- No forward declarations here (round3 §9 `H-461`): after the split every tree
	-- function is defined before its first same-file use (cross-file calls go through
	-- `S.`), so each is a plain `local function`. The `H-404` rule still applies —
	-- a bare `function name()` without a prior `local` is a GLOBAL assignment and
	-- `scripts/test.sh` fails on the GlobalUsedAsLocal lint (see `Slot/init.luau`).

	-- ── attach 3-family ────────────────────────────────────────────────
	local function makeBaseObserver(slot: any): any
		return slot.Offset:Observer(function()
			if slot._physicalTarget == nil then return end -- unmaterialized: swallow the install fire
			local bk = S.BK.getBookkeeping(slot)
			bk.offsetCacheValidUpTo, bk.offsetSetUpTo = 0, 0 -- base changed → all
			S.maybeRecompute(slot, bk)
		end)
	end

	local function materializeSlotTree(slot: any, physicalTarget: any, ownerKey: any, position: number)
		if slot._destroyed then S.Err.errorBefore("Quad0164 Slot: destroyed Slot cannot be mounted", S.SURFACE) end
		slot._physicalTarget = physicalTarget
		-- round10 Q52 (a) (user decision 2026-09-17): while this walk runs, public CRUD (and
		-- :List/:Single install) on THIS Slot raises — a nested :List's first `updateFn` (or an
		-- Observer fired by the recompute below) that mutated an ancestor used to break the
		-- `ipairs` walk (`bindLifetime: already bound`, bookkeeping gone for good). Ancestors on
		-- the walk stack all carry the flag; siblings not on it are untouched. No unwinding
		-- (architecture "예외 안전성 계약"): a throw mid-walk leaves the flag up along with the
		-- open blocker — the tree was already unrecoverable there.
		slot._materializing = true

		local blocker = S.BK.getBlocker(slot)
		blocker:On()
		slot._baseObserver._rerunRequired = false
		module.Backend.bindLifetime(physicalTarget, slot._baseObserver)
		S.BK.setOffsetSource(ownerKey, position, slot.Offset)

		local remountingList = slot._listed and slot._listActivated
		if slot._listed and not slot._listActivated then
			slot:_activateList(physicalTarget) -- initial population — rawAdd registers each slot
		else
			if slot._listed then
				slot:_activateList(physicalTarget) -- remount: anchor only
			end
			for i, element in ipairs(slot._elements) do
				if S.isSlot(element) then
					materializeSlotTree(element, physicalTarget, slot, i)
				else
					S.BK.setOffsetSource(slot, i, S.None)
					S.BK.setLength(slot, i, 1, physicalTarget, element)
				end
			end
		end
		blocker:OffWithoutEmit()
		S.maybeRecompute(slot, S.BK.getBookkeeping(slot)) -- the batch gate just opened; only the reentry gate can still hold
		if remountingList and slot._listObserver then
			module.Backend.bindLifetime(physicalTarget, slot._listObserver)
		end
		S.BK.setLength(ownerKey, position, slot.Length, physicalTarget, slot)
		slot._materializing = false
	end

	-- Mounting is two halves (`H6-9` (b), user decision 2026-09-03): the FLAG
	-- walk (recursive `_mounted`/`_mountedInst`) and ONE physical op for the
	-- whole subtree's flattened leaves — never one op per leaf. rawSplice uses
	-- the halves separately to fold several new subtrees into its single op.
	local function markMountedTree(slot: any, physicalTarget: any)
		slot._mounted = true
		slot._mountedInst = physicalTarget
		for _, element in ipairs(slot._elements) do
			if S.isSlot(element) then markMountedTree(element, physicalTarget) end
		end
	end

	local function mountSlotTree(slot: any, physicalTarget: any)
		module.Backend.nativeInsert(physicalTarget, slot.Offset:Get(), S.collectLeaves(slot))
		markMountedTree(slot, physicalTarget)
	end

	local function attachSlot(slot: any, physicalTarget: any, ownerKey: any, position: number, mount: boolean?)
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
	-- Portal unmount (State<Slot> swap) and user-made OwnsElements=false lists keep
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
	local function teardownTree(slot: any)
		for _, element in ipairs(slot._elements) do
			if S.isSlot(element) then teardownTree(element) end
		end
		local bk = S.BK.getBookkeeping(slot)
		for _, observer in pairs(bk.observers) do
			module.Backend.unbindLifetime(observer)
		end
		if slot._listObserver then module.Backend.unbindLifetime(slot._listObserver) end
		if slot._detachCleanup then module.Backend.unbindLifetime(slot._detachCleanup) end
		module.Backend.unbindLifetime(slot._baseObserver)
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

	local function unmountSlotTree(slot: any)
		if slot._mounted then
			module.Backend.nativeExtract(slot._mountedInst, slot.Offset:Get(), S.collectLeaves(slot))
		end
		teardownTree(slot)
	end

	local function destroySlotTree(slot: any)
		if slot._destroyed then return end
		if slot._owned == false then
			unmountSlotTree(slot)
			-- round11 Q61 (user decision 2026-09-18): a destroy request (`q.dispose(slot)`, or an
			-- OWNING parent's Remove/Clear — both land here) RELEASES every element this Slot holds
			-- and empties it. The elements survive (OwnsElements = false never destroys them) and
			-- are free again — before this, only the sugar wrapper (`H6-12` (b)) let go, and a
			-- user-made OwnsElements=false list kept owning elements nobody could reach any more
			-- ("already mounted elsewhere" on Add, "still held by a Slot" on dispose — 탐사 F′ 1).
			-- The Slot itself stays alive and reusable (no `_destroyed`, Q14-era decision), now EMPTY.
			-- Extract / a non-owning parent's Remove never come here (rawUnmount → leaveAsElement):
			-- there the Slot leaves WITH its elements — user: "dispose 하기 전 경로에는 안 사라지는게
			-- 맞는데, dispose 자체는 recursive 하게 돌아서 release 가 되는게 맞다".
			-- code-review (2026-09-18): an element that is a sugar WRAPPER Slot (wrapElement's
			-- `State → Slot`, reachable by nobody once released) must let go of its own inner
			-- Instance too, or that Instance stays "already mounted" until GC — the very hole `H6-12`
			-- (b) closed on the leave path (`leaveAsElement`). A user-made nested Slot is the user's
			-- to keep (it leaves with its elements, like Extract).
			local bk = S.BK.getBookkeeping(slot)
			for _, element in ipairs(slot._elements) do
				S.releaseOwner(element, slot)
				if S.isSlot(element) and (element :: any)._wrapped ~= nil then releaseSugarWrapper(element) end
			end
			table.clear(slot._elements)
			table.clear(bk.indexOfElement) -- 1:1 with `_elements` (every writer keeps it so) — one clear states that
			if slot._detached then
				for key, element in pairs(slot._detached) do
					S.releaseOwner(element, slot)
					if S.isSlot(element) and (element :: any)._wrapped ~= nil then releaseSugarWrapper(element) end
					slot._detached[key] = nil
				end
			end
			-- a :List/:Single reactivates from scratch at its next mount — the reconcile
			-- closure's `mounted`/`prevKeys` would otherwise name elements that are no
			-- longer here. `_listed` stays (the mode lock is not undone).
			slot._listActivated = nil
			slot._listObserver = nil
			slot._detachCleanup = nil
			return
		end
		-- Q14 (a) (사용자 결정 2026-09-07): release ownership in BOTH loops — an `OwnsElements = false`
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
			module.Backend.unbindLifetime(slot._detachCleanup)
			slot._detachCleanup = nil
		end
		if slot._listObserver then module.Backend.unbindLifetime(slot._listObserver) end
		module.Backend.unbindLifetime(slot._baseObserver)
		local bk = S.BK.getBookkeeping(slot)
		for _, observer in pairs(bk.observers) do
			module.Backend.unbindLifetime(observer)
		end
		slot._mounted, slot._mountedInst = false, nil
		slot._physicalTarget = nil
		slot._destroyed = true
	end

	S.makeBaseObserver = makeBaseObserver
	S.markMountedTree = markMountedTree
	S.attachSlot = attachSlot
	S.releaseSugarWrapper = releaseSugarWrapper
	S.teardownTree = teardownTree
	S.unmountSlotTree = unmountSlotTree
	S.destroySlotTree = destroySlotTree
end
