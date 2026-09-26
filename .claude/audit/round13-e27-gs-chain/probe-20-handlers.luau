--!nocheck
-- E27: GS 20 §1 listHandlers 순서 출력
local H = require("./harness")
local q = H.q
local t = {}
for _, h in q.Dispatch.listHandlers() do table.insert(t, h.name .. "(" .. tostring(h.priority) .. ")") end
print(table.concat(t, ", "))
