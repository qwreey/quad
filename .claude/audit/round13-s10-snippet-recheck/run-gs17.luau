--!nocheck
local H = require("./harness")
local q, D = H.q, H.D
local mock = require("../../../quad-base/test/mock")
Color3 = H.EG.Color3
Enum = H.EG.Enum

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

print("tweens after mount:", #mock.tweenLog)
for i = 1, 9 do
	button.Activated:Fire()
end
print("tweens after 1..9 clicks (should be 0):", #mock.tweenLog, "button text:", button.Text)

button.Activated:Fire() -- 10th click, milestone
print("tweens after 10th click (should be 1):", #mock.tweenLog, "button text (should be ✨):", button.Text)

-- simulate the tween finishing naturally
local tween10 = mock.tweenLog[#mock.tweenLog].tween
tween10:simulateCompleted()
print("button text after Completed (should be + 1):", button.Text)

count:Set(10) -- back to a milestone value again to trigger a fresh milestone tween
button.Activated:Fire() -- 11th click -> n=11, not milestone; but let's go to 20 to test Cancel path
for i = 12, 19 do
	button.Activated:Fire()
end
print("tweens before 20th click:", #mock.tweenLog)
button.Activated:Fire() -- 20th click, milestone
print("button text at 20th (should be ✨):", button.Text)
button.Activated:Fire() -- 21st click -> cancels the gold tween, starts a white one -> Cancelled fires
print("button text right after cancel (should be + 1):", button.Text)
