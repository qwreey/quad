--!strict
--[[
	Elevation: apply an M3 elevation level (0-5) to a surface.

	DEFAULT = `UIShadow` (ONE child instance, drawn behind its parent via `ShowBehindParent`; follows the
	parent's `UICorner`; GPU blur — no image asset, no 9-slice). Level numbers come from
	`Tokens/Elevation.luau` (blur / y-offset / spread / transparency), the color is the theme's `Shadow` role.

	    D.TextButton {
	        ...,
	        Elevation.Shadow({ Level = hoverLevel }),     -- State<number> | number; tweens between levels
	    }
	  Elevation.Shadow(opts) -> UIShadow
	    opts.Level   number | State<number>   0..5 (rounded, clamped). 0 = shadow disabled.
	    opts.Theme   Theme?                   shadow color source (default theme)
	    Animation: Motion Short4 / Standard on blur, offset, spread, transparency; `Enabled` is bound to
	    "level > 0" and flips at once (a drop to 0 hides the shadow immediately — levels 1-5 tween).

	RISK / FALLBACK: `UIShadow` is the newest of the UI classes this kit uses. It exists in the engine API
	dump quad generates its Declaration from, but it could not be verified in a live Studio from this
	environment (no Studio session was allowed) — if a place runs on a client without it, the instance is
	inert/invalid, so keep the fallback in mind:
	  Elevation.Backdrop(opts) -> ImageLabel     ONE 9-slice `ImageLabel` (not 8), `Config.BackdropImage`
	    A GuiObject child is always drawn ABOVE its parent, so the image backdrop cannot be a child of the
	    surface; place it as a SIBLING placed before the surface in a wrapper Frame that has the surface's
	    size (`Size = UDim2.new(1, 2*spread, 1, 2*spread)` relative to that wrapper). It does not follow a
	    `UICorner` automatically — pick the slice image whose corner radius matches (default image: a soft
	    generic rounded shadow, see Config). Default is `Shadow`; components of this kit only ever use
	    `Shadow`. `Backdrop` is here so a project can swap `Elevation.Shadow` for it inside ONE module.
	  Config.BackdropImage  asset id of the 9-slice shadow (default: the soft-shadow image used by the
	    RoStrap/roact-material kits, "rbxassetid://1316045217" — third-party, not verified by this kit;
	    upload your own and set it)
	  Config.BackdropSlice  its SliceCenter (default Rect.new(10, 10, 118, 118) for that image)
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local ImageLabel = q.Elem "ImageLabel"
local UIShadow = q.Elem "UIShadow"

local ElevationTokens = require("./Tokens/Elevation")

export type Options = { Level: (number | q.State<number>)?, Theme: Theme.Theme? }

local Config = {
	BackdropImage = "rbxassetid://1316045217",
	BackdropSlice = Rect.new(10, 10, 118, 118),
}

local function levelState(level: (number | q.State<number>)?): q.State<ElevationTokens.Level>
	local lv = Util.asNumberState(level, 0)
	return lv:Compute(function(self)
		return ElevationTokens.levelOf(self:Get())
	end)
end

local function Shadow(o: Options?)
	local opts: Options = o or {}
	local theme = Theme.resolve(opts.Theme)
	local tok = levelState(opts.Level)
	local animate = Tokens.Motion.options("Short4", "Standard")

	local blur: q.State<UDim> = tok:Compute(function(self)
		return UDim.new(0, self:Get().BlurRadius)
	end)
	local offset: q.State<UDim2> = tok:Compute(function(self)
		return UDim2.fromOffset(0, self:Get().OffsetY)
	end)
	local spread: q.State<UDim2> = tok:Compute(function(self)
		local s = self:Get().Spread
		return UDim2.fromOffset(s, s)
	end)
	local transparency: q.State<number> = tok:Compute(function(self)
		return self:Get().Transparency
	end)
	local enabled: q.State<boolean> = tok:Compute(function(self)
		return self:Get().Dp > 0
	end)

	local shadow = UIShadow {
		Name = "Elevation",
		BlurRadius = blur:Apply(q.Animate(animate)),
		Offset = offset:Apply(q.Animate(animate)),
		Spread = spread:Apply(q.Animate(animate)),
		Transparency = transparency:Apply(q.Animate(animate)),
		Color = theme.Color.Shadow,
		Enabled = enabled,
	}
	-- `ShowBehindParent` is newer than the type definitions some checkers ship (the repo-pinned luau-lsp defs lack it), and
	-- quad's typed surface is built from the checker's own class types — so it is set here, past the typed props table
	;(shadow :: any).ShowBehindParent = true
	return shadow
end

local function Backdrop(o: Options?)
	local opts: Options = o or {}
	local tok = levelState(opts.Level)
	local animate = Tokens.Motion.options("Short4", "Standard")
	local size: q.State<UDim2> = tok:Compute(function(self)
		local grow = 2 * (self:Get().BlurRadius + self:Get().Spread)
		return UDim2.new(1, grow, 1, grow)
	end)
	local position: q.State<UDim2> = tok:Compute(function(self)
		return UDim2.new(0.5, 0, 0.5, self:Get().OffsetY)
	end)
	local transparency: q.State<number> = tok:Compute(function(self)
		return self:Get().Transparency
	end)
	return ImageLabel {
		Name = "ElevationBackdrop",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = Config.BackdropImage,
		ImageColor3 = Color3.new(0, 0, 0),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Config.BackdropSlice,
		Size = size:Apply(q.Animate(animate)),
		Position = position:Apply(q.Animate(animate)),
		ImageTransparency = transparency:Apply(q.Animate(animate)),
	}
end

return {
	Shadow = Shadow,
	Backdrop = Backdrop,
	Config = Config,
}
