--!strict
--[[
	Demo section "Inputs" — every input widget bound to a Source. The Sources are shared through the Context, and the
	readouts at the bottom (plus the slider's ProgressBar and the swatch) show the SAME Sources again — type in the box,
	drag the slider, and the other widgets follow.
]]

local Devui = require("../src")
local Context = require("./Context")
local q = require("./Quad")

type Context = Context.Context

local Frame = q.Elem "Frame"
local Kids = Devui.Kids

local function Inputs(ctx: Context): Instance
	local style = ctx.Style
	local committed = q.Source("quad")
	local count = q.Source(3)
	local drag = q.Source(1.5)
	local vec = q.Source(Vector2.new(10, 20))
	local udim = q.Source(UDim2.new(0.5, 0, 0, 100))

	local progress: q.State<number> = ctx.Volume:Compute(function(self)
		return self:Get() / 100
	end)
	local readout: q.State<string> = ctx.Name:Compute(function(self, _prev, volume, tint, num)
		local c: Color3 = tint:Get()
		return `name = "{self:Get()}", volume = {volume:Get()}, tint = #{string.lower(c:ToHex())}, count = {num:Get()}`
	end, ctx.Volume, ctx.Tint, count)
	local vecText: q.State<string> = vec:Compute(function(self, _prev, ud)
		local v = self:Get()
		local u: UDim2 = ud:Get()
		return `vec = ({v.X}, {v.Y}), udim2 = {tostring(u)}`
	end, udim)
	local dragText: q.State<string> = drag:Compute(function(self)
		return `drag = {string.format("%.3f", self:Get())}`
	end)
	local committedText: q.State<string> = committed:Compute(function(self)
		return `submitted = "{self:Get()}"`
	end)

	return Devui.CollapsingHeader({
		Text = "Inputs",
		Style = style,
		Children = Kids(
			Devui.SeparatorText({ Text = "Text", Style = style }),
			Devui.InputText({ Text = "name (live)", Value = ctx.Name, Placeholder = "type here", Style = style }),
			Devui.InputText({ Text = "name (on Enter)", Value = committed, Commit = "submit", Style = style }),
			Devui.TextDisabled({ Text = committedText, Style = style }),
			Devui.SeparatorText({ Text = "Numbers", Style = style }),
			Devui.InputNum({ Text = "count", Value = count, Min = 0, Max = 10, Style = style }),
			Devui.DragNum({ Text = "drag", Value = drag, Speed = 0.05, Min = -10, Max = 10, Style = style }),
			Devui.TextDisabled({ Text = dragText, Style = style }),
			Devui.SliderNum({ Text = "volume", Value = ctx.Volume, Min = 0, Max = 100, Step = 1, Style = style }),
			Devui.ProgressBar({ Value = progress, Style = style }),
			Devui.SeparatorText({ Text = "Vectors / Color", Style = style }),
			Devui.InputVector2({ Text = "vector2", Value = vec, Drag = true, Style = style }),
			Devui.InputUDim2({ Text = "udim2", Value = udim, Style = style }),
			Devui.InputColor3({ Text = "tint", Value = ctx.Tint, Style = style }),
			Devui.SeparatorText({ Text = "The same Sources, read elsewhere", Style = style }),
			Devui.TextWrapped({ Text = readout, Style = style }),
			Devui.TextDisabled({ Text = vecText, Style = style }),
			-- a swatch bound to the tint Source (one Frame)
			Frame({
				Name = "TintSwatch",
				Size = UDim2.new(1, 0, 0, 14),
				BackgroundColor3 = ctx.Tint,
				BorderSizePixel = 0,
				UICorner = style.Metrics.FrameRounding,
			})
		),
	})
end

return Inputs
