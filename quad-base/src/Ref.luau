--[[
	Ref — general value box. Minimal M2 form (`ROADMAP.md` M2 "공통 기반",
	9라운드 `H-128`): `.Value` / `.Revision` / `:Set` / `:Callback` /
	`:WeakCallback` / `:Uncallback` + `isRef`, and `EpochBrand` membership.
	`:Wait`, `PreRef`/`PostRef` and the dispatch handlers stay in M8.

	Sources, as-is:
	  - `.claude/base/ref-plan.md` "API 모양" (surface, self-returning
	    mutations, "already filled → call once on registration"),
	    "`.Callbacks`는 배열이 아니라" (dedup contract, snapshot before
	    iterating), "`:WeakCallback(fn)`" (weak-key table `.WeakCallbacks`,
	    Weak is the primitive and `:Callback` only adds the GC keep),
	    "`:Set(value)`의 순서" (value → revision → callbacks; the code below
	    is that block), "`Ref`는 `Epoch`를 만족한다" (`.Revision`, brand).
	  - `.claude/base/state-epoch-plan.md` §2: revision bump is the uint32
	    wrap-around decrement `bit32.bnot(-rev)`; only `==`/`~=` are contract.

	Single type parameter, `Ref<T>(T) -> Ref<T>` (`ref-plan.md` "제네릭
	시그니처"): a nil-able slot is widened by the caller, `Ref<<T?>>(nil)`.

	Callback signature is `fn(value, ref)` — the second argument is the Ref
	itself, i.e. the `Epoch` a consumer (`Effect`) feeds to `EpochMap:Update`.
	Plain user callbacks just ignore it.

	`Ref` is NOT a State: no emit propagation, no `Get`/`Compute`. Being an
	`Epoch` only means "carries a mark distinguishable from the previous one".
]]

local Brand = require("./Brand")
local QuadTypes = require("../roblox_packages/quad_types")

export type Ref<T> = QuadTypes.Ref<T>
type Callback<T> = QuadTypes.RefCallback<T>

local RefBrand = Brand.RefBrand
local EpochBrand = Brand.EpochBrand

local WEAK_KEY_MT = { __mode = "k" }

local RefImpl = {}
RefImpl.__index = RefImpl

function RefImpl.Set<T>(self: Ref<T>, value: T): Ref<T>
	self.Value = value -- (1) settle the value first
	self.Revision = bit32.bnot(-self.Revision) -- (2) before callbacks (`H-108`)

	-- (3) snapshot before iterating (`H-23`): registering/unregistering during
	-- the walk must not disturb the iteration. `H-208` (user, 2026-08-31):
	-- `table.clone` + set-merge — cheaper than rebuilding an array, and the
	-- strong plain clone keeps weak-registered callbacks alive for the walk.
	-- Both-table dedup is free (set semantics); `:Wait()` (M8) puts its thread
	-- waiters in `.Callbacks` only, so draining below stays right.
	local callbacks = self.Callbacks
	local weakCallbacks = self.WeakCallbacks
	local snapshot: { [any]: true } = table.clone(callbacks)
	for k in weakCallbacks do
		snapshot[k] = true
	end
	local revision = self.Revision
	for k in snapshot do
		if self.Revision ~= revision then
			-- [`H-169`, user-confirmed 2026-08-28] a callback re-entered `:Set`: that
			-- inner walk already delivered the newer value to everyone, so this
			-- walk drops the rest — a callback never receives a stale value.
			break
		end
		if callbacks[k] == nil and weakCallbacks[k] == nil then
			continue -- released while we were walking
		end
		if type(k) == "thread" then
			callbacks[k] = nil -- waiters are consumed
			-- the Ref itself, not the value. [`H-170`, user-confirmed] `resume` never
			-- raises; the immediately returned failure is re-raised here (a later
			-- yield's fate is out of our hands), per the "no pcall" contract.
			local ok, err = coroutine.resume(k, self)
			if not ok then
				error(err, 0)
			end
		else
			-- value + the Ref itself (= `Epoch`). The cast only quiets the checker:
			-- `k` comes from a `{ any }` snapshot and the `thread` branch is above.
			(k :: Callback<T>)(value, self)
		end
	end
	return self
end

-- "Weak" is the primitive: same behaviour, same guards, only the GC keep
-- removed. Registration calls the callback once right away with whatever
-- is there — nil/unset included (`H-120`; the nil guard is the caller's,
-- `base/lifecycle-hooks-plan.md`).
function RefImpl.WeakCallback<T>(self: Ref<T>, fn: Callback<T>): Ref<T>
	self.WeakCallbacks[fn] = true
	fn(self.Value, self)
	return self
end

function RefImpl.Callback<T>(self: Ref<T>, fn: Callback<T>): Ref<T>
	self.Callbacks[fn] = true -- the strong keep, on top of the weak primitive
	fn(self.Value, self)
	return self
end

-- Detaches a user-registered callback. Both tables — a weakly registered
-- callback is otherwise impossible to remove and keeps firing.
-- Dedup on registration means there is never a "how many times" question.
function RefImpl.Uncallback<T>(self: Ref<T>, fn: Callback<T>): Ref<T>
	self.Callbacks[fn] = nil
	self.WeakCallbacks[fn] = nil
	return self
end

local function Ref<T>(default: T): Ref<T>
	local self = setmetatable({
		Value = default,
		Revision = 0,
		Callbacks = {},
		WeakCallbacks = setmetatable({}, WEAK_KEY_MT),
	}, RefImpl)
	RefBrand:register(self)
	EpochBrand:register(self) -- multi-tagging: a Ref is also an Epoch
	return (self :: any) :: Ref<T>
end

return Ref
