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
	  - Length/Offset bookkeeping: NOT implemented here — `H-277` moved the
	    whole subsystem to `src/Bookkeeping.luau` (its header carries those
	    sources); this file only re-exports the same function objects on the
	    Dispatch table (the public calling surface, H-39/H-25).

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
local Err = require("./ErrorNamespace")
local InitBookkeeping = require("./Bookkeeping")
local NoneModule = require("@self/None")
local StoreBindModule = require("@self/StoreBind")

local QuadTypes = require("../luau_packages/quad_types")
local HandlerModule = require("@self/Handler")

export type Handler = HandlerModule.Handler
export type Dispatch = QuadTypes.Dispatch

type Slot = { handler: Handler, retractor: (nextValue: any?, retracting: boolean) -> () }

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
		-- Arguments are always (nil, true) here: plain retract with no
		-- follow-up — the `retracting` flag is the `H-258` signal that lets
		-- nil-accepting handlers tell teardown apart from a nil VALUE.
		local list: { Slot }? = chains:GetWeak(inst, k) :: any
		if list == nil then
			return
		end
		for i = #list, index, -1 do
			local slot = list[i]
			if slot == nil then
				error(`quad.Dispatch.retractFrom: no slot at index {i} — the chain array has a hole, bookkeeping is broken`, 1)
			end
			slot.retractor(nil, true)
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
			-- retracting=false (`H-258`): the same handler re-processes next,
			-- so even a nil v is a VALUE here, never a teardown signal.
			slot.retractor(v, false)
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

	-- ── Length/Offset bookkeeping — moved to `src/Bookkeeping.luau` (`H-277`,
	-- user-directed split; dependency {Slot, Dispatch} -> Bookkeeping). The
	-- public calling surface stays on this Dispatch table below — same
	-- function objects, no wrappers (terminal-handler contract H-39/H-25).
	module:RunInit(InitBookkeeping)
	local bookkeeping = module._bookkeeping

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
		local blocker = if batching then bookkeeping.getBlocker(inst) else nil
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
			local bk = bookkeeping.getBookkeeping(inst)
			if not bk.recomputeBlocker:IsOn() then
				bookkeeping.recompute(inst, bk)
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
		setLength = bookkeeping.setLength,
		setOffsetSource = bookkeeping.setOffsetSource,
		getOffsetAt = bookkeeping.getOffsetAt,
		getBlocker = bookkeeping.getBlocker,
		getBookkeeping = bookkeeping.getBookkeeping,
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
	-- M4: StoreBind — the descending diff's own recursion, so it registers
	-- here like the None pair, not from a value module (round13 §0 Q3 (a);
	-- `H-278`'s scope was leaf handlers for one value type). It needs `module`
	-- too: lifetime fields are read at fire time (`H-174`).
	StoreBindModule.register(Dispatch, module)
	-- M3 unit 4 leaf handlers + guards: registered by their OWNING modules
	-- (`H-278`, user-directed — Observer.luau/Effect.luau pull InitDispatch
	-- via RunInit and addHandler in their own Init; "각 객체를 아는 곳은 각
	-- 객체가 선언된 곳").

	module.Dispatch = Dispatch
end

return Init
