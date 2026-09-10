--!strict
--[[
	Relate — inst를 weak 키로 하는 범용 릴레이션 프리미티브.
	`.claude/base/relate-plan.md` "API"/"실제 구조" 절 그대로 구현.
]]

local QuadTypes = require("../luau_packages/quad_types")

-- 타입의 소스는 `quad-types`(`Quad.Relate` 필드가 같은 타입을 써야 함) — 여기선 재export만.
export type Relate = QuadTypes.Relate

type Bucket = {
	StrongMap: { [any]: any }?,
	WeakMap: { [any]: any }?,
}

-- 모든 WeakMap이 공유하는 단일 메타테이블 — 매번 새로 만들 이유가 없음
local WEAK_VALUE_MT = { __mode = "v" }

local RelateImpl = {}
RelateImpl.__index = RelateImpl

-- `H-499` (2026-09-08 2차 감사 I-6): the one public surface without tags — a nil inst/key
-- died as `table index is nil` on a Relate.luau line. Relate is a dependency-free leaf
-- (architecture "잎 모듈"), so no quad-error tag: a plain level-2 error blames the caller,
-- which is the user's line for direct use and an already-gated quad frame otherwise.
local function checkArgs(method: string, inst: any, key: any)
	if inst == nil then error(`Relate:{method}: inst must not be nil`, 3) end
	error(`Relate:{method}: key must not be nil`, 3)
end

local function getBucket(self, inst: any): Bucket?
	return self.buckets[inst]
end

local function getOrCreateBucket(self, inst: any): Bucket
	local bucket = self.buckets[inst]
	if bucket == nil then
		bucket = {} :: Bucket
		self.buckets[inst] = bucket
	end
	return bucket
end

function RelateImpl:SetStrong(inst: any, key: any, value: any)
	if inst == nil or key == nil then checkArgs("SetStrong", inst, key) end
	local bucket = getOrCreateBucket(self, inst)
	local strongMap = bucket.StrongMap
	if strongMap == nil then
		local newMap = {}
		bucket.StrongMap = newMap
		newMap[key] = value
		return
	end
	strongMap[key] = value
end

function RelateImpl:GetStrong(inst: any, key: any): any?
	if inst == nil or key == nil then checkArgs("GetStrong", inst, key) end
	local bucket = getBucket(self, inst)
	if bucket == nil then
		return nil
	end
	local strongMap = bucket.StrongMap
	if strongMap == nil then
		return nil
	end
	return strongMap[key]
end

function RelateImpl:SetWeak(inst: any, key: any, value: any)
	if inst == nil or key == nil then checkArgs("SetWeak", inst, key) end
	local bucket = getOrCreateBucket(self, inst)
	local weakMap = bucket.WeakMap
	if weakMap == nil then
		-- `:: any` detour: the metatable-carrying type `{ @metatable WEAK_VALUE_MT, {} }`
		-- is not a subtype of the plain indexer `Bucket.WeakMap` expects (`H-211`).
		local newMap: { [any]: any } = setmetatable({}, WEAK_VALUE_MT) :: any
		bucket.WeakMap = newMap
		newMap[key] = value
		return
	end
	weakMap[key] = value
end

function RelateImpl:GetWeak(inst: any, key: any): any?
	if inst == nil or key == nil then checkArgs("GetWeak", inst, key) end
	local bucket = getBucket(self, inst)
	if bucket == nil then
		return nil
	end
	local weakMap = bucket.WeakMap
	if weakMap == nil then
		return nil
	end
	return weakMap[key]
end

local function Relate(): Relate
	local self = setmetatable({
		buckets = setmetatable({}, { __mode = "k" }) :: { [any]: Bucket },
	}, RelateImpl)
	return (self :: any) :: Relate
end

return Relate
