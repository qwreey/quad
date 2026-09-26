--!strict
local q = require("./s10-config")
local D = q.Declaration

local count = q.Source(0)
local countText = count:Compute(function(c) return `카운트: {c:Get()}` end)

local card = D.Frame {
	q.Tag("Card"),
	count:Compute(function(c: q.StateData<number>) -- 숫자 키 자리의 인라인 Compute도 파라미터 타입을 적어야 strict가 봅니다
		return q.Tag("Card"):Added(if c:Get() % 2 == 0 then "Even" else nil)
	end),

	Size = UDim2.fromOffset(240, 160),
	BackgroundColor3 = Color3.fromRGB(35, 35, 42),
	UICorner = 12,
	D.TextLabel { Text = countText },
	D.TextButton { Text = "+ 1", Activated = function() count:Set(count:Get() + 1) end },
}
