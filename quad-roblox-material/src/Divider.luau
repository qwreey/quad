--!strict
--[[
	M3 divider: a 1 px outlineVariant line.

	    Divider()                                         -- full width, horizontal
	    Divider({ Inset = "Start" })                      -- inset: 16 px on the leading side
	    Divider({ Inset = "Both" })                       -- middle inset: 16 px on both sides
	    Divider({ Orientation = "Vertical" })

	Props (all `read`): Orientation "Horizontal" | "Vertical" (default Horizontal), Inset "None" | "Start" | "Both"
	(default None), Theme, LayoutOrder, Modifier (applied after the base style; for the host Frame).
	Horizontal: Size (1,0 / 0,1); Vertical: Size (0,1 / 1,0) — fill the parent along the line.
	Instances: ONE Frame when not inset; an inset divider is a transparent host Frame + UIPadding + the line Frame (3).
	The inset lives in padding (not Position) so the divider still works inside a UIListLayout.
]]

local q = require("./Quad")
local Theme = require("./Theme")
local Util = require("./Util")
local D = q.Declaration
local dividerName = D.Modifier.Frame():Name("Divider")

export type Props = {
	read Orientation: ("Horizontal" | "Vertical")?,
	read Inset: ("None" | "Start" | "Both")?,
	read LayoutOrder: number?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local InsetPx = 16
local horizontalBase = D.Modifier.Frame():Size(UDim2.new(1, 0, 0, 1)):BorderSizePixel(0)
local verticalBase = D.Modifier.Frame():Size(UDim2.new(0, 1, 1, 0)):BorderSizePixel(0)

local function Divider(props: Props?): Frame
	local p: Props = props or {}
	local theme = Theme.resolve(p.Theme)
	local vertical = p.Orientation == "Vertical"
	local inset = p.Inset or "None"
	local base = if vertical then verticalBase else horizontalBase

	if inset == "None" then
		return D.Frame {
			dividerName,
			base,
			p.Modifier or q.None,
			BackgroundColor3 = theme.Color.OutlineVariant,
			LayoutOrder = p.LayoutOrder,
			table.unpack(Util.hooks(p.Hooks)),
		}
	end

	local startPad = UDim.new(0, InsetPx)
	local endPad = if inset == "Both" then UDim.new(0, InsetPx) else UDim.new(0, 0)
	return D.Frame {
		dividerName,
		base,
		p.Modifier or q.None,
		BackgroundTransparency = 1,
		LayoutOrder = p.LayoutOrder,
		D.UIPadding {
			PaddingLeft = if vertical then UDim.new(0, 0) else startPad,
			PaddingRight = if vertical then UDim.new(0, 0) else endPad,
			PaddingTop = if vertical then startPad else UDim.new(0, 0),
			PaddingBottom = if vertical then endPad else UDim.new(0, 0),
		},
		D.Frame {
			Name = "Line",
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Color.OutlineVariant,
		},
		table.unpack(Util.hooks(p.Hooks)),
	}
end

return Divider
