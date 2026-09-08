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
	fields (the provider-brand CONTRACT, round3 §4 Q27, 2026-09-08).
	The constructor is per module instance because raises go through the
	module's shared error namespace (`H-231`).

	Value API (immutable — frozen, every operation returns a new value):
	  Tween{ Value = v, Info = ?, Time = ?, Style = ?, Direction = ?,
	         RepeatCount = ?, Reverses = ?, DelayTime = ?, Override = ?, Dedup = ? } -> Tween<T>
	  tween:Mapped(fn) -> Tween<U>     -- opts cloned, Value replaced by fn(Value)
	  Override = "Cancel" | "Finish"   -- override policy as a string singleton (default "Cancel")
	  Dedup = true | false             -- [2026-09-08 user decision, round3 Q25] default true: the
	                                   -- CONSUMER (Property handler) compares the incoming
	                                   -- `Value` with the slot's recorded target and does nothing
	                                   -- when equal — options (Time/Style/…) are not compared.
	                                   -- false = always (re)start. The one dedup mechanism;
	                                   -- `Animate` just forwards its option here.

	Not a dispatch participant: no handler, no Length/Offset bookkeeping —
	`StoreBind` unwraps State layers and the branded table arrives at
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
local QuadTypes = require("../luau_packages/quad_types")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local TweenBrand = Brand.TweenBrand
local isTween = Brand.isTween

local NUMBER_FIELDS = { "Time", "RepeatCount", "DelayTime" }

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
	-- `__tostring` (2026-09-08, advisory 권고 1): target value + Time when given as the convenience field
	function TweenImpl.__tostring(self: any): string
		local t = rawget(self, "Time")
		return `Tween({tostring(rawget(self, "Value"))}{if type(t) == "number" then `, {t}s` else ""})`
	end

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
				fail(`Tween: {name} must be a number`, SURFACE)
			end
		end
		if opts.Reverses ~= nil and type(opts.Reverses) ~= "boolean" then
			fail("Tween: Reverses must be a boolean", SURFACE)
		end
		if opts.Dedup ~= nil and type(opts.Dedup) ~= "boolean" then
			fail("Tween: Dedup must be a boolean", SURFACE)
		end
		local override = opts.Override
		if override ~= nil and override ~= "Cancel" and override ~= "Finish" then
			fail('Tween: Override must be "Cancel" or "Finish"', SURFACE)
		end
	end

	local function validate(opts: any)
		if type(opts) ~= "table" then
			Err.errorBeforeNearest("Tween: expected an options table (Tween{ Value = ... })", SURFACE)
		end
		if opts.Value == nil then
			Err.errorBeforeNearest("Tween: Value is required", SURFACE)
		end
		if isState(opts.Value) then
			-- Q16 (b) (사용자 결정 2026-09-07): every Tween field is a plain value (tween-plan 불변식) —
			-- a State here reached the engine as a table (`H-398`). Put the Tween in the State instead.
			Err.errorBeforeNearest("Tween: Value must be a plain value, not a State (animate the State instead — state:Apply(Animate{...}) or state:Compute(function() return Tween{...} end))", SURFACE)
		end
		if opts.Value == None or isTween(opts.Value) then
			-- `H-463`: the same invariant, the other two non-plain quad values — None (the frozen
			-- sentinel) and a nested Tween both reached the engine as a table through
			-- `Property.process`'s Tween branch. To release a property, emit None ITSELF
			-- (`Animate` passes nil/None through untouched — Q8 (a)).
			Err.errorBeforeNearest("Tween: Value must be a plain value, not None or another Tween (emit None itself to release the property)", SURFACE)
		end
		validateFields(opts)
	end

	-- clone → brand → freeze. `table.clone` keeps the caller's table untouched
	-- (immutability is ours to guarantee, not the caller's).
	local function newTween(opts: any): any
		validate(opts)
		local self: any = setmetatable(table.clone(opts), TweenImpl)
		TweenBrand:register(self)
		return table.freeze(self)
	end

	function TweenImpl.Mapped(self: any, fn: any): any
		if type(fn) ~= "function" then
			Err.errorBeforeNearest(`Tween:Mapped: fn must be a function (got {typeof(fn)})`, SURFACE)
		end
		-- `table.clone` copies the metatable too; the clone is not frozen, so
		-- swapping Value is fine before newTween re-brands and re-freezes it
		local opts = table.clone(self)
		opts.Value = fn(self.Value)
		return newTween(opts) -- re-validates: fn returning nil is "Value is required"
	end

	-- Plain generic function (`H-343`): `Tween{...}` constructs, nothing else lives
	-- on it. `H-238`: surface-tagged so validation raises blame the user's line.
	local function Tween(opts: any): any
		return newTween(opts)
	end

	Err.setFuncLevel(SURFACE, Tween, TweenImpl.Mapped)

	quad.Tween = Tween
	quad.isTween = isTween
	-- `validateFields` is quad-roblox-internal wiring for `Animate.luau` (via RobloxFactory),
	-- not a module surface
	return { Tween = Tween, isTween = isTween, validateFields = validateFields }
end

return install
