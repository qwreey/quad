--!nocheck
-- E60 (b) perf + (c) GC. luau .claude/audit/round13-e60-store-fuzz/perf-gc.luau
local mock = require("../../../quad-base/test/mock")
local q = mock.newQuad()
local Source, Store = q.Source, q.Store
local function ms(f) local t = os.clock() f() return (os.clock() - t) * 1000 end

print("== (b) perf, N = 1000 / 10000")
for _, N in { 1000, 10000 } do
	local d = {}
	for i = 1, N do d["k" .. i] = Source(i) end
	local s
	local tCtor = ms(function() s = Store(d) end)
	local tNames = ms(function() for _ = 1, 10 do s:Names() end end) / 10
	local tIter = ms(function() for _ = 1, 10 do local c = 0 for _ in s do c += 1 end end end) / 10
	local tStr = ms(function() tostring(s) end)
	local e = Store()
	local tOf = ms(function() for i = 1, N do e:Of("k" .. i) end end)
	local tOf2 = ms(function() for i = 1, N do e:Of("k" .. i) end end)
	local inst = mock.Instance.new("Frame")
	local tAttr = ms(function() q.Dispatch.drive(inst, { q.Attr(s) }) end)
	local tSet = ms(function() for i = 1, N do s["k" .. i]:Set(-i) end end)
	print(string.format(" N=%d ctor %.2fms  Names %.2fms  iter %.2fms  tostring %.2fms  Of-new %.2fms  Of-again %.2fms  Attr drive %.2fms  Set-all(with Attr) %.2fms",
		N, tCtor, tNames, tIter, tStr, tOf, tOf2, tAttr, tSet))
end

print("== (c) GC")
local function count(w) local c = 0 for _ in w do c += 1 end return c end
local function gc() for _ = 1, 4 do collectgarbage("collect") end end
do -- c1: plain store dropped
	local w = setmetatable({}, { __mode = "k" })
	do local d = {} for i = 1, 1000 do local src = Source(i) w[src] = true d["k" .. i] = src end local s = Store(d) s:Of("extra") w[s] = true end
	gc() print(" c1 plain Store + 1000 Sources dropped -> alive", count(w))
end
do -- c2: store dropped, a Compute over one field kept (dependency keeps that Source only)
	local w = setmetatable({}, { __mode = "k" })
	local keep
	do local d = {} for i = 1, 100 do local src = Source(i) w[src] = true d["k" .. i] = src end local s = Store(d) keep = s.k1:Compute(function(h) return h:Get() end) w[s] = true end
	gc() print(" c2 Store dropped, Compute over k1 kept -> alive", count(w), "(expect 1: k1)")
	keep = nil gc() print("    Compute dropped too -> alive", count(w))
end
do -- c3: Attr(store) on an instance; instance Destroy'd then everything dropped
	local w = setmetatable({}, { __mode = "k" })
	local inst = mock.Instance.new("Frame")
	do local d = {} for i = 1, 100 do local src = Source(i) w[src] = true d["k" .. i] = src end local s = Store(d) w[s] = true q.Dispatch.drive(inst, { q.Attr(s) }) end
	gc() print(" c3 Attr(store) on a live instance, store dropped -> alive", count(w), "(Sources held by the binding; Store itself?)")
	inst:Destroy() gc() print("    after inst:Destroy() -> alive", count(w))
	inst = nil gc() print("    after dropping inst -> alive", count(w))
end
do -- c4: Store brand registry must not pin a Store
	local w = setmetatable({}, { __mode = "k" })
	for _ = 1, 1000 do w[Store({ a = Source(1) })] = true end
	gc() print(" c4 1000 Stores in brand registry -> alive", count(w))
end
