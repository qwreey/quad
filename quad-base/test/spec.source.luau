--[[
	Source 계약 — `.claude/base/source-state-plan.md` "Source는 독립 공개 프리미티브로 격상" /
	"`Source:Set(v)`는 동일값이어도 항상 갱신하고 emit한다" / "`:Emit()`" / "따름정리 — Modifier",
	`.claude/base/modifier-plan.md` 7번, `.claude/base/brand-plan.md`(다중 태깅).
]]

local Quad = require("../src")
local Brand = require("../src/Brand")
local QuadTypes = require("../luau_packages/quad_types")

type Source<T> = QuadTypes.Source<T>

local Source = Quad.Source

print("=== 1. 생성 — 값, Revision 0, SourceBrand+EpochBrand 다중 태깅, StateBrand엔 미등록 ===")
do
	local s = Source(5)
	assert(s:Get() == 5, "default is the value")
	assert(s.Revision == 0, "initial revision")
	assert(Quad.isSource(s) and Quad.isEpoch(s), "Source is both Source and Epoch")
	assert(Quad.isState(s), "isState passes a Source by composition")
	assert(Brand.StateBrand:Is(s) == false, "…but it is NOT registered in StateBrand (predicate composition, not double registration)")
	assert(not Quad.isRef(s) and not Quad.isStore(s), "nothing else")
	local n: Source<number?> = Source(nil :: number?)
	assert(n:Get() == nil, "Source(nil) holds nil")
	print("PASS")
end

print()
print("=== 2. :Set — 값 갱신 + 리비전 감소 랩 + self 반환; 동일값도 항상 (H-68) ===")
do
	local s = Source(1 :: any)
	assert(s:Set(2) == s, "Set returns self")
	assert(s:Get() == 2 and s.Revision == 4294967295, "value moved, revision wrapped from 0")
	local r1 = s.Revision
	s:Set(2) -- same value
	assert(s.Revision ~= r1, "same value still bumps the revision")
	local t = {}
	s:Set(t :: any)
	assert(s:Get() == t, "Get returns the live reference")
	print("PASS")
end

print()
print("=== 3. :Emit — 값은 그대로, 리비전만 갱신, self 반환 ===")
do
	local s = Source({ n = 1 })
	local rev = s.Revision
	s:Get().n = 2
	assert(s:Emit() == s and s.Revision ~= rev and s:Get().n == 2, "Emit bumps revision without touching the value")
	print("PASS")
end

print()
print("=== 4. Modifier 가드 — 생성자와 Set 둘 다, level 2 ===")
do
	local mod = {}
	Brand.ModifierBrand:Register(mod)
	local ok, err = pcall(function()
		Source(mod :: any)
	end)
	assert(not ok and string.find(tostring(err), "Modifier", 1, true) ~= nil, "constructor rejects: " .. tostring(err))
	assert(string.find(tostring(err), "spec.source.luau", 1, true) ~= nil, "level 2 points at the caller")
	local s = Source(1)
	local ok2, err2 = pcall(function()
		s:Set(mod :: any)
	end)
	assert(not ok2 and string.find(tostring(err2), "Modifier", 1, true) ~= nil, "Set rejects: " .. tostring(err2))
	assert(s:Get() == 1, "value untouched after the rejected Set")
	print("PASS")
end

print()
print("=== 5. State 메소드 위임 — Source에서 Depend/Compute/Apply가 바로 됨 ===")
do
	local s = Source(3)
	local doubled: QuadTypes.State<number> = s:Compute(function(x): number
		return x:Get() * 2
	end)
	assert(doubled:Get() == 6, "Compute through a Source")
	local w: QuadTypes.State<number> = s:Depend(Source(0))
	assert(w:Get() == 3, "Depend passes self's value through")
	local applied = s:Apply(function(st: QuadTypes.StateData<number>): number
		return st:Get() + 1
	end)
	assert(applied == 4, "Apply(fn) is just fn(self)")
	print("PASS")
end

print()
print("=== 6. 인스턴스별 팩토리 (H-174) — 다른 New()의 Source는 다른 임플, 브랜드는 공유 ===")
do
	local other = Quad.New()
	local a, b = Quad.Source(1), other.Source(1)
	assert(getmetatable(a :: any) ~= getmetatable(b :: any), "each quad instance has its own Source impl")
	assert(Quad.isSource(b) and other.isSource(a), "brands are shared leaf modules")
	print("PASS")
end

print()
print("=== 7. :SetIfChanged (2026-10-01 사용자 결정) — `==`면 무동작(리비전·통지 없음), 다르면 Set과 같음, self 반환 ===")
do
	local mock = require("./mock")
	local dq = mock.newQuad()
	-- a. same value: nothing — no revision, no notification; returns self
	local s = dq.Source(1 :: any)
	local fires = 0
	local obs = s:Observer(function()
		fires += 1
	end):Subscribe()
	assert(fires == 1, "observer baseline")
	local r0 = s.Revision
	assert(s:SetIfChanged(1) == s, "returns self when it does not write")
	assert(s.Revision == r0 and fires == 1, "equal value: no revision bump, no notification")
	-- b. different value: exactly Set (value, revision step, one notification)
	assert(s:SetIfChanged(2) == s, "returns self when it writes")
	assert(s:Get() == 2 and s.Revision ~= r0 and fires == 2, "different value: Set's write")
	-- chain (same shape as Set)
	s:SetIfChanged(2):SetIfChanged(3)
	assert(s:Get() == 3 and fires == 3, "chain: the equal call is a no-op, the next one writes")
	-- c. Set itself is unchanged (H-68): an equal value still propagates
	s:Set(3)
	assert(fires == 4, "Set still propagates an equal value")
	local _ = obs

	-- d. Luau `==`: a shared `__eq` decides (user: "의도에 맞게 override 될 수 있거든")
	local byId = { __eq = function(x: any, y: any): boolean
		return x.id == y.id
	end }
	local a1 = setmetatable({ id = 1, n = 1 }, byId)
	local a2 = setmetatable({ id = 1, n = 2 }, byId)
	local t = dq.Source(a1 :: any)
	local rt = t.Revision
	t:SetIfChanged(a2)
	assert(rawequal(t:Get(), a1) and t.Revision == rt, "__eq says equal: skipped (the old reference stays)")
	local a3 = setmetatable({ id = 2 }, byId)
	t:SetIfChanged(a3)
	assert(rawequal(t:Get(), a3) and t.Revision ~= rt, "__eq says different: written")
	-- a different `__eq` on each side is not called by Luau — they compare unequal and the write happens
	local other = setmetatable({ id = 2 }, { __eq = function(): boolean
		return true
	end })
	local rt2 = t.Revision
	t:SetIfChanged(other)
	assert(rawequal(t:Get(), other) and t.Revision ~= rt2, "mismatched __eq: unequal, written")
	-- an in-place-mutated table is the same reference → skipped (that is what :Emit is for)
	local live = { n = 1 }
	local m = dq.Source(live)
	local rm = m.Revision
	live.n = 2
	m:SetIfChanged(live)
	assert(m.Revision == rm, "same reference after in-place mutation: skipped")

	-- e. NaN is never equal to itself → always written
	local nan = 0 / 0
	local ns = dq.Source(nan)
	local rn = ns.Revision
	ns:SetIfChanged(nan)
	assert(ns.Revision ~= rn, "NaN always writes")

	-- f. the value gate runs FIRST and raises Set's error, blaming the user line — even when `==` would say equal
	local alwaysEq = { __eq = function(): boolean
		return true
	end }
	local cur = setmetatable({}, alwaysEq)
	local mod = setmetatable({}, alwaysEq)
	Brand.ModifierBrand:Register(mod)
	local g = dq.Source(cur :: any)
	assert((mod :: any) == cur, "precondition: the Modifier compares equal to the current value")
	local okS, errS = pcall(function()
		g:Set(mod :: any)
	end)
	local okC, errC = pcall(function()
		g:SetIfChanged(mod :: any)
	end)
	assert(not okS and not okC, "both reject a Modifier")
	local function body(e: any): string
		local str = tostring(e)
		return string.sub(str, (string.find(str, "Quad0181", 1, true) or 1))
	end
	assert(body(errC) == body(errS) and string.find(body(errC), "Quad0181 Source: cannot Set a Modifier", 1, true) == 1, "same error as Set: " .. tostring(errC))
	mock.assertBlamesUser(errC, "spec.source.luau", "SetIfChanged Modifier blame")
	assert(rawequal(g:Get(), cur), "value untouched after the rejected call")

	-- g. an error raised deep in the wave blames the SetIfChanged caller line, as with Set (H-330)
	local slot = dq.Slot({ mock.Instance.new("Frame") })
	dq.Dispatch.drive(mock.Instance.new("Frame"), { slot })
	local seat = dq.Source(nil :: any)
	dq.Dispatch.drive(mock.Instance.new("Frame"), { seat })
	local okW, errW = pcall(function()
		seat:SetIfChanged(slot) -- second mount of the same Slot → SlotHandler raises inside the wave
	end)
	assert(not okW and string.find(tostring(errW), "already mounted", 1, true) ~= nil, "wave error surfaces: " .. tostring(errW))
	mock.assertBlamesUser(errW, "spec.source.luau", "wave-depth error blames the SetIfChanged line")

	-- h. an Effect trimming its own dep converges with SetIfChanged; the same shape with Set hits Quad0263
	local hp = dq.Source(120)
	local runs = 0
	dq.Effect(function()
		runs += 1
		hp:SetIfChanged(math.clamp(hp:Get(), 0, 100))
	end, hp)
	assert(hp:Get() == 100 and runs == 2, "converges: one trimming re-run, then the equal write is a no-op (" .. runs .. ")")
	local hp2 = dq.Source(120)
	local okL, errL = pcall(function()
		dq.Effect(function()
			hp2:Set(math.clamp(hp2:Get(), 0, 100))
		end, hp2)
	end)
	assert(not okL and string.find(tostring(errL), "Quad0263", 1, true) ~= nil, "Set in the same shape never settles: " .. tostring(errL))
	assert(string.find(tostring(errL), "SetIfChanged", 1, true) ~= nil, "Quad0263 points at SetIfChanged: " .. tostring(errL))

	-- i. a Store field is a Source — the method is there as-is
	local store = dq.Store({ hp = dq.Source(5) })
	local rs = store.hp.Revision
	store.hp:SetIfChanged(5)
	assert(store.hp.Revision == rs, "Store field: equal value skipped")
	store.hp:SetIfChanged(6)
	assert(store.hp:Get() == 6 and store.hp.Revision ~= rs, "Store field: different value written")
	print("PASS")
end

print()
print("=== 8. :SetAndDispose (2026-08-20 SL-74 확정, 2026-10-01 구현) — Set 전파가 먼저, 그 뒤 옛 값 dispose ===")
do
	local mock = require("./mock")
	local dq = mock.newQuad()
	local function body(e: any, code: string): string
		local str = tostring(e)
		return string.sub(str, (string.find(str, code, 1, true) or 1))
	end

	-- a. order: the wave (unmount at the seat) runs to completion, THEN the old value is disposed
	local host = mock.Instance.new("Frame")
	local f1 = mock.Instance.new("Frame")
	local s1 = dq.Slot({ f1 })
	local seat = dq.Source(s1 :: any)
	dq.Dispatch.drive(host, { seat })
	assert(f1.Parent == host, "precondition: the old Slot's element is seated")
	-- negative control — the order matters: disposing the seated value BEFORE the Set is refused
	local okEarly, errEarly = pcall(function()
		dq.dispose(s1)
	end)
	assert(not okEarly and string.find(tostring(errEarly), "Quad0179", 1, true) ~= nil, "dispose before the Set is refused: " .. tostring(errEarly))
	local seenDuringWave: { boolean } = {}
	local obs = seat:Observer(function()
		table.insert(seenDuringWave, s1._destroyed == true or mock.isDestroyed(f1))
	end):Subscribe()
	local f2 = mock.Instance.new("Frame")
	local s2 = dq.Slot({ f2 })
	local r0 = seat.Revision
	assert(seat:SetAndDispose(s2) == seat, "returns self")
	assert(rawequal(seat:Get(), s2) and seat.Revision ~= r0, "Set's write (value + revision)")
	assert(#seenDuringWave == 2 and seenDuringWave[2] == false, "the wave saw the old value still alive (dispose comes after)")
	assert(s1._destroyed and mock.isDestroyed(f1), "old Slot disposed after the wave (its element with it)")
	assert(f2.Parent == host and not mock.isDestroyed(f2), "new value seated")
	local _ = obs

	-- b. same reference: Set still happens (H-68), nothing is disposed
	local r1 = seat.Revision
	seat:SetAndDispose(s2)
	assert(seat.Revision ~= r1, "same value: the write still propagates (H-68)")
	assert(not s2._destroyed and not mock.isDestroyed(f2) and f2.Parent == host, "same value: not disposed, still seated")

	-- c. new value nil: the seat empties and the old value is disposed (remove-and-destroy in one call)
	seat:SetAndDispose(nil)
	assert(seat:Get() == nil and s2._destroyed and mock.isDestroyed(f2), "Set(nil) then dispose the old Slot")

	-- d. old value nil / None: an empty seat — nothing to dispose, no error
	local n = dq.Source(nil :: any)
	local f3 = mock.Instance.new("Frame")
	n:SetAndDispose(f3)
	assert(rawequal(n:Get(), f3), "from nil: written, nothing disposed")
	local nn = dq.Source(dq.None :: any)
	nn:SetAndDispose(1)
	assert(nn:Get() == 1, "from None: written, nothing disposed")

	-- e. an unseated Instance + chaining: the replaced Instance is destroyed
	local fa, fb = mock.Instance.new("Frame"), mock.Instance.new("Frame")
	local free = dq.Source(fa :: any)
	free:SetAndDispose(fb):SetAndDispose(nil)
	assert(mock.isDestroyed(fa) and mock.isDestroyed(fb) and free:Get() == nil, "chain: each replaced Instance destroyed")

	-- f. old value dispose cannot take (a number): dispose's own error AFTER the write, blaming the user line
	local num = dq.Source(5 :: any)
	local rn = num.Revision
	local okN, errN = pcall(function()
		num:SetAndDispose(6)
	end)
	assert(not okN and string.find(body(errN, "Quad0180"), "Quad0180 dispose: this backend cannot dispose this value", 1, true) == 1, "dispose's error: " .. tostring(errN))
	assert(num:Get() == 6 and num.Revision ~= rn, "the write already happened (no rollback, no pcall)")
	mock.assertBlamesUser(errN, "spec.source.luau", "SetAndDispose dispose-error blame")

	-- g. old value still held elsewhere (a manual Slot): Quad0179 after the write, value not destroyed, user line blamed
	local held = mock.Instance.new("Frame")
	dq.Dispatch.drive(mock.Instance.new("Frame"), { dq.Slot({ held }) })
	local h = dq.Source(held :: any)
	local okH, errH = pcall(function()
		h:SetAndDispose(nil)
	end)
	assert(not okH and string.find(tostring(errH), "Quad0179", 1, true) ~= nil, "held elsewhere: " .. tostring(errH))
	assert(h:Get() == nil and not mock.isDestroyed(held), "written; the held value survives")
	mock.assertBlamesUser(errH, "spec.source.luau", "SetAndDispose held blame")

	-- h. Modifier: the same gate as Set, run FIRST — nothing written, nothing disposed, user line blamed
	local mod = {}
	Brand.ModifierBrand:Register(mod)
	local fm = mock.Instance.new("Frame")
	local g = dq.Source(fm :: any)
	local rg = g.Revision
	local okS, errS = pcall(function()
		g:Set(mod :: any)
	end)
	local okD, errD = pcall(function()
		g:SetAndDispose(mod :: any)
	end)
	assert(not okS and not okD and body(errD, "Quad0181") == body(errS, "Quad0181"), "same error as Set: " .. tostring(errD))
	assert(rawequal(g:Get(), fm) and g.Revision == rg and not mock.isDestroyed(fm), "rejected: value, revision and old value untouched")
	mock.assertBlamesUser(errD, "spec.source.luau", "SetAndDispose Modifier blame")

	-- i. a Store field is a Source — the method is there as-is
	local fs = mock.Instance.new("Frame")
	local store = dq.Store({ panel = dq.Source(fs :: any) })
	store.panel:SetAndDispose(nil)
	assert(store.panel:Get() == nil and mock.isDestroyed(fs), "Store field: Set then dispose")
	print("PASS")
end

print()
print("=== ALL PASS ===")
