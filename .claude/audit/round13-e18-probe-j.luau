--!nocheck
-- round13 E18 probe J — per-instance factories (Debounce/Throttle/hooks) applied to another instance's State. Run from repo root.
local Quad = require("../../quad-base/src")
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance
local A = Quad.New(); mock.installLifetime(A)
local Bare = Quad.New()
local function E(f) local ok, err = pcall(f); return ok and "ok" or (tostring(err):match("Quad%d+[^\n]*") or tostring(err)):sub(1, 220) end
local g
print("A.Source:Apply(Bare.Debounce{Time=1}):", E(function() g = A.Source(0):Apply(Bare.Debounce({ Time = 1 })) end))
if g then
	print("  gate owner A?", g._moduleIdentity == A.moduleIdentity)
	local n = 0
	print("  mount gate in A tree:", E(function() A.Dispatch.drive(Instance.new("Frame"), { g:Observer(function() n += 1 end) }) end))
end
local B = Quad.New(); mock.installLifetime(B)
local src = A.Source(0)
local g2 = src:Apply(B.Debounce({ Time = 1 }))
local n2 = 0
A.Dispatch.drive(Instance.new("Frame"), { g2:Observer(function() n2 += 1 end) })
src:Set(1)
print("pending timers (shared mock clock):", mock.pendingTimers and mock.pendingTimers())
do
	local s = A.Source(0)
	local gg = s:Apply(Bare.Debounce({ Time = 1 }))
	A.Dispatch.drive(Instance.new("Frame"), { gg:Observer(function() end) })
	print("A-owned gate from Bare.Debounce, s:Set(1):", E(function() s:Set(1) end))
end
