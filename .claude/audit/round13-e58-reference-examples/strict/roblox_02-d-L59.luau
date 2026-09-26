--!strict
-- E58 strict (generated) — roblox_02-d-L59
-- ==== page prologue roblox/02-d.md (roblox_02-d-L22.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block roblox/02-d.md:59 (line offset marker) ====
local hovered = q.Source(false)
local label = q.Source("확인")
local ref = q.PreRef<<TextButton?>>(nil)

local button = D.TextButton({
	-- 문자 키 — 프로퍼티와 이벤트
	Text = label,                                   -- State: 값이 바뀌면 프로퍼티가 따라간다
	Size = UDim2.fromOffset(120, 36),               -- 평범한 값
	BackgroundColor3 = hovered:Compute(function(self: q.StateData<boolean>): Color3
		return if self:Get() then Color3.fromRGB(60, 130, 255) else Color3.fromRGB(30, 30, 30)
	end),
	TextTransparency = q.Tween({ Value = 0, Time = 0.2 }), -- Tween 값
	MouseEnter = function()                          -- 이벤트: 엔진 인자만 받는다
		hovered:Set(true)
	end,
	MouseLeave = function()
		hovered:Set(false)
	end,
	UICorner = 6,                                    -- 숏핸드 키

	-- 숫자 키 — 자식·Modifier·Ref·디스크립터
	D.UIPadding({ PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
	D.Modifier.TextButton():TextSize(18),
	ref,
	q.Tag("primary"),
	q.OnChange("Text", function(v: string)
		print(v)
	end),
})

button.Parent = script.Parent -- 붙이는 것은 props가 아니라 밖의 한 줄
