--[[
	quad-roblox LifetimeHandle — the real implementation of the lifetime
	primitives (`bindLifetime`/`unbindLifetime`/`canBound`/`canExecute`) plus
	the injected op `nativeClaim(inst)`.

	Canonical source: `.claude/base/lifecycle-pattern.md` (0)/(1)/(3) — this
	file transcribes those sketches onto real Roblox Instances. The mock
	backend (`quad-base/test/mock.luau` `installLifetime`) is the same shape;
	the deliberate divergences are exactly two:
	  1. claim is NOT lazy here — `nativeClaim(inst)` runs once at Instance
	     creation (`New` step ②) or `Claim` time. Lazy claim at bind time
	     would reopen the userdata-identity hole the (0) section exists to
	     close (measured: an unclaimed inst's userdata is collected within
	     one GC cycle even while alive in the tree —
	     `.claude/audit/spike10-full-run-2026-09-01.md` A-6).
	  2. therefore `bindLifetime` on an unclaimed inst is an error here
	     (round14 `H-290`) — the mock lazily claims instead because mock
	     instances are created outside quad.

	`nativeClaim` lives in this file (not EngineOps.luau) because the
	gcconn/gchold path shares `InstData` with `isBoundAlive` — the user
	confirmed the whole path belongs to the op ("gchold/gcconn 경로를 여기에
	전부", claim-plan §7-9). The op *inventory* source stays the
	`architecture.md` EngineOps line.

	Relate comes from the module instance (`quad.Relate` — pure-Lua leaf
	re-exported by quad-base) so this package needs no runtime quad-base
	dependency (round14 Q3 (a)).
]]

local QuadTypes = require("../luau_packages/quad_types")
local SURFACE = QuadTypes.ERROR_LEVEL_SURFACE

local function install(quad: any)
	local Err = quad.errorNamespace
	local Relate = quad.Relate
	local isObserver, isEffect = quad.isObserver, quad.isEffect

	local InstData = Relate() -- inst  -> gchold/gcconn (nativeClaim fills)
	local BindData = Relate() -- value -> gchold/gcconn (bindLifetime fills)

	-- `false or`: keep the local from being constant-folded/inlined, which
	-- would drop the closure's upvalue captures (lifecycle-pattern (0)).
	local nop = (false or function(...: any) end) :: (...any) -> ()

	-- (0) — gcconn/gchold setup, exactly once per quad-owned Instance.
	-- The closure must capture BOTH gchold and inst: the engine keeps the
	-- connected callback alive, which pins the userdata (identity fix).
	local function nativeClaim(inst: any)
		-- `H-293` (기각·UB 확정, 사용자): claiming an ALREADY-DESTROYED inst is
		-- UB — no guard on purpose. Measured on-device: Connect on a destroyed
		-- Instance succeeds and stays Connected forever (zombie binding +
		-- unbreakable capture). Any guard would break legitimate parentless
		-- claims (`:Clone()` results have no Parent) and quad's ownership
		-- concept starts at *creation* — feeding a destroyed object is not an
		-- intended input, and "방어하지 못할 부분을 방어하려고 애매한 방법을
		-- 택할 이유가 없다". Documented in claim-plan §7-13.
		if InstData:GetWeak(inst, "gchold") ~= nil then
			-- double claim: same inst passed to `Claim` twice, or claiming an
			-- inst `New` made — judged by setup presence alone (claim-plan §7-10).
			-- errorBefore (outermost) so the blame lands on the user's line even
			-- when the call arrives via `Claim`'s DFS (`H-272` precedent)
			Err.errorBefore("nativeClaim: Instance is already claimed by quad", SURFACE)
		end
		local gchold: { [any]: any } = {}
		local gcconn = inst:GetPropertyChangedSignal("ClassName"):Connect(function()
			nop(gchold, inst) -- never fires; the capture is the point
		end)
		gchold[1] = gcconn -- array slot 1 is reserved for gcconn (values go in hash part)
		InstData:SetWeak(inst, "gchold", gchold)
		InstData:SetWeak(inst, "gcconn", gcconn)
	end

	-- (1) private predicate shared by both public entry points ((3))
	local function isBoundAlive(value: any): boolean
		-- (a) inst-scoped path: the gcconn copy bindLifetime left on the value
		local gcconn = BindData:GetWeak(value, "gcconn")
		if gcconn ~= nil and gcconn.Connected then
			return true
		end
		-- (b) global subscription path (strong or weak) — Observer/Effect only
		if isObserver(value) or isEffect(value) then
			return value.Subscribed == true
		end
		return false
	end

	local function canBound(value: any): boolean
		return not isBoundAlive(value)
	end

	local function canExecute(value: any): boolean
		return isBoundAlive(value)
	end

	local function bindLifetime(inst: any, value: any)
		local gchold = InstData:GetWeak(inst, "gchold")
		if gchold == nil then
			-- `H-290`: consequence of (0) — every quad-owned Instance is claimed
			-- at creation, so an unclaimed inst here means the caller handed us
			-- an Instance quad does not own. Lazy-claiming would reopen the
			-- userdata-identity hole, so fail fast instead.
			Err.errorBefore("bindLifetime: Instance is not claimed by quad (create it via quad, or Claim it first)", SURFACE)
		end
		if not canBound(value) then
			-- Only report which path holds the value. Never index `.Subscribed`
			-- unconditionally — value may be a plain closure.
			local isGlobal = isObserver(value) or isEffect(value)
			if isGlobal then
				isGlobal = value.Subscribed == true
			end
			Err.errorBefore(
				if isGlobal
					then "bindLifetime: value is already subscribed"
					else "bindLifetime: value is already bound to another Instance",
				SURFACE
			)
		end
		-- `H-184`: ask the value's own hook guard BEFORE committing bookkeeping —
		-- if it throws we must not leave a half-bound handle behind.
		if type(value) == "table" and (value :: any)._assertBindable ~= nil then
			(value :: any):_assertBindable()
		end

		gchold[value] = true -- strong ref: value lives at least as long as inst (contract 1)
		-- the value carries its own liveness evidence (contract 2); both weak —
		-- gchold is kept alive by the (0) closure, gcconn by gchold[1]
		BindData:SetWeak(value, "gchold", gchold)
		BindData:SetWeak(value, "gcconn", InstData:GetWeak(inst, "gcconn"))

		if isObserver(value) then
			value:_catchUp() -- `H-159`: one catch-up for emits held before binding
		end
		if isEffect(value) then
			value:_bindDestroying(inst) -- Destroying hookup + held-change catch-up
		end
	end

	local function unbindLifetime(value: any)
		-- symmetric teardown — never calls cleanup, never detaches Ref
		-- callbacks or inner Observers (lifecycle-pattern (1))
		if isEffect(value) then
			value:_unbindDestroying()
		end
		local gchold = BindData:GetWeak(value, "gchold")
		if gchold ~= nil then
			gchold[value] = nil -- O(1) early release of this one value; inst untouched
		end
		BindData:SetWeak(value, "gchold", nil)
		BindData:SetWeak(value, "gcconn", nil)
	end

	quad.bindLifetime = bindLifetime
	quad.unbindLifetime = unbindLifetime
	quad.canBound = canBound
	quad.canExecute = canExecute
	quad.nativeClaim = nativeClaim

	-- `H-238`: the backend must tag every function it installs in the shared
	-- error namespace, or errorBeforeNearest below these frames cannot find
	-- the surface and blames the wrong line.
	for _, fn in { bindLifetime, unbindLifetime, canBound, canExecute, nativeClaim } :: { any } do
		Err.setFuncLevel(fn, SURFACE)
	end
end

return install
