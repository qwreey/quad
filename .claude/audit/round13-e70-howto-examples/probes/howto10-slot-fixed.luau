--!nocheck
-- E70 probe: how-to 10:205 ✅ 줄을 TextLabel로 바꾸면 도는가(Frame에는 Text가 없다 → Quad0076)
local H = require("../harness")
local q, D = H.q, H.D
local items = q.Source({ "a", "b" })
local s2 = q.Slot()
s2:List(items, function(ctx) return D.TextLabel { Text = ctx.Item } end)
local host = D.Frame { s2 }
print("TextLabel kids", #host:GetChildren(), host:GetChildren()[1].Text)
local s3 = q.Slot()
s3:List(items, function(ctx) return D.Frame { Text = ctx.Item } end)
print("Frame+Text:", (select(2, pcall(function() return D.Frame { s3 } end))):gsub("\n.*", ""))
