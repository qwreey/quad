--!nocheck
-- round13 E24 E — does an Animate option State change alone re-run the Animate Compute? (doc: "옵션 State는 의존성이 아닙니다")
local H = require("./round13-e15-probe-setup")
local q, D, mock = H.q, H.D, H.mock
local log = mock.tweenLog
local function case(label, optKey, v0, v1, v2)
	mock.resetTweenLog()
	local alpha = q.Source(0)
	local opt = q.Source(v0)
	local runs = 0
	local counted = alpha:Compute(function(s) runs += 1 return s:Get() end)
	local st = counted:Apply(q.Animate({ Time = 0.3, [optKey] = opt }))
	local f = D.Frame({ BackgroundTransparency = st })
	alpha:Set(0.5)
	local t0 = #log
	opt:Set(v1)
	local t1 = #log
	opt:Set(v2)
	print(string.format("%-28s tweens after alpha:Set %d | opt->%s %d | opt->%s %d | BT=%s", label, t0, tostring(v1), t1, tostring(v2), #log, tostring(f.BackgroundTransparency)))
end
case("CanAnimate true->false->true", "CanAnimate", true, false, true)
case("Time 0.3->1->2", "Time", 0.3, 1, 2)
-- a CanAnimate that is a Compute (the doc example shape)
do
	mock.resetTweenLog()
	local alpha = q.Source(0)
	local rm = q.Source(false)
	local st = alpha:Apply(q.Animate({ Time = 0.3, CanAnimate = rm:Compute(function(s) return not s:Get() end) }))
	local f = D.Frame({ BackgroundTransparency = st })
	alpha:Set(0.5); local a = #log
	rm:Set(true); local b = #log
	rm:Set(false); local c = #log
	print("Compute CanAnimate:", a, b, c, "BT", f.BackgroundTransparency)
end
do
	local s = q.Source(1); local n = 0
	local c = s:Compute(function(h) n += 1 return h:Get() end)
	local o = c:Observer(function() end)
	local before = n
	s:Set(1)
	print("Source same-value Set re-runs Compute:", n - before)
	mock.resetTweenLog()
	local alpha = q.Source(0); local rm = q.Source(false)
	local st = alpha:Apply(q.Animate({ Time = 0.3, CanAnimate = rm:Compute(function(s2) return not s2:Get() end) }))
	local f = D.Frame({ BackgroundTransparency = st })
	alpha:Set(0.5); rm:Set(true); alpha:Set(0.8); print("plain write:", #log, f.BackgroundTransparency)
	rm:Set(false); print("rm false:", #log)
	alpha:Set(0.8); print("alpha same 0.8:", #log)
	alpha:Set(0.5); alpha:Set(0.8); print("0.5 then 0.8:", #log)
end
print("-- isolate same-value Set")
for _, variant in { "noOptChange", "optChange", "literalCanAnimate" } do
	mock.resetTweenLog()
	local alpha = q.Source(0); local rm = q.Source(false)
	local runs = 0
	local info = { Time = 0.3, CanAnimate = if variant == "literalCanAnimate" then true else rm:Compute(function(s2) return not s2:Get() end) }
	local st = alpha:Apply(q.Animate(info))
	local probe = st:Observer(function() runs += 1 end)
	local f = D.Frame({ BackgroundTransparency = st })
	alpha:Set(0.5); local a = #log; local r0 = runs
	if variant == "optChange" then rm:Set(true) rm:Set(false) end
	alpha:Set(0.5)
	print(variant, "tweens", a, "->", #log, "observer runs", r0, "->", runs)
end
print("-- exact sequence with observer")
for _, flip in { true, false } do
	mock.resetTweenLog()
	local alpha = q.Source(0); local rm = q.Source(false)
	local runs, seen = 0, {}
	local st = alpha:Apply(q.Animate({ Time = 0.3, CanAnimate = rm:Compute(function(s2) return not s2:Get() end) }))
	local probe = st:Observer(function(o) runs += 1 end)
	local f = D.Frame({ BackgroundTransparency = st })
	alpha:Set(0.5)
	if flip then rm:Set(true) end
	alpha:Set(0.8)
	local r1, t1 = runs, #log
	if flip then rm:Set(false) end
	alpha:Set(0.8)
	print("flip", flip, "after 0.8: runs", r1, "tweens", t1, "| same 0.8 again: runs", runs, "tweens", #log)
end
print("-- who re-emits")
do
	mock.resetTweenLog()
	local alpha = q.Source(0); local rm = q.Source(false)
	local up = 0
	local counted = alpha:Compute(function(s) up += 1 return s:Get() end)
	local canA = rm:Compute(function(s2) return not s2:Get() end)
	local st = counted:Apply(q.Animate({ Time = 0.3, CanAnimate = canA }))
	local f = D.Frame({ BackgroundTransparency = st })
	alpha:Set(0.5); rm:Set(true); alpha:Set(0.8)
	local u1, t1, v1 = up, #log, st:Get()
	print("before: up", u1, "tweens", t1, "st:Get", v1, q.isTween(v1))
	rm:Set(false)
	print("after rm false (no alpha set): up", up, "tweens", #log)
	local v2 = st:Get()
	print("st:Get after rm false:", q.isTween(v2) and ("Tween " .. tostring(v2)) or tostring(v2), "tweens", #log)
	alpha:Set(0.8)
	print("after same alpha: up", up, "tweens", #log, "props", #log > t1 and tostring(log[#log].props.BackgroundTransparency) or "-")
end
print("-- minimal: same-value Set after a real change, with/without option flip")
for _, mode in { "none", "rmflip", "rmflipLiteralTrue" } do
	mock.resetTweenLog()
	local alpha = q.Source(0); local rm = q.Source(false)
	local up = 0
	local counted = alpha:Compute(function(s) up += 1 return s:Get() end)
	local info = { Time = 0.3 }
	if mode ~= "rmflipLiteralTrue" then info.CanAnimate = rm:Compute(function(s2) return not s2:Get() end) end
	local st = counted:Apply(q.Animate(info))
	local f = D.Frame({ BackgroundTransparency = st })
	alpha:Set(0.8)
	local u0, t0 = up, #log
	if mode ~= "none" then rm:Set(true); rm:Set(false) end
	alpha:Set(0.8)
	print(mode, "up", u0, "->", up, "tweens", t0, "->", #log)
end
-- plain Compute chain, no Animate
do
	local alpha = q.Source(0); local up = 0
	local c = alpha:Compute(function(s) up += 1 return s:Get() end)
	local f = D.Frame({ BackgroundTransparency = c })
	alpha:Set(0.8); local u0 = up; alpha:Set(0.8)
	print("plain chain same-value: up", u0, "->", up)
end
