--[[
	InitLifetimeHandle(module) — the *interface* of the four top-level
	lifetime primitives, installed on the module instance as error stubs.
	`.claude/base/lifecycle-pattern.md` "`bindLifetime`/`canBound`/`canExecute`/
	`unbindLifetime` — 확정" section; injection rule from
	`.claude/base/module-lifecycle-plan.md` ("base 유틸(... 생명 바인드 유틸)이
	인터페이스만 두고 실제 구현은 백엔드 팩토리가 뮤테이션으로 주입").

	Contract (types in `quad-types`):
	  bindLifetime(inst, value)   -- inst is needed here and only here
	  unbindLifetime(value)       -- early release of one value; no-op if unbound, nil is an error (`H-474`)
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
	2순회 `H-373`: so are `isInst`/`nativeClaim`/`nativeFindChild` — the three
	ops `architecture.md` (EngineOps line) and `slot-plan.md` ("기본 구현(조합
	폴백) — 미주입이 에러가 아니다") classify with `onDestroying` as "cannot be
	composed, so missing = a clear error"; without stubs a bare `Quad.New()`
	raised a nil-call from `Slot/Elements.luau`/`Claim.luau` and blamed quad internals.
]]

local NotInstalled = require("./NotInstalled")

-- Error depth (checklist 0): `errorBefore` (outermost) for EVERY stub — `H-348`,
-- restored by 3순회 `H-378` after `H-370`/`H-373` gave `canBound`/`canExecute`/
-- `isInst` `errorBeforeNearest`: the stub tags ITSELF (`H-231` below), so
-- "nearest" is always the stub's direct caller — and in-tree that caller is
-- quad internals (`Observer.luau` `Subscribe` → `canBound`, `Slot/Elements.luau` →
-- `isInst`), which blamed `Observer.luau:139`/옛 `Slot.luau:52`(now `Slot/init.luau`). Outermost
-- reaches the user's line from both direct and dispatch-depth calls; what it
-- does not serve is any USER CALLBACK running inside a tagged public method
-- (an Observer/Effect fn, `Tag:Apply`, a handler author's `canBound(v)` line) —
-- those blame the public call that ran the callback; §4 Q7 (untagged stubs).
-- the loud stub factory (`NotInstalled.luau` — one body for the three modules, Q3 ②;
-- the blame reasoning above is repeated in that file's header)
local function notInstalled(name: string): (...any) -> ...any
	return NotInstalled(name, "the lifetime primitives / engine ops", "; tests use mock.installLifetime")
end

local function Init(module: any)
	module.bindLifetime = notInstalled("bindLifetime")
	module.unbindLifetime = notInstalled("unbindLifetime")
	module.canBound = notInstalled("canBound")
	module.canExecute = notInstalled("canExecute")
	-- `onDestroying(inst, fn): Connection` — the injected engine op `Effect._bindDestroying`
	-- calls (`architecture.md` EngineOps line: a hook, not a manipulation, so no
	-- composition fallback — missing means a clear error). The same backend that
	-- fills the four above fills this one; until then, the same loud stub.
	module.onDestroying = notInstalled("onDestroying")
	-- `H-373`: the three non-composable engine ops (see header). `if nil` — a
	-- provider may already be there (same idiom as `Tag.luau`/`Attr/Key.luau`).
	if module.isInst == nil then
		module.isInst = notInstalled("isInst")
	end
	if module.nativeClaim == nil then
		module.nativeClaim = notInstalled("nativeClaim")
	end
	if module.nativeFindChild == nil then
		module.nativeFindChild = notInstalled("nativeFindChild")
	end
end

return Init
