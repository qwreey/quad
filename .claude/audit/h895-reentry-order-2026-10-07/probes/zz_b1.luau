local mock = require("./mock")
local q = mock.newQuad()
local I = mock.Instance
local function fr(n) local f = I.new("Frame"); f.Name = n; return f end
local a = fr("a")
print(pcall(q.Slot, { a, a }))
print("retry:", pcall(q.Slot, { a }))
print("dispose a:", pcall(q.dispose, a))
collectgarbage() collectgarbage()
print("retry after gc:", pcall(q.Slot, { a }))
