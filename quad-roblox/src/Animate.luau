--!strict
--[[
	Animate — the `:Apply` combinator that wraps a State's value in a
	`Tween{...}` with fixed options (M11 unit ③, round19). Canonical:
	`.claude/base/tween-plan.md` "`Animate` 콤비네이터" 절 (pseudocode 1:1) and
	"왜 `:Apply`로 정정됐는가" 절 (named combinators attach through `:Apply`,
	never `:Compute` directly — `base/operator-plan.md`).

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

-- `Dedup` rides along as a plain Tween field ([2026-09-08 user decision, round3 Q25] — the
-- dedup MECHANISM lives in the consumer, the Property handler, which compares the incoming
-- target `Value` with the slot's recorded target; Animate no longer hands back the previous
-- Tween object — the 2026-09-07 Q12 identity model was replaced because identity broke under
-- any value transform, e.g. the shorthand handler's `Mapped`).
-- [2026-09-21] the three callbacks ride along too (functions pass `resolve` untouched — not States).
local FIELDS = { "Info", "Time", "Style", "Direction", "RepeatCount", "Reverses", "DelayTime", "Override", "Dedup", "Started", "Completed", "Cancelled" }
local CALLBACK_FIELDS: { [string]: boolean } = { Started = true, Completed = true, Cancelled = true } -- round13 Q115 (a)

-- ── debug layer: unknown option keys ──
-- [2026-09-15 사용자 결정] unknown keys (typos such as `Duration`) are reported only under `q.debug`;
-- execution continues with the defaults. Body kept out of `Animate` (`architecture.md` "debug 층": the
-- logic carries one line).
local KNOWN_OPTIONS: { [string]: boolean } = { CanAnimate = true }
for _, name in FIELDS do
	KNOWN_OPTIONS[name] = true
end
-- [2026-10-06 user decision, round14 Q179] the same pass names the convenience fields an `Info` overrides —
-- the case the user named: `Info` given and `Time` fed as a State here, and the tween "does not follow" the
-- Time (`Info` wins in the Property handler's `buildInfo`). The line itself is `Tween.luau`'s `warnInfoOverlap`
-- (one helper for both — round14 확인 패스 code-review 5), handed over by `RobloxFactory` with the validator;
-- an `Info` State gets the "while it holds a value" wording (code-review 4: one holding nil leaves the
-- tween Info-less, the convenience fields then apply).
local function warnUnknownOptions(info: { [any]: any }, warnInfoOverlap: (string, any, boolean) -> (), isState: (any) -> boolean)
	for key in info do
		if not KNOWN_OPTIONS[key] then
			print(`Animate: unknown option "{tostring(key)}" is ignored (known: {table.concat(FIELDS, ", ")}, CanAnimate)`)
		end
	end
	warnInfoOverlap("Animate", info, isState(info.Info))
end

local function install(quad: any, validateFields: (any, any?) -> (), tweenOutermost: (any) -> any, warnInfoOverlap: (string, any, boolean) -> ()): any
	local isState = quad.isState
	local None = quad.None
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
			Err.errorBeforeNearest(`Quad0214 Animate: options must be a table, e.g. Animate\{ Time = ... \} (got {typeof(info)})`, SURFACE)
		end
		if quad.debug then
			warnUnknownOptions(info, warnInfoOverlap, isState) -- debug layer (top of file)
		end
		-- `H-464`: validate the LITERAL options here, while the user's line is still on the
		-- stack — the Tween is built lazily inside Compute, where a raise blamed `Animate.luau`.
		-- State-valued options are resolved per run and validated by `Tween(opts)` then.
		-- round13 Q115 (a) (user decision 2026-09-28): the three callbacks never take a State (types and
		-- roblox/06 say so) — keep them in the literal set so a State fails `Quad0246` here, on the user's
		-- line. Before, the animating path `resolve`d a State callback into a function while the
		-- `CanAnimate = false` path handed `info.Started` over raw and died on the same option.
		local literal: { [string]: any } = {}
		for _, name in FIELDS do
			local v = info[name]
			if v ~= nil and (not isState(v) or CALLBACK_FIELDS[name]) then
				literal[name] = v
			end
		end
		validateFields(literal)
		-- round13 Q116 (a) (user decision 2026-09-28): the one option that had no runtime check —
		-- `"no"`/`0`/a function were truthy and silently animated. Literal here (user's `Animate{}`
		-- line, like `Quad0243`~`0247`); a State value is checked per run below (outermost blame).
		local canAnimateOpt = info.CanAnimate
		if canAnimateOpt ~= nil and not isState(canAnimateOpt) and type(canAnimateOpt) ~= "boolean" then
			Err.errorBeforeNearest(`Quad0253 Animate: CanAnimate must be a boolean or a State<boolean> (got {typeof(canAnimateOpt)})`, SURFACE)
		end
		return function(self: any): any
			-- round13 Q104 (a) (user decision 2026-09-28): a State-only factory, the Operator `Quad0123`
			-- shape. Through `mod:Apply` / `tag:Apply` / a Modifier setter's transform arm `self` is not a
			-- State and `self:Compute` died inside quad (a VM error on `nil:Get`, or a missing method on a
			-- Tag). Nearest blame: `Modifier:Apply`/`Tag:Apply` are SURFACE-tagged, so the user's `:Apply`
			-- line; the setter transform arm is untagged (`H-250`), so there it falls back to this line.
			if not isState(self) then
				Err.errorBeforeNearest(`Quad0252 Animate: Apply target must be a State (got {if quad.isModifier(self) then "Modifier" elseif quad.isTag(self) then "Tag" else typeof(self)}) - put the Animate on the State that feeds the field: state:Apply(q.Animate\{ ... \})`, SURFACE)
			end
			return self:Compute(function(selfH: any): any
				local v = selfH:Get()
				if v == nil or v == None then
					-- Q8 (a) (사용자 결정 2026-09-07): nil/None pass through untouched —
					-- the Property handler writes nil (Q33 — object references release this way);
					-- wrapping them in a Tween used to reach the engine (`H-379`)
					return v
				end

				local canAnimate = resolve(info.CanAnimate)
				if canAnimate == nil then
					canAnimate = true -- omitted ⇒ always animate (a State holding nil too)
				elseif type(canAnimate) ~= "boolean" then
					-- Q116 (a): a State-valued CanAnimate, resolved per run (its own ID — one raise site, one ID)
					Err.errorBefore(`Quad0254 Animate: CanAnimate State must hold a boolean or nil (got {typeof(canAnimate)})`, SURFACE)
				end
				if not canAnimate then
					-- [2026-09-21 사용자 결정 — docs-review 1-5 (a)] callbacks must still fire without animation
					-- (a dialog's Visible handling hangs off Completed whether or not motion is on): hand the
					-- Property handler an Info-less `Time == 0` Tween — it snaps and calls Started/Completed
					-- synchronously, no engine tween. Without callbacks the plain value goes through as
					-- before (no wrapper — every slot consumer accepts it; calling them from inside this
					-- Compute was rejected: the property is not written yet at this point).
					local started, completed, cancelled = info.Started, info.Completed, info.Cancelled
					if started == nil and completed == nil and cancelled == nil then
						return v -- bypass: plain value, no Tween wrapper
					end
					return tweenOutermost({ Value = v, Time = 0, Dedup = resolve(info.Dedup), Started = started, Completed = completed, Cancelled = cancelled })
				end

				local opts: { [string]: any } = { Value = v }
				for _, name in FIELDS do
					opts[name] = resolve(info[name])
				end
				-- `H-502`/round10 G-1: everything here runs inside Compute, where the nearest tagged frame is
				-- quad's own — so the whole construction (field checks AND the four `Value` checks) uses the
				-- outermost-blame constructor; the former separate `validateFields(opts, Err.errorBefore)` line
				-- was an exact duplicate of what `tweenOutermost` runs (code-review)
				return tweenOutermost(opts) -- a fresh value every run; the Property handler folds equal targets
			end)
		end
	end

	Err.setFuncLevel(SURFACE, Animate) -- `H-238`: public factory tagged
	return Animate
end

return install
