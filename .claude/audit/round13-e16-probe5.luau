--!nocheck
-- round13 E16 probe 5 (2026-09-27): which same-priority FALLBACK guard wins (Ref vs PreRef/PostRef) under
-- the mock backend (spec setup) vs the quad-roblox provider. Run from repo root: luau .claude/audit/round13-e16-probe5.luau
local mock = require("../../quad-base/test/mock")
local function first(e) return (tostring(e):gsub("\n.*", "")) end
local q = mock.newQuad()
for _, v in { q.PreRef(nil), q.PostRef(nil) } do
	local inst = mock.Instance.new("Frame")
	local ok, e = pcall(function() q.Dispatch.drive(inst, { q.Source(v) }) end)
	print("mock newQuad State<" .. tostring(v):match("^%a+") .. ">", first(e))
	local ok2, e2 = pcall(function() q.Dispatch.drive(mock.Instance.new("Frame"), { Foo = v }) end)
	print("mock newQuad Foo=" .. tostring(v):match("^%a+"), first(e2))
end
local names = {}
for _, h in q.Dispatch.listHandlers() do if (h.name or ""):find("Guard") then table.insert(names, h.name) end end
print("guard scan order (mock):", table.concat(names, ", "))
