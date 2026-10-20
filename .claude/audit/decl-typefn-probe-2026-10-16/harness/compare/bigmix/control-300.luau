--!strict
-- [2026-10-20 unit 0 control: same block count/shape, plain engine code, no quad types]
local function Hover0(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card0(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 0
	local h = Hover0(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(0, 0)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok0"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://0"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover1(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card1(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 1
	local h = Hover1(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(1, 1)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok1"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://1"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover2(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card2(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 2
	local h = Hover2(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(2, 2)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok2"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://2"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover3(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card3(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 3
	local h = Hover3(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(3, 3)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok3"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://3"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover4(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card4(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 4
	local h = Hover4(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(4, 4)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok4"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://4"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover5(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card5(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 5
	local h = Hover5(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(5, 5)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok5"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://5"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover6(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card6(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 6
	local h = Hover6(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(6, 6)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok6"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://6"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover7(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card7(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 7
	local h = Hover7(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(7, 7)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok7"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://7"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover8(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card8(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 8
	local h = Hover8(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(8, 8)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok8"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://8"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover9(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card9(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 9
	local h = Hover9(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(9, 9)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok9"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://9"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover10(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card10(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 10
	local h = Hover10(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(10, 10)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok10"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://10"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover11(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card11(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 11
	local h = Hover11(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(11, 11)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok11"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://11"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover12(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card12(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 12
	local h = Hover12(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(12, 12)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok12"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://12"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover13(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card13(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 13
	local h = Hover13(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(13, 13)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok13"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://13"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover14(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card14(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 14
	local h = Hover14(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(14, 14)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok14"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://14"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover15(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card15(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 15
	local h = Hover15(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(15, 15)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok15"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://15"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover16(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card16(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 16
	local h = Hover16(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(16, 16)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok16"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://16"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover17(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card17(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 17
	local h = Hover17(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(17, 17)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok17"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://17"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover18(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card18(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 18
	local h = Hover18(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(18, 18)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok18"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://18"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover19(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card19(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 19
	local h = Hover19(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(19, 19)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok19"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://19"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover20(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card20(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 20
	local h = Hover20(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(20, 20)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok20"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://20"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover21(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card21(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 21
	local h = Hover21(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(21, 21)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok21"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://21"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover22(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card22(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 22
	local h = Hover22(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(22, 22)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok22"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://22"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover23(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card23(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 23
	local h = Hover23(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(23, 23)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok23"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://23"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover24(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card24(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 24
	local h = Hover24(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(24, 24)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok24"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://24"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover25(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card25(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 25
	local h = Hover25(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(25, 25)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok25"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://25"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover26(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card26(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 26
	local h = Hover26(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(26, 26)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok26"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://26"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover27(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card27(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 27
	local h = Hover27(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(27, 27)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok27"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://27"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover28(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card28(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 28
	local h = Hover28(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(28, 28)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok28"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://28"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover29(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card29(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 29
	local h = Hover29(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(29, 29)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok29"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://29"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover30(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card30(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 30
	local h = Hover30(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(30, 30)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok30"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://30"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover31(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card31(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 31
	local h = Hover31(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(31, 31)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok31"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://31"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover32(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card32(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 32
	local h = Hover32(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(32, 32)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok32"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://32"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover33(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card33(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 33
	local h = Hover33(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(33, 33)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok33"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://33"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover34(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card34(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 34
	local h = Hover34(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(34, 34)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok34"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://34"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover35(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card35(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 35
	local h = Hover35(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(35, 35)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok35"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://35"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover36(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card36(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 36
	local h = Hover36(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(36, 36)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok36"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://36"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover37(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card37(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 37
	local h = Hover37(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(37, 37)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok37"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://37"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover38(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card38(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 38
	local h = Hover38(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(38, 38)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok38"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://38"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover39(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card39(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 39
	local h = Hover39(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(39, 39)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok39"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://39"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover40(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card40(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 40
	local h = Hover40(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(40, 40)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok40"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://40"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover41(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card41(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 41
	local h = Hover41(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(41, 41)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok41"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://41"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover42(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card42(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 42
	local h = Hover42(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(42, 42)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok42"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://42"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover43(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card43(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 43
	local h = Hover43(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(43, 43)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok43"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://43"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover44(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card44(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 44
	local h = Hover44(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(44, 44)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok44"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://44"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover45(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card45(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 45
	local h = Hover45(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(45, 45)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok45"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://45"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover46(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card46(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 46
	local h = Hover46(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(46, 46)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok46"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://46"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover47(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card47(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 47
	local h = Hover47(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(47, 47)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok47"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://47"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover48(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card48(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 48
	local h = Hover48(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(48, 48)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok48"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://48"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover49(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card49(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 49
	local h = Hover49(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(49, 49)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok49"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://49"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover50(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card50(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 50
	local h = Hover50(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(50, 50)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok50"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://50"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover51(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card51(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 51
	local h = Hover51(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(51, 51)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok51"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://51"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover52(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card52(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 52
	local h = Hover52(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(52, 52)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok52"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://52"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover53(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card53(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 53
	local h = Hover53(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(53, 53)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok53"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://53"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover54(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card54(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 54
	local h = Hover54(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(54, 54)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok54"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://54"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover55(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card55(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 55
	local h = Hover55(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(55, 55)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok55"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://55"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover56(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card56(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 56
	local h = Hover56(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(56, 56)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok56"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://56"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover57(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card57(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 57
	local h = Hover57(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(57, 57)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok57"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://57"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover58(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card58(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 58
	local h = Hover58(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(58, 58)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok58"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://58"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover59(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card59(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 59
	local h = Hover59(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(59, 59)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok59"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://59"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover60(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card60(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 60
	local h = Hover60(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(60, 60)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok60"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://60"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover61(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card61(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 61
	local h = Hover61(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(61, 61)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok61"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://61"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover62(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card62(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 62
	local h = Hover62(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(62, 62)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok62"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://62"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover63(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card63(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 63
	local h = Hover63(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(63, 63)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok63"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://63"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover64(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card64(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 64
	local h = Hover64(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(64, 64)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok64"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://64"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover65(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card65(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 65
	local h = Hover65(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(65, 65)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok65"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://65"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover66(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card66(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 66
	local h = Hover66(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(66, 66)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok66"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://66"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover67(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card67(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 67
	local h = Hover67(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(67, 67)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok67"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://67"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover68(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card68(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 68
	local h = Hover68(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(68, 68)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok68"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://68"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover69(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card69(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 69
	local h = Hover69(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(69, 69)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok69"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://69"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover70(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card70(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 70
	local h = Hover70(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(70, 70)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok70"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://70"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover71(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card71(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 71
	local h = Hover71(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(71, 71)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok71"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://71"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover72(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card72(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 72
	local h = Hover72(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(72, 72)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok72"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://72"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover73(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card73(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 73
	local h = Hover73(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(73, 73)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok73"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://73"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover74(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card74(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 74
	local h = Hover74(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(74, 74)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok74"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://74"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover75(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card75(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 75
	local h = Hover75(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(75, 75)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok75"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://75"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover76(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card76(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 76
	local h = Hover76(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(76, 76)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok76"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://76"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover77(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card77(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 77
	local h = Hover77(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(77, 77)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok77"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://77"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover78(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card78(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 78
	local h = Hover78(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(78, 78)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok78"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://78"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover79(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card79(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 79
	local h = Hover79(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(79, 79)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok79"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://79"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover80(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card80(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 80
	local h = Hover80(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(80, 80)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok80"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://80"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover81(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card81(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 81
	local h = Hover81(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(81, 81)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok81"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://81"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover82(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card82(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 82
	local h = Hover82(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(82, 82)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok82"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://82"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover83(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card83(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 83
	local h = Hover83(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(83, 83)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok83"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://83"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover84(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card84(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 84
	local h = Hover84(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(84, 84)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok84"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://84"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover85(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card85(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 85
	local h = Hover85(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(85, 85)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok85"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://85"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover86(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card86(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 86
	local h = Hover86(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(86, 86)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok86"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://86"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover87(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card87(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 87
	local h = Hover87(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(87, 87)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok87"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://87"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover88(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card88(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 88
	local h = Hover88(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(88, 88)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok88"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://88"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover89(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card89(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 89
	local h = Hover89(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(89, 89)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok89"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://89"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover90(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card90(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 90
	local h = Hover90(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(90, 90)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok90"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://90"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover91(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card91(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 91
	local h = Hover91(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(91, 91)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok91"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://91"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover92(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card92(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 92
	local h = Hover92(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(92, 92)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok92"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://92"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover93(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card93(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 93
	local h = Hover93(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(93, 93)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok93"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://93"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover94(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card94(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 94
	local h = Hover94(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(94, 94)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok94"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://94"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover95(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card95(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 95
	local h = Hover95(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(95, 95)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok95"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://95"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover96(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card96(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 96
	local h = Hover96(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(96, 96)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok96"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://96"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover97(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card97(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 97
	local h = Hover97(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(97, 97)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok97"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://97"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover98(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card98(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 98
	local h = Hover98(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(98, 98)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok98"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://98"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover99(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card99(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 99
	local h = Hover99(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(99, 99)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok99"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://99"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover100(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card100(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 100
	local h = Hover100(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(100, 100)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok100"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://100"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover101(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card101(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 101
	local h = Hover101(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(101, 101)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok101"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://101"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover102(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card102(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 102
	local h = Hover102(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(102, 102)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok102"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://102"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover103(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card103(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 103
	local h = Hover103(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(103, 103)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok103"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://103"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover104(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card104(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 104
	local h = Hover104(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(104, 104)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok104"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://104"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover105(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card105(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 105
	local h = Hover105(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(105, 105)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok105"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://105"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover106(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card106(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 106
	local h = Hover106(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(106, 106)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok106"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://106"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover107(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card107(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 107
	local h = Hover107(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(107, 107)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok107"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://107"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover108(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card108(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 108
	local h = Hover108(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(108, 108)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok108"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://108"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover109(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card109(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 109
	local h = Hover109(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(109, 109)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok109"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://109"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover110(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card110(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 110
	local h = Hover110(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(110, 110)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok110"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://110"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover111(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card111(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 111
	local h = Hover111(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(111, 111)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok111"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://111"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover112(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card112(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 112
	local h = Hover112(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(112, 112)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok112"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://112"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover113(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card113(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 113
	local h = Hover113(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(113, 113)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok113"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://113"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover114(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card114(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 114
	local h = Hover114(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(114, 114)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok114"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://114"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover115(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card115(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 115
	local h = Hover115(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(115, 115)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok115"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://115"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover116(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card116(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 116
	local h = Hover116(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(116, 116)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok116"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://116"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover117(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card117(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 117
	local h = Hover117(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(117, 117)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok117"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://117"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover118(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card118(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 118
	local h = Hover118(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(118, 118)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok118"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://118"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover119(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card119(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 119
	local h = Hover119(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(119, 119)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok119"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://119"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover120(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card120(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 120
	local h = Hover120(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(120, 120)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok120"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://120"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover121(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card121(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 121
	local h = Hover121(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(121, 121)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok121"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://121"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover122(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card122(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 122
	local h = Hover122(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(122, 122)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok122"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://122"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover123(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card123(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 123
	local h = Hover123(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(123, 123)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok123"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://123"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover124(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card124(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 124
	local h = Hover124(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(124, 124)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok124"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://124"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover125(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card125(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 125
	local h = Hover125(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(125, 125)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok125"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://125"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover126(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card126(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 126
	local h = Hover126(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(126, 126)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok126"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://126"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover127(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card127(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 127
	local h = Hover127(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(127, 127)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok127"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://127"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover128(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card128(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 128
	local h = Hover128(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(128, 128)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok128"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://128"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover129(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card129(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 129
	local h = Hover129(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(129, 129)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok129"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://129"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover130(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card130(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 130
	local h = Hover130(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(130, 130)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok130"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://130"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover131(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card131(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 131
	local h = Hover131(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(131, 131)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok131"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://131"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover132(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card132(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 132
	local h = Hover132(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(132, 132)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok132"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://132"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover133(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card133(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 133
	local h = Hover133(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(133, 133)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok133"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://133"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover134(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card134(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 134
	local h = Hover134(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(134, 134)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok134"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://134"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover135(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card135(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 135
	local h = Hover135(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(135, 135)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok135"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://135"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover136(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card136(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 136
	local h = Hover136(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(136, 136)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok136"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://136"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover137(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card137(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 137
	local h = Hover137(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(137, 137)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok137"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://137"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover138(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card138(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 138
	local h = Hover138(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(138, 138)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok138"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://138"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover139(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card139(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 139
	local h = Hover139(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(139, 139)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok139"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://139"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover140(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card140(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 140
	local h = Hover140(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(140, 140)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok140"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://140"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover141(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card141(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 141
	local h = Hover141(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(141, 141)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok141"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://141"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover142(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card142(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 142
	local h = Hover142(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(142, 142)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok142"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://142"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover143(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card143(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 143
	local h = Hover143(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(143, 143)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok143"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://143"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover144(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card144(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 144
	local h = Hover144(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(144, 144)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok144"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://144"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover145(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card145(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 145
	local h = Hover145(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(145, 145)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok145"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://145"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover146(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card146(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 146
	local h = Hover146(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(146, 146)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok146"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://146"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover147(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card147(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 147
	local h = Hover147(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(147, 147)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok147"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://147"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover148(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card148(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 148
	local h = Hover148(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(148, 148)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok148"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://148"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover149(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card149(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 149
	local h = Hover149(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(149, 149)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok149"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://149"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover150(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card150(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 150
	local h = Hover150(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(150, 150)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok150"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://150"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover151(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card151(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 151
	local h = Hover151(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(151, 151)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok151"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://151"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover152(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card152(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 152
	local h = Hover152(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(152, 152)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok152"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://152"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover153(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card153(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 153
	local h = Hover153(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(153, 153)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok153"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://153"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover154(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card154(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 154
	local h = Hover154(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(154, 154)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok154"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://154"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover155(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card155(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 155
	local h = Hover155(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(155, 155)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok155"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://155"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover156(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card156(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 156
	local h = Hover156(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(156, 156)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok156"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://156"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover157(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card157(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 157
	local h = Hover157(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(157, 157)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok157"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://157"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover158(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card158(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 158
	local h = Hover158(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(158, 158)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok158"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://158"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover159(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card159(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 159
	local h = Hover159(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(159, 159)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok159"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://159"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover160(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card160(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 160
	local h = Hover160(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(160, 160)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok160"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://160"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover161(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card161(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 161
	local h = Hover161(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(161, 161)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok161"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://161"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover162(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card162(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 162
	local h = Hover162(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(162, 162)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok162"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://162"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover163(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card163(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 163
	local h = Hover163(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(163, 163)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok163"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://163"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover164(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card164(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 164
	local h = Hover164(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(164, 164)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok164"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://164"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover165(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card165(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 165
	local h = Hover165(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(165, 165)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok165"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://165"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover166(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card166(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 166
	local h = Hover166(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(166, 166)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok166"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://166"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover167(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card167(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 167
	local h = Hover167(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(167, 167)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok167"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://167"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover168(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card168(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 168
	local h = Hover168(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(168, 168)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok168"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://168"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover169(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card169(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 169
	local h = Hover169(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(169, 169)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok169"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://169"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover170(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card170(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 170
	local h = Hover170(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(170, 170)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok170"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://170"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover171(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card171(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 171
	local h = Hover171(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(171, 171)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok171"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://171"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover172(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card172(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 172
	local h = Hover172(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(172, 172)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok172"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://172"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover173(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card173(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 173
	local h = Hover173(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(173, 173)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok173"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://173"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover174(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card174(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 174
	local h = Hover174(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(174, 174)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok174"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://174"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover175(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card175(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 175
	local h = Hover175(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(175, 175)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok175"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://175"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover176(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card176(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 176
	local h = Hover176(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(176, 176)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok176"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://176"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover177(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card177(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 177
	local h = Hover177(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(177, 177)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok177"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://177"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover178(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card178(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 178
	local h = Hover178(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(178, 178)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok178"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://178"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover179(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card179(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 179
	local h = Hover179(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(179, 179)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok179"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://179"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover180(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card180(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 180
	local h = Hover180(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(180, 180)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok180"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://180"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover181(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card181(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 181
	local h = Hover181(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(181, 181)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok181"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://181"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover182(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card182(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 182
	local h = Hover182(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(182, 182)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok182"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://182"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover183(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card183(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 183
	local h = Hover183(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(183, 183)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok183"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://183"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover184(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card184(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 184
	local h = Hover184(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(184, 184)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok184"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://184"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover185(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card185(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 185
	local h = Hover185(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(185, 185)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok185"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://185"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover186(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card186(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 186
	local h = Hover186(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(186, 186)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok186"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://186"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover187(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card187(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 187
	local h = Hover187(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(187, 187)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok187"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://187"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover188(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card188(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 188
	local h = Hover188(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(188, 188)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok188"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://188"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover189(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card189(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 189
	local h = Hover189(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(189, 189)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok189"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://189"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover190(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card190(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 190
	local h = Hover190(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(190, 190)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok190"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://190"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover191(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card191(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 191
	local h = Hover191(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(191, 191)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok191"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://191"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover192(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card192(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 192
	local h = Hover192(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(192, 192)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok192"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://192"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover193(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card193(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 193
	local h = Hover193(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(193, 193)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok193"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://193"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover194(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card194(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 194
	local h = Hover194(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(194, 194)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok194"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://194"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover195(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card195(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 195
	local h = Hover195(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(195, 195)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok195"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://195"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover196(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card196(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 196
	local h = Hover196(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(196, 196)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok196"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://196"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover197(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card197(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 197
	local h = Hover197(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(197, 197)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok197"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://197"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover198(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card198(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 198
	local h = Hover198(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(198, 198)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok198"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://198"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover199(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card199(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 199
	local h = Hover199(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(199, 199)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok199"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://199"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover200(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card200(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 200
	local h = Hover200(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(200, 200)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok200"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://200"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover201(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card201(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 201
	local h = Hover201(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(201, 201)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok201"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://201"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover202(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card202(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 202
	local h = Hover202(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(202, 202)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok202"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://202"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover203(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card203(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 203
	local h = Hover203(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(203, 203)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok203"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://203"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover204(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card204(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 204
	local h = Hover204(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(204, 204)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok204"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://204"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover205(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card205(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 205
	local h = Hover205(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(205, 205)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok205"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://205"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover206(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card206(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 206
	local h = Hover206(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(206, 206)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok206"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://206"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover207(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card207(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 207
	local h = Hover207(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(207, 207)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok207"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://207"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover208(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card208(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 208
	local h = Hover208(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(208, 208)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok208"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://208"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover209(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card209(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 209
	local h = Hover209(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(209, 209)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok209"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://209"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover210(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card210(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 210
	local h = Hover210(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(210, 210)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok210"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://210"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover211(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card211(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 211
	local h = Hover211(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(211, 211)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok211"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://211"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover212(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card212(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 212
	local h = Hover212(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(212, 212)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok212"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://212"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover213(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card213(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 213
	local h = Hover213(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(213, 213)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok213"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://213"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover214(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card214(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 214
	local h = Hover214(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(214, 214)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok214"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://214"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover215(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card215(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 215
	local h = Hover215(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(215, 215)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok215"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://215"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover216(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card216(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 216
	local h = Hover216(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(216, 216)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok216"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://216"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover217(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card217(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 217
	local h = Hover217(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(217, 217)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok217"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://217"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover218(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card218(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 218
	local h = Hover218(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(218, 218)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok218"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://218"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover219(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card219(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 219
	local h = Hover219(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(219, 219)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok219"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://219"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover220(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card220(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 220
	local h = Hover220(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(220, 220)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok220"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://220"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover221(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card221(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 221
	local h = Hover221(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(221, 221)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok221"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://221"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover222(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card222(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 222
	local h = Hover222(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(222, 222)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok222"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://222"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover223(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card223(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 223
	local h = Hover223(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(223, 223)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok223"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://223"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover224(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card224(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 224
	local h = Hover224(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(224, 224)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok224"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://224"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover225(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card225(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 225
	local h = Hover225(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(225, 225)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok225"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://225"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover226(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card226(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 226
	local h = Hover226(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(226, 226)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok226"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://226"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover227(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card227(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 227
	local h = Hover227(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(227, 227)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok227"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://227"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover228(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card228(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 228
	local h = Hover228(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(228, 228)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok228"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://228"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover229(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card229(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 229
	local h = Hover229(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(229, 229)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok229"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://229"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover230(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card230(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 230
	local h = Hover230(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(230, 230)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok230"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://230"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover231(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card231(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 231
	local h = Hover231(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(231, 231)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok231"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://231"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover232(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card232(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 232
	local h = Hover232(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(232, 232)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok232"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://232"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover233(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card233(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 233
	local h = Hover233(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(233, 233)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok233"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://233"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover234(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card234(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 234
	local h = Hover234(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(234, 234)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok234"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://234"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover235(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card235(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 235
	local h = Hover235(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(235, 235)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok235"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://235"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover236(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card236(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 236
	local h = Hover236(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(236, 236)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok236"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://236"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover237(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card237(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 237
	local h = Hover237(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(237, 237)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok237"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://237"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover238(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card238(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 238
	local h = Hover238(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(238, 238)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok238"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://238"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover239(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card239(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 239
	local h = Hover239(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(239, 239)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok239"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://239"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover240(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card240(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 240
	local h = Hover240(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(240, 240)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok240"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://240"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover241(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card241(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 241
	local h = Hover241(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(241, 241)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok241"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://241"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover242(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card242(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 242
	local h = Hover242(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(242, 242)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok242"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://242"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover243(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card243(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 243
	local h = Hover243(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(243, 243)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok243"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://243"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover244(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card244(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 244
	local h = Hover244(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(244, 244)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok244"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://244"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover245(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card245(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 245
	local h = Hover245(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(245, 245)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok245"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://245"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover246(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card246(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 246
	local h = Hover246(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(246, 246)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok246"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://246"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover247(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card247(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 247
	local h = Hover247(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(247, 247)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok247"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://247"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover248(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card248(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 248
	local h = Hover248(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(248, 248)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok248"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://248"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover249(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card249(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 249
	local h = Hover249(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(249, 249)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok249"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://249"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover250(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card250(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 250
	local h = Hover250(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(250, 250)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok250"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://250"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover251(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card251(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 251
	local h = Hover251(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(251, 251)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok251"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://251"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover252(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card252(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 252
	local h = Hover252(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(252, 252)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok252"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://252"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover253(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card253(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 253
	local h = Hover253(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(253, 253)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok253"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://253"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover254(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card254(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 254
	local h = Hover254(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(254, 254)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok254"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://254"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover255(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card255(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 255
	local h = Hover255(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(255, 255)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok255"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://255"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover256(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card256(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 256
	local h = Hover256(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(256, 256)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok256"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://256"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover257(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card257(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 257
	local h = Hover257(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(257, 257)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok257"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://257"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover258(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card258(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 258
	local h = Hover258(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(258, 258)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok258"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://258"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover259(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card259(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 259
	local h = Hover259(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(259, 259)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok259"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://259"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover260(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card260(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 260
	local h = Hover260(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(260, 260)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok260"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://260"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover261(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card261(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 261
	local h = Hover261(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(261, 261)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok261"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://261"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover262(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card262(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 262
	local h = Hover262(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(262, 262)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok262"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://262"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover263(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card263(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 263
	local h = Hover263(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(263, 263)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok263"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://263"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover264(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card264(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 264
	local h = Hover264(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(264, 264)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok264"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://264"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover265(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card265(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 265
	local h = Hover265(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(265, 265)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok265"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://265"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover266(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card266(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 266
	local h = Hover266(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(266, 266)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok266"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://266"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover267(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card267(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 267
	local h = Hover267(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(267, 267)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok267"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://267"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover268(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card268(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 268
	local h = Hover268(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(268, 268)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok268"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://268"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover269(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card269(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 269
	local h = Hover269(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(269, 269)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok269"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://269"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover270(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card270(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 270
	local h = Hover270(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(270, 270)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok270"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://270"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover271(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card271(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 271
	local h = Hover271(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(271, 271)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok271"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://271"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover272(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card272(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 272
	local h = Hover272(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(272, 272)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok272"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://272"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover273(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card273(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 273
	local h = Hover273(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(273, 273)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok273"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://273"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover274(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card274(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 274
	local h = Hover274(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(274, 274)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok274"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://274"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover275(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card275(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 275
	local h = Hover275(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(275, 275)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok275"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://275"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover276(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card276(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 276
	local h = Hover276(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(276, 276)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok276"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://276"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover277(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card277(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 277
	local h = Hover277(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(277, 277)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok277"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://277"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover278(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card278(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 278
	local h = Hover278(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(278, 278)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok278"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://278"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover279(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card279(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 279
	local h = Hover279(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(279, 279)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok279"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://279"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover280(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card280(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 280
	local h = Hover280(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(280, 280)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok280"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://280"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover281(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card281(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 281
	local h = Hover281(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(281, 281)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok281"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://281"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover282(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card282(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 282
	local h = Hover282(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(282, 282)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok282"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://282"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover283(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card283(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 283
	local h = Hover283(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(283, 283)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok283"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://283"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover284(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card284(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 284
	local h = Hover284(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(284, 284)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok284"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://284"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover285(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card285(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 285
	local h = Hover285(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(285, 285)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok285"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://285"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover286(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card286(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 286
	local h = Hover286(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(286, 286)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok286"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://286"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover287(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card287(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 287
	local h = Hover287(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(287, 287)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok287"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://287"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover288(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card288(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 288
	local h = Hover288(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(288, 288)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok288"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://288"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover289(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card289(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 289
	local h = Hover289(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(289, 289)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok289"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://289"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover290(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card290(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 290
	local h = Hover290(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(290, 290)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok290"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://290"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover291(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card291(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 291
	local h = Hover291(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(291, 291)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 13; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok291"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://291"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover292(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card292(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 292
	local h = Hover292(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(292, 292)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 14; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok292"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://292"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover293(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card293(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 293
	local h = Hover293(function() end); h.Parent = f
	f.ZIndex = 7
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(293, 293)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 15; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok293"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://293"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover294(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card294(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 294
	local h = Hover294(function() end); h.Parent = f
	f.ZIndex = 1
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(294, 294)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 16; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok294"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://294"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover295(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card295(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 295
	local h = Hover295(function() end); h.Parent = f
	f.ZIndex = 2
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(295, 295)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 17; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok295"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://295"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover296(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card296(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 296
	local h = Hover296(function() end); h.Parent = f
	f.ZIndex = 3
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(296, 296)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 18; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok296"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://296"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover297(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card297(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 297
	local h = Hover297(function() end); h.Parent = f
	f.ZIndex = 4
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(297, 297)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 10; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok297"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://297"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover298(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card298(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 298
	local h = Hover298(function() end); h.Parent = f
	f.ZIndex = 5
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(298, 298)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 11; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok298"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://298"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local function Hover299(onEnter: () -> ()): Frame
	local g = Instance.new("Frame"); g.BackgroundTransparency = 0.5; g.MouseEnter:Connect(function(x, y) local _n: number = x + y; onEnter() end)
	return g
end
local function Card299(title: string, canvas: any)
	local f = Instance.new("Frame"); f.Visible = true; f.LayoutOrder = 299
	local h = Hover299(function() end); h.Parent = f
	f.ZIndex = 6
	f.BackgroundTransparency = 0.1; f.Size = UDim2.fromOffset(299, 299)
	do
		f.MouseLeave:Connect(function(x, y) local _n: number = x end)
		f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() local _w: number = f.AbsoluteSize.X end)
		local t = Instance.new("TextLabel"); t.Text = title; t.TextSize = 12; t.TextWrapped = true; t.Parent = f
		local b = Instance.new("TextButton"); b.Text = "ok299"; b.AutoButtonColor = false; b.Activated:Connect(function(input, count) local _c: number = count end); b.Parent = f
		local im = Instance.new("ImageLabel"); im.Image = "rbxassetid://299"; im.ImageTransparency = 0.2; im.Parent = f
		local s = Instance.new("ScrollingFrame"); s:GetPropertyChangedSignal("CanvasSize"):Connect(function() canvas:Set(s.CanvasSize) end); local u = Instance.new("UIListLayout"); u.Padding = UDim.new(0, 4); u.Parent = s; s.Parent = f
	end
	return f
end

local _neg1 = Instance.new("Frame"); _neg1.Visible = 5 -- NEG
