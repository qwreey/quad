--!nocheck
-- E60 targeted axes. luau .claude/audit/round13-e60-store-fuzz/axes.luau
local mock = require("../../../quad-base/test/mock")
local q = mock.newQuad()
local Source, Store = q.Source, q.Store
local function idOf(err) return string.match(tostring(err), "Quad%d%d%d%d") or ("RAW:" .. (tostring(err):gsub("\n.*", ""))) end
local function E(f, ...) local ok, e = pcall(f, ...) return ok and ("ok " .. tostring(e)) or ("ERR " .. tostring(e):gsub("\n.*", "")) end
local function attrs(inst) local t = {} for k, v in mock.getAttributes(inst) do table.insert(t, tostring(k) .. "=" .. tostring(v)) end table.sort(t) return table.concat(t, ",") end

print("== X1 core/04:42 'the passed table becomes the store' vs table.clone")
do
	local d = { hp = Source(1) }
	local s = Store(d)
	d.mp = Source(2)
	print(" store == defaults:", s == d, " late defaults key visible:", s.mp ~= nil, " Names:", table.concat(s:Names(), ","))
	local fz = table.freeze({ hp = Source(3) })
	local s2 = Store(fz)
	print(" frozen defaults accepted:", s2 ~= nil, " store frozen?", table.isfrozen(s2), " Of new on it:", E(function() return s2:Of("mp") ~= nil end))
end

print("== X2 dot read of internal names (core/04:79 'undeclared key -> nil')")
do
	local s = Store({ hp = Source(1) })
	print(" s.__index:", typeof(s.__index), " s.__tostring:", typeof(s.__tostring), " s.Of:", typeof(s.Of), " s.__x:", typeof(s.__x))
	local other = Store({})
	s.__index.zz = Source(9) -- write through the shared metatable
	print(" after s.__index.zz = Source: other.zz:", other.zz ~= nil, " other:Names():", #other:Names(), " other:Of('zz') returns it:", other:Of("zz") == s.__index.zz)
	s.__index.zz = nil
	print(" getmetatable(s) == s.__index:", getmetatable(s) == s.__index)
end

print("== X3 Attr(store) snapshot timing (core/09:267 'the store's declared keys')")
do
	local s = Store({ hp = Source(1) })
	local a = q.Attr(s)
	s:Of("mp"):Set(2)
	local oldHp = s.hp
	s.hp = Source(50) -- type-legal replacement (types-probe2 B1)
	local inst = mock.Instance.new("Frame")
	q.Dispatch.drive(inst, { a })
	print(" Attr built before :Of('mp') and before hp replacement ->", attrs(inst))
	oldHp:Set(7); s.hp:Set(60)
	print(" old hp:Set(7), new hp:Set(60) ->", attrs(inst))
	local inst2 = mock.Instance.new("Frame")
	q.Dispatch.drive(inst2, { q.Attr(s) })
	print(" fresh Attr(s) ->", attrs(inst2))
end

print("== X4 Attr(store) with direct-assigned raw values bypasses the plain-table gates (0007/0008)")
do
	for _, case in { { "table", {} }, { "function", function() end }, { "number", 5 }, { "numeric key", nil } } do
		local s = Store({ hp = Source(1) })
		if case[1] == "numeric key" then rawset(s, 1, Source(3)) else s.x = case[2] end
		local okA, a = pcall(q.Attr, s)
		local inst = mock.Instance.new("Frame")
		local r = if okA then E(function() q.Dispatch.drive(inst, { a }) end) else "Attr() ERR " .. idOf(a)
		print(` {case[1]}: Attr ctor {okA and "ok" or "err"}; drive -> {r}; attrs {attrs(inst)}`)
	end
	-- compare: the same values in a plain table
	print(" plain {x={}}:", E(q.Attr, { x = {} }), " plain {x=fn}:", E(q.Attr, { x = function() end }))
end

print("== X5 tostring / Names under shadowing")
do
	local s = Store({ hp = Source(1) })
	s.Names = function() error("boom") end
	s[true] = 1
	print(" tostring with shadowed Names and boolean key:", E(tostring, s))
	print(" s:Names() now:", E(function() return s:Names() end))
	local s2 = Store({ b = Source(1), a = Source(2), B = Source(3), ["a b"] = Source(4) })
	print(" ordering:", tostring(s2))
	print(" empty:", tostring(Store()), tostring(Store({})))
end

print("== X6 table.clone(store) / copies")
do
	local s = Store({ hp = Source(1) })
	local c = table.clone(s)
	print(" isStore(clone):", q.isStore(c), " clone:Of('hp') == s.hp:", c:Of("hp") == s.hp, " tostring:", tostring(c))
	print(" Attr(clone):", E(q.Attr, c))
end

print("== X7 Of on falsy raw field / Source<Store> field")
do
	local s = Store({})
	s.f = false
	print(" s.f=false; s:Of('f'):", E(function() return s:Of("f") end))
	local inner = Store({ a = Source(1) })
	local s2 = Store({ inner = Source(inner) })
	print(" Source<Store> field Get().a:Get():", s2.inner:Get().a:Get(), " Attr(s2) drive:", E(function() q.Dispatch.drive(mock.Instance.new("Frame"), { q.Attr(s2) }) end))
end

print("== X8 ctor multi-bad precedence (hash order) — same table content, different insertion orders")
do
	local seen = {}
	for i = 1, 200 do
		local d = {}
		local ks = { "", "__a", "x" }
		-- rotate insertion order
		for j = 0, 2 do local k = ks[(i + j) % 3 + 1]; d[k] = if k == "x" then 5 else Source(1) end
		for n = 1, i % 7 do d["pad" .. n] = Source(1) end
		local ok, e = pcall(Store, d)
		seen[idOf(e)] = (seen[idOf(e)] or 0) + 1
	end
	local t = {} for k, v in seen do table.insert(t, k .. ":" .. v) end table.sort(t)
	print(" {'' , '__a', x=5} + padding ->", table.concat(t, " "))
end

print("== X9 same Source under two stores / names, Of reuse after delete")
do
	local shared = Source(1)
	local a, b = Store({ x = shared }), Store({ y = shared, z = shared })
	shared:Set(5)
	print(" a.x==b.y==b.z:", a.x == b.y and b.y == b.z, " values:", a.x:Get(), b.z:Get())
	local dbl = a.x:Compute(function(h) return h:Get() * 2 end)
	a.x = nil
	local fresh = a:Of("x")
	fresh:Set(100)
	print(" after a.x=nil; a:Of('x'):Set(100): dbl =", dbl:Get(), " b.y =", b.y:Get(), " (old Source still shared by b)")
end
