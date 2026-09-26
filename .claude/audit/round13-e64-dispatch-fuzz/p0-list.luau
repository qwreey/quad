--!nocheck
-- E64 p0: registry dump before/after provider, band values
local Quad = require("../../../quad-roblox/luau_packages/quad_base")
local mock = require("../../../quad-base/test/mock")
local q = Quad.New()
q:UseProvider(mock.mockProvider)
print("bands", q.Dispatch.HANDLER_PRIORITY_HIGH, q.Dispatch.HANDLER_PRIORITY_NORMAL, q.Dispatch.HANDLER_PRIORITY_LOW, q.Dispatch.HANDLER_PRIORITY_FALLBACK)
print("-- base+mock backend")
for i, h in q.Dispatch.listHandlers() do print(i, h.name, h.priority, h.keyType) end
local H = require("../round13-e44-ref-statemachine/harness")
print("-- quad-roblox provider")
for i, h in H.q.Dispatch.listHandlers() do print(i, h.name, h.priority, h.keyType) end
print("q.addProcessedHandler?", q.addProcessedHandler, q.Dispatch.addProcessedHandler)
