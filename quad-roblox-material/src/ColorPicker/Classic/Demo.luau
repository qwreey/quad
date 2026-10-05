--!strict
--[[
	The original's demo: a full-size white Frame, centered horizontal UIListLayout (32 px gap), two windows —
	Light and Dark — both starting at HSV(0.8, 0.4, 1) with last color (222, 0, 222), logging confirm/cancel.

	    local root = Demo.build()           -- parent it to a ScreenGui (ZIndexBehavior Sibling, the default)
	    Demo.build({ Log = function(line) ... end })   -- capture the log lines instead of `print`

	Fix vs the original: its confirm/cancel lines formatted the 0..1 hue/sat/val with `%d` (always "0"); here
	they are shown on the 0..255 box scale.
]]

local q = require("../../Quad")
local ClassicColorPicker = require("../Classic")
local D = q.Declaration

export type Options = { Log: ((line: string) -> ())? }

local function bytes(c: Color3): string
	return `{math.floor(c.R * 255 + 0.5)}, {math.floor(c.G * 255 + 0.5)}, {math.floor(c.B * 255 + 0.5)}`
end

local function window(theme: "Light" | "Dark", log: (string) -> ())
	return ClassicColorPicker({
		Theme = theme,
		Title = "Color Picker",
		Initial = { H = 0.8, S = 0.4, V = 1 },
		LastColor = Color3.fromRGB(222, 0, 222),
		OnConfirm = function(color: Color3, h: number, s: number, v: number)
			log(`[confirm] rgb({bytes(color)}), hsv({math.floor(h * 255 + 0.5)}, {math.floor(s * 255 + 0.5)}, {math.floor(v * 255 + 0.5)})`)
		end,
		OnCancel = function(last: Color3, draft: Color3)
			log(`[cancel] last = rgb({bytes(last)}), draft = rgb({bytes(draft)})`)
		end,
	})
end

local function build(opts: Options?)
	local log = (opts and opts.Log) or print
	return D.Frame {
		Name = "ColorPickerDemo",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		D.UIListLayout {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 32),
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		window("Light", log),
		window("Dark", log),
	}
end

return {
	build = build,
}
