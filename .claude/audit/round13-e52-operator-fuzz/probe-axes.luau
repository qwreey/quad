--!nocheck
-- E52 separate axes: (a) recovery after a throw, (b) Indexed keys & nesting, misc edges, (d) perf.
local q = require("../../../quad-base/src")
local Op, None = q.Operator, q.None
local function id(e) local s = tostring(e); return s:match("Quad%d%d%d%d") or ("RAW " .. s) end
local function G(s) local ok, v = pcall(function() return s:Get() end); if ok then return "=" .. tostring(v) end return "!" .. id(v) end
local function T(label, f) local ok, v = pcall(f); print(label, if ok then ("ok " .. tostring(v)) else ("ERR " .. id(v))) end
local function msg(f) local ok, v = pcall(f); return tostring(v) end

print("== (a) recovery after a throw (H-540)")
do
	local a, b = q.Source(1), q.Source(nil)
	local s = a:Apply(Op.Sum(b))
	print("a1 b=nil", G(s), "reread", G(s))
	b:Set(2); print("a1 b=2", G(s))
	b:Set("x"); print("a1 b='x'", G(s)); a:Set(5); print("a1 a=5 (b still 'x')", G(s)); b:Set(3); print("a1 b=3", G(s))
	-- chained: Indexed throws, outer Sum only-dep Set -> inner stuck?
	local t, c = q.Source(5), q.Source(1)
	local inner = t:Apply(Op.Indexed("x"))
	local outer = inner:Apply(Op.Sum(c))
	print("a2 t=5", G(outer)); c:Set(2); print("a2 after c:Set(2) (only outer dep moved)", G(outer))
	print("a2 inner direct", G(inner))
	t:Set({ x = 10 }); print("a2 t={x=10}", G(outer))
	-- Clamp crossing bounds then recover
	local x, lo, hi = q.Source(50), q.Source(0), q.Source(100)
	local cl = x:Apply(Op.Clamp(lo, hi))
	print("a3", G(cl)); lo:Set(200); print("a3 lo=200", G(cl), G(cl)); hi:Set(300); print("a3 hi=300", G(cl))
	-- the downstream Compute of a thrown operator
	local y, z = q.Source(1), q.Source(nil)
	local m = y:Apply(Op.Max(z))
	local down = m:Compute(function(h) return h:Get() * 2 end)
	print("a4", G(down)); z:Set(9); print("a4 z=9", G(down))
	-- Alternative default state nil only when read
	local v, d = q.Source(nil), q.Source(nil)
	local alt = v:Apply(Op.Alternative(d))
	print("a5", G(alt)); v:Set(1); print("a5 v=1 (default still nil, not read)", G(alt)); v:Set(nil); print("a5 v=nil", G(alt)); d:Set(0); print("a5 d=0", G(alt))
end

print("== (b) Indexed keys & nesting")
do
	local t = { a = { b = 7 }, [1] = "one", [0.5] = "half", [true] = "yes" }
	local k = {}; t[k] = "tablekey"
	local f = function() end; t[f] = "fnkey"
	local s = q.Source(t)
	for _, key in { "a", 1, 0.5, true, false, k, f, 0 / 0, None, "missing" } do
		local ok, r = pcall(function() return s:Apply(Op.Indexed(key)):Get() end)
		print("b1 key", tostring(key), ok and tostring(r) or id(r))
	end
	T("b2 key nil", function() return Op.Indexed(nil) end)
	T("b2 key State", function() return Op.Indexed(q.Source("a")) end)
	T("b2 key Derived State", function() return Op.Indexed(q.Source("a"):Compute(function(h) return h:Get() end)) end)
	local nested = s:Apply(Op.Indexed("a")):Apply(Op.Indexed("b"))
	print("b3 nested a.b", G(nested))
	s:Set({ a = { b = 8 } }); print("b3 after Set", G(nested))
	s:Set({}); print("b3 a missing -> inner nil -> outer", G(nested))
	print("b3 message", msg(function() return nested:Get() end))
	s:Set({ a = { b = 9 } }); print("b3 recover", G(nested))
	-- None
	local n = q.Source(None)
	print("b4 None[\"a\"]", G(n:Apply(Op.Indexed("a"))), "None[\"__quadNone\"]", G(n:Apply(Op.Indexed("__quadNone"))))
	-- metatable __index
	local mt = q.Source(setmetatable({}, { __index = function(_, key) return "via:" .. tostring(key) end }))
	print("b5 __index", G(mt:Apply(Op.Indexed("zz"))))
	-- in-place mutation is not seen (whole-value replacement only, sugar/02:268)
	local tt = { a = 1 }; local src = q.Source(tt); local ia = src:Apply(Op.Indexed("a"))
	print("b6", G(ia)); tt.a = 2; print("b6 mutated in place, no Set", G(ia)); src:Set(tt); print("b6 Set same table", G(ia))
	-- Indexed on a string (strings have a metatable __index=string)
	local str = q.Source("hello")
	print("b7 string target", G(str:Apply(Op.Indexed("len"))))
end

print("== misc")
do
	local x = q.Source(3)
	print("m1 self as dep Sum(x)", G(x:Apply(Op.Sum(x))), "Sum(x,x)", G(x:Apply(Op.Sum(x, x))), "Product(x,x,x)", G(x:Apply(Op.Product(x, x, x))))
	local S = Op.Sum(1)
	local a1, a2 = x:Apply(S), x:Apply(S)
	x:Set(10); print("m2 same factory twice on same State", G(a1), G(a2), rawequal(a1, a2))
	print("m3 zero-arg", G(q.Source(-1):Apply(Op.Band())), G(q.Source(1.5):Apply(Op.Bor())), G(q.Source(0/0):Apply(Op.Bxor())), "vs 1-arg", G(q.Source(-1):Apply(Op.Band(0xFFFFFFFF))), "vs Bnot(Bnot)", G(q.Source(-1):Apply(Op.Bnot):Apply(Op.Bnot)))
	print("m3 Sum()/Min()/Max()", G(q.Source(4):Apply(Op.Sum())), G(q.Source(0/0):Apply(Op.Min())), G(q.Source("s"):Apply(Op.Max())))
	T("m4 Clamp()", function() return Op.Clamp() end)
	T("m4 Clamp(1)", function() return Op.Clamp(1) end)
	T("m4 Clamp(0,1,'junk')", function() return q.Source(5):Apply(Op.Clamp(0, 1, "junk")):Get() end)
	T("m4 Shl()", function() return Op.Shl() end)
	T("m4 Shl(1, 'junk')", function() return q.Source(1):Apply(Op.Shl(1, "junk")):Get() end)
	T("m4 Sum(1, nil)", function() return Op.Sum(1, nil) end)
	T("m4 Sum('5')", function() return Op.Sum("5") end)
	T("m4 Alternative()", function() return Op.Alternative() end)
	T("m4 Indexed()", function() return Op.Indexed() end)
	T("m5 Op.Sum(1)(5)", function() return Op.Sum(1)(5) end)
	T("m5 Op.Not(5)", function() return Op.Not(5) end)
	T("m5 Op.Not(State) direct", function() return Op.Not(q.Source(false)):Get() end)
	T("m6 price:Apply(Op.Sum) (curried not called)", function() return type(q.Source(1):Apply(Op.Sum)) end)
	T("m6 price:Apply(Op.Clamp)", function() return type(q.Source(1):Apply(Op.Clamp)) end)
	T("m6 price:Apply(Op.Alternative)", function() return type(q.Source(1):Apply(Op.Alternative)) end)
	T("m6 price:Apply(Op.Indexed)", function() return type(q.Source(1):Apply(Op.Indexed)) end)
	T("m6 price:Apply(Op.Shl)", function() return type(q.Source(1):Apply(Op.Shl)) end)
	print("m7 Not", G(q.Source(nil):Apply(Op.Not)), G(q.Source(None):Apply(Op.Not)), G(q.Source(0):Apply(Op.Not)), G(q.Source(""):Apply(Op.Not)), G(q.Source(false):Apply(Op.Not)))
	print("m8 Alternative", G(q.Source(nil):Apply(Op.Alternative(false))), G(q.Source(false):Apply(Op.Alternative(true))), G(q.Source(None):Apply(Op.Alternative(1))), G(q.Source(nil):Apply(Op.Alternative(None))))
	print("m9 Clamp NaN target", G(q.Source(0/0):Apply(Op.Clamp(0, 1))), "-0", 1 / q.Source(-0):Apply(Op.Clamp(0, 1)):Get(), "lo==hi", G(q.Source(9):Apply(Op.Clamp(3, 3))), "inf bounds", G(q.Source(5):Apply(Op.Clamp(-math.huge, math.huge))), "lo=inf", G(q.Source(5):Apply(Op.Clamp(math.huge, math.huge))))
	print("m9 Clamp lo>hi plain literals: factory ok, raise at read", G(q.Source(5):Apply(Op.Clamp(10, 0))))
	print("m10 Sum inf-inf", G(q.Source(math.huge):Apply(Op.Sum(-math.huge))), "Product 0*inf", G(q.Source(0):Apply(Op.Product(math.huge))), "2^53+1", string.format("%.0f", q.Source(2^53):Apply(Op.Sum(1)):Get()))
	print("m11 target nil + Clamp bounds bad: which error first", G(q.Source(nil):Apply(Op.Clamp(5, 0))), "target nil + arg nil (Sum)", G(q.Source(nil):Apply(Op.Sum(q.Source(nil)))))
	print("m12 messages")
	print("  ", msg(function() return q.Source(nil):Apply(Op.Sum(1)):Get() end))
	print("  ", msg(function() return q.Source(1):Apply(Op.Sum(q.Source("2"))):Get() end))
	print("  ", msg(function() return q.Source(1):Apply(Op.Sum(q.Source(None))):Get() end))
	print("  ", msg(function() return q.Source(None):Apply(Op.Sum(1)):Get() end))
	print("  ", msg(function() return q.Source(5):Apply(Op.Clamp(0 / 0, 1)):Get() end))
end

print("== (d) perf")
do
	local deps = {}
	for i = 1, 100 do deps[i] = q.Source(i) end
	local base = q.Source(0)
	local t0 = os.clock()
	local s = base:Apply(Op.Sum(table.unpack(deps)))
	local build = os.clock() - t0
	t0 = os.clock()
	for i = 1, 10000 do deps[(i % 100) + 1]:Set(i); s:Get() end
	local dt = os.clock() - t0
	print(string.format("d1 Sum(100 States): build %.2f ms, 10k Set+Get %.1f ms (%.2f us/recompute), final %s", build * 1000, dt * 1000, dt * 1e6 / 10000, tostring(s:Get())))
	local lits = {} for i = 1, 100 do lits[i] = i end
	local s2 = base:Apply(Op.Sum(table.unpack(lits)))
	t0 = os.clock()
	for i = 1, 10000 do base:Set(i); s2:Get() end
	dt = os.clock() - t0
	print(string.format("d2 Sum(100 literals): 10k Set+Get %.1f ms (%.2f us/recompute)", dt * 1000, dt * 1e6 / 10000))
	local c = base:Compute(function(h, _, ...) local acc = h:Get() for _, d in { ... } do acc += d:Get() end return acc end, table.unpack(deps))
	t0 = os.clock()
	for i = 1, 10000 do deps[(i % 100) + 1]:Set(i); c:Get() end
	dt = os.clock() - t0
	print(string.format("d3 hand-written Compute (100 deps) baseline: 10k Set+Get %.1f ms", dt * 1000))
end
