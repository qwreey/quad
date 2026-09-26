--!nocheck
-- round13 E24 C — Tween:Mapped edge returns, reuse of one Tween value, and a "strict engine" shim
-- (Create raises like the engine on a non-interpolable property / non-TweenInfo) to see the handler's recovery.
local H = require("./round13-e15-probe-setup")
local q, D, mock = H.q, H.D, H.mock
local log = mock.tweenLog
local installProperty = require("../../quad-roblox/src/Handlers/Property")
local function short(e) local s = (tostring(e):gsub("\n.*", "")); local id = s:match("Quad%d%d%d%d") or "VM"; local w = s:match("([%w%-%._]+%.luau:%d+):") return id .. " @" .. tostring(w) .. (id == "VM" and (" " .. s:sub(1, 90)) or "") end
local function try(label, fn) local ok, e = pcall(fn); print(string.format("%-46s %s", label, ok and ("OK " .. tostring(e)) or ("ERR " .. short(e)))) end

print("== Mapped ==")
local base = q.Tween({ Value = 1, Time = 0.3, Override = "Finish" })
try("fn returns nil", function() return base:Mapped(function() return nil end) end) -- LINE 13
try("fn returns false", function() return tostring(base:Mapped(function() return false end)) end)
try("fn returns State", function() return base:Mapped(function() return q.Source(2) end) end)
try("fn returns Tween", function() return base:Mapped(function() return q.Tween({ Value = 2 }) end) end)
try("fn returns None", function() return base:Mapped(function() return q.None end) end)
try("fn returns string (type change)", function() return tostring(base:Mapped(function() return "s" end)) end)
try("fn throws", function() return base:Mapped(function() error("boom") end) end)
try("fn yields (coroutine)", function()
	local co = coroutine.create(function() return base:Mapped(function(v) coroutine.yield(); return v end) end)
	local ok, r = coroutine.resume(co); return tostring(ok) .. " status=" .. coroutine.status(co)
end)
try("dot call base.Mapped(fn)", function() return base.Mapped(function() return 2 end) end)
try("Mapped on plain table", function() return base.Mapped({ Value = 1 }, function(v) return v end) end)
local m = base:Mapped(function(v) return v * 2 end)
print("mapped keeps opts:", m.Time, m.Override, "frozen", table.isfrozen(m), "orig", base.Value)
-- Mapped carries callbacks: same callback on two props via Mapped (not the P-TWEEN T5 shared-State case)
local n = 0
local cbT = q.Tween({ Value = 0.1, Time = 0.2, Completed = function() n += 1 end })
do
	mock.resetTweenLog()
	local a, b = q.Source(0.5), q.Source(0.5)
	local f = D.Frame({ BackgroundTransparency = a, LayoutOrder = b })
	a:Set(cbT); b:Set(cbT:Mapped(function(v) return v * 100 end))
	for _, e in log do e.tween:simulateCompleted() end
	print("Mapped callbacks on two props: Completed x", n, "tweens", #log)
end
print("== reuse one Tween value ==")
do
	mock.resetTweenLog()
	local tw = q.Tween({ Value = 0.2, Time = 1 })
	local s1, s2 = q.Source(0.9), q.Source(0.9)
	local f1 = D.Frame({ BackgroundTransparency = s1 })
	local f2 = D.Frame({ BackgroundTransparency = s2, LayoutOrder = q.Source(tw) })
	s1:Set(tw); s2:Set(tw)
	print("two instances + second prop first-set:", "tweens", #log, "f2.LayoutOrder(snap)", f2.LayoutOrder)
	-- after finishing on f1, re-set the same object later
	log[1].tween:simulateCompleted(); f1.BackgroundTransparency = 0.2
	s1:Set(0.9); s1:Set(tw)
	print("re-set same object after plain:", "tweens", #log)
	-- mutate attempt
	print("mutate frozen:", pcall(function() tw.Value = 5 end))
	-- Tween used as Source initial on two Frames directly (static)
	local g1 = D.Frame({ BackgroundTransparency = tw }); local g2 = D.Frame({ BackgroundTransparency = tw })
	print("static on two frames (both first-set snap):", g1.BackgroundTransparency, g2.BackgroundTransparency, "tweens", #log)
end
print("== Animate factory reuse with option State ==")
do
	mock.resetTweenLog()
	local time = q.Source(0.3)
	local fac = q.Animate({ Time = time })
	local a, b = q.Source(0), q.Source(0)
	local fa = D.Frame({ BackgroundTransparency = a:Apply(fac) })
	local fb = D.Frame({ BackgroundTransparency = b:Apply(fac) })
	a:Set(1); time:Set(2); b:Set(1)
	print("shared factory, option State changed between:", log[1].info.args[1], log[2].info.args[1], "tweens", #log)
	local st = a:Apply(fac); local st2 = a:Apply(fac)
	print("same source applied twice -> distinct States:", st ~= st2)
end
print("== strict engine shim: Create raises on type mismatch / non-TweenInfo ==")
local game = (getfenv(installProperty)).game
local TS = game:GetService("TweenService")
local origCreate = TS.Create
TS.Create = function(self, inst, info, props)
	if type(info) ~= "table" or not info.__mockTweenInfo then error("Unable to cast value to TweenInfo", 2) end
	for k, v in props do
		if type(v) == "string" or type(v) ~= type(inst[k]) then error("TweenService:Create property named '" .. k .. "' cannot be tweened due to type mismatch", 2) end
	end
	return origCreate(self, inst, info, props)
end
do
	mock.resetTweenLog()
	-- non-interpolable (string) property: Name via a Tween (types forbid — Q34; runtime)
	local s = q.Source(q.Tween({ Value = "a" }))
	local f = D.Frame({ Name = s })
	print("Name first-set snap:", f.Name)
	try("Name second Tween -> engine raise", function() s:Set(q.Tween({ Value = "b" })) end)
	print("  after raise Name=", f.Name, "tweens", #log)
	try("recover with plain 'c'", function() s:Set("c") end)
	print("  Name=", f.Name)
	try("recover with Tween 'd'", function() s:Set(q.Tween({ Value = "d" })) end)
	-- Animate over a string State on Name (types: Animate returns State<Tween<any>>)
	local t = q.Source("x")
	local g = D.Frame({ Name = t:Apply(q.Animate({ Time = 0.2 })) })
	try("Animate string State Set", function() t:Set("y") end)
	print("  Name=", g.Name)
	-- Info=State slipped into Tween (field not checked)
	local u = q.Source(0.5)
	local h = D.Frame({ BackgroundTransparency = u })
	local fired = {}
	try("Tween Info=State -> engine raise", function() u:Set(q.Tween({ Value = 0.1, Info = q.Source(1), Started = function() table.insert(fired, "S") end })) end)
	print("  BT=", h.BackgroundTransparency, "fired", #fired)
	try("next Tween after raise", function() u:Set(q.Tween({ Value = 0.3 })) end)
	print("  tweens", #log)
	-- Running tween, then a bad Tween arrives: is the running one kept (H-406)?
	mock.resetTweenLog()
	local w = q.Source(0.5)
	local k = D.Frame({ BackgroundTransparency = w })
	local x = {}
	w:Set(q.Tween({ Value = 0.1, Cancelled = function() table.insert(x, "X") end }))
	try("bad Tween over running", function() w:Set(q.Tween({ Value = "bad" })) end)
	print("  running tween state:", log[1].tween.PlaybackState, "cancelled cb", #x)
	try("good Tween after", function() w:Set(q.Tween({ Value = 0.7 })) end)
	print("  first tween state:", log[1].tween.PlaybackState, "cancelled cb", #x, "tweens", #log)
end
