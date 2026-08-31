--[[
	Dispatch.drive — M3 unit-1 scope: pipeline stage (b) only, the single
	generalized `for` (`.claude/base/bind-system-plan.md` "`New(name)(props)`
	파이프라인 의사코드"; scope cut: round12 brief §6).

	This spec measures the *language behavior* the contract leans on (`F-4-1`):
	a generalized `for` over a plain Luau table gives the whole array part
	before the hash part, and the array part in index order. That is the exact
	question the retired spike `01` (luau-test/rewrite-required) was due to
	ask — this spec replaces it as a standing regression (round12 brief §6).
]]

local Quad = require("../src")
local QuadTypes = require("../roblox_packages/quad_types")
local mock = require("./mock")

local q = Quad.New()
mock.installLifetime(q) -- `H-229`: 체인 앵커가 bindLifetime을 부른다
local Instance = mock.Instance
local log: { string } = {}
q.Dispatch.addHandler({
	isHandlable = function(_inst: any, _k: any, _v: any): boolean
		return true
	end,
	priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
	process = function(_inst: any, k: any, v: any, index: number): (any?) -> ()
		table.insert(log, `{tostring(k)}={tostring(v)}@{index}`)
		return Quad.Void
	end,
} :: QuadTypes.Handler)

print("=== 1. 배열 파트 전체가 해시 파트보다 먼저 + 배열 안에서는 index 순서 ===")
do
	table.clear(log)
	local flattened: { [any]: any } =
		{ "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8", "a9", "a10", Size = "s", Text = "t", Name = "n" }
	q.Dispatch.drive(Instance.new("Frame"), flattened)
	assert(#log == 13, `13 entries processed, got {#log}`)
	for i = 1, 10 do
		assert(log[i] == `{i}=a{i}@1`, `array slot {i} in index order before any hash key, got "{log[i]}"`)
	end
	local hashSeen: { [string]: boolean } = {}
	for i = 11, 13 do
		hashSeen[log[i]] = true
	end
	assert(hashSeen["Size=s@1"] and hashSeen["Text=t@1"] and hashSeen["Name=n@1"], "all hash keys after the array part")
	print("PASS")
end

print()
print("=== 2. 모든 진입은 체인 인덱스 1 ===")
do
	for _, entry in log do
		assert(string.sub(entry, -2) == "@1", `drive enters every chain at index 1, got "{entry}"`)
	end
	print("PASS")
end

print()
print("=== 3. 빈 props — no-op (아무 핸들러도 안 불림) ===")
do
	table.clear(log)
	q.Dispatch.drive(Instance.new("Frame"), {})
	assert(#log == 0, "empty flattened processes nothing")
	print("PASS")
end

print()
print("=== ALL PASS ===")
