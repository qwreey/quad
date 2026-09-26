--!nocheck
local H = require("./harness")
local q, D = H.q, H.D
UDim2 = H.EG.UDim2
Color3 = H.EG.Color3

local count = q.Source(0)
local countText = count:Compute(function(c) return `카운트: {c:Get()}` end)

-- ── TARGET block 1: Observer inline in numeric key with typed param ──
local card = D.Frame {
	D.TextLabel {
		Text = countText,
		count:Observer(function(target: q.StateData<number>) -- 숫자 키 자리에선 파라미터 타입을 적어 주세요
			print("카운트가", target:Get(), "가 되었습니다")
		end),
	},
	-- ── TARGET block 2: Compute inline as named-key setter with typed param ──
	D.TextButton {
		Text = "+ 1",
		BackgroundColor3 = count:Compute(function(c: q.StateData<number>) -- 인라인 자리라 파라미터 타입을 적습니다
			return if c:Get() >= 10
				then Color3.fromRGB(255, 190, 0)
				else Color3.fromRGB(0, 162, 255)
		end),
		Activated = function() count:Set(count:Get() + 1) end,
	},
}
print("built card:", card.ClassName)
count:Set(5)
count:Set(10)
