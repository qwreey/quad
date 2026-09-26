--!nocheck
-- E27: GS 18 §2 접힘 "원천마다 게이트" — 중간 상태 막힘·Off 뒤 Text 쓰기 2회·파이프 1회
local H = require("./harness")
local q, D = H.q, H.D
local runs, writes = 0, 0
const count = q.Source(10); const unit = q.Source("점")
const blocker = q.Blocker()
const countText = count:Apply(blocker):Compute(function(c, prev, u) runs += 1; return `{c:Get()} {u:Get()}` end, unit:Apply(blocker))
const lbl = D.TextLabel { Text = countText }
lbl:GetPropertyChangedSignal("Text"):Connect(function() writes += 1 end)
runs = 0
blocker:On(); count:Set(100); local mid = lbl.Text; unit:Set("포인트"); blocker:Off()
print("mid", mid, "final", lbl.Text, "runs", runs, "writes", writes)
