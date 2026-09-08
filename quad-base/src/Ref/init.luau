--[[
	Ref — general value box. Minimal M2 form (`ROADMAP.md` M2 "공통 기반",
	9라운드 `H-128`): `.Value` / `.Revision` / `:Set` / `:Callback` /
	`:WeakCallback` / `:Uncallback` + `isRef`, and `EpochBrand` membership.
	M8 단위 ① adds `:Wait(thread?)` (below); `PreRef`/`PostRef` live in their
	own files (same runtime, brand + `_fired`), the dispatch handlers in unit ②.

	Sources, as-is:
	  - `.claude/base/ref-plan.md` "API 모양" (surface, self-returning
	    mutations, "already filled → call once on registration"),
	    "`.Callbacks`는 배열이 아니라" (dedup contract, snapshot before
	    iterating), "`:WeakCallback(fn)`" (weak-key table `.WeakCallbacks`,
	    Weak is the primitive and `:Callback` only adds the GC keep),
	    "`:Set(value)`의 순서" (value → revision → callbacks; the code below
	    is that block), "`Ref`는 `Epoch`를 만족한다" (`.Revision`, brand).
	  - `.claude/base/state-epoch-plan.md` §2: revision bump is the uint32
	    wrap-around decrement `bit32.bnot(-rev)`; only `==`/`~=` are contract.

	Single type parameter, `Ref<T>(T) -> Ref<T>` (`ref-plan.md` "제네릭
	시그니처"): a nil-able slot is widened by the caller, `Ref<<T?>>(nil)`.

	Callback signature is `fn(value, ref)` — the second argument is the Ref
	itself, i.e. the `Epoch` a consumer (`Effect`) feeds to `EpochMap:Update`.
	Plain user callbacks just ignore it.

	`Ref` is NOT a State: no emit propagation, no `Get`/`Compute`. Being an
	`Epoch` only means "carries a mark distinguishable from the previous one".
]]

local Brand = require("./Brand")
local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")
local Relate = require("./Relate")
local Void = require("./Void")
local InitDispatch = require("./Dispatch")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

export type Ref<T> = QuadTypes.Ref<T>
type Callback<T> = QuadTypes.RefCallback<T>

local RefBrand = Brand.RefBrand
local EpochBrand = Brand.EpochBrand

local WEAK_KEY_MT = { __mode = "k" }

local RefImpl = {}
RefImpl.__index = RefImpl
-- phantom type field (`H-321`): never called — the TYPE carries T in a
-- contravariant slot so class-checked children admit ancestor boxes. Lives on
-- the metatable (one slot, `__index`-resolved) rather than per instance: the
-- value is identical for every Ref and H-300 only asks that `ref.__quadRefAccepts`
-- reads as the type promises (review, M8 ③).
RefImpl.__quadRefAccepts = Void
-- `__tostring` (2026-09-08, advisory 권고 1): the nominal kind (PreRef/PostRef carry their H-300
-- marker on the instance) + the current value
function RefImpl.__tostring(self: any): string
	local kind = if rawget(self, "__quadPreRef") then "PreRef" elseif rawget(self, "__quadPostRef") then "PostRef" else "Ref"
	return `{kind}({tostring(self.Value)})`
end

function RefImpl.Set<T>(self: Ref<T>, value: T): Ref<T>
	self.Value = value -- (1) settle the value first
	self.Revision = bit32.bnot(-self.Revision) -- (2) before callbacks (`H-108`)

	-- (3) snapshot before iterating (`H-23`): registering/unregistering during
	-- the walk must not disturb the iteration. `H-208` (user, 2026-08-31):
	-- `table.clone` + set-merge — cheaper than rebuilding an array, and the
	-- strong plain clone keeps weak-registered callbacks alive for the walk.
	-- Both-table dedup is free (set semantics); `:Wait()` (M8) puts its thread
	-- waiters in `.Callbacks` only, so draining below stays right.
	local callbacks = self.Callbacks
	local weakCallbacks = self.WeakCallbacks
	local snapshot: { [any]: true } = table.clone(callbacks)
	for k in weakCallbacks do
		snapshot[k] = true
	end
	local revision = self.Revision
	for k in snapshot do
		if self.Revision ~= revision then
			-- [`H-169`, user-confirmed 2026-08-28] a callback re-entered `:Set`: that
			-- inner walk already delivered the newer value to everyone, so this
			-- walk drops the rest — a callback never receives a stale value.
			break
		end
		if callbacks[k] == nil and weakCallbacks[k] == nil then
			continue -- released while we were walking
		end
		if type(k) == "thread" then
			callbacks[k] = nil -- waiters are consumed
			-- the Ref itself, not the value. [`H-170`, user-confirmed] `resume` never
			-- raises; the immediately returned failure is re-raised here (a later
			-- yield's fate is out of our hands), per the "no pcall" contract.
			-- 6순회 `H-411`: `Wait(thread)` may have registered the CURRENT coroutine,
			-- and resuming a running coroutine is a raw VM error with no position —
			-- say what happened instead (a dead thread stays UB, `H-170`/`H-339`)
			local status = coroutine.status(k)
			if status == "running" or status == "normal" then -- 7순회 `H-426`: "normal" = the waiter resumed us
				Err.errorBeforeNearest(`Ref: cannot :Set from the coroutine that is waiting on this Ref, nor from one it resumed (Wait(thread) registered a {status} coroutine)`, SURFACE)
			end
			local ok, err = coroutine.resume(k, self)
			if not ok then
				error(err, 0)
			end
		else
			-- value + the Ref itself (= `Epoch`). The cast only quiets the checker:
			-- `k` comes from a `{ any }` snapshot and the `thread` branch is above.
			(k :: Callback<T>)(value, self)
		end
	end
	return self
end

-- "Weak" is the primitive: same behaviour, same guards, only the GC keep
-- removed. Registration calls the callback once right away with whatever
-- is there — nil/unset included (`H-120`; the nil guard is the caller's,
-- `base/lifecycle-hooks-plan.md`).
-- `H-473` (Gemini 5차 G-22): nil died at `WeakCallbacks[nil]`, a non-function at the call —
-- both VM lines inside this file. One gate, three doors.
local function checkCallback(fn: any, surface: string)
	if type(fn) ~= "function" then
		Err.errorBeforeNearest(`{surface}: callback must be a function (got {typeof(fn)})`, SURFACE)
	end
end

function RefImpl.WeakCallback<T>(self: Ref<T>, fn: Callback<T>): Ref<T>
	checkCallback(fn, "Ref:WeakCallback")
	self.WeakCallbacks[fn] = true
	fn(self.Value, self)
	return self
end

function RefImpl.Callback<T>(self: Ref<T>, fn: Callback<T>): Ref<T>
	checkCallback(fn, "Ref:Callback")
	self.Callbacks[fn] = true -- the strong keep, on top of the weak primitive
	fn(self.Value, self)
	return self
end

-- `:Wait(thread?)` — the waiter side of the thread-key branch in `:Set`.
-- No argument: capture the running coroutine, register it as a waiter and
-- yield here; `:Set` consumes the key and resumes it with the Ref itself, so
-- `ref:Wait().Value` reads the fresh value. ALWAYS waits for the NEXT `:Set`,
-- filled or not (M8 brief §0 Q5 (a), user: "항상 기다리면 돼" — `nil` is a
-- legitimate value in `Ref<<T?>>`, so "filled" is not decidable here; the
-- `if ref.Value then … else ref:Wait().Value` idiom does the pre-check).
-- An explicit thread: register only and return at once — a coroutine can
-- only suspend itself, never someone else's already-suspended thread
-- (`ref-plan.md` "API 모양"). Dedup is free (set semantics).
function RefImpl.Wait<T>(self: Ref<T>, thread: thread?): Ref<T>
	if thread ~= nil then
		if type(thread) ~= "thread" then
			Err.errorBeforeNearest(`Ref: Wait(thread) expects a thread (got {typeof(thread)})`, SURFACE)
		end
		self.Callbacks[thread] = true
		return self
	end
	if not coroutine.isyieldable() then
		-- a raw `coroutine.yield` here would surface as the host's
		-- "attempt to yield across metamethod/C-call boundary" with quad blamed
		-- (review finding) — say what the caller did wrong instead
		Err.errorBeforeNearest("Ref: Wait() must be called from a yieldable coroutine (pass a thread to register a waiter without yielding)", SURFACE)
	end
	local running = coroutine.running()
	self.Callbacks[running] = true
	coroutine.yield() -- resumed by `:Set` with `self` — the return below is the same value
	return self
end

-- Detaches a user-registered callback. Both tables — a weakly registered
-- callback is otherwise impossible to remove and keeps firing.
-- Dedup on registration means there is never a "how many times" question.
function RefImpl.Uncallback<T>(self: Ref<T>, fn: Callback<T>): Ref<T>
	checkCallback(fn, "Ref:Uncallback")
	self.Callbacks[fn] = nil
	self.WeakCallbacks[fn] = nil
	return self
end

local function Ref<T>(default: T): Ref<T>
	local self = setmetatable({
		Value = default,
		Revision = 0,
		Callbacks = {},
		WeakCallbacks = setmetatable({}, WEAK_KEY_MT),
	}, RefImpl)
	RefBrand:register(self)
	EpochBrand:register(self) -- multi-tagging: a Ref is also an Epoch
	return (self :: any) :: Ref<T>
end

-- `H-231`: public surface joins the shared error-namespace tag layer
Err.setFuncLevel(SURFACE, RefImpl.Set, RefImpl.Callback, RefImpl.WeakCallback, RefImpl.Uncallback, RefImpl.Wait, Ref)

-- ── dispatch handlers (M8 단위 ②, `H-278`: the module that declares the value
-- registers its leaf handler + guards) ─────────────────────────────────────
-- Canon: ref-plan "`Ref`의 retract" 절 pseudocode as-is (with the round18 Q4
-- order: bindLifetime → relate:SetWeak → v:Set), "이중 배치 방지" 절, "동적
-- 경로 가드 Handler도 거울상으로 하나 더" 절. `Processed*Ref` handlers and the
-- pre-pass are Dispatch's (Dispatch/Ref.luau).
local function registerDispatchHandlers(module: any)
	module:RunInit(InitDispatch) -- idempotent pull (the `H-174` idiom)
	local dispatch: QuadTypes.Dispatch = module.Dispatch
	-- (inst, k) -> last bound Ref — spurious re-emit dedup only (closure
	-- capture cannot see across process calls). Weak (`H-71`): `v:Set(inst)`
	-- makes the value reference its own key; v is strongly held by gchold
	-- while bound, so the entry cannot fall out early (`H-266`).
	local relate = Relate()

	dispatch.addHandler({
		name = "RefLeafHandler",
		keyType = "number", -- `H-484`: only number keys can match (isHandlable checks it too)
		isHandlable = function(_inst: any, k: any, v: any): boolean
			-- array-only leaf; the most specific brands win the other two kinds.
			-- `RefBrand:is` (not `isRef`, which is the union of all three) — the
			-- exclusions already cover the other two, so three lookups, not five
			return type(k) == "number" and RefBrand:is(v) and not Brand.isPreRef(v) and not Brand.isPostRef(v)
		end,
		priority = dispatch.HANDLER_PRIORITY_HIGH,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			-- `H-39`: terminal handlers register their array position — no
			-- physical element, so None/0 (shared body: offsetSource → length)
			dispatch.setEmpty(inst, k, inst)

			local old = relate:GetWeak(inst, k) -- read Weak to match the SetWeak write (`H-71`)
			if old ~= v then -- same Ref already here → spurious re-emit, skip both
				module.bindLifetime(inst, v) -- alive elsewhere → error here (double placement)
				relate:SetWeak(inst, k, v) -- BEFORE Set (Q4): a callback re-driving this slot dedups
				v:Set(inst)
			end
			return function(nextValue: any?, _retracting: boolean)
				-- nextValue is nil or a new Ref this same handler is about to bind
				if nextValue ~= v then
					module.unbindLifetime(v) -- v may be placed elsewhere afterwards
					v:Set(nil) -- the ordinary re-set contract, no new channel
					-- clear only when actually standing down (checklist 4)
					if relate:GetWeak(inst, k) == v then
						relate:SetWeak(inst, k, nil)
					end
				end
			end
		end,
	})
	local function addGuard(name: string, predicate: (any) -> boolean, kind: string)
		dispatch.addHandler({
			name = name,
			isHandlable = function(_inst: any, _k: any, v: any): boolean
				return predicate(v) -- k-agnostic on purpose: the literal array path is
				-- consumed by the pre-pass, so a match here is a type-check bypass
			end,
			priority = dispatch.HANDLER_PRIORITY_FALLBACK,
			process = function(_inst: any, k: any, _v: any, _index: number): (any?, boolean) -> ()
				if type(k) == "number" then
					-- an array slot the pre-pass could not see: the value arrived
					-- through a State/Store (StoreBind unwrap) — say so instead of
					-- blaming the key type (review finding, M8 ②)
					Err.errorBefore(`{kind} must be a literal array item — it reached array index {k} through a State/Store value, which the pre-pass cannot see`, SURFACE)
				end
				Err.errorBefore(`{kind}: must be an array item, not the value of a {typeof(k)} key`, SURFACE)
				return Void -- unreachable; keeps the contract type
			end,
		})
	end
	addGuard("PreRefDynamicPathGuard", Brand.isPreRef, "PreRef")
	addGuard("PostRefDynamicPathGuard", Brand.isPostRef, "PostRef")
end

-- PreRef/PostRef share this body by canon ("Ref 런타임 그대로 재사용, 브랜드
-- 태그만 다름") — one factory so the marker/_fired conventions cannot drift
-- between the two files (review, M8 ②). Not a public surface.
local function tagged<T>(default: T, brand: any, markerKey: string): any
	local self: any = Ref(default)
	brand:register(self)
	self[markerKey] = true -- H-300 marker for the nominal type
	self._fired = false -- one-shot guard the pre-pass flips at consume time
	return self
end

return { Ref = Ref, Init = registerDispatchHandlers, _tagged = tagged }
