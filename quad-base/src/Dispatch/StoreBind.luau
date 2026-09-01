--[[
	StoreBind — the recursive re-execution handler (`.claude/base/
	dispatch-core-plan.md` "Store 바인드는 특수 경우인가, 아니면 pluggable
	바인드를 재실행하는 래핑인가" section, as-is; M4).

	Store binding is not a special case: this is an ordinary handler under the
	same `isHandlable`/`priority`/`process` contract whose process subscribes
	(`state:Observer(fn)` reuse — no store-bind-only primitive) and, on every
	emission, hands the real value down with `Dispatch.process(inst, k, realv,
	index + 1)` — NO preceding retractFrom (descending diff decides what to
	retract; checklist 2). A realv that is itself a State/Source lands on this
	same handler at `index + 1` — a separate slot, so no identity collision
	(`State<State<T>>`); a non-reactive realv fails `isHandlable` and falls to
	the next-priority handler — no infinite recursion. `Observer` fires once at
	registration, so first apply and re-runs share one code path.

	Lifetime: the observer is born inside `process` and bound with
	`bindLifetime(inst, observer)` — inst-scoped plumbing, never `:Subscribe()`
	(the global path). Liveness needs no handler code: `_receive` gates each
	fire with `canExecute(observer)`, whose verdict comes from the gcconn
	reference `bindLifetime` copied onto the observer ("핸들러가 직접
	`canExecute`/liveness를 재구현할 필요 없음"). The retractor does exactly
	one thing — `unbindLifetime(observer)`: the observer is an upvalue (no
	Relate lookup), delegated cleanup below is `retractFrom`'s job, and the
	`retracting` flag can be ignored here (own-resource release only; this
	handler never receives nil as a value — brief §1 note ②).

	Registered per module instance by `InitDispatch`'s tail (round13 §0 Q3
	(a) — `None.luau` precedent: StoreBind is the descending diff's own
	recursion, a dispatch-skeleton concept, not any one value module's).
	Priority HIGH — the skeleton band ("base가 소유하는 핸들러가 전부 여기
	오는 게 아님": StoreBind must outmatch property setters); predicates in
	the band are disjoint, so the tie carries no ordering dependence.
	Lifetime fields are read off `module` at call time (`H-174` — the backend
	overwrites them after `New()`).
]]

local Brand = require("../Brand")
local QuadTypes = require("../../luau_packages/quad_types")

-- `isState` composes `isSource` (Source structurally satisfies State,
-- `Brand.luau`) — exactly the "v가 State/Source인 경우" the section confirms.
local isState = Brand.isState

local StoreBind = {}

-- Called by InitDispatch once per module instance, after the Dispatch table
-- is assembled (the factory pattern, `H-174`). addHandler tags the received
-- functions into the shared error namespace itself.
-- Typed against the shared contract (`H-259`).
function StoreBind.register(dispatch: QuadTypes.Dispatch, module: any)
	dispatch.addHandler({
		name = "StoreBind",
		isHandlable = function(_inst: any, _k: any, v: any): boolean
			-- k is anything (array position or hash key) — only v matters
			return isState(v)
		end,
		priority = dispatch.HANDLER_PRIORITY_HIGH,
		process = function(inst: any, k: any, state: any, index: number): (any?, boolean) -> ()
			-- Fires once right here (registration fire) — the initial mount IS
			-- the first re-run. The (B)-branch occupancy marker is already in
			-- place, so the recursion below finds a hole-free chain list.
			local observer = state:Observer(function()
				local realv = state:Get()
				dispatch.process(inst, k, realv, index + 1)
			end)
			module.bindLifetime(inst, observer)
			return function(_nextValue: any?, _retracting: boolean)
				-- Own resource only — the descending diff (or retractFrom)
				-- handles everything delegated below this slot.
				module.unbindLifetime(observer)
			end
		end,
	})
end

return StoreBind
