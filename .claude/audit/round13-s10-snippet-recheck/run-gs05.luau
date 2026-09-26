--!nocheck
local H = require("./harness")
local q, D, None = H.q, H.D, H.None
UDim2 = H.EG.UDim2
Color3 = H.EG.Color3
Enum = H.EG.Enum

-- ── "지금까지의 코드" block (unchanged, needed for `count`/`card`) ──
local count = q.Source(0)
local countText = count:Compute(function(c) return `카운트: {c:Get()}` end)

local card = D.Frame {
	Size = UDim2.fromOffset(240, 160),
	BackgroundColor3 = Color3.fromRGB(35, 35, 42),
	UICorner = 12,
	D.TextLabel { Text = countText },
	D.TextButton { Text = "+ 1", Activated = function() count:Set(count:Get() + 1) end },
}

-- ── "1. 이름표 붙이기" block (unchanged, needed for Tag usage pattern) ──
card = D.Frame {
	q.Tag("Card"),
	Size = UDim2.fromOffset(240, 160),
	BackgroundColor3 = Color3.fromRGB(35, 35, 42),
	UICorner = 12,
	D.TextLabel { Text = countText },
	D.TextButton { Text = "+ 1", Activated = function() count:Set(count:Get() + 1) end },
}
print("tags after card2:", table.concat(H.game:GetService("CollectionService"):GetTags(card), ","))

-- ── TARGET (changed) block: inline Compute param type annotation ──
card = D.Frame {
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
print("tags after target (count=0, even):", table.concat(H.game:GetService("CollectionService"):GetTags(card), ","))
count:Set(1)
print("tags after count=1 (odd):", table.concat(H.game:GetService("CollectionService"):GetTags(card), ","))
