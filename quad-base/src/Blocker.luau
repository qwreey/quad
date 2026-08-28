--[[
	Blocker — value-based emit deferral, as a POLICY on top of `state:Gate`.
	`.claude/base/blocker-plan.md` "메커니즘 (확정)", `.claude/base/gate-plan.md`
	5번 (`blocker:Policy(emit)`), as-is.

	  Blocker() -> blocker
	  blocker:On()              -- IsBlocked = true, nothing else
	  blocker:Off()             -- IsBlocked = false FIRST, then every registered handle with emit=true
	  blocker:OffWithoutEmit()  -- same path with emit=false: the withheld batch is DISCARDED
	  blocker:IsOn() -> boolean -- thin read of `IsBlocked`
	  blocker:Policy(emit) -> onUpstreamEmit
	                            -- this blocker's gate policy as a value; registers the
	                            -- onunblock handle at THIS call (weak-key set)
	  state:Apply(blocker)      -- == state:Gate(function(emit) return blocker:Policy(emit) end)
	                            -- via the method-form `__apply` (`H-158`; old `state:Block` is gone)

	Ownership (`H-63`): the handle set is weak-key; the strong owner of a handle
	is the `onUpstreamEmit` closure the policy returns (upvalue), so a handle
	lives exactly as long as its GateNode. A Blocker holding handles strongly
	was rejected — it would pin every gated state and its upstream chain.
	`Off`/`OffWithoutEmit` snapshot the set before walking (a flush can create
	new gates mid-walk). `IsBlocked` is a plain boolean — nesting the same
	Blocker is deliberately unsupported; make a new one per overlapping batch.
	"HasBlockedEmit" has no field here: it IS `next(gate._withheld) ~= nil`, and
	the gate's `emit(commit) -> boolean` is the only channel to it.

	Dependency-free leaf (`Brand` only) — it never touches lifetime gates, so it
	is shared across quad instances like `Ref`.
]]

local Brand = require("./Brand")
local QuadTypes = require("../roblox_packages/quad_types")

export type Blocker = QuadTypes.Blocker

local BlockerBrand = Brand.BlockerBrand

local WEAK_KEY_MT = { __mode = "k" }

local BlockerImpl = {}
BlockerImpl.__index = BlockerImpl

function BlockerImpl.IsOn(self: any): boolean
	return self.IsBlocked
end

function BlockerImpl.On(self: any): any
	self.IsBlocked = true
	return self
end

-- Shared by Off/OffWithoutEmit — the only difference is the flag passed on.
local function runHandles(self: any, doEmit: boolean)
	local snapshot: { (boolean) -> () } = {}
	for handle in pairs(self._handles) do -- `H-63` (3): snapshot, then walk
		snapshot[#snapshot + 1] = handle
	end
	for _, handle in ipairs(snapshot) do
		handle(doEmit)
	end
end

function BlockerImpl.Off(self: any): any
	self.IsBlocked = false -- first, so a flush that re-enters sees the blocker open
	runHandles(self, true)
	return self
end

function BlockerImpl.OffWithoutEmit(self: any): any
	self.IsBlocked = false
	runHandles(self, false)
	return self
end

-- The gate policy, as a value. `emit` is the gate's flush: `emit()` propagates
-- the withheld batch, `emit(false)` discards it, both no-ops on an empty batch
-- (so the handle is idempotent for free — gate-plan 8번).
function BlockerImpl.Policy(self: any, emit: (boolean?) -> boolean): () -> ()
	local function handle(doEmit: boolean)
		if doEmit then
			emit()
		else
			emit(false)
		end
	end
	self._handles[handle] = true -- `H-63` (1): weak-key set
	return function() -- onUpstreamEmit — `H-63` (2): THIS closure is the handle's strong owner
		if self.IsBlocked then
			return -- the gate already put the source into its withheld set; nothing to do
		end
		handle(true) -- open: pass through — going through `handle` is what keeps it alive (upvalue)
	end
end

-- Applicative factory, method form (`H-158`): `state:Apply(blocker)`.
function BlockerImpl.__apply(self: any, state: any): any
	return state:Gate(function(emit)
		return self:Policy(emit)
	end)
end

local function Blocker(): Blocker
	local self = setmetatable({
		IsBlocked = false,
		_handles = setmetatable({}, WEAK_KEY_MT),
	}, BlockerImpl)
	BlockerBrand:register(self)
	return (self :: any) :: Blocker
end

return Blocker
