--!strict
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
	    runs every stage: ⓪ + (b) + ⓪', the (a) PreRef/PostRef pre-pass and the
	    (c) postRefList (`Dispatch/RefPrePass.luau`).
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
local Brand = require("./Brand") -- `isPlainBranded` — the `H-470` props gate's O(1) half
local DiagnosticsModule = require("@self/Diagnostics") -- match-failure message builders (round15 `H-902`)
local ModifierModule = require("@self/Modifier")
local flatten = ModifierModule.flatten -- M7 단위 ② — drive의 첫 pre-pass(round17 Q4 (a))
local expandSpreads = require("@self/Spread").expand -- [2026-10-20 3.4.0] the pre-pass before flatten
local ProcessedModifier = ModifierModule.ProcessedModifier -- M7 단위 ② — flatten's consumed-slot sentinel
local RefPrePass = require("@self/RefPrePass") -- (a) PreRef/PostRef pre-pass + (c) postRefList

local QuadTypes = require("../luau_packages/quad_types")
local HandlerModule = require("@self/Handler")
local debugPrint = require("./DebugPrint") -- `q.debug` diagnostics (prefix + one channel)

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

-- Brand names for the match-failure message and the `H-470` props gate in `drive` (its full scan only
-- with `q.debug` on — 2026-10-01; it was ~12% of drive on every call, round11 L′ 7). There is
-- deliberately no reverse lookup on Brand (`archive/brand-shared-registry-reversed.md`), so we ask the
-- module's own public predicates. A brand predicate is found by CONTRACT (round3 §4 Q27, user decision
-- 2026-09-08 — no op on Dispatch, user: *"각 프로바이더/플러그인 상 그냥 필드로 넣는게 맞는 계약같아서"*):
-- a top-level module field named `is<Brand>` whose function is registered in the module's
-- `BrandPredicates` set (round13 Q106, 2026-09-28 — only registered `is*` fields count). [2026-10-01 user
-- decision] base brands take the same path: `init.luau` / `Slot/init.luau` register every base `is*`
-- field where they set it, and the hand-kept base probe list that used to live here is gone — Dispatch
-- names no core object (`H-278`). A value answers EVERY predicate it satisfies, so the names are all
-- reported, sorted (`PreRef, Ref`) — user: *"그냥 T 인데 A, B, C 를 impl하는 요소라고 알려주는게 문제가
-- 없는것 같음"*; the old most-specific-first order (`H-220`) is no longer needed.

-- Diagnostics label for a handler in error/warning messages — uses the
-- optional `name` contract field (`H-214` (a)); when absent, only the
-- priority shows (`H-228` — the confirmed wording is "없으면 priority만").
local function describeHandler(h: Handler): string
	return if h.name ~= nil then `"{h.name}" (priority {h.priority})` else `(priority {h.priority})`
end

-- `H-222` provider contract: `process` returns a retractor FUNCTION. The one Quad0077 message — both
-- `process` arms check nil inline (every call, hot path); the full shape is a debug-only check below.
local function noRetractorMessage(h: Handler, k: any, index: number, retractor: any): string
	return `Quad0077 Dispatch: handler {describeHandler(h)} must return a retractor function at key {tostring(k)}, index {index} (got {typeof(retractor)})`
		.. " - return Void when there is nothing to undo"
end

-- ── debug-only checks (`architecture.md` "debug 층"; kept out of the logic below) ──
-- round13 Q148 (user decision 2026-10-01 — debug layer, not every call: *"spring 같은게 들어오면 초당 60번
-- 돌 때 과연 많은 가드가 있는게 유리한가는 모르겠음. debug 면 모를까, 핫패스에 놓인거라"*): a non-function
-- retractor (`true`, `5`, `{}`, a `__call` table — `Quad0079`'s rule for `process` itself) used to be
-- stored and blow up later at retract time, inside quad. Outermost blame, same as the nil check.
local function checkRetractorShape(h: Handler, k: any, index: number, retractor: any)
	if type(retractor) ~= "function" then
		Err.errorBefore(noRetractorMessage(h, k, index, retractor), SURFACE) -- error-code: via noRetractorMessage
	end
end

-- round14 debug detector 3 (user decision 2026-10-06 — replaces the `H-877` callback block, Q166 direction):
-- `process` on an instance the backend does not hold as claimed — destroyed (by `q.dispose` or outside
-- quad) or never made by quad — is undefined: handlers may still run on the corpse (a Tween's `Started`
-- whose `Completed`/`Cancelled` never comes). With `q.debug` on, one line per key — asked only at chain index 1
-- (a top-level call: `drive`, a direct `process`, a delegate starting a fresh chain); the call goes on unchanged.
-- `drive` reaches every key through `process`, so this one place covers both. Why index 1 (round14 확인 패스
-- code-review 2): a delegating handler (StateHandler, NoneHandler) re-dispatches the same key at `index + 1`,
-- so `Source(Source(None))` printed the same line four times. A deeper index on a dead instance is only ever
-- that synchronous recursion under a call that already printed — a later State emission cannot reach a dead
-- instance (the handle bound to it fails `canExecute` once the instance dies, so its change is held).
local function checkClaimedTarget(inst: any, k: any, isClaimed: (any) -> boolean)
	if inst ~= nil and not isClaimed(inst) then
		debugPrint(`Dispatch: process on an instance that is not claimed by quad (destroyed - by q.dispose or outside quad - or not made by quad) at key {tostring(k)} - what the handlers do there is undefined; build a new instance`)
	end
end

-- `H-470` props gate: the one Quad0083 literal — `drive`'s O(1) check and the debug scan below both raise it.
local function propsNotPlainMessage(what: string): string
	return `Quad0083 Dispatch.drive: props must be a plain \{ ... \} table - a quad value needs the braces (got {what})`
end

-- [2026-10-01 user decision — "debug 로 내리기에 동의해"] the braces-forgotten gate's FULL brand scan
-- (`brandNameOf`: every registered `is<Brand>` field of the module, each pcall'd — ~12% of drive,
-- round11 L′ 7) runs only with `q.debug` on. The every-call half in `drive` is O(1): a metatable or a
-- metatable-less base brand (`Brand.isPlainBranded`). What only this scan catches: a value branded by a
-- PROVIDER predicate that carries no metatable — with debug off its fields are dispatched like props and
-- fail (or land) wherever their keys lead.
local function checkPropsBrand(flattened: any, brandNameOf: (any) -> string?)
	local brand = brandNameOf(flattened)
	if brand ~= nil then
		Err.errorBefore(propsNotPlainMessage(brand), SURFACE) -- error-code: via propsNotPlainMessage
	end
end

-- The `Processed*` nop terminal (ProcessedModifier / ProcessedPreRef / ProcessedPostRef —
-- `modifier-plan.md` `H-35` block, `ref-plan.md` canon): matches the sentinel by identity anywhere
-- (it only ever sits at array positions), registers the position out of the order math and retracts
-- with `Void` — flatten / the pre-pass fire already happened, nothing to undo. One factory for the
-- three (Q3 ⑤); 2026-10-01 moved here from 옛 `Dispatch/None.luau` — these are the drive's own
-- sentinels, so Dispatch registers them itself.
local function addProcessedHandler(dispatch: Dispatch, bookkeeping: QuadTypes.Bookkeeping, name: string, sent: any)
	dispatch.addHandler({
		name = name,
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			return v == sent
		end,
		priority = HANDLER_PRIORITY_HIGH, -- "매우 높음, NoneHandler와 동급"
		process = function(inst: any, k: any, _v: any, _index: number): (any?, boolean) -> ()
			bookkeeping.setEmpty(inst, k, inst) -- canon block: offsetSource → length 0 (`H-35`)
			return Void
		end,
	})
end

local function Init(module: any)
	-- {[inst(weak)] = {[k] = {[index] = {handler, retractor}}(weak value)}}
	-- `H-229`: the lists hold retractor closures that (transitively) capture
	-- `inst`, so holding them strongly here would make the bucket value
	-- back-reference its own weak key — the `H-71` "leaks 100%" pattern (no
	-- ephemerons in Luau), and Destroy calls no retract by contract. So the
	-- strong anchor is NOT chains but the instance's own gchold:
	-- `module.Backend.bindLifetime(inst, list)` on list creation ties the list's
	-- lifetime to the bind lifetime — Destroy collapses the gchold island and
	-- the whole chain graph (lists, retractors, observers, the inst userdata)
	-- becomes collectable, with retractors never called (contract kept; this
	-- is memory release, not teardown). Same medicine as the two-Relate cycle
	-- fix in `slot-plan.md` (everything weak + one anchor via bindLifetime).
	-- Consequence: any inst entering Dispatch must be claimable by the
	-- installed lifetime backend (nativeClaim'd real Instance, or the mock).
	local chains = Relate()
	local handlers: { Handler } = {} -- kept sorted, higher priority first
	-- round13 Q135 follow-up (user decision 2026-10-01): `debugOnly` handlers live in their own
	-- sorted array, never in `handlers`: `table.sort` is unstable, so inserting them there reshuffled
	-- equal-priority PRODUCTION handlers (prototype first cut, measured: `[AttrKey] = q.Effect(…)`
	-- flipped from the raw attribute error to `Quad0097` with debug OFF). Kept apart, `handlers` sees
	-- exactly the same insert/sort sequence as without them, so production order is unchanged.
	local debugHandlers: { Handler } = {}
	-- `H-484` (round7 Q37 (a), user decision 2026-09-08): per-key-type scan lists,
	-- each = the handlers DECLARING that `keyType` ∪ the undeclared ones, in the
	-- same priority order as `handlers`. Rebuilt on every addHandler (cold path).
	-- Measured before: a 10-string-prop `Frame` element asked 22 handlers 150 times;
	-- 12 of them can only ever match number keys.
	-- `debugOnly`: two sets of the same three buckets: `buckets` without the `debugOnly`
	-- handlers (what production scans), `debugBuckets` with them. `getHandler` picks one by reading
	-- `module.debug` at call time (the flag is a plain field — toggling it takes effect on the next scan).
	-- Both are rebuilt here, on the cold path; the hot path pays one field read + one branch.
	type Buckets = { number: { Handler }, string: { Handler }, other: { Handler } }
	local buckets: Buckets = { number = {}, string = {}, other = {} }
	local debugBuckets: Buckets = { number = {}, string = {}, other = {} }
	local function fill(into: Buckets, list: { Handler })
		for _, h in list do
			local kt = h.keyType
			if kt == nil or kt == "number" then table.insert(into.number, h) end
			if kt == nil or kt == "string" then table.insert(into.string, h) end
			if kt == nil then table.insert(into.other, h) end
		end
	end
	-- production order merged with the debug handlers: a stable merge, so the relative order of the
	-- production handlers in debug mode is the SAME as with debug off (a debug toggle never changes
	-- which of two tied production handlers wins). On a priority tie the debug handler goes first.
	local function merged(): { Handler }
		if #debugHandlers == 0 then
			return handlers
		end
		local out: { Handler } = {}
		local i, j = 1, 1
		while i <= #handlers or j <= #debugHandlers do
			local p, d = handlers[i], debugHandlers[j]
			if d ~= nil and (p == nil or d.priority >= p.priority) then
				table.insert(out, d)
				j += 1
			else
				table.insert(out, p)
				i += 1
			end
		end
		return out
	end
	local function rebuildBuckets()
		buckets = { number = {}, string = {}, other = {} }
		debugBuckets = { number = {}, string = {}, other = {} }
		fill(buckets, handlers)
		fill(debugBuckets, merged())
	end
	local NOOP = Void -- `H-162`: the single exported no-op, never a fresh closure

	-- the match-failure diagnostics (cold path) — `Dispatch/Diagnostics.luau` (round15 `H-902`: pure pieces out of this closure)
	local diagnostics = DiagnosticsModule(module)
	local brandNameOf, noMatchMessage = diagnostics.brandNameOf, diagnostics.noMatchMessage

	-- `release` (`H-329`, 사용자 확정 (a) 2026-09-06): a PURE retract that empties
	-- the chain also drops the list from `chains` and from the inst's gchold —
	-- otherwise every fresh key (the per-object group keys `State<Attr>`
	-- emits) leaves an empty list + its key alive for the instance's lifetime
	-- (fable 탐사 X-1: ~500 B per emit). The (B) branch of `process` passes
	-- false: it reinstalls into the SAME list right after, so releasing there
	-- would cut the chain it is about to fill.
	local function retractRange(inst: any, k: any, index: number, release: boolean)
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
				error(`Quad0071 Dispatch.retractFrom: no slot at index {i} - the chain array has a hole, bookkeeping is broken`, 1)
			end
			slot.retractor(nil, true)
			list[i] = nil
		end
		if release and #list == 0 then
			module.Backend.unbindLifetime(list) -- the `H-229` anchor — pure GC relation, symmetric release
			chains:SetWeak(inst, k, nil)
		end
	end

	-- `H-504` (2026-09-08 round8 K-2): public `process`/`retractFrom` with a nil inst died
	-- in Relate (`table index is nil`, now `Relate:GetWeak: inst must not be nil`) — a leaf
	-- module's name in a user message. Same gate as `drive` (`H-442`), nearest (direct call).
	local function checkInst(fnName: string, inst: any)
		if inst == nil then
			Err.errorBeforeNearest(`Quad0072 Dispatch.{fnName}: inst must not be nil`, SURFACE)
		end
	end

	-- [2026-09-16 hunt F] chain depth is a positive-integer domain like the array positions
	-- `Bookkeeping.checkPosition` guards (`H-256`): a fractional index parked a retractor at
	-- `list[1.5]` that no unwind ever visited, 0/negative surfaced as "bookkeeping is broken",
	-- a string as a raw VM error.
	local function checkIndex(fnName: string, index: any)
		if type(index) ~= "number" or index % 1 ~= 0 or index < 1 then
			Err.errorBeforeNearest(`Quad0073 Dispatch.{fnName}: index must be a positive integer (got {tostring(index)})`, SURFACE)
		end
	end

	local function checkKey(fnName: string, k: any) -- round11 `H-565` (탐사 G′ 3, `H-504`'s other half)
		if k == nil then
			Err.errorBeforeNearest(`Quad0074 Dispatch.{fnName}: key must not be nil`, SURFACE)
		end
	end

	-- Pure scan: first handler (in priority order) whose isHandlable accepts.
	-- Returns nil on no match — the immediate error is `process`'s job, so the
	-- failure message is only ever built there ("에러 메시지는 매치 실패
	-- 시에만" — 핸들러 계약 절의 지연 생성 규칙). `H-603` (round13 E2): this is
	-- also the PUBLIC `getHandler`, called directly with no `process`/`retractFrom`
	-- in front of it — without its own gate, `inst`/`key = nil` fell straight into
	-- `h.isHandlable`, and the resulting VM error named a leaf module (e.g.
	-- `Handlers/Property.luau`) instead of quad. Same gate, same blame posture
	-- (nearest) as its siblings — no new error id, `checkInst`/`checkKey` already
	-- carry `Quad0072`/`Quad0074`. NOT covered: a non-nil `inst` shaped unlike an
	-- Instance (e.g. `{}`) still reaches `isHandlable` and can still surface a
	-- leaf-module error (e.g. `Reflection.luau`) — `process` dodges this only
	-- incidentally, via its own `bindLifetime` claim-check, which `getHandler` (a
	-- pure scan with no side effects) must not replicate; closing that gap needs a
	-- new inst-shape check this round doesn't introduce.
	-- The one exception to "no side effects": with `module.debug` on, the scan also asks the
	-- `debugOnly` handlers, whose `isHandlable` may print a diagnostic (`DebugKeyFilter.luau`).
	-- [2026-10-06 user decision, round14 Q168 (a)] the scan body without the gates — `process` already
	-- ran `checkInst`/`checkKey` on the same arguments, so it calls this directly; the public
	-- `getHandler` below keeps its own gates (`H-603`). Untagged local (no blame role).
	local function scanHandler(inst: any, k: any, v: any): Handler?
		local kt = type(k)
		local set = if module.debug then debugBuckets else buckets -- the one `debugOnly` branch on the hot path
		local list = if kt == "number" then set.number elseif kt == "string" then set.string else set.other
		for _, h in list do
			if h.isHandlable(inst, k, v) then
				return h
			end
		end
		return nil
	end
	local function getHandler(inst: any, k: any, v: any): Handler?
		checkInst("getHandler", inst)
		checkKey("getHandler", k)
		return scanHandler(inst, k, v)
	end

	local function retractFrom(inst: any, k: any, index: number)
		checkInst("retractFrom", inst)
		checkKey("retractFrom", k)
		checkIndex("retractFrom", index)
		retractRange(inst, k, index, true)
	end

	local function process(inst: any, k: any, v: any, index: number)
		if module.debug and index == 1 then checkClaimedTarget(inst, k, module.Backend.isClaimed) end -- detector 3 (debug-only, file head; once per key)
		checkInst("process", inst)
		checkKey("process", k)
		checkIndex("process", index)
		-- [순서 주의] list 확보 + chains 등록은 반드시 h.process 호출 *전에* —
		-- h.process가 재귀 Dispatch.process(inst,k,…,index+1)를 부르는 게 정상
		-- 경로이고(StateHandler/NoneHandler), 그때 chains에 이 list가 아직 없으면
		-- 재귀 호출이 자기만의 새 테이블을 만들어 저장한 뒤 바깥이 덮어써서
		-- 하위 위임 retractor가 통째로 유실됨(최초 마운트에서 항상 발생).
		local list: { Slot } = chains:GetWeak(inst, k) :: any
		if list == nil then
			list = {}
			-- Anchor first (`H-229`): the list lives exactly as long as the
			-- inst's bind lifetime (gchold), chains only holds it weakly.
			-- bindLifetime treats a value matching no known type as a pure GC
			-- relation (user-confirmed contract, `lifecycle-pattern.md`).
			module.Backend.bindLifetime(inst, list)
			chains:SetWeak(inst, k, list)
		end
		if index > #list + 1 then
			-- round11 `H-564` (탐사 G′ 2, `H-256`'s sibling): a gap index parked a slot no unwind ever
			-- visits (`retractRange` starts at #list) and `release and #list == 0` then dropped the
			-- list with a live retractor in it — dispatch-core-plan "list가 구멍 없는 시퀀스"
			Err.errorBeforeNearest(`Quad0075 Dispatch.process: index {index} would leave a gap in the chain (the chain has {#list} slots - a delegating handler passes index + 1)`, SURFACE)
		end

		local slot = list[index]
		local matched = scanHandler(inst, k, v) -- gates already ran above (Q168 (a))
		if matched == nil then
			-- `H-219`/`H-231`: outermost scan — climbs every wrapper (drive, a
			-- delegating handler, later the M5 pipeline) to the user's entry.
			Err.errorBefore(noMatchMessage(k, v), SURFACE) -- error-code: via noMatchMessage
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
				-- provider-contract violation (`H-222`) — OUTERMOST: this fires at
				-- dispatch depth so nearest blamed `init.luau` itself (6순회 `H-409`,
				-- the sibling `noMatchMessage` already uses errorBefore)
				Err.errorBefore(noRetractorMessage(h, k, index, retractor), SURFACE) -- error-code: via noRetractorMessage
			end
			if module.debug then
				checkRetractorShape(h, k, index, retractor)
			end
			slot.retractor = retractor
		else
			-- (B) different handler (or empty slot) — retract this slot and below,
			-- then install fresh (no release — same list, `H-329`).
			retractRange(inst, k, index, false)
			-- Occupancy marker first: while h.process recurses, `list` must stay a
			-- hole-free sequence for `#list` to be defined (`#` on holey tables is
			-- unspecified).
			list[index] = { handler = h, retractor = NOOP }
			local retractor = h.process(inst, k, v, index)
			if retractor == nil then
				Err.errorBefore(noRetractorMessage(h, k, index, retractor), SURFACE) -- error-code: via noRetractorMessage -- `H-409`
			end
			if module.debug then
				checkRetractorShape(h, k, index, retractor)
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
		-- `H-493` (2026-09-08 2차 감사 I-3): shape gate BEFORE anything reads the table —
		-- a non-table died indexing `keyType` with a VM error, and a missing `process`
		-- reached the setFuncLevel tagging below, whose "renamed or missing method?"
		-- diagnostic is about quad's own tables, not a provider's input.
		if type(handler) ~= "table" or type(handler.isHandlable) ~= "function"
			or type(handler.process) ~= "function" or type(handler.priority) ~= "number" then
			Err.errorBeforeNearest(`Quad0079 Dispatch.addHandler: handler must be a table with isHandlable/process functions and a numeric priority (got {typeof(handler)})`, SURFACE)
		end
		-- Tie detection is free at registration time (the registry is sorted
		-- here, statically). No tiebreak rule is enforced — ties are usually a
		-- handler-design mistake, surfaced via debug visibility only.
		local pr = handler.priority
		if pr ~= pr or pr == math.huge or pr == -math.huge then
			-- round11 `H-568` (탐사 G′ 7): NaN sorted anywhere and defeated the tie print (`==` false)
			Err.errorBeforeNearest(`Quad0080 Dispatch.addHandler: priority must be a finite number (got {tostring(pr)})`, SURFACE)
		end
		for _, existing in handlers do
			if existing == handler then
				return -- round11 `H-568` (탐사 G′ 8): identity dedup, like RunInit/AddPlugin/UseProvider
			end
		end
		for _, existing in debugHandlers do
			if existing == handler then
				return -- same identity dedup over the `debugOnly` array
			end
		end
		local kt = handler.keyType
		if kt ~= nil and kt ~= "number" and kt ~= "string" then
			-- registration gate (`H-484`): a typo here would silently drop the handler
			-- from every bucket — say so where the provider registered it (and before
			-- the tie print below, so a rejected handler leaves no misleading line)
			Err.errorBeforeNearest(`Quad0081 Dispatch.addHandler: keyType must be "number", "string" or nil (got {tostring(kt)})`, SURFACE)
		end
		local fd = handler.debugOnly
		if fd ~= nil and type(fd) ~= "boolean" then
			-- same posture as Quad0081: a truthy non-boolean (`"yes"`, `1`) would
			-- otherwise silently land in the production buckets (only `== true` moves a handler out)
			Err.errorBeforeNearest(`Quad0266 Dispatch.addHandler: debugOnly must be a boolean or nil (got {typeof(fd)})`, SURFACE)
		end
		if module.debug then
			for _, existing in merged() do -- `debugOnly` handlers compete only in debug, and this print is debug-only too
				-- two handlers declaring DIFFERENT key types never share a bucket, so
				-- their equal priority is not a tie (`H-484` follow-up, code-review)
				local ekt = existing.keyType
				local canCompete = kt == nil or ekt == nil or kt == ekt
				if canCompete and existing.priority == handler.priority then
					debugPrint(
						`Dispatch.addHandler: handler priority tie between {describeHandler(existing)}`
							.. ` and {describeHandler(handler)}`
							.. " - ties have no defined order; offset from a HANDLER_PRIORITY_* band"
					)
					break
				end
			end
		end
		local into = if fd == true then debugHandlers else handlers
		table.insert(into, handler)
		table.sort(into, function(a: Handler, b: Handler)
			return a.priority > b.priority
		end)
		rebuildBuckets()
		-- `H-231`: received closures join the surface layer at receipt time
		-- (user's rule — "입력 받은 측에서 level을 설정") so the walker sees
		-- provider frames as quad machinery, not as user code.
		Err.setFuncLevel(SURFACE, handler.isHandlable)
		Err.setFuncLevel(SURFACE, handler.process)
	end

	local function listHandlers(): { Handler }
		-- Pure query — returns every registered handler in priority order (the
		-- union of the three per-key-type scan lists, `H-484` — a given key only
		-- ever asks the list for its `type(k)`), prints nothing (`D-8`); whether to
		-- display them is the caller's business.
		-- `table.clone` is shallow: only this array is a copy — the Handler tables inside
		-- it are the live registry entries, not copies (`H-602`, round13 E2: mutating a
		-- returned handler's `isHandlable` changed real dispatch behavior). Callers may
		-- read but must not write. Each handler carries the doc'd name/priority via the
		-- optional `name` contract field (`H-214` (a) — absent name just shows as nil).
		return table.clone(merged()) -- every registered handler, `debugOnly` ones included (each carries its field)
	end

	-- ── Length/Offset bookkeeping — moved to `src/Bookkeeping.luau` (`H-277`,
	-- user-directed split; dependency {Slot, Dispatch} -> Bookkeeping). [2026-09-15 공개 표면 (30)]
	-- its public surface is its own namespace `module.Bookkeeping` — no longer re-exported here.
	module:RunInit(InitBookkeeping)
	local bookkeeping = module.Bookkeeping

	local function drive(inst: any, flattened: { [any]: any })
		-- `H-419` (외부 리뷰 G-07): a non-table props value used to die inside
		-- `flatten` (`#input` / `next` — VM error blaming Dispatch/Modifier/init.luau); strict
		-- typing is the first defense, this is the untyped-caller one
		if type(flattened) ~= "table" then
			Err.errorBefore(`Quad0082 Dispatch.drive: props must be a table (got {typeof(flattened)})`, SURFACE)
		end
		-- `H-470` (탐사 A): the braces-forgotten form `q.Elem "Frame" (q.Source(1))` — every sibling
		-- constructor refuses a quad value where a plain table is due (`H-204`/`H-377`/
		-- `H-386`/`H-389`), and canon says `flattened` is always a plain table
		-- (dispatch-core-plan "`flattened`는 항상 평범한 Luau 테이블이다"). Without this the
		-- value's own fields were dispatched: a frozen `AttrKey("x")` is `{ Name = "x" }`,
		-- which quad-roblox's Property handler wrote — a silent rename.
		-- [2026-10-01 user decision] every call pays O(1) only (a metatable, or a metatable-less base
		-- brand); the full `brandNameOf` scan is debug-only (`checkPropsBrand` above). The name in the
		-- message is still looked up here — that is the failure path.
		if getmetatable(flattened) ~= nil or Brand.isPlainBranded(flattened) then
			Err.errorBefore(propsNotPlainMessage(brandNameOf(flattened) or "a table with a metatable"), SURFACE) -- error-code: via propsNotPlainMessage
		end
		if module.debug then
			checkPropsBrand(flattened, brandNameOf)
		end
		if inst == nil then
			Err.errorBefore("Quad0084 Dispatch.drive: inst must not be nil", SURFACE) -- round3 `H-442` (G-12): died in Relate with `table index is nil`
		end
		-- Pipeline stages ⓪ + (b) + ⓪'; the (a) PreRef/PostRef pre-pass runs
		-- between the gate opening and this loop, the (c) postRefList after it.
		-- ⓪ batch Blocker — only when there IS an array part (`H-17` guard:
		-- otherwise every childless `Frame { Size = … }` eagerly grows a
		-- Blocker + bk). Single generalized `for` gives array part before hash
		-- part (`F-4-1` — a language behavior base leans on by contract;
		-- spec.drive.luau measures it). Chain entry is always index 1.
		-- ③ flatten — Modifier slots consumed in place (`ProcessedModifier`),
		-- fields merged into the hash part. Owned HERE, not by `New` (round17
		-- §0 Q4 (a), 2026-09-04): one call site serves `New` and `Claim` alike.
		-- [2026-10-20 3.4.0] Spreads are expanded FIRST (canon order: Spread → Modifier → PreRef → body —
		-- component-flatten-sugar-plan 5절 (3)): their array values take the Spread's slot (the array
		-- length can change — so this, too, runs before the batching test), their keys fill keys still
		-- empty, and Modifier flatten then fills what remains.
		-- flatten's hash-part walk also carries the array-key domain check
		-- (`Quad0085`, `H-495`) — no separate full pass here (2026-10-02 사용자).
		expandSpreads(flattened, module.debug)
		flatten(flattened)
		local batching = flattened[1] ~= nil
		local blocker = if batching then bookkeeping._getBlocker(inst) else nil
		if blocker then
			blocker:On()
		end
		-- (a) M8 단위 ②: PreRef fires here (hoisted, index order), PostRef is
		-- collected; both slots become `Processed*Ref` so the array stays
		-- hole-free for the body loop (Dispatch/RefPrePass.luau). AFTER the gate opens
		-- (canon ⓪ → (a)): a PreRef callback that touches this inst's
		-- bookkeeping must be absorbed like everything else in the batch
		-- (review finding — before the gate it crashed in recompute).
		local postRefList = RefPrePass.prePass(inst, flattened)
		for k, v in flattened do
			process(inst, k, v, 1)
		end
		-- (c) M8 단위 ②: PostRef fires after the body loop, BEFORE the batch
		-- closes — the gate is still on, so a callback's `slot:Add`-style
		-- mutation is absorbed and the single recompute below catches up
		-- (`H-17`: "post-pass 포함 … 한 뒤 OffWithoutEmit"; bind-system
		-- pipeline (c) precedes ⓪'). Every child of this instance is already
		-- placed physically by its handler (ref-plan "`PostRef`" 절).
		if postRefList then
			RefPrePass.firePostRefs(inst, postRefList)
		end
		-- ⓪' close the batch once, after everything — then exactly one
		-- recompute, itself gated against reentry (`H-119`).
		if blocker then
			blocker:OffWithoutEmit()
			local bk = bookkeeping.getBookkeeping(inst)
			if not bk.recomputeBlocker.Blocking then
				bookkeeping._recompute(inst, bk)
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
			Err.setFuncLevel(SURFACE, v)
		end
	end

	-- Dispatch's own terminals only — nothing here knows a core value type (2026-10-01 user decision:
	-- *"Dispatch 가 코어 객체들을 아는 방향이 되지 않아야하니까"*).
	-- M3 unit 3: NilHandler — the one place a real `nil` at an array position (an empty seat, not an
	-- object: `State<Slot|nil>` must work without forcing `None`; hash-key `nil` belongs to that key's
	-- own handler) is registered out of the order math. Mounts nothing: `setEmpty(inst, k)` =
	-- offsetSource None → length 0 (release-order contract). `H-39`: terminal handlers register
	-- without exception — this one IS that registration. Constant length → no `element` argument.
	Dispatch.addHandler({
		name = "NilHandler",
		keyType = "number", -- `H-484`: only number keys can match (isHandlable checks it too)
		isHandlable = function(_inst: any, k: any, v: any): boolean
			return type(k) == "number" and v == nil
		end,
		priority = HANDLER_PRIORITY_HIGH,
		process = function(inst: any, k: any, _v: any, _index: number): (any?, boolean) -> ()
			-- no recursion — already nil, nothing further to hand down
			bookkeeping.setEmpty(inst, k)
			return Void
		end,
	})
	-- M7 단위 ② / M8 단위 ②: the nop terminals of drive's own pre-passes (`H-35`, `ref-plan.md` canon)
	addProcessedHandler(Dispatch, bookkeeping, "ProcessedModifierHandler", ProcessedModifier)
	addProcessedHandler(Dispatch, bookkeeping, "ProcessedPreRefHandler", RefPrePass.ProcessedPreRef)
	addProcessedHandler(Dispatch, bookkeeping, "ProcessedPostRefHandler", RefPrePass.ProcessedPostRef)
	-- Everything else is registered by the module that OWNS the value type (`H-278`, user-directed —
	-- each pulls InitDispatch via RunInit and calls addHandler in its own Init; "각 객체를 아는 곳은
	-- 각 객체가 선언된 곳"): NoneHandler by `None.luau`, StateHandler by `State.luau` (2026-10-01 — both
	-- were registered here before), leaf handlers and guards by Observer/Effect/Ref/Slot/Tag/Attr.

	module.Dispatch = Dispatch
end

return Init
