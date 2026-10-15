local mock = require("./mock")
local q = mock.newQuad()

local host = mock.Instance.new("Frame")

local rootSlot = q.Slot()
local parentSlot = q.Slot()
local childSlot = q.Slot()

rootSlot:Add(parentSlot)
parentSlot:Add(childSlot)

-- Mount rootSlot to host
q.Dispatch.drive(host, {
	rootSlot,
})

print("Before invalid Add: rootSlot._materializing =", rootSlot._materializing)
print("Before invalid Add: parentSlot._materializing =", parentSlot._materializing)

-- Now create a Source with a number 123 (invalid element)
local badState = q.Source(123)

-- Try to add badState to childSlot
local ok, err = pcall(function()
	childSlot:Add(badState)
end)

print("Add failed as expected? ok =", ok, "err =", string.sub(tostring(err), 1, 60))
print("After invalid Add: rootSlot._materializing =", rootSlot._materializing)
print("After invalid Add: parentSlot._materializing =", parentSlot._materializing)
print("After invalid Add: childSlot._materializing =", childSlot._materializing)

-- Now try to mutate rootSlot (e.g. Add a valid frame to rootSlot):
local validFrame = mock.Instance.new("Frame")

local ok2, err2 = pcall(function()
	rootSlot:Add(validFrame)
end)
print("Can we mutate rootSlot now? ok =", ok2, "err =", string.sub(tostring(err2), 1, 80))