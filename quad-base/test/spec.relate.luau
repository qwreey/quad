--[[ Relate 계약 — `.claude/base/relate-plan.md` "API (확정)" / "실제 구조 (확정, 2026-08-08 세션)" ]]

local Relate = require("../src/Relate")
local Quad = require("../src")

-- strict 모드에서 `collectgarbage`는 선언 안 된 전역 — 표준 luau CLI엔 있다(Roblox엔 없음)
local collectgarbage = (_G :: any).collectgarbage :: () -> ()
print("=== 1. 네 메서드 — Strong/Weak는 서로 다른 슬롯, 같은 키라도 안 섞임 ===")
do
	local r = Relate()
	local inst = {}
	r:SetStrong(inst, "k", 1)
	r:SetWeak(inst, "k", {})
	assert(r:GetStrong(inst, "k") == 1, "GetStrong reads what SetStrong wrote")
	assert(type(r:GetWeak(inst, "k")) == "table", "GetWeak reads what SetWeak wrote")
	assert(r:GetStrong(inst, "missing") == nil and r:GetWeak(inst, "missing") == nil, "unknown key is nil")
	assert(r:GetStrong({}, "k") == nil and r:GetWeak({}, "k") == nil, "unknown inst is nil")
	assert(Quad.Relate == Relate, "Relate must be re-exported on Quad")
	print("PASS")
end

print()
print("=== 2. lazy 서브테이블 — 읽기는 쓰기를 유발하지 않음, Set이 처음 불릴 때만 생성 ===")
do
	local r = Relate()
	local inst = {}
	local buckets = (r :: any).buckets
	assert(r:GetStrong(inst, "k") == nil, "read on fresh relate")
	assert(buckets[inst] == nil, "a read must not create the bucket")
	r:SetStrong(inst, "k", true)
	assert(buckets[inst] ~= nil and buckets[inst].StrongMap ~= nil, "SetStrong creates bucket + StrongMap")
	assert(buckets[inst].WeakMap == nil, "WeakMap stays unmade until SetWeak")
	r:SetWeak(inst, "w", {})
	assert(buckets[inst].WeakMap ~= nil, "SetWeak creates WeakMap")
	print("PASS")
end

print()
print("=== 3. 공유 메타테이블 — 모든 WeakMap이 같은 {__mode='v'} 객체 ===")
do
	local r = Relate()
	local a, b = {}, {}
	r:SetWeak(a, "k", {})
	r:SetWeak(b, "k", {})
	local buckets = (r :: any).buckets
	local mtA, mtB = getmetatable(buckets[a].WeakMap), getmetatable(buckets[b].WeakMap)
	assert(mtA ~= nil and mtA == mtB, "WeakMap metatable is shared")
	assert(mtA.__mode == "v", "WeakMap is weak-valued")
	assert(getmetatable(buckets[a].StrongMap) == nil, "StrongMap has no metatable")
	print("PASS")
end

print()
print("=== 4. Weak 값은 다른 곳에서 안 잡으면 GC됨, Strong 값은 살아남음 ===")
do
	local r = Relate()
	local inst = {}
	do
		r:SetWeak(inst, "w", {})
		r:SetStrong(inst, "s", {})
	end
	collectgarbage()
	collectgarbage()
	assert(r:GetWeak(inst, "w") == nil, "weakly held value is collected")
	assert(r:GetStrong(inst, "s") ~= nil, "strongly held value survives")
	print("PASS")
end

print()
print("=== 5. inst는 항상 weak — inst를 놓으면 버킷째 사라짐 ===")
do
	local r = Relate()
	local buckets = (r :: any).buckets
	do
		local inst = {}
		r:SetStrong(inst, "s", {})
	end
	collectgarbage()
	collectgarbage()
	assert(next(buckets) == nil, "bucket keyed by a dead inst must be collected")
	print("PASS")
end

print()
print("=== 6. 비싱글톤 — 인스턴스마다 독립 ===")
do
	local a, b = Relate(), Relate()
	local inst = {}
	a:SetStrong(inst, "k", 1)
	assert(b:GetStrong(inst, "k") == nil, "separate Relate instances do not share buckets")
	print("PASS")
end

print()
print()
print("=== 7. 2026-09-08 2차 감사 H-499 — nil inst/key는 호출 줄을 blame하는 표면 에러(옛: Relate.luau 'table index is nil') ===")
do
	local r = Relate()
	for _, m in { "SetStrong", "SetWeak", "GetStrong", "GetWeak" } do
		local ok, err = pcall(function() return (r :: any)[m](r, nil, "k", 1) end)
		assert(not ok and string.find(tostring(err), `Relate:{m}: inst must not be nil`, 1, true) ~= nil, m .. " inst: " .. tostring(err))
		assert(string.find(tostring(err), "spec.relate.luau", 1, true) ~= nil and string.find(tostring(err), "/src/", 1, true) == nil, m .. " blames this file: " .. tostring(err))
		local ok2, err2 = pcall(function() return (r :: any)[m](r, {}, nil, 1) end)
		assert(not ok2 and string.find(tostring(err2), `Relate:{m}: key must not be nil`, 1, true) ~= nil, m .. " key: " .. tostring(err2))
	end
	-- Dispatch.getBlocker(nil) sibling gate (H-447 family)
	local q = Quad.New()
	local ok3, err3 = pcall(function() return q.Dispatch.getBlocker(nil) end)
	assert(not ok3 and string.find(tostring(err3), "Dispatch.getBlocker: ownerKey must not be nil", 1, true) ~= nil, "getBlocker nil: " .. tostring(err3))
	assert(string.find(tostring(err3), "/src/", 1, true) == nil, "getBlocker blames user: " .. tostring(err3))
	-- `H-504` (round8 K-2): the sibling public surfaces too — no leaf-module name (`Relate:`) in the message
	local cases: { { any } } = { { "getBookkeeping", 1 }, { "getOffsetAt", 1 }, { "setLength", 1, 1 }, { "setOffsetSource", 1, q.None }, { "setEmpty", 1 } }
	for _, c in cases do
		local name = c[1] :: string
		local okN, errN = pcall(function() return (q.Dispatch :: any)[name](nil, c[2], c[3]) end)
		assert(not okN and string.find(tostring(errN), `Dispatch.{name}: ownerKey must not be nil`, 1, true) ~= nil, name .. ": " .. tostring(errN))
		assert(string.find(tostring(errN), "/src/", 1, true) == nil and string.find(tostring(errN), "Relate:", 1, true) == nil, name .. " blames user: " .. tostring(errN))
	end
	for _, name in { "process", "retractFrom" } do
		local okP, errP = pcall(function() return (q.Dispatch :: any)[name](nil, "k", 1, 1) end)
		assert(not okP and string.find(tostring(errP), `Dispatch.{name}: inst must not be nil`, 1, true) ~= nil, name .. ": " .. tostring(errP))
		assert(string.find(tostring(errP), "/src/", 1, true) == nil, name .. " blames user: " .. tostring(errP))
	end
	print("PASS")
end

print("=== ALL PASS ===")
