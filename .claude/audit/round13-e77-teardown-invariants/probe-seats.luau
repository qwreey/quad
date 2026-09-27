--!nocheck
local H = require("./harness")
local q, D, mock = H.q, H.D, H.mock
local function try(name, f) local ok, e = pcall(f); print(name, ok and "ok" or ("ERR " .. H.first(e))) end
local p = q.Source(0)
try("tag seat", function() local s = q.Source(q.Tag("T1")); local f = D.Frame { s }; s:Set(q.Tag("T2")); print(table.concat(H.CollectionService:GetTags(f), ",")); s:Set(nil); print(#H.CollectionService:GetTags(f)) end)
try("attr seat", function() local s = q.Source(q.Attr({ A1 = 1 })); local f = D.Frame { s }; s:Set(q.Attr({ A2 = 2 })); print(f:GetAttribute("A1"), f:GetAttribute("A2")) end)
try("obs seat", function() local n = 0; local s = q.Source(p:Observer(function() n += 1 end)); local f = D.Frame { s }; p:Set(1); s:Set(p:Observer(function() n += 10 end)); p:Set(2); print(n) end)
try("eff seat", function() local log = {}; local s = q.Source(q.Effect(function() return function(d) table.insert(log, tostring(d)) end end)); local f = D.Frame { s }; s:Set(nil); f:Destroy(); print(table.concat(log, ",")) end)
try("onchange seat", function() local n = 0; local s = q.Source(q.OnChange("Text", function() n += 1 end)); local f = D.TextBox { s }; f.Text = "a"; s:Set(nil); f.Text = "b"; print(n) end)
try("detach", function()
	local d = q.Source({ 1, 2 })
	local sl = q.Slot():List(d, function(ctx) if ctx.Item == q.KeyGone then return q.Detach end if ctx.Prev then return ctx.Prev end return D.Frame { Name = "k" .. ctx.Item } end)
	local f = D.Frame { sl }; d:Set({ 1 }); print(#f:GetChildren()); d:Set({ 1, 2 }); print(#f:GetChildren()); d:Set({ 1 }); f:Destroy()
end)
try("debounce handle", function()
	local h = q.Ref(nil)
	local g = p:Apply(q.Debounce { Time = 1, Handle = h, MaxTime = 3 })
	local f = D.Frame { LayoutOrder = g }
	p:Set(5); print(h.Value ~= nil, H.pending()); h.Value:Cancel(); print(H.pending())
end)
try("tween completed dispose", function()
	local s = q.Source(1); local f
	f = D.Frame { Size = s:Compute(function(self) return q.Tween { Value = self:Get(), Time = 1, Completed = function() if self:Get() == 2 then q.dispose(f) end end } end) }
	s:Set(2); mock.tweenLog[#mock.tweenLog].tween:simulateCompleted(); print("destroyed", mock.isDestroyed(f))
end)
try("event dispose", function()
	local f; f = D.Frame { D.TextButton { Activated = function() q.dispose(f) end } }
	f:GetChildren()[1].Activated:Fire(); print("destroyed", mock.isDestroyed(f))
end)
try("onchange dispose", function()
	local f; f = D.Frame { D.TextBox { q.OnChange("Text", function(v) if v == "x" then q.dispose(f) end end) } }
	f:GetChildren()[1].Text = "x"; print("destroyed", mock.isDestroyed(f))
end)
