--!nocheck
-- round14 debug coverage probe (scratch, deleted after run): Debounce Time cache (Q55) and H-570.
local mock = require("./mock")
local advance = mock.advanceTime

local function short(e)
	local s = tostring(e)
	s = string.gsub(s, "\n.*", "")
	return string.sub(s, 1, 220)
end

local function run(name, body)
	for _, dbg in { false, true } do
		mock.resetTimers()
		local q = mock.newQuad()
		q.debug = dbg
		print(`--- [{name}] debug={dbg}`)
		local ok, err = pcall(body, q)
		if not ok then
			print("  RAISED: " .. short(err))
		end
	end
end

local function probeOf(g)
	local p = { count = 0 }
	function p._receive(self, _from)
		self.count += 1
	end
	g._subs[p] = true
	return p
end

-- D1: Time State goes bad (-1) DURING a window with no signal in between; the window ends with a
-- withheld value, so the commit reopens a window. Q55 cache: reopen uses the cached Time. Without it:
-- the reopen reads Time inside the timer callback.
run("D1 Throttle Time State goes bad mid-window", function(q)
	local delay = q.Source(1)
	local s = q.Source(0)
	local g = s:Apply(q.Throttle({ Time = delay }))
	local p = probeOf(g)
	s:Set(1) -- leading pass, window 1s
	s:Set(2) -- withheld
	delay:Set(-1) -- bad value, no signal
	local ok, err = pcall(function() advance(1) end) -- window end: 2 passes, reopen
	print(`  window end ok={ok} {if ok then "" else short(err)} passed={p.count} g={g:Get()} timers={mock.pendingTimers()}`)
	local ok2, err2 = pcall(function() s:Set(3) end)
	print(`  next signal ok={ok2} {if ok2 then "" else short(err2)} passed={p.count} g={g:Get()} timers={mock.pendingTimers()}`)
	delay:Set(1)
	local ok3, err3 = pcall(function() s:Set(4) end)
	print(`  after fixing Time, signal ok={ok3} {if ok3 then "" else short(err3)} passed={p.count} g={g:Get()} timers={mock.pendingTimers()}`)
	pcall(function() advance(5) end)
	print(`  +5s passed={p.count} g={g:Get()} timers={mock.pendingTimers()}`)
end)

-- D1b: the Q55 "one signal late" cost (followup §3 scene)
run("D1b Throttle Time change reaches reopened window", function(q)
	local delay = q.Source(1)
	local s = q.Source(0)
	local g = s:Apply(q.Throttle({ Time = delay }))
	local p = probeOf(g)
	s:Set(1)
	s:Set(2)
	delay:Set(5)
	advance(1) -- 2 passes, reopen (cached 1 vs fresh 5)
	s:Set(3)
	advance(1.01)
	print(`  at t=2.01 passed={p.count} g={g:Get()} (cache: 3 passed at t=2; no cache: still held until t=6)`)
end)

-- D2: H-570 — downstream handle:Cancel() re-entrant inside the window-end flush
run("D2 re-entrant Cancel inside timer flush", function(q)
	local s = q.Source(0)
	local h = q.Ref(nil)
	local g = s:Apply(q.Throttle({ Time = 1, Handle = h }))
	local cancelOnce = true
	local p = { count = 0 }
	function p._receive(self, _from)
		self.count += 1
		if cancelOnce and g:Get() == 2 then
			cancelOnce = false
			h.Value:Cancel()
		end
	end
	g._subs[p] = true
	s:Set(1)
	s:Set(2)
	advance(1)
	print(`  after window end: passed={p.count} timers={mock.pendingTimers()} (0 = not reopened)`)
	s:Set(3)
	print(`  next signal: passed={p.count} g={g:Get()} (3 passes at once if idle)`)
	advance(1)
	print(`  +1s: passed={p.count} g={g:Get()}`)
end)

run("D3 re-entrant Cancel inside handle Flush", function(q)
	local s = q.Source(0)
	local h = q.Ref(nil)
	local g = s:Apply(q.Throttle({ Time = 1, Handle = h }))
	local cancelOnce = true
	local p = { count = 0 }
	function p._receive(self, _from)
		self.count += 1
		if cancelOnce and g:Get() == 2 then
			cancelOnce = false
			h.Value:Cancel()
		end
	end
	g._subs[p] = true
	s:Set(1)
	s:Set(2)
	h.Value:Flush()
	print(`  after Flush: passed={p.count} timers={mock.pendingTimers()}`)
	s:Set(3)
	print(`  next signal: passed={p.count} g={g:Get()}`)
end)
