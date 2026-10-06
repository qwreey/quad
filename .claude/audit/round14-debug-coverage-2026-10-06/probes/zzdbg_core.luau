--!nocheck
-- round14 debug coverage probe (scratch, deleted after run): reactive core items.
local mock = require("./mock")

local function short(e)
	local s = tostring(e)
	s = string.gsub(s, "\n.*", "")
	return string.sub(s, 1, 260)
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

-- A1. H-198 (Get restart loop, removed 2026-10-01): Compute fn Sets its own dependency.
run("A1 compute sets own dep", function(q)
	local up = q.Source(1)
	local runs = 0
	local c = up:Compute(function(x)
		runs += 1
		local v = x:Get()
		if v < 3 then
			up:Set(v + 1)
		end
		return v
	end)
	local g1 = c:Get()
	local g2 = c:Get()
	local g3 = c:Get()
	print(`  Get x3 = {g1},{g2},{g3}  up={up:Get()} runs={runs}`)
end)

-- A2. Q93/Q98 yield guards (removed 2026-10-01): Compute fn yields; another coroutine reads.
run("A2 Q93 overlapping yield (A parks gen1, B parks gen2, A returns)", function(q)
	local src = q.Source(0)
	local runs = 0
	local parkNext = true
	local c = src:Compute(function(x)
		runs += 1
		local v = x:Get()
		if parkNext and coroutine.isyieldable() then
			coroutine.yield()
		end
		return v
	end)
	local A = coroutine.create(function() return c:Get() end)
	coroutine.resume(A) -- gen1 parked
	src:Set(1)
	local B = coroutine.create(function() return c:Get() end)
	coroutine.resume(B) -- gen2 parked
	parkNext = false
	local okA, rA = coroutine.resume(A) -- A returns (old: guard kept B's stamp)
	print(`  A returned ok={okA} {short(rA)}`)
	local okM, rM = pcall(function() return c:Get() end)
	print(`  main Get ok={okM} {short(rM)} runs={runs}`)
	local okB, rB = coroutine.resume(B)
	print(`  B returned ok={okB} {short(rB)}`)
	local okF, rF = pcall(function() return c:Get() end)
	print(`  final Get ok={okF} {short(rF)} runs={runs}`)
end)

run("A2b Q98 late return over newer valid cache", function(q)
	local src = q.Source(0)
	local runs = 0
	local parkNext = true
	local c = src:Compute(function(x)
		runs += 1
		local v = x:Get()
		if parkNext and coroutine.isyieldable() then
			coroutine.yield()
		end
		return v * 100
	end)
	local A = coroutine.create(function() return c:Get() end)
	coroutine.resume(A) -- gen1 parked (reads 0)
	src:Set(1)
	parkNext = false
	local okM, rM = pcall(function() return c:Get() end) -- gen2 on main: 100
	print(`  main Get ok={okM} {short(rM)}`)
	local okA, rA = coroutine.resume(A)
	print(`  A returned ok={okA} {short(rA)}`)
	local okF, rF = pcall(function() return c:Get() end)
	print(`  final Get ok={okF} {short(rF)} (expect 100) runs={runs}`)
end)

-- A3. Observer install re-run loop + Quad0262 (removed 2026-10-01): install fn feeds own upstream.
run("A3 install fn feeds own target once (clamp)", function(q)
	local host = mock.Instance.new("Frame")
	local s = q.Source(20)
	local seen = {}
	local o = s:Observer(function(x)
		table.insert(seen, x:Get())
		if x:Get() > 10 then
			s:Set(10)
		end
	end)
	print(`  after install: s={s:Get()} seen={table.concat(seen, ",")}`)
	q.Backend.bindLifetime(host, o)
	print(`  after bind: s={s:Get()} seen={table.concat(seen, ",")}`)
end)

run("A3b install fn keeps feeding (counter to 3)", function(q)
	local host = mock.Instance.new("Frame")
	local s = q.Source(0)
	local seen = {}
	local o = s:Observer(function(x)
		table.insert(seen, x:Get())
		if x:Get() < 3 then
			s:Set(x:Get() + 1)
		end
	end)
	print(`  after install: s={s:Get()} seen={table.concat(seen, ",")}`)
	q.Backend.bindLifetime(host, o)
	print(`  after bind: s={s:Get()} seen={table.concat(seen, ",")}`)
end)

run("A3c install fn feeds, never bound/subscribed", function(q)
	local s = q.Source(20)
	local seen = {}
	local _o = s:Observer(function(x)
		table.insert(seen, x:Get())
		if x:Get() > 10 then
			s:Set(10)
		end
	end)
	print(`  never bound: s={s:Get()} seen={table.concat(seen, ",")}`)
end)

-- Quad0261 retired: Operator fixed-arity factory extra args silently ignored
run("Q0261 Clamp extra arg", function(q)
	local v = q.Source(50)
	local c = v:Apply(q.Operator.Clamp(0, 10, 5))
	print(`  clamp={c:Get()}`)
end)
