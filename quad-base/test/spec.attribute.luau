--[[
	Attribute 계약 (M10, round16 spike) — 단일 키(`base/attribute-plan.md`
	"단일 키"/"동등성"/"메커니즘"/"이름 소유권") + 그룹(같은 문서 "그룹
	`Attribute(...)`"/"메커니즘 — 그룹 전용 키로 단일 키 경로에 위임").
	mock의 `installTagAttributeOps` 로그로 "클로저는 setAttribute를 절대 안
	부른다"·"필드 하나 변경은 그룹 재처리 없이 단일 키 경로"를 직접 관측.
]]

local Quad = require("../src")
local mock = require("./mock")
local newQuad = mock.newQuad
local Instance = mock.Instance

local function newAttrQuad(log: { string }?)
	local q = newQuad()
	mock.installTagAttributeOps(q, log)
	return q
end

print("=== 1. AttributeKey — 이름별 캐시 동일성, 패밀리 = 같은 객체, 브랜드 ===")
do
	local q = newAttrQuad()
	local a = q.AttributeKey("Enabled")
	assert(a == q.AttributeKey("Enabled"), "same name = same object (weak cache)")
	assert(a == q.BooleanAttribute("Enabled") and a == q.StringAttribute("Enabled"), "families share the cache")
	assert(q.isAttributeKey(a) and a.Name == "Enabled", "brand + Name")
	assert(not pcall(function()
		(a :: any).x = 1
	end), "frozen")
	-- 통합 감사 2라운드: 생성자·합성 검증의 blame(H-238 태깅)
	local okK, errK = pcall(function()
		q.AttributeKey(123)
	end)
	assert(not okK, "AttributeKey validates")
	mock.assertBlamesUser(errK, "spec.attribute.luau", "AttributeKey blame")
	local okM, errM = pcall(function()
		q.Attribute.Merged(7)
	end)
	assert(not okM, "Merged validates")
	mock.assertBlamesUser(errM, "spec.attribute.luau", "Merged blame")
	print("PASS")
end

print()
print("=== 2. 단일 키 왕복 — 무조건 set, store-bind, None → nil 삭제 ===")
do
	local log: { string } = {}
	local q = newAttrQuad(log)
	local inst = Instance.new("Frame")
	local hp = q.Source(5)
	q.Dispatch.drive(inst, { [q.AttributeKey("Hp")] = hp, [q.AttributeKey("Title")] = "quad" })
	local attrs = mock.getAttributes(inst)
	assert(attrs.Hp == 5 and attrs.Title == "quad", "both set (store unwrapped by StoreBind)")

	hp:Set(7) -- 필드 갱신 — 그 키 체인만 다시 돌고 setAttribute 재호출
	assert(mock.getAttributes(inst).Hp == 7, "reactive update")

	q.Dispatch.process(inst, q.AttributeKey("Title"), q.None, 1) -- None → nil 재귀
	assert(mock.getAttributes(inst).Title == nil, "None deletes via the same key handler")
	print("PASS")
end

print()
print("=== 3. 그룹 — Store 평탄화 반영, 필드 변경은 그룹 재진입 없이 단일 키 경로 ===")
do
	local log: { string } = {}
	local q = newAttrQuad(log)
	local inst = Instance.new("Frame")
	local store = q.Store({ Hp = q.Source(5), Name = q.Source("hero") })
	q.Dispatch.drive(inst, { q.Attribute(store, { Level = 3 }) })
	local attrs = mock.getAttributes(inst)
	assert(attrs.Hp == 5 and attrs.Name == "hero" and attrs.Level == 3, "flattened and applied")

	local before = #log
	store.Hp:Set(9)
	assert(mock.getAttributes(inst).Hp == 9, "field update flows")
	assert(#log == before + 1 and log[#log] == "setAttribute:Hp=9", "exactly one engine call, single-key path only: " .. table.concat(log, " | ", before + 1))
	print("PASS")
end

print()
print("=== 4. 그룹 교체 — 값은 잔존(클로저는 setAttribute 안 부름), 구독은 끊김 ===")
do
	local log: { string } = {}
	local q = newAttrQuad(log)
	local inst = Instance.new("Frame")
	local storeA = q.Store({ Hp = q.Source(5) })
	local src = q.Source(q.Attribute(storeA))
	q.Dispatch.drive(inst, { src })
	assert(mock.getAttributes(inst).Hp == 5, "mounted")

	src:Set(q.Attribute({ Mana = 2 })) -- Hp가 그룹에서 사라짐
	local attrs = mock.getAttributes(inst)
	assert(attrs.Mana == 2, "new name applied")
	assert(attrs.Hp == 5, "old value PERSISTS — explicit None/nil is the only eraser")
	for _, entry in log do
		assert(entry ~= "setAttribute:Hp=nil", "the retractor never calls setAttribute")
	end

	local before = #log
	storeA.Hp:Set(99) -- 옛 store — 구독이 끊겼으므로 아무 일도 없어야 함
	assert(#log == before, "old subscription is dead (no leak)")
	assert(mock.getAttributes(inst).Hp == 5, "value untouched by the dead store")
	print("PASS")
end

print()
print("=== 5. 합성 정책 — 생성자·Overridden은 뒤가 이김, Merged는 겹치면 error ===")
do
	local q = newAttrQuad()
	local a = q.Attribute({ X = 1, Y = 1 })
	local b = q.Attribute({ Y = 2 })
	assert(q.isAttribute(a), "brand")
	assert(q.Attribute(a, b):NameMap().Y == 2, "constructor: last wins")
	assert(q.Attribute.Overridden(a, b):NameMap().Y == 2, "Overridden: last wins silently")
	local ok, err = pcall(function()
		q.Attribute.Merged(a, b)
	end)
	assert(not ok and string.find(tostring(err), "more than once", 1, true) ~= nil, "Merged: overlap errors: " .. tostring(err))
	assert(q.Attribute.Merged(a):NameMap().X == 1, "Merged without overlap passes")
	print("PASS")
end

print()
print("=== 6. 이름 claim — 그룹이 잡은 이름을 직접 쓰기가 노리면 즉시 error ===")
do
	local q = newAttrQuad()
	local inst = Instance.new("Frame")
	q.Dispatch.drive(inst, { q.Attribute({ Hp = 5 }) })
	local ok, err = pcall(function()
		q.Dispatch.drive(inst, { [q.AttributeKey("Hp")] = 9 })
	end)
	assert(not ok, "cross-owner claim must error")
	assert(string.find(tostring(err), 'attribute "Hp" is already bound by another owner', 1, true) ~= nil, "domain message: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.attribute.luau", "claim blame")
	print("PASS")
end

print()
print("=== 7. groupClaimKeys — 같은 그룹 객체를 두 위치에 놓으면 즉시 error ===")
do
	local q = newAttrQuad()
	local inst = Instance.new("Frame")
	local a = q.Attribute({ Hp = 5 })
	local ok, err = pcall(function()
		q.Dispatch.drive(inst, { a, a })
	end)
	assert(not ok, "double placement must error")
	assert(string.find(tostring(err), "two positions", 1, true) ~= nil, "message: " .. tostring(err))
	print("PASS")
end

print()
print("=== 8. H-39 부기 + 미주입 스텁 안내 ===")
do
	local q = newAttrQuad()
	local inst = Instance.new("Frame")
	local sources = {}
	mock.addSpecLeaf(q, sources)
	q.Dispatch.drive(inst, { q.Attribute({ Hp = 1 }), "child" })
	assert(q.Dispatch.getOffsetAt(inst, 2) == 0, "group contributes 0 to the offset math")

	local bare = Quad.New()
	mock.installLifetime(bare) -- setAttribute는 스텁 그대로
	local inst2 = Instance.new("Frame")
	local ok, err = pcall(function()
		bare.Dispatch.drive(inst2, { [bare.AttributeKey("Hp")] = 5 })
	end)
	assert(not ok and string.find(tostring(err), "setAttribute is not available", 1, true) ~= nil, "guidance: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.attribute.luau", "stub blame")
	print("PASS")
end

print()
print("=== ALL PASS ===")
