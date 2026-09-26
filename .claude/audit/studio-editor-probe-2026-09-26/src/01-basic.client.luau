-- 01-basic — 기본 편집기(플래그 없음, 모드 지시자 없음 = Studio 기본 nonstrict) 프로브
-- 볼 것(README 표 1~5): 편집기 밑줄/에러, 자동완성, Play 뒤 화면·출력.
-- 어떤 줄이 편집기에서 빨간 밑줄이면 그 줄 번호와 메시지를 README에 적어 주세요.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Quad = require(ReplicatedStorage["quad-base"].src)
local QuadRoblox = require(ReplicatedStorage["quad-roblox"].src).QuadRoblox
local q = Quad:UseProvider(QuadRoblox)
local D = q.Declaration

-- (A) `const` — 문서 전체가 쓰는 문법. 편집기가 모르면 여기부터 빨갛다.
const count = q.Source(0)

-- (B) 명시적 타입 인자 `<<T>>` — 문서 관행(시작하기 11 등)
const items = q.Source<<{ string }>>({ "a", "b" })

-- (C) `read` 필드 + 타입 주석 — 컴포넌트 props 관행(how-to 01)
local function Counter(props: { read Label: string, read Count: q.State<number>, read OnClick: () -> () }): TextButton
	return D.TextButton {
		Size = UDim2.fromOffset(240, 40),
		Position = UDim2.fromOffset(20, 20),
		-- (D) `if … then … else` 표현식 + 문자열 보간
		Text = props.Count:Compute(function(self)
			local n = self:Get()
			return `{props.Label}: {n}{if n >= 3 then " (3 이상)" else ""}`
		end),
		Activated = props.OnClick,
	}
end

const gui = D.ScreenGui {
	Name = "QuadEditorProbe01",
	Counter {
		Label = "count",
		Count = count,
		OnClick = function()
			count:Set(count:Get() + 1)
		end,
	},
}
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
print("[editor-probe 01] mounted; items =", #items:Get())
