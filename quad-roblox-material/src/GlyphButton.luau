--!strict
--[[
	GlyphButton: ONE small round control whose icon is an image asset (the `Icons` defaults) or a text glyph (the `Icons`
	fallback) — the date picker's previous / next / mode buttons, the Snackbar's close button, the Chip's remove button.
	The kit's `IconButton` is the public 40 px Material icon button; this one takes either form and covers the three
	shapes the kit needs:

	    GlyphButton.new({ Glyph = "‹", Position = UDim2.fromOffset(8, 8), OnClick = prev })            -- 40 px, state layer
	    GlyphButton.new({ Asset = Icons.asset("close"), Glyph = Icons.glyph("close"), Size = 36, Hit = 48,
	                      ColorRole = "InverseOnSurface", OnClick = close })                           -- 36 px visual in a 48 px hit
	    GlyphButton.new({ Glyph = "×", Hit = 48, Layer = false, Color = c, Transparency = t, OnClick = remove })  -- bare hit target

	Options (`Options` below)
	  Glyph        string | State<string>?   text glyph (a TextButton / TextLabel); ignored when `Asset` is given
	  Asset        (string | State<string>)?  image asset id (an ImageButton host + a centered ImageLabel instead of text); a
	                                         State switches the image (the date picker's edit / calendar mode toggle)
	  Size         number?                   the visible circle / glyph box, default 40
	  Hit          number?                   the transparent touch target, default = Size. Larger than Size WITH a layer: the
	                                         host is the `Hit` square and a `Visual` frame (the circle + state layer) sits
	                                         inside it (+1 instance); without a layer the host just is `Hit` px and draws the glyph
	  Layer        boolean?                  default true: hover / press / focus state layer + ripple (`Interactive`), 3 more
	                                         instances. false: no feedback of its own (the Chip remove button lives inside a
	                                         chip that already lights its own layer)
	  ColorRole    Role?                     default "OnSurfaceVariant"; disabled switches to onSurface @ 38 %
	  Color        Color3 | State<Color3>?   overrides the role-derived content color (and the layer color)
	  Transparency number | State<number>?   overrides the disabled-derived content transparency
	  TextSize     number?                   glyph size (default = the Role style's); with `Asset`: the icon size (default 24)
	  Role         Text role?                text style, default "TitleLarge"
	  Name, Position, AnchorPoint, LayoutOrder, Disabled, Visible (default true), Theme, OnClick
	  Hooks        Hooks?                    extra array-part values on the host (a `Tooltip.hook`, a selection tracker, ...)
	Returns the host (`TextButton`, or `ImageButton` with `Asset` — an empty button hosting a centered `Icon` ImageLabel of
	icon size `TextSize` or 24, in both the wrapped and the bare path).

	Cost: text glyph, layer, no wrapper = host + state layer (Frame + UICorner + UIStroke) = 4; image, layer, no wrapper =
	host + its UICorner + state layer + Icon = 6; wrapper: host + Visual (+ UICorner) + state layer + glyph label = 7; no
	layer = the host alone (text) / host + Icon (image).

	Glyph clipping (Studio QA 2026-10-08, the date picker modal's mode toggle): a `UICorner` rounds its parent's OWN
	drawing — background, image AND text — so a glyph drawn by a round (corner Full) host was cut by the circle wherever
	the glyph's ink reached past it: an engine fallback glyph (edit U+270E / calendar U+25A6 have no Roboto glyph) is
	drawn with another font's metrics, and the role's LineHeight (TitleLarge 28/22) moved it down inside the 40 px circle.
	So the text-glyph host carries NO UICorner (its background is transparent; the state layer has its own corner — the
	visible round shape), and every glyph is set with `LineHeight = 1` (one glyph, no lines to space: its em box is the
	centered box). The wrapped path's label is a child, which a parent's UICorner never clips.
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Interactive = require("./Interactive")
local Text = require("./Text")
local Style = require("./Button/Style")
local ColorTokens = require("./Tokens/Color")
local D = q.Declaration

export type Options = {
	Glyph: (string | q.State<string>)?,
	Asset: (string | q.State<string>)?,
	Size: number?,
	Hit: number?,
	Layer: boolean?,
	ColorRole: ColorTokens.Role?,
	Color: (Color3 | q.State<Color3>)?,
	Transparency: (number | q.State<number>)?,
	TextSize: number?,
	Role: Text.Role?,
	Name: string?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
	Disabled: (boolean | q.State<boolean>)?,
	Visible: (boolean | q.State<boolean>)?,
	Theme: Theme.Theme?,
	OnClick: () -> (),
	Hooks: Util.Hooks?,
}

local function new(o: Options): GuiButton
	local theme = Theme.resolve(o.Theme)
	local disabled = Util.asState(o.Disabled)
	local size = o.Size or 40
	local hit = o.Hit or size
	local withLayer = o.Layer ~= false
	local wrapped = withLayer and hit > size
	local corner = Tokens.Shape.corner("Full")
	local role: ColorTokens.Role = o.ColorRole or "OnSurfaceVariant"
	local color: Color3 | q.State<Color3> = o.Color or Style.disabledPick(disabled, theme.Raw[role], theme.Raw.OnSurface)
	local transparency: number | q.State<number> = o.Transparency or Style.disabledNumber(disabled, 0, Style.DisabledContentTransparency)
	local style = Text.Button(o.Role or "TitleLarge")
	local fx = if withLayer
		then Interactive.new({ Theme = theme, Disabled = disabled, OnColor = o.Color or theme.Color[role], Corner = corner })
		else nil
	local interactable = Util.interactable(disabled)
	local hostSize = UDim2.fromOffset(hit, hit)
	local function activated()
		if not Util.peekBool(disabled) then
			o.OnClick()
		end
	end
	local hooks = Util.hooks(o.Hooks)
	local iconSize = o.TextSize or 24
	-- an image asset is drawn as a centered `ImageLabel` of icon size (never stretched over the hit area)
	local function iconImage(asset: string | q.State<string>): Instance
		return D.ImageLabel {
			Name = "Icon",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(iconSize, iconSize),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = asset,
			ImageColor3 = color,
			ImageTransparency = transparency,
		}
	end
	local hostHook = if fx ~= nil then fx.Hook else q.None
	local layer = if fx ~= nil and not wrapped then fx.Layer else q.None

	-- the drawn glyph: inside the Visual frame when wrapped, else the host draws it itself
	if wrapped and fx ~= nil then
		local glyph: Instance
		if o.Asset ~= nil then
			glyph = iconImage(o.Asset)
		else
			glyph = D.TextLabel {
				Name = "Label",
				Text.Label(o.Role or "TitleLarge"),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = o.Glyph or "",
				TextSize = o.TextSize,
				LineHeight = 1,
				TextColor3 = color,
				TextTransparency = transparency,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}
		end
		return D.TextButton {
			Name = o.Name or "Glyph",
			Size = hostSize,
			Position = o.Position,
			AnchorPoint = o.AnchorPoint,
			LayoutOrder = o.LayoutOrder,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Visible = Util.visible(o.Visible),
			Interactable = interactable,
			Activated = activated,
			hostHook,
			D.Frame {
				Name = "Visual",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(size, size),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				UICorner = corner,
				fx.Layer,
				glyph,
			},
			table.unpack(hooks),
		}
	end

	if o.Asset ~= nil then
		return D.ImageButton {
			Name = o.Name or "Glyph",
			Size = hostSize,
			Position = o.Position,
			AnchorPoint = o.AnchorPoint,
			LayoutOrder = o.LayoutOrder,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Visible = Util.visible(o.Visible),
			Interactable = interactable,
			Activated = activated,
			UICorner = if withLayer then corner else nil,
			hostHook,
			layer,
			iconImage(o.Asset),
			table.unpack(hooks),
		}
	end
	return D.TextButton {
		Name = o.Name or "Glyph",
		style,
		Size = hostSize,
		Position = o.Position,
		AnchorPoint = o.AnchorPoint,
		LayoutOrder = o.LayoutOrder,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = o.Glyph or "",
		TextSize = o.TextSize,
		LineHeight = 1,
		TextColor3 = color,
		TextTransparency = transparency,
		Visible = Util.visible(o.Visible),
		Interactable = interactable,
		Activated = activated,
		-- no UICorner: it would round the host's own TEXT too and cut the glyph (header "Glyph clipping")
		hostHook,
		layer,
		table.unpack(hooks),
	}
end

return { new = new }
