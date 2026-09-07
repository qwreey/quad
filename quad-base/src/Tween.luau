--[[
	Tween — the value-level wrapper (M11 unit ①, round19). Canonical:
	`.claude/base/tween-plan.md` — "확정: `Tween{...}` 최종 모양" (option shape:
	`Info` first, convenience fields as fallback; `Override` two-valued),
	"`Tween<T>:Mapped(fn)`" (clone + swap `Value`), "패키지 경계" (quad-base
	holds the VALUE only — engine-free; the animation itself is the
	`isTween(realv)` branch of quad-roblox `Handlers/Property.luau`, unit ②).

	Value API (immutable — frozen, every operation returns a new value):
	  Tween{ Value = v, Info = ?, Time = ?, Style = ?, Direction = ?,
	         RepeatCount = ?, Reverses = ?, DelayTime = ?, Override = ? } -> Tween<T>
	  tween:Mapped(fn) -> Tween<U>     -- opts cloned, Value replaced by fn(Value)
	  Override = "Cancel" | "Finish"   -- override policy as a string singleton (default "Cancel")

	Not a dispatch participant: no handler, no Length/Offset bookkeeping —
	`StoreBind` unwraps State layers and the branded table arrives at
	PropertyHandler as `realv` ("타입 대수" 절). Hence no `Init(module)`
	registration here; `init.luau` exports `Tween`/`isTween` directly.

	Validation (round19 §0 Q5 (a)): only what an engine-free module can see —
	`opts` is a table, `Value` present (`nil` is not a Tween target), the
	engine-free scalars typed (`Time`/`RepeatCount`/`DelayTime` number,
	`Reverses` boolean), `Override` one of the two sentinels. `Info`/`Style`/
	`Direction` are engine types (TweenInfo/Enum) and pass through unchecked —
	a wrong value raises the engine's own error inside PropertyHandler's
	`process` (same class as `inst[k] = wrongValue`; `dispatch-core-plan.md`
	"`None` 센티널" 절의 NOOP-marker caveat).

	`Override` is a STRING SINGLETON (`H-343`, user decision 2026-09-06 — *"Numeric
	enum 아니고서야 보통 루아우는 singleton string"*): `"Cancel" | "Finish"` types
	itself, autocompletes, and needs no marker value. That also makes `Tween` a
	PLAIN generic function — no callable namespace, so the 8.6 exception of
	`H-324` (generic `__call` losing `T`) disappears with it. Frozen-table
	sentinels stay where a VALUE must be told apart from user data in a slot
	(`None`/`Detach`/`KeyGone`/`Processed*`); an option enum is not that.
]]

local Brand = require("./Brand")
local QuadTypes = require("../luau_packages/quad_types")
local Err = require("./ErrorNamespace")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local TweenBrand = Brand.TweenBrand

local TweenImpl = {}
TweenImpl.__index = TweenImpl
-- `H-300`: the type promises the marker, so the value carries it — read
-- through `__index` (zero per-instance slots, like `RefImpl.__quadRefAccepts`)
TweenImpl.__quadTween = true

local NUMBER_FIELDS = { "Time", "RepeatCount", "DelayTime" }

local function validate(opts: any)
	if type(opts) ~= "table" then
		Err.errorBeforeNearest("Tween: expected an options table (Tween{ Value = ... })", SURFACE)
	end
	if opts.Value == nil then
		Err.errorBeforeNearest("Tween: Value is required", SURFACE)
	end
	if Brand.isState(opts.Value) then
		-- Q16 (b) (사용자 결정 2026-09-07): every Tween field is a plain value (tween-plan 불변식) —
		-- a State here reached the engine as a table (`H-398`). Put the Tween in the State instead.
		Err.errorBeforeNearest("Tween: Value must be a plain value, not a State (animate the State instead — state:Apply(Animate{...}) or state:Compute(function() return Tween{...} end))", SURFACE)
	end
	for _, name in NUMBER_FIELDS do
		local v = opts[name]
		if v ~= nil and type(v) ~= "number" then
			Err.errorBeforeNearest(`Tween: {name} must be a number`, SURFACE)
		end
	end
	if opts.Reverses ~= nil and type(opts.Reverses) ~= "boolean" then
		Err.errorBeforeNearest("Tween: Reverses must be a boolean", SURFACE)
	end
	local override = opts.Override
	if override ~= nil and override ~= "Cancel" and override ~= "Finish" then
		Err.errorBeforeNearest('Tween: Override must be "Cancel" or "Finish"', SURFACE)
	end
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
		Err.errorBeforeNearest("Tween:Mapped expects a function", SURFACE)
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

for _, fn in { Tween, TweenImpl.Mapped } :: { any } do
	Err.setFuncLevel(fn, SURFACE)
end

return { Tween = Tween }
