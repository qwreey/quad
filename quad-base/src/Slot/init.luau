--!strict
--[[
	Slot.Init(module) — the top-level Slot value type (`base/slot-plan.md`,
	ROADMAP M6). A mutable child array whose bound children track its CRUD.

	[M6 fork, H6] Built in slices across M6 — the fork gave the core, the
	2026-09-03 remainder unit closed the rest (ROADMAP M6: no remainder). The subsystem
	factory pattern (`H-174`): `module.Backend.bindLifetime`/`isState`/`Dispatch.*` are
	read late off `module` (backends overwrite them after New()). elementOwner
	and the Detach/KeyGone sentinels live here (re-exported at top level like
	None), so the top-level SlotHandler and this file share one registry.

	Canonical: `base/slot-plan.md`. Bookkeeping (setLength/setOffsetSource/
	getOffsetAt/recompute/_getBlocker/getBookkeeping) is `module.Bookkeeping.*`.

	[2026-09-07 split] What was one ~1200줄 `Slot.luau` is now this init plus five
	siblings, installed from here as `require("@self/X")(S, module)` in this order:
	  Owner.luau    — claimOwner / claimOwnerAt / releaseOwner (the elementOwner ops)
	  Elements.luau — destroyElement / wrapElement / unwrapElement / collectLeaves / leavesOf
	  Raw.luau      — the raw* mutation layer + its bookkeeping helpers (vacate 등)
	  Tree.luau     — materialize/mount/attach + teardown/unmount/destroy tree walks
	  List.luau     — identityUpdateFn / _activateList / checkListInstall / :List / :Single / :Defer
	`S` is the internal table every sibling receives — typed `Types.SlotInternal`
	(`Slot/types.luau`, round3 §9 Q29, user decision 2026-09-07: internal types stay in
	quad-base, quad-types carries only the public contract): init puts the prelude
	values on it BEFORE installing anything, each sibling publishes its own functions
	back onto it (`S.name = name`), cross-file calls are late `S.name(...)` lookups —
	Luau forward declarations cannot cross files — and siblings read `S.x` directly
	everywhere (no per-file re-captures, no wrapper functions). Backend-injected
	primitives are not on `S`: every use is an inline `module.Backend.bindLifetime(...)`/
	`module.Backend.isInst(...)` read (`H-174`; the old wrapper trio was a leftover of the M6
	fork's style, not a need — a hashed field read is cheap, user 2026-09-07). This init keeps the public Slot_mt CRUD,
	the gates (assertLive/assertManual/assertMutable/checkIndex/
	prepareElements), the `Slot(initial)` constructor, `dispose`, the module exposure
	+ `_slotInternal`, the handler registration and the setFuncLevel tagging call.
	`Handler.luau` is the former `Dispatch/Slot.luau` (the top-level SlotHandler).
]]

local Brand = require("./Brand")
local Err = require("./ErrorNamespace")
local InitDispatch = require("./Dispatch")
local Types = require("@self/types")
local QuadTypes = require("../luau_packages/quad_types")
local ModuleIdentity = require("./ModuleIdentity") -- round10 H-4: element doors + dispose are cross-instance doors too

local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

-- Sentinels — identity is the judgement (like None); the marker field is the
-- TYPE-narrowing aid only (`H6-16` (a), user decision 2026-09-03 — same shape
-- as None's `__quadNone`, `H-300`). Re-exported at top level.
local Detach = table.freeze(setmetatable({ __quadDetach = true :: true }, { __tostring = function() return "Detach" end }))
local KeyGone = table.freeze(setmetatable({ __quadKeyGone = true :: true }, { __tostring = function() return "KeyGone" end }))

-- ── debug-only checks (`architecture.md` "debug 층"; kept out of the logic below) ──
-- `H-500` (2026-09-08 2차 감사 G-1): a Slot inside itself or inside one of its own descendants —
-- `s:Add(s)`, `a:Add(b); b:Add(a)` — passes every other pre-pass gate (the ancestor is a root, so it
-- is "not mounted"). Walk this Slot's owner chain: the candidate must not be on it — O(depth) per
-- added Slot. [2026-10-01 user decision — "순환 가드는 … 같은 결정을 따라가자. debug 로 내리기에 동의해"]
-- runs only with `q.debug` on. With it off nothing stops the cycle at the Add line: the next CRUD /
-- teardown on that tree recurses until a stack overflow or trips `releaseOwner`'s invariant — a
-- program error with no integrity promise after it (architecture "예외 안전성 계약", round3 Q18 (c)).
local function checkNotOwnAncestor(self: any, occupant: any, surface: string, elementOwner: any, OWNER: string)
	local cursor = self
	while Brand.isSlot(cursor) do
		if cursor == occupant then
			Err.errorBeforeNearest("Quad0173 " .. surface .. ": cannot add a Slot to itself or to one of its own descendants (that would be a cycle)", SURFACE)
		end
		cursor = elementOwner:GetWeak(cursor, OWNER)
	end
end

-- [2026-10-06 user decision, round14 Q170 (최종)] the in-call duplicate check (`Slot{ A, A }`,
-- `Splice(i, 0, A, A)`, the same State twice) on the values AS GIVEN — no `:Get()`, so a State
-- element's lazy value is not read even here (user: "debug 일 때 lazy 가 사라지는건 안 돼"). Debug
-- layer: with it off the second copy meets `claimOwner` mid-batch (`Quad0170`; the state after that
-- raise is observed, not a contract) — or, for a State given twice, the mount-time `Quad0156`.
-- Also runs the `H-500` cycle walk on each raw Slot element.
local function checkBatchDebug(self: any, surface: string, count: number, items: { any }, elementOwner: any, OWNER: string)
	local seen = {}
	for i = 1, count do
		local v = items[i]
		if v ~= nil then
			if seen[v] then
				Err.errorBeforeNearest("Quad0171 " .. surface .. ": the same element appears twice", SURFACE)
			end
			seen[v] = true
			if Brand.isSlot(v) then
				checkNotOwnAncestor(self, v, surface, elementOwner, OWNER)
			end
		end
	end
end

-- [2026-10-06 user decision — consumer kits C0, the "debug 감지기 셋" (3) family] a CRUD on a Slot whose
-- mount host is no longer claimed by quad (`q.dispose(host)`, or destroyed outside quad) goes through
-- silently and the change lands on a dead Instance — undefined (round3 Q9: "Instance와 동형"). With
-- `q.debug` on, every public CRUD entry asks the backend once and prints one line; the call goes on
-- unchanged. No public "host alive" query (user: 공개 질의는 안 함).
local function checkHostClaimed(self: any, isClaimed: (any) -> boolean)
	local host = self._mountedInst
	if host ~= nil and not isClaimed(host) then
		print("Slot: CRUD on a Slot whose host Instance is no longer claimed by quad (destroyed - by q.dispose or outside quad - or not made by quad) - the change goes to a dead Instance (undefined); stop using this Slot, or build a new one")
	end
end

local function Init(module: any)
	-- ⚠️ H6-3: Slot_mt is created PER module instance, NOT at file scope. Its
	-- methods are closures capturing `module`; a file-level metatable would pin
	-- the most-recent quad module globally and break the New()-instance GC
	-- contract (`H-181`, spec.init test 2).
	local Slot_mt = {}
	Slot_mt.__index = Slot_mt
	Slot_mt._moduleIdentity = module.moduleIdentity -- cross-instance guard token (`ModuleIdentity.luau`)
	Slot_mt.__quadSlot = true -- `SlotMarker<T>` 브랜드 필드(H-300; 판정은 `Brand.isSlot`)
	-- `__tostring` (2026-09-08, advisory 권고 1): element count + mount/destroy state, read-only
	function Slot_mt.__tostring(self: any): string
		if self._destroyed then
			return "Slot(destroyed)"
		end
		return `Slot(len={#self._elements}{if self._mounted then ", mounted" else ""})`
	end

	module:RunInit(InitDispatch) -- idempotent pull (`H-174` idiom; `H-358` — was the only Init relying on init.luau's order)
	local Dispatch = module.Dispatch
	-- H6-2: the Bookkeeping header states Slot must reach the bookkeeping
	-- subsystem directly (not through Dispatch) — and the internal `_recompute`
	-- is only there. Route all prefix-sum ops through BK (`module.Bookkeeping`,
	-- public namespace since 2026-09-15).
	local BK = module.Bookkeeping
	local None = module.None
	local isState = module.isState
	-- ⚠️ H-174: lifetime primitives + native ops + isInst are backend-injected
	-- AFTER New(), so they must be read LATE off module — capturing them as
	-- Init-time locals would freeze the base error stubs forever.

	-- element(Slot | mountable value) -> ownerKey(inst | Slot). All weak — the
	-- real strong ref is slot._elements / SlotHandler's bindLifetime. Shared by
	-- top-level SlotHandler and nested rawAdd (the gap H fixed by unifying).
	local elementOwner = module.Relate()
	local OWNER, OWNER_POS = "__owner", "__ownerPos"

	-- Q9 (b) (사용자 결정 2026-09-07): a Slot whose mount target was destroyed outside quad
	-- (`inst:Destroy()`) is dead for good — same as an Instance whose owner disposed it. No
	-- liveness bookkeeping; the two "mounted" messages just say so (slot-plan "부수 효과" 절 UB).
	local ZOMBIE_NOTE = " (if its owner was destroyed outside quad - `inst:Destroy()` - the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)"

	local isSlot = Brand.isSlot -- `H-403`: the predicate lives in Brand.luau with its siblings

	-- ⚠️ [2026-09-07 split] `S` — the module-instance-internal table the five sibling
	-- files receive. The prelude values below are the ones that are stable for this
	-- module instance; anything that must be read LATE off `module` stays an inline
	-- `module.xxx` at its use site, except the three wrappers above (they read late
	-- themselves, so passing the WRAPPER preserves `H-174`).
	local S = {
		Slot_mt = Slot_mt,
		BK = BK,
		None = None,
		isState = isState,
		elementOwner = elementOwner,
		OWNER = OWNER,
		OWNER_POS = OWNER_POS,
		ZOMBIE_NOTE = ZOMBIE_NOTE,
		isSlot = isSlot,
		Err = Err,
		SURFACE = SURFACE,
		Detach = Detach,
		KeyGone = KeyGone,
	} :: Types.SlotInternal

	-- Published names are exactly the ones another file reads (round3 §9 `H-461` — the
	-- first split copied every local; `S` is `any`, so a dead publish or a typo'd read is
	-- not analyzable and only surfaces as a nil call). Two entries are published AFTER the
	-- installs below — `S.assertLive` and `S.Slot` — so siblings must read those inside a
	-- function body, never at their file top (`Slot/List.luau`·`Slot/Elements.luau` do).
	require("@self/Owner")(S, module)
	require("@self/Elements")(S, module)
	require("@self/Raw")(S, module)
	require("@self/Tree")(S, module)
	require("@self/List")(S, module)

	-- ── public CRUD (guard + raw* delegation) ──────────────────────────
	local function assertLive(self: any)
		if self._destroyed then Err.errorBeforeNearest("Quad0165 Slot: destroyed Slot cannot be reused", SURFACE) end
	end
	-- [2026-09-16 hunt F] `_crudUsed` is set by `markManual` at each CRUD's mutation point, not
	-- here — a CRUD call rejected by its own validation (`Add(nil)`, out-of-range `Remove`) used to
	-- lock the Slot as manual, and a later `:List` blamed "CRUD was used" (the `H-386` shape again).
	local function assertManual(self: any)
		if self._listed then Err.errorBeforeNearest("Quad0166 Slot: manual CRUD is not allowed after :List/:Single/:Defer", SURFACE) end
	end
	local function markManual(self: any)
		self._crudUsed = true
	end
	-- round10 Q52 (a) (user decision 2026-09-17): no CRUD on a Slot whose mount walk is on the
	-- stack — the `:List` updateFn is a pure item→element function, and an ancestor CRUD from
	-- inside it broke the walk (slot-plan "재진입성" 절의 예외). User: "compute 든 slot 이든
	-- 순수성 제약을 크게 풀어줄 이유가 없어서, 계약 상 조상 건들이기 등은 던져도 될것 같아".
	-- round13 Q74 (a) (2026-10-01): a runtime attach raises the flag on the whole owner chain
	-- (`Slot/Raw.luau` raiseChain), so "an ancestor" means every Slot above the one being attached.
	-- round14 Q185 (d) (user decision 2026-10-12): the same flag also covers the BACKEND CALL of an
	-- operation — the physical insert of a subtree (every Slot of it, `Slot/Tree.luau` raiseTree), the
	-- insert/remove of a raw CRUD (that Slot, `Slot/Raw.luau`) and a destroy (that Slot). A backend
	-- signal delivered synchronously from inside that call (Roblox Immediate SignalBehavior: an
	-- element's `Parent` changed) used to CRUD a Slot whose records were half-written — wrong
	-- Length, the wrong element vacated, an element in the records but never attached, all silent
	-- (`audit/q185-guard-window-2026-10-12`). Same rule as Q52, one window wider; unmount needs no
	-- flag (its logical half runs first). With deferred signals the callback runs after the
	-- operation and is never refused.
	local function assertNotMounting(self: any)
		if self._materializing then
			Err.errorBeforeNearest("Quad0167 Slot: cannot mutate a Slot while it is being mounted or while one of its elements is being inserted/removed (it, or a Slot inside it, is mid-operation) - a :List/:Single updateFn, an Observer that fires during that mount, or a backend signal callback that runs synchronously inside the insert/remove (an element's parent changed) must not CRUD this Slot or an ancestor Slot; run it through slot:WhenIdle(fn) - fn runs as soon as the operation has finished (or an earlier operation on this Slot or a Slot inside it threw mid-way - then this Slot stays unusable: dispose its host Instance)", SURFACE)
		end
	end
	-- every public CRUD entry: live AND manual (Q3 ⑥ — nine hand copies folded) AND not mid-mount
	local function assertMutable(self: any)
		assertLive(self)
		assertManual(self)
		assertNotMounting(self)
		if module.debug then checkHostClaimed(self, module.Backend.isClaimed) end -- C0 (debug-only, file head)
	end

	S.assertLive = assertLive -- `checkListInstall` (Slot/List.luau) gates through this
	S.assertNotMounting = assertNotMounting -- and this (Q52)

	-- checkIndex: fail-fast, no clamping (CRUD table "에러 조건"). `allowEnd`
	-- admits n+1 (an insertion position — Add/Splice); otherwise 1..n.
	local function checkIndex(self: any, index: any, surface: string, allowEnd: boolean?)
		local n = #self._elements
		local limit = if allowEnd then n + 1 else n
		if type(index) ~= "number" or index < 1 or index > limit or index % 1 ~= 0 then
			-- 6순회: two faults, two messages (a fractional index is not "out of range")
			Err.errorBeforeNearest( -- error-code: inline if
				if type(index) ~= "number" or index % 1 ~= 0 or index < 1
					then `Quad0168 {surface}: index must be a positive integer (got {tostring(index)})`
					else `Quad0236 {surface}: index out of range (got {index}, limit {limit})`,
				SURFACE
			)
		end
	end

	-- prepareElements: the PRE-PASS for CRUD that takes new elements (`H-30`/`H-31`) — the
	-- `wrapElement` type gate (nil/None/handler-layer/isInst/isClaimed, destroyed or foreign Slot,
	-- State → wrapper Slot), BEFORE any raw* mutates. The wrapped results are what raw* receives
	-- (never wrapped twice).
	-- [2026-10-06 user decision, round14 Q170 (최종)] that is ALL it does on the normal path. Gone:
	-- the scan of this Slot's existing elements (`H6-24` — O(length) per Add, O(N²) for N Adds), the
	-- State element's current-value gate (`H-517`, 2026-09-16 — it read `raw:Get()` at the CRUD line,
	-- running a lazy Compute early), and the in-call duplicate table. A State element is checked like
	-- `:List`/`:Single` items — when the Slot mounts or the value changes (lazy model). A raw element
	-- already held is caught by `rawAdd`/`rawReplace`'s `claimOwner` (it claims even before mount), so
	-- `Add(A); Add(A)` and `Slot{ A, A }` raise at the same place with the same message. User: "Get은
	-- 디버그에도 없는게 맞아보여" — the debug layer adds only the in-call duplicate check on the values
	-- as given (`checkBatchDebug`, file head) and the `H-500` cycle walk on raw Slots.
	local function prepareElements(self: any, surface: string, count: number, items: { any }): { any }
		local prepared = table.create(count)
		for i = 1, count do
			prepared[i] = S.wrapElement(items[i], Err.errorBeforeNearest) -- type gate; direct surface → nearest
		end
		if module.debug then
			checkBatchDebug(self, surface, count, items, elementOwner, OWNER) -- Quad0171 / `H-500` (debug-only, file head)
		end
		return prepared
	end

	-- ── WhenIdle (round14 Q185, user decision 2026-10-12) ────────────────
	-- The way out of `Quad0167`: `slot:WhenIdle(fn)` runs `fn(slot)` NOW when this Slot is idle, and
	-- otherwise right after the operation it is in the middle of has finished — in every signal mode
	-- and in the mock, with no engine scheduler. User: "엔진 자체 문제라고 보기 애매한 부분에 엔진을 써서
	-- 해결 … 이런 상황을 우회할 도구를 아예 안 주는 경우는 없는지라". quad does NOT queue the refused CRUD
	-- itself: the API is index-based, so an index taken at the call is wrong by the time it would be
	-- applied — `fn` takes its indices again when it runs.
	--   * idle = not `_materializing`, or destroyed (a destroyed Slot never becomes "not mid-operation";
	--     user decision: fn just runs — a CRUD inside it meets the usual destroyed-Slot error).
	--   * waiting requests live in ONE module-level list (`S.pending`, nil when empty — the hot-path
	--     cost of an operation is that nil check). No per-Slot field.
	--   * `settle` runs at the END of every entry that can raise the flag — the public CRUD below,
	--     `:List`/`:Single` install and each reconcile, the dispatch handler's mount
	--     (`Slot/Handler.luau`) and `dispose` — never where the flag comes down: the tail of an
	--     operation (`vacate`, `setLength`) still uses an index captured before the backend call.
	--     (`rawUnmount` raises the chain too — Q185 (d) / Q186 — and settles at the end of the entry that
	--     called it: `Extract`, a `:List` reconcile, `Splice`/`ExtractAll`.)
	--   * no pcall (contract): a raise from `fn` propagates to the caller of the operation that
	--     settled it (the request is already off the list); an operation that raised mid-way leaves
	--     its Slot flagged, and requests on that Slot wait until it is destroyed.
	local function settle()
		local i = 1
		while true do
			local pending = S.pending -- re-read every turn: fn may run operations, and each settles at its own end
			if pending == nil then return end
			local item = pending[i]
			if item == nil then return end
			local slot = item.slot
			if slot._materializing and not slot._destroyed then
				i += 1 -- still mid-operation (an outer frame): that operation's own end comes back here
			else
				-- (same `i` next turn: the list closed up. Everything left of `i` is a skipped,
				-- still-flagged request, so nothing runnable can end up behind the cursor.)
				table.remove(pending, i)
				if #pending == 0 then S.pending = nil end
				item.fn(slot)
			end
		end
	end
	S.settle = settle

	function Slot_mt.WhenIdle(self: any, fn: (slot: any) -> ())
		if type(fn) ~= "function" then
			Err.errorBeforeNearest(`Quad0268 Slot:WhenIdle: fn must be a function (got {typeof(fn)})`, SURFACE)
		end
		if self._materializing and not self._destroyed then
			local request = { slot = self, fn = fn }
			local pending = S.pending
			if pending == nil then
				S.pending = { request }
			else
				table.insert(pending, request)
			end
			return
		end
		fn(self)
	end

	function Slot_mt.Add(self: any, element: any, index: number?): number
		assertMutable(self)
		if index ~= nil then checkIndex(self, index, "Slot:Add", true) end
		local prepared = prepareElements(self, "Slot:Add", 1, { element })
		markManual(self)
		local added = S.rawAdd(self, prepared[1], index)
		if S.pending ~= nil then settle() end
		return added
	end

	function Slot_mt.Remove(self: any, index: number)
		assertMutable(self)
		checkIndex(self, index, "Slot:Remove")
		markManual(self)
		S.rawRemove(self, index)
		if S.pending ~= nil then settle() end
	end

	-- Replace: same position, new occupant, old one DESTROYED — Extract's
	-- destroy twin (`B-5`). Public Replace always destroys (`destroyOld = true`).
	function Slot_mt.Replace(self: any, index: number, newElement: any)
		assertMutable(self)
		checkIndex(self, index, "Slot:Replace")
		local prepared = prepareElements(self, "Slot:Replace", 1, { newElement })
		markManual(self)
		S.rawReplace(self, index, prepared[1], true)
		if S.pending ~= nil then settle() end
	end

	-- Extract(index, newElement?): alive removal. Without `newElement` the
	-- tail is pulled in (O(n)); with it the position is swapped in place
	-- (O(1)). Returns the previous element, unwrapped.
	function Slot_mt.Extract(self: any, index: number, newElement: any?): any
		assertMutable(self)
		checkIndex(self, index, "Slot:Extract")
		local old = self._elements[index]
		if newElement ~= nil then
			local prepared = prepareElements(self, "Slot:Extract", 1, { newElement })
			markManual(self)
			S.rawReplace(self, index, prepared[1], false)
		else
			markManual(self)
			S.rawUnmount(self, index)
		end
		if S.pending ~= nil then settle() end
		return S.unwrapElement(old)
	end

	-- Splice(index, removeCount, ...newElements): alive removal of a span +
	-- insertion in its place, one recompute. `index` ranges like Add (1..n+1);
	-- `removeCount` must fit what is actually there — no clamping.
	function Slot_mt.Splice(self: any, index: number, removeCount: number, ...: any): { any }
		assertMutable(self)
		checkIndex(self, index, "Slot:Splice", true)
		if type(removeCount) ~= "number" or removeCount < 0 or removeCount % 1 ~= 0
			or index + removeCount - 1 > #self._elements then
			Err.errorBeforeNearest("Quad0174 Slot:Splice: removeCount out of range", SURFACE)
		end
		local items = table.pack(...)
		local prepared = prepareElements(self, "Slot:Splice", items.n, items)
		markManual(self)
		local removed = S.rawSplice(self, index, removeCount, prepared)
		for i, element in ipairs(removed) do
			removed[i] = S.unwrapElement(element)
		end
		if S.pending ~= nil then settle() end
		return removed
	end

	-- Move/Swap: reposition only — no ownership change, no Parent op on
	-- Roblox (`nativeMove`/`nativeSwap` are no-ops there). void by design:
	-- the caller already knows the positions.
	function Slot_mt.Move(self: any, oldIndex: number, newIndex: number)
		assertMutable(self)
		checkIndex(self, oldIndex, "Slot:Move")
		checkIndex(self, newIndex, "Slot:Move")
		markManual(self)
		S.rawMove(self, oldIndex, newIndex)
	end

	function Slot_mt.Swap(self: any, indexA: number, indexB: number)
		assertMutable(self)
		checkIndex(self, indexA, "Slot:Swap")
		checkIndex(self, indexB, "Slot:Swap")
		markManual(self)
		S.rawSwap(self, indexA, indexB) -- Swap(i, i) is a no-op inside
	end

	function Slot_mt.Get(self: any, index: number): any
		if type(index) ~= "number" then
			-- `H-468` (Gemini 5차 G-20, 사용자 Q32 "nil 허용 불가"): a nil/non-number index used to
			-- read `_elements[nil]` and answer nil as if the slot were empty. Out-of-range stays nil
			-- (`SlotItem<T>?` — spec.slot "arrays still construct" relies on it).
			Err.errorBeforeNearest(`Quad0175 Slot:Get: index must be a number (got {typeof(index)})`, SURFACE)
		end
		return S.unwrapElement(self._elements[index])
	end

	function Slot_mt.IndexOf(self: any, element: any): number?
		-- O(1) through the reverse map every raw* mutation maintains (`H-481`, 2026-09-08
		-- advisory RFC) — a raw element is its own key there. A State element is held
		-- by a sugar wrapper (`_wrapped`), so the map misses it: unwrap-and-scan below.
		local direct = S.indexOfRaw(self, element)
		if direct ~= nil then return direct end
		for i, el in ipairs(self._elements) do
			if S.unwrapElement(el) == element then return i end
		end
		return nil
	end

	-- Clear/ExtractAll — the whole-Slot forms of Remove/Extract, ONE recompute
	-- (`H-479`, 2026-09-08 advisory RFC, measured: a per-element `rawRemove` tail
	-- ran `recompute` N times, O(N²) — 1000 elements took ~130 ms in the CLI mock
	-- against ~1 ms for `Splice(1, N)`). Same batch-gate idiom as `rawSplice`;
	-- the closer analogue is List's KeyGone pass, which also DESTROYS elements
	-- (user cleanup code) inside the gate — a raise in there leaves the gate On
	-- and this Slot's layout frozen, the same accepted outcome as a throwing
	-- `updateFn` (`H-38` note in round7 `H-485`; 2026-09-08 감사 A-2).
	function Slot_mt.Clear(self: any)
		assertMutable(self)
		markManual(self)
		local gate = if self._physicalTarget ~= nil then S.BK._getBlocker(self) else nil
		local ownsGate = gate ~= nil and not gate.Blocking
		if ownsGate then gate:On() end
		for i = #self._elements, 1, -1 do
			S.rawRemove(self, i)
		end
		if ownsGate then
			gate:OffWithoutEmit()
			S.maybeRecompute(self, S.BK.getBookkeeping(self))
		end
		if S.pending ~= nil then settle() end
	end

	function Slot_mt.ExtractAll(self: any): { any }
		assertMutable(self)
		markManual(self)
		-- `rawSplice` directly, not `self:Splice(1, n)` — a tagged public method calling
		-- another would make a raise inside it blame this delegation line (`H-385`).
		local removed = S.rawSplice(self, 1, #self._elements, {})
		for i, element in ipairs(removed) do
			removed[i] = S.unwrapElement(element)
		end
		if S.pending ~= nil then settle() end
		return removed
	end

	-- forward decl — `function Slot(...)` below is a GLOBAL assignment without a
	-- prior `local` (`H-404`; the full rule sits with the tree forward decls in
	-- `Slot/Tree.luau`)
	local Slot

	-- ── constructor ────────────────────────────────────────────────────
	function Slot(initial: { any }?): any
		local self = setmetatable({
			_elements = {},
			_bk = nil,
			Length = module.Source(0),
			Offset = module.Source(0),
			_mounted = false,
			_materializing = false, -- round10 Q52 (a): mount walk on the stack; round14 Q185 (d): or a backend call of an operation on it
		}, Slot_mt)
		Brand.SlotBrand:Register(self)
		self._baseObserver = S.makeBaseObserver(self)
		if initial ~= nil then
			-- 4순회 `H-386` (the `H-380` container gate, sibling entry): `Slot(frame)` /
			-- `Slot(tag)` / `Slot(source)` / `Slot({ k = v })` — a forgotten `{}` or a
			-- quad value — passed `ipairs` as ZERO elements, then `_crudUsed` locked
			-- the Slot so the first symptom was a later "cannot install :List after
			-- manual CRUD was used" naming a feature never used. Container shape
			-- only — a nil hole stays UB per slot-plan (`ipairs` stops, rest ignored).
			if type(initial) ~= "table" or getmetatable(initial) ~= nil or Brand.isPlainBranded(initial) then
				Err.errorBeforeNearest(`Quad0176 Slot: initial elements must be a plain \{ element, ... \} array (got {typeof(initial)} - a bare element or quad value needs the braces)`, SURFACE)
			end
			local count, highest = 0, 0
			for k in pairs(initial :: { [any]: any }) do
				-- 5순회 `H-396`: `[0]`/`[-1]`/`[1.5]` live in the hash part too (Tag's
				-- `flattenInto` mirror)
				if type(k) ~= "number" or k % 1 ~= 0 or k < 1 then
					Err.errorBeforeNearest(`Quad0177 Slot: initial elements must be an array - key "{tostring(k)}" is not an array position`, SURFACE)
				end
				count += 1
				if k > highest then highest = k end
			end
			-- [2026-10-12 user decision, round14 Q125] a nil hole (`Slot{ a, nil, c }`) stays undefined with
			-- debug off (the `ipairs` below stops there, the rest is ignored); `q.debug` reports it — the
			-- same check, off the same pass, as `:List`'s data (`Slot/List.luau` checkDataKeys).
			if module.debug and count ~= highest then
				local hole = 1
				while (initial :: { [any]: any })[hole] ~= nil do hole += 1 end
				Err.errorBeforeNearest(`Quad0270 Slot: initial elements have a nil hole at index {hole} (the array goes on to index {highest}) - the elements behind it would be ignored; build the array without the nil (a Slot element cannot be nil or None)`, SURFACE)
			end
			self._crudUsed = true
			-- Not `self:Add(v)` — the tagged Add would then be the nearest tagged
			-- frame and blame THIS line instead of the user's `Slot{…}` (round15
			-- `H6-19`). Same pre-pass + raw* as Add, called directly.
			-- `H-506`: ONE pre-pass over the whole list (with `q.debug` it also catches
			-- `Slot{ a, a }` — the in-call duplicate check; off, the second rawAdd's claimOwner
			-- raises `Quad0170`), then raw adds. `ipairs` first, so a nil hole
			-- still just stops the list (documented UB, spec 22b) instead of raising.
			local list = {}
			for _, v in ipairs(initial) do table.insert(list, v) end
			for _, element in ipairs(prepareElements(self, "Slot", #list, list)) do
				S.rawAdd(self, element)
			end
		end
		return self
	end

	S.Slot = Slot -- `wrapElement` (Slot/Elements.luau) mints wrapper Slots through this

	-- dispose(value) — the one safe path to destroy a quad-managed value. The body is an UNTAGGED
	-- local (`disposeValue`) so another tagged surface can run it and keep the blame on ITS caller:
	-- `Source:SetAndDispose` (2026-10-01) reaches it through `_slotInternal.disposeValue` — calling the
	-- tagged `dispose` from there would make `dispose` the nearest tagged frame and blame Source.luau.
	local function disposeValue(value: any)
		if value == nil then
			Err.errorBeforeNearest("Quad0178 dispose: value must not be nil", SURFACE) -- `H-474` (Q31): say nil, not "cannot dispose this value"
		end
		if elementOwner:GetWeak(value, OWNER) ~= nil then
			-- 6순회: name a remedy that exists for each holder kind (a :List Slot's
			-- detached element cannot be Remove/Extract-ed — it goes with its owner)
			-- Q9: same note as the "already mounted" sites (one constant — round3 `H-451`)
			Err.errorBeforeNearest("Quad0179 dispose: this value is still held by a Slot or a mounted position - Remove/Extract it from a manual Slot, drop its key from a :List Slot's data, destroy the owner Slot (a detached element goes with its owner), or take it off its numeric-key seat first (Set(nil) the State holding it; a shorthand-managed child goes with its key)" .. ZOMBIE_NOTE, SURFACE)
		end
		-- round10 H-537: `elementOwner` is per module instance, so another instance's Slot passed this
		-- check and was destroyed under a live tree — a quad value from another instance is refused
		-- (`H-186` door). An Instance is NOT gated on ownership — round10 Q58 (가), user decision
		-- 2026-09-17: the contract is "can this be removed without breaking our bookkeeping", not
		-- "did we make it" ("소유하지 않더라도 부기에 없는 형태가 맞다면 지울 수 있다"), so
		-- `q.dispose(Instance.new(...))` stays allowed; another instance's seated Instance is UB.
		if isSlot(value) or module.isState(value) then
			ModuleIdentity.assertOwnAtCall(module, value, "dispose")
		end
		if isSlot(value) then
			S.destroySlotTree(value)
			if S.pending ~= nil then settle() end -- `slot:WhenIdle` requests made while it was being destroyed
		elseif module.Backend.isInst(value) then module.Backend.nativeDispose(value)
		else Err.errorBeforeNearest("Quad0180 dispose: this backend cannot dispose this value", SURFACE) end
	end
	local function dispose(value: any)
		disposeValue(value) -- the tagged public door (a statement call — the tag is on THIS frame)
	end

	-- Expose to module + the SlotHandler (Slot/Handler.luau reaches these
	-- through module).
	module.Slot = Slot
	module.Detach = Detach
	module.KeyGone = KeyGone
	module.dispose = dispose
	module.isSlot = isSlot
	module.BrandPredicates:Register(isSlot) -- [2026-10-01] a public `is*` field is a registered brand predicate (same function as init.luau's — idempotent)
	-- internal surface the SlotHandler needs
	module._slotInternal = {
		claimOwnerAt = S.claimOwnerAt,
		releaseOwner = S.releaseOwner,
		attachSlot = S.attachSlot,
		unmountSlotTree = S.unmountSlotTree,
		isSlot = isSlot,
		disposeValue = disposeValue, -- 2026-10-01: Source:SetAndDispose's untagged route (see `dispose` above)
		settleIdle = function() -- `slot:WhenIdle`: the handler's mount is an operation entry too
			if S.pending ~= nil then settle() end
		end,
	}
	-- [2026-09-17 round10 Q48 (a) — user decision] the seat ops are public on the bookkeeping
	-- namespace: a provider's numeric-key handler that parents a value (quad-roblox's
	-- `InstanceChild`) or makes a managed child (`InstanceShorthand`) registers the seat in
	-- THIS registry — one `elementOwner` for every mount site, no second registry. Tagged
	-- SURFACE here (Bookkeeping's own tagging loop ran before this Init).
	module.Bookkeeping.claimOwnerAt = S.claimOwnerAt
	module.Bookkeeping.releaseOwner = S.releaseOwner
	Err.setFuncLevel(SURFACE, S.claimOwnerAt, S.releaseOwner)

	-- Register the top-level SlotHandler here (H-278: the owning module
	-- registers its own handler). Dispatch is installed (pulled at the top of
	-- Init, `H-358`), and _slotInternal above is ready.
	require("@self/Handler").register(Dispatch, module)

	-- `H-238`: public surface tagged so argument-validation raises (Nearest)
	-- blame the user's line, not this file. All are table-stored (module field
	-- / metatable methods) — the spike-27 inlining rule holds. (round15
	-- `H6-10`: the fork tagged only `dispose`; the same gap `H10-7` closed
	-- for Tag/Attr.)
	Err.setFuncLevel(
		SURFACE,
		Slot,
		dispose,
		Slot_mt.Add,
		Slot_mt.Remove,
		Slot_mt.Replace,
		Slot_mt.Extract,
		Slot_mt.ExtractAll,
		Slot_mt.Splice,
		Slot_mt.Clear,
		Slot_mt.Move,
		Slot_mt.Swap,
		S.List, -- [split] Slot_mt fields defined in Slot/List.luau, taken via S
		S.Single,
		S.Defer,
		Slot_mt.Get, -- 6순회 `H-410`: read methods too — a raise inside them blames the caller
		Slot_mt.IndexOf,
		Slot_mt.WhenIdle
	)
end

return Init
