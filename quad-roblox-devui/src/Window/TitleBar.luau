--!strict
--[[
	Window title bar (internal part of the window decoration, Window/Decoration.luau): collapse arrow, title, close
	button. One Frame + three children (ImageButton / TextLabel / ImageButton). Drag and focus are wired by the caller
	(`Drag` handle).

	TAB STRIP [2026-10-21 user decision — docking stage 3]: a tab group with two or more open windows shows a tab strip
	in the title bar's place. The strip IS the drawn window's title bar with its title and close button hidden
	(`Tabbed`): the same background colours by focus, the collapse arrow at the left (hidden by `CanCollapse` when a
	window of the group has NoCollapse), and its empty area drags the group. The tabs themselves are decoration parts of
	each window, laid over this row by Window/Decoration.luau ("TABS"). In a split every leaf shows its strip, even with
	one window.

	FOLDED [2026-10-21 user decision — docking stage 4]: a leaf of a split folded along a top / bottom split keeps just
	this row, its arrow pointing right (Dear ImGui's collapsed arrow); folded along a left | right split it is a bar the
	decoration draws instead, and this row hides (`Shown`).
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
local Overlay = require("../Overlay")
local Style = require("../Style")
local Tooltip = require("../Tooltip")
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
	Tabbed: State<boolean>, -- the tab strip replaces the title and the close button (header TAB STRIP)
	CanCollapse: State<boolean>, -- the group allows collapsing (the arrow's Visible)
	Shown: State<boolean>, -- the bar's Visible (a leaf folded to a bar hides it — header FOLDED)
	Folded: State<boolean>, -- the leaf is folded to this row: the arrow points right (header FOLDED)
}

local TitleBar = {}

-- transparent until hovered/pressed, then the Header look (also the close button of a tab, Window/Decoration.luau)
local function titleButton(
	style: Style,
	icon: string | State<string>,
	onClick: () -> (),
	side: "Left" | "Right",
	size: State<number>,
	shown: State<boolean>,
	visible: State<boolean>?,
	rotation: State<number>?
)
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
		Visible = visible or true,
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
			Rotation = rotation or 0,
			ImageColor3 = style.Color.Text,
			ImageTransparency = style.Transparency.Text,
		}),
	})
end

TitleBar.button = titleButton

-- the close button's rule (the title bar's and a tab's): a close REQUEST when the app asked for one (it may ask to
-- save first), else the close itself
function TitleBar.close(open: Source<boolean>, request: (() -> ())?)
	if request ~= nil then
		request()
	else
		open:Set(false)
	end
end

-- the round button's side for a title bar of this style (TextSize + the frame padding's vertical part, minus a pixel each)
-- [2026-10-21 user decision] the full title as a hover tooltip while the label cuts it off (Dear ImGui shows a clipped
-- tab's name the same way): the three array-part entries for a title TextLabel. `TextFits` is false exactly while the
-- truncated text does not fit the padded label (Studio-confirmed 2026-10-21, padding included). It shows on the default
-- Overlay only while that layer is mounted (re-read on every enter): a hint the app never asked for must not make the
-- overlay warn in a host that shows no popups (a UI Labs story)
function TitleBar.fullTitleTip(style: Style, title: string | State<string>): (any, any, any)
	local fits: Source<boolean> = q.Source(true)
	local mounted: Source<boolean> = q.Source(true)
	local tip = Tooltip.hook({
		Text = title,
		Style = style,
		Enabled = fits:Compute(function(self, _prev, isMounted)
			return not self:Get() and isMounted:Get()
		end, mounted),
	})
	local watch = q.PostRef(nil :: GuiObject?)
	watch:Callback(function(inst)
		if inst ~= nil then
			inst.MouseEnter:Connect(function()
				mounted:SetIfChanged(Overlay.getDefault().Layer.Parent ~= nil)
			end)
		end
	end)
	return q.Out "TextLabel" "TextFits" (fits), watch, tip.Hook
end

function TitleBar.buttonSize(style: Style): State<number>
	return style.Metrics.TextSize:Compute(function(self, _prev, padding)
		return self:Get() + (padding:Get().Y - 1) * 2
	end, style.Metrics.FramePadding)
end

function TitleBar.new(spec: TitleBarSpec): Frame
	local style = spec.Style
	local icons = style.Icons
	local collapsed = spec.Collapsed

	local height = style.FrameHeight
	local buttonSize: State<number> = TitleBar.buttonSize(style)
	local untabbed: State<boolean> = spec.Tabbed:Compute(function(self)
		return not self:Get()
	end)
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

	local fitsOut, mountWatch, titleTip = TitleBar.fullTitleTip(style, spec.Title)
	return Frame({
		if spec.Drag then spec.Drag.Hook else q.None,
		Name = "TitleBar",
		Size = barSize,
		BackgroundColor3 = bg,
		BackgroundTransparency = bgAlpha,
		BorderSizePixel = 0,
		Active = true,
		Visible = spec.Shown,
		UIPadding({ PaddingLeft = sidePad, PaddingRight = sidePad }),
		if spec.NoCollapse
			then q.None
			else titleButton(style, arrow, function()
				collapsed:Set(not collapsed:Get())
			end, "Left", buttonSize, shown, spec.CanCollapse, spec.Folded:Compute(function(self)
				return if self:Get() then -90 else 0
			end)),
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
			Visible = untabbed,
			fitsOut,
			mountWatch,
			titleTip,
			UIPadding({ PaddingLeft = leftPad, PaddingRight = rightPad }),
		}),
		if spec.NoClose
			then q.None
			else titleButton(style, closeIcon, function()
				TitleBar.close(spec.Open, spec.OnCloseRequest)
			end, "Right", buttonSize, shown, untabbed),
	})
end

return TitleBar
