--!nocheck
-- round13 E20 probe A (2026-09-27) — Observer/Effect lifetime state machine: states x entry points. Run from repo root: luau .claude/audit/round13-e20-probe-a.luau
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance
local q = mock.newQuad()
local B = q.Backend
local function E(f, ...)
	local ok, err = pcall(f, ...)
	if ok then return "ok" end
	local s = tostring(err)
	return (s:match("Quad%d+") or s:sub(1, 80))
end

-- make a handle in a given state. returns ctx {h, dep, host, runs, cl (list of dying), throwNext, kind}
local function make(kind, state, inWave)
	local c = { kind = kind, runs = 0, cl = {}, throwNext = false }
	c.dep = q.Source(0)
	if kind == "Observer" then
		c.h = c.dep:Observer(function()
			c.runs += 1
			if c.throwNext then c.throwNext = false; error("boom") end
		end)
	else
		c.h = q.Effect(function()
			c.runs += 1
			if c.throwNext then c.throwNext = false; error("boom") end
			return function(dying) table.insert(c.cl, dying) end
		end, c.dep)
	end
	local h = c.h
	if state == "fresh" then
	elseif state == "weak" then h:WeakSubscribe()
	elseif state == "strong" then h:Subscribe()
	elseif state == "bound" then c.host = Instance.new("Frame"); B.bindLifetime(c.host, h)
	elseif state == "thrown" then h:Subscribe(); c.throwNext = true; pcall(function() c.dep:Set(1) end)
	elseif state == "thrownBound" then c.host = Instance.new("Frame"); B.bindLifetime(c.host, h); c.throwNext = true; pcall(function() c.dep:Set(1) end)
	elseif state == "destroyed" then c.host = Instance.new("Frame"); B.bindLifetime(c.host, h); c.host:Destroy()
	elseif state == "unbound" then c.host = Instance.new("Frame"); B.bindLifetime(c.host, h); B.unbindLifetime(h)
	end
	c.runs0, c.cl0 = c.runs, #c.cl
	return c
end

local entries = {
	{ "Subscribe", function(c) return c.h:Subscribe() end },
	{ "WeakSubscribe", function(c) return c.h:WeakSubscribe() end },
	{ "Unsubscribe", function(c) return c.h:Unsubscribe() end },
	{ "WeakUnsubscribe", function(c) return c.h:WeakUnsubscribe() end },
	{ "Rerun", function(c) if c.kind == "Observer" then error("n/a") end return c.h:Rerun() end },
	{ "bind(new)", function(c) c.newHost = Instance.new("Frame"); return B.bindLifetime(c.newHost, c.h) end },
	{ "unbind", function(c) return B.unbindLifetime(c.h) end },
	{ "hostDestroy", function(c) if not c.host then error("n/a") end c.host:Destroy() end },
}

local function cell(c, res)
	local dRuns = c.runs - c.runs0
	local cls = {}
	for i = c.cl0 + 1, #c.cl do table.insert(cls, tostring(c.cl[i])) end
	-- after: does a dep Set run fn?
	local r1 = c.runs
	pcall(function() c.dep:Set(c.dep:Get() + 100) end)
	local fires = c.runs - r1
	return `{res} fn+{dRuns} cl[{table.concat(cls, ",")}] Sub={tostring(c.h.Subscribed)} exe={tostring(B.canExecute(c.h))} set→fn+{fires}`
end

for _, kind in { "Observer", "Effect" } do
	print(`==================== {kind} ====================`)
	for _, st in { "fresh", "weak", "strong", "bound", "thrown", "thrownBound", "destroyed", "unbound", "inWave" } do
		for _, e in entries do
			local c, res
			if st == "inWave" then
				-- inside the host's Destroying wave, AFTER the handle's own Destroying callback (mock fires newest-first,
				-- so connect ours BEFORE binding)
				c = { kind = kind, runs = 0, cl = {}, throwNext = false }
				c.dep = q.Source(0)
				if kind == "Observer" then
					c.h = c.dep:Observer(function() c.runs += 1 end)
				else
					c.h = q.Effect(function() c.runs += 1; return function(d) table.insert(c.cl, d) end end, c.dep)
				end
				c.host = Instance.new("Frame")
				local out
				c.host.Destroying:Connect(function()
					c.runs0, c.cl0 = c.runs, #c.cl
					if e[1] == "hostDestroy" then out = "n/a(self)" return end
					out = E(e[2], c)
					out = out .. ` [inWave exe={tostring(B.canExecute(c.h))} dying={tostring(c.h._dying)}]`
					-- in-wave dep set
					local r = c.runs
					pcall(function() c.dep:Set(c.dep:Get() + 1) end)
					out ..= ` inWaveSet→fn+{c.runs - r}`
				end)
				B.bindLifetime(c.host, c.h)
				c.host:Destroy()
				res = out
			else
				c = make(kind, st)
				res = E(e[2], c)
			end
			print(string.format("%-12s %-16s %s", st, e[1], cell(c, res)))
		end
	end
end
