--!nocheck
-- round14 debug coverage probe (scratch, deleted after run): Slot / Tag / StoreBind / Bookkeeping items.
-- Runs unchanged against HEAD and against a patched scratch copy ("after" = guard removed).
local mock = require("./mock")
local Instance = mock.Instance

local function short(e)
	local s = tostring(e)
	s = string.gsub(s, "\n.*", "")
	return string.sub(s, 1, 240)
end

local function run(name, body)
	for _, dbg in { false, true } do
		local q = mock.newQuad()
		q.debug = dbg
		print(`--- [{name}] debug={dbg}`)
		local ok, err = pcall(body, q)
		if not ok then
			print("  RAISED: " .. short(err))
		end
	end
end

local function F(name)
	local f = Instance.new("Frame")
	f.Name = name
	return f
end
local function names(inst)
	local t = {}
	for _, c in inst:GetChildren() do
		table.insert(t, c.Name)
	end
	return table.concat(t, ",")
end

-- Q176 Tag depth guard Quad0201
run("T1 Tag self-containing list", function(q)
	local t = { "a" }
	t[2] = t
	local tag = q.Tag(t)
	print("  constructed: " .. tostring(tag))
end)
run("T2 Tag honest 100-level nesting", function(q)
	local t = { "deep" }
	for _ = 1, 100 do
		t = { t }
	end
	local tag = q.Tag(t)
	print("  constructed: " .. tostring(tag))
end)

-- Q173 StoreBind chain Quad0070
run("C1 StoreBind two-State cycle via Set", function(q)
	local host = Instance.new("Frame")
	local b = q.Source(q.Slot({ F("b0") }))
	local a = q.Source(b)
	q.Dispatch.drive(host, { a })
	print("  mounted, children=" .. names(host))
	local ok, err = pcall(function() b:Set(a) end)
	print(`  b:Set(a) ok={ok} {if ok then "" else short(err)}`)
	local ok2, err2 = pcall(function() b:Set(q.Slot({ F("x") })) end)
	print(`  recover b:Set(F) ok={ok2} {if ok2 then "" else short(err2)} children={names(host)}`)
end)
run("C2 StoreBind self Set (numeric position)", function(q)
	local host = Instance.new("Frame")
	local s = q.Source(q.Slot({ F("s0") }))
	q.Dispatch.drive(host, { s })
	local ok, err = pcall(function() s:Set(s) end)
	print(`  s:Set(s) ok={ok} {if ok then "" else short(err)}`)
end)
run("C3 Slot element State cycle (mounted)", function(q)
	local host = Instance.new("Frame")
	local st = q.Source(F("a"))
	local sl = q.Slot({ st })
	q.Dispatch.drive(host, { sl })
	local ok, err = pcall(function() st:Set(st) end)
	print(`  st:Set(st) ok={ok} {if ok then "" else short(err)} children={names(host)}`)
	local ok2, err2 = pcall(function() st:Set(F("b")) end)
	print(`  recover ok={ok2} {if ok2 then "" else short(err2)} children={names(host)}`)
end)
run("C4 Slot:Add of an already circular State", function(q)
	local sl = q.Slot()
	local cyc = q.Source(nil)
	cyc:Set(cyc)
	local ok, err = pcall(function() sl:Add(cyc) end)
	print(`  Add ok={ok} {if ok then "" else short(err)} len={sl.Length:Get()}`)
	if ok then
		local host = Instance.new("Frame")
		local ok2, err2 = pcall(function() q.Dispatch.drive(host, { sl }) end)
		print(`  mount ok={ok2} {if ok2 then "" else short(err2)}`)
	end
end)

-- Q170 Slot CRUD pre-scan (existing elements seeded as "held")
run("P1 re-Add same raw Instance (unmounted)", function(q)
	local s = q.Slot()
	local x = F("x")
	s:Add(x)
	local ok, err = pcall(function() s:Add(x) end)
	print(`  2nd Add ok={ok} {if ok then "" else short(err)} len={s.Length:Get()}`)
end)
run("P2 re-Add same raw Instance (mounted)", function(q)
	local s = q.Slot()
	local x = F("x")
	s:Add(x)
	local host = Instance.new("Frame")
	q.Dispatch.drive(host, { s })
	local ok, err = pcall(function() s:Add(x) end)
	print(`  2nd Add ok={ok} {if ok then "" else short(err)} len={s.Length:Get()} children={names(host)}`)
end)
run("P3 two States holding one Instance (unmounted, then mount)", function(q)
	local s = q.Slot()
	local x = F("x")
	local sa, sb = q.Source(x), q.Source(x)
	s:Add(sa)
	local ok, err = pcall(function() s:Add(sb) end)
	print(`  Add(sb) ok={ok} {if ok then "" else short(err)} len={s.Length:Get()}`)
	local host = Instance.new("Frame")
	local ok2, err2 = pcall(function() q.Dispatch.drive(host, { s }) end)
	print(`  mount ok={ok2} {if ok2 then "" else short(err2)} children={names(host)} len={s.Length:Get()}`)
end)
run("P4 two States holding one Instance (mounted Slot)", function(q)
	local s = q.Slot()
	local x = F("x")
	local sa, sb = q.Source(x), q.Source(x)
	local host = Instance.new("Frame")
	q.Dispatch.drive(host, { s })
	s:Add(sa)
	local ok, err = pcall(function() s:Add(sb) end)
	print(`  Add(sb) ok={ok} {if ok then "" else short(err)} children={names(host)} len={s.Length:Get()}`)
end)
run("P5 raw Instance + State holding it (unmounted)", function(q)
	local s = q.Slot()
	local x = F("x")
	s:Add(x)
	local ok, err = pcall(function() s:Add(q.Source(x)) end)
	print(`  Add(State(x)) ok={ok} {if ok then "" else short(err)} len={s.Length:Get()}`)
	if ok then
		local host = Instance.new("Frame")
		local ok2, err2 = pcall(function() q.Dispatch.drive(host, { s }) end)
		print(`  mount ok={ok2} {if ok2 then "" else short(err2)} children={names(host)}`)
	end
end)

-- Q171 H-240 Get-window checks (E73 PBK): length Compute behind a closed gate Sets ANOTHER length Source
run("B1 H-240 PBK", function(q)
	local BK = q.Bookkeeping
	local inst = Instance.new("Frame")
	local hold = function(_emit) return function() end end
	local S1, d2, d = q.Source(1), q.Source(10), q.Source(100)
	local armed2, armed = false, false
	local L2 = d2:Gate(hold):Compute(function(x)
		if armed2 then armed2 = false; S1:Set(S1:Get() + 5) end
		return x:Get()
	end)
	local L = d:Gate(hold):Compute(function(x)
		if armed then armed = false; d2:Set(d2:Get() + 1); armed2 = true end
		return x:Get()
	end)
	local OF2, OF4 = q.Source(-1), q.Source(-1)
	BK.setOffsetSource(inst, 1, q.None); BK.setLength(inst, 1, S1)
	BK.setOffsetSource(inst, 2, OF2); BK.setLength(inst, 2, L2)
	BK.setOffsetSource(inst, 3, q.None); BK.setLength(inst, 3, L)
	BK.setOffsetSource(inst, 4, OF4); BK.setLength(inst, 4, 0)
	print(`  setup OF2={OF2:Get()} OF4={OF4:Get()} (1/111)`)
	armed = true
	d:Set(200)
	S1:Set(2)
	print(`  after: S1={S1:Get()} OF2={OF2:Get()} (want 7) OF4={OF4:Get()} (want 218) getOffsetAt(4)={BK.getOffsetAt(inst, 4)} getOffsetAt(2)={BK.getOffsetAt(inst, 2)}`)
	S1:Set(S1:Get())
	print(`  next event (S1:Set same): OF2={OF2:Get()} OF4={OF4:Get()}`)
end)

-- Quad0173 Slot cycle (debug layer since 2026-10-01): what does debug-off do afterwards?
run("Y1 s:Add(s) then CRUD / mount", function(q)
	local s = q.Slot()
	s:Add(F("a"))
	local ok, err = pcall(function() s:Add(s) end)
	print(`  Add(s) ok={ok} {if ok then "" else short(err)}`)
	if ok then
		local ok2, err2 = pcall(function() s:Add(F("b")) end)
		print(`  next Add ok={ok2} {if ok2 then "" else short(err2)}`)
		local host = Instance.new("Frame")
		local ok3, err3 = pcall(function() q.Dispatch.drive(host, { s }) end)
		print(`  mount ok={ok3} {if ok3 then "" else short(err3)}`)
		local ok4, err4 = pcall(function() q.dispose(s) end)
		print(`  dispose ok={ok4} {if ok4 then "" else short(err4)}`)
	end
end)
run("Y2 a:Add(b); b:Add(a) then mount", function(q)
	local a, b = q.Slot(), q.Slot()
	a:Add(b)
	local ok, err = pcall(function() b:Add(a) end)
	print(`  b:Add(a) ok={ok} {if ok then "" else short(err)}`)
	if ok then
		local ok1, err1 = pcall(function() return a:Remove(1) end)
		print(`  a:Remove(1) ok={ok1} {if ok1 then "" else short(err1)}`)
		local host = Instance.new("Frame")
		local ok3, err3 = pcall(function() q.Dispatch.drive(host, { a }) end)
		print(`  mount ok={ok3} {if ok3 then "" else short(err3)}`)
	end
end)

-- Quad0141 retired (SlotDynamicPathGuard/RefDynamicPathGuard): Slot/Ref at a string key, and raw process at 1.5
run("K1 Slot at a non-property string key", function(q)
	local host = Instance.new("Frame")
	local ok, err = pcall(function() q.Dispatch.drive(host, { Foo = q.Slot() }) end)
	print(`  drive ok={ok} {if ok then "" else short(err)}`)
end)
run("K2 State<Slot> at a string key", function(q)
	local host = Instance.new("Frame")
	local ok, err = pcall(function() q.Dispatch.drive(host, { Foo = q.Source(q.Slot()) }) end)
	print(`  drive ok={ok} {if ok then "" else short(err)}`)
end)
run("K3 Ref at a non-property string key", function(q)
	local host = Instance.new("Frame")
	local ok, err = pcall(function() q.Dispatch.drive(host, { Foo = q.Ref() }) end)
	print(`  drive ok={ok} {if ok then "" else short(err)}`)
end)
run("K4 raw process at fractional key 1.5 with a Slot", function(q)
	local host = Instance.new("Frame")
	local s = q.Slot()
	s:Add(F("a"))
	local ok, err = pcall(function() q.Dispatch.process(host, 1.5, s, 1) end)
	print(`  process ok={ok} {if ok then "" else short(err)} children={names(host)}`)
end)
