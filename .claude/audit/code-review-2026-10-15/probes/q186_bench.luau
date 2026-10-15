--!nocheck
local mock = require("./mock")
local q = mock.newQuad()
local function F(n) local f = mock.Instance.new("Frame"); f.Name = n; return f end
local depth, N = (_G.DEPTH or 1), 3000
local function build()
	local host = mock.Instance.new("Frame")
	local inner = q.Slot()
	local top = inner
	for _ = 1, depth do top = q.Slot({ top }) end
	q.Dispatch.drive(host, { top })
	return inner
end
local function time(label, f) local t = os.clock(); f(); print(label, depth, string.format("%.1f ms", (os.clock() - t) * 1000)) end
local inner = build()
time("add", function() for i = 1, N do inner:Add(F("x")) end end)
time("remove-each", function() for i = N, 1, -1 do inner:Remove(i) end end)
for i = 1, N do inner:Add(F("x")) end
time("clear", function() inner:Clear() end)
for i = 1, N do inner:Add(F("x")) end
time("extractall", function() inner:ExtractAll() end)
