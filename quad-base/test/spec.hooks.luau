--[[
	생명주기 훅 슈거 계약 — `.claude/base/lifecycle-hooks-plan.md` "핵심 논지"(순수 팩토리, nil 가드 `H-120`,
	2-인자 흘림 `H-107`), ① 절(PreRef/PostRef/Effect 계약 그대로, 다중 등록 = 배열 자리), `OnDestroyed`
	= leaf 사망 cleanup. 디스패치 통합은 `Dispatch.drive` pre-pass(spec.refhandlers 관용구).
]]

local mock = require("./mock")
local Instance = mock.Instance

type MockInstance = mock.MockInstance

local SPEC_FILE = "spec.hooks.luau"
local q = mock.newQuad()
local OnCreated, OnRendered, OnDestroyed = q.OnCreated, q.OnRendered, q.OnDestroyed

print("=== 1. 팩토리 — fn 게이트(blame은 호출 줄), 반환은 PreRef/PostRef/EffectHandle 인스턴스 그 자체(새 브랜드 없음) ===")
do
	for _, name in { "OnCreated", "OnRendered", "OnDestroyed" } do
		local ok, err = pcall(function()
			return (q :: any)[name](5)
		end)
		assert(not ok and string.find(tostring(err), `{name}: fn must be a function`, 1, true), tostring(err))
		mock.assertBlamesUser(err, SPEC_FILE, name)
	end
	local pre = OnCreated(function() end)
	local post = OnRendered(function() end)
	local eff = OnDestroyed(function() end)
	assert(q.isPreRef(pre) and q.isRef(pre) and not q.isPostRef(pre), "OnCreated → PreRef")
	assert(q.isPostRef(post) and q.isRef(post) and not q.isPreRef(post), "OnRendered → PostRef")
	assert(q.isEffect(eff), "OnDestroyed → EffectHandle")
	assert(OnCreated(function() end) ~= pre, "every call is a fresh instance (multiple registration)")
	print("PASS")
end

print()
print("=== 2. nil 가드(H-120) — 생성 시점 fn(nil) 호출이 없다; 채워지면 fn(inst, ref) 2-인자(H-107) ===")
do
	local calls = {}
	local pre = OnCreated(function(inst: MockInstance, ref)
		calls[#calls + 1] = { inst, ref }
	end)
	assert(#calls == 0, "no fn(nil) at registration")
	local inst = Instance.new("Frame")
	pre:Set(inst)
	assert(#calls == 1 and calls[1][1] == inst and calls[1][2] == pre, "fn(inst, ref)")
	local post = OnRendered(function(v: MockInstance, r)
		calls[#calls + 1] = { v, r }
	end)
	post:Set(inst)
	assert(#calls == 2 and calls[2][2] == post, "PostRef mirror")
	print("PASS")
end

print()
print("=== 3. drive 통합 — OnCreated는 pre-pass(다른 어떤 것보다 먼저), OnRendered는 두 패스 뒤; 같은 계열은 배열 순서 ===")
do
	local log = {}
	local inst = Instance.new("Frame")
	local leaf = q.Source("x")
	mock.addSpecLeaf(q, { leaf }, log)
	q.Dispatch.drive(inst, {
		OnRendered(function(i: MockInstance)
			log[#log + 1] = "rendered1:" .. i.Name
		end),
		OnCreated(function(i: MockInstance)
			log[#log + 1] = "created1:" .. i.Name
		end),
		leaf,
		OnCreated(function()
			log[#log + 1] = "created2"
		end),
		OnRendered(function()
			log[#log + 1] = "rendered2"
		end),
	})
	local s = table.concat(log, ",")
	assert(string.find(s, "^created1:Frame,created2,") ~= nil, `PreRefs first, in array order: {s}`)
	assert(string.find(s, "rendered1:Frame,rendered2$") ~= nil, `PostRefs last, in array order: {s}`)
	print("PASS")
end

print()
print("=== 4. OnDestroyed — 설치 때 fn은 안 돈다; 묶인 inst가 죽을 때 정확히 1회; 죽은 뒤 unbindLifetime은 다시 안 돌린다 ===")
do
	local runs = 0
	local e = OnDestroyed(function()
		runs += 1
	end)
	assert(runs == 0, "install runs the wrapper only, never fn")
	local inst = Instance.new("Frame")
	q.bindLifetime(inst, e)
	assert(runs == 0, "bound: still not run")
	inst:Destroy()
	assert(runs == 1, "leaf death → fn once")
	q.unbindLifetime(e)
	assert(runs == 1, "no double run")
	-- drive path: an OnDestroyed in the children array is bound to that inst
	local runs2 = 0
	local inst2 = Instance.new("Frame")
	q.Dispatch.drive(inst2, { OnDestroyed(function()
		runs2 += 1
	end), OnDestroyed(function()
		runs2 += 10
	end) })
	assert(runs2 == 0, "not yet")
	inst2:Destroy()
	assert(runs2 == 11, "both hooks ran once")
	print("PASS")
end

print()
print("ALL PASS")
