--!strict
local q = require("./s10-config")
local D = q.Declaration

local count = q.Source(0)
local countText = count:Compute(function(c) return `카운트: {c:Get()}` end)

local card = D.Frame {
	D.TextLabel {
		Text = countText,
		count:Observer(function(target: q.StateData<number>) -- 숫자 키 자리에선 파라미터 타입을 적어 주세요
			print("카운트가", target:Get(), "가 되었습니다")
		end),
	},
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
print(card)
