--!nocheck
--[[
	Slot spec — M6 fork, built per slice and accumulated (slices 2~4, `H6-1`~
	`H6-6`): plain-element end-to-end (`Frame { slot }` mounts children,
	Add/Remove reflect physically, ordering via Length/Offset, unmount on
	State<Slot> swap, dispose guard), Slot-in-Slot nesting, `:List`/`:Single`
	reconcile (Detach reuse, remount catch-up), wrapper-Slot reorder (`H6-6`).
	Sections 17~21 are the M6 remainder (2026-09-03, main): the public CRUD
	five (Move/Swap/Extract/Replace/Splice) + `collectLeaves` reaching native*,
	the `KeyGone` disposition branches, and pre-materialization CRUD.

	`--!nocheck`: this spec pokes internal fields (`_elements`, `_mounted`,
	`bk`) that the public `Quad` type does not expose — the M5 specs use the
	same pragma for the same reason. Contract source: `base/slot-plan.md`.
]]

local mock = require("./mock")
local q = mock.newQuad()
local Instance = mock.Instance
local Slot, dispatch = q.Slot, q.Dispatch

local function childCount(inst)
	return #inst:GetChildren()
end

print("=== 1. 생성 — 빈 Slot, 브랜드, Length 0 ===")
do
	local s = Slot()
	assert(q.isSlot(s), "isSlot true")
	assert(not q.isSlot({}), "plain table not a slot")
	assert(s.Length:Get() == 0, "empty Length 0")
	print("PASS")
end

print()
print("=== 2. Slot 마운트 — Frame { slot }, 요소가 물리 자식이 된다 ===")
do
	local s = Slot()
	local a, b = Instance.new("Frame"), Instance.new("Frame")
	a.Name, b.Name = "A", "B"
	s:Add(a)
	s:Add(b)
	assert(#s._elements == 2, "Add appends to _elements")
	-- H6 observation: Length is 0 until mount (rawAdd early-returns before
	-- materialize; recompute is what fills Length). Assert post-mount.
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { s }) -- Frame { slot } shape (array slot 1)
	assert(s.Length:Get() == 2, "Length = 2 after mount: " .. s.Length:Get())
	assert(childCount(parent) == 2, "both elements mounted physically: " .. childCount(parent))
	assert(a.Parent == parent and b.Parent == parent, "elements parented")
	print("PASS")
end

print()
print("=== 3. 마운트 후 Add/Remove가 물리에 반영 ===")
do
	local s = Slot()
	local a = Instance.new("Frame"); a.Name = "A"
	s:Add(a)
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { s })
	assert(childCount(parent) == 1, "1 mounted")
	local b = Instance.new("Frame"); b.Name = "B"
	s:Add(b)
	assert(childCount(parent) == 2 and s.Length:Get() == 2, "Add reflects after mount")
	s:Remove(1)
	assert(childCount(parent) == 1 and s.Length:Get() == 1, "Remove reflects (destroy)")
	assert(a.Parent == nil, "removed element destroyed (Parent nil)")
	print("PASS")
end

print()
print("=== 4. 형제 순서 — Frame { slotA, static, slotB }, Offset 누적 ===")
do
	-- two slots + a static-length leaf between them via a spec leaf handler
	local sA, sB = Slot(), Slot()
	local a1 = Instance.new("Frame"); a1.Name = "a1"
	sA:Add(a1)
	local b1 = Instance.new("Frame"); b1.Name = "b1"
	local b2 = Instance.new("Frame"); b2.Name = "b2"
	sB:Add(b1); sB:Add(b2)
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { sA, sB })
	assert(sA.Offset:Get() == 0, "sA offset 0")
	assert(sB.Offset:Get() == 1, "sB offset = sA.Length (1): " .. sB.Offset:Get())
	sA:Add(Instance.new("Frame")) -- sA grows → sB offset shifts
	assert(sB.Offset:Get() == 2, "sB offset shifts to 2 after sA grows: " .. sB.Offset:Get())
	print("PASS")
end

print()
print("=== 5. State<Slot> 교체 = 언마운트(파괴 아님), 재마운트 가능 ===")
do
	local src = q.Source(nil)
	local s = Slot()
	local a = Instance.new("Frame"); a.Name = "A"
	s:Add(a)
	local parent = Instance.new("Folder")
	-- store-bind: StoreBind unwraps State → the Slot lands at the array slot
	dispatch.drive(parent, { src })
	src:Set(s)
	assert(childCount(parent) == 1, "slot mounted via State")
	src:Set(nil) -- swap away → unmount, NOT destroy
	assert(childCount(parent) == 0, "unmounted")
	assert(a.Parent == nil, "element detached")
	assert(not s._destroyed, "swap is unmount, not destroy")
	src:Set(s) -- remount the same slot (portal)
	assert(childCount(parent) == 1 and a.Parent == parent, "remounted same slot")
	print("PASS")
end

print()
print("=== 6. dispose — 마운트 중이면 거부, 뗀 뒤엔 파괴 ===")
do
	local s = Slot()
	local a = Instance.new("Frame")
	s:Add(a)
	local src = q.Source(s)
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { src }) -- State<Slot> so we can retract via Set(nil)
	local ok = pcall(function() q.dispose(s) end)
	assert(not ok, "dispose refuses a still-mounted slot")
	src:Set(nil) -- retract → unmount + releaseOwner (SlotHandler retractor)
	assert(not s._destroyed, "retract unmounts")
	q.dispose(s) -- now free (owner released)
	assert(s._destroyed, "dispose destroys after unmount")
	local ok2 = pcall(function() s:Add(Instance.new("Frame")) end)
	assert(not ok2, "destroyed slot rejects CRUD")
	print("PASS")
end

print()
print("=== 7. 타입 가드 — nil/None·핸들러 계층 값 거부 (State는 :List 슬라이스) ===")
do
	local s = Slot()
	assert(not pcall(function() s:Add(nil) end), "nil rejected")
	assert(not pcall(function() s:Add(q.None) end), "None rejected")
	assert(not pcall(function() s:Add(q.Blocker()) end), "handler-layer value rejected")
	print("PASS")
end

print()
print("=== 7b. 디스패치 깊이의 Slot 오류는 사용자 줄을 blame(H-330 — errorBefore) ===")
do
	local s = Slot({ mock.Instance.new("Frame") })
	dispatch.drive(mock.Instance.new("Frame"), { s })
	local ok, err = pcall(function()
		dispatch.drive(mock.Instance.new("Frame"), { s }) -- second mount → SlotHandler raise inside drive
	end)
	assert(not ok and string.find(tostring(err), "already mounted", 1, true) ~= nil, "second mount rejected: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.slot.luau", "dispatch-depth Slot error blames the user's drive line")
	print("PASS")
end

print()
print("=== 8. Slot-in-Slot 중첩 — 재귀 마운트, Length = 기여도 합 ===")
do
	local outer, inner = Slot(), Slot()
	local h = Instance.new("Frame"); h.Name = "header"
	local i1 = Instance.new("Frame"); i1.Name = "i1"
	local i2 = Instance.new("Frame"); i2.Name = "i2"
	outer:Add(h)
	inner:Add(i1); inner:Add(i2)
	outer:Add(inner) -- outer = { header, inner{ i1, i2 } }
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { outer })
	-- all leaves flatten to the same physical parent (no wrapper)
	assert(childCount(parent) == 3, "3 physical leaves (header + i1 + i2): " .. childCount(parent))
	assert(h.Parent == parent and i1.Parent == parent and i2.Parent == parent, "all leaves under parent")
	-- outer.Length = header(1) + inner.Length(2) = 3
	assert(outer.Length:Get() == 3, "outer Length = contribution sum (3): " .. outer.Length:Get())
	assert(inner.Length:Get() == 2, "inner Length 2")
	-- growing inner bumps outer's contribution sum
	inner:Add(Instance.new("Frame"))
	assert(inner.Length:Get() == 3 and outer.Length:Get() == 4, "inner grow → outer sum 4: " .. outer.Length:Get())
	print("PASS")
end

print()
print("=== 9. 중첩 언마운트 — outer 언마운트가 inner까지 재귀로 뗀다 ===")
do
	local outer, inner = Slot(), Slot()
	inner:Add(Instance.new("Frame"))
	outer:Add(inner)
	local src = q.Source(outer)
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { src })
	assert(childCount(parent) == 1, "inner leaf mounted through outer")
	src:Set(nil)
	assert(childCount(parent) == 0, "outer unmount recurses into inner")
	assert(not outer._destroyed and not inner._destroyed, "unmount, not destroy")
	src:Set(outer)
	assert(childCount(parent) == 1, "nested remount (portal)")
	print("PASS")
end

print()
print("=== 10. :List — 키 기반 재조정(추가/갱신/제거/필터) ===")
do
	local data = q.Source({ { id = "a", n = 1 }, { id = "b", n = 2 } })
	local s = Slot()
	local built = {}
	s:List(data, function(item, _index, _off, prev, _ud)
		if item == q.KeyGone then return nil end
		if prev then return prev end -- reuse
		local f = Instance.new("Frame"); f.Name = item.id
		built[item.id] = (built[item.id] or 0) + 1
		return f
	end, function(item) return item.id end)
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { s })
	assert(childCount(parent) == 2, "2 items mounted: " .. childCount(parent))
	assert(built.a == 1 and built.b == 1, "each built once")
	-- add c, remove a
	data:Set({ { id = "b", n = 2 }, { id = "c", n = 3 } })
	assert(childCount(parent) == 2, "still 2 after add c / remove a")
	assert(built.b == 1, "b reused (not rebuilt)")
	assert(built.c == 1, "c built")
	print("PASS")
end

print()
print("=== 11. :Single(state) + Slot:Add(state) — State 요소 래핑 ===")
do
	local src = q.Source(Instance.new("Frame"))
	local s = Slot()
	s:Single(src)
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { s })
	assert(childCount(parent) == 1, ":Single mounts current state value")
	local newFrame = Instance.new("Frame")
	src:Set(newFrame)
	assert(childCount(parent) == 1 and newFrame.Parent == parent, "coarse swap to new value")
	src:Set(nil)
	assert(childCount(parent) == 0, "nil state → empty")
	-- Slot:Add(state) sugar (wrapElement path)
	local s2 = Slot()
	local st = q.Source(Instance.new("Frame"))
	s2:Add(st)
	local p2 = Instance.new("Folder")
	dispatch.drive(p2, { s2 })
	assert(childCount(p2) == 1, "Add(state) wraps + mounts")
	print("PASS")
end

print()
print("=== 12. Detach — 파괴 없이 뗐다 되붙임(재사용) ===")
do
	local show = q.Source(true)
	local data = q.Source({ { id = "x" } })
	local s = Slot()
	local theFrame
	local builds = 0
	s:List(data, function(item, _i, _o, prev, _ud)
		if item == q.KeyGone then return q.Detach end
		if not show:Get() then return q.Detach end
		if prev then return prev end
		builds += 1
		theFrame = Instance.new("Frame"); theFrame.Name = item.id
		return theFrame
	end, function(item) return item.id end)
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { s })
	assert(childCount(parent) == 1 and builds == 1, "built once, mounted")
	show:Set(false); data:Set({ { id = "x" } }) -- re-eval → Detach
	assert(childCount(parent) == 0, "detached from tree")
	assert(theFrame.Parent == nil and not mock.isDestroyed(theFrame), "detached, not destroyed")
	show:Set(true); data:Set({ { id = "x" } }) -- re-eval → prev returned → remount
	assert(childCount(parent) == 1 and builds == 1, "remounted same frame, no rebuild")
	print("PASS")
end

print()
print("=== 12b. 5순회 H-393 — Detach된 Owned=false 요소 Slot을 settle이 nil로 버릴 때 소유권을 먼저 놓는다(죽은 owner가 영구히 남던 것) ===")
do
	local show, drop = q.Source(true), q.Source(false)
	local data = q.Source({ { id = "x" } })
	local sub = Slot()
	sub:List(q.Source({ { id = "a" } }), function(item, _i, _o, prev)
		if item == q.KeyGone then return nil end
		if prev then return prev end
		local f = Instance.new("Frame"); f.Name = item.id; return f
	end, function(item) return item.id end, { Owned = false })
	local outer = Slot()
	outer:List(data, function(item, _i, _o, prev)
		if item == q.KeyGone then return q.Detach end
		if not show:Get() then return q.Detach end
		if drop:Get() then return nil end -- settle drops the detached prev → releaseElement(wasDetached)
		return prev or sub
	end, function(item) return item.id end)
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { outer })
	assert(childCount(parent) == 1, "sub mounted through outer")
	show:Set(false); data:Set({ { id = "x" } }) -- Detach
	drop:Set(true); show:Set(true); data:Set({ { id = "x" } }) -- key back, updateFn returns nil → dropped
	assert(childCount(parent) == 0, "dropped")
	-- sub is Owned=false: it survives its parent — and must be mountable again
	local other = Slot()
	other:Add(sub)
	dispatch.drive(Instance.new("Folder"), { other })
	assert(other:Get(1) == sub, "the surviving Owned=false Slot remounts elsewhere (owner released)")
	print("PASS")
end

print()
print("=== 13. :List 상호배타 가드 — CRUD 후 :List, :List 후 CRUD 금지 ===")
do
	local s1 = Slot(); s1:Add(Instance.new("Frame"))
	assert(not pcall(function() s1:List(q.Source({}), function() end) end), "no :List after manual CRUD")
	local s2 = Slot(); s2:List(q.Source({}), function() end)
	assert(not pcall(function() s2:Add(Instance.new("Frame")) end), "no manual CRUD after :List")
	-- 4순회 `H-385`: the same gates through the `:Single` sugar blame the user's
	-- `:Single(...)` line, not Single's delegation to `:List` inside Slot/List.luau
	local _, errS1 = pcall(function() s1:Single(q.Source(nil)) end)
	assert(string.find(tostring(errS1), ":List/:Single on a manual Slot", 1, true) ~= nil, "Single after CRUD is the same gate, and the message names both entries: " .. tostring(errS1))
	mock.assertBlamesUser(errS1, "spec.slot.luau", "Single-after-CRUD blame")
	local s3 = Slot(); s3:Single(q.Source(nil))
	local _, errS2 = pcall(function() s3:Single(q.Source(nil)) end)
	assert(string.find(tostring(errS2), "already has :List/:Single installed", 1, true) ~= nil, "Single twice is the same gate: " .. tostring(errS2))
	mock.assertBlamesUser(errS2, "spec.slot.luau", "Single-twice blame")
	print("PASS")
end

print()
print("=== 14. :List 리오더 — State 요소(래퍼 Slot)의 Offset이 자기 자리를 따라간다 ===")
do
	-- advisor §1: rawMove must permute sourceList too. State elements produce
	-- wrapper Slots (non-None sourceList entries) — plain-element test 10 can't
	-- see a missing permutation. Stable keys, reversed data order.
	local sx = q.Source(Instance.new("Frame"))
	local sy = q.Source(Instance.new("Frame"))
	local data = q.Source({ { id = "x", s = sx }, { id = "y", s = sy } })
	local s = Slot()
	s:List(data, function(item, _i, _o, prev, _ud)
		if item == q.KeyGone then return nil end
		if prev then return prev end
		return item.s -- a State element → wrapElement makes a wrapper Slot
	end, function(item) return item.id end)
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { s })
	-- x at slotPos 1 (Offset 0), y at slotPos 2 (Offset 1)
	local wx = s._elements[1]
	local wy = s._elements[2]
	assert(q.isSlot(wx) and q.isSlot(wy), "both wrapped")
	assert(wx.Offset:Get() == 0 and wy.Offset:Get() == 1, "initial offsets 0,1: " .. wx.Offset:Get() .. "," .. wy.Offset:Get())
	-- reverse order → y should move to pos 1 (Offset 0), x to pos 2 (Offset 1)
	data:Set({ { id = "y", s = sy }, { id = "x", s = sx } })
	-- the SAME wrapper Slots must be reused (reorder, not rebuild)
	assert(s._elements[1] == wy and s._elements[2] == wx, "reordered same wrappers")
	assert(wy.Offset:Get() == 0, "y moved to Offset 0: " .. wy.Offset:Get())
	assert(wx.Offset:Get() == 1, "x moved to Offset 1: " .. wx.Offset:Get())
	print("PASS")
end

print()
print("=== 15. :List Slot의 언마운트→재마운트(H-163) — 상태 보존 + 캐치업 1회 ===")
do
	local builds = 0
	local data = q.Source({ { id = "a" }, { id = "b" } })
	local list = Slot()
	list:List(data, function(item, _i, _o, prev, _ud)
		if item == q.KeyGone then return nil end
		if prev then return prev end
		builds += 1
		local f = Instance.new("Frame"); f.Name = item.id
		return f
	end, function(item) return item.id end)
	local src = q.Source(list)
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { src })
	assert(childCount(parent) == 2 and builds == 2, "initial mount, 2 built")
	-- (a) unmount
	src:Set(nil)
	assert(childCount(parent) == 0 and not list._destroyed, "unmounted, not destroyed")
	-- (c) data changes WHILE unmounted
	data:Set({ { id = "a" }, { id = "b" }, { id = "c" } })
	-- (a) remount — no error, (b) state preserved (a,b not rebuilt), (c) caught up
	src:Set(list)
	assert(childCount(parent) == 3, "remounted + caught up to 3: " .. childCount(parent))
	assert(builds == 3, "only c built on catch-up (a,b preserved): builds=" .. builds)
	print("PASS")
end

print()
print("=== 16. 통합 리뷰 — 이름 키의 Slot은 매치 안 됨(H-52, 소유권·생명주기 고아 없음) + :List keyFn nil은 도메인 에러 ===")
do
	local parent = Instance.new("Folder")
	local s = Slot()
	local ok, err = pcall(function()
		dispatch.drive(parent, { Text = s })
	end)
	assert(not ok, "a Slot at a NAME key must not be handled")
	assert(string.find(tostring(err), "position must be a positive integer", 1, true) == nil, "must fail as a dispatch match error, not an internal bookkeeping error: " .. tostring(err))
	assert(q.canBound(s) == true, "no orphaned lifetime bind (claim/bind must not have committed)")

	local data = q.Source({ { id = "a" }, { n = 2 } })
	local s2 = Slot()
	local ok2, err2 = pcall(function()
		s2:List(data, function(item, _i, _o, prev)
			if item == q.KeyGone then return nil end
			return prev or Instance.new("Frame")
		end, function(item) return item.id end)
		dispatch.drive(Instance.new("Folder"), { s2 }) -- reconcile runs on mount
	end)
	assert(not ok2 and string.find(tostring(err2), "keyFn returned nil", 1, true) ~= nil, "domain error instead of raw 'table index is nil': " .. tostring(err2))
	mock.assertBlamesUser(err2, "spec.slot.luau", "keyFn nil blame")
	print("PASS")
end

-- ── M6 잔여 마감(2026-09-03, 메인) — 공개 CRUD 다섯 + collectLeaves + KeyGone 분기 ──

-- spy(name, fn): temporarily replace an injected op on `q` (Slot reads
-- `module.<op>` late — `H-174`), returning the captured call list.
local function spy(name, body)
	local orig, calls = q[name], {}
	q[name] = function(...)
		table.insert(calls, { ... })
		if orig then return orig(...) end
		return nil
	end
	body()
	q[name] = orig
	return calls
end

print()
print("=== 17. Move/Swap — 중첩 Slot 요소의 리프가 native*에 배열로 넘어가고(collectLeaves) 부기가 따라간다 ===")
do
	local s, inner = Slot(), Slot()
	local a = Instance.new("Frame"); a.Name = "a"
	local i1 = Instance.new("Frame"); i1.Name = "i1"
	local i2 = Instance.new("Frame"); i2.Name = "i2"
	local c = Instance.new("Frame"); c.Name = "c"
	inner:Add(i1); inner:Add(i2)
	s:Add(a); s:Add(inner); s:Add(c) -- leaves: a(0) i1(1) i2(2) c(3)
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { s })
	assert(inner.Offset:Get() == 1 and s.Length:Get() == 4, "initial layout")

	-- Move(2, 1): the nested block moves up — toOffset is where it lands (0)
	local moves = spy("nativeMove", function() s:Move(2, 1) end)
	assert(#moves == 1, "one nativeMove call")
	local m = moves[1]
	assert(m[1] == parent and m[2] == 1 and m[4] == 0, "nativeMove(target, fromOffset=1, leaves, toOffset=0): " .. tostring(m[2]) .. "," .. tostring(m[4]))
	assert(#m[3] == 2 and m[3][1] == i1 and m[3][2] == i2, "elements = flattened leaves of the nested Slot (collectLeaves)")
	assert(s:IndexOf(inner) == 1 and s:IndexOf(a) == 2, "reordered")
	assert(inner.Offset:Get() == 0, "inner Offset follows its new position: " .. inner.Offset:Get())
	assert(dispatch.getOffsetAt(s, 3) == 3, "c still at absolute 3")

	-- Move(1, 3): the block moves down past a(1) and c(1) → lands at 2
	moves = spy("nativeMove", function() s:Move(1, 3) end)
	assert(moves[1][2] == 0 and moves[1][4] == 2, "toOffset = post-move first-leaf offset (2): " .. tostring(moves[1][4]))
	assert(s:IndexOf(inner) == 3 and inner.Offset:Get() == 2, "inner now last, Offset 2: " .. inner.Offset:Get())

	-- Swap(1, 3): a(0) ↔ inner(2..3); the middle (c) stays
	local swaps = spy("nativeSwap", function() s:Swap(1, 3) end)
	local w = swaps[1]
	assert(w[2] == 0 and w[3][1] == a and w[4] == 2 and #w[5] == 2 and w[5][1] == i1, "nativeSwap(target, 0, {a}, 2, {i1,i2})")
	assert(s:IndexOf(inner) == 1 and s:IndexOf(c) == 2 and s:IndexOf(a) == 3, "swapped ends, middle fixed")
	assert(inner.Offset:Get() == 0 and dispatch.getOffsetAt(s, 3) == 3, "offsets after swap")

	-- Swap(i, i) is a no-op (no physical op); range errors are fail-fast
	assert(#spy("nativeSwap", function() s:Swap(2, 2) end) == 0, "Swap(i,i) no-op")
	assert(not pcall(function() s:Move(0, 1) end), "Move index 0 rejected")
	assert(not pcall(function() s:Swap(1, 9) end), "Swap out of range rejected")
	assert(not pcall(function() s:Move(1.5, 2) end), "non-integer index rejected")
	local _, err = pcall(function() s:Move(0, 1) end)
	mock.assertBlamesUser(err, "spec.slot.luau", "public CRUD argument error blames the caller (H-238)")
	assert(s.Length:Get() == 4 and childCount(parent) == 4, "nothing lost")
	print("PASS")
end

print()
print("=== 18. Extract/Replace — 비파괴 추출(소유권 반납), 제자리 교체, 파괴 교체, State 요소 언래핑 ===")
do
	local s = Slot()
	local a = Instance.new("Frame"); a.Name = "a"
	local b = Instance.new("Frame"); b.Name = "b"
	local c = Instance.new("Frame"); c.Name = "c"
	s:Add(a); s:Add(b); s:Add(c)
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { s })

	assert(s:Extract(2) == b, "Extract returns the element")
	assert(b.Parent == nil and not mock.isDestroyed(b), "extracted: out of the tree, alive")
	assert(s.Length:Get() == 2 and childCount(parent) == 2, "tail pulled in")
	assert(s:Add(b) == 3, "ownership was released — re-Add works")

	local d = Instance.new("Frame"); d.Name = "d"
	assert(s:Extract(1, d) == a, "Extract(index, new) returns the previous element")
	assert(a.Parent == nil and not mock.isDestroyed(a) and d.Parent == parent, "swapped in place, old alive")
	assert(s:Get(1) == d and s:Get(2) == c and s:Get(3) == b and s.Length:Get() == 3, "order d,c,b")

	local e = Instance.new("Frame"); e.Name = "e"
	s:Replace(1, e)
	assert(mock.isDestroyed(d) and e.Parent == parent and s:Get(1) == e, "Replace destroys the old occupant")
	assert(s.Length:Get() == 3 and childCount(parent) == 3, "position count unchanged")

	-- pre-pass: an already-mounted element is rejected before anything mutates
	local other = Slot(); local f = Instance.new("Frame"); other:Add(f)
	dispatch.drive(Instance.new("Folder"), { other })
	assert(not pcall(function() s:Replace(1, f) end), "Replace with a mounted element rejected")
	assert(s:Get(1) == e and not mock.isDestroyed(e), "rejected Replace mutated nothing")

	-- State element: Extract returns the unwrapped State, the instance is detached
	local g = Instance.new("Frame"); g.Name = "g"
	local st = q.Source(g)
	s:Add(st)
	assert(s:IndexOf(st) == 4 and g.Parent == parent, "state element mounted via wrapper")
	assert(s:Extract(4) == st, "Extract unwraps the State")
	assert(g.Parent == nil and not mock.isDestroyed(g), "user instance detached, alive")
	-- H6-12 (b): the discarded sugar wrapper released its claim — the State is
	-- re-addable right away (no GC dependence), and dispose(g) is allowed
	assert(s:Add(st) == 4 and g.Parent == parent, "re-Add(state) after Extract works (wrapper claim released)")
	assert(s:Extract(4) == st, "extract again")
	q.dispose(g)
	assert(mock.isDestroyed(g), "dispose(inst) allowed after the wrapper let go")
	-- Remove(state element): the wrapper is asked to die → user instance survives, unclaimed
	local h = Instance.new("Frame"); h.Name = "h"
	local sth = q.Source(h)
	s:Add(sth)
	s:Remove(s:IndexOf(sth))
	assert(not mock.isDestroyed(h) and h.Parent == nil, "Owned=false wrapper: Remove unmounts, does not destroy")
	local reclaim = Slot(); reclaim:Add(h)
	dispatch.drive(Instance.new("Folder"), { reclaim })
	assert(h.Parent ~= nil, "the instance is claimable elsewhere after the wrapper died")
	print("PASS")
end

print()
print("=== 19. Splice — 구간 비파괴 추출 + 삽입, recompute 1회, 검증 선행 패스(반쪽 상태 없음) ===")
do
	local s = Slot()
	local a, b, c, d = Instance.new("Frame"), Instance.new("Frame"), Instance.new("Frame"), Instance.new("Frame")
	a.Name, b.Name, c.Name, d.Name = "a", "b", "c", "d"
	s:Add(a); s:Add(b); s:Add(c); s:Add(d)
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { s })
	local x, y, z = Instance.new("Frame"), Instance.new("Frame"), Instance.new("Frame")
	x.Name, y.Name, z.Name = "x", "y", "z"

	local recomputes = 0
	local bkTable = q._bookkeeping
	local origRecompute = bkTable.recompute
	bkTable.recompute = function(...) recomputes += 1; return origRecompute(...) end
	local removed
	local inserts
	local extracts = spy("nativeExtract", function()
		inserts = spy("nativeInsert", function()
			removed = s:Splice(2, 2, x, y, z)
		end)
	end)
	bkTable.recompute = origRecompute
	assert(#removed == 2 and removed[1] == b and removed[2] == c, "removed span returned in order")
	assert(b.Parent == nil and not mock.isDestroyed(b) and c.Parent == nil and not mock.isDestroyed(c), "removed alive")
	assert(s:Get(1) == a and s:Get(2) == x and s:Get(3) == y and s:Get(4) == z and s:Get(5) == d, "a,x,y,z,d")
	assert(s.Length:Get() == 5 and childCount(parent) == 5, "5 mounted")
	assert(recomputes == 1, "one explicit recompute for the whole splice (batched): " .. recomputes)
	-- H6-9 (b): ONE physical op — nativeExtract(target, offset, removed, new)
	assert(#extracts == 1 and #inserts == 0, "exactly one nativeExtract, no nativeInsert: " .. #extracts .. "/" .. #inserts)
	local e = extracts[1]
	assert(e[1] == parent and e[2] == 1, "offset of the span (1): " .. tostring(e[2]))
	assert(#e[3] == 2 and e[3][1] == b and e[3][2] == c, "removed leaves in order")
	assert(#e[4] == 3 and e[4][1] == x and e[4][2] == y and e[4][3] == z, "new leaves in order")
	assert(dispatch.getOffsetAt(s, 5) == 4, "offsets settled after the batch")

	-- nested Slots on both sides still fold into the one op (collectLeaves)
	local inner = Slot(); local i1, i2 = Instance.new("Frame"), Instance.new("Frame")
	inner:Add(i1); inner:Add(i2)
	local w = Instance.new("Frame")
	local ex2 = spy("nativeExtract", function() s:Splice(2, 2, inner, w) end) -- removes x,y; inserts inner{i1,i2}, w
	assert(#ex2 == 1 and #ex2[1][3] == 2 and #ex2[1][4] == 3 and ex2[1][4][1] == i1 and ex2[1][4][3] == w, "nested leaves flattened into the single op")
	assert(inner._mounted and inner._mountedInst == parent and inner.Offset:Get() == 1, "new nested Slot marked mounted at its offset")
	assert(s.Length:Get() == 6 and childCount(parent) == 6, "6 leaves")
	-- pure insertion (removeCount 0) is one nativeInsert; pure removal one nativeExtract
	local ins = spy("nativeInsert", function() s:Splice(1, 0, Instance.new("Frame")) end)
	assert(#ins == 1 and ins[1][2] == 0, "removeCount 0 → one nativeInsert at the span offset")
	local ex3 = spy("nativeExtract", function() s:Splice(1, 1) end)
	assert(#ex3 == 1 and ex3[1][4] == nil, "no new elements → nativeExtract without newElements")

	-- insertion at the end (index n+1, removeCount 0) is the Add-like range
	local n, L = #s._elements, s.Length:Get() -- positions vs leaves (inner holds 2)
	assert(#s:Splice(n + 1, 0, Instance.new("Frame")) == 0 and s.Length:Get() == L + 1, "append via Splice")
	assert(not pcall(function() s:Splice(n + 3, 0) end), "index n+2 rejected")
	assert(not pcall(function() s:Splice(n, 3) end), "removeCount past the end rejected")
	assert(not pcall(function() s:Splice(1, -1) end), "negative removeCount rejected")

	-- pre-pass: the LAST new element is bad → nothing at all changes (H-30/H-31)
	local p, mountedElsewhere = Instance.new("Frame"), Instance.new("Frame")
	local other = Slot(); other:Add(mountedElsewhere)
	dispatch.drive(Instance.new("Folder"), { other })
	local before = childCount(parent)
	assert(not pcall(function() s:Splice(1, 1, p, mountedElsewhere) end), "mounted element in the batch rejected")
	assert(childCount(parent) == before and s:Get(1) == a and p.Parent == nil, "half-applied state prevented")
	assert(not pcall(function() s:Splice(1, 0, p, p) end), "duplicate within the batch rejected")
	assert(not pcall(function() s:Splice(1, 0, p, nil, p) end), "nil hole in the vararg rejected")
	assert(childCount(parent) == before, "still untouched")
	print("PASS")
end

print()
print("=== 20. KeyGone 처분 세 갈래 — nil(파괴) / Detach(홀드→재마운트) / 새 값(error), Owned=false는 언마운트만 ===")
do
	local frames, builds = {}, 0
	local data = q.Source({ { id = "a" }, { id = "b" } })
	local goneReply = "nil" -- what updateFn returns for KeyGone
	local s = Slot()
	s:List(data, function(item, _i, _o, prev, _ud)
		if item == q.KeyGone then
			if goneReply == "nil" then return nil end
			if goneReply == "detach" then return q.Detach end
			return Instance.new("Frame") -- a NEW value on KeyGone is a contract error
		end
		if prev then return prev end
		builds += 1
		local f = Instance.new("Frame"); f.Name = item.id
		frames[item.id] = f
		return f
	end, function(item) return item.id end)
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { s })
	assert(childCount(parent) == 2 and builds == 2, "initial")

	-- (1) nil → destroyed
	data:Set({ { id = "b" } })
	assert(mock.isDestroyed(frames.a) and childCount(parent) == 1, "KeyGone→nil destroys")

	-- (2) Detach → held (alive, out of the tree), key returns → the SAME frame remounts
	goneReply = "detach"
	data:Set({})
	assert(not mock.isDestroyed(frames.b) and frames.b.Parent == nil and childCount(parent) == 0, "KeyGone→Detach holds")
	assert(s._detached and s._detached.b == frames.b, "held in slot._detached")
	data:Set({ { id = "b" } })
	assert(childCount(parent) == 1 and frames.b.Parent == parent and builds == 2, "remounted the held frame, no rebuild")

	-- (3) a new value on KeyGone → error
	goneReply = "new"
	assert(not pcall(function() data:Set({}) end), "KeyGone accepts only nil/None/Detach")

	-- Owned = false: the user's frames are never destroyed, only unmounted
	local u1 = Instance.new("Frame"); u1.Name = "u1"
	local udata = q.Source({ { id = "u1", f = u1 } })
	local us = Slot()
	us:List(udata, function(item, _i, _o, prev, _ud)
		if item == q.KeyGone then return nil end
		return prev or item.f
	end, function(item) return item.id end, { Owned = false })
	local uparent = Instance.new("Folder")
	dispatch.drive(uparent, { us })
	assert(u1.Parent == uparent, "user frame mounted")
	udata:Set({})
	assert(not mock.isDestroyed(u1) and u1.Parent == nil and childCount(uparent) == 0, "Owned=false: KeyGone→nil unmounts only")
	-- and the element is free again (ownership released on the way out)
	local reuse = Slot(); reuse:Add(u1)
	dispatch.drive(Instance.new("Folder"), { reuse })
	assert(u1.Parent ~= nil, "unowned element reusable after leaving the list")
	print("PASS")
end

print()
print("=== 21. 실체화 전 CRUD — Move/Swap/Splice/Extract가 _elements만 만지고, 마운트 때 그 순서대로 선다 ===")
do
	local s = Slot()
	local a, b, c, d = Instance.new("Frame"), Instance.new("Frame"), Instance.new("Frame"), Instance.new("Frame")
	a.Name, b.Name, c.Name, d.Name = "a", "b", "c", "d"
	s:Add(a); s:Add(b); s:Add(c)
	s:Move(3, 1) -- c,a,b
	s:Swap(2, 3) -- c,b,a
	assert(s:Extract(2) == b, "Extract before mount") -- c,a
	local removed = s:Splice(2, 1, d, b) -- c,d,b
	assert(removed[1] == a and s:Get(1) == c and s:Get(2) == d and s:Get(3) == b, "c,d,b")
	assert(s.Length:Get() == 0, "Length is 0 until mount (H6-4)")
	local parent = Instance.new("Folder")
	local calls = spy("nativeMove", function() dispatch.drive(parent, { s }) end)
	assert(#calls == 0, "no reposition op replayed at mount")
	assert(s.Length:Get() == 3 and childCount(parent) == 3, "mounted in the final order")
	assert(dispatch.getOffsetAt(s, 1) == 0 and dispatch.getOffsetAt(s, 3) == 2, "offsets from the final layout")
	assert(a.Parent == nil and not mock.isDestroyed(a), "spliced-out element alive, unmounted")
	print("PASS")
end

print()
print("=== 22. 통합 리뷰(H6-19) — 선행 검증이 raw 값을 본다·파괴된 Slot 요소·언마운트 부기 리셋·생성자 blame ===")
do
	-- (a) a destroyed Slot as a new element fails in the pre-pass — the batch
	-- gate must not be left On by a raise inside rawSplice
	local s = Slot()
	local a, b = Instance.new("Frame"), Instance.new("Frame")
	s:Add(a); s:Add(b)
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { s })
	local dead = Slot(); q.dispose(dead)
	assert(not pcall(function() s:Splice(1, 0, dead) end), "destroyed Slot element rejected")
	assert(not dispatch.getBlocker(s):IsOn(), "batch gate NOT left On")
	assert(#s._elements == 2 and s.Length:Get() == 2, "nothing mutated")
	s:Add(Instance.new("Frame"))
	assert(s.Length:Get() == 3 and childCount(parent) == 3, "bookkeeping still alive after the rejected Splice")

	-- (b) State elements: the same State twice, or a State whose current value
	-- is mounted elsewhere, are rejected BEFORE any mutation (raw-value checks)
	local f = Instance.new("Frame")
	local st = q.Source(f)
	assert(not pcall(function() s:Splice(1, 0, st, st) end), "same State twice rejected")
	assert(#s._elements == 3 and childCount(parent) == 3, "no half-applied wrapper")
	local elsewhere = Slot(); elsewhere:Add(st)
	dispatch.drive(Instance.new("Folder"), { elsewhere })
	assert(f.Parent ~= nil, "st's value mounted elsewhere")
	assert(not pcall(function() s:Add(st) end), "Add(State) whose value is mounted elsewhere rejected")
	assert(not pcall(function() s:Splice(1, 0, Instance.new("Frame"), st) end), "…and inside a Splice batch")
	assert(#s._elements == 3 and childCount(parent) == 3, "still untouched")

	-- (c) nested Slot extracted, mutated while unmounted, re-added: Length and
	-- sibling offsets come from the CURRENT elements, not the old mount's N
	local p, child = Slot(), Slot()
	local pa, pc = Instance.new("Frame"), Instance.new("Frame")
	child:Add(Instance.new("Frame")); child:Add(Instance.new("Frame")); child:Add(Instance.new("Frame"))
	p:Add(pa); p:Add(child); p:Add(pc)
	local pp = Instance.new("Folder")
	dispatch.drive(pp, { p })
	assert(p.Length:Get() == 5, "5 leaves")
	assert(p:Extract(2) == child, "nested Slot extracted alive")
	child:Remove(3) -- while unmounted
	p:Add(child)
	assert(child.Length:Get() == 2, "child Length from current elements: " .. child.Length:Get())
	assert(p.Length:Get() == 4 and childCount(pp) == 4, "parent Length 4: " .. p.Length:Get())
	assert(child.Offset:Get() == 2, "re-added at the end → offset 2: " .. child.Offset:Get())

	-- (d) `Slot{bad}` blames the user's line, not the constructor's Add call
	local _, err = pcall(function() return Slot({ 123 }) end)
	mock.assertBlamesUser(err, "spec.slot.luau", "constructor element error blames the caller (H-238)")
	-- (e) 2순회 `H-375`: the element-type gate raised by a direct CRUD call made
	-- INSIDE a reactive callback blames the CRUD line, not the `:Set` that ran
	-- the callback (nearest, like the sibling "appears twice" check) — the
	-- reconcile-depth path (`settle`) keeps outermost blame (1절 위 drive 단언)
	local src = q.Source(0)
	local s2 = Slot({})
	local lineAdd = 0
	local okN, errN = pcall(function()
		-- the Observer's initial run happens under THIS call, not under a `:Set`
		local o = src:Observer(function()
			lineAdd = (debug.info(1, "l") :: number) + 1
			s2:Add(nil)
		end)
		o:Subscribe()
	end)
	assert(not okN and string.find(tostring(errN), "nil/None cannot be an element", 1, true) ~= nil, "gate fired: " .. tostring(errN))
	assert(string.find(tostring(errN), `spec.slot.luau:{lineAdd}:`, 1, true) ~= nil, "nested direct CRUD blames its own line, not the Subscribe/Set that ran the callback: " .. tostring(errN))
	print("PASS")
end

print()
print("=== 22b. 4순회 H-386 — Slot(initial)의 컨테이너 모양 게이트: 잊은 {}·quad 값·해시 테이블이 요소 0개로 통과해 :List를 잠그던 것 ===")
do
	local frame = Instance.new("Frame")
	for label, bad in { bareElement = frame, slotValue = Slot(), tagValue = q.Tag("x"), source = q.Source(1), hash = { gamma = frame }, str = "s", zeroKey = { [0] = frame }, fracKey = { [1.5] = frame } } :: { [string]: any } do
		local ok, err = pcall(function() return Slot(bad) end)
		assert(not ok and string.find(tostring(err), "initial elements must be", 1, true) ~= nil, label .. " rejected at construction: " .. tostring(err))
		mock.assertBlamesUser(err, "spec.slot.luau", label .. " blame")
	end
	-- positive: a real array (and an empty one) — and a nil hole stays UB (ipairs stops), not an error
	assert(Slot({}):Get(1) == nil and Slot({ frame }):Get(1) == frame, "arrays still construct")
	local holed = Slot({ Instance.new("Frame"), nil, Instance.new("Frame") })
	assert(holed:Get(1) ~= nil and holed:Get(2) == nil, "nil hole: ipairs stops (slot-plan UB), no gate")
	print("PASS")
end

print()
print("=== 23. 회신 반영 리뷰(H6-24) — 점유자 단위 dedup: 같은 Instance를 든 State 둘·raw+State, 마운트 전 aliasing, 미실체화 Extract(i,new)의 래퍼 반납 ===")
do
	-- (a) two States over one instance inside one Splice: rejected in the
	-- pre-pass (no half-applied array, gate not left On)
	local s = Slot()
	s:Add(Instance.new("Frame"))
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { s })
	local f = Instance.new("Frame")
	assert(not pcall(function() s:Splice(2, 0, q.Source(f), q.Source(f)) end), "two States over one instance rejected")
	assert(not pcall(function() s:Splice(2, 0, f, q.Source(f)) end), "raw + State over the same instance rejected")
	assert(#s._elements == 1 and childCount(parent) == 1 and not dispatch.getBlocker(s):IsOn(), "nothing mutated, gate open")
	s:Add(Instance.new("Frame"))
	assert(s.Length:Get() == 2, "still reactive")

	-- (b) aliasing States added BEFORE mount (materializeSlotTree variant):
	-- the second Add already sees the first wrapper's occupant
	local u = Slot()
	local g = Instance.new("Frame")
	u:Add(q.Source(g))
	assert(not pcall(function() u:Add(q.Source(g)) end), "second State over the same instance rejected before mount")
	local up = Instance.new("Folder")
	dispatch.drive(up, { u })
	assert(childCount(up) == 1 and u.Length:Get() == 1, "mounts cleanly")

	-- (c) unmaterialized Extract(i, new) on a previously mounted nested Slot
	-- releases the outgoing sugar wrapper's claim
	local outer, p = Slot(), Slot()
	local x, h = Instance.new("Frame"), Instance.new("Frame")
	local st = q.Source(h)
	p:Add(x); p:Add(st)
	outer:Add(p)
	dispatch.drive(Instance.new("Folder"), { outer })
	assert(outer:Extract(1) == p and p._physicalTarget == nil, "p alive, unmaterialized")
	assert(p:Extract(2, Instance.new("Frame")) == st, "Extract(i, new) returns the State")
	q.dispose(h)
	assert(mock.isDestroyed(h), "the wrapper let go of h (dispose allowed)")
	print("PASS")
end

print("=== 24. 회신 3차(2026-09-07) — Q9 (b) 마운트 대상이 quad 밖에서 Destroy된 Slot은 죽은 것(메시지가 그렇게 말한다), Q14 (a) destroySlotTree가 Owned=false 자식의 소유권을 놓는다, G-11 List 인자 게이트 ===")
do
	-- Q9: zombie — the two messages name the cause
	local frame = mock.Instance.new("Frame")
	local s = q.Slot()
	s:Add(mock.Instance.new("Frame"))
	q.Dispatch.drive(frame, { s })
	frame:Destroy()
	local okD, errD = pcall(function() q.dispose(s) end)
	assert(not okD and string.find(tostring(errD), "destroyed outside quad", 1, true) ~= nil, "dispose names the destroyed-owner case: " .. tostring(errD))
	local okA, errA = pcall(function() q.Slot():Add(s) end)
	assert(not okA and string.find(tostring(errA), "cannot be reused after its parent is destroyed", 1, true) ~= nil, "Add names the destroyed-owner case: " .. tostring(errA))
	-- Q14: an Owned=false child Slot survives its parent's destruction AND is free again
	local parent = q.Slot()
	local child = q.Slot()
	child:List({ 1 }, function(_item, _index, _offset, _prev)
		return mock.Instance.new("Frame")
	end, nil, { Owned = false })
	parent:Add(child)
	local host = mock.Instance.new("Frame")
	local holder = q.Source(parent :: any)
	q.Dispatch.drive(host, { holder })
	holder:Set(nil) -- unmount (retract)
	q.dispose(parent) -- destroySlotTree(parent): child is Owned=false → unmount-only, must be released
	assert(not child._destroyed, "Owned=false child survives (S-07 / slot-plan)")
	q.Slot():Add(child) -- used to raise "already mounted elsewhere" (dead elementOwner)
	-- G-11: List argument gates blame the caller, not Slot/List.luau
	local okL, errL = pcall(function() q.Slot():List(nil :: any, function() end) end)
	assert(not okL and string.find(tostring(errL), "data must be a plain array", 1, true) ~= nil, "nil data: " .. tostring(errL))
	mock.assertBlamesUser(errL, "spec.slot.luau", "List nil data blame")
	local okF, errF = pcall(function() q.Slot():List({}, "x" :: any) end)
	assert(not okF and string.find(tostring(errF), "updateFn must be a function", 1, true) ~= nil, "non-function updateFn: " .. tostring(errF))
	mock.assertBlamesUser(errF, "spec.slot.luau", "List updateFn blame")
	-- round3 `H-446`: the same gates on Single's updateFn, List's keyFn, and branded "data"
	local okS, errS = pcall(function() q.Slot():Single(nil, 42 :: any) end)
	assert(not okS and string.find(tostring(errS), "Slot:Single: updateFn must be a function", 1, true) ~= nil, "Single updateFn: " .. tostring(errS))
	mock.assertBlamesUser(errS, "spec.slot.luau", "Single updateFn blame")
	local okK, errK = pcall(function() q.Slot():List({}, function() end, "id" :: any) end)
	assert(not okK and string.find(tostring(errK), "keyFn must be a function", 1, true) ~= nil, "keyFn: " .. tostring(errK))
	local okN, errN = pcall(function() q.Slot():List(q.None :: any, function() end) end)
	assert(not okN and string.find(tostring(errN), "plain array", 1, true) ~= nil, "None is not an array: " .. tostring(errN))
	print("PASS")
end

print("=== 25. Gemini 5차 G-16/G-20 — :Single의 None은 nil과 같다(Q30, H-467): KeyGone 언마운트; Slot:Get(nil)은 에러(Q32, H-468), 범위 밖은 여전히 nil ===")
do
	local src = q.Source(Instance.new("Frame"))
	local s = Slot()
	local gone = 0
	s:Single(src, function(item, off, prev, ud)
		if item == q.KeyGone then gone += 1; return nil end
		assert(item ~= q.None, "None must never reach updateFn as an item")
		return item
	end)
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { s })
	assert(childCount(parent) == 1, ":Single mounts")
	src:Set(q.None)
	assert(childCount(parent) == 0 and gone == 1, "None → empty + KeyGone once: " .. childCount(parent) .. "/" .. gone)
	src:Set(Instance.new("Frame"))
	assert(childCount(parent) == 1, "re-set after None mounts again")
	-- plain None at install
	local s2 = Slot()
	s2:Single(q.None)
	local p2 = Instance.new("Folder")
	dispatch.drive(p2, { s2 })
	assert(childCount(p2) == 0, "plain None installs empty")
	-- Get(nil) is an error, out-of-range still nil
	local s3 = Slot({ Instance.new("Frame") })
	local ok, err = pcall(function() return s3:Get(nil) end)
	assert(not ok and string.find(tostring(err), "Slot:Get: index must be a number (got nil)", 1, true) ~= nil, "Get(nil) errors: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.slot.luau", "Get(nil) blame")
	assert(s3:Get(2) == nil, "out-of-range stays nil (SlotItem<T>?)")
	print("PASS")
end


print()
print("=== 26. 자문 RFC(2026-09-08) — Clear/ExtractAll은 배치 한 번의 recompute(H-479), IndexOf는 역맵 경유·State 요소는 언랩 폴백(H-481), List의 KeyGone 사이클(H-480 clone 제거, H-485 증분 집합 유지) ===")
do
	local s = Slot()
	local a, b, c = Instance.new("Frame"), Instance.new("Frame"), Instance.new("Frame")
	local inner = Slot({ Instance.new("Frame"), Instance.new("Frame") })
	s:Add(a); s:Add(inner); s:Add(b)
	local parent = Instance.new("Folder")
	dispatch.drive(parent, { s })
	assert(childCount(parent) == 4, "4 leaves mounted: " .. childCount(parent))
	assert(s:IndexOf(inner) == 2 and s:IndexOf(b) == 3, "IndexOf answers the current positions")
	local map = dispatch.getBookkeeping(s).indexOfElement
	assert(map[inner] == 2 and map[b] == 3, "the reverse map itself holds them (the O(1) path is real, not the scan fallback)")
	local st = q.Source(c)
	s:Add(st)
	assert(s:IndexOf(st) == 4, "a State element is found by unwrapping its sugar wrapper")
	assert(s:IndexOf(c) == nil, "the State's VALUE is not a member")
	assert(s:IndexOf(Instance.new("Frame")) == nil, "non-member → nil")

	-- ExtractAll: one recompute for the whole batch — Length lands on 0 in ONE emit
	local emits = 0
	s.Length:Observer(function() emits += 1 end):Subscribe() -- runs at create + Subscribe; count from here
	emits = 0
	local out = s:ExtractAll()
	assert(#out == 4 and out[1] == a and out[2] == inner and out[3] == b and out[4] == st, "order preserved; the State element comes back as the State")
	assert(emits == 1, "exactly one Length emit for ExtractAll: " .. emits)
	assert(childCount(parent) == 0 and s.Length:Get() == 0 and #s._elements == 0, "everything extracted")
	assert(a.Parent == nil and not mock.isDestroyed(a) and not inner._destroyed, "extracted alive, not destroyed")
	local again = Slot()
	again:Add(a); again:Add(inner)
	local parent2 = Instance.new("Folder")
	dispatch.drive(parent2, { again })
	assert(childCount(parent2) == 3, "extracted elements are reusable elsewhere: " .. childCount(parent2))

	-- Clear: same batch, destroys
	local s2 = Slot()
	local x, y = Instance.new("Frame"), Instance.new("Frame")
	local inner2 = Slot({ Instance.new("Frame") })
	s2:Add(x); s2:Add(inner2); s2:Add(y)
	local parent3 = Instance.new("Folder")
	dispatch.drive(parent3, { s2 })
	local emits2 = 0
	s2.Length:Observer(function() emits2 += 1 end):Subscribe()
	emits2 = 0
	s2:Clear()
	assert(emits2 == 1, "exactly one Length emit for Clear: " .. emits2)
	assert(childCount(parent3) == 0 and mock.isDestroyed(x) and mock.isDestroyed(y) and inner2._destroyed, "Clear destroys elements and nested Slots")
	s2:Clear() -- empty: no-op, no error
	assert(s2.Length:Get() == 0 and emits2 == 1, "Clear on an empty Slot is a no-op")

	-- pre-materialization forms (no batch gate — no bookkeeping yet)
	local s3 = Slot({ Instance.new("Frame"), Instance.new("Frame") })
	local out3 = s3:ExtractAll()
	assert(#out3 == 2 and #s3._elements == 0, "unmaterialized ExtractAll")
	local s4 = Slot({ Instance.new("Frame") })
	s4:Clear()
	assert(#s4._elements == 0 and out3[1].Parent == nil, "unmaterialized Clear")

	-- :List KeyGone across cycles still works with the prevKeys swap (`H-480`):
	-- a key gone in cycle 2 is asked once, and not again in cycle 3
	local data = q.Source({ { id = "a" }, { id = "b" } })
	local gone = {}
	local ls = Slot()
	ls:List(data, function(item, _i, _o, prev)
		if item == q.KeyGone then gone[#gone + 1] = prev.Name; return nil end
		if prev then return prev end
		local f = Instance.new("Frame"); f.Name = item.id
		return f
	end, function(item) return item.id end)
	local parent4 = Instance.new("Folder")
	dispatch.drive(parent4, { ls })
	data:Set({ { id = "b" } })
	assert(#gone == 1 and gone[1] == "a" and childCount(parent4) == 1, "a asked once on KeyGone")
	data:Set({ { id = "b" }, { id = "c" } })
	assert(#gone == 1, "a is not asked again in the next cycle")
	data:Set({})
	assert(#gone == 3 and childCount(parent4) == 0, "b and c gone: " .. #gone)
	print("PASS")
end

print()
print()
print("=== 27. 2026-09-08 2차 감사 H-500 — 자기 자신·조상을 요소로 넣는 순환은 선행 검증이 거부(옛: 다음 CRUD에서 스택오버플로/내부 불변식 에러) ===")
do
	local q = mock.newQuad()
	local s = q.Slot()
	local ok, err = pcall(function() return s:Add(s) end)
	assert(not ok and string.find(tostring(err), "Slot:Add: cannot add a Slot to itself or to one of its own descendants", 1, true) ~= nil, "self: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.slot.luau", "cycle gate")
	assert(s.Length:Get() == 0 and s:IndexOf(s) == nil, "nothing was added")
	local a, b, c = q.Slot(), q.Slot(), q.Slot()
	a:Add(b); b:Add(c)
	local ok2, err2 = pcall(function() return c:Add(a) end) -- a is c's grandparent
	assert(not ok2 and string.find(tostring(err2), "cycle", 1, true) ~= nil, "ancestor: " .. tostring(err2))
	local ok3, err3 = pcall(function() return b:Splice(1, 0, a) end) -- Splice path shares the pre-pass
	assert(not ok3 and string.find(tostring(err3), "Slot:Splice: cannot add a Slot", 1, true) ~= nil, "splice: " .. tostring(err3))
	-- a sibling (not on the owner chain) is still fine, and so is a fresh Slot
	local d = q.Slot()
	c:Add(d)
	assert(a.Length:Get() == 0 and c:IndexOf(d) == 1, "legal nesting untouched")
	-- the gate does not disturb the pre-pass's other checks: a mounted element is still "already mounted"
	local ok4 = pcall(function() return d:Add(c) end) -- c is d's parent AND already owned by b: the older "already mounted" gate fires first
	assert(not ok4, "parent rejected (by the mounted gate, which runs before the cycle walk)")
	print("PASS")
end

print()
print("=== 28. 2026-09-08 round8 H-505/H-506 — Move 뒤 역맵은 회전 구간만 다시 쓰고도 정확, 생성자는 배치 선행 패스 한 번(Slot{ a, a } 거부 유지) ===")
do
	local q = mock.newQuad()
	local s = q.Slot()
	local f = {}
	for i = 1, 8 do f[i] = mock.Instance.new("Frame"); s:Add(f[i]) end
	local function check(label: string)
		for i = 1, 8 do
			local e = s:Get(i)
			assert(s:IndexOf(e) == i, `{label}: IndexOf(e{i}) == {i} (got {tostring(s:IndexOf(e))})`)
		end
	end
	s:Move(2, 6); check("move up")
	s:Move(7, 1); check("move down")
	s:Move(4, 4); check("no-op move")
	s:Move(1, 8); check("front to back")
	s:Swap(3, 5); check("swap")
	-- mounted + nested (round8 O-7): the consumer that could go wrong is gatedRecompute's
	-- `indexOfElement[element]` — a one-off there silently miscomputes offsets. Six child
	-- Slots of lengths 1..6 under a mounted root; permute and check every child's Offset
	-- against a prefix sum, plus the root Length.
	local root = q.Slot()
	local kids = {}
	for i = 1, 6 do
		local c = q.Slot()
		for _ = 1, i do c:Add(mock.Instance.new("Frame")) end
		kids[i] = c; root:Add(c)
	end
	local parent = mock.Instance.new("Folder")
	q.Dispatch.drive(parent, { root })
	local function checkLayout(label: string)
		local sum = 0
		for i = 1, 6 do
			local c = root:Get(i)
			assert(root:IndexOf(c) == i, `{label}: IndexOf child {i}`)
			assert(c.Offset:Get() == sum, `{label}: child {i} offset {c.Offset:Get()} ~= {sum}`)
			sum += c.Length:Get()
		end
		assert(root.Length:Get() == sum, `{label}: root Length {root.Length:Get()} ~= {sum}`)
		assert(#parent:GetChildren() == sum, `{label}: physical children`)
	end
	checkLayout("mounted steady")
	root:Move(1, 6); checkLayout("mounted move down")
	root:Move(5, 2); checkLayout("mounted move up")
	root:Swap(1, 6); checkLayout("mounted swap")
	root:Get(3):Add(mock.Instance.new("Frame")); checkLayout("nested add after permutation") -- gatedRecompute via indexOfElement
	local a = mock.Instance.new("Frame")
	local ok, err = pcall(function() return q.Slot({ a, a }) end)
	assert(not ok and string.find(tostring(err), "Slot: the same element appears twice", 1, true) ~= nil, "constructor duplicate still caught: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.slot.luau", "constructor pre-pass blame")
	local big = {}
	for i = 1, 300 do big[i] = mock.Instance.new("Frame") end
	local s2 = q.Slot(big)
	assert(s2:IndexOf(big[300]) == 300 and s2:IndexOf(big[1]) == 1, "batch constructor: all 300 in, indexed")
	print("PASS")
end

print("=== ALL PASS ===")
