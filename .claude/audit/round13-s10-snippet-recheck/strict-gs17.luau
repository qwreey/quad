--!strict
local q = require("./s10-config")
local D = q.Declaration

local count = q.Source(0)
local flash = q.Source(false)

local label = D.TextLabel {
	TextColor3 = count:Compute(function(c: q.StateData<number>) -- 테이블 안 인라인 Compute는 파라미터 타입을 적습니다
		local n = c:Get()
		local isMilestone = n > 0 and n % 10 == 0

		return q.Tween {
			Value = if isMilestone then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(255, 255, 255),
			Time = if isMilestone then 0.6 else 0.2,
			Style = Enum.EasingStyle.Quad,
			Override = "Cancel",
			Started = if isMilestone then function() flash:Set(true) end else nil,
			Completed = if isMilestone then function() flash:Set(false) end else nil,
			Cancelled = if isMilestone then function() flash:Set(false) end else nil,
		}
	end),
}

local button = D.TextButton {
	Text = flash:Compute(function(f: q.StateData<boolean>) return if f:Get() then "✨" else "+ 1" end),
	Activated = function() count:Set(count:Get() + 1) end,
}
print(label, button)
