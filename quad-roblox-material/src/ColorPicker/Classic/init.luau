--!strict
--[[
	Classic color picker — a near-identical port of the user's original 2348-line OOP LocalScript.

	    local ClassicColorPicker = require("./ColorPicker/Classic")
	    ClassicColorPicker({
	        Theme = "Dark",                       -- "Light" | "Dark" | a Themes.Theme table      (default Light)
	        Title = "Color Picker",
	        Initial = { H = 0.8, S = 0.4, V = 1 },-- uncontrolled start (ignored when Value is given)
	        Value = hsvSource,                    -- Source<HSV>?  controlled draft; the picker writes it, you may too
	        LastColor = Color3.fromRGB(222, 0, 222), -- or a Source<Color3>; the left half of the preview
	        OnUpdate = function(color, h, s, v) end,  -- every USER change of the draft (not cancel, not outside writes)
	        OnConfirm = function(color, h, s, v) end, -- Select pressed: last := draft
	        OnCancel = function(last, draft) end,     -- Cancel / close pressed: draft := last (no OnUpdate)
	        Modifier = D.Modifier.Frame():Position(...),
	    })

	Returns the window Frame (230 x 418, ZIndexBehavior Sibling — no ZIndex numbers are used except the fake
	cursor and the hue slider's shadow-below-handle / shadow-below-bubble pairs, HueSlider.luau). Look, sizes, colors, asset ids, layout order, fonts, timings: see the headers of the sub-files and
	`docs/colorpicker-original-analysis.md`. Display scale = ColorModel.Scale.Legacy (0..255), hex without `#`.

	Port fidelity (kept on purpose): the original tweens the handle/cursor/ring toward EVERY pointer move; the port keeps
	those per-move tweens (`Anim`) rather than snapping, so a drag allocates one short tween per move. The Material panel
	(`ColorPicker.Panel`) never animates a position that follows the pointer.

	Files: Model (all state + writers), HueSlider, SVField, EditRow, ConfirmBar, Window (title bar, shadow),
	FakeCursor, Anim, Themes, Demo.

	Original bugs fixed (details in the sub-file headers): hue/saturation lost on R/G/B/HEX entry and on cancel
	(single `Source<HSV>`); H/S/V boxes did not update the preview; cancel wrote boxes with the OLD hsv; the
	drag-end path indexed `true.Position` on focus loss (error); close "x" never visible; duplicated MouseEnter;
	`fromInstance` mixups (HueSlider restored by the SV class, H/S box names swapped) — gone with `q.dispose`;
	hard-coded `y - 36` inset (positions now come from the drag tracker in AbsolutePosition space); wheel on an
	empty box errored; pointer-to-handle drift at the track ends; `onConfirm` demo formatted 0..1 floats with %d.
]]

local q = require("../Quad")
local Util = require("../Util")
local ConfirmBar = require("@self/ConfirmBar")
local EditRow = require("@self/EditRow")
local FakeCursor = require("@self/FakeCursor")
local HueSlider = require("@self/HueSlider")
local Model = require("@self/Model")
local SVField = require("@self/SVField")
local Themes = require("@self/Themes")
local Window = require("@self/Window")
local D = q.Declaration

export type HSV = Model.HSV

export type Props = {
	read Theme: Themes.ThemeInput?,
	read Title: string?,
	read Initial: HSV?,
	read Value: q.Source<HSV>?,
	read LastColor: (Color3 | q.Source<Color3>)?,
	read OnUpdate: ((color: Color3, h: number, s: number, v: number) -> ())?,
	read OnConfirm: ((color: Color3, h: number, s: number, v: number) -> ())?,
	read OnCancel: ((last: Color3, draft: Color3) -> ())?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local baseModifier = D.Modifier.Frame():Size(UDim2.fromOffset(230, 418)):BorderSizePixel(0)

local function ClassicColorPicker(props: Props)
	local theme = Themes.resolve(props.Theme)
	local model = Model.new({
		Value = props.Value,
		Initial = props.Initial,
		LastColor = props.LastColor,
		OnUpdate = props.OnUpdate,
		OnConfirm = props.OnConfirm,
		OnCancel = props.OnCancel,
	})
	local fake = FakeCursor.new()

	return D.Frame {
		Name = "ClassicColorPicker",
		baseModifier,
		props.Modifier or q.None,
		BackgroundColor3 = theme.WindowBackgroundColor,
		UICorner = 10,
		Window.WindowShadow(),

		D.Frame {
			Name = "Holder",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			D.UIPadding {
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
				PaddingTop = UDim.new(0, 16),
			},
			D.UIListLayout { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder },

			Window.TitleBar({ Theme = theme, Title = props.Title or "Color Picker", OnClose = model.cancel, LayoutOrder = 0 }),
			SVField({ Model = model, Fake = fake, LayoutOrder = 1 }),
			HueSlider({ Model = model, Fake = fake, LayoutOrder = 2 }),
			EditRow.HSV({ Model = model, Theme = theme, LayoutOrder = 3 }),
			EditRow.RGB({ Model = model, Theme = theme, LayoutOrder = 4 }),
			EditRow.Hex({ Model = model, Theme = theme, LayoutOrder = 5 }),
			ConfirmBar({ Model = model, Theme = theme, LayoutOrder = 6 }),
		},
		fake.Element,
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return ClassicColorPicker
