--!nocheck
-- round13 E23 D — Slot element place: cycles and the pre-pass on State<State<…>> occupants
local H = require("./round13-e15-probe-setup")
local q, D, mock = H.q, H.D, H.mock
local function first(err) return (tostring(err):gsub("\n.*", ""):gsub("^.-(Quad%d%d%d%d)", "%1"):sub(1, 140)) end
local function kids(f) local t = {} for _, c in f:GetChildren() do table.insert(t, c.Name) end return table.concat(t, ",") end
local function sec(name, fn) print("=== " .. name .. " ==="); local ok, err = pcall(fn); if not ok then print("  !! section error:", first(err)) end end
local function tryp(label, fn) local ok, err = pcall(fn); print("  " .. label, ok and "ok" or ("ERR " .. first(err))); return ok end
local function host(el) local sl = q.Slot { el }; local f = D.Frame { Name = "host", sl }; return sl, f end
local function state(sl, f) return ("kids[%s] Length=%s"):format(kids(f), tostring(sl.Length:Get())) end

sec("D1 single-level self: st:Set(st) mounted Slot element", function()
	local st = q.Source(D.Frame { Name = "a" })
	local sl, f = host(st)
	tryp("st:Set(st)", function() st:Set(st) end); print("  ", state(sl, f))
	tryp("st:Set(b)", function() st:Set(D.Frame { Name = "b" }) end); print("  ", state(sl, f))
	tryp("sl:Add(c)", function() sl:Add(D.Frame { Name = "c" }) end); print("  ", state(sl, f))
end)

sec("D2 two-State cycle a->b->a as Slot element (mounted)", function()
	local b = q.Source(D.Frame { Name = "b" })
	local a = q.Source(b)
	local sl, f = host(a)
	tryp("b:Set(a)", function() b:Set(a) end); print("  ", state(sl, f))
	tryp("b:Set(x)", function() b:Set(D.Frame { Name = "x" }) end); print("  ", state(sl, f))
end)

sec("D3 self-holding State given to unmounted Slot, then mount", function()
	local st = q.Source(0); st:Set(st)
	local sl
	tryp("Slot{st}", function() sl = q.Slot { st } end)
	if sl then local f; tryp("mount", function() f = D.Frame { sl } end); if f then print("  ", state(sl, f)) end end
end)

sec("D4 self-holding State at static child place (InstanceChild/StoreBind) for comparison", function()
	local st = q.Source(0); st:Set(st)
	tryp("D.Frame{st}", function() D.Frame { st } end)
end)

sec("D5 Add(Source(Source(a))) where a is held by ANOTHER mounted Slot", function()
	local a = D.Frame { Name = "a" }
	local s1, f1 = host(a)
	local s2, f2 = host(D.Frame { Name = "z" })
	tryp("s2:Add(Source(Source(a)))", function() s2:Add(q.Source(q.Source(a))) end)
	print("  s1", state(s1, f1), "s2", state(s2, f2))
	tryp("s2:Add(fresh) after", function() s2:Add(D.Frame { Name = "fresh" }) end); print("  s2", state(s2, f2))
	-- compare single level
	local s3, f3 = host(D.Frame { Name = "z3" })
	tryp("s3:Add(Source(a)) single level", function() s3:Add(q.Source(a)) end)
	tryp("s3:Add(fresh) after", function() s3:Add(D.Frame { Name = "fresh3" }) end); print("  s3", state(s3, f3))
end)

sec("D6 Add(Source(Source('text'))) — non-mountable inner value", function()
	local s, f = host(D.Frame { Name = "z" })
	tryp("Add(Source(Source('text')))", function() s:Add(q.Source(q.Source("text"))) end); print("  ", state(s, f))
	tryp("Add(fresh) after", function() s:Add(D.Frame { Name = "fresh" }) end); print("  ", state(s, f))
	local s2, f2 = host(D.Frame { Name = "z2" })
	tryp("single Add(Source('text'))", function() s2:Add(q.Source("text")) end)
	tryp("Add(fresh) after", function() s2:Add(D.Frame { Name = "fresh" }) end); print("  ", state(s2, f2))
end)

sec("D7 Add(Source(Source(foreign))) — unclaimed inner", function()
	local s, f = host(D.Frame { Name = "z" })
	tryp("Add(Source(Source(foreign)))", function() s:Add(q.Source(q.Source(mock.Instance.foreign("Frame")))) end); print("  ", state(s, f))
	tryp("Add(fresh) after", function() s:Add(D.Frame { Name = "fresh" }) end); print("  ", state(s, f))
end)

sec("D8 unmounted Slot: Add(Source(Source(a))) with a held elsewhere, then mount", function()
	local a = D.Frame { Name = "a" }
	local s1, f1 = host(a)
	local s = q.Slot {}
	tryp("unmounted Add", function() s:Add(q.Source(q.Source(a))) end)
	local f; tryp("mount", function() f = D.Frame { s } end)
	print("  s1", state(s1, f1))
end)

sec("D9 Slot{ Source(Source(Slot)) } — State<State<Slot>> element; inner swaps Slot", function()
	local inner = q.Source(q.Slot { D.Frame { Name = "p" }, D.Frame { Name = "q" } })
	local outer = q.Source(inner)
	local sl, f = host(outer)
	print("  ", state(sl, f))
	tryp("inner:Set(Slot{r})", function() inner:Set(q.Slot { D.Frame { Name = "r" } }) end); print("  ", state(sl, f))
	tryp("outer:Set(Source(Slot{s,t,u}))", function() outer:Set(q.Source(q.Slot { D.Frame { Name = "s" }, D.Frame { Name = "t" }, D.Frame { Name = "u" } })) end); print("  ", state(sl, f))
end)

sec("D10 Slot element State<State>: outer swapped to a State holding a Slot that CONTAINS this Slot (cycle via state)", function()
	local sl = q.Slot {}
	local outer = q.Source(q.Source(D.Frame { Name = "a" }))
	sl:Add(outer)
	local f = D.Frame { Name = "host", sl }
	local cyc = q.Slot { sl } -- sl already mounted -> should be rejected
	print("  ", state(sl, f))
end)
