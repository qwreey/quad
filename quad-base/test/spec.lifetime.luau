--[[
	LifetimeHandle 계약 — `.claude/base/lifecycle-pattern.md` "`bindLifetime`/`canBound`/
	`canExecute`/`unbindLifetime` — 확정" 절 + mock 백엔드(`mock.luau` installLifetime, ROADMAP `H-97`).
	Observer/Effect의 `.Subscribed` 경로는 단위 3(Observer/Effect)에서 합류.
]]

local Quad = require("../src")
local mock = require("./mock")

-- strict 모드에서 `collectgarbage`는 선언 안 된 전역 — 표준 luau CLI엔 있다(Roblox엔 없음)
local collectgarbage = (_G :: any).collectgarbage :: () -> ()
print("=== 1. 미주입 스텁 — 네 슬롯 전부 영어 메시지로 error, 호출부(level 2)를 가리킴 ===")
do
	local fresh = Quad.New()
	for _, name in { "bindLifetime", "unbindLifetime", "canBound", "canExecute" } do
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
	assert(string.find(tostring(err), "spec.lifetime.luau", 1, true) ~= nil, "level 2 points at the caller: " .. tostring(err))
	-- 같은 inst에 다시 묶는 것도 이중 바인딩
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
print("=== ALL PASS ===")
