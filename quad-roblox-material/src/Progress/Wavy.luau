--!strict
--[[
	M3 Expressive WAVY linear progress (determinate): the active indicator is a travelling sine wave instead of a flat
	bar; after a 4 px gap the flat track continues to its stop dot, like the flat LinearProgress.

	    Progress.WavyProgress({ Value = loaded })                -- Value: number | State<number>, 0..1 (required)
	    Progress.WavyProgress({ Value = 0.6, Amplitude = 4, Wavelength = 32 })

	Props (all `read`): Value (required — see "indeterminate" below), Amplitude (px, default 3), Wavelength (px, default
	40), Thickness (stroke px, default 4), Visible (boolean | State<boolean>?, default true; the wave stops travelling while
	not Visible), Theme, Modifier (Frame Modifier after the base: width, position, LayoutOrder ...), Hooks. Height =
	Thickness + 2 x Amplitude (10 by default). Colors: wave + stop dot `Primary`, track `SecondaryContainer`.
	Returns the host `Frame`.

	HOW (Roblox has no path rendering): the wave is a polyline of short rotated Frames, 8 per wavelength, each a straight
	stroke between two samples of the sine with a little overlap to close the joins. The segments sit in one-wavelength
	groups on a strip that slides left by the phase every frame (ONE property write per frame: the strip's Position) —
	the wave travels without touching its segments. The strip is clipped to the filled length by a `CanvasGroup` (`Wave`,
	size = Value, tweened Medium1 / Standard): a plain `ClipsDescendants` frame does not clip ROTATED descendants, a
	CanvasGroup does (cost: one offscreen texture of the filled area). Groups are added when the host gets wider (checked
	in the loop: ceil(width / Wavelength) + 1 groups), never removed.
	Cost: host + Track(+UICorner, stop dot + UICorner) + Wave CanvasGroup + Strip + groups x (Frame + 8 segments) — a
	300 px bar has 9 groups = 81 + 6 = 87 instances; one Heartbeat (`Loop.luau`, only while mounted and Visible).
	Indeterminate (no Value) is NOT built: the flat indeterminate bars move their window every frame, and resizing a
	CanvasGroup per frame reallocates its texture — use `LinearProgress({})` for unknown progress. Deviations from M3:
	the wave's ends are cut square by the clip (M3 rounds them); no amplitude ramp near 0 / 100 %.
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Util = require("../Util")
local Loop = require("./Loop")
local D = q.Declaration

export type Props = {
	read Value: number | q.State<number>,
	read Amplitude: number?,
	read Wavelength: number?,
	read Thickness: number?,
	read Visible: (boolean | q.State<boolean>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local SEGMENTS = 8 -- per wavelength
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
	local amp = props.Amplitude or 3
	local lambda = props.Wavelength or 40
	local thick = props.Thickness or 4
	local height = thick + 2 * amp
	local mid = height / 2
	local step = lambda / SEGMENTS

	local value: q.State<number> = Util.asNumberState(props.Value, 0):Compute(function(self)
		return math.clamp(self:Get(), 0, 1)
	end)

	-- one wavelength of segments (identical for every group)
	local function group(k: number): Frame
		local segs: { Instance } = {}
		for i = 0, SEGMENTS - 1 do
			local x0, x1 = i * step, (i + 1) * step
			local y0 = mid - amp * math.sin(2 * math.pi * x0 / lambda)
			local y1 = mid - amp * math.sin(2 * math.pi * x1 / lambda)
			local dy = y1 - y0
			table.insert(
				segs,
				D.Frame {
					Name = "Segment",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset((x0 + x1) / 2, (y0 + y1) / 2),
					Size = UDim2.fromOffset(math.sqrt(step * step + dy * dy) + thick / 2, thick),
					Rotation = math.deg(math.atan2(dy, step)),
					BackgroundColor3 = theme.Color.Primary,
					BorderSizePixel = 0,
				}
			)
		end
		return D.Frame {
			Name = "Period",
			Position = UDim2.fromOffset(k * lambda, 0),
			Size = UDim2.fromOffset(lambda, height),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			table.unpack(segs),
		}
	end

	local groups = q.Slot({ group(0) } :: { Instance })
	local count = 1
	local host: GuiObject? = nil
	local strip: GuiObject? = nil

	local hook, effect = Loop.new(visible, function(t: number)
		local h, st = host, strip
		if h == nil or st == nil then
			return
		end
		local need = math.ceil(h.AbsoluteSize.X / lambda) + 1
		if need > count then
			for k = count, need - 1 do
				groups:Add(group(k))
			end
			count = need
			st.Size = UDim2.new(0, count * lambda, 1, 0)
		end
		st.Position = UDim2.fromOffset(-((t / PERIOD) % 1) * lambda, 0)
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
		Util.preHook(function(inst)
			host = inst
		end),
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
		D.CanvasGroup {
			Name = "Wave",
			Size = waveSize:Apply(motion),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.Frame {
				Name = "Strip",
				Size = UDim2.new(0, lambda, 1, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Util.preHook(function(inst)
					strip = inst
				end),
				groups,
			},
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return {
	WavyProgress = WavyProgress,
}
