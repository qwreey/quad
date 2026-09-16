--!nocheck
--[[
	Input gates found by the 2026-09-16 static/execution hunt (round10 — `H-517`~): every public
	entry that takes caller input checks its shape up front and blames the caller's line (the
	`H-419`/`H-441`/`H-446`/`H-493`/`H-497`/`H-504` family). Negative cases only — the positive
	paths are covered by the topic specs.
]]

local mock = require("./mock")
local Quad = require("../src")

local function failsWith(fn, needle, what)
	local ok, err = pcall(fn)
	assert(not ok, what .. ": expected an error")
	assert(string.find(tostring(err), needle, 1, true) ~= nil, what .. ": " .. tostring(err))
	return err
end

print("=== 1. Dispatch.process/retractFrom — index는 양의 정수(hunt F 1) ===")
do
	local q = mock.newQuad()
	local inst = mock.Instance.new("Frame")
	q.Dispatch.drive(inst, { q.Slot() }) -- the mock has no Property handler; a numeric-key Slot chain is enough
	local err = failsWith(function() q.Dispatch.process(inst, 1, q.Slot(), 1.5) end, "Dispatch.process: index must be a positive integer (got 1.5)", "fractional depth")
	mock.assertBlamesUser(err, "spec.inputgates.luau", "process index gate blames the caller")
	failsWith(function() q.Dispatch.retractFrom(inst, 1, 0) end, "Dispatch.retractFrom: index must be a positive integer (got 0)", "zero depth")
	failsWith(function() q.Dispatch.retractFrom(inst, 1, "1") end, "index must be a positive integer (got 1)", "string depth")
	-- a legal depth still works after the rejects (nothing parked at list[1.5])
	q.Dispatch.retractFrom(inst, 1, 1)
	print("PASS")
end

print()
print("=== 2. Modifier:Apply — factory는 함수(hunt F 2, H-497 형제) ===")
do
	local q = mock.newQuad()
	local mod = q.Modifier({ Visible = true })
	local err = failsWith(function() return mod:Apply(nil) end, "Modifier:Apply: factory must be a function (got nil)", "nil factory")
	mock.assertBlamesUser(err, "spec.inputgates.luau", "Apply gate blames the caller")
	failsWith(function() return mod:Apply(5) end, "factory must be a function (got number)", "number factory")
	print("PASS")
end

print()
print("=== 3. Slot:List/:Single opts는 테이블(hunt F 3) — 문자열도 조용히 안 지나간다 ===")
do
	local q = mock.newQuad()
	local s = q.Slot()
	failsWith(function() s:List(q.Source({}), function() return nil end, nil, 5) end, "Slot:List: opts must be a table (got number)", "number opts")
	local s2 = q.Slot()
	local err = failsWith(function() s2:Single(q.Source(nil), nil, "x") end, "Slot:Single: opts must be a table (got string)", "string opts")
	mock.assertBlamesUser(err, "spec.inputgates.luau", "opts gate blames the caller")
	-- a rejected install must not half-install (code-review): the same Slot installs fine afterwards
	s:List(q.Source({}), function() return nil end)
	s2:Single(q.Source(nil))
	print("PASS")
end

print()
print("=== 4. AddPlugin/UseProvider — 함수가 아니면 거부, 확장 테이블을 안 돌려주면 거부(hunt F 4) ===")
do
	local q = Quad.New()
	local err = failsWith(function() q:AddPlugin(nil) end, "AddPlugin: plugin must be a function (got nil)", "AddPlugin(nil)")
	mock.assertBlamesUser(err, "spec.inputgates.luau", "AddPlugin gate blames the caller")
	failsWith(function() q:UseProvider(nil) end, "UseProvider: provider must be a function (got nil)", "UseProvider(nil) used to be a silent no-op")
	failsWith(function() q:AddPlugin(function(m) m.X = 1 end) end, "AddPlugin: the function must return its extension table (got nil", "plugin forgot to return")
	q.debug = true -- code-review: the debug overwrite loop used to iterate the nil before the gate
	failsWith(function() q:AddPlugin(function(m) m.Y = 1 end) end, "AddPlugin: the function must return its extension table (got nil", "plugin forgot to return (debug on)")
	q.debug = false
	failsWith(function() q:UseProvider(function(m) return 5 end) end, "UseProvider: the function must return its extension table (got number", "provider returned a number")
	-- a real provider still installs after the rejects (the failed ones did not occupy the slot)
	q:UseProvider(mock.mockProvider)
	assert(q.Backend.isInst ~= nil, "provider installed")
	print("PASS")
end

print()
print("=== 5. 자기 검증에 실패한 CRUD는 Slot을 수동으로 표시하지 않는다(hunt F 5, H-386 형제) ===")
do
	local q = mock.newQuad()
	local s = q.Slot()
	failsWith(function() s:Add(nil) end, "nil/None cannot be an element", "Add(nil) rejected")
	failsWith(function() s:Remove(1) end, "out of range", "Remove out of range rejected")
	s:List(q.Source({}), function() return nil end) -- must still be allowed: nothing was mutated
	local s2 = q.Slot()
	s2:Add(mock.Instance.new("Frame"))
	failsWith(function() s2:List(q.Source({}), function() return nil end) end, "cannot install :List/:Single on a manual Slot", "a real CRUD still locks")
	print("PASS")
end

print()
print("=== 6. Tag — 자기를 담은 리스트는 도메인 메시지(hunt F 7) ===")
do
	local q = mock.newQuad()
	local t = {}
	t[1] = t
	local err = failsWith(function() return q.Tag(t) end, "this list nests deeper than 64 levels (does it contain itself?)", "self-containing list")
	mock.assertBlamesUser(err, "spec.inputgates.luau", "Tag cycle gate blames the caller")
	assert(q.Tag("a", { "b", { "c" } }):Contains("c"), "nested lists still flatten after the guard")
	for _ = 1, 200 do -- depth is per call, not accumulated module state (re-check found the counter drifting)
		assert(q.Tag({ { { "deep" } } }):Contains("deep"), "repeated nested Tags never trip the depth guard")
	end
	print("PASS")
end

print("=== ALL PASS ===")
