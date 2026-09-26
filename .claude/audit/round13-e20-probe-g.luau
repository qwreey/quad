--!nocheck
-- round13 E20 probe G — q.dispose on the handles themselves; Observer fn disposing its host mid-wave. Run from repo root.
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance
local q = mock.newQuad()
local function E(f, ...)
	local ok, err = pcall(f, ...)
	if ok then return "ok" end
	return (tostring(err):match("Quad%d+[^\n]*") or tostring(err):sub(1, 100))
end
local src = q.Source(0)
local o = src:Observer(function() end)
local e = q.Effect(function() end, src)
print("dispose(observer):", E(q.dispose, o))
print("dispose(effect):", E(q.dispose, e))
local host = Instance.new("Frame")
local runs = 0
local o2 = src:Observer(function(_, self, from) if from then runs += 1; q.dispose(host) end end)
q.Dispatch.drive(host, { o2 })
print("observer disposes own host in fn:", E(function() src:Set(1) end), "runs", runs, "exe", q.Backend.canExecute(o2), "running", o2._running)
src:Set(2)
print("  next Set runs", runs)
