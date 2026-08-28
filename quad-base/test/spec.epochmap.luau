--[[ EpochMap 계약 — `.claude/base/state-epoch-plan.md` §3 "`EpochMap` — 컴포지션 가능한 부기 객체" ]]

local Quad = require("../src")
local EpochMap = require("../src/EpochMap")
local Brand = require("../src/Brand")

-- strict 모드에서 `collectgarbage`는 선언 안 된 전역 — 표준 luau CLI엔 있다(Roblox엔 없음)
local collectgarbage = (_G :: any).collectgarbage :: () -> ()

local function epoch(rev: number): any
	local e = { Revision = rev }
	Brand.EpochBrand:register(e)
	return e
end

print("=== 1. Update — 읽고 비교하고 덮는다, 하나라도 달랐으면 true ===")
do
	local m = EpochMap()
	local a = epoch(1)
	assert(m:Update(a) == true, "first sight of an epoch is a change")
	assert(m:Update(a) == false, "same revision again is not")
	a.Revision = 2
	assert(m:Update(a) == true and m:Update(a) == false, "revision moved → true once, then absorbed")
	print("PASS")
end

print()
print("=== 2. EpochSet — 집합({[Epoch]: true})을 받는다, 배열이 아니다 ===")
do
	local m = EpochMap()
	local a, b = epoch(1), epoch(1)
	assert(m:Update({ [a] = true, [b] = true }) == true, "set: any unseen key → true")
	assert(m:Update({ [a] = true, [b] = true }) == false, "set: all absorbed → false")
	b.Revision = 5
	assert(m:Update({ [a] = true, [b] = true }) == true, "set: one moved → true")
	assert(m:Update(b) == false, "and it was written even though the answer was already fixed")
	-- (배열 `{a, b}`는 계약 밖 — 집합이어야 한다. 문서가 경고한 그 함정은 여기서 고정하지 않는다.)
	print("PASS")
end

print()
print("=== 3. Peek — 비교만, 덮지 않음 ===")
do
	local m = EpochMap()
	local a = epoch(1)
	assert(m:Peek(a) == true, "unseen → differs")
	assert(m:Peek(a) == true, "still differs: Peek wrote nothing")
	m:Update(a)
	assert(m:Peek(a) == false, "absorbed by Update")
	a.Revision = 2
	assert(m:Peek({ [a] = true }) == true and m:Update(a) == true, "set form too; Update still sees the change")
	print("PASS")
end

print()
print("=== 4. Sync — 읽지 않고 쓰기만, 반환값 없음 ===")
do
	local m = EpochMap()
	local a = epoch(3)
	assert(select("#", m:Sync(a)) == 0, "Sync returns nothing")
	assert(m:Update(a) == false, "after Sync the epoch is current")
	local b = epoch(1)
	m:Sync({ [b] = true })
	assert(m:Update(b) == false, "set form")
	print("PASS")
end

print()
print("=== 5. Refresh — 인자 없는 Update: 추적 중인 키 전부를 라이브로 ===")
do
	local m = EpochMap()
	local a, b = epoch(1), epoch(1)
	m:Sync({ [a] = true, [b] = true })
	assert(m:Refresh() == false, "nothing moved")
	b.Revision = 2
	assert(m:Refresh() == true, "b moved")
	assert(m:Refresh() == false and m:Update(b) == false, "Refresh wrote the live revision")
	assert(EpochMap():Refresh() == false, "empty map: nothing to walk → false")
	print("PASS")
end

print()
print("=== 6. TrackFrom — other의 키를 넘겨받아 라이브 리비전으로, other는 안 건드림 ===")
do
	local up = EpochMap()
	local a = epoch(1)
	up:Sync(a)
	a.Revision = 7 -- up의 저장값(1)은 이제 낡았다
	local down = EpochMap()
	down:TrackFrom(up)
	assert(down:Update(a) == false, "down was filled with the LIVE revision (7), not up's stored 1")
	assert(up:Refresh() == true, "up itself was untouched — it still sees the move")
	print("PASS")
end

print()
print("=== 7. 키는 weak — Epoch가 죽으면 항목이 사라짐 ===")
do
	local m = EpochMap()
	local function seed()
		m:Sync(epoch(1))
	end
	seed()
	collectgarbage()
	collectgarbage()
	assert(next((m :: any)._map) == nil, "dead epoch's entry is gone")
	print("PASS")
end

print()
print("=== 8. Source/Ref는 Epoch로서 그대로 들어간다 ===")
do
	local m = EpochMap()
	local src = Quad.Source(0)
	local ref = Quad.Ref(0)
	assert(m:Update({ [src] = true, [ref] = true } :: any) == true, "both are Epochs")
	src:Set(1)
	assert(m:Update(src) == true, "Source:Set bumps its revision")
	ref:Set(1)
	assert(m:Refresh() == true, "Ref:Set too")
	print("PASS")
end

print()
print("=== ALL PASS ===")
