--!nocheck
-- round13 E18 probe E — values from a SECOND quad_base copy (not q.New()) into the first copy. Run from repo root.
local Q1 = require("../../quad-base/src")                       -- copy 1
local Q2 = require("../../quad-roblox/luau_packages/quad_base")  -- copy 2 (same source, separate module load)
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance
local A = Q1.New(); mock.installLifetime(A)
local B = Q2.New(); mock.installLifetime(B)
local function E(f)
	local ok, err = pcall(f)
	if ok then return "ok" end
	local s = tostring(err)
	return (s:match("Quad%d+[^\n]*") or s):sub(1, 220)
end
local function T(name, f) print(name .. " => " .. E(f)) end
print("A.isState(B.Source(1))", A.isState(B.Source(1)), "A.isSlot(B.Slot())", A.isSlot(B.Slot()), "A.isEffect(B.Effect)", A.isEffect(B.Effect(function() end)))
T("copy: numeric B.Observer", function() A.Dispatch.drive(Instance.new("Frame"), { B.Source(1):Observer(function() end) }) end)
T("copy: numeric B.Effect", function() A.Dispatch.drive(Instance.new("Frame"), { B.Effect(function() end) }) end)
T("copy: numeric B.Slot", function() A.Dispatch.drive(Instance.new("Frame"), { B.Slot() }) end)
T("copy: A.Slot():Add(B.Slot())", function() A.Slot():Add(B.Slot()) end)
T("copy: A.Slot():List(B.Source({}))", function() A.Slot():List(B.Source({}), function() return nil end) end)
T("copy: A.dispose(B.Slot())", function() A.dispose(B.Slot()) end)
T("copy: A.Source(1):Depend(B.Source(2))", function() A.Source(1):Depend(B.Source(2)) end)
T("copy: A.Effect(fn, B.Source)", function() A.Effect(function() end, B.Source(1)) end)
T("copy: A.Store{x=B.Source}", function() A.Store({ x = B.Source(1) }) end)
-- string key with mock: add a spec leaf for strings so we see what arrives
local seen
A.Dispatch.addHandler({ name = "Catch", isHandlable = function(_i, k) return k == "Name" end, priority = A.Dispatch.HANDLER_PRIORITY_LOW,
	process = function(_i, _k, v) seen = v; return A.Void end })
T("copy: string key B.Source into A (with a low-priority catch-all for Name)", function() A.Dispatch.drive(Instance.new("Frame"), { Name = B.Source("x") }) end)
print("   Catch handler received:", seen ~= nil and (B.isState(seen) and "B's raw Source table (unwrapped? no)" or tostring(seen)) or "nothing")
