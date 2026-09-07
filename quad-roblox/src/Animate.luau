--[[
	Animate — the `:Apply` combinator that wraps a State's value in a
	`Tween{...}` with fixed options (M11 unit ③, round19). Canonical:
	`.claude/base/tween-plan.md` "`Animate` 콤비네이터" 절 (pseudocode 1:1) and
	"왜 `:Apply`로 정정됐는가" 절 (named combinators attach through `:Apply`,
	never `:Compute` directly — `research/operator-sugar-plan.md`).

	  Position = mySource:Apply(Animate{ Style = Enum.EasingStyle.Bounce, Time = 0.3 })

	`Animate(info)` returns `factory(self) -> State`. Inside, `self:Compute`
	re-runs only when `self` (the Value) changes; every option field may be
	`T | State<T>` and is read through `resolve` (`:Get()` once, inside the
	fn) — so an option State changing does NOT re-animate on its own (canon:
	"style 같은 게 바뀐다고 다시 애니메이션을 수행하는 경우는 없다"), the next
	Value change picks up the latest options. `Tween{...}` itself still
	receives plain values only (its invariant, "`Tween{...}`의 모든 필드는
	plain 값만 받음" 절).

	`CanAnimate` (`State<boolean> | boolean | nil`, default true — Q6 (a),
	casing confirmed): false ⇒ the Compute returns the plain value, so the
	PropertyHandler writes it directly (reduceMotion-style bypass). The
	factory's DECLARED type is `(self: any) -> State<Tween<any>>` (`H-334`,
	§4 확인 항목 — `types.luau` lists the four measured alternatives that fail):
	the honest `State<T | Tween<T>>` cannot be a slot-union member without the
	checker giving up, and `:Apply` only takes a non-generic factory. Every
	slot consumer accepts both shapes at runtime anyway.

	quad-roblox util, not a base primitive ("패키지 경계" 절): it only
	composes `:Compute`, `isState` and `Tween{...}` from the module instance
	it is installed on — hence the install shape (module-level factory).
]]

local QuadTypes = require("../luau_packages/quad_types")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local FIELDS = { "Info", "Time", "Style", "Direction", "RepeatCount", "Reverses", "DelayTime", "Override" }

-- Q12 (사용자 결정 2026-09-07): the previous Tween is handed back unchanged when the target
-- value AND every option are the same — the Property handler's identity check then leaves the
-- active engine tween alone (no cancel + restart from the interpolated position, `H-391`).
-- `Dedup = false` (or a State of it) opts out — re-emitting the same target then re-triggers.
local function sameTween(previous: any, v: any, opts: { [string]: any }): boolean
	if previous.Value ~= v then
		return false
	end
	for _, name in FIELDS do
		if previous[name] ~= opts[name] then
			return false
		end
	end
	return true
end

local function install(quad: any, validateFields: (any) -> ()): any
	local isState = quad.isState
	local isTween = quad.isTween
	local None = quad.None
	local Tween = quad.Tween
	local Err = quad.errorNamespace -- shared namespace (`H-231`)

	-- if-then-else, not `and/or`: `false`-valued options (Override/CanAnimate)
	-- would leak the State object through an `and/or` ternary (canon note)
	local function resolve(v: any): any
		if isState(v) then
			return v:Get()
		else
			return v
		end
	end

	local function Animate(info: any): any
		if type(info) ~= "table" then
			Err.errorBeforeNearest("Animate: expected an options table (Animate{ Time = ... })", SURFACE)
		end
		-- `H-464`: validate the LITERAL options here, while the user's line is still on the
		-- stack — the Tween is built lazily inside Compute, where a raise blamed `Animate.luau`.
		-- State-valued options are resolved per run and validated by `Tween(opts)` then.
		local literal: { [string]: any } = {}
		for _, name in FIELDS do
			local v = info[name]
			if v ~= nil and not isState(v) then
				literal[name] = v
			end
		end
		validateFields(literal)
		return function(self: any): any
			return self:Compute(function(selfH: any, previous: any): any
				local v = selfH:Get()
				if v == nil or v == None then
					-- Q8 (a) (사용자 결정 2026-09-07): nil/None pass through untouched — the
					-- the Property handler writes nil (Q33 — object references release this way);
					-- wrapping them in a Tween used to reach the engine (`H-379`)
					return v
				end

				local canAnimate = resolve(info.CanAnimate)
				if canAnimate == nil then
					canAnimate = true -- omitted ⇒ always animate
				end
				if not canAnimate then
					return v -- bypass: plain value, no Tween wrapper
				end

				local opts: { [string]: any } = { Value = v }
				for _, name in FIELDS do
					opts[name] = resolve(info[name])
				end
				local dedup = resolve(info.Dedup)
				if dedup == nil then
					dedup = true -- omitted ⇒ dedup (Q12)
				end
				if dedup and isTween(previous) and sameTween(previous, v, opts) then
					return previous
				end
				return Tween(opts)
			end)
		end
	end

	Err.setFuncLevel(SURFACE, Animate) -- `H-238`: public factory tagged
	return Animate
end

return install
