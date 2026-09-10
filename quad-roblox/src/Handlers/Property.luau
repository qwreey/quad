--!strict
--[[
	PropertyHandler — the plain-property terminal handler (backend-owned:
	Reflection is an engine concept, `dispatch-core-plan.md` "base가 소유하는
	핸들러와 주입되는 엔진 op" 절).

	Match rule: string key ∧ key ~= "Parent" (`H-142` — the rejection IS the
	runtime guard: no handler matches, so `Dispatch.process` raises its
	regular no-match error; no special wording, `H-148`) ∧ the key is a real
	property of `inst.ClassName` per `ReflectionService:GetPropertiesOfClass`
	(descriptor array with `.Name`, inherited included — Studio-measured
	2026-09-02). Event keys are NOT properties in that API (measured
	2026-09-03: `GetEventsOfClass` and `GetPropertiesOfClass` are disjoint),
	so they fall through to `Handlers/Event.luau` — a separate handler at the
	same NORMAL priority (M10). A string key that is neither raises the
	regular no-match error.

	process is one line (`inst[k] = v`) — hash keys touch no Length/Offset
	bookkeeping (`H-39` is about ARRAY positions only). The retractor is
	`Void`: a property cannot be "unset", and a descending-diff replacement
	simply writes the next value. `v == nil` (a `None` re-dispatch, or a
	State that computed nil) WRITES nil — [Q33 (a), 2026-09-08] object
	references (Adornee/Part0/NextSelection*) are released only this way; a
	property that cannot take nil raises in the engine, and that raise is the
	user's error to see (the old M10 skip-defense, `H-352`, swallowed None
	silently — reversed). An active tween on that key is cancelled first
	(plain-value path), spec.tweenproperty 6절.

	M11 unit ② (round19, `tween-plan.md` "3-상태 저장" / "override 정책" /
	"옵션 값 모양"): `isTween(realv)` is a branch INSIDE process, not a
	handler — the 3-state relation slot per (inst, propName):
	  nil                            never processed here → first set SNAPS
	                                 (even a Tween writes `Value` directly —
	                                 no engine tween, no entry animation)
	  true                           set before (plain value), no active engine tween
	  { Value }                      [Q26 (a), 2026-09-08] a Tween SNAPPED here (first set) —
	                                 no engine tween, the target is kept for the dedup below
	  { Tween = TweenBase, Value }   an engine tween is running toward Value
	Dedup ([2026-09-08 user decision, round3 Q25] — replaces the 2026-09-07 Q12 object-identity
	check): an incoming Tween whose `Value` EQUALS the recorded target does nothing — the
	active tween keeps running, a finished one is not re-triggered. Only `Value` is compared
	(user: Time/Style/… are not comparison targets, as option changes never re-animated);
	`Tween{ Dedup = false }` opts out. Value equality is the engine's (`UDim.new(0, 8)` twice
	is equal), which is why the shorthand handler's `Mapped` copies fold too. A plain-value
	slot (`true`) records no value, so a Tween arriving there always plays.
	Order invariant: an active tween is cancelled BEFORE the new value is
	written (the engine keeps writing the property asynchronously). The
	override policy consulted is the INCOMING Tween's `Override` (`H-328`):
	`"Finish"` snaps the previous target first; `"Cancel"` (default, `H-343`)
	and a plain incoming value continue from the interpolated value as-is.
	`TweenInfo`: `Info` wins; otherwise the convenience fields go to
	`TweenInfo.new` positionally with the engine's own defaults filled in for
	absent fields (`H-333` — an explicit nil is rejected by the engine). `TweenService`/`TweenInfo` are read lazily so the
	CLI spec can shim both through `getfenv` (same seam as Reflection).
	Engine-typed option misuse (`Style = 3`, wrong `Info`) raises the engine's
	own error inside process — same class as `inst[k] = wrongValue` (Q5 (a)).

	The `game` global is read lazily inside the cache miss path so the CLI
	spec can substitute a Reflection shim via `getfenv` (same seam the D
	pipeline spec uses for `Instance`).
]]

local QuadTypes = require("../../luau_packages/quad_types")
local Reflection = require("../Reflection")

local function install(quad: any)
	local dispatch = quad.Dispatch
	local Void = quad.Void
	local isTween = quad.isTween

	-- 3-state slot (header) — weak-keyed by inst through Relate, so a dying
	-- instance drops its slots (and the engine tween handle) with it
	local tweenSlots = quad.Relate()

	local tweenService: any = nil
	local function getTweenService(): any
		if tweenService == nil then
			tweenService = game:GetService("TweenService")
		end
		return tweenService
	end

	-- `H-333` (Studio 2026-09-06): `TweenInfo.new` rejects an explicit nil in an
	-- enum position ("third argument expects Enum.EasingDirection"), so the
	-- convenience fields cannot be passed through as nil — the defaults are
	-- spelled out here and equal `TweenInfo.new()`'s own (tween-plan "옵션 값
	-- 모양" 절의 기본값 표 — 값의 소스는 여전히 엔진이고 여기는 그 사본).
	local function buildInfo(v: any): any
		if v.Info ~= nil then
			return v.Info
		end
		return TweenInfo.new(
			if v.Time ~= nil then v.Time else 1,
			if v.Style ~= nil then v.Style else Enum.EasingStyle.Quad,
			if v.Direction ~= nil then v.Direction else Enum.EasingDirection.Out,
			if v.RepeatCount ~= nil then v.RepeatCount else 0,
			if v.Reverses ~= nil then v.Reverses else false,
			if v.DelayTime ~= nil then v.DelayTime else 0
		)
	end

	-- className -> { [propName]: true } (inherited included — one Reflection
	-- call per class, cached for the module's lifetime; `Reflection.luau`
	-- memoizer, Q3 ④). `game` is read HERE (the getfenv shim seam, header).
	local isPropertyOf = Reflection.memberSet(function(className: string): { any }
		return game:GetService("ReflectionService"):GetPropertiesOfClass(className)
	end, function(d: any): boolean
		-- `H-302`(리뷰 발견, `H-297` (a)의 런타임판): 쓰기 표면만 매치 —
		-- 읽기 전용(AbsoluteSize 등)은 `Permits.Write` 키 자체가 없다
		-- (Studio 실측 2026-09-02). 걸러두지 않으면 대입이 h.process
		-- 한가운데서 엔진 원시 에러를 내고 `H-103` NOOP 마커가 고착된다.
		return d.Permits ~= nil and d.Permits.Write ~= nil
	end)

	dispatch.addHandler({
		name = "Property",
		keyType = "string", -- `H-484`: only string keys can match (isHandlable checks it too)
		isHandlable = function(inst: any, k: any, _v: any): boolean
			return type(k) == "string" and k ~= "Parent" and isPropertyOf(inst.ClassName, k)
		end,
		priority = dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			-- [Q33 (a), 사용자 결정 2026-09-08 — round3 §11] NO nil skip: nil is a legitimate write
			-- (object references — Adornee/Part0/NextSelection* — release only this way; the
			-- engine itself raises on a property that cannot take nil, and that is the user's
			-- error to see). The old skip-defense (M10, `H-352`) silently swallowed None here.
			-- A nil takes the plain-value path below: it cancels an active tween and writes nil.
			local prev = tweenSlots:GetStrong(inst, k)
			local tweenIn = isTween(v)
			if tweenIn and type(prev) == "table" and v.Dedup ~= false and prev.Value == v.Value then
				-- Q25 (사용자 결정 2026-09-08): same target VALUE — the active tween keeps
				-- running, no cancel + restart (`H-391`); a completed tween is not
				-- re-triggered either. `Tween{ Dedup = false }` is the re-trigger switch.
				return Void
			end
			if prev == nil then
				-- branch 1: first set — snap, no animation even for a Tween value.
				-- Q26 (a) (2026-09-08, round3 §4): a Tween keeps `{ Value }` (no engine
				-- tween) so the value dedup above already holds after the snap.
				inst[k] = if tweenIn then v.Value else v
				tweenSlots:SetStrong(inst, k, if tweenIn then { Value = v.Value } else true)
				return Void
			end
			-- 6순회 `H-406` (`H-256` (a) read-then-write, second site): build the NEW
			-- engine tween before touching the old one — `TweenService:Create` may
			-- raise on engine-typed options (header), and cancelling first left a
			-- slot naming a dead tween whose stale target a later `Finish` snapped
			-- to. The slot is written before `Play` so a raise there leaves at most
			-- an unplayed tween the slot knows about.
			local engineTween = if tweenIn then getTweenService():Create(inst, buildInfo(v), { [k] = v.Value }) else nil
			if type(prev) == "table" and prev.Tween ~= nil then
				-- branch 3: an engine tween is active — clean it up before the new value lands
				-- (a snapped `{ Value }` record has nothing to cancel and nothing to
				-- Finish-snap to: the property already holds that value)
				prev.Tween:Cancel()
				if tweenIn and v.Override == "Finish" then
					inst[k] = prev.Value -- Finish: snap to the previous target before continuing
				end
			end
			-- branches 2/3 tail: plain → write + `true`; Tween → slot, then play
			if tweenIn then
				tweenSlots:SetStrong(inst, k, { Tween = engineTween, Value = v.Value })
				engineTween:Play()
			else
				inst[k] = v
				tweenSlots:SetStrong(inst, k, true)
			end
			return Void
		end,
	} :: QuadTypes.Handler)
end

return install
