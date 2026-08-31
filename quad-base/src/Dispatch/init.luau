--[[
	InitDispatch(module) — the dispatch engine, installed on the module
	instance as `module.Dispatch` (factory shape: `.claude/base/
	module-lifecycle-plan.md` "New()의 내부 구성 — InitXxx 팩토리 체이닝";
	Dispatch is not a primitive: `.claude/base/dispatch-core-plan.md`
	"Dispatch는 프리미티브가 아니다"). The handler registry and `chains` are
	per-instance state — two `New()` modules never share them.

	Sources, as-is:
	  - `dispatch-core-plan.md` "Dispatch 체인" — `chains` (per-(inst,k) index
	    array, each slot {handler, retractor}), descending-diff `process`
	    (A)/(B) branches, 3-arg `retractFrom` (tail-first), the `H-103` caveat
	    (a throwing h.process leaves the NOOP marker permanently — no pcall,
	    `architecture.md` "예외 안전성 계약").
	  - same doc "핸들러 계약" / "우선순위 동률/매치 실패 처리" — priority scan,
	    first match wins; match failure errors immediately (message built only
	    on failure, with brand if known + typeof + provider guidance); named
	    priority bands; optional diagnostics-only `name` field (`H-214` (a));
	    tie warning printed only when `module.debug`; `listHandlers` is a pure
	    query (returns, never prints — `D-8`).
	  - `bind-system-plan.md` "`New(name)(props)` 파이프라인 의사코드" — `drive`
	    (stages ⓪ + (b) + ⓪' as of M3 unit 2; the (a) PreRef/PostRef pre-pass
	    and (c) postRefList come with M8, where those values are born).
	  - `dispatch-core-plan.md` "Length/Offset" / "두 필드" / "배치 등록을
	    안전하게 만드는 Blocker 게이팅" — setLength/setOffsetSource/getOffsetAt,
	    the prefix-sum cache with its two cursors, recompute with reentry block
	    + rewind, per-owner batch Blockers (M3 unit 2).

	Errors follow `architecture.md` "error 계약" via the shared error
	namespace (`H-231`): match failure climbs to the user's entry
	(`errorBefore` — outermost surface scan, closing `H-219`'s drive-path
	limit), the provider-contract violation (no retractor) blames the nearest
	surface's caller (`errorBeforeNearest`, `H-222`), broken internal
	bookkeeping stays a plain level-1 `error`. Messages in English. All public
	functions and every received handler function join the SURFACE tag layer.
]]

local Relate = require("./Relate")
local Void = require("./Void")
local Brand = require("./Brand")
local Blocker = require("./Blocker")
local Err = require("./ErrorNamespace")
local NoneModule = require("@self/None")
local LeafModule = require("@self/Leaf")

local None = NoneModule.None
local QuadTypes = require("../luau_packages/quad_types")
local HandlerModule = require("@self/Handler")

export type Handler = HandlerModule.Handler
export type Dispatch = QuadTypes.Dispatch

type Slot = { handler: Handler, retractor: (nextValue: any?) -> () }

-- Band constants live in quad-types (`H-230` (a) — backends reach them
-- without quad-base; single source, re-exported on `module.Dispatch` below).
-- Ordering/band semantics are the contract, literals are `H-213`.
local HANDLER_PRIORITY_HIGH = QuadTypes.HANDLER_PRIORITY_HIGH
local HANDLER_PRIORITY_NORMAL = QuadTypes.HANDLER_PRIORITY_NORMAL
local HANDLER_PRIORITY_LOW = QuadTypes.HANDLER_PRIORITY_LOW
local HANDLER_PRIORITY_FALLBACK = QuadTypes.HANDLER_PRIORITY_FALLBACK
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

-- Probed (cold path only) to name a value's brand in the match-failure
-- message — there is deliberately no reverse lookup on Brand
-- (`archive/brand-shared-registry-reversed.md`), so we ask the module's own
-- public predicates. Base predicates only; backend-added brands just fall
-- back to typeof.
-- Order is most-specific-first (`H-220`): `isRef` is a superset of
-- `isPreRef`/`isPostRef` (`brand-plan.md` predicate composition) and
-- `isState` of `isSource`, so subtypes must come before their union
-- predicates or they are unreachable; `isEpoch` last (most generic).
-- ⚠️ This is a hand-copied predicate list (alongside Brand.luau/init.luau/
-- quad-types) — when a milestone adds `isTag`/`isTween`/`isSlot` etc. to the
-- module surface, extend this list too or the new brand silently falls back
-- to typeof (the `type(predicate) == "function"` guard hides omissions).
local BRAND_PROBES = {
	"isPreRef",
	"isPostRef",
	"isRef",
	"isSource",
	"isStore",
	"isState",
	"isObserver",
	"isEffect",
	"isBlocker",
	"isModifier",
	"isEpoch",
}

-- Diagnostics label for a handler in error/warning messages — uses the
-- optional `name` contract field (`H-214` (a)); when absent, only the
-- priority shows (`H-228` — the confirmed wording is "없으면 priority만").
local function describeHandler(h: Handler): string
	return if h.name ~= nil then `"{h.name}" (priority {h.priority})` else `(priority {h.priority})`
end

local function Init(module: any)
	-- {[inst(weak)] = {[k] = {[index] = {handler, retractor}}(weak value)}}
	-- `H-229`: the lists hold retractor closures that (transitively) capture
	-- `inst`, so holding them strongly here would make the bucket value
	-- back-reference its own weak key — the `H-71` "leaks 100%" pattern (no
	-- ephemerons in Luau), and Destroy calls no retract by contract. So the
	-- strong anchor is NOT chains but the instance's own gchold:
	-- `module.bindLifetime(inst, list)` on list creation ties the list's
	-- lifetime to the bind lifetime — Destroy collapses the gchold island and
	-- the whole chain graph (lists, retractors, observers, the inst userdata)
	-- becomes collectable, with retractors never called (contract kept; this
	-- is memory release, not teardown). Same medicine as the two-Relate cycle
	-- fix in `slot-plan.md` (everything weak + one anchor via bindLifetime).
	-- Consequence: any inst entering Dispatch must be claimable by the
	-- installed lifetime backend (nativeClaim'd real Instance, or the mock).
	local chains = Relate()
	local handlers: { Handler } = {} -- kept sorted, higher priority first
	local NOOP = Void -- `H-162`: the single exported no-op, never a fresh closure

	local function noMatchMessage(k: any, v: any): string
		local brand: string? = nil
		for _, probeName in BRAND_PROBES do
			local predicate = module[probeName]
			if type(predicate) == "function" and (predicate :: (any) -> boolean)(v) then
				brand = string.sub(probeName, 3) -- "isSource" -> "Source"
				break
			end
		end
		return `quad.Dispatch: no handler matched key {tostring(k)} (value: {typeof(v)}{if brand then `, brand: {brand}` else ""})`
			.. " — check that the provider for this value (e.g. quad-roblox) is initialized"
			-- `H-257`: a nil here often started life as the None sentinel (NoneHandler
			-- recursion erases the provenance) — say so, or the user is told they
			-- passed the one value None exists to be distinguishable from
			.. (if v == nil then " (a nil at this depth may be an unwrapped None or a reactive nil — the key's own handler must accept nil)" else "")
	end

	local function noRetractorMessage(h: Handler, k: any, index: number): string
		return `quad.Dispatch: handler {describeHandler(h)} returned no retractor at key {tostring(k)}, index {index}`
			.. " — return Void when there is nothing to undo"
	end

	-- Pure scan: first handler (in priority order) whose isHandlable accepts.
	-- Returns nil on no match — the immediate error is `process`'s job, so the
	-- failure message is only ever built there ("에러 메시지는 매치 실패
	-- 시에만" — 핸들러 계약 절의 지연 생성 규칙).
	local function getHandler(inst: any, k: any, v: any): Handler?
		for _, h in handlers do
			if h.isHandlable(inst, k, v) then
				return h
			end
		end
		return nil
	end

	local function retractFrom(inst: any, k: any, index: number)
		-- From index (inclusive) to the tail, retracted tail-first (deepest
		-- index first — LIFO: the shallower slot created the deeper one).
		-- The argument is always nil here: plain retract with no follow-up.
		local list: { Slot }? = chains:GetWeak(inst, k) :: any
		if list == nil then
			return
		end
		for i = #list, index, -1 do
			local slot = list[i]
			if slot == nil then
				error(`quad.Dispatch.retractFrom: no slot at index {i} — the chain array has a hole, bookkeeping is broken`, 1)
			end
			slot.retractor(nil)
			list[i] = nil
		end
	end

	local function process(inst: any, k: any, v: any, index: number)
		-- [순서 주의] list 확보 + chains 등록은 반드시 h.process 호출 *전에* —
		-- h.process가 재귀 Dispatch.process(inst,k,…,index+1)를 부르는 게 정상
		-- 경로이고(StoreBind/NoneHandler), 그때 chains에 이 list가 아직 없으면
		-- 재귀 호출이 자기만의 새 테이블을 만들어 저장한 뒤 바깥이 덮어써서
		-- 하위 위임 retractor가 통째로 유실됨(최초 마운트에서 항상 발생).
		local list: { Slot } = chains:GetWeak(inst, k) :: any
		if list == nil then
			list = {}
			-- Anchor first (`H-229`): the list lives exactly as long as the
			-- inst's bind lifetime (gchold), chains only holds it weakly.
			-- bindLifetime treats a value matching no known type as a pure GC
			-- relation (user-confirmed contract, `lifecycle-pattern.md`).
			module.bindLifetime(inst, list)
			chains:SetWeak(inst, k, list)
		end

		local slot = list[index]
		local matched = getHandler(inst, k, v)
		if matched == nil then
			-- `H-219`/`H-231`: outermost scan — climbs every wrapper (drive, a
			-- delegating handler, later the M5 pipeline) to the user's entry.
			Err.errorBefore(noMatchMessage(k, v), SURFACE)
		end
		-- errorBefore never returns; the cast just tells the checker (field
		-- calls typed `-> never` don't narrow like the `error` builtin does)
		local h: Handler = matched :: any

		if slot ~= nil and slot.handler == h then
			-- (A) same handler — leave everything below untouched; hand the new
			-- value to the sitting retractor so it does its own transition, then
			-- replace this one slot with the fresh retractor.
			-- v is guaranteed to satisfy h.isHandlable — getHandler picked h on v.
			slot.retractor(v)
			slot.retractor = NOOP -- consumed; no double call while h.process recurses
			local retractor = h.process(inst, k, v, index)
			if retractor == nil then
				-- provider-contract violation — nearest surface's caller (`H-222`)
				Err.errorBeforeNearest(noRetractorMessage(h, k, index), SURFACE)
			end
			slot.retractor = retractor
		else
			-- (B) different handler (or empty slot) — retract this slot and below,
			-- then install fresh.
			retractFrom(inst, k, index)
			-- Occupancy marker first: while h.process recurses, `list` must stay a
			-- hole-free sequence for `#list` to be defined (`#` on holey tables is
			-- unspecified).
			list[index] = { handler = h, retractor = NOOP }
			local retractor = h.process(inst, k, v, index)
			if retractor == nil then
				Err.errorBeforeNearest(noRetractorMessage(h, k, index), SURFACE)
			end
			list[index] = { handler = h, retractor = retractor }
		end
	end
	-- ⚠️ `H-103`: if h.process throws, the NOOP marker above stays permanently —
	-- that slot's cleanup is gone and even an explicit retract recovers nothing.
	-- Deliberately NOT wrapped in pcall (`architecture.md` "예외 안전성 계약":
	-- hot path, and quad does not guarantee bookkeeping integrity after a throw).
	-- The (A)/(B) tails are intentionally left duplicated, 1:1 with the
	-- confirmed pseudocode ("Dispatch 체인" 절) — merging them was reviewed and
	-- declined (`H-226`: no measured bottleneck, and structural divergence from
	-- the confirmed shape costs more than it saves).

	local function addHandler(handler: Handler)
		-- Tie detection is free at registration time (the registry is sorted
		-- here, statically). No tiebreak rule is enforced — ties are usually a
		-- handler-design mistake, surfaced via debug visibility only.
		if module.debug then
			for _, existing in handlers do
				if existing.priority == handler.priority then
					print(
						`quad.Dispatch: handler priority tie between {describeHandler(existing)}`
							.. ` and {describeHandler(handler)}`
							.. " — ties have no defined order; offset from a HANDLER_PRIORITY_* band"
					)
					break
				end
			end
		end
		table.insert(handlers, handler)
		table.sort(handlers, function(a: Handler, b: Handler)
			return a.priority > b.priority
		end)
		-- `H-231`: received closures join the surface layer at receipt time
		-- (user's rule — "입력 받은 측에서 level을 설정") so the walker sees
		-- provider frames as quad machinery, not as user code.
		Err.setFuncLevel(handler.isHandlable, SURFACE)
		Err.setFuncLevel(handler.process, SURFACE)
	end

	local function listHandlers(): { Handler }
		-- Pure query — returns the registered handlers in scan order, prints
		-- nothing (`D-8`); whether to display them is the caller's business.
		-- A copy, so callers can't disturb the scan order. Each handler carries
		-- the doc'd name/priority via the optional `name` contract field
		-- (`H-214` (a) — absent name just shows as nil).
		return table.clone(handlers)
	end

	-- ── Length/Offset bookkeeping (M3 unit 2) ────────────────────────────
	-- `dispatch-core-plan.md` "Length/Offset" / "두 필드" / "배치 등록을
	-- 안전하게 만드는 Blocker 게이팅" sections, as-is.

	-- ownerKey(weak) -> bk. Weak VALUE + gchold anchor (`H-229` pattern): the
	-- observers stored in bk hold gatedRecompute closures that capture
	-- ownerKey, so a strong Relate value would back-reference its own weak key
	-- (`H-71` — the exact chains leak, one shelf over).
	-- M6 note (`H-232` (a), user-confirmed): a Slot ownerKey cannot be
	-- bindLifetime'd (not claimable) and its bk must outlive unmounts, so the
	-- SLOT owns its bk strongly as `slot._bk` — getBookkeeping branches on
	-- SlotBrand when M6 lands. Until then only claimable insts reach this path.
	local bookkeeping = Relate()
	-- ownerKey(weak) -> batch Blocker. Strong is fine here: a Blocker holds no
	-- reference back to the ownerKey, so the weak key still collects.
	local blockers = Relate()

	local function getBlocker(ownerKey: any): any
		local blocker = blockers:GetStrong(ownerKey, "blocker")
		if blocker == nil then
			blocker = Blocker()
			blockers:SetStrong(ownerKey, "blocker", blocker)
		end
		return blocker
	end

	-- Never returns nil — lazy creation ("`getBookkeeping(ownerKey)`은 절대
	-- `nil`을 돌려주지 않는다"; callers must not re-guard). Initial values are
	-- contract (`H-4`): the two cursors start at 0, only `N` stays nil ("아직
	-- 아무 자리도 등록 안 됨"과 "0번까지 유효"는 다른 뜻).
	local function getBookkeeping(ownerKey: any): any
		local bk = bookkeeping:GetWeak(ownerKey, "bk")
		if bk == nil then
			bk = {
				lengthList = {},
				sourceList = {},
				observers = {},
				N = nil,
				offsetCache = {},
				offsetCacheValidUpTo = 0,
				offsetSetUpTo = 0,
				recomputeBlocker = Blocker(),
				-- element(inst|slot) -> position. Weak keys (`H-145`): the
				-- top-level release setLength(…, 0) carries no element arg, so
				-- stale keys must fall out on their own. Alive-while-mounted is
				-- guaranteed elsewhere (slot._elements / gatedRecompute capture).
				indexOfElement = setmetatable({}, { __mode = "k" }),
			}
			module.bindLifetime(ownerKey, bk)
			bookkeeping:SetWeak(ownerKey, "bk", bk)
		end
		return bk
	end

	local function contribution(bk: any, i: number): number
		local v = bk.lengthList[i]
		return if Brand.isState(v) then v:Get() else v
	end

	-- Absolute offset (0-based count) of position `at` — single function with
	-- a prefix-sum cache; sequential callers extend it one slot at a time so a
	-- full pass is O(N). Touches ONLY offsetCacheValidUpTo, never offsetSetUpTo
	-- ("두 필드" 절 — the split exists because this tail once erased the
	-- rewind signal).
	local function getOffsetAt(ownerKey: any, at: number): number
		local bk = getBookkeeping(ownerKey)
		if bk.offsetCacheValidUpTo == 0 then
			-- bootstrap: position 1's offset is this owner's base itself —
			-- a Slot's own .Offset, or 0 for a physical inst (no base concept).
			bk.offsetCache[1] = if Brand.SlotBrand:is(ownerKey) then ownerKey.Offset:Get() else 0
			bk.offsetCacheValidUpTo = 1
		end
		if at <= bk.offsetCacheValidUpTo then
			return bk.offsetCache[at]
		end
		local cur = bk.offsetCache[bk.offsetCacheValidUpTo]
		for i = bk.offsetCacheValidUpTo, at - 1 do
			if bk.lengthList[i] == nil then
				-- `H-106`: without this the C-6 diagnosis is bypassed and an
				-- anonymous arithmetic error fires first. Internal invariant.
				error(`Dispatch.getOffsetAt: lengthList[{i}] is nil — bookkeeping is broken`, 1)
			end
			cur += contribution(bk, i)
			bk.offsetCache[i + 1] = cur -- this slot's length decides the NEXT slot's offset
		end
		bk.offsetCacheValidUpTo = at
		return cur
	end

	-- Full pass: reentry blocked by bk.recomputeBlocker, upper bound re-read
	-- every iteration, rewind when someone lowered offsetSetUpTo mid-pass
	-- (`H-101`/`H-113`/`H-124` — the confirmed pseudocode, 1:1).
	local function recompute(ownerKey: any, bk: any)
		local sum = 0
		bk.recomputeBlocker:On()
		local prefix, i = {} :: { number }, 1
		while i <= (bk.N or 0) do
			prefix[i] = sum
			local offset = bk.sourceList[i]
			-- None is truthy — must be excluded explicitly; nil means broken
			-- bookkeeping (`C-6`: the contract says None), never skip quietly.
			if offset == nil then
				error(`Dispatch.recompute: sourceList[{i}] is nil — bookkeeping is broken (the contract says None)`, 1)
			end
			local abs = getOffsetAt(ownerKey, i)
			bk.offsetSetUpTo = i -- Set done up to here
			if offset ~= None and offset:Get() ~= abs then
				offset:Set(abs) -- ← user code can run here
			end
			-- `H-124`: rewind check BEFORE reading lengthList[i] — user code in
			-- the Set above may have removed slots past the cursor, and dying
			-- between recomputeBlocker:On/Off would freeze this owner forever.
			if bk.offsetSetUpTo < i then
				-- resume AT the lowered slot (`+1` was wrong: prefix[j+1] was
				-- accumulated with the OLD lengthList[j]); clamp to 1 —
				-- offsetSetUpTo can legally be 0 ("1번부터 전부 다시").
				i = math.max(bk.offsetSetUpTo, 1)
				sum = prefix[i]
				continue
			end
			-- `H-244`: same single coercion as getOffsetAt's cache fill — two
			-- inline copies would drift when the coercion gains a case (M6).
			sum += contribution(bk, i)
			i += 1
		end
		-- Cursor close + blocker release BEFORE Length:Set — that Set can run
		-- user code, and stomping a lowered cursor after it would mark unset
		-- slots as done with nobody left to rerun.
		bk.offsetSetUpTo = bk.N or 0
		bk.recomputeBlocker:OffWithoutEmit()
		if Brand.SlotBrand:is(ownerKey) and ownerKey.Length:Get() ~= sum then
			ownerKey.Length:Set(sum) -- Length carries no base — length is position-free
		end
	end

	-- `setLength(ownerKey, i, len, anchor?, element?)` — the one place that
	-- owns calling recompute for length changes (`H-19`). `anchor` is the
	-- lifetime anchor (physical Instance; defaults to ownerKey — only Slot
	-- owners pass it explicitly, `C-4`). `element` is the registered occupant
	-- for the position (`H-141`/Q3): the persistent closure captures it and
	-- looks the current index up in bk.indexOfElement instead of freezing `i`;
	-- constant-length slots omit it.
	local function setLength(ownerKey: any, i: number, len: any, anchor: any?, element: any?)
		anchor = anchor or ownerKey
		local bk = getBookkeeping(ownerKey)
		local blocker = getBlocker(ownerKey)

		local oldObserver = bk.observers[i]
		if oldObserver then
			module.unbindLifetime(oldObserver) -- no need to know gchold internals or which inst
			bk.observers[i] = nil
		end

		bk.lengthList[i] = len
		bk.N = math.max(bk.N or 0, i) -- N lifecycle: grows here only ("저장 위치" 절)
		if element ~= nil then
			bk.indexOfElement[element] = i -- splice-time rewrites are the Slot layer's job (reindexFrom)
		end
		-- invalidation pulls BOTH cursors to `i` — position i's own offset is
		-- the sum of 1..i-1 and does not change; everything AFTER it does.
		bk.offsetCacheValidUpTo = math.min(bk.offsetCacheValidUpTo, i)
		bk.offsetSetUpTo = math.min(bk.offsetSetUpTo, i)

		local function gatedRecompute()
			-- current position by element lookup, not captured index (`H-102`)
			local cur = if element ~= nil then bk.indexOfElement[element] else i
			bk.offsetCacheValidUpTo = math.min(bk.offsetCacheValidUpTo, cur)
			bk.offsetSetUpTo = math.min(bk.offsetSetUpTo, cur)
			if blocker:IsOn() then
				return -- batch registration in progress
			end
			if bk.recomputeBlocker:IsOn() then
				return -- recompute reentry — the outer pass's rewind picks it up
			end
			recompute(ownerKey, bk)
		end

		if Brand.isState(len) then
			local observer = len:Observer(gatedRecompute) -- immediate first run is gated too
			module.bindLifetime(anchor, observer) -- physical target's lifetime, not :Subscribe()
			bk.observers[i] = observer
		else
			gatedRecompute() -- constants go through the same gate
		end
	end

	-- Registration + (if there is a publish channel) one immediate Set — the
	-- batch is processed in order so 1..i-1 are always already registered.
	-- None means "no publish channel", NOT "not participating" (that is
	-- lengthList's answer); pull the number via getOffsetAt when needed.
	local function setOffsetSource(ownerKey: any, i: number, source: any)
		local bk = getBookkeeping(ownerKey)
		bk.sourceList[i] = source
		if source == None then
			return
		end
		local offset = getOffsetAt(ownerKey, i)
		if source:Get() ~= offset then
			source:Set(offset)
		end
	end

	local function drive(inst: any, flattened: { [any]: any })
		-- Pipeline stages ⓪ + (b) + ⓪' (M3 unit 2 wired the batch gating; the
		-- (a) PreRef/PostRef pre-pass and (c) postRefList join in M8 — between
		-- the gate opening and this loop / after it, respectively).
		-- ⓪ batch Blocker — only when there IS an array part (`H-17` guard:
		-- otherwise every childless `Frame { Size = … }` eagerly grows a
		-- Blocker + bk). Single generalized `for` gives array part before hash
		-- part (`F-4-1` — a language behavior base leans on by contract;
		-- spec.drive.luau measures it). Chain entry is always index 1.
		local batching = flattened[1] ~= nil
		local blocker = if batching then getBlocker(inst) else nil
		if blocker then
			blocker:On()
		end
		for k, v in flattened do
			process(inst, k, v, 1)
		end
		-- ⓪' close the batch once, after everything — then exactly one
		-- recompute, itself gated against reentry (`H-119`).
		if blocker then
			blocker:OffWithoutEmit()
			local bk = getBookkeeping(inst)
			if not bk.recomputeBlocker:IsOn() then
				recompute(inst, bk)
			end
		end
	end

	-- Assembled with the declared type so luau-analyze checks this producer
	-- surface against `quad-types` (`H-227` — a bare `:: any` table left the
	-- exact drift `H-25` exists to prevent unchecked on the producing side).
	local Dispatch: Dispatch = {
		getHandler = getHandler,
		process = process,
		retractFrom = retractFrom,
		addHandler = addHandler,
		listHandlers = listHandlers,
		drive = drive,
		setLength = setLength,
		setOffsetSource = setOffsetSource,
		getOffsetAt = getOffsetAt,
		getBlocker = getBlocker,
		getBookkeeping = getBookkeeping,
		HANDLER_PRIORITY_HIGH = HANDLER_PRIORITY_HIGH,
		HANDLER_PRIORITY_NORMAL = HANDLER_PRIORITY_NORMAL,
		HANDLER_PRIORITY_LOW = HANDLER_PRIORITY_LOW,
		HANDLER_PRIORITY_FALLBACK = HANDLER_PRIORITY_FALLBACK,
	}

	-- `H-231`: the public surface joins the tag layer — the walker's boundary.
	-- `H-242`: tag by iterating the assembled surface itself — a hand-written
	-- list here just duplicated the table above and could silently drift
	-- (a missed entry degrades blame with nothing failing).
	for _, v in Dispatch :: { [string]: any } do
		if type(v) == "function" then
			Err.setFuncLevel(v, SURFACE)
		end
	end

	-- M3 unit 3: quad-base fills its own registry with the None pair —
	-- NoneHandler (recursion only) + NilHandler (the one place an empty array
	-- position is registered out of the order math).
	NoneModule.register(Dispatch)
	-- M3 unit 4: ObserverEffectLeafHandler (HIGH — dispatch skeleton) + the
	-- two named-slot dynamic-path guards (FALLBACK — override-able).
	LeafModule.register(Dispatch, module)

	module.Dispatch = Dispatch
end

return Init
