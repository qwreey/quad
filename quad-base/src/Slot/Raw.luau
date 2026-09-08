--!strict
--[[
	Slot/Raw.luau — the raw* mutation layer (rawAdd/rawRemove/rawUnmount/
	rawDetach/rawReplace/rawMove/rawSwap/rawSplice + releaseElement) and the
	bookkeeping helpers they share (reindexFrom, the splice/rotate array ops,
	maybeRecompute, unbindObserverAt, vacate, invalidateFrom, indexOfRaw,
	getDetached, leaveAsElement).

	Installed by `Slot/init.luau` with `(S, module)` (see its header for the split
	and the `S` protocol). Behaviour and comments are the moved originals.
]]

local Types = require("./types")

return function(S: Types.SlotInternal, module: any)

	-- reindexFrom: rewrite bk.indexOfElement from `from` to end. Every place
	-- that shifts _elements calls this — regardless of materialization.
	local function reindexFrom(self: any, from: number)
		local bk = S.BK.getBookkeeping(self)
		for i = from, #self._elements do
			bk.indexOfElement[self._elements[i]] = i
		end
	end
	-- reindexRange: a rotation only disturbs [lo, hi] — `H-505` (2026-09-08 round8 L-4):
	-- rawMove used reindexFrom(lo) to the END, so List's "delete one in the middle"
	-- (settle → rawMove of every following key by one slot) was O(N) per key, O(N²)
	-- per cycle (4000 rows: 39 ms for one deletion).
	local function reindexRange(self: any, lo: number, hi: number)
		local bk = S.BK.getBookkeeping(self)
		local els = self._elements
		for i = lo, hi do
			bk.indexOfElement[els[i]] = i
		end
	end

	local function spliceArraysUp(self: any, index: number)
		local bk = S.BK.getBookkeeping(self)
		local n = bk.N or 0
		for i = n, index, -1 do
			bk.lengthList[i + 1] = bk.lengthList[i]
			bk.sourceList[i + 1] = bk.sourceList[i]
			bk.observers[i + 1] = bk.observers[i]
		end
		bk.lengthList[index] = 0 -- placeholder (H-5) — filled by setLength
		bk.sourceList[index] = S.None
		bk.observers[index] = nil
		bk.N = n + 1
		bk.offsetCacheValidUpTo = math.min(bk.offsetCacheValidUpTo, index - 1)
		bk.offsetSetUpTo = math.min(bk.offsetSetUpTo, index - 1)
	end

	local function spliceArraysDown(self: any, index: number)
		local bk = S.BK.getBookkeeping(self)
		local n = bk.N or 0
		for i = index, n - 1 do
			bk.lengthList[i] = bk.lengthList[i + 1]
			bk.sourceList[i] = bk.sourceList[i + 1]
			bk.observers[i] = bk.observers[i + 1]
		end
		bk.lengthList[n] = nil
		bk.sourceList[n] = nil
		bk.observers[n] = nil
		bk.N = if n > 0 then n - 1 else 0
		bk.offsetCacheValidUpTo = math.min(bk.offsetCacheValidUpTo, index - 1)
		bk.offsetSetUpTo = math.min(bk.offsetSetUpTo, index - 1)
	end

	-- maybeRecompute — THE recompute gate for explicit calls (`H-119`): the
	-- owner's batch Blocker and the reentry blocker are both honored; whatever
	-- a skipped call would have done is recovered by the outer pass's rewind
	-- through the cursors the caller already pulled (`dispatch-core-plan.md`).
	-- Extracted 2026-09-03 (user-approved) — it was copy-pasted at every
	-- raw* tail and the reconcile/List tails.
	local function maybeRecompute(self: any, bk: any)
		if S.BK.getBlocker(self):IsOn() or bk.recomputeBlocker:IsOn() then return end
		S.BK.recompute(self, bk)
	end

	-- unbindObserverAt — a position's length observer (State-length slots
	-- only; constants have none) goes with the position.
	local function unbindObserverAt(bk: any, index: number)
		local observer = bk.observers[index]
		if observer then module.unbindLifetime(observer) end
	end

	-- vacate — the shared tail of the raw 3-family (rawRemove/rawUnmount/
	-- rawDetach; extraction user-approved 2026-09-03, `slot-plan.md` "raw
	-- 3형제"). The three differ ONLY in what happens before this call
	-- (destroy? release ownership?); what is identical is that the position
	-- ceases to exist: array + reverse map always, bookkeeping splice + gated
	-- recompute only once materialized (`H-12`: bookkeeping is unconditional
	-- after materialization, physical ops are what `_mounted` gates).
	local function vacate(self: any, index: number, element: any, bk: any)
		table.remove(self._elements, index)
		reindexFrom(self, index)
		bk.indexOfElement[element] = nil
		if self._physicalTarget ~= nil then
			spliceArraysDown(self, index)
			maybeRecompute(self, bk)
		end
	end

	-- ── raw layer ──────────────────────────────────────────────────────
	-- `deferPhysical` (rawAdd/rawUnmount): bookkeeping only — the caller
	-- (rawSplice) issues the ONE physical op for the whole batch itself.
	local function rawAdd(self: any, element: any, index: number?, fromDetached: boolean?, deferPhysical: boolean?): number
		S.claimOwner(element, self, fromDetached)
		index = index or (#self._elements + 1)
		table.insert(self._elements, index, element)
		reindexFrom(self, index)

		if self._physicalTarget == nil then
			return index -- unmaterialized: _elements + reverse-map only
		end

		spliceArraysUp(self, index)
		local physical = self._mounted and not deferPhysical
		if S.isSlot(element) then
			S.attachSlot(element, self._physicalTarget, self, index, physical)
		else
			S.BK.setOffsetSource(self, index, S.None)
			if physical then
				module.nativeInsert(self._mountedInst, S.BK.getOffsetAt(self, index), { element })
			end
			S.BK.setLength(self, index, 1, self._physicalTarget, element)
		end
		return index
	end

	-- leaveAsElement — a Slot element leaving its outer Slot ALIVE (rawUnmount,
	-- non-destroying rawReplace, rawSplice): unmount (logical only when the
	-- caller batches the physical op), then drop a sugar wrapper's inner claim.
	local function leaveAsElement(element: any, deferPhysical: boolean?)
		if deferPhysical then S.teardownTree(element) else S.unmountSlotTree(element) end
		if element._wrapped ~= nil then S.releaseSugarWrapper(element) end
	end

	-- raw 3-family — two axes decide the head (destroy? / release ownership?),
	-- the tail is `vacate` for all three (`slot-plan.md` "raw 3형제"):
	--   rawRemove : release + DESTROY
	--   rawUnmount: release + keep alive   ← the element leaves, reusable elsewhere
	--   rawDetach : KEEP ownership + alive ← this Slot still holds it (_detached)
	local function rawRemove(self: any, index: number)
		local element = self._elements[index]
		local bk = S.BK.getBookkeeping(self)
		unbindObserverAt(bk, index)
		S.releaseOwner(element, self)
		if S.isSlot(element) then S.destroySlotTree(element)
		elseif self._mounted then
			module.nativeRemove(self._mountedInst, S.BK.getOffsetAt(self, index), { element })
		else
			module.nativeDispose(element)
		end
		vacate(self, index, element, bk)
	end

	local function rawUnmount(self: any, index: number, deferPhysical: boolean?)
		local element = self._elements[index]
		local bk = S.BK.getBookkeeping(self)
		unbindObserverAt(bk, index)
		S.releaseOwner(element, self)
		if S.isSlot(element) then leaveAsElement(element, deferPhysical)
		elseif self._mounted and not deferPhysical then
			module.nativeExtract(self._mountedInst, S.BK.getOffsetAt(self, index), { element })
		end
		vacate(self, index, element, bk)
	end

	local function rawDetach(self: any, index: number)
		local element = self._elements[index]
		local bk = S.BK.getBookkeeping(self)
		unbindObserverAt(bk, index)
		-- releaseOwner NOT called — the one difference from rawUnmount: releasing
		-- would let someone else claim what slot._detached still holds.
		if S.isSlot(element) then S.unmountSlotTree(element)
		elseif self._mounted then
			module.nativeExtract(self._mountedInst, S.BK.getOffsetAt(self, index), { element })
		end
		vacate(self, index, element, bk)
	end

	-- rawReplace: keep the array position, swap the occupant (H-1/B-5).
	local function rawReplace(self: any, index: number, newElement: any, destroyOld: boolean)
		local oldElement = self._elements[index]
		S.claimOwner(newElement, self)
		S.releaseOwner(oldElement, self)
		self._elements[index] = newElement
		local bk = S.BK.getBookkeeping(self)
		bk.indexOfElement[oldElement] = nil
		bk.indexOfElement[newElement] = index

		if not self._mounted then
			if destroyOld then
				S.destroyElement(oldElement)
			elseif S.isSlot(oldElement) then
				-- materialized but unmounted: the old subtree still has its
				-- observers bound to the target — logical teardown (`H6-23`).
				-- Unmaterialized: nothing to tear down, but a sugar wrapper that
				-- was mounted earlier still holds its claim (`H6-24`) — release.
				if self._physicalTarget ~= nil then S.teardownTree(oldElement) end
				if oldElement._wrapped ~= nil then S.releaseSugarWrapper(oldElement) end
			end
			if self._physicalTarget ~= nil then
				if S.isSlot(newElement) then
					S.attachSlot(newElement, self._physicalTarget, self, index, false)
				else
					S.BK.setOffsetSource(self, index, S.None)
					S.BK.setLength(self, index, 1, self._physicalTarget, newElement)
				end
			end
			return
		end

		local offset = S.BK.getOffsetAt(self, index)
		if S.isSlot(oldElement) or S.isSlot(newElement) then
			if S.isSlot(oldElement) then
				if destroyOld then S.destroySlotTree(oldElement) else leaveAsElement(oldElement) end
			else
				local op = if destroyOld then module.nativeRemove else module.nativeExtract
				op(self._mountedInst, offset, { oldElement })
			end
			if S.isSlot(newElement) then
				S.attachSlot(newElement, self._physicalTarget, self, index, self._mounted)
				return
			end
			S.BK.setOffsetSource(self, index, S.None)
			module.nativeInsert(self._mountedInst, offset, { newElement })
		else
			local op = if destroyOld then module.nativeRemove else module.nativeExtract
			op(self._mountedInst, offset, { oldElement }, { newElement })
		end
		S.BK.setLength(self, index, 1, self._physicalTarget, newElement)
	end

	-- rawMove: reorder within _elements (no Parent op on Roblox — LayoutOrder-
	-- based). Bookkeeping arrays move with the permutation; recompute re-runs
	-- the affected positions' setLength so offsets follow (H-19).
	-- rotate one array's [from..to] span exactly as table.remove(from)+insert(to)
	-- does — but by index assignment so nil holes (bk.observers is sparse)
	-- survive. `#`-based table.remove/insert would corrupt a hole-laden array.
	local function rotateInPlace(arr: any, from: number, to: number)
		local v = arr[from]
		if from < to then
			for i = from, to - 1 do arr[i] = arr[i + 1] end
		else
			for i = from, to + 1, -1 do arr[i] = arr[i - 1] end
		end
		arr[to] = v
	end

	-- invalidateFrom — raw* regulation 3 (`H-3`/`H-113`): after a permutation,
	-- pull BOTH cursors to one before the lowest touched position — `math.min`
	-- with the position itself is exactly the formula `H-113` disproved.
	local function invalidateFrom(bk: any, lowest: number)
		bk.offsetCacheValidUpTo = math.min(bk.offsetCacheValidUpTo, lowest - 1)
		bk.offsetSetUpTo = math.min(bk.offsetSetUpTo, lowest - 1)
	end

	local function rawMove(self: any, fromIndex: number, toIndex: number)
		if fromIndex == toIndex then return end
		local els = self._elements
		if self._mounted then
			-- raw* regulation 5·6: the physical op gets the flattened leaves and
			-- runs only when mounted. Offsets are read BEFORE the permutation
			-- (the cache describes the current layout). `toOffset` = the absolute
			-- offset the block's first leaf has AFTER the move — the leaf array
			-- is spliced like `_elements` is (remove at from, insert at to), so
			-- moving down past `to` lands after `to`'s leaves minus our own.
			local moving = S.leavesOf(els[fromIndex])
			local fromOffset = S.BK.getOffsetAt(self, fromIndex)
			local toOffset = S.BK.getOffsetAt(self, toIndex)
			if fromIndex < toIndex then
				toOffset += #S.leavesOf(els[toIndex]) - #moving
			end
			module.nativeMove(self._mountedInst, fromOffset, moving, toOffset)
		end
		rotateInPlace(els, fromIndex, toIndex)
		local lo = math.min(fromIndex, toIndex)
		reindexRange(self, lo, math.max(fromIndex, toIndex)) -- `H-505`
		if self._physicalTarget == nil then return end
		-- H6-6: raw* regulation 1 — lengthList/sourceList/observers move with the
		-- SAME permutation as _elements. sourceList especially is ELEMENT-bound
		-- (a nested Slot's own .Offset), not position-bound; permuting only
		-- _elements + indexOfElement leaves recompute writing offsets to the old
		-- occupant's Source. (Roblox nativeMove is a no-op — correctness is
		-- entirely this bookkeeping permutation + recompute.)
		local bk = S.BK.getBookkeeping(self)
		rotateInPlace(bk.lengthList, fromIndex, toIndex)
		rotateInPlace(bk.sourceList, fromIndex, toIndex)
		rotateInPlace(bk.observers, fromIndex, toIndex)
		invalidateFrom(bk, lo)
		maybeRecompute(self, bk)
	end

	-- rawSwap: the O(1) pair exchange — the middle stays put (that is why
	-- nativeSwap exists apart from nativeMove). Same regulations as rawMove.
	local function rawSwap(self: any, indexA: number, indexB: number)
		if indexA == indexB then return end
		local els = self._elements
		local lo, hi = math.min(indexA, indexB), math.max(indexA, indexB)
		if self._mounted then
			module.nativeSwap(
				self._mountedInst,
				S.BK.getOffsetAt(self, lo), S.leavesOf(els[lo]),
				S.BK.getOffsetAt(self, hi), S.leavesOf(els[hi])
			)
		end
		els[lo], els[hi] = els[hi], els[lo]
		local bk = S.BK.getBookkeeping(self)
		bk.indexOfElement[els[lo]], bk.indexOfElement[els[hi]] = lo, hi
		if self._physicalTarget == nil then return end
		for _, arr in { bk.lengthList, bk.sourceList, bk.observers } :: { any } do
			arr[lo], arr[hi] = arr[hi], arr[lo]
		end
		invalidateFrom(bk, lo)
		maybeRecompute(self, bk)
	end

	-- rawSplice: remove `removeCount` positions at `index` (alive — returned)
	-- and insert `newElements` there — ONE recompute and ONE physical op
	-- (`H6-9` (b), user decision 2026-09-03: `nativeExtract(target, offset,
	-- removedLeaves, newLeaves)` — the reflow-window rationale in slot-plan's
	-- native* section). Bookkeeping goes through rawUnmount/rawAdd with
	-- `deferPhysical` under this Slot's batch Blocker; the physical halves are
	-- gathered with collectLeaves before (removed) and after (new — nested
	-- Slots are materialized but not yet marked mounted) the array mutation,
	-- then the new subtrees get the flag walk. Elements are already
	-- wrapped/validated by the caller (`H-30`/`H-31` pre-pass).
	local function rawSplice(self: any, index: number, removeCount: number, newElements: { any }): { any }
		local removed = table.create(removeCount)
		for i = index, index + removeCount - 1 do
			removed[i - index + 1] = self._elements[i]
		end
		local mounted = self._mounted
		local gate = if self._physicalTarget ~= nil then S.BK.getBlocker(self) else nil
		local ownsGate = gate ~= nil and not gate:IsOn()
		if ownsGate then gate:On() end

		local base, removedLeaves: { any } = 0, {}
		if mounted then
			base = S.BK.getOffsetAt(self, index) -- before the mutation — the cache describes the current layout
			for _, element in ipairs(removed) do
				if S.isSlot(element) then S.collectLeaves(element, removedLeaves)
				else table.insert(removedLeaves, element) end
			end
		end
		for i = index + removeCount - 1, index, -1 do
			rawUnmount(self, i, true)
		end
		for k, element in ipairs(newElements) do
			rawAdd(self, element, index + k - 1, nil, true)
		end
		if mounted then
			local newLeaves = {}
			for k, element in ipairs(newElements) do
				if S.isSlot(element) then S.collectLeaves(element, newLeaves)
				else table.insert(newLeaves, element) end
			end
			if #removedLeaves > 0 then
				module.nativeExtract(self._mountedInst, base, removedLeaves, if #newLeaves > 0 then newLeaves else nil)
			elseif #newLeaves > 0 then
				module.nativeInsert(self._mountedInst, base, newLeaves)
			end
			for _, element in ipairs(newElements) do
				if S.isSlot(element) then S.markMountedTree(element, self._mountedInst) end
			end
		end

		if ownsGate then
			gate:OffWithoutEmit()
			maybeRecompute(self, S.BK.getBookkeeping(self))
		end
		return removed
	end

	-- releaseElement: disposition of a pushed-out/removed element — Owned decides.
	local function releaseElement(self: any, index: number?, element: any, wasDetached: boolean)
		if wasDetached then
			-- 5순회 `H-393`: release ownership FIRST, both arms — an `Owned = false`
			-- element Slot outlives its parent, and without this it kept a dead
			-- `elementOwner` forever ("already mounted elsewhere" on the next
			-- Add, "still requires its tree" on dispose — both counterfactual).
			-- `slot-plan.md` `_detachCleanup` 의사코드 "`releaseOwner`를 먼저, 두 분기
			-- 공통으로". The two `destroySlotTree` loops got the same line — Q14 (a).
			S.releaseOwner(element, self)
			if self._owned ~= false then
				S.destroyElement(element)
			end
			return
		end
		if self._owned ~= false then rawRemove(self, index :: number)
		else rawUnmount(self, index :: number) end
	end

	local function indexOfRaw(self: any, element: any): number?
		return S.BK.getBookkeeping(self).indexOfElement[element]
	end

	local function getDetached(self: any): any
		local d = self._detached
		if d == nil then
			d = {}
			self._detached = d
		end
		return d
	end

	S.maybeRecompute = maybeRecompute
	S.rawAdd = rawAdd
	S.rawRemove = rawRemove
	S.rawUnmount = rawUnmount
	S.rawDetach = rawDetach
	S.rawReplace = rawReplace
	S.rawMove = rawMove
	S.rawSwap = rawSwap
	S.rawSplice = rawSplice
	S.releaseElement = releaseElement
	S.indexOfRaw = indexOfRaw
	S.getDetached = getDetached
end
