--!nocheck
-- obs-eff-root probe (2026-09-30): Observer vs Effect "when does fn run" — state x event cells.
-- Run: ./scripts/relink.sh && luau quad-base/test/xprobe-obseff.luau
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
local function nsubs(s) local n = 0 for _ in s._subs do n += 1 end return n end

-- Each maker returns (handle, log) where log collects the value fn read on each run.
local function mkObs(s, body)
	local log = {}
	local h = s:Observer(function(st, self, from)
		local v = st:Get()
		table.insert(log, v)
		if body then body(v, self, from, log) end
	end)
	return h, log
end
local function mkEff(s, body)
	local log = {}
	local h = Effect(function(self)
		local v = s:Get()
		table.insert(log, v)
		if body then body(v, self, nil, log) end
	end, s)
	return h, log
end
local MAKERS = { { "Observer", mkObs }, { "Effect", mkEff } }

print("== C1 install: fn Sets its own dep once (A1)")
for _, m in MAKERS do T(m[1], function()
	local s = Source(0)
	local h, log = m[2](s, function(v) if v == 0 then s:Set(1) end end)
	print(`  {m[1]}: install runs {j(log)} now={s:Get()} rerunReq={tostring(h._rerunRequired)}`)
	h:Subscribe()
	print(`  {m[1]}: after Subscribe runs {j(log)}`)
end) end

print("== C2 install: fn's side effect makes ANOTHER subscribed Observer Set the dep (B)")
for _, m in MAKERS do T(m[1], function()
	local s, other = Source(0), Source(0)
	local o1 = other:Observer(function(_, _, from) if from ~= nil then s:Set(s:Get() + 1) end end):Subscribe()
	local h, log = m[2](s, function(v, _, _, lg) if #lg == 1 then other:Set(1) end end)
	print(`  {m[1]}: install runs {j(log)} now={s:Get()}`)
	h:Subscribe()
	print(`  {m[1]}: after Subscribe runs {j(log)}`)
	o1:Unsubscribe()
end) end

print("== C3 install: explicit self:Rerun() inside fn (Effect only; Q110)")
T("Effect", function()
	local s = Source(0)
	local n = 0
	local dyings = {}
	local h = Effect(function(self)
		n += 1
		if n == 1 then self:Rerun() end
		return function(dying) table.insert(dyings, tostring(dying)) end
	end, s)
	print(`  Effect: install runs {n} cleanups {j(dyings)}`)
	h:Subscribe(); print(`  Effect: after Subscribe runs {n}`)
	h:Unsubscribe(); print(`  Effect: after Unsubscribe cleanups {j(dyings)}`)
end)

print("== C4 held: two Sets while unexecutable, then Subscribe / bind")
for _, m in MAKERS do T(m[1], function()
	local s = Source(0)
	local h, log = m[2](s)
	s:Set(1); s:Set(2)
	print(`  {m[1]}: before Subscribe {j(log)}`)
	h:Subscribe(); print(`  {m[1]}: after Subscribe {j(log)}`)
	s:Set(3); print(`  {m[1]}: after Set(3) {j(log)}`)
	h:Unsubscribe()
	local s2 = Source(0)
	local h2, log2 = m[2](s2)
	s2:Set(5)
	local f = Instance.new("Frame"); q.Dispatch.drive(f, { h2 })
	print(`  {m[1]}: bind catch-up {j(log2)}`)
	f:Destroy(); s2:Set(6); print(`  {m[1]}: after host Destroy + Set(6) {j(log2)}`)
end) end

print("== C5 subscribed: fn clamps its own dep (reads v, Sets 0 if v<0, then records v) — last recorded vs current")
for _, m in MAKERS do T(m[1], function()
	local s = Source(5)
	local last
	local h = (if m[1] == "Observer" then s:Observer(function(st)
		local v = st:Get()
		if v < 0 then s:Set(0) end
		last = v
	end) else Effect(function()
		local v = s:Get()
		if v < 0 then s:Set(0) end
		last = v
	end, s)):Subscribe()
	s:Set(-3)
	print(`  {m[1]}: s={s:Get()} last recorded={last}  {if last == s:Get() then "OK" else "STALE"}`)
	h:Unsubscribe()
end) end

print("== C6 subscribed, nested wave: A (subscribed) Sets s=2 when s==1; how many runs does sibling B do on Set(1)?")
for _, m in MAKERS do T(m[1], function()
	local counts = {}
	for trial = 1, 50 do
		local s = Source(0)
		local pad = {}
		for i = 1, trial % 5 do pad[i] = s:Observer(function() end):Subscribe() end
		local a = s:Observer(function(st, _, from) if from ~= nil and st:Get() == 1 then s:Set(2) end end):Subscribe()
		local b, log = m[2](s)
		b:Subscribe()
		table.clear(log)
		s:Set(1)
		local key = j(log)
		counts[key] = (counts[key] or 0) + 1
		a:Unsubscribe(); b:Unsubscribe(); for _, p in pad do p:Unsubscribe() end
	end
	local ks = {} for k, c in counts do table.insert(ks, k .. "x" .. c) end table.sort(ks)
	print(`  {m[1]}: B runs per Set(1) over 50 trials: {table.concat(ks, " ")}`)
end) end

print("== C7 gate: handle on s:Apply(blocker), blocker On — install Sets s; then Off (flush must still arrive)")
for _, m in MAKERS do T(m[1], function()
	local s = Source(0)
	local b = Blocker()
	local g = s:Apply(b)
	b:On()
	local h, log = m[2](g, function(v) if v == 0 then s:Set(1) end end)
	print(`  {m[1]}: install {j(log)}`)
	h:Subscribe(); print(`  {m[1]}: after Subscribe {j(log)}`)
	b:Off(); print(`  {m[1]}: after Off {j(log)}`)
	h:Unsubscribe()
end) end

print("== C8 gate + held: unsubscribed handle on gated node, blocker On, s:Set(1); Subscribe; Off")
for _, m in MAKERS do T(m[1], function()
	local s = Source(0)
	local b = Blocker()
	local g = s:Apply(b)
	local h, log = m[2](g)
	s:Set(1) -- open: delivered, held
	b:On()
	s:Set(2) -- withheld
	h:Subscribe(); print(`  {m[1]}: after Subscribe {j(log)}`)
	b:Off(); print(`  {m[1]}: after Off {j(log)} (gate contract: flush re-runs)`)
	h:Unsubscribe()
end) end

print("== C9 oscillation: fn toggles its own dep, stops itself after 40 runs")
for _, m in MAKERS do T(m[1], function()
	local s = Source(0)
	local n = 0
	local h = (if m[1] == "Observer" then s:Observer(function(st)
		n += 1
		if n < 40 then s:Set(1 - st:Get()) end
	end) else Effect(function()
		n += 1
		if n < 40 then s:Set(1 - s:Get()) end
	end, s))
	print(`  {m[1]}: install runs {n}`)
	n = 0; h:Subscribe(); s:Set(5); print(`  {m[1]}: subscribed Set runs {n}`)
	h:Unsubscribe()
end) end

print("== C10 install fire throws (after Setting its own dep)")
for _, m in MAKERS do T(m[1], function()
	local s = Source(0)
	local weak = setmetatable({}, { __mode = "k" })
	local n = 0
	local ok, err = pcall(function()
		if m[1] == "Observer" then
			s:Observer(function(_, self) weak[self] = true; n += 1; s:Set(n); error("boom") end)
		else
			Effect(function(self) weak[self] = true; n += 1; s:Set(n); error("boom") end, s)
		end
	end)
	local h = next(weak)
	print(`  {m[1]}: threw={not ok} runs={n} subsOfS={nsubs(s)} running={tostring(h._running)} rerunReq={tostring(h._rerunRequired)}`)
	s:Set(99); print(`  {m[1]}: after Set(99) runs={n}`)
	h = nil
	collectgarbage("collect"); collectgarbage("collect")
	print(`  {m[1]}: collected={next(weak) == nil} subsOfS={nsubs(s)}`)
end) end

print("== C11 revive mid-wave (Q109): held older change, sibling Subscribes it during the wave that will also reach it")
for _, m in MAKERS do T(m[1], function()
	local counts = {}
	for t = 1, 100 do
		local src = Source(0)
		local pad = {}
		for i = 1, t % 7 do pad[i] = src:Observer(function() end):Subscribe() end
		local sib, log = m[2](src)
		src:Set(1) -- held
		local a = src:Observer(function(_, _, from)
			if from ~= nil and src:Get() == 2 and not sib.Subscribed then sib:Subscribe() end
		end):Subscribe()
		table.clear(log)
		src:Set(2)
		counts[#log] = (counts[#log] or 0) + 1
		a:Unsubscribe(); for _, p in pad do p:Unsubscribe() end
		if sib.Subscribed then sib:Unsubscribe() end
	end
	local ks = {} for k, c in counts do table.insert(ks, k .. "x" .. c) end table.sort(ks)
	print(`  {m[1]}: runs in wave: {table.concat(ks, " ")}`)
end) end

print("== C12 Observer on a Compute: install fn Sets the upstream Source (derived-state Q73)")
for _, m in MAKERS do T(m[1], function()
	local s = Source(0)
	local c = s:Compute(function(x) return x:Get() * 10 end)
	local h, log = m[2](c, function(v) if v == 0 then s:Set(1) end end)
	print(`  {m[1]}: install {j(log)} now={c:Get()}`)
end) end

print("== C6c same as C6 but B observes a Compute over s")
for _, m in MAKERS do T(m[1], function()
	local counts = {}
	for trial = 1, 50 do
		local s = Source(0)
		local c = s:Compute(function(x) return x:Get() end)
		local pad = {}
		for i = 1, trial % 5 do pad[i] = s:Observer(function() end):Subscribe() end
		local a = s:Observer(function(st, _, from) if from ~= nil and st:Get() == 1 then s:Set(2) end end):Subscribe()
		local b, log = m[2](c)
		b:Subscribe()
		table.clear(log)
		s:Set(1)
		local key = j(log)
		counts[key] = (counts[key] or 0) + 1
		a:Unsubscribe(); b:Unsubscribe(); for _, p in pad do p:Unsubscribe() end
	end
	local ks = {} for k, c in counts do table.insert(ks, k .. "x" .. c) end table.sort(ks)
	print(`  {m[1]}: B runs per Set(1) over 50 trials: {table.concat(ks, " ")}`)
end) end

print("== C11c revive mid-wave, handle on a Compute over src")
for _, m in MAKERS do T(m[1], function()
	local counts = {}
	for t = 1, 100 do
		local src = Source(0)
		local c = src:Compute(function(x) return x:Get() end)
		local pad = {}
		for i = 1, t % 7 do pad[i] = src:Observer(function() end):Subscribe() end
		local sib, log = m[2](c)
		src:Set(1)
		local a = src:Observer(function(_, _, from)
			if from ~= nil and src:Get() == 2 and not sib.Subscribed then sib:Subscribe() end
		end):Subscribe()
		table.clear(log)
		src:Set(2)
		counts[#log] = (counts[#log] or 0) + 1
		a:Unsubscribe(); for _, p in pad do p:Unsubscribe() end
		if sib.Subscribed then sib:Unsubscribe() end
	end
	local ks = {} for k, c in counts do table.insert(ks, k .. "x" .. c) end table.sort(ks)
	print(`  {m[1]}: runs in wave: {table.concat(ks, " ")}`)
end) end

print("== C13 H-68 same-value Set on a Source still re-runs (each Set is a new revision)")
for _, m in MAKERS do T(m[1], function()
	local s = Source(1)
	local h, log = m[2](s)
	h:Subscribe()
	s:Set(1); s:Set(1)
	print(`  {m[1]}: runs {j(log)}`)
	h:Unsubscribe()
end) end
