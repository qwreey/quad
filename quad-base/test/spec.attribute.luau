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

print("=== 1. AttributeKey — 이름별 캐시 동일성, 브랜드 (패밀리는 이제 키가 아니다 — 10절) ===")
do
	local q = newAttrQuad()
	local a = q.AttributeKey("Enabled")
	assert(a == q.AttributeKey("Enabled"), "same name = same object (weak cache)")
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
	assert(not pcall(function() q.AttributeKey("") end), "an empty attribute name is rejected (`H-417`)")
	local okM, errM = pcall(function()
		q.Attribute.Merged(7)
	end)
	assert(not okM, "Merged validates")
	mock.assertBlamesUser(errM, "spec.attribute.luau", "Merged blame")
	print("PASS")
end

print()
print("=== 1b. 생성자 — plain 테이블만 (핸드오버 리뷰 `H-345`, Modifier `H-310`의 거울) ===")
do
	local q = newAttrQuad()
	local okS, errS = pcall(function()
		q.Attribute(q.Source(1))
	end)
	assert(not okS and string.find(tostring(errS), "plain tables", 1, true) ~= nil, "a Source is not a plain table: " .. tostring(errS))
	mock.assertBlamesUser(errS, "spec.attribute.luau", "constructor blame")
	local okR, errR = pcall(function()
		q.Attribute(q.Ref(1))
	end)
	assert(not okR and string.find(tostring(errR), "plain tables", 1, true) ~= nil, "a Ref (metatable) is not flattened field by field: " .. tostring(errR))
	-- 1순회 `H-368`: brands are not metatables — the metatable-less quad values
	-- (AttributeKey — a frozen `{ Name }`) were still flattened into `{ Name = "…" }`
	local okK, errK = pcall(function()
		q.Attribute(q.AttributeKey("Selected"))
	end)
	assert(not okK and string.find(tostring(errK), "plain tables", 1, true) ~= nil, "an AttributeKey (brand, no metatable) is not a plain table: " .. tostring(errK))
	mock.assertBlamesUser(errK, "spec.attribute.luau", "AttributeKey-arg blame")
	-- function values: the engine cannot store one — raise at construction, not
	-- inside setAttribute at dispatch depth (quad-roblox's OnChange descriptor
	-- `{ Name, Callback }` lands here too)
	local okF, errF = pcall(function()
		q.Attribute({ Foo = function() end })
	end)
	assert(not okF and string.find(tostring(errF), 'attribute "Foo" cannot be a function', 1, true) ~= nil, "function value rejected: " .. tostring(errF))
	mock.assertBlamesUser(errF, "spec.attribute.luau", "function-value blame")
	-- 7순회 `H-421`: the empty-name gate covers the group constructor and the scalar sugar too
	assert(not pcall(function() q.Attribute({ [""] = 5 }) end), "group: empty attribute name rejected")
	assert(not pcall(function() q.NumberAttribute("", 5) end), "sugar: empty attribute name rejected")
	-- positive control — raw + State + None still flow
	local ok = q.Attribute({ A = 1, B = q.Source("x"), C = q.None })
	assert((ok :: any).__quadAttribute == true, "AttributeMarker field readable (H-300, 2026-09-07 마커 전면화)")
	assert(ok:NameMap().A == 1, "raw/State/None values are untouched")
end

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
	-- [2026-09-06] 그룹↔그룹 같은 이름 — 스파이크 19 B 섹션의 재작성 지침이 요구한
	-- 음성 대조군(0-Z 확정 내용): 다른 그룹 객체가 같은 이름을 노려도 즉시 error
	local inst2 = Instance.new("Frame")
	local ok2, err2 = pcall(function()
		q.Dispatch.drive(inst2, { q.Attribute({ Hp = 5 }), q.Attribute({ Hp = 9 }) })
	end)
	assert(not ok2, "group-vs-group claim must error")
	assert(string.find(tostring(err2), 'attribute "Hp" is already bound by another owner', 1, true) ~= nil, "group-vs-group message: " .. tostring(err2))
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
	-- [M10 엔진 축] mockProvider가 attribute op까지 심으므로 모듈 자신의 스텁을
	-- 붙잡아 뒀다가 설치 뒤 되돌린다(spec.tag 2와 같은 이유 — 디스패치 경유
	-- blame 경로 유지)
	local stub = bare.setAttribute
	mock.installLifetime(bare)
	bare.setAttribute = stub
	local inst2 = Instance.new("Frame")
	local ok, err = pcall(function()
		bare.Dispatch.drive(inst2, { [bare.AttributeKey("Hp")] = 5 })
	end)
	assert(not ok and string.find(tostring(err), "setAttribute is not available", 1, true) ~= nil, "guidance: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.attribute.luau", "stub blame")
	print("PASS")
end

print()
print("=== 9. 통합 리뷰(H10-8) — 같은 그룹 객체 재발행은 엔진 호출 0·claim 유지 ===")
do
	local log: { string } = {}
	local q = newAttrQuad(log)
	local inst = Instance.new("Frame")
	local group = q.Attribute({ Hp = 5, Name = "hero" })
	q.Dispatch.drive(inst, { group })
	local before = #log
	q.Dispatch.process(inst, 1, group, 1) -- same immutable object re-emitted
	assert(#log == before, "no retract/reclaim/setAttribute churn on same-object re-emission: " .. table.concat(log, " | ", before + 1))
	assert(mock.getAttributes(inst).Hp == 5, "values intact")
	-- 그리고 진짜 교체는 여전히 작동(재발행 스킵이 후속 교체를 막지 않는다)
	q.Dispatch.process(inst, 1, q.Attribute({ Hp = 7 }), 1)
	-- 키 retractor는 claim만 반납하고 엔진 부작용이 없다(attribute-plan "이름
	-- 소유권" — 삭제는 None 경로) — 그래서 Name은 엔진에 남고 Hp만 갱신된다
	assert(mock.getAttributes(inst).Hp == 7 and mock.getAttributes(inst).Name == "hero", "replacement re-applies (retract has no engine side effect by contract)")
	-- State로 감싼 그룹의 같은 값 재발행도 StoreBind 경유로 같은 dedup
	local src = q.Source(group)
	local inst2 = Instance.new("Frame")
	q.Dispatch.drive(inst2, { src })
	local before2 = #log
	src:Set(group)
	assert(#log == before2, "StoreBind path: same-object re-emission is silent too")
	print("PASS")
end

print()
print("=== 10. 타입드 스칼라 슈가(2026-09-03 사용자 확정) — 단일 항목 그룹, 값 검증, 이름 claim·위치 claim은 그룹 그대로 ===")
do
	local q = newAttrQuad()
	local inst = Instance.new("Frame")
	-- 슈가 = Attribute 그룹 값(자기 핸들러 없음)
	local s = q.StringAttribute("Title", "quad")
	assert(q.isAttribute(s) and s:NameMap().Title == "quad", "sugar is a one-entry group")
	local hp = q.Source(3)
	q.Dispatch.drive(inst, { s, q.NumberAttribute("Hp", hp), q.BooleanAttribute("Alive", true) })
	local attrs = mock.getAttributes(inst)
	assert(attrs.Title == "quad" and attrs.Hp == 3 and attrs.Alive == true, "all three landed through the group → single-key path")
	hp:Set(4)
	assert(mock.getAttributes(inst).Hp == 4, "State value stays reactive (StoreBind downstream)")
	-- None = 삭제는 바인딩된 State 경유(새 슈가 값을 다른 자리에 두면 그룹과 같은
	-- 이름 claim 충돌 — 아래 inst3에서 단언)
	local inst2 = Instance.new("Frame")
	local src = q.Source("a")
	q.Dispatch.drive(inst2, { q.StringAttribute("Label", src) })
	assert(mock.getAttributes(inst2).Label == "a", "reactive sugar")
	src:Set(q.None)
	assert(mock.getAttributes(inst2).Label == nil, "None deletes")
	-- 검증: 이름·nil·raw 타입 불일치(State/None은 통과)
	local cases: { [string]: () -> () } = {
		["name"] = function() q.StringAttribute(1, "x") end,
		["nil value"] = function() q.StringAttribute("X", nil) end,
		["type"] = function() q.NumberAttribute("X", "not a number") end,
		["type2"] = function() q.BooleanAttribute("X", 1) end,
	}
	for label, fn in cases do
		local ok, err = pcall(fn)
		assert(not ok, "sugar validates: " .. label)
		mock.assertBlamesUser(err, "spec.attribute.luau", "sugar blame " .. label)
	end
	assert(q.isAttribute(q.StringAttribute("X", q.Source("s"))) and q.isAttribute(q.StringAttribute("X", q.None)), "State/None pass the check")
	-- 이름 claim: 슈가가 잡은 이름을 직접 키가 노리면 error(그룹과 동일), 같은 이름 슈가 둘도 error
	local inst3 = Instance.new("Frame")
	q.Dispatch.drive(inst3, { q.StringAttribute("Owned", "x") })
	local okC = pcall(function()
		q.Dispatch.process(inst3, q.AttributeKey("Owned"), "y", 1)
	end)
	assert(not okC, "direct key cannot steal a sugar-claimed name")
	-- (같은 자리 교체는 하강 diff가 옛 그룹을 먼저 물리므로 충돌이 아니다 —
	-- 충돌은 서로 다른 자리에 같은 이름을 둘 때)
	local okD = pcall(function()
		q.Dispatch.drive(Instance.new("Frame") :: any, { q.StringAttribute("Owned", "x"), q.StringAttribute("Owned", "z") })
	end)
	assert(not okD, "two sugar values for the same name at two positions collide (distinct private keys)")
	-- 위치 claim: 같은 슈가 객체를 두 자리에
	local okP = pcall(function()
		local same = q.StringAttribute("Twice", "t")
		q.Dispatch.drive(Instance.new("Frame") :: any, { same, same })
	end)
	assert(not okP, "same sugar object at two positions is the group's H-41 error")
	print("PASS")
end

print()
print("=== ALL PASS ===")
