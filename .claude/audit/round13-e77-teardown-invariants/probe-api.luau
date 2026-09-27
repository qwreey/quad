--!nocheck
local H = require("./harness")
local q, D, mock = H.q, H.D, H.mock
local function try(name, f) local ok, e = pcall(f); print(name, ok and "ok" or ("ERR " .. H.first(e))) end
local pulse = q.Source(0)
try("modseat", function()
	local m = q.Source(q.Modifier { BackgroundTransparency = 0.5 })
	local f = D.Frame { m }
	print(" bt", f.BackgroundTransparency); m:Set(nil); print(" bt after nil", f.BackgroundTransparency)
	m:Set(q.Modifier { BackgroundTransparency = 0.25 }); print(" bt", f.BackgroundTransparency)
end)
try("single", function()
	local k = q.Source("a")
	local s = q.Slot():Single(k, function(ctx) if ctx.Item == q.KeyGone then return nil end return D.TextLabel { Text = ctx.Item } end)
	local f = D.Frame { s }
	k:Set("b"); print(" n", #f:GetChildren(), f:GetChildren()[1].Text)
end)
try("nested slot", function()
	local inner = q.Slot({ D.Frame {} })
	local outer = q.Slot({ inner, D.Frame {} })
	local f = D.Frame { outer }
	inner:Add(D.Frame {}); print(" n", #f:GetChildren())
	q.dispose(f)
end)
try("ctx", function()
	local P = q.Context.Provider("Theme")
	local c = q.Context():Set(P, q.Source("x"))
	local f = D.TextLabel { Text = c:Get(P) }
	print(" text", f.Text)
end)
try("tween", function()
	local s = q.Source(1)
	local log = {}
	local f = D.Frame { Size = s:Compute(function(self) return q.Tween { Value = self:Get(), Time = 1, Started = function() table.insert(log, "S") end, Completed = function() table.insert(log, "C") end, Cancelled = function() table.insert(log, "X") end } end) }
	s:Set(2); print(" log", table.concat(log, ","), #mock.tweenLog)
	f:Destroy(); for _, t in mock.tweenLog do t.tween:simulateCompleted() end; print(" after", table.concat(log, ","))
	print(" conns on tween.Completed", #mock.tweenLog[#mock.tweenLog].tween.Completed.connections)
end)
try("animate", function()
	local s = q.Source(1)
	local f = D.Frame { Size = s:Apply(q.Animate { Time = 1 }) }
	s:Set(3); print(" tweens", #mock.tweenLog)
end)
try("out/onchange", function()
	local src = q.Source("a")
	local n = 0
	local f = D.TextBox { Text = src, q.Out("Text", src), q.OnChange("Text", function(v) n += 1 end) }
	f.Text = "zz"; print(" src", src:Get(), n)
end)
try("event", function()
	local n = 0
	local b = D.TextButton { Activated = function() n += 1 end }
	b.Activated:Fire(); print(" n", n, #b.Activated.connections)
end)
try("debounce", function()
	local s = q.Source(0)
	local g = s:Apply(q.Debounce { Time = 1 })
	local seen = 0
	local f = D.Frame { g:Observer(function() seen += 1 end) }
	s:Set(1); H.runTask(2); print(" seen", seen, H.pending())
end)
try("throttle", function()
	local s = q.Source(0)
	local f = D.Frame { LayoutOrder = s:Apply(q.Throttle { Time = 1 }) }
	s:Set(1); s:Set(2); H.runTask(2); print(" lo", f.LayoutOrder, H.pending())
end)
try("blocker", function()
	local b = q.Blocker(); local s = q.Source(0)
	local f = D.Frame { LayoutOrder = s:Apply(b) }
	b:On(); s:Set(5); print(" lo", f.LayoutOrder); b:Off(); print(" lo", f.LayoutOrder)
end)
try("hooks", function()
	local log = {}
	local f = D.Frame { q.OnCreated(function() table.insert(log, "c") end), q.OnRendered(function() table.insert(log, "r") end), q.OnDestroyed(function() table.insert(log, "d") end), q.PreRef(), q.PostRef() }
	f:Destroy(); print(" ", table.concat(log))
end)
try("fallback", function()
	local C = q.Fallback(function(p) if p.bad then error("boom") end return D.Frame {} end, function(e) return D.Frame { Name = "fb" } end)
	print(" ", C({ bad = true }).Name)
end)
try("attrkey", function()
	local k = q.AttrKey("A1")
	local f = D.Frame { [k] = 3, q.Attr({ A2 = pulse }), q.Tag("T1") }
	print(" ", f:GetAttribute("A1"), f:GetAttribute("A2"), table.concat(H.CollectionService:GetTags(f), ","))
end)
try("effect", function()
	local log = {}
	local f = D.Frame { q.Effect(function() pulse:Get(); return function(d) table.insert(log, tostring(d)) end end, pulse) }
	pulse:Set(1); q.dispose(f); print(" ", table.concat(log, ","))
end)
try("seat inst", function()
	local seat = q.Source(D.Frame { Name = "c1" })
	local f = D.Frame { seat }
	local c1 = seat:Get(); seat:Set(nil); print(" c1 parent", c1.Parent, mock.isDestroyed(c1))
end)
try("dispose from callback", function()
	local kill = q.Source(0)
	local f
	f = D.Frame { D.Frame { kill:Observer(function() q.dispose(f) end) } }
	kill:Set(1); print(" destroyed", mock.isDestroyed(f))
end)
