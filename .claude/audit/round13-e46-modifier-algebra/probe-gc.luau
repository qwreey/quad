--!nocheck
local H = require("./harness")
local q, D = H.q, H.D
local s = q.Source(1)
local w1, w2 = setmetatable({}, { __mode = "v" }), setmetatable({}, { __mode = "v" })
do w1[1] = D.Frame{ ZIndex = s } end
do w2[1] = D.Frame{ q.Modifier{ ZIndex = s } } end
for _ = 1, 5 do collectgarbage("collect") end
print("inline State, dropped undestroyed collected:", w1[1] == nil, "| via Modifier:", w2[1] == nil)
