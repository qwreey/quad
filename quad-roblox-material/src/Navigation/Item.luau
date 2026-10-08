--!strict
--[[
	Pieces the navigation bar and the navigation rail items share (internal; the drawer item has its own row).

	  Item.icon(dest, color, theme, at) -> Instance
	      the destination's 24 px icon (IconView — an `Icons` name, an asset URL or a glyph) and, when the destination has a
	      `Badge`, the badge on it: Compose puts the badge on the icon through `BadgedBox` (the navigation samples:
	      `BadgedBox(badge = { Badge { Text("8") } }) { Icon(...) }`). With a badge the icon sits in a 24 x 24 "IconBox" (the
	      BadgedBox anchor) that also holds the badge at `Badge.position`; without one the IconView itself is returned (one
	      instance). `at` places the returned instance (Name, AnchorPoint, Position).
	      Badge text: `Badge = ""` draws the SMALL badge (a 6 px dot — Compose `Badge()` without content), any other string or
	      a State draws the LARGE badge with that text (`Badge { Text(...) }`). The drawer item reads the same field as its
	      trailing badge text (Compose NavigationDrawerItem `badge`).
	  Item.ICON = 24
	Item colors are NOT animated on selection: Compose's NavigationItem passes `animateColor = false` to the label and gives the
	icon its color directly (NavigationItem.kt 356-373) — the indicator pill is what animates.
]]

local q = require("../Quad")
local Theme = require("../Theme")
local IconView = require("../IconView")
local Badge = require("../Badge")
local Destination = require("./Destination")
local D = q.Declaration

local ICON = 24

export type Placement = {
	Name: string?,
	AnchorPoint: Vector2?,
	Position: (UDim2 | q.State<UDim2>)?,
}

local function icon<K>(dest: Destination.Destination<K>, color: q.State<Color3>, theme: Theme.Theme, at: Placement): Instance
	local value = dest.Icon or ""
	local badge = dest.Badge
	if badge == nil then
		local view = IconView.new({
			Name = at.Name or "Icon",
			Icon = value,
			Size = ICON,
			Color = color,
			AnchorPoint = at.AnchorPoint,
			Position = at.Position,
		})
		return view
	end
	local hasText = badge ~= ""
	return D.Frame {
		Name = "IconBox",
		Size = UDim2.fromOffset(ICON, ICON),
		AnchorPoint = at.AnchorPoint,
		Position = at.Position,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		(IconView.new({ Name = at.Name or "Icon", Icon = value, Size = ICON, Color = color })),
		Badge.Badge({
			Text = if hasText then badge else nil,
			Theme = theme,
			Modifier = D.Modifier.Frame():Position(Badge.position(hasText)):ZIndex(2),
		}),
	}
end

return {
	icon = icon,
	ICON = ICON,
}
