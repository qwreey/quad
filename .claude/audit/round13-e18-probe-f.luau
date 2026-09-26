--!nocheck
-- round13 E18 probe F — shared leaf values (Blocker/Ref/Context/Tag/Modifier) across two q.New() instances. Run from repo root.
local Quad = require("../../quad-base/src")
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance
local A, B = Quad.New(), Quad.New()
mock.installLifetime(A); mock.installLifetime(B)
local function E(f) local ok, err = pcall(f); return ok and "ok" or (tostring(err):match("Quad%d+[^\n]*") or tostring(err)):sub(1, 200) end
-- Blocker shared by gates of two instances
local blk = A.Blocker()
local sa, sb = A.Source(0), B.Source(0)
local ga, gb = sa:Apply(blk), sb:Apply(blk)
local na, nb = 0, 0
local oa = ga:Observer(function() na += 1 end); oa:Subscribe()
local ob = gb:Observer(function() nb += 1 end); ob:Subscribe()
blk:On(); sa:Set(1); sb:Set(1); sa:Set(2)
print("during On: na,nb", na, nb)
blk:Off()
print("after Off: na,nb", na, nb, "values", ga:Get(), gb:Get())
print("gate owners: ga is A's", ga._moduleIdentity == A.moduleIdentity, "gb is B's", gb._moduleIdentity == B.moduleIdentity)
-- Ref (A.Ref) used in B's tree, then B's Effect depends on it
local r = A.Ref()
local inst = Instance.new("Frame")
print("B drive with A.Ref:", E(function() B.Dispatch.drive(inst, { r }) end), "ref.Value==inst", r.Value == inst)
local runs = 0
local e = B.Effect(function() runs += 1 end, r)
print("B.Effect on A.Ref (dep edge):", E(function() B.Dispatch.drive(Instance.new("Frame"), { e }) end), "runs", runs)
r:Set(Instance.new("Frame")); print("   after r:Set runs", runs)
-- PreRef consumed by one instance then reused in the other
local pre = A.PreRef()
B.Dispatch.drive(Instance.new("Frame"), { pre })
print("PreRef reused in A after B fired:", E(function() A.Dispatch.drive(Instance.new("Frame"), { pre }) end))
-- same Ref in both instances' trees
local r2 = A.Ref()
print("same Ref A then B:", E(function() A.Dispatch.drive(Instance.new("Frame"), { r2 }) end), E(function() B.Dispatch.drive(Instance.new("Frame"), { r2 }) end))
-- Modifier from A with A.State field used in B
local mod = A.Modifier { Name = A.Source("m") }
print("A.Modifier{State} in B:", E(function() B.Dispatch.drive(Instance.new("Frame"), { mod }) end))
-- Operator on mixed instances
print("Operator.Sum(A.s, B.s) result owner:", E(function()
	local s = A.Operator.Sum(A.Source(1), B.Source(2))
	print("   owner A?", s._moduleIdentity == A.moduleIdentity, "value", s:Get())
end))
print("Operator.Sum(B.s, A.s) result owner:", E(function()
	local s = A.Operator.Sum(B.Source(1), A.Source(2))
	print("   owner A?", s._moduleIdentity == A.moduleIdentity, "value", s:Get())
end))
