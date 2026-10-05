--!strict
--[[
	Material 3 state-layer opacities and disabled opacities (m3.material.io/foundations/interaction/states).

	A state layer is a rectangle of the component's "on" color at these opacities, laid over the container:
	  Hover .08   Focus .10   Pressed .10   Dragged .16
	Disabled: container = onSurface at .12 opacity, content = onSurface at .38 opacity.
	When several states hold at once the layer shows the HIGHEST one (they do not add up) — `layerOpacity`.

	Pure numbers.
]]

local Opacity = {
	Hover = 0.08,
	Focus = 0.10,
	Pressed = 0.10,
	Dragged = 0.16,
	DisabledContainer = 0.12,
	DisabledContent = 0.38,
}

export type Flags = { Hovered: boolean?, Focused: boolean?, Pressed: boolean?, Dragged: boolean?, Disabled: boolean? }

-- The single state-layer opacity for a set of simultaneous states (0 when disabled or idle).
local function layerOpacity(f: Flags): number
	if f.Disabled == true then
		return 0
	end
	local o = 0
	if f.Hovered == true then
		o = math.max(o, Opacity.Hover)
	end
	if f.Focused == true then
		o = math.max(o, Opacity.Focus)
	end
	if f.Pressed == true then
		o = math.max(o, Opacity.Pressed)
	end
	if f.Dragged == true then
		o = math.max(o, Opacity.Dragged)
	end
	return o
end

return {
	Opacity = Opacity,
	layerOpacity = layerOpacity,
}
