--!nocheck
-- axis (f) non-Instance values + the placement cells the fuzzer deliberately skips
local H = require("./harness")
local q, D = H.q, H.D
local function id(e) return tostring(e):match("Quad%d%d%d%d") or ("RAW:" .. H.first(e)) end
local function try(label, f) local ok, e = pcall(f); print(label, ok and "ok" or id(e)); return ok end

-- f1: Set a table / a State / a function; Callback delivery; Unwrap; then placement overwrites
do
	local r = q.Ref(nil)
	local seen = {}
	r:Callback(function(v) table.insert(seen, typeof(v) .. (q.isState(v) and "(State)" or "")) end)
	local st = q.Source(1)
	r:Set({ a = 1 }); r:Set(st); r:Set(print)
	print("f1 deliveries:", table.concat(seen, ","), "Unwrap is fn:", r:Unwrap() == print)
	local f = D.Frame { r }
	print("f1 placed after holding a function: Value is the Frame", r.Value == f)
	r:Set(st) -- user overwrites a bound Ref with a State
	print("f1 bound Ref now holds a State; canBound", q.Backend.canBound(r))
end

-- f2: string keys: arbitrary name vs a reflected property name vs Modifier field
try("f2 Foo = ref:", function() return D.Frame { Foo = q.Ref(nil) } end)
try("f2 Name = ref (reflected prop):", function() return D.Frame { Name = q.Ref(nil) } end)
try("f2 Name = PreRef:", function() return D.Frame { Name = q.PreRef(nil) } end)
try("f2 Size = PostRef:", function() return D.Frame { Size = q.PostRef(nil) } end)
try("f2 Modifier field:", function() return D.Frame { q.Modifier { Foo = q.Ref(nil) } } end)
try("f2 [5] = ref (sparse numeric key):", function() return D.Frame { [5] = q.Ref(nil) } end)
try("f2 dispose(ref):", function() q.dispose(q.Ref(nil)) end)

-- f3: State seat: target bound elsewhere
do
	local a, b = q.Ref(nil), q.Ref(nil)
	local fb = D.Frame { b }
	local st = q.Source(a)
	local g = D.Frame { st }
	local ok, e = pcall(function() st:Set(b) end)
	print("f3 seat a->b (b bound elsewhere):", ok and "ok" or id(e), "| a.Value", a.Value, "| a canBound", q.Backend.canBound(a), "| b.Value==fb", b.Value == fb)
	local ok2, e2 = pcall(function() st:Set(a) end)
	print("f3  then seat ->a:", ok2 and "ok" or id(e2), "| a.Value==g", a.Value == g)
	local ok3, e3 = pcall(function() st:Set(q.None) end)
	print("f3  then seat ->None:", ok3 and "ok" or id(e3), "| a.Value", a.Value)
end

-- f4: State seat after the seat frame is destroyed
do
	local a, b = q.Ref(nil), q.Ref(nil)
	local st = q.Source(a)
	local g = D.Frame { st }
	g:Destroy()
	local n = 0
	a:Callback(function() n += 1 end); n = 0
	local ok, e = pcall(function() st:Set(b) end)
	print("f4 seat Set after Destroy:", ok and "ok" or id(e), "| a.Value==g", a.Value == g, "a calls", n, "| b.Value", b.Value)
end

-- f5: seat -> same Ref again (spurious re-emit dedup), seat -> State<Ref> whose Ref Value is a table
do
	local a = q.Ref(nil)
	local n = 0
	a:Callback(function() n += 1 end); n = 0
	local st = q.Source(a)
	local g = D.Frame { st }
	st:Set(a)
	print("f5 seat same Ref: extra deliveries", n - 1)
end

-- f6: PreRef/PostRef: one-shot after a user :Set, and Unwrap on them
do
	local p = q.PreRef(nil)
	p:Set("x")
	try("f6 PreRef user-Set then placed:", function() return D.Frame { p } end)
	local pp = q.PostRef(nil)
	print("f6 PostRef Unwrap empty:", select(2, pcall(function() return pp:Unwrap() end)) and id(select(2, pcall(function() return pp:Unwrap() end))))
	print("f6 tostring:", tostring(q.Ref(1)), tostring(q.PreRef(nil)), tostring(q.PostRef(2)))
end

-- f7: same Ref in two seats of the SAME frame via State (Quad0232 path through a State)
do
	local a = q.Ref(nil)
	local st = q.Source(q.None)
	local ok, e = pcall(function() return D.Frame { a, st } end)
	local ok2, e2 = pcall(function() st:Set(a) end)
	print("f7 literal + State seat, same frame:", ok and "built" or id(e), "| st:Set(a):", ok2 and "ok" or id(e2))
end

-- f8: the retract Set(nil) when the seat changes while a Wait() waiter throws (H-569 regression)
do
	local a = q.Ref(nil)
	local st = q.Source(a)
	local g = D.Frame { st }
	local co = coroutine.create(function() a:Wait():Unwrap() end)
	coroutine.resume(co)
	local ok, e = pcall(function() st:Set(q.None) end)
	local ok2, e2 = pcall(function() st:Set(a) end)
	print("f8 throwing waiter on retract:", ok and "ok" or id(e), "| re-seat:", ok2 and "ok" or id(e2), "| a.Value==g", a.Value == g)
end
