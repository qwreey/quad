--!nocheck
-- round13 E24 D — roblox/06 and GS 17 examples under mock.
local H = require("./round13-e15-probe-setup")
local q, D, mock = H.q, H.D, H.mock
local log = mock.tweenLog
local C = function(r, g, b) return { r = r, g = g, b = b, __c = true } end
local CMT = { __eq = function(a, b) return a.r == b.r and a.g == b.g and a.b == b.b end, __tostring = function(a) return a.r .. "," .. a.g .. "," .. a.b end }
local function rgb(r, g, b) return setmetatable({ r = r, g = g, b = b }, CMT) end
local GOLD, WHITE = rgb(255, 215, 0), rgb(255, 255, 255)

print("== GS17 §1 + callbacks ==")
do
	mock.resetTweenLog()
	local count = q.Source(0)
	local flash = q.Source(false)
	local lbl = D.TextLabel({
		TextColor3 = count:Compute(function(c)
			local n = c:Get()
			local isMilestone = n > 0 and n % 10 == 0
			return q.Tween({
				Value = if isMilestone then GOLD else WHITE,
				Time = if isMilestone then 0.6 else 0.2,
				Started = if isMilestone then function() flash:Set(true) end else nil,
				Completed = if isMilestone then function() flash:Set(false) end else nil,
				Cancelled = if isMilestone then function() flash:Set(false) end else nil,
			})
		end),
	})
	local btn = D.TextButton({ Text = flash:Compute(function(f) return if f:Get() then "*" else "+ 1" end) })
	for i = 1, 9 do count:Set(i) end
	print("after 1..9: tweens", #log, "color", tostring(lbl.TextColor3))
	count:Set(10); print("click10: tweens", #log, "btn", btn.Text)
	count:Set(11); print("click11 during gold: tweens", #log, "btn", btn.Text, "gold state", log[1].tween.PlaybackState)
	count:Set(20); print("click20: btn", btn.Text); log[#log].tween:simulateCompleted(); print("gold completes: btn", btn.Text)
	-- deferred window: gold reached target (PlaybackState Completed) but notice not yet delivered -> Completed fires synchronously
	count:Set(21); count:Set(30); log[#log].tween.PlaybackState = "Completed"; count:Set(31); print("replace in window: btn", btn.Text)
end
print("== roblox/06 examples ==")
do
	mock.resetTweenLog()
	local FADE = q.Tween({ Value = 0, Time = 0.15 })
	local a = FADE:Mapped(function(v) return 1 end)
	print("FADE Mapped", tostring(a), a.Time)
	local size = q.Source(q.Tween({ Value = 10, Time = 0.3 }))
	local box = D.Frame({ BackgroundTransparency = size })
	print("first set snap:", box.BackgroundTransparency, "tweens", #log)
	local alpha = q.Source(0)
	local reduceMotion = q.Source(false)
	local guarded = alpha:Apply(q.Animate({ Time = 0.3, CanAnimate = reduceMotion:Compute(function(s) return not s:Get() end) }))
	local b2 = D.Frame({ BackgroundTransparency = guarded })
	alpha:Set(0.5); print("guarded animate:", "tweens", #log)
	reduceMotion:Set(true); print("reduceMotion flip alone re-animates? tweens", #log)
	alpha:Set(0.8); print("after next change: BT", b2.BackgroundTransparency, "tweens", #log)
	-- CanAnimate false -> plain; then CanAnimate true again with same Value target
	reduceMotion:Set(false); alpha:Set(0.8); print("same value after flip back: tweens", #log)
	alpha:Set(0.2); print("next change animates: tweens", #log)
end
