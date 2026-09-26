--!strict
-- E27 strict 누적 A — GS 01~10 Main.client 코드(문서 그대로, require 경로만 로컬 설정 모듈로).
-- 문서는 화면 코드를 nonstrict로 가정하지만(01 §1) strict 주석을 여러 자리에 달아 두었으므로 strict로 검사해 진단을 기록한다.
local Players = game:GetService("Players")
if not game:IsLoaded() then game.Loaded:Wait() end
const q = require("./Quad")
const D = q.Declaration
const playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
const screen = D.ScreenGui { ResetOnSpawn = false }
do -- 01#3
	const hello = D.TextLabel { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(240, 40),
		BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 18, Text = "Quad is running" }
	hello.Parent = screen
	screen.Parent = playerGui
end
do -- 02#2/#3/#4
	const card = D.Frame { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(240, 160),
		BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12 }
	card.Parent = screen
	print(card.ClassName)
	const card2 = D.Frame { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(240, 160),
		BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12,
		D.TextLabel { Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -32, 0, 48), BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255), TextScaled = true, Text = "카운트: 0" } }
	card2.Parent = screen
end
do -- 02#5
	const maybe = nil
	const card = D.Frame { D.TextLabel { Text = "a" }, maybe, D.TextLabel { Text = "b" } }
	print(card)
end
do -- 03#2
	const label = q.Source("카운트: 0")
	const card = D.Frame { D.TextLabel { Text = label } }
	label:Set("카운트: 1")
	print(card)
end
do -- 03#3/#4
	const count = q.Source(0)
	const countText = count:Compute(function(c) return `카운트: {c:Get()}` end)
	const card = D.Frame { D.TextLabel { Text = countText } }
	count:Set(7)
	const suffix = q.Source("회")
	const both = count:Compute(function(c, previous, s) return `{c:Get()}{s:Get()}` end, suffix)
	print(both:Get()); suffix:Set("번"); print(both:Get(), card)
end
do -- 04
	const count = q.Source(0)
	const countText = count:Compute(function(c) return `카운트: {c:Get()}` end)
	const card = D.Frame { Size = UDim2.fromOffset(240, 160), BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12,
		D.TextLabel { Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -32, 0, 48), BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255), TextScaled = true, Text = countText },
		D.TextButton { Size = UDim2.new(1, -40, 0, 42), Position = UDim2.new(0, 20, 1, -62), BackgroundColor3 = Color3.fromRGB(0, 162, 255),
			TextColor3 = Color3.fromRGB(255, 255, 255), Text = "+ 1", TextSize = 16, UICorner = 8,
			Activated = function() count:Set(count:Get() + 1) end } }
	card.Parent = screen
end
do -- 05
	const count = q.Source(0)
	const countText = count:Compute(function(c) return `카운트: {c:Get()}` end)
	const inst = D.Frame { q.Tag("Card"), q.Tag("Card", "Panel") }
	const active = q.Source(true)
	const card = D.Frame { q.Tag("Card"),
		count:Compute(function(c: q.StateData<number>) return q.Tag("Card"):Added(if c:Get() % 2 == 0 then "Even" else nil) end),
		q.Attr { Kind = "counter", Count = count }, q.BooleanAttr("Active", active),
		Size = UDim2.fromOffset(240, 160), BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12,
		D.TextLabel { Text = countText }, D.TextButton { Text = "+ 1", Activated = function() count:Set(count:Get() + 1) end } }
	card.Parent = screen
	const CollectionService = game:GetService("CollectionService")
	print(#CollectionService:GetTagged("Card"), inst)
	count:Set(2); count:Set(3)
	print(card:GetAttributes())
	active:Set(false); active:Set(q.None)
	print(D.Frame { q.Attr { Kind = "counter" }, q.Attr { Kind = "other" } })
	print(#screen:QueryDescendants(".Card"), #screen:QueryDescendants("[$Kind=counter]"))
end
do -- 06
	const name = q.Source("quad")
	const nameLabel = D.TextLabel { Size = UDim2.fromOffset(240, 28), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = name:Compute(function(n) return `{n:Get()}의 카운터` end) }
	nameLabel.Parent = screen
	local emits = 0
	name:Observer(function() emits += 1 end):Subscribe()
	print(emits)
	const nameBox = D.TextBox { q.Out("Text", name), Size = UDim2.fromOffset(240, 32), BackgroundColor3 = Color3.fromRGB(50, 50, 58),
		TextColor3 = Color3.fromRGB(255, 255, 255), PlaceholderText = "이름", Text = name }
	nameBox.Parent = screen
	const resetButton = D.TextButton { Size = UDim2.fromOffset(120, 28), Text = "이름 되돌리기", Activated = function() name:Set("quad") end }
	resetButton.Parent = screen
	const shout = q.Source("")
	D.TextBox { Text = name, q.OnChange("Text", function(v) shout:Set(string.upper(v)) end) }
	const derived = name:Compute(function(n) return n:Get() end)
	D.TextBox { q.Out("Text", derived) } -- 문서: strict에서 타입 검사가 먼저 막는다(기대 진단)
end
do -- 07
	const count = q.Source(0)
	do
		const buttonRef = q.Ref<<TextButton?>>(nil)
		const card = D.Frame { D.TextButton { buttonRef, Text = "+ 1", Activated = function() count:Set(count:Get() + 1) end } }
		print(buttonRef.Value.ClassName, card) -- 문서 07#1 그대로(strict면 Value가 nil일 수 있음)
		const a = q.Ref(nil)
		const b = q.Ref<<TextButton?>>(nil)
		print(a, b)
	end
	do
		const buttonRef = q.PreRef<<TextButton?>>(nil)
		const card = D.Frame { D.TextButton { buttonRef, Text = "+ 1", BackgroundTransparency = 0,
			Activated = function() count:Set(count:Get() + 1); buttonRef:Unwrap().BackgroundTransparency = 0.5 end } }
		print(card)
	end
	do
		const buttonRef = q.Ref<<TextButton?>>(nil)
		buttonRef:Callback(function(inst) print("상자:", if inst then inst.ClassName else "nil") end)
		const card = D.Frame { D.TextButton { buttonRef, Text = "+ 1" } }
		task.spawn(function()
			const inst = if buttonRef.Value then buttonRef.Value else buttonRef:Wait().Value
			print("버튼 준비됨:", inst.ClassName)
		end)
		task.spawn(function()
			const inst = if buttonRef.Value then buttonRef.Value else buttonRef:Wait():Unwrap()
			print("strict 권장형:", inst.ClassName)
		end)
		print(card)
	end
	do
		const doneRef = q.PostRef<<Frame?>>(nil)
		doneRef:Callback(function(inst) if inst then print("자식 수:", #inst:GetChildren()) end end)
		const card = D.Frame { doneRef, D.TextLabel { Text = "A" }, D.TextLabel { Text = "B" } }
		print(card)
	end
end
do -- 08
	const count = q.Source(0)
	const countText = count:Compute(function(c) return `카운트: {c:Get()}` end)
	const GuiService = game:GetService("GuiService")
	const buttonRef = q.Ref<<TextButton?>>(nil)
	const isBig = count:Compute(function(c) return c:Get() >= 10 end)
	const lonely = count:Observer(function(target) print("이건 한 번만 찍힙니다", target:Get()) end)
	const logger = q.Source<<q.Observer?>>(count:Observer(function(t) print("카운트", t:Get()) end))
	const card = D.Frame { logger,
		D.TextLabel { Text = countText, count:Observer(function(target: q.StateData<number>) print("카운트가", target:Get(), "가 되었습니다") end) },
		D.TextButton { buttonRef, Text = "+ 1", BackgroundTransparency = 0,
			Activated = function() count:Set(count:Get() + 1); buttonRef:Unwrap().BackgroundTransparency = 0.5 end,
			BackgroundColor3 = count:Compute(function(c: q.StateData<number>)
				return if c:Get() >= 10 then Color3.fromRGB(255, 190, 0) else Color3.fromRGB(0, 162, 255) end) },
		q.Effect(function()
			const n = count:Get()
			print("이펙트: 지금", n)
			return function() print("정리:", n, "회차의 뒤처리") end
		end, count),
		q.Effect(function()
			const inst = buttonRef.Value
			if inst and isBig:Get() then
				GuiService.SelectedObject = inst
				return function() if GuiService.SelectedObject == inst then GuiService.SelectedObject = nil end end
			end
			return nil
		end, isBig, buttonRef),
	}
	logger:Set(nil)
	print(lonely, card)
end
do -- 09
	const created = q.PreRef<<Frame?>>(nil)
	created:Callback(function(inst) if inst then print("만들어짐:", inst.ClassName) end end)
	const rendered = q.PostRef<<Frame?>>(nil)
	rendered:Callback(function(inst) if inst then const kids = inst:GetChildren(); print("다 그려짐: 자식", #kids, "개") end end)
	const card = D.Frame { UICorner = 12, created, rendered, q.Effect(function() return function() print("없어짐") end end),
		D.TextLabel {}, D.TextButton {} }
	const card2 = D.Frame { UICorner = 12,
		q.OnCreated<<Frame>>(function(inst) print("만들어짐:", inst.ClassName) end),
		q.OnRendered<<Frame>>(function(inst) const kids = inst:GetChildren(); print("다 그려짐: 자식", #kids, "개") end),
		q.OnDestroyed(function() print("없어짐") end),
		D.TextLabel {}, D.TextButton {} }
	print(card, card2)
end
do -- 10
	const hot = q.Source(false)
	const cardColor = hot:Compute(function(h) return if h:Get() then Color3.fromRGB(240, 60, 60) else Color3.fromRGB(35, 35, 42) end)
	const CardStyle = D.Modifier.Frame { BackgroundColor3 = cardColor, BorderSizePixel = 0 }
	const card = D.Frame { CardStyle, Size = UDim2.fromOffset(240, 160), UICorner = 12 }
	hot:Set(true)
	const base = D.Modifier.TextButton { TextSize = 16 }
	const big = base:TextSize(24)
	local function accent(color)
		return D.Modifier.TextButton { BackgroundColor3 = color, TextColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0 }
	end
	const button = D.TextButton { accent(Color3.fromRGB(0, 162, 255)), Text = "+ 1" }
	const accentColor = q.Source(Color3.fromRGB(0, 162, 255))
	const button2 = D.TextButton { accent(accentColor), Text = "+ 1" }
	accentColor:Set(Color3.fromRGB(240, 60, 60))
	local function emphasis(size)
		return function(mod) return mod:TextSize(size):TextColor3(Color3.fromRGB(255, 230, 120)) end
	end
	const title = D.Modifier.TextLabel { BackgroundTransparency = 1 }:Apply(emphasis(24))
	const label = D.TextLabel { title, Text = "카운터" }
	print(card, big, button, button2, label)
end
