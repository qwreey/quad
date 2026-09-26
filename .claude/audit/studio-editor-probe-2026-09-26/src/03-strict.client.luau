--!strict
-- 03-strict — 01과 같은 코드에 `--!strict`만 붙인 것. Studio **내장** 타입 검사기(luau-lsp 아님)가
-- quad 타입을 어떻게 보는지 — 볼 것(README 표 7): 스크립트 분석 창의 경고/에러 개수와 첫 세 개의 메시지·줄 번호.
-- (Studio 베타 "새 타입 솔버"가 켜져 있는지 꺼져 있는지도 같이 적어 주세요 — 둘 다 보면 더 좋습니다.)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Quad = require(ReplicatedStorage["quad-base"].src)
local QuadRoblox = require(ReplicatedStorage["quad-roblox"].src).QuadRoblox
local q = Quad:UseProvider(QuadRoblox)
local D = q.Declaration

const count = q.Source(0)

local function Counter(props: { read Label: string, read Count: q.State<number>, read OnClick: () -> () }): TextButton
	return D.TextButton {
		Size = UDim2.fromOffset(240, 40),
		Position = UDim2.fromOffset(20, 80),
		Text = props.Count:Compute(function(self)
			return `{props.Label}: {self:Get()}`
		end),
		Activated = props.OnClick,
	}
end

const gui = D.ScreenGui {
	Name = "QuadEditorProbe03",
	Counter {
		Label = "strict",
		Count = count,
		OnClick = function()
			count:Set(count:Get() + 1)
		end,
	},
}
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
print("[editor-probe 03] mounted")
