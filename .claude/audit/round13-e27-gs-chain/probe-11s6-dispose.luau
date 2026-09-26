--!nocheck
-- E27 최소 재현: GS 11 §6 "State 자리에 지금 놓여 있는 원소는 q.dispose도 막지 않으니" vs 실제
local H = require("./harness")
local q, D = H.q, H.D
const cur = q.Source(nil)
const host = D.Frame { D.TextLabel { Text = "머리" }, cur }
const a = D.TextLabel { Text = "A" }
cur:Set(a)
print(pcall(q.dispose, a))
print("a destroyed?", H.mock.isDestroyed(a), "a.Parent == host?", a.Parent == host)
