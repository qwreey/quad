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
	so they fall through to `Handlers/Event.luau` — a separate handler one
	band step below (`NORMAL - 1`, round10 Q58 (나); it was the same NORMAL
	value until 2026-09-17). A string key that is neither raises the
	regular no-match error.

	process is one line (`inst[k] = v`) — hash keys touch no Length/Offset
	bookkeeping (`H-39` is about ARRAY positions only). A property cannot be
	"unset", and a descending-diff replacement simply writes the next value — so
	the retractor does nothing on a value swap. [round10 Q53 (a), user decision
	2026-09-17; round11 `H-547` widened it from "a chain that has carried a Tween"
	to EVERY chain] the per-(inst, k) retractor is returned by every path —
	on teardown (`retracting == true`: `Dispatch.retractFrom`, the shorthand's
	managed-child destroy, AND Dispatch's handler-switch branch) it `Cancel`s the
	running engine tween and downgrades that record to `true` (round11 Q65: the
	record is per (inst, k) for the Instance's life — never reset to nil, so "first
	set = snap" is quad's first write to that property); on a value swap (`retracting == false`) it does nothing,
	because `process` already cancels/Finish-snaps by the INCOMING tween's
	`Override`. Before: the engine tween ran on into the destroyed child (Studio:
	the corner just vanished) and the stale slot deduped a re-declared same-target
	tween away (G-7). One closure per (inst, k), cached — not one per emit. `v == nil` (a `None` re-dispatch, or a
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
	local isTween = quad.isTween

	-- 3-state slot (header) — weak-keyed by inst through Relate, so a dying
	-- instance drops its slots (and the engine tween handle) with it
	local tweenSlots = quad.Relate()
	-- (inst, k) -> the tween-chain retractor (round10 Q53 (a)). Weak VALUE (`H-71`/`H-229`, checkpoint
	-- code-review): the closure captures `inst`, so a strong bucket value would back-reference its
	-- own weak key and pin every tweened Instance for the module's lifetime (Luau has no ephemerons).
	-- The live chain holds the retractor strongly (`list[index].retractor`); after teardown the
	-- entry may collect and a later chain simply mints a new one — identity never matters.
	local tweenRetractors = quad.Relate()

	-- [2026-09-21 사용자 결정 — docs-review 1-5; round13 묶음 1 2026-09-28 round13 tween-callback-structure §8-1] Tween callbacks
	-- `Started`/`Completed`/`Cancelled`, called `(inst, prop, value)` — the Instance, this property's key, and the
	-- target of the Tween the event is about. Nothing is CAPTURED for that (a closure holding `inst` in the engine
	-- tween's connection would pin the Instance while the record holds the tween — `audit/tween-completed-2026-09-21/
	-- REPORT.md` 7·8; weak-key tables are not ephemerons): the connection reads `rec.Tween.Instance`/`rec.Key`/
	-- `rec.Value` when it fires, every other site has `inst`/`k` in scope. Where they fire:
	--   Started   — right after `engineTween:Play()`; on a snap, right before Completed.
	--   Completed — from the engine `Completed` signal, only for `PlaybackState.Completed` (a natural finish);
	--               on a snap (first write, or an Info-less `Time == 0`); and for a REPLACED tween caught in the
	--               deferred-notice window (`H-581` — reached its target, notice not yet delivered). The engine
	--               re-fires `Completed(Cancelled)` even for a finished tween (REPORT 2), so the connection
	--               disconnects itself on its first fire and the record remembers `Done`.
	--   Cancelled — at quad's OWN `:Cancel()` site (value replacement) while that tween had not finished, and on
	--               EVERY teardown of a record naming an engine tween that had not settled — including the
	--               deferred-notice window (round13 Q99 c: the place is going away, so "it did reach the target"
	--               is not reported). The engine's own Cancelled notice is deferred (REPORT 3) — never used.
	-- Collect → write → call (round13 §3/§7): `process` settles the previous record WITHOUT calling the user,
	-- writes its own record (and `Play`s), and only then calls, in order: previous value's Cancelled / window
	-- Completed → this value's Started → (snap) Completed. A callback that re-enters the same (inst, k) replaces
	-- the record; the later callbacks of THIS value are then skipped (`GetStrong(inst, k) ~= rec`). So writing the
	-- same property from any callback lands in order and leaves one tween — the Property-layer half of `H-589`'s
	-- UB is gone (the StoreBind None-switch outer frame is not covered). Settle callbacks (the previous value's,
	-- teardown's) are skipped on an Instance quad no longer claims (round13 Q82 (a) — a corpse under
	-- `retractFrom`; the engine tween is still cancelled). A Destroy runs no chain retractor, so a tween keeps
	-- running on the destroyed Instance and the engine still sends `Completed` (REPORT 5·6) — ignored by the same
	-- `isClaimed` gate (round12 Q71, `H-594`). Dedup-skipped same-target Tween fires nothing (no tween starts) —
	-- the callbacks that stay wired are those of the value that actually STARTED the tween. A connection and the
	-- `Cb`/`Key` fields are made only when the value carries Completed or Cancelled (the connection is needed for
	-- the `Done` bookkeeping even when only Cancelled is given — otherwise a finished tween would get Cancelled
	-- on teardown); callback-less tweens keep the old record shape and GC profile. `Done` means SETTLED and is set
	-- before any callback runs, so a throwing callback cannot leave the record "running"; `Cb` is released as
	-- soon as it has been handed out.
	local function fire(v: any, name: string, inst: any, k: any, value: any)
		-- annotated on purpose: an unannotated `v[name]` narrowed by `~= nil` comes out as `*error-type* | ~nil`
		-- under the new solver (2026-09-21 scratch, `typing-limits.md` 8.24)
		local cb: ((any, string, any) -> ())? = v[name]
		if cb ~= nil then
			cb(inst, k, value)
		end
	end
	-- round13 묶음 1: a SETTLE callback (the previous value's Cancelled / window Completed, and teardown's Cancelled) —
	-- round13 Q82 (a): not on an Instance quad no longer claims (a corpse under `retractFrom`); the Cancel
	-- itself already happened in `settle`. Same gate as the engine connection's (Q71, `H-594`).
	local function fireSettled(cb: any?, name: string, inst: any, k: any, value: any)
		if cb ~= nil and quad.Backend.isClaimed(inst) then
			fire(cb, name, inst, k, value)
		end
	end
	-- round13 묶음 1 "collect -> write -> call": settle a record WITHOUT calling the user — Cancel its engine tween if
	-- it is still running, drop its connection, and hand back the callback holder plus whether it counts as
	-- FINISHED (deferred-notice window) so the caller fires it after its own slot write.
	-- The property keeps whatever value it reached (engine `Cancel` semantics).
	local function settle(rec: any): (any?, boolean)
		local conn = rec.Conn
		if conn ~= nil then
			rec.Conn = nil
			conn:Disconnect()
		end
		if rec.Done then
			return nil, false
		end
		rec.Done = true -- settle first (header)
		local cb = rec.Cb
		rec.Cb = nil
		-- Deferred-notice window (code-review 2026-09-21; REPORT 1·3): the engine flips `PlaybackState` when the
		-- tween reaches its target but delivers `Completed` only at the next resumption point — a synchronous
		-- replacement/teardown inside that window is a FINISH, not a cancel. The pending notice died with the
		-- connection above, so Completed is fired here instead (once). The engine state is read only for this
		-- gate; the record's value truth still comes from the property (retractor below).
		local playback = (Enum :: any).PlaybackState
		if playback ~= nil and rec.Tween.PlaybackState == playback.Completed then
			return cb, true
		end
		rec.Tween:Cancel()
		return cb, false
	end
	-- round13 묶음 1: the call phase of a transition — runs AFTER the slot holds `rec` (and after `Play`). Order:
	-- previous value's settle (Cancelled / window Completed) → this value's Started → (snap) Completed. A
	-- callback that re-entered the same (inst, k) and replaced `rec` stops the chain: the later callbacks of
	-- THIS value are not fired (the Q91 OLD-FIRST `GetStrong` check, generalized). `oldValue` = the previous
	-- record's target (the value its callbacks were about).
	local function announce(inst: any, k: any, rec: any, v: any, oldCb: any?, oldFinished: boolean, oldValue: any, snapped: boolean)
		fireSettled(oldCb, if oldFinished then "Completed" else "Cancelled", inst, k, oldValue)
		if tweenSlots:GetStrong(inst, k) ~= rec then
			return
		end
		fire(v, "Started", inst, k, v.Value)
		if snapped and tweenSlots:GetStrong(inst, k) == rec then
			fire(v, "Completed", inst, k, v.Value)
		end
	end
	-- Snap: write the target now, no engine tween; `{ Value }` keeps the dedup honest (Q26 (a)).
	local function snap(inst: any, k: any, v: any, oldCb: any?, oldFinished: boolean, oldValue: any)
		inst[k] = v.Value
		local srec = { Value = v.Value }
		tweenSlots:SetStrong(inst, k, srec)
		announce(inst, k, srec, v, oldCb, oldFinished, oldValue, true)
	end

	local function tweenRetractor(inst: any, k: any): (any?, boolean) -> ()
		local r = tweenRetractors:GetWeak(inst, k)
		if r == nil then
			r = function(_nextValue: any?, retracting: boolean)
				if not retracting then
					return -- value swap: process handles the previous tween (Override)
				end
				-- round11 Q65 (user decision 2026-09-18): teardown does NOT forget that the property was
				-- written. "First set = snap" means quad's first write to THIS (inst, k) — the record lives
				-- with the Instance (weak key), not with the chain. Only a record that names a RUNNING tween
				-- is downgraded: after `Cancel` the property sits at an interpolated value, so its `Value`
				-- would be a lie the dedup believes (G-7 — a re-declared same-target tween skipped for good).
				-- `true` = "set before, target unknown" — the next Tween always plays. A `true` / `{ Value }`
				-- record (nothing running) stays: the property really holds that value. Before this, the
				-- slot was reset to nil, which also fired on a handler switch (plain ↔ State, via None — the
				-- (B) branch calls the old retractor with retracting == true) and made the next Tween snap.
				local slot = tweenSlots:GetStrong(inst, k)
				if type(slot) == "table" and slot.Tween ~= nil then
					local cb = settle(slot) -- Cancel (if still running) + Disconnect; callback held (window or not)
					-- code-review (2026-09-18): `.Tween` is still set after a tween COMPLETED on its own,
					-- and then the property really holds `Value` — keep the `{ Value }` snap record so the
					-- dedup stays right. The record's truth is read from the property itself, not from the
					-- engine's PlaybackState (engine-agnostic, mock-safe); `Done` only gates the callback.
					tweenSlots:SetStrong(inst, k, if inst[k] == slot.Value then { Value = slot.Value } else true)
					-- round13 묶음 1: after this retractor's own record write. round13 Q99 c: a teardown is ALWAYS
					-- Cancelled, even inside the deferred-notice window (the tween did reach its target, but the
					-- place is going away — the replacement window keeps Completed, `H-581`).
					fireSettled(cb, "Cancelled", inst, k, slot.Value)
				end
			end
			tweenRetractors:SetWeak(inst, k, r)
		end
		return r
	end

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
				return tweenRetractor(inst, k) -- still a tween chain: teardown must cancel/clear (Q53)
			end
			if prev == nil then
				-- branch 1: first set — snap, no animation even for a Tween value.
				-- Q26 (a) (2026-09-08, round3 §4): a Tween keeps `{ Value }` (no engine
				-- tween) so the value dedup above already holds after the snap.
				if tweenIn then
					snap(inst, k, v, nil, false, nil)
				else
					inst[k] = v
					tweenSlots:SetStrong(inst, k, true)
				end
				return tweenRetractor(inst, k) -- `H-547`: every chain, see the plain tail below
			end
			-- [2026-09-21] an Info-less `Time == 0` Tween with nothing else to play (no delay, no repeat, no
			-- reverse) is a snap with callbacks — Animate's CanAnimate=false path hands one over, and a hand-written
			-- one behaves the same (the only difference from the engine is that the write is synchronous;
			-- CHANGELOG Changed). Any of those fields set keeps the engine path (code-review 2026-09-21).
			local zeroTime = tweenIn and v.Info == nil and v.Time == 0
				and (v.DelayTime == nil or v.DelayTime == 0)
				and (v.RepeatCount == nil or v.RepeatCount == 0)
				and v.Reverses ~= true
			-- 6순회 `H-406` (`H-256` (a) read-then-write, second site): build the NEW
			-- engine tween before touching the old one — `TweenService:Create` may
			-- raise on engine-typed options (header), and cancelling first left a
			-- slot naming a dead tween whose stale target a later `Finish` snapped
			-- to. The slot is written before `Play` so a raise there leaves at most
			-- an unplayed tween the slot knows about.
			local engineTween = if tweenIn and not zeroTime then getTweenService():Create(inst, buildInfo(v), { [k] = v.Value }) else nil
			-- round13 묶음 1: the previous value's settle, fired after our write (with its own target as `value`)
			local oldCb: any, oldFinished, oldValue: any = nil, false, nil
			if type(prev) == "table" and prev.Tween ~= nil then
				-- branch 3: an engine tween is active — clean it up before the new value lands
				-- (a snapped `{ Value }` record has nothing to cancel and nothing to
				-- Finish-snap to: the property already holds that value)
				oldCb, oldFinished = settle(prev) -- Cancel (if still running) + Disconnect; callback held
				oldValue = prev.Value
				if tweenIn and v.Override == "Finish" and not zeroTime then
					-- (a zero-time snap writes `v.Value` right below — a Finish snap first would be a second
					-- synchronous write of the same property, visible under Immediate signals; code-review)
					inst[k] = prev.Value -- Finish: snap to the previous target before continuing
				end
			end
			if zeroTime then
				snap(inst, k, v, oldCb, oldFinished, oldValue)
				return tweenRetractor(inst, k)
			end
			-- branches 2/3 tail: plain → write + `true`; Tween → slot, then play
			if tweenIn then
				local rec: any = { Tween = engineTween, Value = v.Value }
				tweenSlots:SetStrong(inst, k, rec)
				if v.Completed ~= nil or v.Cancelled ~= nil then
					-- `Cb` and the connection share this gate (header: Cancelled alone still needs `Done`);
					-- the closure captures `rec`/`conn` only — never `inst`. round13 묶음 1: `Key` = the property name the
					-- connection reports as `prop` (a string — pins nothing); inst/value are read off the record.
					rec.Cb = v
					rec.Key = k
					local conn: any
					conn = engineTween.Completed:Connect(function(state: any)
						conn:Disconnect()
						if rec.Conn == conn then
							rec.Conn = nil
						end
						if state == Enum.PlaybackState.Completed and not rec.Done then
							rec.Done = true
							local cb = rec.Cb
							rec.Cb = nil
							-- round12 Q71 (user decision 2026-09-21, `H-594`): a Destroy runs no chain retractor, so the
							-- engine tween finishes on the corpse and still sends this notice (REPORT 5·6). Not undone,
							-- just IGNORED: `isClaimed` reads the gcconn Destroy cuts synchronously (even under
							-- Deferred), and only a claimed Instance can carry a tween in the first place. The Instance
							-- is read off the tween (the engine tween holds it anyway) — the closure still captures no
							-- `inst`.
							if cb ~= nil and quad.Backend.isClaimed(rec.Tween.Instance) then
								fire(cb, "Completed", rec.Tween.Instance, rec.Key, rec.Value)
							end
						end
					end)
					rec.Conn = conn
				end
				engineTween:Play()
				announce(inst, k, rec, v, oldCb, oldFinished, oldValue, false)
				return tweenRetractor(inst, k)
			end
			inst[k] = v
			tweenSlots:SetStrong(inst, k, true)
			-- round13 묶음 1: plain incoming value — the previous value's settle after the `true` record
			fireSettled(oldCb, if oldFinished then "Completed" else "Cancelled", inst, k, oldValue)
			-- round11 `H-547` (탐사 D′): EVERY chain returns the retractor, not only one that has carried
			-- a Tween. Two reasons — (1) the checkpoint's `GetWeak(...) or Void` relied on the previous
			-- chain's `list[index].retractor` keeping the closure alive, but Dispatch parks NOOP there
			-- before calling `process`, so a GC step inside this function turned it into Void (the
			-- Tween record then survived teardown: no Cancel, next re-drive animated); (2) a chain that
			-- never carried a Tween wrote `true` with Void, so after teardown the next Tween skipped
			-- branch 1 and animated instead of snapping (tween-plan "3-state store"). The retractor is
			-- cached weakly and re-minted when collected — identity never matters.
			return tweenRetractor(inst, k)
		end,
	} :: QuadTypes.Handler)
end

return install
