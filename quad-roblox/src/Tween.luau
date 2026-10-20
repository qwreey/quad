--!strict
--[[
	Tween — the value-level wrapper, a quad-roblox VALUE since 2026-09-07 (user
	decision, `base/tween-plan.md` "패키지 경계" 절: the option vocabulary —
	`Time`/`Style`/`Direction`/`RepeatCount`/`Reverses`/`DelayTime` — is Roblox's
	`TweenInfo`, a web backend would have a different name and shape
	(`Transition`), and `Animate` already lived here; user: *"Tween 자체가 워낙
	엔진의 지식인지라, 엔진 자체로 옮기고 싶어"*). Canonical shape:
	"확정: `Tween{...}` 최종 모양" (`Info` first, convenience fields as fallback;
	`Override` two-valued), "`Tween<T>:Mapped(fn)`" (clone + swap `Value`). The
	animation itself is the `isTween(realv)` branch of `Handlers/Property.luau`.

	Install (RobloxFactory, FIRST — Property/InstanceShorthand/Animate read
	`quad.Tween`/`quad.isTween` off the module at their own install):
	  install(module) -> { Tween, isTween }   -- also set on the module directly
	The pair is returned so RobloxFactory can carry it in the typed extension
	(`RobloxExtension` — `q.Tween`/`q.isTween` through `UseProvider`'s `Self & P`);
	the direct set is what the sibling installers and quad-base's diagnostic
	brand probe see — `Dispatch/init.luau` scans the module for `is<Brand>`
	fields (the provider-brand CONTRACT, round3 §4 Q27, 2026-09-08) that are registered in
	the module's `BrandPredicates` (round13 Q106 — `RobloxFactory.luau` registers `isTween` at install).
	The constructor is per module instance because raises go through the
	module's shared error namespace (`H-231`).

	Value API (immutable — frozen, every operation returns a new value):
	  Tween{ Value = v, Info = ?, Time = ?, Style = ?, Direction = ?,
	         RepeatCount = ?, Reverses = ?, DelayTime = ?, Override = ?, Dedup = ?,
	         Started = ?, Completed = ?, Cancelled = ? } -> Tween<T>
	  tween:Mapped(fn, wrap?) -> Tween<U> -- opts cloned, Value replaced by fn(Value); with `wrap`, the
	                                   -- callbacks too (round13 묶음 1 2026-09-28 — one copy for both)
	  tween:Wrapped(wrap) -> Tween<T>  -- round13 묶음 1: same Value, callbacks replaced by wrap(cb)'s set
	    wrap(cb) -> { Started?, Completed?, Cancelled? }  -- called once per call; the returned set is the
	                                   -- copy's WHOLE callback set. `cb` = the source's three callbacks
	                                   -- (function or nil) + `cb:Map(g)` (g applied to each present one)
	  Override = "Cancel" | "Finish"   -- override policy as a string singleton (default "Cancel")
	  Dedup = true | false             -- [2026-09-08 user decision, round3 Q25] default true: the
	                                   -- CONSUMER (Property handler) compares the incoming
	                                   -- `Value` with the slot's recorded target and does nothing
	                                   -- when equal — options (Time/Style/…) are not compared.
	                                   -- false = always (re)start. The one dedup mechanism;
	                                   -- `Animate` just forwards its option here.

	Not a dispatch participant: no handler, no Length/Offset bookkeeping —
	`StateHandler` unwraps State layers and the branded table arrives at
	PropertyHandler as `realv` ("타입 대수" 절).

	Validation (round19 §0 Q5 (a), unchanged by the move): `opts` is a table,
	`Value` present and not a State (Q16 (b)), the scalars typed (`Time`/
	`RepeatCount`/`DelayTime` number, `Reverses` boolean), `Override` one of the
	two sentinels. `Info`/`Style`/`Direction` still pass through unchecked —
	the CLI specs run with a `TweenInfo` shim (mock.luau), and a wrong value
	raises the engine's own error inside PropertyHandler's `process` (same
	class as `inst[k] = wrongValue`; `dispatch-core-plan.md` "`None` 센티널" 절의
	NOOP-marker caveat). The TYPE side is now precise (types.luau —
	`Info: TweenInfo?`, `Style: Enum.EasingStyle?`, `Direction: Enum.EasingDirection?`),
	which the quad-types placement could not be (engine-free `any`).

	`Override` is a STRING SINGLETON (`H-343`, user decision 2026-09-06 — *"Numeric
	enum 아니고서야 보통 루아우는 singleton string"*): `"Cancel" | "Finish"` types
	itself, autocompletes, and needs no marker value. That also makes `Tween` a
	PLAIN generic function — no callable namespace, so the 8.6 exception of
	`H-324` (generic `__call` losing `T`) disappears with it.
]]

local Brand = require("./Brand")
local TweenOptions = require("./TweenOptions")
local QuadTypes = require("../luau_packages/quad_types")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local TweenBrand = Brand.TweenBrand
local isTween = Brand.isTween

-- the `q.debug` diagnostic channel of quad-roblox: the same `[quad debug] ` prefix as quad-base's `DebugPrint.luau`
-- (a separate package — this file cannot require it). `Animate.luau` gets it from `install` below. Ref: H-915 Q190
local function debugPrint(line: string)
	print("[quad debug] " .. line)
end

local NUMBER_FIELDS = { "Time", "RepeatCount", "DelayTime" }
-- [2026-09-21 사용자 결정 — docs-review 1-5] three optional callbacks (round13 묶음 1 2026-09-28: called `(inst, prop, value)`,
-- a zero-argument function still fits), plain fields of the value
-- (bare names, not `On*` — the `On*` prefix means "a factory called to fill a numeric-key slot" in this
-- library). WHEN they fire is the consumer's contract: `Handlers/Property.luau` header. `Mapped(fn)` carries them
-- unchanged (the copy's value arg is then the MAPPED value); `Mapped(fn, wrap)`/`Wrapped(wrap)` rewrite them.
local CALLBACK_FIELDS = TweenOptions.CALLBACK_FIELDS

-- ── debug layer: unknown option keys ──
-- [2026-09-15 사용자 결정] unknown keys (typos) are reported only under `q.debug`, execution continues.
-- Checked on the user's constructor call (`Tween(opts)`), not in `validate` — `Mapped` re-validates per emit.
-- Body kept out of the constructor (`architecture.md` "debug 층": the logic carries one line).
local KNOWN_OPTIONS: { [string]: boolean } = { Value = true }
for _, name in TweenOptions.OPTION_FIELDS do
	KNOWN_OPTIONS[name] = true
end
local KNOWN_LIST = "Value, " .. table.concat(TweenOptions.OPTION_FIELDS, ", ")
-- [2026-10-06 user decision, round14 Q179] the same pass names the convenience fields an `Info` overrides:
-- `Info` wins (`Handlers/Property.luau` `buildInfo`), so `Time`/`Style`/… given next to it are ignored — a
-- `Time` State fed through `Animate` that "does not follow" was the case the user named.
-- [2026-10-06 round14 확인 패스 code-review 4·5] One helper for both constructors — `Animate.luau` receives it
-- through `RobloxFactory` with the validator (the field list and the line were copied there before). `who` is the
-- caller's name; `infoIsState` is Animate's case: an `Info` State that holds nil leaves the tween Info-less, so the
-- convenience fields DO apply then — the line says "while Info holds a value" instead of "ignored".
local INFO_FIELDS = { "Time", "Style", "Direction", "RepeatCount", "Reverses", "DelayTime" }
local function warnInfoOverlap(who: string, opts: { [any]: any }, infoIsState: boolean)
	if opts.Info == nil then
		return
	end
	local ignored = {}
	for _, field in INFO_FIELDS do
		if opts[field] ~= nil then
			table.insert(ignored, field)
		end
	end
	if #ignored == 0 then
		return
	end
	local list, verb = table.concat(ignored, ", "), if #ignored == 1 then "is" else "are"
	if infoIsState then
		debugPrint(`{who}: Info is a State, so {list} {verb} ignored while it holds a value (Info wins over the convenience fields; they apply only while Info holds nil - put them in the TweenInfo, or drop Info)`)
	else
		debugPrint(`{who}: Info is given, so {list} {verb} ignored (Info wins over the convenience fields - put them in the TweenInfo, or drop Info)`)
	end
end
local function warnUnknownOptions(opts: any)
	if type(opts) ~= "table" then
		return -- the constructor's own gate reports a non-table
	end
	for key in opts do
		if not KNOWN_OPTIONS[key] then
			debugPrint(`Tween: unknown option "{tostring(key)}" is ignored (known: {KNOWN_LIST})`)
		end
	end
	warnInfoOverlap("Tween", opts, false) -- a Tween's own fields are plain values (a State Info fails `validate`)
end

local function install(quad: any): any
	-- shared error namespace (`H-231`) — never a private quad-error copy
	local Err = quad.errorNamespace
	-- `isState` from the module instance (Q16 (b) gate below)
	local isState = quad.isState
	local None = quad.None

	local TweenImpl = {}
	TweenImpl.__index = TweenImpl
	-- `H-300`: the type promises the marker, so the value carries it — read
	-- through `__index` (zero per-instance slots, like `RefImpl.__quadRefAccepts`)
	TweenImpl.__quadTween = true
	-- `__tostring` (2026-09-08, advisory 권고 1): target value + Time when given as the convenience field.
	-- [2026-10-06 user decision, round14 Q179] `Info` first: with an `Info` the second part is `Info` (it wins
	-- over `Time` — `Tween(1, Info)`), so the string never shows a Time the tween does not use.
	function TweenImpl.__tostring(self: any): string
		local value = tostring(rawget(self, "Value"))
		if rawget(self, "Info") ~= nil then
			return `Tween({value}, Info)`
		end
		local t = rawget(self, "Time")
		return `Tween({value}{if type(t) == "number" then `, {t}s` else ""})`
	end
	-- round14 Q161·Q182 (a) (user decision 2026-10-06): the `q.Protocols.DispatchHint` hook — a Tween at a
	-- string key no handler takes is almost always a key that is not a writable property of this element
	-- (the 10-01 "belongs in a numeric slot" hint sent it to an array slot, where it raised again). At a
	-- numeric key: nil → the generic tail.
	function TweenImpl.__dispatchHint(_self: any, key: any): string?
		if type(key) == "string" then
			return "this key may not be a field of this element (a typo, a read-only field, or one from another class)"
		end
		return nil
	end
	local DispatchHint = quad.Protocols.DispatchHint -- members register at creation (newTween)

	-- Option fields only (everything but Value). Shared with `Animate.luau`, which runs it
	-- EAGERLY on the literal (non-State) options at `Animate(info)` time — the lazy Compute
	-- builds the Tween far from the user's line, so a raise there blamed `Animate.luau`
	-- (`H-464`). Raises `errorBeforeNearest(SURFACE)`: the nearest tagged frame is whichever
	-- public factory (Tween or Animate) the user called.
	-- `raise` (`H-502`, 2026-09-08 2차 감사 I-1): `Animate`'s lazy Compute re-validates the
	-- State-resolved options per run at EMIT depth, where nearest is `Animate.luau` itself —
	-- it passes `errorBefore` (outermost = the user's Get/Set line); everyone else takes the default.
	local function validateFields(opts: any, raise: ((string, number) -> ())?)
		local fail = raise or Err.errorBeforeNearest
		for _, name in NUMBER_FIELDS do
			local v = opts[name]
			if v ~= nil and type(v) ~= "number" then
				fail(`Quad0243 Tween: {name} must be a number (got {typeof(v)})`, SURFACE)
			end
		end
		if opts.Reverses ~= nil and type(opts.Reverses) ~= "boolean" then
			fail(`Quad0244 Tween: Reverses must be a boolean (got {typeof(opts.Reverses)})`, SURFACE)
		end
		if opts.Dedup ~= nil and type(opts.Dedup) ~= "boolean" then
			fail(`Quad0245 Tween: Dedup must be a boolean (got {typeof(opts.Dedup)})`, SURFACE)
		end
		for _, name in CALLBACK_FIELDS do
			local v = opts[name]
			if v ~= nil and type(v) ~= "function" then
				fail(`Quad0246 Tween: {name} must be a function (got {typeof(v)})`, SURFACE)
			end
		end
		local override = opts.Override
		if override ~= nil and override ~= "Cancel" and override ~= "Finish" then
			fail('Quad0247 Tween: Override must be "Cancel" or "Finish"', SURFACE)
		end
	end

	-- `raise` — nearest by default (direct `q.Tween{}` call); `Animate` passes outermost because its
	-- lazy Compute's nearest tagged frame is `Tween` itself, which blamed `Animate.luau` (round10 G-1 —
	-- the third layer of the `H-464`/`H-502` residue: literals were hoisted, State fields were routed,
	-- but the four `Value` checks here still blamed nearest)
	local function validate(opts: any, raise: ((string, number) -> ())?)
		local fail = raise or Err.errorBeforeNearest
		if type(opts) ~= "table" then
			fail(`Quad0248 Tween: options must be a table, e.g. Tween\{ Value = ... \} (got {typeof(opts)})`, SURFACE)
		end
		if opts.Value == nil then
			fail("Quad0249 Tween: Value is required", SURFACE)
		end
		if isState(opts.Value) then
			-- Q16 (b) (사용자 결정 2026-09-07): every Tween field is a plain value (tween-plan 불변식) —
			-- a State here reached the engine as a table (`H-398`). Put the Tween in the State instead.
			fail("Quad0250 Tween: Value must be a plain value, not a State (animate the State instead - state:Apply(Animate{...}) or state:Compute(function() return Tween{...} end))", SURFACE)
		end
		if opts.Value == None or isTween(opts.Value) then
			-- `H-463`: the same invariant, the other two non-plain quad values — None (the frozen
			-- sentinel) and a nested Tween both reached the engine as a table through
			-- `Property.process`'s Tween branch. To release a property, emit None ITSELF
			-- (`Animate` passes nil/None through untouched — Q8 (a)).
			fail("Quad0251 Tween: Value must be a plain value, not None or another Tween (emit None itself to release the property)", SURFACE)
		end
		validateFields(opts, raise)
	end

	-- clone → brand → freeze. `table.clone` keeps the caller's table untouched
	-- (immutability is ours to guarantee, not the caller's).
	local function newTween(opts: any, raise: ((string, number) -> ())?): any
		validate(opts, raise)
		local self: any = setmetatable(table.clone(opts), TweenImpl)
		TweenBrand:Register(self)
		DispatchHint:Register(self)
		return table.freeze(self)
	end

	-- round13 묶음 1 (research/tween-callback-structure §8-1, user decision 2026-09-28): the callback handle `wrap`
	-- receives — the source Tween's three callbacks as fields (function or nil) plus `cb:Map(g)`, which
	-- returns a new set with `g(f)` applied to each present one. Frozen: it is a read-only view.
	local CallbackHandleImpl = {}
	CallbackHandleImpl.__index = CallbackHandleImpl
	local EMPTY_HANDLE: any, EMPTY_SET: any
	function CallbackHandleImpl.Map(self: any, g: any): any
		if type(g) ~= "function" then
			Err.errorBeforeNearest(`Quad0258 Tween callbacks:Map: g must be a function (got {typeof(g)})`, SURFACE)
		end
		if self == EMPTY_HANDLE then
			return EMPTY_SET -- code-review (2026-09-28): no callbacks, nothing to map — no allocation
		end
		local out = {}
		for _, name in CALLBACK_FIELDS do
			local f = self[name]
			if f ~= nil then
				out[name] = g(f)
			end
		end
		return out
	end
	-- shared, frozen: the handle of a Tween with no callbacks and the empty set `Map` returns for it — the
	-- shorthand wraps EVERY Tween it forwards, so a callback-less one must not allocate per emit
	EMPTY_HANDLE = table.freeze(setmetatable({}, CallbackHandleImpl))
	EMPTY_SET = table.freeze({})
	-- `opts` (an unfrozen clone) takes the set `wrap(handle)` returns as its WHOLE callback set: a field the
	-- set leaves out is no callback. The values are checked by `newTween`'s own validation (Quad0246).
	local function callWrap(method: string, self: any, wrap: any): any
		if type(wrap) ~= "function" then
			Err.errorBeforeNearest(`Quad0256 Tween:{method}: wrap must be a function (got {typeof(wrap)})`, SURFACE)
		end
		local handle: any
		if self.Started == nil and self.Completed == nil and self.Cancelled == nil then
			handle = EMPTY_HANDLE
		else
			handle = setmetatable({}, CallbackHandleImpl)
			for _, name in CALLBACK_FIELDS do
				handle[name] = self[name]
			end
			table.freeze(handle)
		end
		local set = wrap(handle)
		if type(set) ~= "table" then
			Err.errorBeforeNearest(`Quad0257 Tween:{method}: wrap must return a callback set table (got {typeof(set)})`, SURFACE)
		end
		return set
	end
	local function applySet(opts: any, set: any)
		for _, name in CALLBACK_FIELDS do
			opts[name] = set[name]
		end
	end

	function TweenImpl.Mapped(self: any, fn: any, wrap: any?): any
		if type(fn) ~= "function" then
			Err.errorBeforeNearest(`Quad0227 Tween:Mapped: fn must be a function (got {typeof(fn)})`, SURFACE)
		end
		-- `table.clone` copies the metatable too; the clone is not frozen, so
		-- swapping Value is fine before newTween re-brands and re-freezes it
		local set = if wrap ~= nil then callWrap("Mapped", self, wrap) else nil
		local opts = table.clone(self)
		opts.Value = fn(self.Value)
		if set ~= nil then
			applySet(opts, set) -- one copy for both (the fast path the user asked for)
		end
		return newTween(opts) -- re-validates: fn returning nil is "Value is required"
	end

	-- round13 묶음 1 (user decision 2026-09-28): `tween:Wrapped(wrap)` — same value, callbacks replaced by
	-- `wrap(cb)`'s set. When the set is exactly the source's (the same three functions, e.g. a Tween with no
	-- callbacks through the shorthand's filtering wrap), the frozen source itself is returned — no copy. Nothing
	-- keys on a Tween's identity (the Property dedup compares the target `Value`, round3 Q25), and before this
	-- method the shorthand's identity path passed the source through unchanged anyway. `wrap` is still called:
	-- it may ADD callbacks to a Tween that had none.
	function TweenImpl.Wrapped(self: any, wrap: any): any
		local set = callWrap("Wrapped", self, wrap)
		if rawequal(set.Started, self.Started) and rawequal(set.Completed, self.Completed) and rawequal(set.Cancelled, self.Cancelled) then
			return self -- compared before cloning: the unchanged path allocates nothing here
		end
		local opts = table.clone(self)
		applySet(opts, set)
		return newTween(opts)
	end

	-- Plain generic function (`H-343`): `Tween{...}` constructs, nothing else lives
	-- on it. `H-238`: surface-tagged so validation raises blame the user's line.
	local function Tween(opts: any): any
		if quad.debug then
			warnUnknownOptions(opts) -- debug layer (top of file)
		end
		return newTween(opts)
	end

	Err.setFuncLevel(SURFACE, Tween, TweenImpl.Mapped, TweenImpl.Wrapped, CallbackHandleImpl.Map)

	quad.Tween = Tween
	quad.isTween = isTween
	-- `validateFields` is quad-roblox-internal wiring for `Animate.luau` (via RobloxFactory),
	-- not a module surface
	-- `tweenOutermost` — the same constructor with outermost blame, for `Animate`'s lazy Compute (G-1)
	local function tweenOutermost(opts: any): any
		return newTween(opts, Err.errorBefore)
	end
	-- `warnInfoOverlap` — the debug Info-overlap line (file head), shared with `Animate` the same way
	return { Tween = Tween, isTween = isTween, validateFields = validateFields, tweenOutermost = tweenOutermost, warnInfoOverlap = warnInfoOverlap, debugPrint = debugPrint }
end

return install
