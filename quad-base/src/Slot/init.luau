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

	[2026-09-07 split] What was one ~1200줄 `Slot.luau` is now this init plus five
	siblings, installed from here as `require("@self/X")(S, module)` in this order:
	  Owner.luau    — claimOwner / claimOwnerAt / releaseOwner (the elementOwner ops)
	  Elements.luau — destroyElement / wrapElement / unwrapElement / collectLeaves / leavesOf
	  Raw.luau      — the raw* mutation layer + its bookkeeping helpers (vacate 등)
	  Tree.luau     — materialize/mount/attach + teardown/unmount/destroy tree walks
	  List.luau     — identityUpdateFn / _activateList / checkListInstall / :List / :Single
	`S` is the internal table every sibling receives — typed `Types.SlotInternal`
	(`Slot/types.luau`, round3 §9 Q29, user decision 2026-09-07: internal types stay in
	quad-base, quad-types carries only the public contract): init puts the prelude
	values on it BEFORE installing anything, each sibling publishes its own functions
	back onto it (`S.name = name`), cross-file calls are late `S.name(...)` lookups —
	Luau forward declarations cannot cross files — and siblings read `S.x` directly
	everywhere (no per-file re-captures, no wrapper functions). Backend-injected
	primitives are not on `S`: every use is an inline `module.bindLifetime(...)`/
	`module.isInst(...)` read (`H-174`; the old wrapper trio was a leftover of the M6
	fork's style, not a need — a hashed field read is cheap, user 2026-09-07). This init keeps the public Slot_mt CRUD,
	the gates (assertLive/assertManual/assertMutable/checkIndex/occupantOf/
	prepareElements), the `Slot(initial)` constructor, `dispose`, the module exposure
	+ `_slotInternal`, the handler registration and the setFuncLevel tagging call.
	`Handler.luau` is the former `Dispatch/Slot.luau` (the top-level SlotHandler).
]]

local Brand = require("./Brand")
local Err = require("./ErrorNamespace")
local InitDispatch = require("./Dispatch")
local Types = require("@self/types")
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
	-- subsystem directly (not through Dispatch) — and `recompute` is only on
	-- `_bookkeeping` (Dispatch re-exports the other five, not it). Route all six
	-- prefix-sum ops through BK.
	local BK = module._bookkeeping
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
	local ZOMBIE_NOTE = " (if its owner was destroyed outside quad — `inst:Destroy()` — the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)"

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
		if self._destroyed then Err.errorBeforeNearest("Slot: destroyed Slot cannot be reused", SURFACE) end
	end
	local function assertManual(self: any)
		if self._listed then Err.errorBeforeNearest("Slot: manual CRUD is not allowed after :List/:Single", SURFACE) end
		self._crudUsed = true
	end
	-- every public CRUD entry: live AND manual (Q3 ⑥ — nine hand copies folded)
	local function assertMutable(self: any)
		assertLive(self)
		assertManual(self)
	end

	S.assertLive = assertLive -- `checkListInstall` (Slot/List.luau) gates through this

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
			local element = S.wrapElement(raw, Err.errorBeforeNearest) -- type gate (nil/None/handler-layer/isInst); direct surface → nearest
			local occupant = if element ~= raw then raw:Get() else raw
			if occupant ~= nil then
				if seen[occupant] then
					Err.errorBeforeNearest(surface .. ": the same element appears twice", SURFACE)
				end
				if elementOwner:GetWeak(occupant, OWNER) ~= nil then
					Err.errorBeforeNearest(surface .. ": this element is already mounted — multiple mounts are not allowed" .. ZOMBIE_NOTE, SURFACE)
				end
				seen[occupant] = true
			end
			prepared[i] = element
		end
		return prepared
	end

	function Slot_mt.Add(self: any, element: any, index: number?): number
		assertMutable(self)
		if index ~= nil then checkIndex(self, index, "Slot:Add", true) end
		return S.rawAdd(self, prepareElements(self, "Slot:Add", 1, element)[1], index)
	end

	function Slot_mt.Remove(self: any, index: number)
		assertMutable(self)
		checkIndex(self, index, "Slot:Remove")
		S.rawRemove(self, index)
	end

	-- Replace: same position, new occupant, old one DESTROYED — Extract's
	-- destroy twin (`B-5`). Public Replace always destroys (`destroyOld = true`).
	function Slot_mt.Replace(self: any, index: number, newElement: any)
		assertMutable(self)
		checkIndex(self, index, "Slot:Replace")
		local prepared = prepareElements(self, "Slot:Replace", 1, newElement)
		S.rawReplace(self, index, prepared[1], true)
	end

	-- Extract(index, newElement?): alive removal. Without `newElement` the
	-- tail is pulled in (O(n)); with it the position is swapped in place
	-- (O(1)). Returns the previous element, unwrapped.
	function Slot_mt.Extract(self: any, index: number, newElement: any?): any
		assertMutable(self)
		checkIndex(self, index, "Slot:Extract")
		local old = self._elements[index]
		if newElement ~= nil then
			local prepared = prepareElements(self, "Slot:Extract", 1, newElement)
			S.rawReplace(self, index, prepared[1], false)
		else
			S.rawUnmount(self, index)
		end
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
			Err.errorBeforeNearest("Slot:Splice: removeCount out of range", SURFACE)
		end
		local prepared = prepareElements(self, "Slot:Splice", select("#", ...), ...)
		local removed = S.rawSplice(self, index, removeCount, prepared)
		for i, element in ipairs(removed) do
			removed[i] = S.unwrapElement(element)
		end
		return removed
	end

	-- Move/Swap: reposition only — no ownership change, no Parent op on
	-- Roblox (`nativeMove`/`nativeSwap` are no-ops there). void by design:
	-- the caller already knows the positions.
	function Slot_mt.Move(self: any, oldIndex: number, newIndex: number)
		assertMutable(self)
		checkIndex(self, oldIndex, "Slot:Move")
		checkIndex(self, newIndex, "Slot:Move")
		S.rawMove(self, oldIndex, newIndex)
	end

	function Slot_mt.Swap(self: any, indexA: number, indexB: number)
		assertMutable(self)
		checkIndex(self, indexA, "Slot:Swap")
		checkIndex(self, indexB, "Slot:Swap")
		S.rawSwap(self, indexA, indexB) -- Swap(i, i) is a no-op inside
	end

	function Slot_mt.Get(self: any, index: number): any
		if type(index) ~= "number" then
			-- `H-468` (Gemini 5차 G-20, 사용자 Q32 "nil 허용 불가"): a nil/non-number index used to
			-- read `_elements[nil]` and answer nil as if the slot were empty. Out-of-range stays nil
			-- (`SlotItem<T>?` — spec.slot "arrays still construct" relies on it).
			Err.errorBeforeNearest(`Slot:Get: index must be a number (got {typeof(index)})`, SURFACE)
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
	-- against ~1 ms for `Splice(1, N)`). Same batch-gate idiom as `rawSplice`.
	function Slot_mt.Clear(self: any)
		assertMutable(self)
		local gate = if self._physicalTarget ~= nil then S.BK.getBlocker(self) else nil
		local ownsGate = gate ~= nil and not gate:IsOn()
		if ownsGate then gate:On() end
		for i = #self._elements, 1, -1 do
			S.rawRemove(self, i)
		end
		if ownsGate then
			gate:OffWithoutEmit()
			S.maybeRecompute(self, S.BK.getBookkeeping(self))
		end
	end

	function Slot_mt.ExtractAll(self: any): { any }
		assertMutable(self)
		-- `rawSplice` directly, not `self:Splice(1, n)` — a tagged public method calling
		-- another would make a raise inside it blame this delegation line (`H-385`).
		local removed = S.rawSplice(self, 1, #self._elements, {})
		for i, element in ipairs(removed) do
			removed[i] = S.unwrapElement(element)
		end
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
		}, Slot_mt)
		Brand.SlotBrand:register(self)
		self._baseObserver = S.makeBaseObserver(self)
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
				S.rawAdd(self, prepareElements(self, "Slot", 1, v)[1])
			end
		end
		return self
	end

	S.Slot = Slot -- `wrapElement` (Slot/Elements.luau) mints wrapper Slots through this

	-- dispose(value) — the one safe path to destroy a quad-managed value.
	local function dispose(value: any)
		if value == nil then
			Err.errorBeforeNearest("dispose: value must not be nil", SURFACE) -- `H-474` (Q31): say nil, not "cannot dispose this value"
		end
		if elementOwner:GetWeak(value, OWNER) ~= nil then
			-- 6순회: name a remedy that exists for each holder kind (a :List Slot's
			-- detached element cannot be Remove/Extract-ed — it goes with its owner)
			-- Q9: same note as the "already mounted" sites (one constant — round3 `H-451`)
			Err.errorBeforeNearest("dispose: this value is still held by a Slot or a mounted position — Remove/Extract it from a manual Slot, drop its key from a :List Slot's data, or destroy the owner Slot (a detached element goes with its owner)" .. ZOMBIE_NOTE, SURFACE)
		end
		if isSlot(value) then S.destroySlotTree(value)
		elseif module.isInst(value) then module.nativeDispose(value)
		else Err.errorBeforeNearest("dispose: this backend cannot dispose this value", SURFACE) end
	end

	-- Expose to module + the SlotHandler (Slot/Handler.luau reaches these
	-- through module).
	module.Slot = Slot
	module.Detach = Detach
	module.KeyGone = KeyGone
	module.dispose = dispose
	module.isSlot = isSlot
	-- internal surface the SlotHandler needs
	module._slotInternal = {
		claimOwnerAt = S.claimOwnerAt,
		releaseOwner = S.releaseOwner,
		attachSlot = S.attachSlot,
		unmountSlotTree = S.unmountSlotTree,
		isSlot = isSlot,
	}

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
		Slot_mt.Get, -- 6순회 `H-410`: read methods too — a raise inside them blames the caller
		Slot_mt.IndexOf
	)
end

return Init
