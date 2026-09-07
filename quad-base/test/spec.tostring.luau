--[[
	`__tostring` 계약 (2026-09-08 사용자 결정 — Gemini 자문 권고 1, `print(v)`가
	`table: 0x…` 대신 상태를 보이게). 대상은 사용자 손에 쥐어지는 값 프리미티브
	열넷 + quad-roblox의 Tween(그쪽 spec) — "브랜드가 있으면 `__tostring`"이
	아니다(사용자: Epoch도 브랜드, 브랜드 대상엔 함수·메타테이블 없는 값도
	있다). `AttrKey`는 메타테이블 없는 plain 브랜드 값이라 의도적으로 제외.
	불변식: 계산을 일으키지 않는다(State는 캐시가 유효할 때만 값을 찍는다).
]]

local _Quad = require("../src") -- 모듈 로드 자체가 계약의 일부(spec 관용구)
local mock = require("./mock")
local newQuad = mock.newQuad
local Instance = mock.Instance

print("=== 1. Source / State / Gate — 값, 캐시 무효면 `?`, print가 compute를 돌리지 않음 ===")
do
	local q = newQuad()
	local s = q.Source(42)
	assert(tostring(s) == "Source(42)", tostring(s))
	local runs = 0
	local st = s:Compute(function(self): number
		runs += 1
		return (self:Get() :: number) * 2
	end)
	assert(tostring(st) == "State(?)", "uncomputed: " .. tostring(st))
	assert(runs == 0, "tostring must not compute")
	assert(st:Get() == 84 and tostring(st) == "State(84)", tostring(st))
	s:Set(1)
	assert(tostring(st) == "State(?)", "invalidated: " .. tostring(st))
	assert(runs == 1, "still no compute from tostring")
	local g = s:Gate(function(emit)
		return function()
			emit(true)
		end
	end)
	assert(string.sub(tostring(g), 1, 5) == "Gate(", tostring(g))
	assert(tostring(q.Source(q.None)) == "Source(None)", "nested __tostring composes")
end

print("=== 2. Store / Tag / Attr — 키·이름 집합, 정렬 ===")
do
	local q = newQuad()
	local store = q.Store({ Name = q.Source("x"), Health = q.Source(1) })
	assert(tostring(store) == "Store{Health, Name}", tostring(store))
	assert(tostring(q.Store()) == "Store{}", tostring(q.Store()))
	assert(tostring(q.Tag("selected", "primary")) == 'Tag("primary", "selected")', tostring(q.Tag("selected", "primary")))
	assert(tostring(q.Tag()) == "Tag()", tostring(q.Tag()))
	assert(tostring(q.Attr({ Hp = 1, Name = "a" })) == "Attr{Hp, Name}", tostring(q.Attr({ Hp = 1, Name = "a" })))
	assert(getmetatable(q.AttrKey("Hp")) == nil, "AttrKey stays metatable-less (isPlainBranded) — no __tostring by design")
end

print("=== 3. Ref / PreRef / PostRef / Slot / Modifier ===")
do
	local q = newQuad()
	local r = q.Ref(nil :: any)
	assert(tostring(r) == "Ref(nil)", tostring(r))
	r:Set(7)
	assert(tostring(r) == "Ref(7)", tostring(r))
	assert(tostring(q.PreRef(nil :: any)) == "PreRef(nil)", tostring(q.PreRef(nil :: any)))
	assert(tostring(q.PostRef(nil :: any)) == "PostRef(nil)", tostring(q.PostRef(nil :: any)))

	local slot = q.Slot()
	assert(tostring(slot) == "Slot(len=0)", tostring(slot))
	slot:Add(Instance.new("Frame"))
	assert(tostring(slot) == "Slot(len=1)", tostring(slot))
	local parent = Instance.new("Frame")
	q.Dispatch.drive(parent, { slot })
	assert(tostring(slot) == "Slot(len=1, mounted)", tostring(slot))
	parent:Destroy()

	local m = q.Modifier():Size(1)
	assert(tostring(m) == "Modifier(1 fields)", tostring(m))
	local Label = q.Modifier.TypedFactory("SpecTostringLabel")
	assert(tostring(Label({ Text = "a", Size = 1 })) == "Modifier<SpecTostringLabel>(2 fields)", tostring(Label({ Text = "a", Size = 1 })))
end

print("=== 4. Observer / Effect / Blocker — 구독·차단 상태 ===")
do
	local q = newQuad()
	local s = q.Source(1)
	local o = s:Observer(function() end)
	assert(tostring(o) == "Observer(unsubscribed)", tostring(o))
	o:WeakSubscribe()
	assert(tostring(o) == "Observer(weak)", tostring(o))
	o:WeakUnsubscribe()
	o:Subscribe()
	assert(tostring(o) == "Observer(subscribed)", tostring(o))
	o:Unsubscribe()
	local e = q.Effect(function() end, s)
	assert(tostring(e) == "Effect(unsubscribed)", tostring(e))
	e:Subscribe()
	assert(tostring(e) == "Effect(subscribed)", tostring(e))
	e:Unsubscribe()
	local b = q.Blocker()
	assert(tostring(b) == "Blocker(off)", tostring(b))
	b:On()
	assert(tostring(b) == "Blocker(on)", tostring(b))
end

print("=== ALL PASS ===")
