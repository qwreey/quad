--!strict
--[[
	Slot.Init(module) — the top-level Slot value type (`base/slot-plan.md`,
	ROADMAP M6). A mutable child array whose bound children track its CRUD.

	[M6 fork, H6] Built in slices across M6 — the fork gave the core, the
	2026-09-03 remainder unit closed the rest (ROADMAP M6: no remainder). The subsystem
	factory pattern (`H-174`): `module.bindLifetime`/`isState`/`Dispatch.*` are
	read late off `module` (backends overwrite them after New()). elementOwner
	and the Detach/KeyGone sentinels live here (re-exported at top level like
	None), so the top-level SlotHandler and this file share one registry.

	Canonical: `base/slot-plan.md`. Bookkeeping (setLength/setOffsetSource/
	getOffsetAt/recompute/getBlocker/getBookkeeping) is `module.Dispatch.*`.
]]

local Brand = require("./Brand")
local Err = require("./ErrorNamespace")
local InitDispatch = require("./Dispatch")
local QuadTypes = require("../luau_packages/quad_types")

local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

-- Sentinels — identity is the judgement (like None); the marker field is the
-- TYPE-narrowing aid only (`H6-16` (a), user decision 2026-09-03 — same shape
-- as None's `__quadNone`, `H-300`). Re-exported at top level.
local Detach = table.freeze(setmetatable({ __quadDetach = true :: true }, { __tostring = function() return "Detach" end }))
local KeyGone = table.freeze(setmetatable({ __quadKeyGone = true :: true }, { __tostring = function() return "KeyGone" end }))

local function Init(module: any)
	-- ⚠️ H6-3: Slot_mt is created PER module instance, NOT at file scope. Its
	-- methods are closures capturing `module`; a file-level metatable would pin
	-- the most-recent quad module globally and break the New()-instance GC
	-- contract (`H-181`, spec.init test 2).
	local Slot_mt = {}
	Slot_mt.__index = Slot_mt

	module:RunInit(InitDispatch) -- idempotent pull (`H-174` idiom; `H-358` — was the only Init relying on init.luau's order)
	local Dispatch = module.Dispatch
	-- H6-2: the Bookkeeping header states Slot must reach the bookkeeping
	-- subsystem directly (not through Dispatch) — and `recompute` is only on
	-- `_bookkeeping` (Dispatch re-exports the other five, not it). Route all six
	-- prefix-sum ops through BK.
	local BK = module._bookkeeping
	local None = module.None
	local isState = module.isState
	-- ⚠️ H-174: lifetime primitives + native ops + isInst are backend-injected
	-- AFTER New(), so they must be read LATE off module — capturing them as
	-- Init-time locals would freeze the base error stubs forever.
	local function bindLifetime(inst: any, v: any) module.bindLifetime(inst, v) end
	local function unbindLifetime(v: any) module.unbindLifetime(v) end
	local function isInst(v: any): boolean return module.isInst(v) end

	-- element(Slot | mountable value) -> ownerKey(inst | Slot). All weak — the
	-- real strong ref is slot._elements / SlotHandler's bindLifetime. Shared by
	-- top-level SlotHandler and nested rawAdd (the gap H fixed by unifying).
	local elementOwner = module.Relate()
	local OWNER, OWNER_POS = "__owner", "__ownerPos"

	local function claimOwner(element: any, ownerKey: any, fromDetached: boolean?)
		local cur = elementOwner:GetWeak(element, OWNER)
		if cur ~= nil then
			if not (fromDetached and cur == ownerKey) then
				Err.errorBefore("Slot: this element is already mounted — multiple mounts are not allowed", SURFACE)
			end
			return
		end
		elementOwner:SetWeak(element, OWNER, ownerKey)
	end

	local function claimOwnerAt(element: any, inst: any, k: any): boolean
		local current = elementOwner:GetWeak(element, OWNER)
		if current == inst and elementOwner:GetWeak(element, OWNER_POS) == k then
			return false -- exactly this position already holds it — re-confirm, no-op
		end
		if current ~= nil then
			Err.errorBefore("Slot: this element is already mounted elsewhere — multiple mounts are not allowed", SURFACE)
		end
		elementOwner:SetWeak(element, OWNER, inst)
		elementOwner:SetWeak(element, OWNER_POS, k)
		return true
	end

	local function releaseOwner(element: any, ownerKey: any)
		local current = elementOwner:GetWeak(element, OWNER)
		if current ~= ownerKey then
			error("releaseOwner: this element is not owned by this ownerKey — ownership tracking is broken", 1)
		end
		elementOwner:SetWeak(element, OWNER, nil)
		elementOwner:SetWeak(element, OWNER_POS, nil)
	end

	local isSlot = Brand.isSlot -- `H-403`: the predicate lives in Brand.luau with its siblings

	-- forward decls (mutual recursion)
	-- ⚠️ Forward declarations for the mutually recursive tree functions below —
	-- every bare `function name(...)` further down MUST be listed here: without a
	-- prior `local`, `function name()` is sugar for a GLOBAL assignment (사용자
	-- 실측 2026-09-07, `H-404`). `scripts/test.sh` fails on luau-analyze's
	-- GlobalUsedAsLocal lint so a missing name here cannot slip through.
	local Slot, materializeSlotTree, mountSlotTree, markMountedTree, attachSlot, destroySlotTree, unmountSlotTree, teardownTree

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
		local sub = Slot()
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

	-- reindexFrom: rewrite bk.indexOfElement from `from` to end. Every place
	-- that shifts _elements calls this — regardless of materialization.
	local function reindexFrom(self: any, from: number)
		local bk = BK.getBookkeeping(self)
		for i = from, #self._elements do
			bk.indexOfElement[self._elements[i]] = i
		end
	end

	local function spliceArraysUp(self: any, index: number)
		local bk = BK.getBookkeeping(self)
		local n = bk.N or 0
		for i = n, index, -1 do
			bk.lengthList[i + 1] = bk.lengthList[i]
			bk.sourceList[i + 1] = bk.sourceList[i]
			bk.observers[i + 1] = bk.observers[i]
		end
		bk.lengthList[index] = 0 -- placeholder (H-5) — filled by setLength
		bk.sourceList[index] = None
		bk.observers[index] = nil
		bk.N = n + 1
		bk.offsetCacheValidUpTo = math.min(bk.offsetCacheValidUpTo, index - 1)
		bk.offsetSetUpTo = math.min(bk.offsetSetUpTo, index - 1)
	end

	local function spliceArraysDown(self: any, index: number)
		local bk = BK.getBookkeeping(self)
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
		if BK.getBlocker(self):IsOn() or bk.recomputeBlocker:IsOn() then return end
		BK.recompute(self, bk)
	end

	-- unbindObserverAt — a position's length observer (State-length slots
	-- only; constants have none) goes with the position.
	local function unbindObserverAt(bk: any, index: number)
		local observer = bk.observers[index]
		if observer then unbindLifetime(observer) end
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

	-- ── attach 3-family ────────────────────────────────────────────────
	local function makeBaseObserver(slot: any): any
		return slot.Offset:Observer(function()
			if slot._physicalTarget == nil then return end -- unmaterialized: swallow the install fire
			local bk = BK.getBookkeeping(slot)
			bk.offsetCacheValidUpTo, bk.offsetSetUpTo = 0, 0 -- base changed → all
			maybeRecompute(slot, bk)
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
		maybeRecompute(slot, BK.getBookkeeping(slot)) -- the batch gate just opened; only the reentry gate can still hold
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
		module.nativeInsert(physicalTarget, slot.Offset:Get(), collectLeaves(slot))
		markMountedTree(slot, physicalTarget)
	end

	function attachSlot(slot: any, physicalTarget: any, ownerKey: any, position: number, mount: boolean?)
		materializeSlotTree(slot, physicalTarget, ownerKey, position)
		if mount ~= false then
			mountSlotTree(slot, physicalTarget)
		end
	end

	-- ── raw layer ──────────────────────────────────────────────────────
	-- `deferPhysical` (rawAdd/rawUnmount): bookkeeping only — the caller
	-- (rawSplice) issues the ONE physical op for the whole batch itself.
	local function rawAdd(self: any, element: any, index: number?, fromDetached: boolean?, deferPhysical: boolean?): number
		claimOwner(element, self, fromDetached)
		index = index or (#self._elements + 1)
		table.insert(self._elements, index, element)
		reindexFrom(self, index)

		if self._physicalTarget == nil then
			return index -- unmaterialized: _elements + reverse-map only
		end

		spliceArraysUp(self, index)
		local physical = self._mounted and not deferPhysical
		if isSlot(element) then
			attachSlot(element, self._physicalTarget, self, index, physical)
		else
			BK.setOffsetSource(self, index, None)
			if physical then
				module.nativeInsert(self._mountedInst, BK.getOffsetAt(self, index), { element })
			end
			BK.setLength(self, index, 1, self._physicalTarget, element)
		end
		return index
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
			releaseOwner(element, wrapper)
		end
	end

	-- leaveAsElement — a Slot element leaving its outer Slot ALIVE (rawUnmount,
	-- non-destroying rawReplace, rawSplice): unmount (logical only when the
	-- caller batches the physical op), then drop a sugar wrapper's inner claim.
	local function leaveAsElement(element: any, deferPhysical: boolean?)
		if deferPhysical then teardownTree(element) else unmountSlotTree(element) end
		if element._wrapped ~= nil then releaseSugarWrapper(element) end
	end

	-- raw 3-family — two axes decide the head (destroy? / release ownership?),
	-- the tail is `vacate` for all three (`slot-plan.md` "raw 3형제"):
	--   rawRemove : release + DESTROY
	--   rawUnmount: release + keep alive   ← the element leaves, reusable elsewhere
	--   rawDetach : KEEP ownership + alive ← this Slot still holds it (_detached)
	local function rawRemove(self: any, index: number)
		local element = self._elements[index]
		local bk = BK.getBookkeeping(self)
		unbindObserverAt(bk, index)
		releaseOwner(element, self)
		if isSlot(element) then destroySlotTree(element)
		elseif self._mounted then
			module.nativeRemove(self._mountedInst, BK.getOffsetAt(self, index), { element })
		else
			module.nativeDispose(element)
		end
		vacate(self, index, element, bk)
	end

	local function rawUnmount(self: any, index: number, deferPhysical: boolean?)
		local element = self._elements[index]
		local bk = BK.getBookkeeping(self)
		unbindObserverAt(bk, index)
		releaseOwner(element, self)
		if isSlot(element) then leaveAsElement(element, deferPhysical)
		elseif self._mounted and not deferPhysical then
			module.nativeExtract(self._mountedInst, BK.getOffsetAt(self, index), { element })
		end
		vacate(self, index, element, bk)
	end

	local function rawDetach(self: any, index: number)
		local element = self._elements[index]
		local bk = BK.getBookkeeping(self)
		unbindObserverAt(bk, index)
		-- releaseOwner NOT called — the one difference from rawUnmount: releasing
		-- would let someone else claim what slot._detached still holds.
		if isSlot(element) then unmountSlotTree(element)
		elseif self._mounted then
			module.nativeExtract(self._mountedInst, BK.getOffsetAt(self, index), { element })
		end
		vacate(self, index, element, bk)
	end

	-- rawReplace: keep the array position, swap the occupant (H-1/B-5).
	local function rawReplace(self: any, index: number, newElement: any, destroyOld: boolean)
		local oldElement = self._elements[index]
		claimOwner(newElement, self)
		releaseOwner(oldElement, self)
		self._elements[index] = newElement
		local bk = BK.getBookkeeping(self)
		bk.indexOfElement[oldElement] = nil
		bk.indexOfElement[newElement] = index

		if not self._mounted then
			if destroyOld then
				if isSlot(oldElement) then destroySlotTree(oldElement) else module.nativeDispose(oldElement) end
			elseif isSlot(oldElement) then
				-- materialized but unmounted: the old subtree still has its
				-- observers bound to the target — logical teardown (`H6-23`).
				-- Unmaterialized: nothing to tear down, but a sugar wrapper that
				-- was mounted earlier still holds its claim (`H6-24`) — release.
				if self._physicalTarget ~= nil then teardownTree(oldElement) end
				if oldElement._wrapped ~= nil then releaseSugarWrapper(oldElement) end
			end
			if self._physicalTarget ~= nil then
				if isSlot(newElement) then
					attachSlot(newElement, self._physicalTarget, self, index, false)
				else
					BK.setOffsetSource(self, index, None)
					BK.setLength(self, index, 1, self._physicalTarget, newElement)
				end
			end
			return
		end

		local offset = BK.getOffsetAt(self, index)
		if isSlot(oldElement) or isSlot(newElement) then
			if isSlot(oldElement) then
				if destroyOld then destroySlotTree(oldElement) else leaveAsElement(oldElement) end
			else
				local op = if destroyOld then module.nativeRemove else module.nativeExtract
				op(self._mountedInst, offset, { oldElement })
			end
			if isSlot(newElement) then
				attachSlot(newElement, self._physicalTarget, self, index, self._mounted)
				return
			end
			BK.setOffsetSource(self, index, None)
			module.nativeInsert(self._mountedInst, offset, { newElement })
		else
			local op = if destroyOld then module.nativeRemove else module.nativeExtract
			op(self._mountedInst, offset, { oldElement }, { newElement })
		end
		BK.setLength(self, index, 1, self._physicalTarget, newElement)
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
			local moving = leavesOf(els[fromIndex])
			local fromOffset = BK.getOffsetAt(self, fromIndex)
			local toOffset = BK.getOffsetAt(self, toIndex)
			if fromIndex < toIndex then
				toOffset += #leavesOf(els[toIndex]) - #moving
			end
			module.nativeMove(self._mountedInst, fromOffset, moving, toOffset)
		end
		rotateInPlace(els, fromIndex, toIndex)
		local lo = math.min(fromIndex, toIndex)
		reindexFrom(self, lo)
		if self._physicalTarget == nil then return end
		-- H6-6: raw* regulation 1 — lengthList/sourceList/observers move with the
		-- SAME permutation as _elements. sourceList especially is ELEMENT-bound
		-- (a nested Slot's own .Offset), not position-bound; permuting only
		-- _elements + indexOfElement leaves recompute writing offsets to the old
		-- occupant's Source. (Roblox nativeMove is a no-op — correctness is
		-- entirely this bookkeeping permutation + recompute.)
		local bk = BK.getBookkeeping(self)
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
				BK.getOffsetAt(self, lo), leavesOf(els[lo]),
				BK.getOffsetAt(self, hi), leavesOf(els[hi])
			)
		end
		els[lo], els[hi] = els[hi], els[lo]
		local bk = BK.getBookkeeping(self)
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
		local gate = if self._physicalTarget ~= nil then BK.getBlocker(self) else nil
		local ownsGate = gate ~= nil and not gate:IsOn()
		if ownsGate then gate:On() end

		local base, removedLeaves: { any } = 0, {}
		if mounted then
			base = BK.getOffsetAt(self, index) -- before the mutation — the cache describes the current layout
			for _, element in ipairs(removed) do
				if isSlot(element) then collectLeaves(element, removedLeaves)
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
				if isSlot(element) then collectLeaves(element, newLeaves)
				else table.insert(newLeaves, element) end
			end
			if #removedLeaves > 0 then
				module.nativeExtract(self._mountedInst, base, removedLeaves, if #newLeaves > 0 then newLeaves else nil)
			elseif #newLeaves > 0 then
				module.nativeInsert(self._mountedInst, base, newLeaves)
			end
			for _, element in ipairs(newElements) do
				if isSlot(element) then markMountedTree(element, self._mountedInst) end
			end
		end

		if ownsGate then
			gate:OffWithoutEmit()
			maybeRecompute(self, BK.getBookkeeping(self))
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
			-- 공통으로". The two `destroySlotTree` loops are §4 Q14 (C-4 exemption).
			releaseOwner(element, self)
			if self._owned ~= false then
				if isSlot(element) then destroySlotTree(element) else module.nativeDispose(element) end
			end
			return
		end
		if self._owned ~= false then rawRemove(self, index :: number)
		else rawUnmount(self, index :: number) end
	end

	local function indexOfRaw(self: any, element: any): number?
		return BK.getBookkeeping(self).indexOfElement[element]
	end

	local function getDetached(self: any): any
		local d = self._detached
		if d == nil then
			d = {}
			self._detached = d
		end
		return d
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
			module.nativeExtract(slot._mountedInst, slot.Offset:Get(), collectLeaves(slot))
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
		for _, element in ipairs(slot._elements) do
			if isSlot(element) then destroySlotTree(element)
			else module.nativeDispose(element) end
		end
		if slot._detached then
			for key, element in pairs(slot._detached) do
				if isSlot(element) then destroySlotTree(element) else module.nativeDispose(element) end
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

	-- ── public CRUD (guard + raw* delegation) ──────────────────────────
	local function assertLive(self: any)
		if self._destroyed then Err.errorBeforeNearest("Slot: destroyed Slot cannot be reused", SURFACE) end
	end
	local function assertManual(self: any)
		if self._listed then Err.errorBeforeNearest("Slot: manual CRUD is not allowed after :List/:Single", SURFACE) end
		self._crudUsed = true
	end

	-- checkIndex: fail-fast, no clamping (CRUD table "에러 조건"). `allowEnd`
	-- admits n+1 (an insertion position — Add/Splice); otherwise 1..n.
	local function checkIndex(self: any, index: any, surface: string, allowEnd: boolean?)
		local n = #self._elements
		local limit = if allowEnd then n + 1 else n
		if type(index) ~= "number" or index < 1 or index > limit or index % 1 ~= 0 then
			-- 6순회: two faults, two messages (a fractional index is not "out of range")
			Err.errorBeforeNearest(
				if type(index) ~= "number" or index % 1 ~= 0 or index < 1
					then `{surface}: index must be a positive integer (got {tostring(index)})`
					else `{surface}: index out of range (got {index}, limit {limit})`,
				SURFACE
			)
		end
	end

	-- prepareElements: the validation PRE-PASS for CRUD that takes new
	-- elements (`H-30`/`H-31`) — wrap (type gate) + "already mounted" + no
	-- duplicates within the batch, all BEFORE any raw* mutates. The wrapped
	-- results are what raw* receives (never wrapped twice).
	-- ⚠️ The checks run on the RAW values (round15 `H6-19`, 통합 리뷰): a State
	-- element is wrapped into a fresh Slot, so checking the wrapper would be
	-- vacuous — the same State twice, or a State whose current value is
	-- already mounted, would pass here and raise from reconcile depth
	-- mid-mutation. For a State the occupant to check is its current value.
	-- Dedup is on the OCCUPANT (a State's current value), not the raw value
	-- (`H6-24`, 회신 반영 리뷰): two States holding one instance, or a raw
	-- instance plus a State holding it, are two wrappers over one occupant —
	-- the wrappers' own claims happen at mount, mid-loop, inside the batch
	-- gate. The same occupant test runs against what `self` already holds
	-- (unmaterialized wrappers have not claimed yet, so elementOwner alone
	-- cannot see them — the materializeSlotTree variant of the leak).
	local function occupantOf(element: any): any
		if isSlot(element) then
			return if element._wrapped ~= nil then element._wrapped:Get() else element
		end
		return element
	end

	local function prepareElements(self: any, surface: string, count: number, ...: any): { any }
		local prepared, seen = table.create(count), {}
		for _, existing in ipairs(self._elements) do
			local occ = occupantOf(existing)
			if occ ~= nil then seen[occ] = true end
		end
		for i = 1, count do
			local raw = (select(i, ...))
			local element = wrapElement(raw, Err.errorBeforeNearest) -- type gate (nil/None/handler-layer/isInst); direct surface → nearest
			local occupant = if element ~= raw then raw:Get() else raw
			if occupant ~= nil then
				if seen[occupant] then
					Err.errorBeforeNearest(surface .. ": the same element appears twice", SURFACE)
				end
				if elementOwner:GetWeak(occupant, OWNER) ~= nil then
					Err.errorBeforeNearest(surface .. ": this element is already mounted — multiple mounts are not allowed", SURFACE)
				end
				seen[occupant] = true
			end
			prepared[i] = element
		end
		return prepared
	end

	function Slot_mt.Add(self: any, element: any, index: number?): number
		assertLive(self); assertManual(self)
		if index ~= nil then checkIndex(self, index, "Slot:Add", true) end
		return rawAdd(self, prepareElements(self, "Slot:Add", 1, element)[1], index)
	end

	function Slot_mt.Remove(self: any, index: number)
		assertLive(self); assertManual(self)
		checkIndex(self, index, "Slot:Remove")
		rawRemove(self, index)
	end

	-- Replace: same position, new occupant, old one DESTROYED — Extract's
	-- destroy twin (`B-5`). Public Replace always destroys (`destroyOld = true`).
	function Slot_mt.Replace(self: any, index: number, newElement: any)
		assertLive(self); assertManual(self)
		checkIndex(self, index, "Slot:Replace")
		local prepared = prepareElements(self, "Slot:Replace", 1, newElement)
		rawReplace(self, index, prepared[1], true)
	end

	-- Extract(index, newElement?): alive removal. Without `newElement` the
	-- tail is pulled in (O(n)); with it the position is swapped in place
	-- (O(1)). Returns the previous element, unwrapped.
	function Slot_mt.Extract(self: any, index: number, newElement: any?): any
		assertLive(self); assertManual(self)
		checkIndex(self, index, "Slot:Extract")
		local old = self._elements[index]
		if newElement ~= nil then
			local prepared = prepareElements(self, "Slot:Extract", 1, newElement)
			rawReplace(self, index, prepared[1], false)
		else
			rawUnmount(self, index)
		end
		return unwrapElement(old)
	end

	-- Splice(index, removeCount, ...newElements): alive removal of a span +
	-- insertion in its place, one recompute. `index` ranges like Add (1..n+1);
	-- `removeCount` must fit what is actually there — no clamping.
	function Slot_mt.Splice(self: any, index: number, removeCount: number, ...: any): { any }
		assertLive(self); assertManual(self)
		checkIndex(self, index, "Slot:Splice", true)
		if type(removeCount) ~= "number" or removeCount < 0 or removeCount % 1 ~= 0
			or index + removeCount - 1 > #self._elements then
			Err.errorBeforeNearest("Slot:Splice: removeCount out of range", SURFACE)
		end
		local prepared = prepareElements(self, "Slot:Splice", select("#", ...), ...)
		local removed = rawSplice(self, index, removeCount, prepared)
		for i, element in ipairs(removed) do
			removed[i] = unwrapElement(element)
		end
		return removed
	end

	-- Move/Swap: reposition only — no ownership change, no Parent op on
	-- Roblox (`nativeMove`/`nativeSwap` are no-ops there). void by design:
	-- the caller already knows the positions.
	function Slot_mt.Move(self: any, oldIndex: number, newIndex: number)
		assertLive(self); assertManual(self)
		checkIndex(self, oldIndex, "Slot:Move")
		checkIndex(self, newIndex, "Slot:Move")
		rawMove(self, oldIndex, newIndex)
	end

	function Slot_mt.Swap(self: any, indexA: number, indexB: number)
		assertLive(self); assertManual(self)
		checkIndex(self, indexA, "Slot:Swap")
		checkIndex(self, indexB, "Slot:Swap")
		rawSwap(self, indexA, indexB) -- Swap(i, i) is a no-op inside
	end

	function Slot_mt.Get(self: any, index: number): any
		return unwrapElement(self._elements[index])
	end

	function Slot_mt.IndexOf(self: any, element: any): number?
		for i, el in ipairs(self._elements) do
			if unwrapElement(el) == element then return i end
		end
		return nil
	end

	function Slot_mt.Clear(self: any)
		assertLive(self); assertManual(self)
		for i = #self._elements, 1, -1 do
			rawRemove(self, i)
		end
	end

	function Slot_mt.ExtractAll(self: any): { any }
		assertLive(self); assertManual(self)
		local out = {}
		for i = #self._elements, 1, -1 do
			table.insert(out, 1, unwrapElement(self._elements[i]))
			rawUnmount(self, i)
		end
		return out
	end

	-- ── :List / :Single (slice 4) ──────────────────────────────────────
	local function identityUpdateFn(item: any): any
		if item == KeyGone then return nil end
		return item
	end

	-- _activateList — called by materializeSlotTree at mount. Fresh path builds
	-- the reconcile closure (mounted/userdata/prevKeys upvalues) + subscribes;
	-- remount path re-anchors only (idempotent guard).
	function Slot_mt._activateList(self: any, physicalTarget: any)
		if self._listActivated then
			-- remount: keep closure state, move the detachCleanup anchor only.
			-- (_listObserver re-bind is materializeSlotTree's tail — H-163.)
			bindLifetime(physicalTarget, self._detachCleanup)
			return
		end
		self._listActivated = true

		local keyFn, updateFn = self._keyFn, self._updateFn
		local offset = self.Offset
		local mounted, userdata, prevKeys = {}, {}, {}

		local function settle(key: any, result: any, detach: boolean, slotPos: number)
			local wasMounted = mounted[key]
			local detached = self._detached
			local wasDetached = detached and detached[key]
			local prev = wasMounted or wasDetached

			if detach then
				if wasMounted ~= nil then
					local idx = indexOfRaw(self, wasMounted) :: number
					if self._owned == false then
						rawUnmount(self, idx)
						mounted[key] = nil
					else
						rawDetach(self, idx)
						getDetached(self)[key], mounted[key] = wasMounted, nil
					end
				end
			elseif result == nil then
				if prev ~= nil then
					local idx = if wasDetached ~= nil then nil else indexOfRaw(self, wasMounted)
					releaseElement(self, idx, prev, wasDetached ~= nil)
				end
				mounted[key] = nil
				if detached then detached[key] = nil end
			elseif result == unwrapElement(prev) then
				if wasDetached ~= nil then
					detached[key] = nil
					rawAdd(self, prev, slotPos, true)
					mounted[key] = prev
				else
					local idx = indexOfRaw(self, wasMounted) :: number
					if idx ~= slotPos then rawMove(self, idx, slotPos) end
				end
			else
				local element = wrapElement(result, Err.errorBefore) -- reconcile depth → outermost
				if wasDetached ~= nil then
					releaseElement(self, nil, prev, true)
					detached[key] = nil
					rawAdd(self, element, slotPos)
				elseif wasMounted ~= nil then
					local idx = indexOfRaw(self, wasMounted) :: number
					rawReplace(self, idx, element, self._owned ~= false)
					if idx ~= slotPos then rawMove(self, idx, slotPos) end
				else
					rawAdd(self, element, slotPos)
				end
				mounted[key] = element
			end
		end

		local function reconcile(items: any)
			local keys, seen = table.create(#items), {}
			for i, item in ipairs(items) do
				local key = keyFn(item, i)
				if key == nil then
					-- fail-fast domain error instead of Luau's raw "table index is nil"
					-- at seen[key] (통합 리뷰 발견). errorBefore (outermost), not
					-- Nearest: reconcile runs at dispatch/emission depth (mount or
					-- data:Set), never as a direct user call — `H10-2` reasoning,
					-- same for the duplicate-key raise below
					Err.errorBefore("Slot:List — keyFn returned nil for item #" .. tostring(i), SURFACE)
				end
				if seen[key] then
					Err.errorBefore("Slot:List — duplicate key: " .. tostring(key), SURFACE)
				end
				seen[key] = true
				keys[i] = key
			end

			local blocker = BK.getBlocker(self)
			local ownsGate = not blocker:IsOn()
			if ownsGate then blocker:On() end

			local slotPos = 0
			for i, item in ipairs(items) do
				local key = keys[i]
				local prev = unwrapElement(mounted[key] or (self._detached and self._detached[key]))
				local candidateSlot = slotPos + 1
				local physIndex = BK.getOffsetAt(self, candidateSlot) - offset:Get() + 1
				local result, ud = updateFn(item, physIndex, offset, prev, userdata[key])
				if result == None then result = nil end
				local detach = (result == Detach)
				if detach then result = nil end
				if result ~= nil then slotPos = candidateSlot end
				prevKeys[key] = true
				settle(key, result, detach, slotPos)
				userdata[key] = ud
			end

			for key in pairs(table.clone(prevKeys)) do
				if not seen[key] then
					local prev = unwrapElement(mounted[key] or (self._detached and self._detached[key]))
					local result, ud = updateFn(KeyGone, 0, offset, prev, userdata[key])
					if result == None then result = nil end
					local detach = (result == Detach)
					if detach then result = nil end
					if result ~= nil then
						Err.errorBefore("Slot:List — KeyGone accepts only nil/None (destroy) or Detach (hold)", SURFACE)
					end
					settle(key, result, detach, 0)
					userdata[key] = ud
					prevKeys[key] = nil
				end
			end

			if ownsGate then
				blocker:OffWithoutEmit()
				maybeRecompute(self, BK.getBookkeeping(self))
			end
		end

		self._detachCleanup = module.Effect(function()
			return function()
				if not self._detached then return end
				for key, element in pairs(self._detached) do
					releaseOwner(element, self)
					if isSlot(element) then destroySlotTree(element) else module.nativeDispose(element) end
					self._detached[key] = nil
				end
			end
		end)
		bindLifetime(physicalTarget, self._detachCleanup)

		local data = self._listData
		if isState(data) then
			local observer = data:Observer(function() reconcile(data:Get()) end)
			self._listObserver = observer
			bindLifetime(physicalTarget, observer)
		else
			reconcile(data)
		end
	end

	-- 4순회 `H-385`: the install gates run at the PUBLIC entry — `Single` is tagged
	-- and delegates to `List`, so a gate raised inside `List` was nearest to
	-- `Single`'s own delegation line (`Slot.luau`), not the user's `:Single(...)`.
	local function checkListInstall(self: any)
		assertLive(self)
		if self._listed then Err.errorBeforeNearest("Slot: already has :List/:Single installed", SURFACE) end
		if self._crudUsed then Err.errorBeforeNearest("Slot: cannot install :List/:Single after elements were added manually (CRUD or Slot{ ... } initial elements)", SURFACE) end
	end

	function Slot_mt.List(self: any, data: any, updateFn: any, keyFn: any?, opts: any?): any
		checkListInstall(self)
		self._listed = true
		self._listData = data
		self._updateFn = updateFn
		self._keyFn = keyFn or function(_item: any, index: number) return index end
		if opts and opts.Owned == false then self._owned = false end
		-- if already materialized, activate now (mount is a one-shot event)
		if self._physicalTarget then
			self:_activateList(self._physicalTarget)
			maybeRecompute(self, BK.getBookkeeping(self))
		end
		return self
	end

	function Slot_mt.Single(self: any, state: any, updateFn: any?, opts: any?): any
		checkListInstall(self) -- `H-385`: gate here so the blame is this call, not the delegation below
		local uf = updateFn or identityUpdateFn
		local data = if isState(state)
			then state:Compute(function(v: any) local g = v:Get(); return (if g == nil then {} else { g }) end)
			else (if state == nil then {} else { state })
		return self:List(data, function(item: any, _index: number, off: any, prev: any, ud: any)
			return (uf :: any)(item, off, prev, ud)
		end, function() return true end, opts)
	end

	-- ── constructor ────────────────────────────────────────────────────
	function Slot(initial: { any }?): any
		local self = setmetatable({
			_elements = {},
			_bk = nil,
			Length = module.Source(0),
			Offset = module.Source(0),
			_mounted = false,
		}, Slot_mt)
		Brand.SlotBrand:register(self)
		self._baseObserver = makeBaseObserver(self)
		if initial ~= nil then
			-- 4순회 `H-386` (the `H-380` container gate, sibling entry): `Slot(frame)` /
			-- `Slot(tag)` / `Slot(source)` / `Slot({ k = v })` — a forgotten `{}` or a
			-- quad value — passed `ipairs` as ZERO elements, then `_crudUsed` locked
			-- the Slot so the first symptom was a later "cannot install :List after
			-- manual CRUD was used" naming a feature never used. Container shape
			-- only — a nil hole stays UB per slot-plan (`ipairs` stops, rest ignored).
			if type(initial) ~= "table" or getmetatable(initial) ~= nil or Brand.isPlainBranded(initial) then
				Err.errorBeforeNearest(`Slot: initial elements must be a plain \{ element, ... \} array (got {typeof(initial)} — a bare element or quad value needs the braces)`, SURFACE)
			end
			for k in pairs(initial :: { [any]: any }) do
				-- 5순회 `H-396`: `[0]`/`[-1]`/`[1.5]` live in the hash part too (Tag's
				-- `flattenInto` mirror); a nil hole stays UB (no count check)
				if type(k) ~= "number" or k % 1 ~= 0 or k < 1 then
					Err.errorBeforeNearest(`Slot: initial elements must be an array — key "{tostring(k)}" is not an array position`, SURFACE)
				end
			end
			self._crudUsed = true
			-- Not `self:Add(v)` — the tagged Add would then be the nearest tagged
			-- frame and blame THIS line instead of the user's `Slot{…}` (round15
			-- `H6-19`). Same pre-pass + raw* as Add, called directly.
			for _, v in ipairs(initial) do
				rawAdd(self, prepareElements(self, "Slot", 1, v)[1])
			end
		end
		return self
	end

	-- dispose(value) — the one safe path to destroy a quad-managed value.
	local function dispose(value: any)
		if elementOwner:GetWeak(value, OWNER) ~= nil then
			-- 6순회: name a remedy that exists for each holder kind (a :List Slot's
			-- detached element cannot be Remove/Extract-ed — it goes with its owner)
			Err.errorBeforeNearest("dispose: this value is still held by a Slot — Remove/Extract it from a manual Slot, drop its key from a :List Slot's data, or destroy the owner Slot (a detached element goes with its owner)", SURFACE)
		end
		if isSlot(value) then destroySlotTree(value)
		elseif isInst(value) then module.nativeDispose(value)
		else Err.errorBeforeNearest("dispose: this backend cannot dispose this value", SURFACE) end
	end

	-- Expose to module + the SlotHandler (Dispatch/Slot.luau reaches these
	-- through module).
	module.Slot = Slot
	module.Detach = Detach
	module.KeyGone = KeyGone
	module.dispose = dispose
	module.isSlot = isSlot
	-- internal surface the SlotHandler needs
	module._slotInternal = {
		claimOwnerAt = claimOwnerAt,
		releaseOwner = releaseOwner,
		attachSlot = attachSlot,
		unmountSlotTree = unmountSlotTree,
		isSlot = isSlot,
	}

	-- Register the top-level SlotHandler here (H-278: the owning module
	-- registers its own handler). Dispatch is installed (pulled at the top of
	-- Init, `H-358`), and _slotInternal above is ready.
	require("./Dispatch/Slot").register(Dispatch, module)

	-- `H-238`: public surface tagged so argument-validation raises (Nearest)
	-- blame the user's line, not this file. All are table-stored (module field
	-- / metatable methods) — the spike-27 inlining rule holds. (round15
	-- `H6-10`: the fork tagged only `dispose`; the same gap `H10-7` closed
	-- for Tag/Attribute.)
	for _, fn in
		{
			Slot, dispose,
			Slot_mt.Add, Slot_mt.Remove, Slot_mt.Replace, Slot_mt.Extract, Slot_mt.ExtractAll,
			Slot_mt.Splice, Slot_mt.Clear, Slot_mt.Move, Slot_mt.Swap,
			Slot_mt.List, Slot_mt.Single,
			Slot_mt.Get, Slot_mt.IndexOf, -- 6순회 `H-410`: read methods too (checkIndex raises)
		} :: { any }
	do
		Err.setFuncLevel(fn, SURFACE)
	end
end

return Init
