--!strict
--[[
	StoryParts — the pieces every story file used to repeat (one copy). Not a `.story`, so UI Labs ignores it.

	  themed(scheme)   the story's own Theme (never `Theme.default`) plus an Effect that mirrors the `Scheme` control
	                   Source into it, so a scheme switch cross-fades every bound role. Nothing global is touched.
	  page             full-size surface-coloured page with a vertical stack; `follow` rides in its array part
	  scrollPage       the same page in a vertical ScrollingFrame, for a story taller than the UI Labs view (the
	                   gallery's "Scroller" shape: AutomaticCanvasSize Y over an AutomaticSize Y "Page" that holds the
	                   padding and the stack); `gap` is the stack spacing, default 16
	  row              a wrapping horizontal row (AutomaticSize Y)
	  holder           a fixed-height box for something StoryKit.rebuild fills
	  caption / show   a small label, and a State<T> -> State<string> formatter for live readouts
]]
local Material = require("../src")
local q = require("./Quad")
local D = q.Declaration

local ICON = "rbxassetid://6031094678" -- placeholder image asset (the kit ships none)
local captionStyle = Material.Text.Label("BodyMedium")

local StoryParts = {}

StoryParts.ICON = ICON

function StoryParts.themed(scheme: q.Source<any>): (Material.Theme, q.Effect)
	local theme = Material.Theme.new({ Scheme = scheme:Get() })
	local follow = q.Effect(function()
		theme.Scheme:SetIfChanged(scheme:Get())
	end, scheme)
	return theme, follow
end

function StoryParts.page(theme: Material.Theme, follow: q.Effect, children: { Instance }): Frame
	return D.Frame {
		Name = "Story",
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = theme.Color.Surface,
		D.UIPadding {
			PaddingTop = UDim.new(0, 24),
			PaddingBottom = UDim.new(0, 24),
			PaddingLeft = UDim.new(0, 24),
			PaddingRight = UDim.new(0, 24),
		},
		D.UIListLayout {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 16),
		},
		follow,
		table.unpack(children),
	}
end

function StoryParts.scrollPage(theme: Material.Theme, follow: q.Effect, children: { Instance }, gap: number?): ScrollingFrame
	return D.ScrollingFrame {
		Name = "Story",
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = theme.Color.Surface,
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = theme.Color.OnSurface,
		ScrollBarImageTransparency = 1 - Material.Tokens.State.Opacity.ScrollBar,
		follow,
		D.Frame {
			Name = "Page",
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.UIPadding {
				PaddingTop = UDim.new(0, 24),
				PaddingBottom = UDim.new(0, 24),
				PaddingLeft = UDim.new(0, 24),
				PaddingRight = UDim.new(0, 24),
			},
			D.UIListLayout {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, gap or 16),
			},
			table.unpack(children),
		},
	}
end

function StoryParts.row(children: { Instance }): Frame
	return D.Frame {
		Name = "Row",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		D.UIListLayout {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Wraps = true,
			Padding = UDim.new(0, 16),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		},
		table.unpack(children),
	}
end

function StoryParts.holder(height: number, child: Instance): Frame
	return D.Frame {
		Name = "Holder",
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		child,
	}
end

function StoryParts.caption(theme: Material.Theme, text: string | q.State<string>): TextLabel
	return D.TextLabel {
		Name = "Caption",
		captionStyle,
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		TextColor3 = theme.Color.OnSurfaceVariant,
		Text = text,
	}
end

function StoryParts.show<T>(source: q.State<T>, prefix: string, fmt: (T) -> string): q.State<string>
	local out: q.State<string> = source:Compute(function(self)
		return prefix .. fmt(self:Get())
	end)
	return out
end

function StoryParts.tostr(v: any): string
	return tostring(v)
end

return StoryParts
