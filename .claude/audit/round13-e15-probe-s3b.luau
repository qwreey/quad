--!nocheck
-- E15 S3 follow-up — what a module-scope Slot does after its host is destroyed with inst:Destroy() (core/06 "마운트 대상이 quad 밖에서 파괴된 Slot" UB).
local H = require("./round13-e15-probe-setup")
local q, D, mock, try = H.q, H.D, H.mock, H.try
-- manual slot
local s = q.Slot()
local host = D.Frame { s }
host:Destroy()
local l
try("manual Add after host Destroy", function() l = D.TextLabel {}; s:Add(l) end)
print("  added label parent", l.Parent, "parent destroyed?", l.Parent and mock.isDestroyed(l.Parent), "label destroyed?", mock.isDestroyed(l), "Length", s.Length:Get())
-- list slot
local data = q.Source({ 1 })
local built = 0
local ls = q.Slot():List(data, function(ctx)
	if ctx.Item == q.KeyGone then return nil, ctx.UserData end
	if ctx.Prev then return ctx.Prev, ctx.UserData end
	built += 1
	return D.TextLabel { Name = "x" .. ctx.Item }, nil
end, function(i) return i end)
local host2 = D.Frame { ls }
host2:Destroy()
data:Set({ 1, 2, 3 })
print("list after host Destroy: built", built, "Length", ls.Length:Get())
