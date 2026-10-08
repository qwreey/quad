--!strict
--[[
	IconView: draws ONE icon prop value (Button / SplitButton `Icon`, Slider `TrackIcon*`) as the instance it resolves to
	(`Icons.resolve` — see Icons.luau "ICON PROPS"): an `ImageLabel` for an image (a name with an image, an asset URL), a
	`TextLabel` glyph for the rest (a name whose image was overridden away, or any other text). One instance either way.

	    IconView.new({ Name = "Icon", Icon = "check", Size = 18, Color = c, Transparency = t, LayoutOrder = 1 })
	Options
	  Icon         string | State<string>   a static string is resolved once (image or glyph); a State is always an
	                                        IMAGE whose `Image` follows `Icons.imageOf(value)` (the date picker header
	                                        switches arrowDown / arrowUp this way)
	  Size         number                   the icon box (square, px); a glyph is drawn at this text size
	  Color        Color3 | State<Color3>   ImageColor3 / TextColor3 (the images are white on transparency — tinted)
	  Transparency number | State<number>?  ImageTransparency / TextTransparency
	  Name, Position, AnchorPoint, LayoutOrder, Visible, Rotation (number | State<number>)   passed through
	Glyphs use `LineHeight = 1` and the TitleLarge face (the 8th-QA rule of GlyphButton: one glyph, its em box centered).
	Returns the instance and its kind ("Image" | "Glyph").
]]

local q = require("./Quad")
local Icons = require("./Icons")
local Text = require("./Text")
local Theme = require("./Theme")
local D = q.Declaration

export type ColorIn = Color3 | q.State<Color3> | Theme.Animated
export type NumberIn = number | q.State<number> | Theme.Animated

export type Options = {
	Icon: string | q.State<string>,
	Size: number,
	Color: ColorIn,
	Transparency: NumberIn?,
	Name: string?,
	Position: (UDim2 | q.State<UDim2>)?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
	Visible: (boolean | q.State<boolean>)?,
	Rotation: NumberIn?,
}

local glyphStyle = Text.Label("TitleLarge")

local function new(o: Options): (Instance, Icons.Kind)
	local icon = o.Icon
	local kind: Icons.Kind = "Image"
	local image: string | q.State<string>
	local glyph = ""
	if type(icon) == "string" then
		local k, v = Icons.resolve(icon)
		kind = k
		image = v
		glyph = v
	else
		image = (icon :: q.State<string>):Compute(function(self)
			return Icons.imageOf(self:Get())
		end)
	end
	local size = UDim2.fromOffset(o.Size, o.Size)
	if kind == "Image" then
		return D.ImageLabel {
			Name = o.Name or "Icon",
			Size = size,
			Position = o.Position,
			AnchorPoint = o.AnchorPoint,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = image,
			ImageColor3 = o.Color,
			ImageTransparency = o.Transparency,
			LayoutOrder = o.LayoutOrder,
			Visible = o.Visible,
			Rotation = o.Rotation,
		},
			kind
	end
	return D.TextLabel {
		Name = o.Name or "Icon",
		glyphStyle,
		Size = size,
		Position = o.Position,
		AnchorPoint = o.AnchorPoint,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = glyph,
		TextSize = o.Size,
		LineHeight = 1,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextColor3 = o.Color,
		TextTransparency = o.Transparency,
		LayoutOrder = o.LayoutOrder,
		Visible = o.Visible,
		Rotation = o.Rotation,
	},
		kind
end

return { new = new }
