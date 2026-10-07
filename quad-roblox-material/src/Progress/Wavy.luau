--!strict
--[[
	M3 Expressive WAVY linear progress (determinate): the active indicator is a travelling sine wave instead of a flat
	bar; after a 4 px gap the flat track continues to its stop dot, like the flat LinearProgress.

	    Progress.WavyProgress({ Value = loaded })                -- Value: number | State<number>, 0..1 (required)
	    Progress.WavyProgress({ Value = 0.6, Thickness = 6, Wavelength = 60 })

	Props (all `read`): Value (required — see "indeterminate" below), Thickness (stroke px, default 4), Wavelength (px,
	default 40), Visible (boolean | State<boolean>?, default true; the wave stops travelling while not Visible), Theme,
	Modifier (Frame Modifier after the base: width, position, LayoutOrder ...), Hooks. Height = 2.5 x Thickness (10 by
	default) and the amplitude is 0.75 x Thickness (3 by default) — FIXED ratios, see "HOW". Colors: wave + stop dot
	`Primary`, track `SecondaryContainer`. Returns the host `Frame`.

	HOW (Roblox has no path rendering): the wave is a TILED IMAGE. `WAVE_IMAGE` is one wavelength of an anti-aliased white
	sine stroke on a transparent 512 x 128 texture (source: quad-roblox-material/assets/wavy-progress-512x128.png; stroke
	= 4/10 of the height, amplitude = 3/10, centre line at both edges, rising first, so it repeats seamlessly), drawn by one
	ImageLabel (`Strip`, ScaleType Tile, TileSize = Wavelength x height, tinted by ImageColor3). The strip is one
	wavelength wider than its clip and slides left by the phase every frame (ONE property write per frame: its Position)
	— the tiles move with it, so the wave travels. The strip sits in a plain `ClipsDescendants` frame (`Wave`, size =
	Value, tweened Medium1 / Standard): nothing is rotated, so ordinary clipping works — no CanvasGroup (no offscreen
	texture, nothing reallocated on resize).
	Why an image (2026-10-07, replaced a polyline of 8 rotated Frames per wavelength + a CanvasGroup clip, 87 instances
	at 300 px): Roblox does not anti-alias the edges of rotated GuiObjects (DevForum "GUI Anti-Aliasing for Rotation",
	"Rotation causes frames' edges to be pixelated"), and a CanvasGroup renders through a texture whose resolution the
	engine lowers with the graphics level and memory (DevForum "CanvasGroups content is blurred!", "Is there anyway to
	get a consistent quality on Canvas Groups?") — the two likely causes of the low-resolution look seen in Studio (not
	separated by measurement). The texture's stroke is anti-aliased in the image itself and shown ~12.8x downsampled
	by the engine's image filtering, so its edge should stay smooth (Studio QA to confirm).
	Fixed ratios: the texture's stroke and amplitude scale WITH the height, so they cannot be set independently —
	`Thickness` sets the height (2.5 x) and the amplitude follows (M3's default 4 / 3 / 10 dp). `Wavelength` stretches
	the tile horizontally: away from 4 x the height (40 for Thickness 4) the slopes steepen or flatten and a steep
	stroke looks a little thinner.
	Cost: host + Track(+UICorner, stop dot + UICorner) + Wave clip + Strip = 7 instances at any width; one Heartbeat
	(`Loop.luau`, only while mounted and Visible).
	`WAVE_IMAGE` = rbxassetid://78445787165309 (the texture above, uploaded by the kit author — the IMAGE id the Decal resolves to, not the Decal id). If the asset fails to
	load the wave is invisible; the track and stop dot still show.
	Indeterminate (no Value) is NOT built: use `LinearProgress({})` for unknown progress. Deviations from M3: the
	wave's ends are cut square by the clip (M3 rounds them); no amplitude ramp near 0 / 100 %; amplitude and stroke are
	tied to the height (above).
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Util = require("../Util")
local Loop = require("./Loop")
local D = q.Declaration

export type Props = {
	read Value: number | q.State<number>,
	read Thickness: number?,
	read Wavelength: number?,
	read Visible: (boolean | q.State<boolean>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

-- One wavelength of the sine stroke: assets/wavy-progress-512x128.png, uploaded by the kit author (2026-10-07).
local WAVE_IMAGE = "rbxassetid://78445787165309"
local HEIGHT_PER_THICKNESS = 2.5 -- the texture: stroke 4/10, amplitude 3/10 of its height
local GAP = 4
local STOP = 4
local PERIOD = 1 -- seconds for the wave to travel one wavelength
local full = UDim.new(0.5, 0)

local function WavyProgress(props: Props): Frame
	if props.Value == nil then
		error("WavyProgress: Value is required (use LinearProgress({}) for indeterminate progress)", 2)
	end
	local theme = Theme.resolve(props.Theme)
	local visible = Util.asState(props.Visible, true)
	local thick = props.Thickness or 4
	local lambda = props.Wavelength or 40
	local height = thick * HEIGHT_PER_THICKNESS

	local value: q.State<number> = Util.asNumberState(props.Value, 0):Compute(function(self)
		return math.clamp(self:Get(), 0, 1)
	end)

	local strip: GuiObject? = nil
	local hook, effect = Loop.new(visible, function(t: number)
		local st = strip
		if st ~= nil then
			st.Position = UDim2.fromOffset(-((t / PERIOD) % 1) * lambda, 0)
		end
	end)

	local motion = q.Animate(Tokens.Motion.options("Medium1", "Standard"))
	local waveSize: q.State<UDim2> = value:Compute(function(self)
		return UDim2.fromScale(self:Get(), 1)
	end)
	local trackPosition: q.State<UDim2> = value:Compute(function(self)
		local x = self:Get()
		return UDim2.new(x, if x > 0 then GAP else 0, 0.5, 0)
	end)
	local trackSize: q.State<UDim2> = value:Compute(function(self)
		local x = self:Get()
		return UDim2.new(1 - x, if x > 0 then -GAP else 0, 0, thick)
	end)
	local notFull: q.State<boolean> = value:Compute(function(self)
		return self:Get() < 1
	end)

	return D.Frame {
		Name = "WavyProgress",
		D.Modifier.Frame():Size(UDim2.new(1, 0, 0, height)):BackgroundTransparency(1):BorderSizePixel(0),
		props.Modifier or q.None,
		Visible = visible,
		hook,
		effect,
		D.Frame {
			Name = "Track",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = trackPosition:Apply(motion),
			Size = trackSize:Apply(motion),
			Visible = notFull,
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Color.SecondaryContainer,
			UICorner = full,
			D.Frame {
				Name = "Stop",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(STOP, STOP),
				BorderSizePixel = 0,
				BackgroundColor3 = theme.Color.Primary,
				UICorner = full,
			},
		},
		D.Frame {
			Name = "Wave",
			Size = waveSize:Apply(motion),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			D.ImageLabel {
				Name = "Strip",
				-- the clip's width plus one wavelength (room for the slide); tiles start at the strip's left edge, so
				-- growing it as Value tweens does not move the wave
				Size = UDim2.new(1, lambda, 1, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = WAVE_IMAGE,
				ImageColor3 = theme.Color.Primary,
				ScaleType = Enum.ScaleType.Tile,
				TileSize = UDim2.fromOffset(lambda, height),
				Util.preHook(function(inst)
					strip = inst
				end),
			},
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return {
	WavyProgress = WavyProgress,
}
