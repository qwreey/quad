--!strict
--[[
	Style editor window.

	WHAT IS LIVE: the scheme (Dark / Light) and density (Default / Clear) radio groups are bound two-way to
	`style.Scheme` / `style.Density`, so the whole demo repaints as you click.

	WHAT IS NOT (kit gap, reported): `Style` has no per-token setter — its tokens are read-only derived States and the
	palette/metric overrides are fixed at `Style.new{...}` time. So the colour/metric editors below edit a THROW-AWAY
	preview Style: a change builds a fresh `Style.new{...}` and re-mounts the small preview panel (a `Slot:Single`
	that owns and destroys the previous panel). The config is DEBOUNCED (`q.Debounce{ Time = 0.15 }`) so dragging a
	colour / number rebuilds the panel once the value settles, not once per pixel. The shared style is never modified by
	those fields.
]]

local Devui = require("./Kit")
local Context = require("./Context")
local q = require("../Quad")

type Context = Context.Context

local D = q.Declaration
local Kids = Devui.Kids

type Scheme = typeof(Devui.Style.default.Scheme:Get())
type Density = typeof(Devui.Style.default.Density:Get())
type Config = { Accent: Color3, Field: Color3, Rounding: number, TextSize: number }

export type StyleEditorProps = {
	read Context: Context,
	read Open: q.Source<boolean>?,
	read Position: q.Source<UDim2>?,
	read Size: q.Source<Vector2>?,
	read Manager: Devui.Manager?,
}

-- the preview panel: a few widgets drawn with a Style built from the config
local function buildPreview(c: Config): Instance
	local overrides = { ButtonColor = c.Accent, FrameBgColor = c.Field, HeaderColor = c.Accent }
	local pStyle = Devui.Style.new({
		Dark = overrides,
		Light = overrides,
		Metrics = { FrameRounding = c.Rounding, TextSize = c.TextSize },
	})
	local on = q.Source(true)
	local value = q.Source(35)
	return D.Frame({
		Name = "Preview",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		D.UIListLayout({ SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
		Devui.Button({ Text = "Preview button", Style = pStyle }),
		Devui.Checkbox({ Text = "Preview checkbox", Value = on, Style = pStyle }),
		Devui.SliderNum({ Text = "slider", Value = value, Min = 0, Max = 100, Style = pStyle }),
		Devui.Selectable({ Text = "Preview selectable (header colour)", Selected = q.Source(true), Style = pStyle }),
	})
end

local function StyleEditorWindow(props: StyleEditorProps): Frame
	local ctx = props.Context
	local style = ctx.Style
	local accent = q.Source(Color3.fromRGB(66, 150, 250))
	local field = q.Source(Color3.fromRGB(41, 74, 122))
	local rounding = q.Source(3)
	local textSize = q.Source(13)

	local config: q.State<Config> = accent:Compute(function(self, _prev, f, r, t)
		return { Accent = self:Get(), Field = f:Get(), Rounding = r:Get(), TextSize = t:Get() }
	end, field, rounding, textSize)

	local settled: q.State<Config> = config:Apply(q.Debounce({ Time = 0.15 }))
	local preview = q.Slot<<Instance>>():Single<<Config, nil>>(settled, function(c)
		return buildPreview(c.Item :: Config), nil
	end)

	return Devui.Window({
		Title = "Style Editor",
		Style = style,
		Open = props.Open,
		Position = props.Position or q.Source(UDim2.fromOffset(520, 60)),
		Size = props.Size or q.Source(Vector2.new(320, 420)),
		Manager = props.Manager,
		Children = Kids(
			Devui.SeparatorText({ Text = "Live (shared Style)", Style = style }),
			Devui.SameLine({
				Style = style,
				Children = Kids(
					Devui.Text({ Text = "scheme", Style = style }),
					Devui.RadioButton<<Scheme>>({ Text = "Dark", Value = style.Scheme, Option = "Dark", Style = style }),
					Devui.RadioButton<<Scheme>>({ Text = "Light", Value = style.Scheme, Option = "Light", Style = style })
				),
			}),
			Devui.SameLine({
				Style = style,
				Children = Kids(
					Devui.Text({ Text = "density", Style = style }),
					Devui.RadioButton<<Density>>({ Text = "Default", Value = style.Density, Option = "Default", Style = style }),
					Devui.RadioButton<<Density>>({ Text = "Clear", Value = style.Density, Option = "Clear", Style = style })
				),
			}),
			Devui.SeparatorText({ Text = "Preview style (rebuilt per change)", Style = style }),
			Devui.TextWrapped({ Text = "The shared Style has no per-token setter, so these fields restyle a separate preview Style.", Style = style }),
			Devui.InputColor3({ Text = "Button / Header", Value = accent, Style = style }),
			Devui.InputColor3({ Text = "FrameBg", Value = field, Style = style }),
			Devui.DragNum({ Text = "FrameRounding", Value = rounding, Min = 0, Max = 12, Step = 1, Style = style }),
			Devui.DragNum({ Text = "TextSize", Value = textSize, Min = 9, Max = 24, Step = 1, Style = style }),
			D.Frame({
				Name = "PreviewHost",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				D.UIListLayout({ SortOrder = Enum.SortOrder.LayoutOrder }),
				preview,
			})
		),
	})
end

return StyleEditorWindow
