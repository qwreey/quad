--!strict
--[[
	EventHandler — the string-key terminal handler for engine signals
	(`Frame { MouseButton1Click = fn }`). Backend-owned: Reflection and the
	signal itself are the logic (`architecture.md` "패키지 경계"
	분할 기준, `dispatch-core-plan.md` "base가 소유하는 핸들러와 주입되는 엔진
	op" 절). Canon: `base/event-plan.md` (both sections, as-is) +
	`bind-system-plan.md` "인스턴스 생성 / 이벤트 네이밍 인체공학" 절 (plain
	string key + reflection, no `On.X` dot-access).

	Match rule: string key ∧ the key is an event of `inst.ClassName` per
	`ReflectionService:GetEventsOfClass` (descriptor array with `.Name`,
	inherited included — Studio-measured 2026-09-03; events are NOT in
	`GetPropertiesOfClass`, so this set and PropertyHandler's are disjoint
	and both sit at NORMAL priority). The match is KEY-based on purpose: it
	must also fire for `v == nil` (event-plan "이벤트도 store-bind 가능" —
	`= None` reaches here as `nil` through NoneHandler's recursion; NilHandler
	is number-key only, so no overlap).

	process:
	  v == nil  → no Connect, `Void` retractor (the previous binding's own
	              retractor already disconnected — descending-diff order).
	  otherwise → `inst[k]:Connect(v)` — the user's function goes to the
	              engine AS-IS (no self/Instance wrapper: event-plan 1절), and
	              the retractor closes over the Connection and disconnects it
	              (no per-instance store — `dispatch-core-plan.md` "핸들러 내부
	              상태 저장" 절).
	No same-value dedup (`H-154` is about physical detach/attach that emits
	engine events; `Connect` is not idempotent, so a one-sided retractor skip
	would double-connect). Re-emitting the same function costs one
	Disconnect+Connect — the churn caveat event-plan documents as accepted.
	Value-type guard (`H-507`, 2026-09-08 Studio 실측): the old posture "a
	non-function reaches `Connect` and the engine raises" is FALSE on the
	current engine — `signal:Connect(5)` returns an RBXScriptConnection and only
	prints "Attempt to connect failed: Passed value is not a function" to the
	output (pcall sees no error), blaming `Handlers/Event.luau`. So `process`
	gates it: outermost (dispatch depth). The generated `D` types still pin
	the callback signature statically; this is the runtime seam for `:: any`
	and State-carried values (StoreBind unwraps before we see them).

	`game` is read lazily inside the cache-miss path so the CLI spec can
	substitute a Reflection shim via `getfenv` (Property.luau seam).
]]

local QuadTypes = require("../../luau_packages/quad_types")
local Reflection = require("../Reflection")

local function install(quad: any)
	local dispatch = quad.Dispatch
	local Void = quad.Void
	local Err = quad.errorNamespace
	local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

	-- className -> { [eventName]: true } (inherited included — one Reflection
	-- call per class, cached for the module's lifetime; `Reflection.luau`
	-- memoizer, Q3 ④). `game` is read HERE (the getfenv shim seam, header).
	local isEventOf = Reflection.memberSet(function(className: string): { any }
		return game:GetService("ReflectionService"):GetEventsOfClass(className)
	end)

	dispatch.addHandler({
		name = "Event",
		keyType = "string", -- `H-484`: only string keys can match (isHandlable checks it too)
		isHandlable = function(inst: any, k: any, _v: any): boolean
			-- v deliberately not inspected — nil must match too (header)
			return type(k) == "string" and isEventOf(inst.ClassName, k)
		end,
		priority = dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(inst: any, k: any, v: any, _index: number): (any?, boolean) -> ()
			if v == nil then
				return Void -- `None`/`nil`: disconnect-only (event-plan) — nothing to connect
			end
			if type(v) ~= "function" then
				Err.errorBefore(`Event: handler for "{k}" must be a function (got {typeof(v)})`, SURFACE) -- `H-507`
			end
			local connection = inst[k]:Connect(v)
			return function(_nextValue: any?, _retracting: boolean)
				connection:Disconnect()
			end
		end,
	} :: QuadTypes.Handler)
end

return install
