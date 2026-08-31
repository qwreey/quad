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
	  - `bind-system-plan.md` "`New(name)(props)` 파이프라인 의사코드" — `drive`.
	    M3 unit-1 scope (`qa-request/m3-implementation-round12-brief.md` §6):
	    only stage (b), the single generalized `for`, lives here now. The ⓪/⓪'
	    batch Blocker gating is wired in unit 2 (where `getBlocker`/bookkeeping
	    are born); the (a) PreRef/PostRef pre-pass and (c) postRefList come with
	    M8 (where those values are born).

	Error levels follow `architecture.md` "error 계약": user-side validation
	points at the caller (level 2), broken internal bookkeeping points at
	itself (level 1). Messages in English. The `level 2` on the two
	handler-contract violations (no match / no retractor) is a provisional
	implementation choice — the contract table has no "provider contract
	violation" row and the blame destination through `drive` is an open
	question (`H-219`/`H-222`, round12 §4).
]]

local Relate = require("./Relate")
local Void = require("./Void")
local QuadTypes = require("../roblox_packages/quad_types")
local HandlerModule = require("@self/Handler")

export type Handler = HandlerModule.Handler
export type Dispatch = QuadTypes.Dispatch

type Slot = { handler: Handler, retractor: (nextValue: any?) -> () }

-- Band constants. The docs fix only the names, the ordering (HIGH > NORMAL >
-- LOW > FALLBACK) and that the space is open for ± offsets — the literals are
-- implementation-chosen with room between bands (`H-213`).
local HANDLER_PRIORITY_HIGH = 1000
local HANDLER_PRIORITY_NORMAL = 0
local HANDLER_PRIORITY_LOW = -1000
local HANDLER_PRIORITY_FALLBACK = -1000000

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
	-- {[inst(weak)] = {[k] = {[index] = {handler, retractor}}(strong)}}
	-- ⚠️ The list values hold retractor closures that capture `inst`, so a
	-- chain entry does NOT go away by dropping outside references to `inst`
	-- (no ephemerons in Luau — `relate-plan.md` `H-71`); whoever abandons a
	-- delegated (inst, k) must retract it explicitly. The base-doc contract
	-- wording around this is pending `H-218` (round12 §4).
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
		local list: { Slot }? = chains:GetStrong(inst, k) :: any
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
		local list: { Slot } = chains:GetStrong(inst, k) :: any
		if list == nil then
			list = {}
			chains:SetStrong(inst, k, list)
		end

		local slot = list[index]
		local h = getHandler(inst, k, v)
		if h == nil then
			error(noMatchMessage(k, v), 2)
		end

		if slot ~= nil and slot.handler == h then
			-- (A) same handler — leave everything below untouched; hand the new
			-- value to the sitting retractor so it does its own transition, then
			-- replace this one slot with the fresh retractor.
			-- v is guaranteed to satisfy h.isHandlable — getHandler picked h on v.
			slot.retractor(v)
			slot.retractor = NOOP -- consumed; no double call while h.process recurses
			local retractor = h.process(inst, k, v, index)
			if retractor == nil then
				error(noRetractorMessage(h, k, index), 2)
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
				error(noRetractorMessage(h, k, index), 2)
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
	end

	local function listHandlers(): { Handler }
		-- Pure query — returns the registered handlers in scan order, prints
		-- nothing (`D-8`); whether to display them is the caller's business.
		-- A copy, so callers can't disturb the scan order. Each handler carries
		-- the doc'd name/priority via the optional `name` contract field
		-- (`H-214` (a) — absent name just shows as nil).
		return table.clone(handlers)
	end

	local function drive(inst: any, flattened: { [any]: any })
		-- Pipeline stage (b) only in M3 unit 1 (see header). Single generalized
		-- `for`: Luau's traversal gives the whole array part before the hash
		-- part (`F-4-1`) — that ordering stays a *contract* base promises, and
		-- quad-base keeps it by leaning on exactly this language behavior
		-- (spec.drive.luau measures it). Chain entry is always index 1.
		for k, v in flattened do
			process(inst, k, v, 1)
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
		HANDLER_PRIORITY_HIGH = HANDLER_PRIORITY_HIGH,
		HANDLER_PRIORITY_NORMAL = HANDLER_PRIORITY_NORMAL,
		HANDLER_PRIORITY_LOW = HANDLER_PRIORITY_LOW,
		HANDLER_PRIORITY_FALLBACK = HANDLER_PRIORITY_FALLBACK,
	}

	module.Dispatch = Dispatch
end

return Init
