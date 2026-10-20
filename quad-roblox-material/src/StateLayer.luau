--!strict
--[[
	M3 state layer: ONE `Frame` laid over a component's container, in the component's "on" color, whose
	transparency follows hover / focus / pressed / dragged (opacities .08 / .10 / .10 / .16, the highest one
	wins — they do not add up; nothing shows while disabled). Optionally it also hosts the pressed ripple
	and the gamepad focus ring, so the whole interaction visual of a component is this single child.

	    q.Elem "TextButton" {
	        ...,                       -- container (rounded, has the same `Corner`)
	        StateLayer.new({ Color = theme.Color.OnPrimary, Corner = Shape.corner("Full"),
	                         Hovered = ix.Hovered, Pressed = ix.Pressed, Focused = ix.Focused }),
	        q.Elem "TextLabel" { ... },       -- content AFTER the layer (siblings draw in array order)
	    }
	Normally you do not call this directly — `Interactive.new` builds Interaction + StateLayer + Ripple
	together and returns the pieces to place.

	Rounding: the layer has its own `UICorner` equal to the host's, so it is exactly as rounded as the
	container without a `CanvasGroup` (the ripple inside it is the only clipped part — see Ripple.luau).

	opts
	  Color      Color3 | State<Color3>         the "on" color (e.g. OnPrimary for a filled button)
	  Corner     UDim | State<UDim>             the host's corner radius (default 0; a State follows an animated radius)
	  Hovered, Pressed, Focused   State<boolean>
	  Dragged    State<boolean>?                (sliders, handles)
	  Disabled   boolean | State<boolean>       layer hidden while true
	  Ripple     Ripple?                        when given, the PRESSED look is the ripple (Android style:
	                                            the static layer then shows at most hover/focus); when nil the
	                                            static layer shows the pressed .10 itself
	  FocusRing  Color3 | State<Color3>?        draw a 3 px outline 2 px outside the host while Focused
	                                            (the M3 focus indicator, for gamepad/keyboard selection)
	Timing: opacity changes tween with Motion Short2 / Standard (100 ms).
	Instances: 1 Frame + 1 UICorner + 1 UIStroke (when FocusRing) — the stroke is disabled, not absent,
	when unfocused.
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Ripple = require("./Ripple")
local Theme = require("./Theme")
local Util = require("./Util")
local Frame = q.Elem "Frame"
local UIStroke = q.Elem "UIStroke"

export type ColorInput = Color3 | Theme.Animated | q.State<Color3>

export type Options = {
	Color: ColorInput,
	Corner: Ripple.CornerInput?,
	Hovered: q.State<boolean>,
	Pressed: q.State<boolean>,
	Focused: q.State<boolean>,
	Dragged: q.State<boolean>?,
	Disabled: (boolean | q.State<boolean>)?,
	Ripple: Ripple.Ripple?,
	FocusRing: ColorInput?,
}

-- The layer's opacity as a State (0..0.16), before the 1 - x flip and the tween. Exposed for specs and for
-- components that draw their own layer.
local function opacityState(o: Options): q.State<number>
	local disabled = Util.asState(o.Disabled)
	local dragged = o.Dragged or q.Source(false)
	local hasRipple = o.Ripple ~= nil
	local result: q.State<number> = o.Hovered:Compute(function(self, _prev, pressed, focused, dis, drg)
		return Tokens.State.layerOpacity({
			Hovered = self:Get(),
			Pressed = (not hasRipple) and pressed:Get(),
			Focused = focused:Get(),
			Dragged = drg:Get(),
			Disabled = dis:Get(),
		})
	end, o.Pressed, o.Focused, disabled, dragged)
	return result
end

local function new(o: Options): Frame
	local opacity = opacityState(o)
	local transparency: q.State<number> = opacity:Compute(function(self)
		return 1 - self:Get()
	end)
	local anim = transparency:Apply(q.Animate(Tokens.Motion.options("Short2", "Standard")))

	local ring: Instance? = nil
	if o.FocusRing ~= nil then
		ring = UIStroke {
			Name = "FocusRing",
			Color = o.FocusRing,
			Thickness = 3,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			BorderStrokePosition = Enum.BorderStrokePosition.Outer,
			BorderOffset = UDim.new(0, 2),
			Enabled = o.Focused,
		}
	end

	return Frame {
		Name = "StateLayer",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = o.Color,
		BackgroundTransparency = anim,
		BorderSizePixel = 0,
		UICorner = o.Corner or UDim.new(0, 0),
		if o.Ripple then o.Ripple.Hook else q.None,
		if o.Ripple then o.Ripple.Slot else q.None,
		ring or q.None,
	}
end

return {
	new = new,
	opacityState = opacityState,
}
