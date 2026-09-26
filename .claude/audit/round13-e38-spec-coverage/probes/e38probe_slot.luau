local mock = require("./mock")
local q = mock.newQuad()
local Instance = mock.Instance
local Slot, dispatch = q.Slot, q.Dispatch
local function kids(p) local t = {} for _, c in p:GetChildren() do table.insert(t, c.Name) end return table.concat(t, ",") end
local function try(label, f) local ok, e = pcall(f) print(label, ok and "ok" or ("ERR " .. tostring(e))) return ok, e end
local function F(n) local f = Instance.new("Frame"); f.Name = n; return f end

print("--- P1 Replace before mount (never mounted): old destroyed?")
do
	local s = Slot(); local a, b = F("a"), F("b"); s:Add(a); s:Replace(1, b)
	print("a destroyed", mock.isDestroyed(a), "a.Parent", a.Parent, "Get(1)==b", s:Get(1) == b)
	local p = Instance.new("Folder"); dispatch.drive(p, { s }); print("mounted kids", kids(p), "Length", s.Length:Get())
end

print("--- P2 Replace mounted: Slot -> plain, plain -> Slot")
do
	local inner = Slot(); inner:Add(F("i1")); inner:Add(F("i2"))
	local s = Slot(); s:Add(F("x")); s:Add(inner); s:Add(F("y"))
	local p = Instance.new("Folder"); dispatch.drive(p, { s })
	print("before", kids(p), s.Length:Get())
	local i1 = inner:Get(1)
	local z = F("z"); s:Replace(2, z)
	print("after Slot->plain", kids(p), "Length", s.Length:Get(), "i1 destroyed", mock.isDestroyed(i1), "Offsets", s:IndexOf(z))
	local inner2 = Slot(); inner2:Add(F("k1")); inner2:Add(F("k2")); inner2:Add(F("k3"))
	s:Replace(2, inner2)
	print("after plain->Slot", kids(p), "Length", s.Length:Get(), "z destroyed", mock.isDestroyed(z), "inner2.Offset", inner2.Offset:Get())
	s:Add(F("w")); print("tail add", kids(p), s.Length:Get())
	-- Extract variant (destroyOld=false)
	local got = s:Extract(2, F("e")); print("Extract Slot->plain", kids(p), s.Length:Get(), "returned inner2?", got == inner2, "k1 destroyed", mock.isDestroyed(inner2:Get(1)))
end

print("--- P3 List duplicate key / non-array data from State")
do
	local data = q.Source({ { id = 1 }, { id = 2 } })
	local s = Slot()
	s:List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end return ctx.Prev or F(tostring(ctx.Item.id)) end, function(it) return it.id end)
	local p = Instance.new("Folder"); dispatch.drive(p, { s })
	print("initial", kids(p), s.Length:Get())
	try("dup key", function() data:Set({ { id = 1 }, { id = 1 } }) end)
	print("after dup", kids(p), s.Length:Get(), "data:Get #", #data:Get())
	try("non-array", function() data:Set(5 :: any) end)
	try("recover", function() data:Set({ { id = 3 } }) end)
	print("after recover", kids(p), s.Length:Get())
	try("dup key at initial mount", function()
		local s2 = Slot(); s2:List({ { id = 1 }, { id = 1 } }, function(ctx) return F("d") end, function(it) return it.id end)
		dispatch.drive(Instance.new("Folder"), { s2 })
	end)
end

print("--- P4 List Detach with OwnsElements=false (mounted)")
do
	local show = q.Source(true)
	local data = q.Source({ { id = "x" } })
	local s = Slot(); local made, frames = 0, {}
	s:List(data, function(ctx)
		if ctx.Item == q.KeyGone then return q.Detach end
		if not show:Get() then return q.Detach end
		if ctx.Prev then return ctx.Prev end
		made += 1; local f = F("x" .. made); frames[made] = f; return f
	end, function(it) return it.id end, { OwnsElements = false })
	local p = Instance.new("Folder"); dispatch.drive(p, { s })
	show:Set(false); data:Set({ { id = "x" } })
	print("detached(non-owned)", kids(p), "Length", s.Length:Get(), "x1 destroyed", mock.isDestroyed(frames[1]), "x1.Parent", frames[1].Parent, "_detached", s._detached and s._detached.x)
	show:Set(true); data:Set({ { id = "x" } })
	print("re-show", kids(p), "made", made, "Length", s.Length:Get())
	try("dispose x1 (user's now)", function() q.dispose(frames[1]) end)
end

print("--- P5 List: detached key comes back with a NEW element (settle 77-79)")
do
	local show = q.Source(true); local data = q.Source({ { id = "x" } })
	local s = Slot(); local made, frames = 0, {}
	s:List(data, function(ctx)
		if ctx.Item == q.KeyGone then return q.Detach end
		if not show:Get() then return q.Detach end
		made += 1; local f = F("x" .. made); frames[made] = f; return f -- never reuse Prev
	end, function(it) return it.id end)
	local p = Instance.new("Folder"); dispatch.drive(p, { s })
	show:Set(false); data:Set({ { id = "x" } })
	print("held", kids(p), s._detached and s._detached.x == frames[1])
	show:Set(true); data:Set({ { id = "x" } })
	print("new instead of prev", kids(p), "Length", s.Length:Get(), "x1 destroyed", mock.isDestroyed(frames[1]), "detached cleared", s._detached == nil or s._detached.x == nil)
end

print("--- P6 held (Detach) element fate when owner Slot is destroyed / physical parent destroyed")
do
	local data = q.Source({ { id = "x" } })
	local s = Slot(); local fx
	s:List(data, function(ctx) if ctx.Item == q.KeyGone then return q.Detach end fx = ctx.Prev or F("x"); return fx end, function(it) return it.id end)
	local outer = Slot(); outer:Add(s)
	local p = Instance.new("Folder"); dispatch.drive(p, { outer })
	data:Set({}) -- x held
	print("held", s._detached and s._detached.x == fx, "fx alive", not mock.isDestroyed(fx))
	outer:Remove(1) -- destroys s (owned)
	print("after owner Slot destroyed: fx destroyed", mock.isDestroyed(fx))
end
do
	local data = q.Source({ { id = "x" } })
	local s = Slot(); local fx
	s:List(data, function(ctx) if ctx.Item == q.KeyGone then return q.Detach end fx = ctx.Prev or F("x"); return fx end, function(it) return it.id end)
	local p = Instance.new("Folder"); dispatch.drive(p, { s })
	data:Set({})
	print("held2", s._detached and s._detached.x == fx)
	p:Destroy()
	print("after physical parent Destroy: fx destroyed", mock.isDestroyed(fx), "_detached", s._detached and s._detached.x)
end

print("--- P7 :List installed on an already-mounted empty Slot")
do
	local s = Slot(); local outer = Slot(); outer:Add(F("before")); outer:Add(s); outer:Add(F("after")); local p = Instance.new("Folder"); dispatch.drive(p, { outer })
	print("pre", kids(p), s.Length:Get())
	local data = q.Source({ { id = 1 }, { id = 2 } })
	s:List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end return ctx.Prev or F("L" .. ctx.Item.id) end, function(it) return it.id end)
	print("post-install", kids(p), "Length", s.Length:Get(), "Offset", s.Offset:Get())
	data:Set({ { id = 2 }, { id = 3 } }); print("reconcile", kids(p), s.Length:Get(), "outer.Length", outer.Length:Get(), "after offset", outer:IndexOf(outer:Get(3)))
end
