--!nocheck
-- E75 group F: 07-roblox.md + 08-roblox-tween.md (main session)
local H = require("../harness")
local R = require("../runner")
local q, D = H.q, H.D
local M = D.Mapper
local mock = H.mock
-- mock TweenService does not interpolate: a tween "reaches" its target iff a Create call recorded it
local function tweenedTo(inst, prop, v)
	for i = #mock.tweenLog, 1, -1 do
		local e = mock.tweenLog[i]
		if e.inst == inst and e.props[prop] ~= nil then return e.props[prop] == v, tostring(e.props[prop]) end
	end
	return inst[prop] == v, "direct=" .. tostring(inst[prop])
end

-- ===== 07-roblox =====
-- 0215/0216/0217: backend time ops, public via q.Backend
R.case({ id = "Quad0215",
	trigger = function() q.Backend.setTimeout(nil, 1) end,
	fix = function()
		local fired = false
		q.Backend.setTimeout(function() fired = true end, 1)
		H.runTask(1.1)
		return fired, "fired=" .. tostring(fired)
	end })
R.case({ id = "Quad0216",
	trigger = function() q.Backend.setTimeout(function() end, -1) end,
	fix = function()
		local fired = false
		q.Backend.setTimeout(function() fired = true end, 0)
		H.runTask(0)
		return fired, "delay 0 fired=" .. tostring(fired)
	end })
R.case({ id = "Quad0216", note = "NaN variant",
	trigger = function() q.Backend.setTimeout(function() end, 0/0) end })
R.case({ id = "Quad0216", note = "reach via Debounce Time State negative?",
	trigger = function()
		local t = q.Source(0.1)
		local src = q.Source(0)
		local d = src:Apply(q.Debounce({ Time = t }))
		local e = q.Effect(function(h) d:Get() end); e:Subscribe()
		t:Set(-1)
		src:Set(1)
	end })
R.case({ id = "Quad0217",
	trigger = function() q.Backend.clearTimeout({}) end,
	fix = function()
		local fired = false
		local h = q.Backend.setTimeout(function() fired = true end, 1)
		q.Backend.clearTimeout(h)
		H.runTask(2)
		return not fired, "cancelled, fired=" .. tostring(fired)
	end })

-- 0218 Event handler not a function
R.case({ id = "Quad0218",
	trigger = function() D.TextButton({ Activated = "click" }) end,
	fix = function()
		local n = 0
		local b = D.TextButton({ Activated = function() n += 1 end })
		b.Activated:Fire()
		local b2 = D.TextButton({ Activated = q.None })
		local b3 = D.TextButton({ Activated = nil })
		return n == 1, "fn fired n=" .. n .. "; None/nil accepted"
	end })
R.case({ id = "Quad0218", note = "State holding non-function",
	trigger = function() D.TextButton({ Activated = q.Source(5) }) end })

-- 0219 unclaimed child
R.case({ id = "Quad0219",
	trigger = function()
		local child = mock.Instance.foreign("Frame")
		D.Frame({ child })
	end,
	fix = function()
		-- prescription: build with D, or take over with Claim first
		local child = mock.Instance.foreign("Frame")
		q.Claim(child, M.Frame(M.Root)({}))
		local p = D.Frame({ child })
		local c2 = D.Frame({})
		local p2 = D.Frame({ c2 })
		return child.Parent == p and c2.Parent == p2, "claimed child parented=" .. tostring(child.Parent == p)
	end })
R.case({ id = "Quad0219", note = "mock Instance.new (Declaration stand-in) under real quad-roblox backend",
	trigger = function() D.Frame({ mock.Instance.new("Frame") }) end })
R.case({ id = "Quad0219", note = "destroyed D child",
	trigger = function()
		local c = D.Frame({}); c:Destroy()
		D.Frame({ c })
	end })

-- 0220 cycle
R.case({ id = "Quad0220",
	trigger = function()
		local src = q.Source(nil)
		local host = D.Frame({ src })
		src:Set(host)
	end,
	fix = function()
		local src = q.Source(nil)
		local host = D.Frame({ src })
		local other = D.Frame({})
		src:Set(other)
		return other.Parent == host, "restructured: other under host"
	end })
R.case({ id = "Quad0220", note = "descendant variant: place the ancestor into a child's seat",
	trigger = function()
		local src = q.Source(nil)
		local child = D.Frame({ src })
		local host = D.Frame({ child })
		src:Set(host)
	end })

-- 0221/0222 OnChange
R.case({ id = "Quad0221",
	trigger = function() D.TextBox({ q.OnChange("", function() end) }) end,
	fix = function()
		local got
		local tb = D.TextBox({ q.OnChange("Text", function(v) got = v end) })
		tb.Text = "hi"
		return got == "hi", "got=" .. tostring(got)
	end })
R.case({ id = "Quad0221", note = "non-string name at call",
	trigger = function() q.OnChange(5, function() end) end })
R.case({ id = "Quad0222",
	trigger = function() q.OnChange("Text", "x") end,
	fix = function()
		local got
		local tb = D.TextBox({ q.OnChange("Text", function(v) got = v end) })
		tb.Text = "yo"
		return got == "yo", "got=" .. tostring(got)
	end })
-- 0223/0224 Out
R.case({ id = "Quad0223",
	trigger = function() q.Out("", q.Source("")) end,
	fix = function()
		local s = q.Source("")
		local tb = D.TextBox({ q.Out("Text", s) })
		tb.Text = "abc"
		return s:Get() == "abc", "src=" .. tostring(s:Get())
	end })
R.case({ id = "Quad0224",
	trigger = function() local s = q.Source(""); q.Out("Text", s:Compute(function(h) return h:Get() end)) end,
	fix = function()
		local s = q.Source("")
		local tb = D.TextBox({ q.Out("Text", s) })
		tb.Text = "zz"
		return s:Get() == "zz", "src=" .. tostring(s:Get())
	end })

-- 0225 nativeClaim twice (backend direct)
R.case({ id = "Quad0225",
	trigger = function()
		local f = mock.Instance.foreign("Frame")
		q.Backend.nativeClaim(f); q.Backend.nativeClaim(f)
	end,
	fix = function()
		local f = mock.Instance.foreign("Frame")
		q.Backend.nativeClaim(f)
		return q.Backend.isClaimed(f), "claimed once"
	end })
R.case({ id = "Quad0225", note = "public q.Claim twice -> expect Quad0029 not 0225",
	trigger = function()
		local f = mock.Instance.foreign("Frame")
		q.Claim(f, M.Frame(M.Root)({})); q.Claim(f, M.Frame(M.Root)({}))
	end })

-- 0226 bindLifetime unclaimed
R.case({ id = "Quad0226",
	trigger = function()
		local f = mock.Instance.foreign("Frame")
		q.Dispatch.process(f, 1, q.Effect(function() end), 1)
	end,
	fix = function()
		local f = mock.Instance.foreign("Frame")
		q.Claim(f, M.Frame(M.Root)({}))
		local ran = 0
		local e = q.Effect(function() ran += 1 end)
		q.Dispatch.process(f, 1, e, 1)
		return ran >= 1, "claimed; effect ran=" .. ran
	end })
R.case({ id = "Quad0226", note = "direct bindLifetime",
	trigger = function() q.Backend.bindLifetime(mock.Instance.foreign("Frame"), {}) end,
	fix = function()
		local f = mock.Instance.foreign("Frame")
		q.Claim(f, M.Frame(M.Root)({}))
		q.Backend.bindLifetime(f, {})
		return true, "bound after Claim"
	end })
R.case({ id = "Quad0226", note = "destroyed then bindLifetime",
	trigger = function() local f = D.Frame({}); f:Destroy(); q.Backend.bindLifetime(f, {}) end })

-- ===== 08-roblox-tween =====
R.case({ id = "Quad0214",
	trigger = function() q.Source(0):Apply(q.Animate(0.3)) end,
	fix = function()
		local s = q.Source(0)
		local st = s:Apply(q.Animate({ Time = 0.3 }))
		local f = D.Frame({ BackgroundTransparency = st })
		s:Set(1)
		return tweenedTo(f, "BackgroundTransparency", 1)
	end })
R.case({ id = "Quad0227",
	trigger = function() q.Tween({ Value = 1 }):Mapped(5) end,
	fix = function()
		local t = q.Tween({ Value = 1, Time = 0.2 }):Mapped(function(v) return v * 2 end)
		return t.Value == 2 and t.Time == 0.2, "Value=" .. tostring(t.Value)
	end })
R.case({ id = "Quad0243",
	trigger = function() q.Tween({ Value = 1, Time = "0.3" }) end,
	fix = function() local t = q.Tween({ Value = 1, Time = 0.3 }); return t.Time == 0.3 end })
R.case({ id = "Quad0243", note = "via Animate State option at run",
	trigger = function()
		local s = q.Source(0)
		local f = D.Frame({ BackgroundTransparency = s:Apply(q.Animate({ Time = q.Source("x") })) })
		s:Set(1)
	end,
	fix = function()
		local s = q.Source(0)
		local f = D.Frame({ BackgroundTransparency = s:Apply(q.Animate({ Time = q.Source(0.3) })) })
		s:Set(1)
		return tweenedTo(f, "BackgroundTransparency", 1)
	end })
R.case({ id = "Quad0244",
	trigger = function() q.Tween({ Value = 1, Reverses = 1 }) end,
	fix = function() return q.Tween({ Value = 1, Reverses = true }).Reverses == true end })
R.case({ id = "Quad0245",
	trigger = function() q.Tween({ Value = 1, Dedup = "yes" }) end,
	fix = function() return q.Tween({ Value = 1, Dedup = false }).Dedup == false end })
R.case({ id = "Quad0246",
	trigger = function() q.Tween({ Value = 1, Completed = true }) end,
	fix = function()
		local done = false
		local f = D.Frame({ BackgroundTransparency = q.Tween({ Value = 1, Time = 0.1, Completed = function() done = true end }) })
		H.runTask(1)
		return done, "Completed fired=" .. tostring(done)
	end })
R.case({ id = "Quad0247",
	trigger = function() q.Tween({ Value = 1, Override = "cancel" }) end,
	fix = function()
		local a = q.Tween({ Value = 1, Override = "Cancel" })
		local b = q.Tween({ Value = 1 })
		return a.Override == "Cancel", "omitted Override field=" .. tostring(b.Override)
	end })
R.case({ id = "Quad0248",
	trigger = function() q.Tween(1) end,
	fix = function() return q.isTween(q.Tween({ Value = 1 })) end })
R.case({ id = "Quad0249",
	trigger = function() q.Tween({ Time = 1 }) end,
	fix = function() return q.Tween({ Value = 0, Time = 1 }).Value == 0 end })
R.case({ id = "Quad0249", note = "Mapped fn returning nil",
	trigger = function() q.Tween({ Value = 1 }):Mapped(function() return nil end) end })
R.case({ id = "Quad0250",
	trigger = function() q.Tween({ Value = q.Source(1) }) end,
	fix = function()
		-- (a) state:Apply(Animate{...})
		local s = q.Source(0)
		local f = D.Frame({ BackgroundTransparency = s:Apply(q.Animate({ Time = 0.2 })) })
		s:Set(1); H.runTask(1)
		-- (b) Compute inside which Tween{...} is built
		local s2 = q.Source(0)
		local f2 = D.Frame({ BackgroundTransparency = s2:Compute(function(h) return q.Tween({ Value = h:Get(), Time = 0.2 }) end) })
		s2:Set(1); H.runTask(1)
		local a, ad = tweenedTo(f, "BackgroundTransparency", 1)
		local b, bd = tweenedTo(f2, "BackgroundTransparency", 1)
		return a and b, "a=" .. ad .. " b=" .. bd
	end })
R.case({ id = "Quad0251",
	trigger = function() q.Tween({ Value = q.None }) end,
	fix = function()
		local s = q.Source(0.5)
		local f = D.Frame({ BackgroundTransparency = s })
		local before = f.BackgroundTransparency
		s:Set(q.None)
		return f.BackgroundTransparency == nil, "before=" .. tostring(before) .. " after None=" .. tostring(f.BackgroundTransparency)
	end })
R.case({ id = "Quad0251", note = "nested Tween",
	trigger = function() q.Tween({ Value = q.Tween({ Value = 1 }) }) end })
R.done()
