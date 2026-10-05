--!strict
--[[
	Material 3 color picker for quad.

	    local ColorPicker = require("./ColorPicker")
	    -- inline panel (a Frame; width comes from the parent, height is automatic)
	    local brand = q.Source(Color3.fromRGB(103, 80, 164))
	    ColorPicker.Panel({ Value = brand, Swatches = { ... }, OnChange = function(c) ... end })
	    -- modal (kit Dialog): draft vs committed
	    ColorPicker.Modal.open({ Value = brand:Get(), Title = "Brand color", OnConfirm = function(c) brand:Set(c) end })
	    ColorPicker.ColorModel   -- the pure color math (HSV, hue-preserving writes, hex/channel parsing)
	    ColorPicker.Classic      -- the near-identical port of the original OOP picker (see Classic/init.luau)

	== Panel ==
	Layout (top to bottom): SV area · hue slider · [preview | hex field] · RGB/HSV toggle + three number boxes ·
	preset swatches + recent colors. Parts live in `Material/`: Model (all state), SVArea, HueSlider, Preview,
	HexField, Fields, Swatches (the shared `src/KeyNav.luau` delivers their key presses). Every part reads/writes ONE model; the model's single truth is a
	`Source<HSV>`.

	PanelProps (all `read`):
	  Value      Source<Color3>?   the EXTERNAL API most callers have. Two-way: the picker writes it
	                               (`:SetIfChanged`) and follows outside writes. Hue and saturation survive trips through
	                               black / grey because the picker's own state stays HSV; the sync is ONE `Effect`
	                               (Material/Model.luau header: why an Effect, how an outside write is told from our own
	                               echo, why no Observer feeds its own upstream). Outside writes do not call OnChange.
	  HSV        Source<HSV>?      the lossless alternative: you own the canonical `{ H, S, V }` (0..1) Source and the
	                               picker needs no sync node at all. Use it when the hue matters to you (a gradient
	                               editor, a palette generator). Pass `Value` OR `HSV`, not both (error). Neither = the
	                               picker keeps its own, starting white.
	  Initial    Color3 | State<Color3>?   the "before" half of the preview (default: the color at construction)
	  OnChange   ((Color3) -> ())?  after every USER change (not outside writes, not mount)
	  Swatches   { Color3 }?       presets (static; default 8 colors)
	  Recent     Source<{ Color3 }>?  newest-first list the picker fills at the END of a gesture (drag release, key step,
	                               swatch click, field blur); pass your own to persist/share it. MaxRecent default 6.
	  ShowChannels boolean?        the RGB/HSV toggle + boxes (default true); Mode "RGB" | "HSV" starts the toggle
	  AreaHeight number?           SV area height, default 160
	  Surface    Color3 | State<Color3>?  the backdrop color behind the panel (the Outlined hex field's label notch must
	                               match it; default theme Surface — `Modal` passes SurfaceContainerHigh)
	  Disabled   boolean | State<boolean>?  input blocked (SV/hue not selectable, a surface veil at 38 % sinks the
	                               pointer over everything)
	  Theme, Modifier, Hooks       as the kit (Modifier = Frame Modifier applied after the base)

	Why the canonical state is HSV and not Color3 (the original picker's bug, see ColorModel.luau): black and grey have
	no hue; a Color3-only state snaps the hue slider to red whenever the user touches the black edge.
	Why `Value: Source<Color3>` AND `HSV: Source<HSV>`: nearly every consumer holds a Color3 (a theme field, a
	Frame's BackgroundColor3), so that is the primary prop; HSV is the escape hatch that makes the lossless state
	public instead of re-deriving it.

	== Modal ==
	`ColorPicker.Modal.open(opts)` opens a kit `Dialog` (scrim, Escape, focus handling are the Dialog's) whose body is a
	Panel editing a DRAFT (`Source<HSV>`) — nothing outside changes until OK. Cancel / scrim / Escape discard the draft.
	  opts.Value        Color3?      the committed color (default white); shown as the "before" half of the preview
	  opts.Title        string?      headline (default "Select color")
	  opts.ConfirmLabel / CancelLabel   string?   defaults "OK" / "Cancel"
	  opts.OnConfirm    ((Color3) -> ())?   once, at the start of closing, only when OK was pressed; the color is pushed to
	                               the recent list
	  opts.OnCancel     (() -> ())?         once, on Cancel / scrim / Escape
	  opts.Swatches, Recent, MaxRecent, ShowChannels, Mode, AreaHeight, Width (default 360), Overlay, Theme   as above / Dialog
	Returns the Dialog's handle (`Close(result?)`, `Result`, `IsOpen`, `Closing`).
	`ColorPicker.Recent` is the module-level default recent list the Modal uses when `Recent` is not given.

	Instances at rest (asserted in test/spec.colorpicker.luau): panel 107 including the host = SV area 12 + hue slider 11 +
	preview 4 + hex field 13 (incl. the error mark) + channels 29 + swatches 32 (8 presets x 3, no recents) + 6 of glue (host, content + list,
	value row + list, disabled veil). Recents add 3 per swatch. No image assets, no ZIndex numbers.
	M3 deviations (forced by Roblox / cost): no alpha channel (Color3 has none; an alpha slider would write a separate
	Source — out of scope); no 2D gradient shadow under the SV thumb; hex commits on blur / Enter, not per keystroke
	(Material/HexField.luau); dense 40 px channel boxes; 32 px swatches. Verified only on the mock backend —
	geometry (pointer mapping on a real AbsolutePosition, the GUI inset) and the look are not checked on a device.
]]

local q = require("./Quad")
local Theme = require("./Theme")
local Util = require("./Util")
local Dialog = require("./Dialog")
local Overlay = require("./Overlay")
local ColorModel = require("@self/ColorModel")
local Classic = require("@self/Classic")
local Model = require("@self/Material/Model")
local SVArea = require("@self/Material/SVArea")
local HueSlider = require("@self/Material/HueSlider")
local Preview = require("@self/Material/Preview")
local HexField = require("@self/Material/HexField")
local Fields = require("@self/Material/Fields")
local SwatchesModule = require("@self/Material/Swatches")
local D = q.Declaration

export type HSV = ColorModel.HSV
export type Mode = Model.Mode

export type PanelProps = {
	read Value: q.Source<Color3>?,
	read HSV: q.Source<HSV>?,
	read Initial: (Color3 | q.State<Color3>)?,
	read OnChange: ((color: Color3) -> ())?,
	read Swatches: { Color3 }?,
	read Recent: q.Source<{ Color3 }>?,
	read MaxRecent: number?,
	read ShowChannels: boolean?,
	read Mode: Mode?,
	read AreaHeight: number?,
	read Surface: (Color3 | q.State<Color3>)?,
	read Disabled: (boolean | q.State<boolean>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

export type ModalOptions = {
	read Value: Color3?,
	read Title: string?,
	read ConfirmLabel: string?,
	read CancelLabel: string?,
	read OnConfirm: ((color: Color3) -> ())?,
	read OnCancel: (() -> ())?,
	read Swatches: { Color3 }?,
	read Recent: q.Source<{ Color3 }>?,
	read MaxRecent: number?,
	read ShowChannels: boolean?,
	read Mode: Mode?,
	read AreaHeight: number?,
	read Width: number?,
	read Overlay: Overlay.Overlay?,
	read Theme: Theme.Theme?,
}

local baseModifier = D.Modifier.Frame()
	:Size(UDim2.fromScale(1, 0))
	:AutomaticSize(Enum.AutomaticSize.Y)
	:BackgroundTransparency(1)
	:BorderSizePixel(0)

local Recent: q.Source<{ Color3 }> = q.Source({} :: { Color3 })

local function Panel(props: PanelProps)
	local theme = Theme.resolve(props.Theme)
	local model = Model.new({
		HSV = props.HSV,
		Value = props.Value,
		Initial = props.Initial,
		Recent = props.Recent,
		MaxRecent = props.MaxRecent,
		Mode = props.Mode,
		OnChange = props.OnChange,
	})
	local disabled = Util.asState(props.Disabled)
	local surface = props.Surface or theme.Color.Surface
	local hex = HexField({
		Model = model,
		Theme = theme,
		NotchColor = surface,
		Disabled = props.Disabled,
		Modifier = D.Modifier.Frame():Size(UDim2.new(1, -68, 0, 0)),
	})
	local veil: q.State<number> = disabled:Compute(function(self)
		return if self:Get() then 0.38 else 1
	end)

	return D.Frame {
		Name = "ColorPicker",
		baseModifier,
		props.Modifier or q.None,
		model.Sync or q.None,
		hex.Sync,
		D.Frame {
			Name = "Content",
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.UIListLayout {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 12),
			},
			SVArea({ Model = model, Theme = theme, Height = props.AreaHeight, Disabled = disabled, LayoutOrder = 1 }),
			HueSlider({ Model = model, Theme = theme, Disabled = disabled, LayoutOrder = 2 }),
			D.Frame {
				Name = "ValueRow",
				Size = UDim2.new(1, 0, 0, 56),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = 3,
				D.UIListLayout {
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 12),
				},
				Preview({ Model = model, Theme = theme }),
				hex.Field,
			},
			if props.ShowChannels == false then q.None else Fields({ Model = model, Theme = theme, LayoutOrder = 4 }),
			SwatchesModule.Swatches({ Model = model, Theme = theme, Swatches = props.Swatches, LayoutOrder = 5 }),
		},
		D.Frame {
			Name = "DisabledVeil",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = surface,
			BackgroundTransparency = veil,
			BorderSizePixel = 0,
			Active = true,
			Visible = disabled,
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
end

local function open(o: ModalOptions): Dialog.Handle
	local theme = Theme.resolve(o.Theme)
	local start = o.Value or Color3.new(1, 1, 1)
	local draft = q.Source(ColorModel.fromColor3(start, nil))
	local recent = o.Recent or Recent
	local maxRecent = o.MaxRecent or 6
	local panel = Panel({
		HSV = draft,
		Initial = start,
		Swatches = o.Swatches,
		Recent = recent,
		MaxRecent = maxRecent,
		ShowChannels = o.ShowChannels,
		Mode = o.Mode,
		AreaHeight = o.AreaHeight,
		Surface = theme.Color.SurfaceContainerHigh,
		Theme = theme,
	})
	return Dialog.open({
		Headline = o.Title or "Select color",
		Body = panel,
		Width = o.Width or 360,
		Overlay = o.Overlay,
		Theme = theme,
		DismissResult = false,
		Actions = {
			{ Label = o.CancelLabel or "Cancel", Result = false },
			{ Label = o.ConfirmLabel or "OK", Result = true },
		},
		OnClose = function(result: unknown?)
			if result == true then
				local c = ColorModel.toColor3(draft:Get())
				Model.pushRecent(recent, c, maxRecent)
				if o.OnConfirm then
					o.OnConfirm(c)
				end
			elseif o.OnCancel then
				o.OnCancel()
			end
		end,
	})
end

return {
	Panel = Panel,
	Modal = { open = open },
	Recent = Recent,
	ColorModel = ColorModel,
	Classic = Classic,
	Defaults = SwatchesModule.Defaults,
}
