local H = require("./probe_h")
local q, mock = H.q, H.mock
local Tween = q.Tween
-- E1 SetIfChanged with Tween values (equal target, fresh object)
mock.resetTweenLog()
local src = q.Source(0 :: any)
local f = q.Declaration.Frame({ Name = "F", Size = src }) :: any
local rev0 = src.Revision
src:SetIfChanged(Tween({ Value = 5, Time = 0.2 }))
local rev1 = src.Revision
src:SetIfChanged(Tween({ Value = 5, Time = 0.2 }))
print("E1 SetIfChanged same-target Tween twice: revisions", rev0, rev1, src.Revision, "(second write happened =", src.Revision ~= rev1, ") engine tweens=", #H.log)
-- E2 SetAndDispose on a Source holding Tween values
local ok, err = pcall(function() src:SetAndDispose(Tween({ Value = 9, Time = 0.2 })) end)
print("E2 SetAndDispose(old = Tween) ok=", ok, err and string.sub(tostring(err), 1, 200))
local ok2, err2 = pcall(function() src:SetAndDispose(3) end)
print("E2b SetAndDispose(old = Tween) -> plain ok=", ok2, err2 and string.sub(tostring(err2), 1, 200))
local ok3, err3 = pcall(function() src:SetAndDispose(4) end)
print("E2c SetAndDispose(old = number) ok=", ok3, err3 and string.sub(tostring(err3), 1, 200))
