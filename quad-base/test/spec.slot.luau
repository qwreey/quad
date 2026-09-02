--!nocheck
--[[
	Slot spec — M6 fork, built per slice. Slice 2: plain-element end-to-end
	(`Frame { slot }` mounts children, Add/Remove reflect physically, ordering
	via Length/Offset, unmount on State<Slot> swap, dispose guard).

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
print("=== ALL PASS ===")
