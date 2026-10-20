--!strict
--[[
	M3 badge — Compose material3 `Badge` and the placement of `BadgedBox` (androidx/androidx@40ff481 compose/material3/
	material3/src/commonMain/kotlin/androidx/compose/material3/Badge.kt 63-238; tokens/BadgeTokens.kt).

	    Material.Badge()                       -- the small dot (no content)
	    Material.Badge({ Text = "8" })         -- the large badge with a label
	Props (all optional, `read`): Text (string | State<string>)? — nil = small badge; Theme, Modifier (Frame), Hooks.
	  Small: 6 x 6 (BadgeTokens.Size), error, corner full.
	  Large: 16 high (LargeSize), at least 16 wide (`defaultMinSize`), the label (LabelSmall, onError) padded 4 on each side
	  (BadgeWithContentHorizontalPadding), error container, corner full. The host grows with the text (AutomaticSize X; the
	  label carries a minimum width of 8 so a one-digit badge stays a 16 x 16 circle).
	Instances: small 2 (Frame + UICorner); large 5 (Frame + UICorner + UIPadding + the TextLabel "Text" + UISizeConstraint).

	Badge.position(hasText) -> UDim2 — BadgedBox placement (Badge.kt 104-127): the badge's Position inside a 24 x 24 ICON box
	(the anchor). Small: its start edge 6 from the anchor's end (BadgeOffset), its top at 6 - 6 = 0 (a 6 px vertical
	overlap); large: its start edge 12 from the anchor's end (BadgeWithContentHorizontalOffset), its top 14 - 16 = -2 above the
	anchor's top (BadgeWithContentVerticalOffset). The badge rulers of the navigation items (BadgeEndRuler / BadgeTopRuler,
	which keep a long badge inside the indicator) are not reproduced.
	Not here: `BadgedBox` as a public layout (the kit's navigation items place their badge themselves).
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Text = require("./Text")
local Frame = q.Elem "Frame"
local TextLabel = q.Elem "TextLabel"
local UIPadding = q.Elem "UIPadding"
local UISizeConstraint = q.Elem "UISizeConstraint"
local FrameModifier = q.Modifier "Frame"
local badgeName = FrameModifier():Name("Badge")

export type Props = {
	read Text: (string | q.State<string>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.ModifierInto<Frame>?,
	read Hooks: Util.Hooks?,
}

local SMALL = 6 -- BadgeTokens.Size
local LARGE = 16 -- BadgeTokens.LargeSize
local PADDING = 4 -- BadgeWithContentHorizontalPadding
local SMALL_OFFSET = 6 -- BadgeOffset
local LARGE_X = 12 -- BadgeWithContentHorizontalOffset
local LARGE_Y = 14 -- BadgeWithContentVerticalOffset
local ANCHOR = 24 -- the navigation icon size

local labelStyle = Text.Label("LabelSmall")
local smallBase = FrameModifier():Size(UDim2.fromOffset(SMALL, SMALL))
local largeBase = FrameModifier():Size(UDim2.fromOffset(0, LARGE)):AutomaticSize(Enum.AutomaticSize.X)

local function Badge(props: Props?): Frame
	local p: Props = props or {}
	local theme = Theme.resolve(p.Theme)
	local corner = Tokens.Shape.corner("Full")
	if p.Text == nil then
		return Frame {
			badgeName,
			smallBase,
			BackgroundColor3 = theme.Color.Error,
			BorderSizePixel = 0,
			p.Modifier or q.None,
			UICorner = corner,
			table.unpack(Util.hooks(p.Hooks)),
		}
	end
	return Frame {
		badgeName,
		largeBase,
		BackgroundColor3 = theme.Color.Error,
		BorderSizePixel = 0,
		p.Modifier or q.None,
		UICorner = corner,
		UIPadding { PaddingLeft = UDim.new(0, PADDING), PaddingRight = UDim.new(0, PADDING) },
		TextLabel {
			Name = "Text",
			labelStyle,
			Size = UDim2.fromOffset(0, LARGE),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = p.Text,
			TextColor3 = theme.Color.OnError,
			TextXAlignment = Enum.TextXAlignment.Center,
			UISizeConstraint { MinSize = Vector2.new(LARGE - 2 * PADDING, 0) },
		},
		table.unpack(Util.hooks(p.Hooks)),
	}
end

-- the badge's Position inside a 24 x 24 anchor box (BadgedBox)
local function position(hasText: boolean): UDim2
	if hasText then
		return UDim2.fromOffset(ANCHOR - LARGE_X, -LARGE + LARGE_Y)
	end
	return UDim2.fromOffset(ANCHOR - SMALL_OFFSET, -SMALL + SMALL_OFFSET)
end

return {
	Badge = Badge,
	position = position,
}
