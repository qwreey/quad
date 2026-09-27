--!nocheck
-- E65 targeted axes (edge cases the docs call UB or leave unspecified). usage (repo root):
--   luau .claude/audit/round13-e65-internal-ds-fuzz/axes.luau
local E = require("./env")
local SRC = "../../../quad-roblox/luau_packages/.pesde/qwreey+quad_base/3.2.0/quad_base/src/"
local EpochMap = require(SRC .. "EpochMap")
local Relate = require(SRC .. "Relate")
local ImplRegistry = require(SRC .. "ImplRegistry")
local Void = require(SRC .. "Void")
local KEEP = {}
local ONLY = ({ ... })[1]
local function want(tag) return ONLY == nil or ONLY == tag end
local function try(f, ...)
	local ok, e = pcall(f, ...)
	return if ok then "ok" else E.id(e)
end
local function newOwner()
	local q = E.newBase()
	return q, q.Bookkeeping, E.mock.Instance.new("Frame")
end
local function dump(BK, inst, n)
	local t = {}
	for i = 1, n do
		local ok, v = pcall(BK.getOffsetAt, inst, i)
		table.insert(t, if ok then tostring(v) else E.id(v))
	end
	return table.concat(t, ",")
end

if want("a") then print("== (a) State length with an invalid INITIAL value (H-445 path)")

	local q, BK, inst = newOwner()
	BK.setEmpty(inst, 1)
	local L = q.Source(-1)
	print("  setOffsetSource(2,None):", try(BK.setOffsetSource, inst, 2, q.None))
	print("  setLength(2, Source(-1)):", try(BK.setLength, inst, 2, L))
	local bk = BK.getBookkeeping(inst)
	print("  after raise: lengthList[2] is the State:", bk.lengthList[2] == L, " N =", bk.N, " frozen =", bk.recomputeBlocker.Blocking)
	local s3 = q.Source(99)
	print("  setOffsetSource(3,src):", try(BK.setOffsetSource, inst, 3, s3), " src3 =", s3:Get(), "(true offset with len2=-1 is -1)")
	print("  setLength(3,1):", try(BK.setLength, inst, 3, 1), " offsets 1..4 =", dump(BK, inst, 4))
	L:Set(5)
	print("  L:Set(5) -> offsets 1..4 =", dump(BK, inst, 4), " src3 =", s3:Get(), "(true: 0,0,5,6 / src3 5)")
	collectgarbage("collect")
	L:Set(2)
	print("  after GC, L:Set(2) -> offsets =", dump(BK, inst, 4), " src3 =", s3:Get(), "(true: 0,0,2,3 / src3 2)")
	print("  observers[2] =", tostring(bk.observers[2]))
end

if want("b") then print("== (b) registered State length later :Set(-1), then back")

	local q, BK, inst = newOwner()
	local L = q.Source(2)
	BK.setOffsetSource(inst, 1, q.None); BK.setLength(inst, 1, L)
	local s2 = q.Source(0)
	BK.setOffsetSource(inst, 2, s2); BK.setLength(inst, 2, 1)
	print("  before: offsets", dump(BK, inst, 3), " s2 =", s2:Get())
	print("  L:Set(-1):", try(function() L:Set(-1) end), " offsets", dump(BK, inst, 3), " s2 =", s2:Get(), " frozen", BK.getBookkeeping(inst).recomputeBlocker.Blocking)
	print("  a later unrelated setLength(3,0) with source None:", try(BK.setEmpty, inst, 3), " offsets", dump(BK, inst, 3), " s2 =", s2:Get())
	print("  L:Set(4):", try(function() L:Set(4) end), " offsets", dump(BK, inst, 3), " s2 =", s2:Get(), "(true 0,4,5 / 4)")
end

if want("c") then print("== (c) owner frozen by Quad0023 raised inside a State-length observer's first run")

	local q, BK, inst = newOwner()
	local L = q.Source(3)
	print("  setLength(1, State) w/o source:", try(BK.setLength, inst, 1, L), " frozen", BK.getBookkeeping(inst).recomputeBlocker.Blocking)
	print("  offsets 1..2 =", dump(BK, inst, 2))
	L:Set(7)
	print("  L:Set(7) -> offsets 1..2 =", dump(BK, inst, 2), "(true 0,7) observers[1] =", tostring(BK.getBookkeeping(inst).observers[1]))
end

if want("d") then print("== (d) one element passed at two positions (single-mount contract broken by a handler)")

	local q, BK, inst = newOwner()
	local elem = {}
	local L = q.Source(1)
	BK.setEmpty(inst, 1)
	BK.setOffsetSource(inst, 1, q.None); BK.setLength(inst, 1, L, nil, elem)
	local s = {}
	for i = 2, 4 do s[i] = q.Source(0); BK.setOffsetSource(inst, i, s[i]); BK.setLength(inst, i, 1, nil, if i == 3 then elem else nil) end
	print("  offsets", dump(BK, inst, 5), " (elem now indexed at", BK.getBookkeeping(inst).indexOfElement[elem], ")")
	L:Set(10)
	print("  L(pos1):Set(10) -> offsets", dump(BK, inst, 5), " sources", s[2]:Get(), s[3]:Get(), s[4]:Get(), "(true 0,10,11,12,13 / 10,11,12)")
end

if want("e1") then print("== (e1) re-entrancy: an offset Source's subscriber rewrites an EARLIER length mid-recompute (rewind path)")

	for trial = 1, 3 do
		local q, BK, inst = newOwner()
		local s = {}
		BK.setEmpty(inst, 1)
		for i = 2, 6 do s[i] = q.Source(-1) end
		local fired = 0
		local target = trial + 1 -- rewrite position target-1's length from s[target]'s subscriber, once
		KEEP[#KEEP + 1] = s[target]:Observer(function() -- held strongly: an unheld Observer is collectable
			fired += 1
			if fired == 3 then BK.setLength(inst, target - 1, 4) end
		end):Subscribe()
		local blocker = BK.getBlocker(inst)
		blocker:On()
		for i = 2, 6 do BK.setOffsetSource(inst, i, s[i]); BK.setLength(inst, i, 1) end
		blocker:OffWithoutEmit()
		print(`  trial {trial}: setup ok; offsets {dump(BK, inst, 7)} fired {fired}`)
		print("    setLength(1,2):", try(BK.setLength, inst, 1, 2))
		local vals = {}
		for i = 2, 6 do table.insert(vals, s[i]:Get()) end
		print(`    after: sources {table.concat(vals, ",")} offsets {dump(BK, inst, 7)} fired {fired}  (true offsets: pos{target - 1} len 4 -> recomputed by hand below)`)
		local len = { 2, 1, 1, 1, 1, 1 }
		len[target - 1] = 4
		local acc, tr = 0, {}
		for i = 1, 7 do table.insert(tr, acc); acc += len[i] or 0 end
		print(`    true offsets 1..7: {table.concat(tr, ",")}`)
	end
end

if want("e2") then print("== (e2) cycle: an offset Source is also an EARLIER position's length State")

	local q, BK, inst = newOwner()
	local X = q.Source(1)
	local sets = 0
	KEEP[#KEEP + 1] = X:Observer(function() sets += 1; if sets > 2000 then error("CYCLE-CAP") end end):Subscribe()
	BK.setEmpty(inst, 1)
	BK.setOffsetSource(inst, 2, q.None); BK.setLength(inst, 2, X)
	BK.setOffsetSource(inst, 3, q.None); BK.setLength(inst, 3, 1)
	print("  X at length(2) and offset(4); setOffsetSource(4, X):", try(BK.setOffsetSource, inst, 4, X), " X =", X:Get())
	print("  setLength(4,0):", try(BK.setLength, inst, 4, 0), " X =", X:Get(), " observer runs", sets, " frozen", BK.getBookkeeping(inst).recomputeBlocker.Blocking)
end

if want("f") then print("== (f) extreme positions")

	local q, BK, inst = newOwner()
	BK.setEmpty(inst, 1)
	for _, at in { 0 / 0, math.huge, -math.huge, 2 ^ 53, 2 ^ 31, 1e300 } do
		print(`  getOffsetAt({at}):`, try(BK.getOffsetAt, inst, at), ` setLength:`, try(BK.setLength, inst, at, 0))
	end
	local bk = BK.getBookkeeping(inst)
	print("  N after the setLength sweep =", bk.N)
	local t0 = os.clock()
	print("  setEmpty(inst, 2^20+1) (sparse far position):", try(BK.setEmpty, inst, 2 ^ 20 + 1), string.format("%.3fs", os.clock() - t0))
end

if want("g") then print("== (g) EpochMap revision edge (uint32 wrap) and non-epoch set members")

	local q = E.newBase()
	local s = q.Source(0)
	local m = EpochMap()
	m:Sync(s)
	s.Revision = 0
	print("  Revision forced to 0; Update ->", m:Update(s))
	s:Set(1)
	print("  Set once from 0: Revision =", s.Revision, " Update ->", m:Update(s))
	local r0 = s.Revision
	s.Revision = r0 -- same value written back
	print("  same revision rewritten; Update ->", m:Update(s))
	local st = q.Source(1):Compute(function(v) return v end)
	print("  a (non-epoch) State inside an EpochSet: Update ->", try(function() return m:Update({ [st] = true }) end), " stored =", tostring(m._map[st]))
	print("  Update({}) ->", m:Update({}), " Peek({}) ->", m:Peek({}))
end

if want("h") then print("== (h) Relate NaN / odd keys")

	local r = Relate()
	print("  SetStrong(inst, NaN key):", try(r.SetStrong, r, {}, 0 / 0, 1))
	print("  SetWeak(NaN inst):", try(r.SetWeak, r, 0 / 0, "k", 1))
	print("  GetStrong(NaN inst):", try(r.GetStrong, r, 0 / 0, "k"))
	print("  GetWeak(inst, NaN key) with WeakMap present:", (function() local i = {}; r:SetWeak(i, "k", {}); return try(r.GetWeak, r, i, 0 / 0) end)())
	print("  nil inst + nil key ->", try(r.SetStrong, r, nil, nil, 1), "(inst checked first)")
	print("  public q.Relate is the same constructor:", E.newBase().Relate == Relate)
	-- H-77 leak shape still present (confirm only): inner key referencing the outer inst
	local leaks = 0
	for _ = 1, 50 do
		local rr = Relate()
		local inst = {}
		rr:SetWeak(inst, { back = inst }, true)
		inst = nil
		collectgarbage("collect")
		for _ in rr.buckets do leaks += 1 end
	end
	print("  inner-key back-reference leaks (H-77, documented):", leaks, "/ 50")
end

if want("i") then print("== (i) ImplRegistry on frozen / proxied modules")

	local fz = table.freeze({})
	print("  implsOf(frozen table):", try(ImplRegistry.implsOf, fz))
	local q = E.newBase()
	print("  table.isfrozen(Quad.New()) =", table.isfrozen(q), " implsOf twice same:", ImplRegistry.implsOf(q) == ImplRegistry.implsOf(q))
	print("  implsOf(nil):", try(ImplRegistry.implsOf, nil), " implsOf('str'):", try(ImplRegistry.implsOf, "s"))
end

if want("j") then print("== (j) Void identity")

	local q = E.newBase()
	print("  q.Void == Void module:", q.Void == Void, " returns nothing:", select("#", Void(1, 2, 3)))
end
