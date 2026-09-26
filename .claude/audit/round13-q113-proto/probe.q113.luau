--!nocheck
-- round13 P-Q113 — Slot element State path cycle check (Quad0070). Run from a variant root.
local H = require("./round13-e15-probe-setup")
local q, D = H.q, H.D
local function loc(err) local s = tostring(err):gsub("\n.*", ""); return (s:match("([%w%-%.]+%.luau:%d+):") or "?") .. " | " .. (s:match("(Quad%d%d%d%d [%w:]+)") or s:sub(-60)) end
local function kids(f) local t = {} for _, c in f:GetChildren() do table.insert(t, c.Name) end return table.concat(t, ",") end
local function st(sl, f) return ("kids[%s] Length=%s"):format(kids(f), tostring(sl.Length:Get())) end
local function t(label, fn) local ok, err = pcall(fn); print("  " .. label, ok and "ok" or loc(err)); return ok end
local function sec(n, fn) print("=== " .. n); local ok, e = pcall(fn); if not ok then print("  !! " .. loc(e)) end end

sec("C1 mounted element st:Set(st), then Length/next Set/Add/Remove", function()
	local s = q.Source(D.Frame { Name = "a" })
	local sl = q.Slot { s }; local f = D.Frame { sl }
	t("st:Set(st)", function() s:Set(s) end); print("   ", st(sl, f))
	t("st:Set(b)", function() s:Set(D.Frame { Name = "b" }) end); print("   ", st(sl, f))
	local okb, blk = pcall(function() return q.Bookkeeping.getBlocker(sl) end)
	print("    blocker.Blocking =", okb and tostring(blk.Blocking) or ("? " .. tostring(blk)))
	t("sl:Add(c)", function() sl:Add(D.Frame { Name = "c" }) end); print("   ", st(sl, f))
	t("sl:Remove(1)", function() sl:Remove(1) end); print("   ", st(sl, f))
	t("s:Set(d) after removal", function() s:Set(D.Frame { Name = "d" }) end); print("   ", st(sl, f))
end)
sec("C2 two-State cycle through inner wrapper b:Set(a)", function()
	local b = q.Source(D.Frame { Name = "b" }); local a = q.Source(b)
	local sl = q.Slot { D.Frame { Name = "z" }, a }; local f = D.Frame { sl }
	t("b:Set(a)", function() b:Set(a) end); print("   ", st(sl, f))
	t("a:Set(a) (outer self)", function() a:Set(a) end); print("   ", st(sl, f))
	t("a:Set(y)", function() a:Set(D.Frame { Name = "y" }) end); print("   ", st(sl, f))
end)
sec("C3 three-hop a->b->c->b (cycle not through a)", function()
	local c = q.Source(D.Frame { Name = "c" }); local b = q.Source(c); local a = q.Source(b)
	local sl = q.Slot { a }; local f = D.Frame { sl }
	t("c:Set(b)", function() c:Set(b) end); print("   ", st(sl, f))
	t("c:Set(k)", function() c:Set(D.Frame { Name = "k" }) end); print("   ", st(sl, f))
end)
sec("C4 unmounted Slot{st}, THEN st:Set(st), then mount", function()
	local s = q.Source(D.Frame { Name = "a" })
	local sl = q.Slot { s }
	t("st:Set(st) (unmounted)", function() s:Set(s) end)
	local f; t("mount D.Frame{sl}", function() f = D.Frame { sl } end)
	if f then print("   ", st(sl, f)) end
	t("st:Set(b) after", function() s:Set(D.Frame { Name = "b" }) end)
	if f then print("   ", st(sl, f)) end
end)
sec("C5 user-level sl:Single(st) (no updateFn), st:Set(st)", function()
	local s = q.Source(D.Frame { Name = "a" })
	local sl = q.Slot(); sl:Single(s); local f = D.Frame { sl }
	t("st:Set(st)", function() s:Set(s) end); print("   ", st(sl, f))
	t("st:Set(b)", function() s:Set(D.Frame { Name = "b" }) end); print("   ", st(sl, f))
end)
sec("C6 sl:List(stateArray, pass-through updateFn), an item State becomes cyclic", function()
	local x = q.Source(D.Frame { Name = "x" }); local y = q.Source(D.Frame { Name = "y" })
	local sl = q.Slot(); sl:List({ x, y }, function(ctx) if ctx.Item == q.KeyGone then return nil end return ctx.Item end); local f = D.Frame { sl }
	print("   ", st(sl, f))
	t("y:Set(y)", function() y:Set(y) end); print("   ", st(sl, f))
	t("y:Set(w)", function() y:Set(D.Frame { Name = "w" }) end); print("   ", st(sl, f))
end)
sec("C7 sl:List(data, updateFn) returning a cyclic State (non-identity)", function()
	local cyc = q.Source(0); cyc:Set(cyc)
	local data = q.Source({ 1 })
	local sl = q.Slot(); sl:List(data, function(ctx) if ctx.Item == 2 then return cyc end if ctx.Item == q.KeyGone then return nil end return D.Frame { Name = "i" .. ctx.Item } end)
	local f = D.Frame { sl }
	print("   ", st(sl, f))
	t("data:Set({2})", function() data:Set({ 2 }) end); print("   ", st(sl, f))
	t("data:Set({3})", function() data:Set({ 3 }) end); print("   ", st(sl, f))
	t("data:Set({4,5})", function() data:Set({ 4, 5 }) end); print("   ", st(sl, f))
	local bk = q.Bookkeeping; local okb, blk = pcall(function() return bk.getBlocker(sl) end)
	print("    blocker.Blocking after =", okb and tostring(blk.Blocking) or ("? " .. tostring(blk)))
	t("data:Set({2,6}) (cycle mid-list)", function() data:Set({ 2, 6 }) end); print("   ", st(sl, f))
	t("data:Set({7})", function() data:Set({ 7 }) end); print("   ", st(sl, f))
end)
sec("C8 CRUD sl:Add(cyclic State) / Replace / Splice", function()
	local cyc = q.Source(0); cyc:Set(cyc)
	local sl = q.Slot { D.Frame { Name = "z" } }; local f = D.Frame { sl }
	t("sl:Add(cyc)", function() sl:Add(cyc) end); print("   ", st(sl, f))
	t("sl:Replace(1, cyc)", function() sl:Replace(1, cyc) end); print("   ", st(sl, f))
	t("sl:Splice(1,0,cyc)", function() sl:Splice(1, 0, cyc) end); print("   ", st(sl, f))
	t("sl:Add(ok)", function() sl:Add(D.Frame { Name = "ok" }) end); print("   ", st(sl, f))
end)
sec("C9 legit deep chain State<State<State<Frame>>> still mounts; swap depth", function()
	local a = q.Source(q.Source(q.Source(D.Frame { Name = "deep" })))
	local sl = q.Slot { a }; local f = D.Frame { sl }
	print("   ", st(sl, f))
	t("a:Set(Source(Frame n))", function() a:Set(q.Source(D.Frame { Name = "n" })) end); print("   ", st(sl, f))
end)
sec("C10 same State twice in chain but no cycle (diamond: a->b, c->b)", function()
	local b = q.Source(D.Frame { Name = "b" })
	local a = q.Source(b)
	local sl = q.Slot { a }; local f = D.Frame { sl }
	local c = q.Source(b)
	t("a:Set(c)", function() a:Set(c) end); print("   ", st(sl, f))
end)
sec("C11 after the raise, the wrapper must still recompute Length (State<Slot> swap)", function()
	local s = q.Source(D.Frame { Name = "a" })
	local sl = q.Slot { s, D.Frame { Name = "z" } }; local f = D.Frame { sl }
	t("s:Set(s)", function() s:Set(s) end); print("   ", st(sl, f))
	t("s:Set(Slot{p,q,r})", function() s:Set(q.Slot { D.Frame { Name = "p" }, D.Frame { Name = "q" }, D.Frame { Name = "r" } }) end); print("   ", st(sl, f))
	t("s:Set(Frame m)", function() s:Set(D.Frame { Name = "m" }) end); print("   ", st(sl, f))
end)
sec("C12 comparison (pre-existing): non-identity updateFn returns a non-mountable string mid-list", function()
	local data = q.Source({ 1 })
	local sl = q.Slot(); sl:List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end if ctx.Item == 2 then return "bad" end return D.Frame { Name = "i" .. ctx.Item } end)
	local f = D.Frame { sl }
	t("data:Set({2})", function() data:Set({ 2 }) end); print("   ", st(sl, f))
	t("data:Set({4,5})", function() data:Set({ 4, 5 }) end); print("   ", st(sl, f))
end)
