--!nocheck
-- Does installing the real provider under q.debug=true print any tie line (CHANGELOG [Unreleased]: the two lines are gone)?
local H = require("./harness")
local QuadRoblox = require("../../../quad-roblox/src").QuadRoblox
local m = H.Quad.New()
m.debug = true
print("BEGIN UseProvider under debug")
m:UseProvider(QuadRoblox)
print("END")
for _, h in m.Dispatch.listHandlers() do print("  ", h.name, h.priority, h.keyType) end
