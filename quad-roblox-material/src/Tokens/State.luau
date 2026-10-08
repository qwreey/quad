--!strict
--[[
	Material 3 state-layer opacities and disabled opacities (m3.material.io/foundations/interaction/states).

	A state layer is a rectangle of the component's "on" color at these opacities, laid over the container:
	  Hover .08   Focus .10   Pressed .10   Dragged .16   (+ ScrollBar .50 — a kit choice, not M3; see below)
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
	-- NOT an M3 token (the M3 token set has no scrollbar: material-components/material-web@763a973
	-- tokens/versions/latest/sass, 195 files, none for a scrollbar). The kit's ScrollingFrame thumbs are onSurface at this
	-- opacity — Compose Desktop's default scrollbar (JetBrains/compose-multiplatform-core@289cb59
	-- compose/foundation/foundation/src/skikoMain/kotlin/androidx/compose/foundation/Scrollbar.skiko.kt 105-111) is black
	-- at .12 at rest and .50 hovered; a Roblox thumb has no hover state, so the visible one (.50), with onSurface for
	-- black so it reads on a dark scheme too. Studio QA 2026-10-08 (9th): the engine default thumb is white — invisible
	-- on a light menu.
	ScrollBar = 0.50,
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
