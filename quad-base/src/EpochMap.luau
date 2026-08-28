--[[
	EpochMap — reusable epoch bookkeeping object.
	`.claude/base/state-epoch-plan.md` §3 "`EpochMap` — 컴포지션 가능한 부기 객체",
	as-is. `State` composes two of these (`valueEpochMap` / `emitEpochMap`),
	`GateNode` and `Effect` use the same object (§6) — so it lives in its own
	leaf module, not inside `State.luau`.

	  EpochMap:Update(Epoch | EpochSet) -> boolean  -- "does this need to propagate?"
	                                                --   read, compare, overwrite; true if any differed
	  EpochMap:Peek(Epoch | EpochSet) -> boolean    -- same comparison, no write (`H-72`)
	  EpochMap:Refresh() -> boolean                 -- re-read every key it already tracks (= Update with no args)
	  EpochMap:Sync(Epoch | EpochSet)               -- write only, no read, no return
	  EpochMap:TrackFrom(other: EpochMap)           -- take over other's keys, filled with LIVE revisions
	                                                --   (not other's stored values; other is untouched)

	`EpochSet = {[Epoch]: true}` is a SET, not an array — a gate batch is
	exactly the swapped-out `withheld` table (`base/gate-plan.md` 4번), and
	iterating it with `ipairs` would see zero elements. Single-vs-set is
	decided at runtime with `isEpoch` (§5 "런타임 분기는 `isEpoch`로").

	Keys are weak: when an `Epoch` dies its entry goes with it. Values are
	plain numbers, so `relate-plan.md`'s "value must not refer back to the
	key" caveat does not apply.
]]

local Brand = require("./Brand")
local QuadTypes = require("../roblox_packages/quad_types")

type Epoch = QuadTypes.Epoch
export type EpochSet = { [Epoch]: true }
export type EpochMap = {
	Update: (self: EpochMap, from: Epoch | EpochSet) -> boolean,
	Peek: (self: EpochMap, from: Epoch | EpochSet) -> boolean,
	Refresh: (self: EpochMap) -> boolean,
	Sync: (self: EpochMap, from: Epoch | EpochSet) -> (),
	TrackFrom: (self: EpochMap, other: EpochMap) -> (),
}

local isEpoch = Brand.isEpoch

local WEAK_KEY_MT = { __mode = "k" }

local EpochMapImpl = {}
EpochMapImpl.__index = EpochMapImpl

-- Read-compare-write over one epoch. Returns whether it differed. Once a
-- caller already knows the answer is `true` it can keep writing without
-- reading (the "내부 최적화" in §3) — `Update` below does exactly that.
local function updateOne(map: { [Epoch]: number }, epoch: Epoch): boolean
	local revision = epoch.Revision
	if map[epoch] ~= revision then
		map[epoch] = revision
		return true
	end
	return false
end

function EpochMapImpl.Update(self: EpochMap, from: Epoch | EpochSet): boolean
	local map = (self :: any)._map
	if isEpoch(from) then
		return updateOne(map, from :: Epoch)
	end
	local changed = false
	for epoch in pairs(from :: EpochSet) do
		if changed then
			map[epoch] = epoch.Revision -- answer already fixed: write only
		else
			changed = updateOne(map, epoch)
		end
	end
	return changed
end

function EpochMapImpl.Peek(self: EpochMap, from: Epoch | EpochSet): boolean
	local map = (self :: any)._map
	if isEpoch(from) then
		local epoch = from :: Epoch
		return map[epoch] ~= epoch.Revision
	end
	for epoch in pairs(from :: EpochSet) do
		if map[epoch] ~= epoch.Revision then
			return true
		end
	end
	return false
end

function EpochMapImpl.Refresh(self: EpochMap): boolean
	local map = (self :: any)._map
	local changed = false
	for epoch, revision in pairs(map) do
		local live = epoch.Revision
		if live ~= revision then
			changed = true
			map[epoch] = live
		end
	end
	return changed
end

function EpochMapImpl.Sync(self: EpochMap, from: Epoch | EpochSet)
	local map = (self :: any)._map
	if isEpoch(from) then
		local epoch = from :: Epoch
		map[epoch] = epoch.Revision
		return
	end
	for epoch in pairs(from :: EpochSet) do
		map[epoch] = epoch.Revision
	end
end

function EpochMapImpl.TrackFrom(self: EpochMap, other: EpochMap)
	local map = (self :: any)._map
	for epoch in pairs((other :: any)._map) do
		map[epoch] = epoch.Revision -- live revision, not other's stored one
	end
end

local function EpochMap(): EpochMap
	local self = setmetatable({
		_map = setmetatable({}, WEAK_KEY_MT) :: { [Epoch]: number },
	}, EpochMapImpl)
	return (self :: any) :: EpochMap
end

return EpochMap
