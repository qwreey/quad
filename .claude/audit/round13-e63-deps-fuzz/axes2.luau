--!nocheck
-- E63 axis probes part 2: Ref deps inside Declarations / Slot elements, slot.Length as dep
local H = require("./harness")
local q, D = H.q, H.D
local function hdr(s) print("\n== " .. s) end

for _, mk in { { "Ref", q.Ref }, { "PreRef", q.PreRef }, { "PostRef", q.PostRef } } do
	for _, effFirst in { true, false } do
		hdr(`A15 D.Frame with {mk[1]} + Effect(fn, ref) — effect {effFirst and "before" or "after"} ref`)
		local r = mk[2]()
		local log = {}
		local e = q.Effect(function() table.insert(log, r.Value == nil and "nil" or "inst"); return function(d) table.insert(log, "cl" .. tostring(d)) end end, r)
		local f = if effFirst then D.Frame { e, r } else D.Frame { r, e }
		print("after mount:", table.concat(log, " "))
		f:Destroy()
		print("after Destroy:", table.concat(log, " "), "ref still set:", r.Value == f)
	end
end

hdr("A16 Ref placed in a Slot:List element, element removed (KeyGone → destroy)")
do
	local items = q.Source({ "a", "b" })
	local refs = { a = q.Ref(), b = q.Ref() }
	local n = { a = 0, b = 0 }
	local ea = q.Effect(function() n.a += 1 end, refs.a):Subscribe()
	local eb = q.Effect(function() n.b += 1 end, refs.b):Subscribe()
	local slot = q.Slot():List(items, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Prev then return ctx.Prev end
		return D.Frame { refs[ctx.Item] }
	end)
	local host = D.Frame { slot }
	print("after mount runs a/b", n.a, n.b)
	items:Set({ "a" })
	print("after removing b runs a/b", n.a, n.b, "refs.b still points at destroyed element:", refs.b.Value ~= nil)
	local lenRuns = 0
	local el = q.Effect(function() lenRuns += 1 end, slot.Length):Subscribe()
	items:Set({ "a", "b" }); items:Set({})
	print("Effect(fn, slot.Length): runs after two list changes", lenRuns, "Length", slot.Length:Get())
	items:Set({ "b" })
	print("re-added b: runs b", n.b)
	host:Destroy()
end

hdr("A17 Effect with 0 deps")
do
	local n = 0
	local e = q.Effect(function() n += 1 end)
	e:Rerun(); print("Rerun unsubscribed:", n)
	e:Subscribe(); print("Subscribe after held Rerun:", n)
	e:Rerun(); print("Rerun subscribed:", n)
end

hdr("A18 Effect whose dep node Compute throws: other deps keep driving?")
do
	local a, b = q.Source(0), q.Source(0)
	local c = a:Compute(function(s) if s:Get() == 1 then error("boom", 0) end return s:Get() end)
	local n = 0
	local e = q.Effect(function() n += 1; c:Get() end, c, b):Subscribe()
	local ok, err = pcall(function() a:Set(1) end)
	print("a:Set(1) throws through Set:", not ok, tostring(err):gsub("\n.*", ""))
	b:Set(1); a:Set(2)
	print("runs after death (install+1 attempt):", n)
end

hdr("A19 same handle passed as dep AND bound in the frame that Ref points to")
do
	local r = q.Ref()
	local runs = 0
	local e = q.Effect(function() runs += 1 end, r, r, r)
	local f = D.Frame { r, e }
	print("Frame{ r, e } with Effect(fn, r, r, r): runs (install + one Set)", runs)
end

hdr("A20 error position: first bad argument vs reported index")
do
	local a = q.Source(0)
	local function first(e) return (tostring(e):gsub("\n.*", ""):gsub("^.-(Quad%d%d%d%d)", "%1")) end
	print("a:Depend(5, nil)      ", first(select(2, pcall(function() a:Depend(5, nil) end))))
	print("a:Compute(fn, {}, nil)", first(select(2, pcall(function() a:Compute(function() end, {}, nil) end))))
	print("q.Effect(fn, 5, nil)  ", first(select(2, pcall(function() q.Effect(function() end, 5, nil) end))))
end
