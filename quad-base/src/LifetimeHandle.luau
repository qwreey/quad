--[[
	InitLifetimeHandle(module) — the *interface* of the four top-level
	lifetime primitives, installed on the module instance as error stubs.
	`.claude/base/lifecycle-pattern.md` "`bindLifetime`/`canBound`/`canExecute`/
	`unbindLifetime` — 확정" section; injection rule from
	`.claude/base/module-lifecycle-plan.md` ("base 유틸(... 생명 바인드 유틸)이
	인터페이스만 두고 실제 구현은 백엔드 팩토리가 뮤테이션으로 주입").

	Contract (types in `quad-types`):
	  bindLifetime(inst, value)   -- inst is needed here and only here
	  unbindLifetime(value)       -- early release of one value; no-op if unbound
	  canBound(value)  -> boolean -- "may I bind this now?"  true = not bound anywhere
	  canExecute(value)-> boolean -- "may this fire now?"    emit-propagation gate
	`canBound(v) == not canExecute(v)` — both wrap one private predicate
	(`isBoundAlive`) that belongs to the backend, not here.

	quad-base knows nothing about Instances, so these slots default to stubs
	that error loudly (never a silent no-op — base cannot guess an arbitrary
	engine's "right" default). quad-roblox overwrites them on the module
	instance (implemented in M5 unit 1 — `quad-roblox/src/LifetimeHandle.luau`);
	tests overwrite them with the mock backend
	(`quad-base/test/mock.luau` `installLifetime`, ROADMAP `H-97`).

	They are flat top-level functions, not `LifetimeHandle.bind(...)` —
	first-class primitives handler authors call directly, like `isState`.
	The `onDestroying(inst, fn)` engine op stub is installed here too (M2 unit
	3) — it belongs to the same backend injection and `Effect` needs it.
]]

local Err = require("./ErrorNamespace")
local QuadTypes = require("../luau_packages/quad_types")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

-- `raise` picks the error depth per slot (checklist 0, `H-348` → `H-370`):
--   - `bindLifetime`/`unbindLifetime`/`onDestroying` fire at dispatch depth
--     (`process` → handler → `bindLifetime`), so `errorBefore` (outermost) —
--     the real backend's `quad-roblox/src/LifetimeHandle.luau` does the same;
--   - `canBound`/`canExecute` are the direct-call primitives the header above
--     describes ("like `isState`") and the real backend never raises from them,
--     so `errorBeforeNearest` — blame lands on the handler author's own line,
--     not on whoever called `drive`.
local function notInstalled(name: string, raise: (string, any) -> ()): (...any) -> ...any
	local stub = function(...: any)
		raise(
			`quad: {name} is not available — no backend has installed the lifetime primitives `
				.. "(quad-roblox does this when it wraps the module; tests use mock.installLifetime)",
			SURFACE
		)
	end
	-- `H-231`: the stubs sit on the public surface until a backend overwrites
	-- them (the backend tags its own replacements via `Quad.errorNamespace`)
	Err.setFuncLevel(stub, SURFACE)
	return stub
end

local function Init(module: any)
	module.bindLifetime = notInstalled("bindLifetime", Err.errorBefore)
	module.unbindLifetime = notInstalled("unbindLifetime", Err.errorBefore)
	module.canBound = notInstalled("canBound", Err.errorBeforeNearest)
	module.canExecute = notInstalled("canExecute", Err.errorBeforeNearest)
	-- `onDestroying(inst, fn): Connection` — the injected engine op `Effect._bindDestroying`
	-- calls (`architecture.md` EngineOps line: a hook, not a manipulation, so no
	-- composition fallback — missing means a clear error). The same backend that
	-- fills the four above fills this one; until then, the same loud stub.
	module.onDestroying = notInstalled("onDestroying", Err.errorBefore)
end

return Init
