--!nocheck
-- E80 group B: Slot Fixed bullets (F4 F11 F30 F33 F38 F43 F44 F31) + Changed C30
local H = require("../harness")
local L = require("../lib")
local q, D, mock = H.q, H.D, H.mock

local function kids(p) return #p:GetChildren() end

print("--- F4: 파괴된 quad Instance를 slot:Add → 즉시 not claimed ---")
L.section(function()
	local s = q.Slot()
	local host = D.Frame { s }
	local f = D.Frame {}
	f:Destroy()
	local m, id = L.err("F4 Add(destroyed)", function() s:Add(f) end)
	L.check("F4 rejected as not claimed", L.has(m, "not claimed"), id)
	L.check("F4 nothing added", s.Length:Get() == 0, s.Length:Get())
end)

print("--- F11: :List data가 배열이 아니면 거부, 아무것도 안 건드림; updateFn이 KeyGone을 돌려주면 안내 ---")
L.section(function()
	local data = q.Source({ { id = "a" }, { id = "b" } })
	local s = q.Slot()
	s:List(data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Prev then return ctx.Prev end
		return D.Frame {}
	end, function(item) return item.id end)
	local host = D.Frame { s }
	local m, id = L.err("F11 map data", function() data:Set({ a = { id = "a" }, b = { id = "b" } }) end)
	L.check("F11 message", L.has(m, "Slot:List: data must be a plain array — key \""), id)
	L.check("F11 untouched", s.Length:Get() == 2 and kids(host) == 2, "len=" .. s.Length:Get() .. " kids=" .. kids(host))
	local m2 = L.err("F11 array with hash key", function() data:Set({ { id = "a" }, extra = 1 }) end)
	L.check("F11 hash key message", L.has(m2, 'key "extra" is not an array position'), m2)
	local s2 = q.Slot()
	local m3, id3 = L.err("F11 updateFn returns KeyGone", function()
		s2:List(q.Source({ { id = "x" } }), function() return q.KeyGone end, function(i) return i.id end)
		D.Frame { s2 }
	end)
	L.check("F11 KeyGone guidance", m3 ~= nil and L.has(m3, "KeyGone"), id3)
	-- constructor initial parity (bullet says 생성자 initial과 같은 규칙)
	local m4 = L.err("F11 constructor initial map", function() q.Slot({ a = D.Frame {} }) end)
end)

print("--- F30: 중첩 :List updateFn이 첫 마운트 중 조상 Slot CRUD → 거부 ---")
L.section(function()
	local outer = q.Slot()
	local inner = q.Slot()
	local m, id
	inner:List(q.Source({ 1 }), function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Prev then return ctx.Prev end
		local okx, e = pcall(function() outer:Add(D.Frame {}) end)
		if not okx then m = L.first(e); id = L.id(m) end
		return D.Frame {}
	end)
	outer:Add(inner)
	local host = D.Frame { outer }
	print("  F30 inner updateFn CRUD on ancestor: " .. tostring(m))
	L.check("F30 rejected with mounting message", L.has(m, "Slot: cannot mutate a Slot while it is being mounted"), id)
	-- after mount, ancestor still usable
	local ok2, e2 = pcall(function() outer:Add(D.Frame {}) end)
	L.check("F30 ancestor usable after mount", ok2, ok2 and outer.Length:Get() or L.first(e2))
	-- filling own child Slot is fine
	local okc, ec = pcall(function()
		local o2 = q.Slot()
		local i2 = q.Slot()
		o2:List(q.Source({ 1 }), function(ctx)
			if ctx.Item == q.KeyGone then return nil end
			if ctx.Prev then return ctx.Prev end
			local child = q.Slot()
			child:Add(D.Frame {})
			return D.Frame { child }
		end)
		D.Frame { o2 }
	end)
	L.check("F30 own child Slot fill unaffected", okc, okc and "ok" or L.first(ec))
	-- the spec's exact shape (insert at position 1, no pcall inside updateFn)
	local o3, i3 = q.Slot(), q.Slot()
	i3:List(q.Source({ 1 }), function(ctx) o3:Add(D.Frame {}, 1); return D.Frame {} end, function(x) return x end)
	o3:Add(i3)
	local m3, id3 = L.err("F30 Add(x, 1) inside nested updateFn during mount", function() D.Frame { o3 } end)
	L.check("F30 spec shape rejected with mounting message", L.has(m3, "while it is being mounted"), id3)
end)

print("--- F33: State에 담은 원소의 검사가 삽입 전, 실패한 호출은 아무것도 안 바꿈 ---")
L.section(function()
	local s = q.Slot()
	local host = D.Frame { s }
	s:Add(D.Frame {})
	local foreign = mock.Instance.new("Frame") -- not claimed under quad-roblox provider
	local st = q.Source(foreign)
	local m, id = L.err("F33 Add(State(unclaimed))", function() s:Add(st) end)
	L.check("F33 rejected, unchanged", s.Length:Get() == 1 and #s._elements == 1, "len=" .. s.Length:Get() .. " elems=" .. #s._elements)
	s:Add(D.Frame {})
	L.check("F33 slot still reconciles after rejection", s.Length:Get() == 2 and kids(host) == 2, "len=" .. s.Length:Get() .. " kids=" .. kids(host))
	local st2 = q.Source(5)
	local m2 = L.err("F33 Add(State(5)) non-mountable", function() s:Add(st2) end)
	L.check("F33 non-mountable State rejected before insert", s.Length:Get() == 2, s.Length:Get())
	-- dead Slot inside State
	local dead = q.Slot(); q.dispose(dead)
	local m3 = L.err("F33 Add(State(disposed Slot))", function() s:Add(q.Source(dead)) end)
	L.check("F33 disposed Slot in State rejected", m3 ~= nil and s.Length:Get() == 2, m3)
	-- pre-mount Slot rejects at call
	local pre = q.Slot()
	local m4 = L.err("F33 pre-mount Add(State(unclaimed))", function() pre:Add(q.Source(mock.Instance.new("Frame"))) end)
	L.check("F33 pre-mount rejects at call", m4 ~= nil and #pre._elements == 0, m4)
end)

print("--- F38: 다른 quad 인스턴스가 만든 Slot을 원소로/ dispose → 거부 ---")
L.section(function()
	local B = H.Quad.New():UseProvider(H.QuadRoblox)
	local bSlot = B.Slot()
	local a = q.Slot()
	local m, id = L.err("F38 Add(other Slot)", function() a:Add(bSlot) end)
	L.check("F38 Add rejected", L.has(m, "another quad module instance"), id)
	local m2 = L.err("F38 dispose(other Slot)", function() q.dispose(bSlot) end)
	L.check("F38 dispose rejected", L.has(m2, "another quad module instance"), L.id(m2))
	local m3 = L.err("F38 Add(State(other Slot))", function() a:Add(q.Source(bSlot)) end)
	local bState = B.Source(1)
	local m4 = L.err("F38 Add(other State) — same wording as Slot", function() a:Add(bState) end)
	L.check("F38 State & Slot same wording", L.id(m) ~= nil and L.id(m) == L.id(m4), tostring(L.id(m)) .. " vs " .. tostring(L.id(m4)))
	local l = q.Slot()
	l:List(q.Source({ 1 }), function() return bSlot end)
	local m5 = L.err("F38 :List returns other Slot", function() D.Frame { l } end)
	L.check("F38 :List return rejected", L.has(m5, "another quad module instance"), L.id(m5))
end)

print("--- F43: 검증 실패한 CRUD가 Slot을 수동으로 표시하지 않는다 ---")
L.section(function()
	local s = q.Slot()
	L.err("F43 Add(nil)", function() s:Add(nil) end)
	local ok, e = pcall(function()
		s:List(q.Source({ 1 }), function(ctx) if ctx.Item == q.KeyGone then return nil end; return ctx.Prev or D.Frame {} end)
	end)
	L.check("F43 :List after failed Add ok", ok, ok and "ok" or L.first(e))
	local s2 = q.Slot()
	s2:Add(D.Frame {})
	local m2 = L.err("F43 control: real Add then :List", function()
		s2:List(q.Source({ 1 }), function(ctx) return ctx.Prev or D.Frame {} end)
	end)
	L.check("F43 control still rejected", m2 ~= nil, L.id(m2))
end)

print("--- F44: Splice 되넣기/Replace(i, Get(i)) 문구, keyFn NaN, Tag 자기 참조 ---")
L.section(function()
	local s = q.Slot()
	local a, b = D.Frame {}, D.Frame {}
	s:Add(a); s:Add(b)
	local m1 = L.err("F44 Splice re-insert removed", function() s:Splice(1, 1, a) end)
	L.check("F44 Splice says already in this Slot / Move/Swap", L.has(m1, "Move") or L.has(m1, "Swap"), m1)
	local m2 = L.err("F44 Replace(1, Get(1))", function() s:Replace(1, s:Get(1)) end)
	L.check("F44 Replace says already in this Slot / Move/Swap", L.has(m2, "Move") or L.has(m2, "Swap"), m2)
	L.check("F44 slot unchanged", s:Get(1) == a and s:Get(2) == b and #s._elements == 2, tostring(s:Get(1) == a) .. " " .. tostring(s:Get(2) == b) .. " n=" .. #s._elements)
	local sN = q.Slot()
	local mN = L.err("F44 keyFn NaN", function()
		sN:List(q.Source({ 1 }), function(ctx) return ctx.Prev or D.Frame {} end, function() return 0 / 0 end)
		D.Frame { sN }
	end)
	local sNil = q.Slot()
	local mNil = L.err("F44 keyFn nil (control)", function()
		sNil:List(q.Source({ 1 }), function(ctx) return ctx.Prev or D.Frame {} end, function() return nil end)
		D.Frame { sNil }
	end)
	L.check("F44 NaN same domain error as nil", L.id(mN) ~= nil and L.id(mN) == L.id(mNil), tostring(L.id(mN)) .. " vs " .. tostring(L.id(mNil)))
	local t = {}
	t[1] = t
	local mT = L.err("F44 Tag self-containing list", function() q.Tag(t) end)
	L.check("F44 Tag self list domain error (not stack overflow)", mT ~= nil and not L.has(mT, "stack overflow") and L.id(mT) ~= nil, mT)
end)

print("--- F31: Dispatch.process(inst, 0, child, 1) → no handler matched, 아무것도 안 남김 ---")
L.section(function()
	local host = D.Frame {}
	local child = D.Frame {}
	local m, id = L.err("F31 process key 0", function() q.Dispatch.process(host, 0, child, 1) end)
	L.check("F31 no handler matched", L.has(m, "no handler matched key"), id)
	local host2 = D.Frame { child }
	L.check("F31 child placeable afterwards", child.Parent == host2, tostring(child.Parent))
	local sl = q.Slot()
	local m2 = L.err("F31 process key 1.5 Slot", function() q.Dispatch.process(host, 1.5, sl, 1) end)
	L.check("F31 Slot no handler matched (bullet wording)", L.has(m2, "no handler matched key"), L.id(m2))
	local m2b = L.err("F31 process key 0 Slot", function() q.Dispatch.process(host, 0, sl, 1) end)
	local okS = pcall(function() D.Frame { sl } end)
	L.check("F31 Slot placeable afterwards", okS, "")
end)

print("--- C30: OwnsElements=false Slot dispose → 원소 소유권 풀림, Slot 재사용 ---")
L.section(function()
	local frames = {}
	local data = q.Source({ { id = "a" }, { id = "b" } })
	local s = q.Slot()
	s:List(data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Prev then return ctx.Prev end
		local f = D.Frame {}; table.insert(frames, f); return f
	end, function(i) return i.id end, { OwnsElements = false })
	local holder = q.Source(s)
	local host = D.Frame { holder }
	holder:Set(nil)
	q.dispose(s)
	L.check("C30 elements not destroyed", frames[1].Parent == nil and not mock.isDestroyed(frames[1]), "")
	local other = q.Slot()
	local ok, e = pcall(function() other:Add(frames[1]) end)
	L.check("C30 element can join another Slot", ok, ok and "ok" or L.first(e))
	local okd, ed = pcall(function() q.dispose(frames[2]) end)
	L.check("C30 element can be disposed", okd, okd and "ok" or L.first(ed))
	local host2 = D.Frame { s }
	L.check("C30 Slot reusable, reconciles from data", s.Length:Get() == 2 and kids(host2) == 2, "len=" .. s.Length:Get())
	-- parent Remove path
	local frames2 = {}
	local inner = q.Slot()
	inner:List(q.Source({ 1 }), function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Prev then return ctx.Prev end
		local f = D.Frame {}; table.insert(frames2, f); return f
	end, nil, { OwnsElements = false })
	local parent = q.Slot({ inner })
	local h3 = D.Frame { parent }
	parent:Remove(1)
	local ok3, e3 = pcall(function() q.Slot():Add(frames2[1]) end)
	L.check("C30 parent Remove releases elements", ok3, ok3 and "ok" or L.first(e3))
end)
L.done()
