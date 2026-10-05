--!strict
--[[
	TextField palette: the field's status (disabled > error > focused > hover > idle) and the four role colors derived
	from it. Each color is ONE animated State (`byStatus`), so a scheme switch and a status flip cross-fade together.
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Style = require("../Button/Style")
local Ctx = require("./Ctx")

type Palette = {
	Disabled: q.State<Color3>,
	Error: q.State<Color3>,
	Focused: q.State<Color3>,
	Hover: q.State<Color3>,
	Idle: q.State<Color3>,
}

local function byStatus(status: q.State<Ctx.Status>, p: Palette): Theme.Animated
	local picked: q.State<Color3> = status:Compute(function(self, _prev, dis, err, foc, hov, idle)
		local s = self:Get()
		if s == "disabled" then
			return dis:Get()
		elseif s == "error" then
			return err:Get()
		elseif s == "focused" then
			return foc:Get()
		elseif s == "hover" then
			return hov:Get()
		end
		return idle:Get()
	end, p.Disabled, p.Error, p.Focused, p.Hover, p.Idle)
	return picked:Apply(Style.animation())
end

-- the status State from the focus / hover / error / disabled States
local function status(
	focused: q.State<boolean>,
	hovered: q.State<boolean>,
	errorS: q.State<boolean>,
	disabled: q.State<boolean>
): q.State<Ctx.Status>
	return focused:Compute(function(self, _prev, hov, err, dis): Ctx.Status
		if dis:Get() then
			return "disabled"
		elseif err:Get() then
			return "error"
		elseif self:Get() then
			return "focused"
		elseif hov:Get() then
			return "hover"
		end
		return "idle"
	end, hovered, errorS, disabled)
end

local function colors(st: q.State<Ctx.Status>, theme: Theme.Theme, filled: boolean): Ctx.Colors
	local R = theme.Raw
	return {
		Label = byStatus(st, {
			Disabled = R.OnSurface,
			Error = R.Error,
			Focused = R.Primary,
			Hover = R.OnSurfaceVariant,
			Idle = R.OnSurfaceVariant,
		}),
		Line = byStatus(st, {
			Disabled = R.OnSurface,
			Error = R.Error,
			Focused = R.Primary,
			Hover = R.OnSurface,
			Idle = if filled then R.OnSurfaceVariant else R.Outline,
		}),
		Support = byStatus(st, {
			Disabled = R.OnSurface,
			Error = R.Error,
			Focused = R.OnSurfaceVariant,
			Hover = R.OnSurfaceVariant,
			Idle = R.OnSurfaceVariant,
		}),
		Trailing = byStatus(st, {
			Disabled = R.OnSurface,
			Error = R.Error,
			Focused = R.OnSurfaceVariant,
			Hover = R.OnSurfaceVariant,
			Idle = R.OnSurfaceVariant,
		}),
	}
end

return { status = status, colors = colors }
