--!strict
--[[
	Runtime info window — live counters of the demo itself.

		FPS        1 / mean Heartbeat dt over the last 0.5 s (a `Clock.ticker`, so no per-frame work)
		Instances  descendants of `Target` (one GetChildren walk, once per second)
		Overlay    popups currently open (`Overlay.Count`)
		Version    `q.Version`

	`Target` is a function so the count can follow whatever root the host mounted (Demo.mount passes the ScreenGui).
	Both tickers are gated on the window's `Open` Source and `Collapsed` (no Heartbeat connection while it is closed or collapsed) and die with the window.
]]

local Devui = require("./Kit")
local Context = require("./Context")
local Clock = require("./Clock")
local q = require("../Quad")

type Context = Context.Context

local Kids = Devui.Kids

export type RuntimeInfoProps = {
	read Context: Context,
	read Target: (() -> Instance?)?,
	read Open: q.Source<boolean>?,
	read Position: q.Source<UDim2>?,
	read Size: q.Source<Vector2>?,
	read Manager: Devui.Manager?,
}

local function countDescendants(root: Instance): number
	local n = 0
	for _, child in root:GetChildren() do
		n += 1 + countDescendants(child)
	end
	return n
end

local function RuntimeInfoWindow(props: RuntimeInfoProps): Frame
	local ctx = props.Context
	local style = ctx.Style
	local target = props.Target
	local open: q.Source<boolean> = props.Open or q.Source(true)
	local collapsed: q.Source<boolean> = q.Source(false)
	local active: q.State<boolean> = open:Compute(function(self, _prev, isCollapsed)
		return self:Get() and not isCollapsed:Get()
	end, collapsed)
	local fps = q.Source(0)
	local instances = q.Source(0)

	local fpsTicker = Clock.ticker(0.5, function(elapsed: number)
		fps:Set(math.floor(1 / math.max(elapsed, 1e-3) + 0.5))
	end, active)
	local countTicker = Clock.ticker(1, function()
		local root = if target then target() else nil
		instances:Set(if root then countDescendants(root) else 0)
	end, active)

	local fpsText: q.State<string> = fps:Compute(function(self)
		return tostring(self:Get())
	end)
	local instText: q.State<string> = instances:Compute(function(self)
		return tostring(self:Get())
	end)
	local popupText: q.State<string> = ctx.Overlay.Count:Compute(function(self)
		return tostring(self:Get())
	end)

	return Devui.Window({
		Title = "Runtime Info",
		Style = style,
		Open = open,
		Collapsed = collapsed,
		Position = props.Position or q.Source(UDim2.fromOffset(520, 500)),
		Size = props.Size or q.Source(Vector2.new(260, 150)),
		Manager = props.Manager,
		Children = Kids(
			fpsTicker,
			countTicker,
			Devui.LabelText({ Label = "frames / s (Heartbeat)", Text = fpsText, Style = style }),
			Devui.LabelText({ Label = "demo instances", Text = instText, Style = style }),
			Devui.LabelText({ Label = "open popups", Text = popupText, Style = style }),
			Devui.LabelText({ Label = "quad version", Text = q.Version, Style = style })
		),
	})
end

return RuntimeInfoWindow
