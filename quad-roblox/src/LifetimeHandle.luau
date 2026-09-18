--!strict
--[[
	quad-roblox LifetimeHandle — the instance side of the lifetime primitives:
	the four hold ops (`holdLifetime`/`releaseLifetime`/`isHeld`/`isHeldBy`) plus
	the injected ops `nativeClaim(inst)`/`isClaimed(inst)`.
	[2026-09-18 round11 Q59] `bindLifetime`/`unbindLifetime`/`canBound`/`canExecute`
	themselves are quad-base's (`quad-base/src/LifetimeHandle.luau`) — a backend
	no longer transcribes them; it only answers "hold this value on that
	Instance / let go / is it still held / held by this one?".

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
	  2. therefore `holdLifetime` on an unclaimed inst is an error here
	     (round14 `H-290`, message still says `bindLifetime:` — that is the
	     primitive the user called) — the mock lazily claims instead because
	     mock instances are created outside quad.

	`nativeClaim` lives in this file (not EngineOps.luau) because the
	gcconn/gchold path shares `InstData` with `isHeld`/`holdLifetime` — the user
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

	local InstData = Relate() -- inst  -> gchold/gcconn (nativeClaim fills)
	local BindData = Relate() -- value -> gchold/gcconn (holdLifetime fills)

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

	-- [2026-09-16 사용자 결정] claim 여부 — `nativeClaim`이 남기는 셋업(gchold) 유무 그대로(이중 claim 판정과 같은 검사).
	-- Slot이 요소를 받을 때 부른다(`Slot/Elements.luau`); ~~파괴된 인스턴스도 셋업이 남아 있으면 참~~ → round11 `H-548`: 파괴되면
	-- 즉시 거짓(gcconn 끊김 — 아래 주석). 파괴된 인스턴스를 넣는 것 자체는 `H-293` UB 그대로.
	local function isClaimed(inst: any): boolean
		if inst == nil then
			return false
		end
		-- round11 `H-548` (탐사 D′): gchold/gcconn are weak values anchored by the gcconn closure, which
		-- Destroy cuts — so a destroyed Instance read as claimed until the next GC and as not claimed
		-- after it (`Slot:Add(corpse)` passed and seated it before the GC, threw after). `H-293` makes
		-- feeding a destroyed Instance UB, but the gate should not depend on GC pacing: a cut gcconn
		-- is "not claimed" right away (the two gate messages now say a destroyed Instance counts as such).
		-- NOT applied to `nativeClaim`'s double-claim check above nor to `holdLifetime`'s gate: a
		-- corpse re-claimed pre-GC would get a fresh gcconn that never fires and read as alive forever.
		local gcconn = InstData:GetWeak(inst, "gcconn")
		return InstData:GetWeak(inst, "gchold") ~= nil and gcconn ~= nil and gcconn.Connected == true
	end

	-- ── the four hold ops (round11 Q59, 2026-09-18) — the only lifetime code a backend owns ──
	-- quad-base composes `bindLifetime`/`unbindLifetime`/`canBound`/`canExecute` on top of
	-- these (`quad-base/src/LifetimeHandle.luau`): the nil gates, the refusal messages, the
	-- Observer/Effect hooks and the `.Subscribed` arm live there. Here: gchold/gcconn only.

	-- `isHeld(value)` — (a) inst-scoped liveness: the gcconn copy holdLifetime left on the
	-- value. inst destroyed → Connected false at once; GC clears the weak entry later.
	local function isHeld(value: any): boolean
		if value == nil then
			return false -- round3 `H-444` (G-14): a nil key died in Relate
		end
		local gcconn = BindData:GetWeak(value, "gcconn")
		return gcconn ~= nil and gcconn.Connected == true
	end

	-- `isHeldBy(value, inst)` — 5순회 `H-395`: is it THIS Instance's holder? (one message arm)
	local function isHeldBy(value: any, inst: any): boolean
		if value == nil or inst == nil then
			return false
		end
		local held = BindData:GetWeak(value, "gchold")
		return held ~= nil and held == InstData:GetWeak(inst, "gchold")
	end

	-- `holdLifetime(inst, value)` — the commit. Called by base AFTER its gates (nil, canBound,
	-- `_assertBindable`) and BEFORE the value's post-commit hooks.
	local function holdLifetime(inst: any, value: any)
		local gchold = InstData:GetWeak(inst, "gchold")
		if gchold == nil then
			-- `H-290`: consequence of (0) — every quad-owned Instance is claimed
			-- at creation, so an unclaimed inst here means the caller handed us
			-- an Instance quad does not own. Lazy-claiming would reopen the
			-- userdata-identity hole, so fail fast instead.
			-- round1 Q20 (사용자 확정 2026-09-07): a destroyed quad Instance and a foreign one look the
			-- same here (Parent is nil at creation and right after Clone, so no ancestry test can tell
			-- them apart — tried and retracted earlier); one message names both.
			-- NOT `isClaimed`'s cut-gcconn test (`H-548` note above): a corpse re-claimed pre-GC would
			-- get a fresh gcconn that never fires and read as alive forever.
			Err.errorBefore("bindLifetime: Instance is not claimed by quad — it was not created or claimed through quad, or it has already been destroyed (a destroyed Instance cannot be reused)", SURFACE)
		end
		gchold[value] = true -- strong ref: value lives at least as long as inst (contract 1)
		-- the value carries its own liveness evidence (contract 2); both weak —
		-- gchold is kept alive by the (0) closure, gcconn by gchold[1]
		BindData:SetWeak(value, "gchold", gchold)
		BindData:SetWeak(value, "gcconn", InstData:GetWeak(inst, "gcconn"))
	end

	-- `releaseLifetime(value)` — the reverse; no-op when not held, inst untouched.
	local function releaseLifetime(value: any)
		local gchold = BindData:GetWeak(value, "gchold")
		if gchold ~= nil then
			gchold[value] = nil -- O(1) early release of this one value
		end
		BindData:SetWeak(value, "gchold", nil)
		BindData:SetWeak(value, "gcconn", nil)
	end

	quad.Backend.holdLifetime = holdLifetime
	quad.Backend.releaseLifetime = releaseLifetime
	quad.Backend.isHeld = isHeld
	quad.Backend.isHeldBy = isHeldBy
	quad.Backend.nativeClaim = nativeClaim
	quad.Backend.isClaimed = isClaimed

	-- `H-238`: the backend must tag every function it installs in the shared
	-- error namespace, or errorBeforeNearest below these frames cannot find
	-- the surface and blames the wrong line.
	Err.setFuncLevel(SURFACE, holdLifetime, releaseLifetime, isHeld, isHeldBy, nativeClaim, isClaimed)
end

return install
