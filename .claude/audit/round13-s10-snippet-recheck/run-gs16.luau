--!nocheck
local H = require("./harness")
local q, D = H.q, H.D
UDim2 = H.EG.UDim2

local settings = q.Store({
	Step = q.Source(1),
})

local screen = D.Frame {}

local stepButton = D.TextButton {
	Size = UDim2.fromOffset(120, 32),
	Text = settings.Step:Compute(function(s: q.StateData<number>) -- 테이블 안 인라인 Compute는 파라미터 타입을 적습니다
		return `보폭: {s:Get()}`
	end),
	Activated = function()
		settings.Step:Set(settings.Step:Get() % 5 + 1) -- 1→2→…→5→1
	end,
}
stepButton.Parent = screen

print(stepButton.Text)
for _ = 1, 6 do
	stepButton.Activated:Fire()
	print(stepButton.Text)
end
