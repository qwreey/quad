--!nocheck
-- obs-eff-unify probe (2026-09-30): cells that the U model changes beyond xprobe-obseff.
local mock = require("./mock")
local Instance = mock.Instance
local q = mock.newQuad()
local Source, Effect, Blocker = q.Source, q.Effect, q.Blocker
local collectgarbage = (_G :: any).collectgarbage

local function T(name, f)
	local ok, err = pcall(f)
	if not ok then print(`--- {name}: ERR {tostring(err):gsub("\n.*", ""):sub(1, 160)}`) end
end
local function j(t) local o = {} for _, v in t do table.insert(o, tostring(v)) end return "[" .. table.concat(o, ",") .. "]" end
local function hist(counts) local ks = {} for k, c in counts do table.insert(ks, tostring(k) .. "x" .. c) end table.sort(ks) return table.concat(ks, " ") end

print("== U1 gate withholding at creation: Blocker On, s:Set(1) withheld, THEN create handle on gate; Off")
for _, kind in { "Observer", "Effect" } do T(kind, function()
	local s = Source(0)
	local b = Blocker()
	local g = s:Apply(b)
	b:On()
	s:Set(1)
	local log = {}
	local h = if kind == "Observer" then g:Observer(function(st) table.insert(log, st:Get()) end)
		else Effect(function() table.insert(log, g:Get()) end, g)
	h:Subscribe()
	b:Off()
	print(`  {kind}: runs {j(log)} (gate contract says the flush re-runs: expect [1,1])`)
	h:Unsubscribe()
end) end

print("== U2 throw liveness: subscribed Observer throws on value 1; then Set(2)")
T("Observer", function()
	local s = Source(0)
	local log = {}
	local o = s:Observer(function(st) local v = st:Get(); table.insert(log, v); if v == 1 then error("boom") end end):Subscribe()
	local ok = pcall(function() s:Set(1) end)
	pcall(function() s:Set(2) end)
	print(`  Observer: threw={not ok} runs {j(log)} running={tostring(o._running)} pending={tostring(o._pending)}`)
end)
print("== U3 from per run: Observer on s, fn Sets s once (from the first delivery)")
T("Observer", function()
	local s = Source(0)
	local froms = {}
	local o = s:Observer(function(st, _, from)
		table.insert(froms, (if from == nil then "nil" elseif from == s then "s" else "?") .. "@" .. tostring(st:Get()))
		if st:Get() == 1 then s:Set(2) end
	end):Subscribe()
	table.clear(froms)
	s:Set(1)
	print(`  Observer: {j(froms)}`)
	o:Unsubscribe()
end)

print("== U4 order in one wave: O1 Sets s=2 when s==1; O2 logs; event sequence (hist over 40 trials)")
T("order", function()
	local counts = {}
	for trial = 1, 40 do
		local s = Source(0)
		local ev = {}
		local pad = {}
		for i = 1, trial % 5 do pad[i] = s:Observer(function() end):Subscribe() end
		local o1 = s:Observer(function(st, _, from)
			if from == nil and #ev == 0 then return end
			table.insert(ev, "O1:" .. st:Get() .. "<")
			if st:Get() == 1 then s:Set(2) end
			table.insert(ev, "O1:" .. st:Get() .. ">")
		end):Subscribe()
		local o2 = s:Observer(function(st, _, from)
			if from == nil and #ev == 0 then return end
			table.insert(ev, "O2:" .. st:Get())
		end):Subscribe()
		s:Set(1)
		local k = table.concat(ev, " ")
		counts[k] = (counts[k] or 0) + 1
		o1:Unsubscribe(); o2:Unsubscribe(); for _, p in pad do p:Unsubscribe() end
	end
	for k, c in counts do print(`  {c}x  {k}`) end
end)

print("== U5 deep self-Set: Observer counts its own Source up to N (HEAD nests one wave per step)")
for _, N in { 100, 1000, 10000 } do T("N=" .. N, function()
	local s = Source(0)
	local runs = 0
	local o = s:Observer(function(st) runs += 1; local v = st:Get(); if v > 0 and v < N then s:Set(v + 1) end end):Subscribe()
	local ok, err = pcall(function() s:Set(1) end)
	print(`  N={N}: ok={ok} final={s:Get()} runs={runs} {if ok then "" else tostring(err):sub(1, 80)}`)
	pcall(function() o:Unsubscribe() end)
end) end

print("== U6 Effect cross-dep: X on A Sets B; Effect(fn, A, B); runs per A:Set (hist over 40)")
T("Effect", function()
	local counts = {}
	for trial = 1, 40 do
		local A, B = Source(0), Source(0)
		local pad = {}
		for i = 1, trial % 5 do pad[i] = A:Observer(function() end):Subscribe() end
		local x = A:Observer(function(st, _, from) if from ~= nil then B:Set(st:Get() * 10) end end):Subscribe()
		local runs = 0
		local e = Effect(function() A:Get(); B:Get(); runs += 1 end, A, B):Subscribe()
		runs = 0
		A:Set(1)
		counts[runs] = (counts[runs] or 0) + 1
		x:Unsubscribe(); e:Unsubscribe(); for _, p in pad do p:Unsubscribe() end
	end
	print(`  Effect runs per A:Set: {hist(counts)}`)
end)

print("== U7 fn unsubscribes itself, then Sets its own State; later Subscribe")
T("Observer", function()
	local s = Source(0)
	local log = {}
	local o
	o = s:Observer(function(st, self, from)
		table.insert(log, st:Get())
		if from ~= nil and st:Get() == 1 then self:Unsubscribe(); s:Set(5) end
	end):Subscribe()
	s:Set(1)
	print(`  after Set(1): {j(log)} subscribed={tostring(o.Subscribed)} held={tostring(o._rerunRequired)}`)
	o:Subscribe()
	print(`  after re-Subscribe: {j(log)}`)
	o:Unsubscribe()
end)

print("== U8 explicit Rerun mid-wave, then the same wave reaches the Effect (hist over 40)")
T("Effect", function()
	local counts = {}
	for trial = 1, 40 do
		local s = Source(0)
		local runs = 0
		local e = Effect(function() s:Get(); runs += 1 end, s):Subscribe()
		local pad = {}
		for i = 1, trial % 5 do pad[i] = s:Observer(function() end):Subscribe() end
		local x = s:Observer(function(_, _, from) if from ~= nil then e:Rerun() end end):Subscribe()
		runs = 0
		s:Set(1)
		counts[runs] = (counts[runs] or 0) + 1
		x:Unsubscribe(); e:Unsubscribe(); for _, p in pad do p:Unsubscribe() end
	end
	print(`  Effect runs per Set: {hist(counts)}`)
end)

print("== U9 install throws; GC; subs cleared")
T("Observer", function()
	local s = Source(0)
	local weak = setmetatable({}, { __mode = "k" })
	local ok = pcall(function() s:Observer(function(_, self) weak[self] = true; error("boom") end) end)
	collectgarbage("collect"); collectgarbage("collect")
	local n = 0 for _ in s._subs do n += 1 end
	print(`  Observer: threw={not ok} collected={next(weak) == nil} subs={n}`)
end)

print("== U10 Effect object count per State dep (internal Observer vs direct _subs)")
T("Effect", function()
	local s = Source(0)
	local c = s:Compute(function(x) return x:Get() end)
	local e = Effect(function() c:Get() end, s, c)
	local n = 0 for _ in s._subs do n += 1 end
	local m = 0 for _ in c._subs do m += 1 end
	local d = e._deps
	local kinds = {}
	for k, v in d do table.insert(kinds, typeof(v)) end
	table.sort(kinds)
	print(`  s._subs={n} c._subs={m} _deps values={j(kinds)}`)
end)

print("== U11 Observer on a Compute whose fn Sets the upstream (clamp through a derived State)")
T("Observer", function()
	local s = Source(5)
	local c = s:Compute(function(x) return x:Get() end)
	local last
	local o = c:Observer(function(st) local v = st:Get(); if v < 0 then s:Set(0) end; last = v end):Subscribe()
	s:Set(-3)
	print(`  c={c:Get()} last={last} {if last == c:Get() then "OK" else "STALE"}`)
	o:Unsubscribe()
end)
