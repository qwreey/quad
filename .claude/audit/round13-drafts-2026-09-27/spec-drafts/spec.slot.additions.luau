-- ── round13 Q154 (a) 초안 — E69/E73 변이 공백을 닫는 절. 대상 파일 끝의 `print("=== ALL PASS ===")` 바로 앞에 넣는다.
-- 이 파일은 `spec.slot.luau`의 지역 이름(`q`, `Slot`, `dispatch`, `Instance`, `mock`)을 그대로 쓴다(--!nocheck 파일).

print()
print("=== 39. 기준 오프셋이 0이 아닌 자리의 중첩 Slot — 손자 Slot의 Offset·getOffsetAt은 기준을 더하고, 앞선 Slot이 자라면 따라간다 ===")
-- 계약: docs/reference/core/06-slot.md `slot.Offset` 동작("마운트 대상 안에서 … 절대 위치"),
-- .claude/base/dispatch-core-plan.md "Length/Offset" 절. 변이: E69 BK16(Bookkeeping 기준값을 0으로),
-- E69 SE01(Slot/Tree 기준 Observer의 캐시 되돌림 삭제).
do
	local sA, sB, inner = Slot(), Slot(), Slot()
	sA:Add(Instance.new("Frame"))
	inner:Add(Instance.new("Frame"))
	sB:Add(inner)
	dispatch.drive(Instance.new("Folder"), { sA, sB })
	assert(sB.Offset:Get() == 1, "sB sits after sA's one leaf")
	assert(inner.Offset:Get() == 1, "grandchild Slot carries its parent's base 1: " .. inner.Offset:Get())
	sB:Add(Instance.new("Frame"), 1) -- a leaf before inner inside sB
	assert(inner.Offset:Get() == 2, "inner moves past the new leaf: " .. inner.Offset:Get())
	sA:Add(Instance.new("Frame")) -- the uncle grows: sB's base 1 -> 2, inner must follow to 3
	assert(sB.Offset:Get() == 2, "sB follows the uncle")
	assert(inner.Offset:Get() == 3, "inner follows the uncle's growth: " .. inner.Offset:Get())
	inner:Add(Instance.new("Frame"), 1)
	assert(q.Bookkeeping.getOffsetAt(inner, 1) == 3, "getOffsetAt(inner, 1) includes the base: " .. q.Bookkeeping.getOffsetAt(inner, 1))
	assert(q.Bookkeeping.getOffsetAt(inner, 2) == 4, "getOffsetAt(inner, 2) = base + first leaf")
	print("PASS")
end

print()
print("=== 40. IndexOf — 빠진 원소(Remove)·밀려난 원소(Replace)는 nil ===")
-- 계약: docs/reference/core/06-slot.md `slot:IndexOf` "없으면 nil". 변이: E69 SW04(vacate의 역맵 삭제), SW07(rawReplace의 옛 원소 칸).
do
	local s = Slot()
	local a, b, c = Instance.new("Frame"), Instance.new("Frame"), Instance.new("Frame")
	s:Add(a); s:Add(b)
	s:Remove(1)
	assert(s:IndexOf(a) == nil, "removed element has no index: " .. tostring(s:IndexOf(a)))
	assert(s:IndexOf(b) == 1, "survivor shifted to 1")
	s:Replace(1, c)
	assert(s:IndexOf(b) == nil, "replaced-out element has no index: " .. tostring(s:IndexOf(b)))
	assert(s:IndexOf(c) == 1, "replacement sits at 1")
	print("PASS")
end

print()
print("=== 41. :List — Detach로 보관한 원소를 다음 사이클에 nil로 버리면 소유 Slot은 그 원소를 파괴한다 ===")
-- 계약: docs/reference/core/06-slot.md `:List` 반환 표("`nil` 또는 `q.None` — 이 키를 버립니다(소유 Slot이면 파괴)",
-- "`q.Detach` — … 보관"), `q.Detach`("보관 중인 원소는 Slot이 소유"). 변이: E69 SW14(releaseElement의 wasDetached 갈래 반전).
do
	local s = Slot()
	local data = q.Source({ "a" })
	local mode = "keep"
	local el
	s:List(data, function(ctx)
		if mode == "keep" then el = el or Instance.new("Frame"); return el end
		if mode == "detach" then return q.Detach end
		return nil
	end, function(item) return item end)
	dispatch.drive(Instance.new("Folder"), { s })
	mode = "detach"; data:Set({ "a" })
	assert(not mock.isDestroyed(el) and el.Parent == nil, "detached: off the tree, alive")
	mode = "drop"; data:Set({ "a" })
	assert(mock.isDestroyed(el), "a held element dropped with nil is destroyed by the owning Slot")
	print("PASS")
end

print()
print("=== 42. :List — 중복 키는 Quad0145 ===")
-- 계약: docs/reference/core/06-slot.md `:List` 재조정 중 에러 `Quad0145 Slot:List: duplicate key`,
-- docs/reference/errors/03-slot.md Quad0145. 변이: E69 SL04(중복 게이트 삭제 → VM `table index is nil`).
do
	local s = Slot()
	s:List({ 1, 1 }, function() return Instance.new("Frame") end, function(item) return item end)
	local ok, err = pcall(function() dispatch.drive(Instance.new("Folder"), { s }) end)
	assert(not ok and string.find(tostring(err), "Quad0145", 1, true) ~= nil, "duplicate key: " .. tostring(err))
	print("PASS")
end

print()
print("=== 43. :List — updateFn의 둘째 반환값은 그 키의 다음 ctx.UserData로 돌아온다 ===")
-- 계약: docs/reference/core/06-slot.md `:List` 표("`ctx.UserData` — 지난 호출이 두 번째로 반환한 값. 키마다 따로"),
-- "두 번째 반환값은 이 키의 다음 `ctx.UserData`가 됩니다". 변이: E69 SL06(`userdata[key] = ud` 삭제).
do
	local s = Slot()
	local data = q.Source({ "a", "b" })
	local seen = {}
	s:List(data, function(ctx)
		seen[ctx.Item] = ctx.UserData
		return ctx.Prev or Instance.new("Frame"), (ctx.UserData or 0) + 1
	end, function(item) return item end)
	dispatch.drive(Instance.new("Folder"), { s })
	assert(seen.a == nil and seen.b == nil, "first call: no UserData yet")
	data:Set({ "a", "b" })
	assert(seen.a == 1 and seen.b == 1, "second cycle sees the first return: " .. tostring(seen.a) .. "/" .. tostring(seen.b))
	data:Set({ "b", "a" })
	assert(seen.a == 2 and seen.b == 2, "per-key, independent of position")
	print("PASS")
end

print()
print("=== 44. :List — 한 재조정 사이클은 한 배치: 원소 다섯을 한 번에 넣어도 Length는 한 번만 발행된다 ===")
-- 계약: docs/reference/core/06-slot.md `:List` 동작("한 사이클은 **하나의 배치**로 묶여 재계산이 한 번만 일어납니다").
-- 변이: E69 SL10(List의 ownsGate 반전), BK10(setLength의 배치 블로커 게이트 삭제).
do
	local s = Slot()
	local data = q.Source({})
	s:List(data, function(ctx) return ctx.Prev or Instance.new("Frame") end)
	dispatch.drive(Instance.new("Folder"), { s })
	local n = 0
	local o = s.Length:Observer(function() n += 1 end):Subscribe()
	n = 0
	data:Set({ 1, 2, 3, 4, 5 })
	assert(s.Length:Get() == 5, "five mounted")
	assert(n == 1, "Length emitted once per reconcile cycle: " .. n)
	o:Unsubscribe()
	print("PASS")
end

print()
print("=== 45. :List — updateFn이 이미 다른 Slot에 든 원소를 돌려주면 Quad0156(다중 마운트 금지) ===")
-- 계약: docs/reference/errors/03-slot.md Quad0156("`:List`/`:Single`의 `updateFn`이 돌려준 값이 이미 다른 자리에 마운트").
-- 변이: E69 SN01(Slot/Owner claimOwner 게이트 삭제 — List 경로의 유일한 문).
do
	local other = Slot(); local shared = Instance.new("Frame"); other:Add(shared)
	local s = Slot()
	s:List({ 1 }, function() return shared end)
	local ok, err = pcall(function() dispatch.drive(Instance.new("Folder"), { s }) end)
	assert(not ok and string.find(tostring(err), "Quad0156", 1, true) ~= nil, "double mount via :List: " .. tostring(err))
	print("PASS")
end

print()
print("=== 46. q.Bookkeeping.releaseOwner — 잡은 주인이 아닌 ownerKey로 풀면 Quad0163 ===")
-- 계약: docs/reference/errors/03-slot.md Quad0163, docs/reference/extend/02-dispatch-handler-contract.md
-- `q.Bookkeeping.releaseOwner(element, ownerKey)`. 변이: E69 SN03(주인 불일치 게이트 삭제).
do
	local inst, other = Instance.new("Frame"), Instance.new("Frame")
	local el = Instance.new("Frame")
	q.Bookkeeping.claimOwnerAt(el, inst, 1)
	local ok, err = pcall(function() q.Bookkeeping.releaseOwner(el, other) end)
	assert(not ok and string.find(tostring(err), "Quad0163", 1, true) ~= nil, "wrong-owner release: " .. tostring(err))
	q.Bookkeeping.releaseOwner(el, inst) -- the real owner still releases cleanly
	print("PASS")
end

print()
print("=== 47. Splice — removeCount가 남은 길이를 넘으면 Quad0174(클램프하지 않음) ===")
-- 계약: docs/reference/errors/03-slot.md Quad0174("`index + removeCount - 1`이 현재 길이를 넘을 때").
-- 변이: E69 SI09(범위 게이트를 한 칸 늦춤 → Quad0161로 죽음).
do
	local s = Slot(); s:Add(Instance.new("Frame"))
	local ok, err = pcall(function() s:Splice(1, 2) end)
	assert(not ok and string.find(tostring(err), "Quad0174", 1, true) ~= nil, "Splice range error: " .. tostring(err))
	assert(#s._elements == 1, "nothing removed")
	print("PASS")
end

print()
print("=== 48. 같은 Slot을 같은 숫자 키 자리에 다시 drive하면 no-op — 에러 없음, 물리 재삽입 없음, 이후 CRUD 정상 ===")
-- 계약: docs/reference/extend/02-dispatch-handler-contract.md `claimOwnerAt`("정확히 같은 자리가 이미 쥐고 있으면 `false` …
-- 같은 값 재발행 dedup 뒤 다시 `process`될 때 — 이때는 물리 부착도 건너뛰면 됩니다"). 변이: E73 SH05(claimOwnerAt 결과 무시 →
-- 이중 바인딩 에러), SH06(`slotValue == nextValue` 조기 반환 삭제 → 빠졌다 다시 들어감).
do
	local s = Slot()
	s:Add(Instance.new("Frame"))
	local parent = Instance.new("Folder")
	local lead = Slot(); lead:Add(Instance.new("Frame"))
	local inserts = 0
	local orig = q.Backend.nativeInsert
	q.Backend.nativeInsert = function(...) inserts += 1; return orig(...) end
	dispatch.drive(parent, { lead, s })
	local before = inserts
	local ok, err = pcall(function() dispatch.drive(parent, { lead, s }) end)
	q.Backend.nativeInsert = orig
	assert(ok, "re-drive of the same Slot at the same position raised: " .. tostring(err))
	assert(inserts == before, "re-drive re-inserted elements: " .. (inserts - before))
	assert(childCount(parent) == 2, "children unchanged")
	local b = Instance.new("Frame")
	s:Add(b)
	assert(childCount(parent) == 3 and b.Parent == parent, "CRUD after the re-drive still mounts")
	assert(s.Offset:Get() == 1 and s.Length:Get() == 2, "bookkeeping intact")
	print("PASS")
end

print()
print("=== 49. 파괴된 Slot을 숫자 키 자리에 놓으면 핸들러 사전검사 Quad0140 ===")
-- 계약: docs/reference/errors/03-slot.md Quad0140(공개 경로에서는 이 ID가 먼저 — Quad0164 절 "공개 경로에서는 핸들러 사전검사
-- Quad0140이 먼저 걸리고"). 변이: E73 SH03(Slot/Handler 파괴 게이트 삭제 → Quad0164).
do
	local dead = Slot()
	q.dispose(dead)
	local ok, err = pcall(function() dispatch.drive(Instance.new("Folder"), { dead }) end)
	assert(not ok and string.find(tostring(err), "Quad0140", 1, true) ~= nil, "destroyed Slot mount: " .. tostring(err))
	print("PASS")
end

print()
print("=== 50. Slot 원소 게이트 — Modifier는 Quad0238(핸들러 레이어 값), None은 Quad0239 ===")
-- 계약: docs/reference/errors/03-slot.md Quad0238·Quad0239. 변이: E73 EL02(Modifier 판정 삭제), EL04(None 판정 삭제) —
-- 둘 다 뭉뚱그린 Quad0240으로 떨어졌다.
do
	local ok, err = pcall(function() Slot():Add(q.Modifier()) end)
	assert(not ok and string.find(tostring(err), "Quad0238", 1, true) ~= nil, "Modifier element: " .. tostring(err))
	local ok2, err2 = pcall(function() Slot():Add(q.None) end)
	assert(not ok2 and string.find(tostring(err2), "Quad0239", 1, true) ~= nil, "None element: " .. tostring(err2))
	print("PASS")
end

print()
print("=== 51. q.Dispatch.process로 Slot을 배열 리터럴이 아닌 숫자 키(0·소수)에 놓으면 Quad0141; drive는 그 키를 먼저 막는다 ===")
-- 계약: docs/reference/errors/03-slot.md Quad0141("숫자 키라도 `q.Dispatch.process(inst, key, slot, index)`를 직접 불러 배열 리터럴이
-- 아닌 자리(`0`·음수 키 등)에 놓으면 같은 가드로 … `q.Dispatch.drive`는 그런 키를 Quad0085로 먼저 막습니다").
-- 변이: E73 SH01(`k >= 1` 삭제), SH02(`k % 1 == 0` 삭제) — 둘 다 Quad0019로 떨어졌다.
do
	local ok0, err0 = pcall(function() dispatch.process(Instance.new("Folder"), 0, Slot(), 1) end)
	assert(not ok0 and string.find(tostring(err0), "Quad0141", 1, true) ~= nil, "zero key: " .. tostring(err0))
	local okf, errf = pcall(function() dispatch.process(Instance.new("Folder"), 1.5, Slot(), 1) end)
	assert(not okf and string.find(tostring(errf), "Quad0141", 1, true) ~= nil, "fractional key: " .. tostring(errf))
	local okd, errd = pcall(function() dispatch.drive(Instance.new("Folder"), { [1.5] = Slot() }) end)
	assert(not okd and string.find(tostring(errd), "Quad0085", 1, true) ~= nil, "drive gates the key first: " .. tostring(errd))
	print("PASS")
end
