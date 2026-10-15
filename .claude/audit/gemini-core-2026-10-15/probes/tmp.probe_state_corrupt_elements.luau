local mock = require("./mock")
local q = mock.newQuad()

local host = mock.Instance.new("Frame")
local rootSlot = q.Slot()
local childSlot = q.Slot()
rootSlot:Add(childSlot)
q.Dispatch.drive(host, { rootSlot })

print("childSlot elements count before:", #childSlot._elements)
local badState = q.Source(123)
pcall(function() childSlot:Add(badState) end)
print("childSlot elements count after:", #childSlot._elements)
print("childSlot element 1:", childSlot._elements[1])