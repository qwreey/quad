--[[
	LifetimeHandle 계약 — `.claude/base/lifecycle-pattern.md` "`bindLifetime`/`canBound`/
	`canExecute`/`unbindLifetime` — 확정" 절 + mock 백엔드(`mock.luau` installLifetime, ROADMAP `H-97`).
	Observer/Effect의 `.Subscribed` 경로는 단위 3(Observer/Effect)에서 합류.
]]

local Quad = require("../src")
local mock = require("./mock")

-- strict 모드에서 `collectgarbage`는 선언 안 된 전역 — 표준 luau CLI엔 있다(Roblox엔 없음)
local collectgarbage = (_G :: any).collectgarbage :: () -> ()
print("=== 1. 미주입 스텁 — 생명주기 넷 + 조합 불가 엔진 op 넷(onDestroying/isInst/nativeClaim/nativeFindChild, 2순회 H-373) 전부 영어 메시지로 error, 호출부를 가리킴 ===")
do
	local fresh = Quad.New()
	for _, name in { "bindLifetime", "unbindLifetime", "canBound", "canExecute", "onDestroying", "isInst", "nativeClaim", "nativeFindChild" } do
		local ok, err = pcall(function()
			return (fresh :: any)[name]({}, {})
		end)
		assert(not ok, name .. " must error before a backend is installed")
		assert(string.find(tostring(err), name, 1, true) ~= nil, name .. ": message names the slot: " .. tostring(err))
		assert(string.find(tostring(err), "not available", 1, true) ~= nil, name .. ": message is English: " .. tostring(err))
		-- level 2 = 이 파일(호출부)을 가리킨다, LifetimeHandle.luau가 아니라
		assert(string.find(tostring(err), "spec.lifetime.luau", 1, true) ~= nil, name .. ": error level must point at the caller: " .. tostring(err))
	end
	print("PASS")
end

print()
print("=== 1b. 스텁의 에러 깊이 — 여덟 전부 errorBefore(최외곽): 태그된 래퍼(핸들러 프레임 상당)를 타넘어 그 호출자를 blame (H-348, 3순회 H-378로 복원) ===")
do
	local fresh = Quad.New()
	local QuadTypes = require("../luau_packages/quad_types")
	-- a SURFACE-tagged wrapper stands in for a public method / handler frame
	local lineUser = 0
	local function viaSurface(name: string)
		return (fresh :: any)[name]({}, {})
	end
	fresh.errorNamespace.setFuncLevel(viaSurface, QuadTypes.ERROR_LEVEL_SURFACE)
	local function user(name: string)
		lineUser = (debug.info(1, "l") :: number) + 1
		return viaSurface(name)
	end
	for _, name in { "bindLifetime", "unbindLifetime", "canBound", "canExecute", "onDestroying", "isInst", "nativeClaim", "nativeFindChild" } do
		local ok, err = pcall(user, name)
		assert(not ok, name .. " stub errors")
		assert(string.find(tostring(err), `spec.lifetime.luau:{lineUser}:`, 1, true) ~= nil, name .. ": outermost — blames past the surface frame: " .. tostring(err))
	end
	-- the in-tree pattern `H-378` fixed: quad internals call `canBound`/`isInst`
	-- from inside public methods — the blame must be the user's line, not
	-- Observer.luau / Slot.luau (a stub tagged SURFACE made "nearest" = that internal line)
	local okO, errO = pcall(function()
		fresh.Source(1):Observer(function() end):Subscribe()
	end)
	assert(not okO and string.find(tostring(errO), "canBound is not available", 1, true) ~= nil, "Subscribe reaches the canBound stub: " .. tostring(errO))
	mock.assertBlamesUser(errO, "spec.lifetime.luau", "canBound via Observer:Subscribe blames the user")
	local okS, errS = pcall(function()
		fresh.Slot():Add(mock.Instance.new("Frame"))
	end)
	assert(not okS and string.find(tostring(errS), "isInst is not available", 1, true) ~= nil, "Slot:Add reaches the isInst stub: " .. tostring(errS))
	mock.assertBlamesUser(errS, "spec.lifetime.luau", "isInst via Slot:Add blames the user")
	print("PASS")
end

local quad = Quad.New()
mock.installLifetime(quad)
local Instance = mock.Instance

print()
print("=== 2. 주입 후 — bind 전엔 canBound/‖canExecute, bind 후엔 반대 ===")
do
	local inst = Instance.new("Frame")
	local value = {}
	assert(quad.canBound(value) == true and quad.canExecute(value) == false, "unbound value: may bind, may not execute")
	quad.bindLifetime(inst, value)
	assert(quad.canBound(value) == false and quad.canExecute(value) == true, "bound value: may not bind again, may execute")
	print("PASS")
end

print()
print("=== 3. Destroy → canExecute false / canBound true (gcconn.Connected 전환) ===")
do
	local inst = Instance.new("Frame")
	local value = {}
	quad.bindLifetime(inst, value)
	inst:Destroy()
	assert(quad.canExecute(value) == false, "after Destroy the value may not execute")
	assert(quad.canBound(value) == true, "after Destroy the value may be bound again")
	print("PASS")
end

print()
print("=== 4. 이중 바인딩 게이트 — `if not canBound(v) then error(...)` 모양, level 2 ===")
do
	local a, b = Instance.new("Frame"), Instance.new("Frame")
	local value = {}
	quad.bindLifetime(a, value)
	local ok, err = pcall(function()
		quad.bindLifetime(b, value)
	end)
	assert(not ok, "binding an already-bound value must error")
	assert(string.find(tostring(err), "already bound", 1, true) ~= nil, "message: " .. tostring(err))
	assert(string.find(tostring(err), "spec.lifetime.luau", 1, true) ~= nil, "blames the caller (errorBefore, H-272): " .. tostring(err))
	assert(string.find(tostring(err), "another Instance", 1, true) ~= nil, "bound to a: b is another Instance: " .. tostring(err))
	-- 같은 inst에 다시 묶는 것도 이중 바인딩 — 5순회 `H-395`: 메시지는 "this Instance"
	local okSame, errSame = pcall(function()
		quad.bindLifetime(a, value)
	end)
	assert(not okSame and string.find(tostring(errSame), "this Instance", 1, true) ~= nil, "same inst twice names THIS Instance, not another: " .. tostring(errSame))
	local ok2 = pcall(function()
		quad.bindLifetime(a, value)
	end)
	assert(not ok2, "rebinding to the same inst is also a double bind")
	print("PASS")
end

print()
print("=== 5. unbindLifetime — 특정 값 하나만 조기 해제, inst는 그대로 ===")
do
	local inst = Instance.new("Frame")
	local x, y = {}, {}
	quad.bindLifetime(inst, x)
	quad.bindLifetime(inst, y)
	quad.unbindLifetime(x)
	assert(quad.canExecute(x) == false and quad.canBound(x) == true, "x is released")
	assert(quad.canExecute(y) == true, "y is untouched")
	quad.unbindLifetime(x) -- 안 걸려있던 값에 불러도 안전한 no-op
	quad.unbindLifetime({})
	quad.bindLifetime(inst, x) -- 해제됐으니 다시 묶을 수 있음
	assert(quad.canExecute(x) == true, "x can be rebound after release")
	print("PASS")
end

print()
print("=== 6. gchold — inst가 사는 동안 value 생존 보장(계약 1), inst가 죽고 놓이면 같이 회수 ===")
do
	local inst = Instance.new("Frame")
	local weak = setmetatable({}, { __mode = "v" })
	do
		local value = {}
		quad.bindLifetime(inst, value)
		weak[1] = value
	end
	collectgarbage()
	collectgarbage()
	assert(weak[1] ~= nil, "bound value must survive while inst lives (gchold strong ref)")

	inst:Destroy()
	inst = nil :: any
	collectgarbage()
	collectgarbage()
	assert(weak[1] == nil, "after Destroy + dropping inst, the value is collectable")
	print("PASS")
end

print()
print("=== 6b. 이미 Destroy된 inst에 bind — GC 여부와 무관하게 죽은 상태로 시작 (H-171) ===")
do
	local inst = Instance.new("Frame")
	quad.bindLifetime(inst, {})
	inst:Destroy()
	local a = {}
	quad.bindLifetime(inst, a)
	assert(quad.canExecute(a) == false, "bound onto a destroyed inst: dead immediately (no GC yet)")
	collectgarbage()
	collectgarbage()
	local b = {}
	quad.bindLifetime(inst, b)
	assert(quad.canExecute(b) == false, "bound onto a destroyed inst after GC: still dead")
	print("PASS")
end

print()
print("=== 6c. 조상 Destroy — 자손에 묶인 값도 같이 죽는다 (H-172) ===")
do
	local root = Instance.new("Frame")
	local child = Instance.new("Frame")
	child.Parent = root
	local v = {}
	quad.bindLifetime(child, v)
	local parentChanges = 0
	child:GetPropertyChangedSignal("Parent"):Connect(function()
		parentChanges += 1
	end)
	root:Destroy()
	assert(child.Parent == nil, "descendant is detached")
	assert(quad.canExecute(v) == false, "value bound to a descendant dies with the ancestor")
	assert(parentChanges == 1, "Parent change is observable before connections are cut")
	root:Destroy() -- 두 번째는 no-op
	print("PASS")
end

print()
print("=== 7. 첫 인자는 mock Instance여야 함 ===")
do
	local ok, err = pcall(function()
		quad.bindLifetime({}, {})
	end)
	assert(not ok and string.find(tostring(err), "not a mock instance", 1, true) ~= nil, "non-instance first arg: " .. tostring(err))
	print("PASS")
end

print()
print("=== 8. installLifetime은 quad 인스턴스별 — 다른 New()엔 안 퍼짐, 두 번 불러도 무시 ===")
do
	local other = Quad.New()
	local ok = pcall(function()
		other.canBound({})
	end)
	assert(not ok, "another Quad instance still has the stubs")
	local before = quad.bindLifetime
	mock.installLifetime(quad)
	assert(quad.bindLifetime == before, "second install is ignored")
	print("PASS")
end

print()
print("=== 9. mock 프로바이더도 nativeClaim/nativeFindChild를 심는다 — 실 프로바이더와 같은 형태 (2순회 H-374, H-305 (d′)) ===")
do
	local root = Instance.new("Frame")
	local child = Instance.new("TextLabel")
	child.Name = "Title"
	child.Parent = root
	assert(quad.nativeFindChild(root, "Title") == child and quad.nativeFindChild(root, "Nope") == nil, "nativeFindChild = FindFirstChild")
	quad.nativeClaim(root)
	local ok, err = pcall(function()
		quad.nativeClaim(root)
	end)
	assert(not ok and string.find(tostring(err), "already claimed", 1, true) ~= nil, "double claim is the real provider's contract (§7-10): " .. tostring(err))
	mock.assertBlamesUser(err, "spec.lifetime.luau", "nativeClaim blame")
	-- Claim itself runs under the mock backend — resolve → nativeClaim → nativeFindChild → drive
	-- (a fresh tree: `root` above is already claimed, and Claim claims first)
	local root2 = Instance.new("Frame")
	local child2 = Instance.new("TextLabel")
	child2.Name = "Title"
	child2.Parent = root2
	-- (mock has no Property/InstanceChild handlers, so a root-only descriptor:
	-- the claim itself is the observation — child resolution is `spec.claim`'s)
	local M = quad.newMapperClass
	local out = quad.Claim(root2, M("Frame")(quad.MapperRoot)({}))
	assert(out == root2, "Claim returns the root")
	local okC = pcall(function()
		quad.nativeClaim(root2)
	end)
	assert(not okC, "Claim claimed the root through the mock's nativeClaim")
	-- `H-418` (외부 리뷰 G-06): a non-Instance first argument is refused at the surface
	local okN, errN = pcall(function()
		quad.Claim(nil, M("Frame")(quad.MapperRoot)({}))
	end)
	assert(not okN and string.find(tostring(errN), "first argument must be an Instance", 1, true) ~= nil, "Claim(nil) is a surface error: " .. tostring(errN))
	mock.assertBlamesUser(errN, "spec.lifetime.luau", "Claim(nil) blame")
	-- 7순회 `H-425`: non-table props are refused BEFORE nativeClaim — a fixed retry still works
	local root3 = Instance.new("Frame")
	local okP, errP = pcall(function()
		quad.Claim(root3, M("Frame")(quad.MapperRoot)("oops" :: any))
	end)
	assert(not okP and string.find(tostring(errP), "props must be a table", 1, true) ~= nil, "string props refused: " .. tostring(errP))
	assert(quad.Claim(root3, M("Frame")(quad.MapperRoot)({})) == root3, "the root was not claimed by the failed call — retry succeeds")
	print("PASS")
end

print("=== 10. round3 H-444 (외부 리뷰 G-14) — nil 인자: unbindLifetime(nil)은 no-op(헤더 계약), canExecute(nil) false, canBound(nil) true, bindLifetime(nil, v)는 표면 에러 ===")
do
	local q = mock.newQuad()
	q.unbindLifetime(nil)
	assert(q.canExecute(nil) == false and q.canBound(nil) == true, "nil is simply unbound")
	local ok, err = pcall(function()
		q.bindLifetime(nil, q.Source(1))
	end)
	assert(not ok and string.find(tostring(err), "inst must not be nil", 1, true) ~= nil, "surface error, not a VM one: " .. tostring(err))
	-- round3 `H-447`: the fourth nil door — bindLifetime(inst, nil) died at `gchold[nil]`
	local frame = mock.Instance.new("Frame")
	q.Dispatch.drive(frame, {})
	local okV, errV = pcall(function()
		q.bindLifetime(frame, nil)
	end)
	assert(not okV and string.find(tostring(errV), "value must not be nil", 1, true) ~= nil, "nil value: " .. tostring(errV))
	print("PASS")
end

print()
print("=== ALL PASS ===")
