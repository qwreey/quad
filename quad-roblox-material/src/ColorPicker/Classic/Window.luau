--!strict
--[[
	Window chrome: the title bar (title + red close button) and the window drop shadow.

	Title bar geometry is the original's: an 8 px transparent row with 4 px bottom padding (so its content box is
	4 px tall and the 14 px text simply overflows it, centered), the close dot 14 px at x = -4. The close button
	showed its "x" on hover in the original but the icon's ImageTransparency was stuck at 1 (the hover toggled
	`Visible` on an invisible image) — here hover really reveals the "x".
	Shadow: the original stacked 8 nine-slice images (left/right/top/bottom + 4 corners, 40/40/30/50 px thick);
	here ONE `UIShadow` child (drawn behind the window, follows its UICorner). Visual equivalence is approximate
	(a soft Gaussian rather than the baked image) and was not compared in Studio.
]]

local q = require("../../Quad")
local Interaction = require("../../Interaction")
local Themes = require("./Themes")
local D = q.Declaration

local IMG_CLOSE_X = "rbxassetid://2751883273"

export type TitleProps = {
	read Theme: Themes.Theme,
	read Title: string,
	read OnClose: () -> (),
	read LayoutOrder: number?,
}

local function TitleBar(props: TitleProps)
	local theme = props.Theme
	local ix = Interaction.new()
	return D.Frame {
		Name = "TitleBar",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, theme.TitleFrameSizeY),
		LayoutOrder = props.LayoutOrder or 0,
		D.UIPadding { PaddingBottom = UDim.new(0, theme.TitleFramePaddingBottom) },

		D.TextLabel {
			Name = "TitleText",
			Font = Enum.Font.GothamBold,
			Text = props.Title,
			TextColor3 = theme.TitleTextColor,
			TextSize = 14,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		},
		D.TextButton {
			Name = "CloseButton",
			ix.Hook,
			AutoButtonColor = false,
			Text = "",
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = theme.CloseButtonBackgroundColor,
			BorderSizePixel = 0,
			Position = UDim2.new(0, -4, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			Activated = function(_input: InputObject, _clicks: number)
			props.OnClose()
		end,
			UICorner = UDim.new(0.5, 0),

			D.ImageLabel {
				Name = "CloseIcon",
				Image = IMG_CLOSE_X,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -2, 1, -2),
				Visible = ix.Hovered,
			},
		},
	}
end

local function WindowShadow()
	return D.UIShadow {
		Name = "WindowShadow",
		BlurRadius = UDim.new(0, 24),
		Offset = UDim2.fromOffset(0, 8),
		Transparency = 0.55,
		Color = Color3.new(0, 0, 0),
		ShowBehindParent = true,
	}
end

return {
	TitleBar = TitleBar,
	WindowShadow = WindowShadow,
}
