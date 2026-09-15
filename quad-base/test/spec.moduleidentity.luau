--!strict
--[[
	Cross-instance guard — `moduleIdentity` (2026-09-15 user decision, public surface (12)).
	Values made by one quad module instance cannot be placed into another instance's tree:
	lifetime registries are per instance, so the handle would silently never run there.
	Shared leaf values (Ref/Blocker) have no owning instance and are not guarded.
]]

local Quad = require("../src")
local mock = require("./mock")

local A, B = Quad.New(), Quad.New()
mock.installLifetime(A)
mock.installLifetime(B)
local Instance = mock.Instance

local function expectCross(label: string, f: () -> ())
	local ok, err = pcall(f)
	assert(not ok, label .. ": must error")
	assert(string.find(tostring(err), "another quad module instance", 1, true) ~= nil, label .. ": message: " .. tostring(err))
	assert(string.find(tostring(err), "spec.moduleidentity.luau", 1, true) ~= nil, label .. ": blames the user line: " .. tostring(err))
end

print("=== 1. moduleIdentity — an empty table per instance, never the module ===")
do
	local ia: any, ib: any = A.moduleIdentity, B.moduleIdentity
	assert(type(ia) == "table" and next(ia) == nil, "empty table")
	assert(ia ~= ib, "one per instance")
	assert(type(Quad.moduleIdentity) == "table" and Quad.moduleIdentity ~= ia, "the top-level instance has its own")
	print("PASS")
end

print()
print("=== 2. handles/Slot/State placed into another instance's tree raise at the placement ===")
do
	expectCross("Observer", function()
		A.Dispatch.drive(Instance.new("Frame"), { B.Source(1):Observer(function() end) })
	end)
	expectCross("Effect", function()
		A.Dispatch.drive(Instance.new("Frame"), { B.Effect(function() end) })
	end)
	expectCross("Slot", function()
		A.Dispatch.drive(Instance.new("Frame"), { B.Slot() })
	end)
	expectCross("State", function()
		A.Dispatch.drive(Instance.new("Frame"), { Name = B.Source("x") })
	end)
	expectCross("Slot:List data", function()
		A.Slot():List(B.Source({}), function(_ctx: any) return nil end)
	end)
	-- `:Single` gates at its own entry — the message names Single and the blame is this file (not List.luau)
	local okS, errS = pcall(function()
		A.Slot():Single(B.Source(1))
	end)
	assert(not okS and string.find(tostring(errS), "Slot:Single: this value was made by another quad module instance", 1, true) ~= nil, "Single names itself: " .. tostring(errS))
	assert(string.find(tostring(errS), "spec.moduleidentity.luau", 1, true) ~= nil, "Single blames the user line: " .. tostring(errS))
	print("PASS")
end

print()
print("=== 3. same-instance placement is untouched; reactive links across instances are not guarded ===")
do
	local runs = 0
	A.Dispatch.drive(Instance.new("Frame"), { A.Source(1):Observer(function() runs += 1 end) })
	assert(runs == 1, "own Observer mounts and fires once")
	-- a dependency edge carries no lifetime, so it works across instances and stays allowed
	local s = A.Source(1)
	local effectRuns = 0
	local e = B.Effect(function() effectRuns += 1 end, s)
	e:Subscribe()
	s:Set(2)
	assert(effectRuns == 2, "cross-instance dep edge still reruns")
	e:Unsubscribe()
	print("PASS")
end

print()
print("=== ALL PASS ===")
