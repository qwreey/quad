--!strict
--[[
	Source — the writable root value. Structurally satisfies `State` (all
	derived methods come from `State.luau`'s impl through `__index`) and is
	itself an `Epoch` (`Revision`), so it is registered in BOTH
	`SourceBrand` and `EpochBrand` (multi-tagging, `brand-plan.md`) — never in
	`StateBrand`: `isState = isSource or StateBrand` is composed in the
	predicate, not by double registration.

	Sources, as-is:
	  - `.claude/base/source-state-plan.md` "State는 쓰기 대상이 아님 —
	    확정, Source는 독립 공개 프리미티브로 격상" (`Source(default)`),
	    "`Source:Set(v)`는 동일값이어도 항상 갱신하고 emit한다" (`H-68`; its 2026-10-01
	    paragraph adds the opt-in `:SetIfChanged(v)`),
	    "Source 값을 직접 mutate한 뒤 전파 — `:Emit()`" (root only),
	    "따름정리 — `Store<T>`/`Source<T>`의 `T`는 Modifier가 될 수 없음".
	  - `.claude/base/slot-plan.md` "`SetAndDispose` 류" item (`SL-74`, implemented
	    2026-10-01): `:SetAndDispose(v)` — `Set`, then `dispose` the replaced value.
	  - `.claude/base/modifier-plan.md` 7번: `isModifier` guard at the
	    constructor and at `:Set` (the constructor also covers `store:Of`).
	  - `.claude/base/state-epoch-plan.md` §2: `Revision` bump is
	    `bit32.bnot(-rev)`; `Set`/`Emit` push the Source itself as the emit
	    payload ("출처" only — no value, no revision).

	Assembly (`H-174`): `InitSource(module)` — needs the per-instance State
	impl for its `__index` chain, and pulls it in itself via
	`module:RunInit(State.Init)` (idempotent), so `New()` order is irrelevant.
]]

local Brand = require("./Brand")
local State = require("./State")
local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

export type Source<T> = QuadTypes.Source<T>

local SourceBrand = Brand.SourceBrand
local EpochBrand = Brand.EpochBrand
local isModifier = Brand.isModifier

local WEAK_KEY_MT = { __mode = "k" }

-- ── debug-only checks (`architecture.md` "debug 층"; kept out of the logic below) ──
-- 2026-10-01 (user decision), signal (b) of the Compute detector (`State.luau` has the other): a
-- `Set`/`Emit` while a Compute fn of this quad instance is on the call stack — directly in the fn or
-- in anything it called, an Observer it woke included. A Compute only reads and combines; the write
-- tangles the wave with nothing to untangle it (`source-state-plan.md` "Compute 순수성", undefined).
-- Prints once per Source (weak) — a fn that writes on every run would otherwise print every run.
local function checkWriteInCompute(module: any, source: any, warned: { [any]: true })
	if warned[source] == nil and State.computeFnOnStack(module) then
		warned[source] = true
		print("Source: Set/Emit inside a Compute fn - a Compute only reads and combines (undefined)")
	end
end

local function Init(module: any)
	-- Pull our dependency ourselves, `require`-style (`module-lifecycle-plan.md`
	-- "순서 의존성은 각 `InitXxx`를 `require`처럼 멱등하게 만들어서 해소한다") —
	-- `RunInit` is idempotent, so `New()` need not order us after `State.Init`.
	module:RunInit(State.Init)
	local StateImpl = State.implFor(module)
	local emitDown = StateImpl._emitDown

	local Impl = setmetatable({}, { __index = StateImpl })
	Impl.__index = Impl
	-- `__tostring` (2026-09-08 user decision, Gemini advisory 권고 1 — `print(v)` in Studio shows
	-- state, not `table: 0x…`; read-only, never triggers a compute). Metamethods are NOT inherited
	-- through `__index`, so every metatable spells its own.
	function Impl.__tostring(self: any): string
		return `Source({tostring(self._value)})`
	end

	function Impl.Get(self: any): any
		return self._value
	end

	-- In-place mutation was done by the caller; only the signal is sent.
	-- Root Sources only — derived States have no such concept ("하드 경계").
	-- `H-207`: one copy of the bump-and-emit tail, as an UNTAGGED local —
	-- `Set` calls it directly. If `Set` called the tagged `Impl.Emit`, every
	-- Nearest raise inside the wave (Slot reconcile, KeyGone …) would blame
	-- this file's `Emit` line instead of the user's `:Set` line (`H-330`,
	-- fable 탐사 2026-09-06; `H-250`: local direct calls need no tag).
	local debugWarned: { [any]: true } = setmetatable({}, WEAK_KEY_MT) :: any
	local function bumpAndEmit(self: any): any
		if module.debug then
			checkWriteInCompute(module, self, debugWarned)
		end
		self.Revision = bit32.bnot(-self.Revision)
		emitDown(self, self) -- payload = the source epoch itself
		return self
	end

	function Impl.Emit(self: any): any
		return bumpAndEmit(self)
	end

	-- The value gate shared by `Set` and `SetIfChanged` — an UNTAGGED local, so the Nearest walk
	-- skips it and lands on whichever tagged surface (`Set`/`SetIfChanged`) the user called.
	-- round14 (user decision 2026-10-02): `type` first — a Modifier is always a table, so the brand
	-- lookup runs only for tables (this is on every Set; numbers/strings/userdata skip it)
	local function checkSettable(value: any)
		if type(value) == "table" and isModifier(value) then
			Err.errorBeforeNearest("Quad0181 Source: cannot Set a Modifier as a Source value", SURFACE)
		end
	end

	-- `H-68`: same value still bumps the revision and emits — dedup is the
	-- downstream's job (EpochMap judgement, gates), and `==` would silently
	-- drop in-place table mutations.
	function Impl.Set(self: any, value: any): any
		checkSettable(value)
		self._value = value
		return bumpAndEmit(self) -- direct local call (`H-207`/`H-330`), not colon delegation
	end

	-- 2026-10-01 (user decision, `source-state-plan.md` `H-68` 절 끝): the opt-in comparing write —
	-- for the narrow spots that must cut a feedback loop. `Set` stays unconditional; this one does
	-- nothing (no revision, no emit) when `value == current` by Luau `==` (so a shared `__eq`
	-- metamethod decides; NaN is never equal to itself, so it always writes). The value gate runs
	-- FIRST — a bad value raises the same error whether or not it would compare equal. Returns self
	-- either way (same chain as `Set`; a caller that needs "did it write" spells the compare out).
	function Impl.SetIfChanged(self: any, value: any): any
		checkSettable(value)
		if value == self._value then
			return self
		end
		self._value = value
		return bumpAndEmit(self) -- direct local call, as in `Set`
	end

	-- 2026-10-01 (decided 2026-08-20 `SL-74`, `slot-plan.md` "`SetAndDispose` 류" item): `Set`, then
	-- `dispose` the value it replaced — slot-plan's "Set (unmount) → then clean up" order in one call,
	-- so the caller no longer holds the old value via `Get()` first. Same value gate as `Set`, run
	-- FIRST (a rejected value leaves both values alone). The wave runs to completion before the
	-- dispose, so a synchronous seat downstream has already unmounted the old value. Skipped:
	-- the old value is `nil` or `None` (an empty seat — nothing to dispose), or the very value just
	-- written (`rawequal` — disposing it would destroy what was just put in; the write itself still
	-- happens, `H-68`). Anything else goes to `q.dispose`'s body as-is: a value it cannot dispose
	-- (a number, a plain table) or one still held elsewhere (a Gate/Debounce/Blocker between the
	-- Source and the seat holds the old value past the wave) raises dispose's own error AFTER the
	-- write — never wrapped in pcall (the write is not rolled back; `dispose`'s contract decides).
	-- The body is reached through the untagged `_slotInternal.disposeValue`, so its raises blame the
	-- user's `SetAndDispose` line (the tagged `dispose` would be the nearest frame and blame here).
	-- Returns self, as `Set`.
	function Impl.SetAndDispose(self: any, value: any): any
		checkSettable(value)
		local old = self._value
		self._value = value
		bumpAndEmit(self) -- direct local call, as in `Set`
		if old ~= nil and not rawequal(old, module.None) and not rawequal(old, value) then
			module._slotInternal.disposeValue(old)
		end
		return self
	end

	function Impl._track(self: any, map: any)
		map:Sync(self) -- a Source IS an Epoch: it goes into the map directly
	end

	local function Source(default: any): any
		if type(default) == "table" and isModifier(default) then -- `type` first, as `checkSettable`
			Err.errorBeforeNearest("Quad0182 Source: cannot hold a Modifier as a Source value", SURFACE)
		end
		local self = setmetatable({
			_value = default,
			Revision = 0,
			_subs = setmetatable({}, WEAK_KEY_MT), -- weak-key subscribers (downstream)
		}, Impl)
		SourceBrand:Register(self)
		EpochBrand:Register(self)
		return self
	end

	-- `H-231`: public surface joins the shared error-namespace tag layer
	Err.setFuncLevel(SURFACE, Impl.Get, Impl.Emit, Impl.Set, Impl.SetIfChanged, Impl.SetAndDispose, Source)

	module.Source = Source
end

return Init
