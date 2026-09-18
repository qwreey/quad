--!strict
--[[
	InitLifetimeHandle(module) — the four top-level lifetime primitives
	(`bindLifetime`/`unbindLifetime`/`canBound`/`canExecute`) and the error stubs
	for every injected engine op.
	`.claude/base/lifecycle-pattern.md` "`bindLifetime`/`canBound`/`canExecute`/
	`unbindLifetime` — 확정" section; injection rule from
	`.claude/base/module-lifecycle-plan.md` ("base 유틸(... 생명 바인드 유틸)이
	인터페이스만 두고 실제 구현은 백엔드 팩토리가 뮤테이션으로 주입").

	[2026-09-18 round11 Q59 — user decision] The four primitives are implemented HERE,
	by quad-base. Until then each backend (quad-roblox, mock) carried a full copy of
	`bindLifetime` — and more than half of that copy was quad-base knowledge (the nil
	gates, the three refusal messages, the `_assertBindable` / `_catchUp` /
	`_bindDestroying` hooks of Observer/Effect, the `.Subscribed` arm of the liveness
	predicate). Two backends transcribed the same forty lines, and base-private hooks
	leaked into the provider contract. User: "bindLifetime 자체가 base 가 아는 경계랑
	각 백엔드가 아는 경계가 섞여있다는 점이 문제가 돼 … base 에 사소한 변경만 와도
	백엔드 전부 코드 개편이 불가피함". Now the backend injects only what it alone
	knows — the four hold ops below — and this file composes the primitives on top.

	Contract (types in `quad-types`):
	  -- quad-base implements (this file):
	  bindLifetime(inst, value)   -- inst is needed here and only here
	  unbindLifetime(value)       -- early release of one value; no-op if unbound, nil is an error (`H-474`)
	  canBound(value)  -> boolean -- "may I bind this now?"  true = not bound anywhere
	  canExecute(value)-> boolean -- "may this fire now?"    emit-propagation gate
	  `canBound(v) == not canExecute(v)` — both wrap one predicate (`isBoundAlive` below).
	  -- the backend injects (instance-side knowledge only):
	  holdLifetime(inst, value)   -- put value in inst's strong holder (gchold) and leave the
	                                 liveness evidence (gcconn) on value; throws if inst is not
	                                 quad-owned (quad-roblox) / lazily claims (mock). COMMITS.
	  releaseLifetime(value)      -- the reverse: drop value from its holder, clear the evidence;
	                                 no-op when not held; never touches inst; never runs cleanup.
	  isHeld(value)    -> boolean -- is the evidence on value still alive (gcconn.Connected)?
	  isHeldBy(value, inst) -> boolean -- is value held by THIS inst? (one error-message arm)
	  Names: user decision 2026-09-18 after two independent sonnet opinions — `hold` is the
	  verb of the existing noun `gchold`, `release` sits next to `Bookkeeping.releaseOwner`;
	  attach/detach was dropped because `q.Detach` (keep alive) means the opposite of op 2.

	quad-base knows nothing about Instances, so the injected ops default to stubs
	that error loudly (never a silent no-op — base cannot guess an arbitrary
	engine's "right" default). quad-roblox overwrites them on the module
	instance (`quad-roblox/src/LifetimeHandle.luau`); tests overwrite them with the
	mock backend (`quad-base/test/mock.luau` `installLifetime`, ROADMAP `H-97`).

	They are flat top-level functions, not `LifetimeHandle.bind(...)` —
	first-class primitives handler authors call directly, like `isState`.
	The `onDestroying(inst, fn)` engine op stub is installed here too (M2 unit
	3) — it belongs to the same backend injection and `Effect` needs it.
	2순회 `H-373`: so are `isInst`/`nativeClaim`/`nativeFindChild` (and, since
	2026-09-16, `isClaimed`) — the ops `architecture.md` (EngineOps line) and `slot-plan.md` ("기본 구현(조합
	폴백) — 미주입이 에러가 아니다") classify with `onDestroying` as "cannot be
	composed, so missing = a clear error"; without stubs a bare `Quad.New()`
	raised a nil-call from `Slot/Elements.luau`/`Claim.luau` and blamed quad internals.
]]

local Brand = require("./Brand")
local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")
local NotInstalled = require("./NotInstalled")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local isObserver, isEffect = Brand.isObserver, Brand.isEffect

-- Error depth (checklist 0): `errorBefore` (outermost) for EVERY stub — `H-348`,
-- restored by 3순회 `H-378` after `H-370`/`H-373` gave `canBound`/`canExecute`/
-- `isInst` `errorBeforeNearest`: the stub tags ITSELF (`H-231` below), so
-- "nearest" is always the stub's direct caller — and in-tree that caller is
-- quad internals (`Observer.luau` `Subscribe` → `canBound`, `Slot/Elements.luau` →
-- `isInst`), which blamed `Observer.luau:139`/옛 `Slot.luau:52`(now `Slot/init.luau`). Outermost
-- reaches the user's line from both direct and dispatch-depth calls; what it
-- does not serve is any USER CALLBACK running inside a tagged public method
-- (an Observer/Effect fn, `Tag:Apply`, a handler author's `canBound(v)` line) —
-- those blame the public call that ran the callback; §4 Q7 (untagged stubs).
-- the loud stub factory (`NotInstalled.luau` — one body for the three modules, Q3 ②;
-- the blame reasoning above is repeated in that file's header)
local function notInstalled(name: string): (...any) -> ...any
	return NotInstalled(name, "the lifetime primitives / engine ops", "; tests use mock.installLifetime")
end

local function Init(module: any)
	local Backend = module.Backend

	-- ── the four hold ops: stubs until a backend installs them ──────────
	for _, name in { "holdLifetime", "releaseLifetime", "isHeld", "isHeldBy" } do
		if Backend[name] == nil then
			Backend[name] = notInstalled(name)
		end
	end

	-- ── the four primitives: quad-base's own ────────────────────────────
	-- The hold ops are read from `Backend` at CALL time, never captured here (`H-174`:
	-- a backend installs after `New()`; a capture would pin the stub forever).

	-- private predicate shared by both public entry points (lifecycle-pattern (3)):
	-- "does this value have a structurally live binding?" — (a) the inst-scoped
	-- path the backend answers, (b) the global subscription path (strong or weak —
	-- `H-111`: `WeakSubscribe` raises the flag too) that only Observer/Effect have.
	local function isBoundAlive(value: any): boolean
		if value == nil then
			return false -- round3 `H-444` (G-14): `canExecute(nil)`/`canBound(nil)` died in Relate
		end
		if Backend.isHeld(value) then
			return true
		end
		if isObserver(value) or isEffect(value) then
			return value.Subscribed == true
		end
		return false
	end

	local function canBound(value: any): boolean
		return not isBoundAlive(value)
	end

	local function canExecute(value: any): boolean
		return isBoundAlive(value)
	end

	local function bindLifetime(inst: any, value: any)
		if inst == nil then
			Err.errorBefore("bindLifetime: inst must not be nil", SURFACE) -- round3 `H-447`: its own message, not "Claim it first"
		end
		if value == nil then
			Err.errorBefore("bindLifetime: value must not be nil", SURFACE) -- `H-447`: used to die at `gchold[nil]`
		end
		if not canBound(value) then
			-- Only report which path holds the value. Never index `.Subscribed`
			-- unconditionally — value may be a plain closure.
			local isGlobal = isObserver(value) or isEffect(value)
			if isGlobal then
				isGlobal = value.Subscribed == true
			end
			-- 5순회 `H-395`: say WHICH Instance holds it — the same handle at two
			-- positions of one Instance (`D.Frame { eff, eff }`) is not "another"
			Err.errorBefore(
				if isGlobal
					then "bindLifetime: value is already subscribed"
					elseif Backend.isHeldBy(value, inst) then "bindLifetime: value is already bound to this Instance (the same handle at two positions?)"
					else "bindLifetime: value is already bound to another Instance",
				SURFACE
			)
		end
		-- `H-184`: ask the value's own hook guard BEFORE committing bookkeeping —
		-- if it throws we must not leave a half-bound handle behind. That promise covers
		-- `_assertBindable` ONLY: the catch-up / Destroying hookup below run user callbacks
		-- AFTER the commit, and a throw there leaves the handle bound to this inst (a retry
		-- with the same handle says "already bound to another Instance"). Documented UB —
		-- round10 Q56 (b), user decision 2026-09-17 ("에러로 인해 자료가 깨지는건 일반적이고 …
		-- UB에 가까운것"); no pcall (architecture "예외 안전성 계약 — 감싸지 않는다").
		-- (0.5) `H-229`: a value of no known type has no hooks — pure GC relation.
		if type(value) == "table" and (value :: any)._assertBindable ~= nil then
			(value :: any):_assertBindable()
		end

		-- the commit: the backend's holder + evidence (contracts 1 and 2). Its own gate
		-- ("Instance is not claimed by quad" / "not a mock instance") throws here, before
		-- anything is written — the same "nothing left behind" promise as the gates above.
		Backend.holdLifetime(inst, value)

		if isObserver(value) then
			value:_catchUp() -- `H-159`: one catch-up for emits held before binding
		end
		if isEffect(value) then
			value:_bindDestroying(inst) -- Destroying hookup + held-change catch-up
		end
	end

	local function unbindLifetime(value: any)
		if value == nil then
			-- `H-474` (Gemini 5차 Q31, 사용자: "특별한 이유가 없다면 에러"): `H-444` had made nil a
			-- silent no-op under "no-op if unbound" — nil is not an unbound value, it is a missing
			-- argument, and a silent success there hides the bug (same door as bindLifetime, `H-447`)
			Err.errorBeforeNearest("unbindLifetime: value must not be nil", SURFACE)
		end
		-- symmetric teardown — never calls cleanup, never detaches Ref
		-- callbacks or inner Observers (lifecycle-pattern (1))
		if isEffect(value) then
			value:_unbindDestroying()
		end
		Backend.releaseLifetime(value) -- O(1) early release of this one value; inst untouched
	end

	Backend.bindLifetime = bindLifetime
	Backend.unbindLifetime = unbindLifetime
	Backend.canBound = canBound
	Backend.canExecute = canExecute
	-- `H-238`/`H-231`: every function in the shared error namespace is tagged, or
	-- errorBeforeNearest below these frames cannot find the surface.
	Err.setFuncLevel(SURFACE, bindLifetime, unbindLifetime, canBound, canExecute)

	-- ── injected engine ops: stubs until a backend installs them ────────
	-- `onDestroying(inst, fn): Connection` — the injected engine op `Effect._bindDestroying`
	-- calls (`architecture.md` EngineOps line: a hook, not a manipulation, so no
	-- composition fallback — missing means a clear error). The same backend that
	-- fills the hold ops fills this one; until then, the same loud stub.
	Backend.onDestroying = notInstalled("onDestroying")
	-- `H-373`: the non-composable engine ops (see header) — three then, four with `isClaimed`. `if nil` — a
	-- provider may already be there (same idiom as `Tag.luau`/`Attr/Key.luau`).
	if Backend.isInst == nil then
		Backend.isInst = notInstalled("isInst")
	end
	if Backend.nativeClaim == nil then
		Backend.nativeClaim = notInstalled("nativeClaim")
	end
	-- [2026-09-16] `isClaimed(inst)` — Slot's foreign-element gate (`Slot/Elements.luau`); user decision:
	-- unclaimed elements are rejected, never auto-claimed (question.md §2, 2026-09-16).
	if Backend.isClaimed == nil then
		Backend.isClaimed = notInstalled("isClaimed")
	end
	if Backend.nativeFindChild == nil then
		Backend.nativeFindChild = notInstalled("nativeFindChild")
	end
	-- `H-501` (2026-09-08 2차 감사 H-2): Q6 withdrew the composition fallback and promised
	-- "여섯 전부 필수·미주입이면 안내 스텁 에러" — but the six had no stub at all, so a
	-- backend that forgot one died with `attempt to call a nil value` on a Slot/Raw.luau line.
	for _, name in { "nativeInsert", "nativeExtract", "nativeRemove", "nativeMove", "nativeSwap", "nativeDispose" } do
		if Backend[name] == nil then
			Backend[name] = notInstalled(name)
		end
	end
	-- 2026-09-08: the two time ops (`architecture.md` EngineOps line — the last
	-- "absent" pair, `debounce-throttle-plan.md` 6절). Same "base 범용 유틸" group as
	-- the hold ops: pure Luau has no scheduler at all, so base cannot
	-- default them — `Debounce`/`Throttle` need a backend (or the mock's virtual clock).
	for _, name in { "setTimeout", "clearTimeout" } do
		if Backend[name] == nil then
			Backend[name] = notInstalled(name)
		end
	end
end

return Init
