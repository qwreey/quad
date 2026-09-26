local mock = require("./mock")
local q = mock.newQuad()
local Instance = mock.Instance
local dispatch = q.Dispatch
local function try(label, f) local ok, e = pcall(f) print(label, ok and "ok" or ("ERR " .. tostring(e))) return ok, e end
print("start")
local st = q.Store({ A = q.Source(1) }); print("store ok")
try("direct assign", function() (st :: any)[""] = q.Source(2) end)
try("Quad0003 Attr(store with '')", function() q.Attr(st) end)
do
	local s = q.Slot(); q.dispose(s)
	try("destroyed Slot mounted (0140 vs 0164)", function() dispatch.drive(Instance.new("Folder"), { s }) end)
	local f = Instance.new("Frame")
	local s2 = q.Slot()
	s2:List({ 1, 2 }, function(ctx) return f end)
	try("updateFn same element for two keys (0156)", function() dispatch.drive(Instance.new("Folder"), { s2 }) end)
end
