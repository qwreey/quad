--!strict
--[[
	Window title bar (internal part of the window decoration, Window/Decoration.luau): collapse arrow, title, close
	button. One Frame + three children (ImageButton / TextLabel / ImageButton). Drag and focus are wired by the caller
	(`Drag` handle).
]]

local Quad = require("../Quad")
local q = Quad
local Frame = q.Elem "Frame"
local ImageButton = q.Elem "ImageButton"
local ImageLabel = q.Elem "ImageLabel"
local TextLabel = q.Elem "TextLabel"
local UIPadding = q.Elem "UIPadding"
local Common = require("../Common")
local Interaction = require("../Interaction")
local Style = require("../Style")
local Util = require("../Util")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

export type TitleBarSpec = {
	Style: Style,
	Title: string | State<string>,
	Collapsed: Source<boolean>,
	Open: Source<boolean>,
	Focused: State<boolean>,
	NoCollapse: boolean,
	NoClose: boolean,
	OnCloseRequest: (() -> ())?,
	Drag: Interaction.DragHandle?,
}

local TitleBar = {}

-- transparent until hovered/pressed, then the Header look
local function titleButton(style: Style, icon: string | State<string>, onClick: () -> (), side: "Left" | "Right", size: State<number>, shown: State<boolean>)
	local hover = Interaction.hover()
	local look = Common.headerLook(style, hover, nil, false)
	local box: State<UDim2> = size:Compute(function(self)
		return UDim2.fromOffset(self:Get(), self:Get())
	end)
	local iconSize: State<UDim2> = size:Compute(function(self)
		local s = math.floor(0.7 * self:Get())
		return UDim2.fromOffset(s, s)
	end)
	return ImageButton({
		hover.Hook,
		-- closing or collapsing the window hides an ANCESTOR of the button (the decoration frame): no MouseLeave comes,
		-- so drop the hover look explicitly
		q.Effect(function()
			if not shown:Get() then
				hover.Reset()
			end
		end, shown),
		Name = if side == "Left" then "CollapseButton" else "CloseButton",
		AnchorPoint = Vector2.new(if side == "Left" then 0 else 1, 0.5),
		Position = UDim2.new(if side == "Left" then 0 else 1, 0, 0.5, 0),
		Size = box,
		BackgroundColor3 = look.Color,
		BackgroundTransparency = look.Transparency,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Image = "",
		Activated = function()
			onClick()
		end,
		UICorner = 100,
		ImageLabel({
			Name = "Icon",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = iconSize,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = icon,
			ImageColor3 = style.Color.Text,
			ImageTransparency = style.Transparency.Text,
		}),
	})
end

function TitleBar.new(spec: TitleBarSpec): Frame
	local style = spec.Style
	local icons = style.Icons
	local collapsed = spec.Collapsed

	local height = style.FrameHeight
	local buttonSize: State<number> = style.Metrics.TextSize:Compute(function(self, _prev, padding)
		return self:Get() + (padding:Get().Y - 1) * 2
	end, style.Metrics.FramePadding)
	local sidePad: State<UDim> = Util.pxX(style.Metrics.FramePadding)

	-- background: focused > idle (colour and transparency). The bar is never seen collapsed — a collapsed window is
	-- an icon (Window/Decoration.luau), so there is no collapsed colour and no right-pointing arrow here.
	local bg: State<Color3> = spec.Focused:Compute(function(self, _prev, n, a)
		return if self:Get() then a:Get() else n:Get()
	end, style.Color.TitleBg, style.Color.TitleBgActive)
	local bgAlpha: State<number> = spec.Focused:Compute(function(self, _prev, n, a)
		return if self:Get() then a:Get() else n:Get()
	end, style.Transparency.TitleBg, style.Transparency.TitleBgActive)

	local arrow = icons.DownTriangle
	local closeIcon = icons.Close
	-- the bar is on screen (its frame is hidden while closed or collapsed — a collapsed window is an icon)
	local shown: State<boolean> = spec.Open:Compute(function(self, _prev, isCollapsed)
		return self:Get() and not isCollapsed:Get()
	end, collapsed)

	local align: State<Enum.TextXAlignment> = style.Metrics.WindowTitleAlign:Compute(function(self)
		local a = self:Get()
		if a == Enum.LeftRight.Center then
			return Enum.TextXAlignment.Center
		elseif a == Enum.LeftRight.Right then
			return Enum.TextXAlignment.Right
		end
		return Enum.TextXAlignment.Left
	end)

	-- the title sits between the buttons (padding = button + gap on each side that has a button)
	local leftPad: State<UDim> = buttonSize:Compute(function(self)
		return UDim.new(0, if spec.NoCollapse then 0 else self:Get() + 4)
	end)
	local rightPad: State<UDim> = buttonSize:Compute(function(self)
		return UDim.new(0, if spec.NoClose then 0 else self:Get() + 4)
	end)
	local barSize: State<UDim2> = height:Compute(function(self)
		return UDim2.new(1, 0, 0, self:Get())
	end)

	return Frame({
		if spec.Drag then spec.Drag.Hook else q.None,
		Name = "TitleBar",
		Size = barSize,
		BackgroundColor3 = bg,
		BackgroundTransparency = bgAlpha,
		BorderSizePixel = 0,
		Active = true,
		UIPadding({ PaddingLeft = sidePad, PaddingRight = sidePad }),
		if spec.NoCollapse
			then q.None
			else titleButton(style, arrow, function()
				collapsed:Set(not collapsed:Get())
			end, "Left", buttonSize, shown),
		TextLabel({
			Name = "Title",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = spec.Title,
			FontFace = style.Metrics.TextFont,
			TextSize = style.Metrics.TextSize,
			TextColor3 = style.Color.Text,
			TextTransparency = style.Transparency.Text,
			TextXAlignment = align,
			TextTruncate = Enum.TextTruncate.AtEnd,
			UIPadding({ PaddingLeft = leftPad, PaddingRight = rightPad }),
		}),
		if spec.NoClose
			then q.None
			else titleButton(style, closeIcon, function()
				-- a close REQUEST when the app asked for one (it may ask to save first), else the close itself
				local request = spec.OnCloseRequest
				if request ~= nil then
					request()
				else
					spec.Open:Set(false)
				end
			end, "Right", buttonSize, shown),
	})
end

return TitleBar
