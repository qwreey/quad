--!strict
--[[
	Interactive: the whole M3 interaction visual of a component in one call — hover/pressed/focus tracking
	(Interaction), the state layer, the pressed ripple and the gamepad focus ring.

	    local fx = Interactive.new({
	        Theme = props.Theme,
	        Disabled = props.Disabled,
	        OnColor = theme.Color.OnPrimary,        -- state layer + ripple color
	        Corner = Shape.corner("Full"),          -- must equal the host's UICorner
	    })
	    return q.Elem "TextButton" {
	        fx.Hook,                                -- 1. wires input (array part)
	        fx.Layer,                               -- 2. the state layer Frame (array part; BEFORE the content)
	        q.Elem "TextLabel" { ... },                    -- 3. content, drawn above the layer
	        Activated = props.OnClick,
	        UICorner = fx.Corner,
	    }
	  .Hovered/.Pressed/.Focused  State<boolean>   for extra component logic (e.g. raise elevation on hover)
	  .CancelPress()               end the press as cancelled (the ripple fades; OnRelease(true)) — an ancestor's drag took
	                               the pointer over (Interaction.luau)
	  .Corner                      the UDim you passed (convenience for `UICorner = fx.Corner`)
	Interactive.noSelectionImage() -> Frame   the shared invisible SelectionImageObject (for hosts that wire their
	  own Interaction instead of `fx.Hook`; never parent it)
	PLACEMENT: `fx.Layer` must be a DIRECT child of the host and the host must carry no UIPadding / UIListLayout
	(put those on an inner Content frame) — see Button/init.luau.

	opts
	  Theme       Theme?                  (default theme when nil) — used for the focus ring color (Secondary)
	  Disabled    boolean | State<boolean>
	  OnColor     Color3 | State<Color3>  the component's "on" color
	  Corner      UDim                    the host's corner radius
	  Ripple      boolean?                default true; false = static pressed layer only (no CanvasGroup ever)
	  FocusRing   boolean?                default true (gamepad/keyboard selection outline)
	  Dragged     State<boolean>?         passthrough to the state layer
	  OnPress     (position: Vector2?) -> ()?  extra callback at press start (after the ripple started)
	  OnRelease   (cancelled: boolean) -> ()?

	The HOST must also hide the engine's default selection box, otherwise gamepad focus shows two outlines;
	`fx.Hook` does that for you (it assigns a shared invisible `SelectionImageObject`).

	Cost at rest, no ripple running: Layer Frame + UICorner + UIStroke = 3 instances (see Ripple.luau for
	the transient per-press cost).
]]

local q = require("./Quad")
local Interaction = require("./Interaction")
local Ripple = require("./Ripple")
local StateLayer = require("./StateLayer")
local Theme = require("./Theme")
local Frame = q.Elem "Frame"

export type Options = {
	Theme: Theme.Theme?,
	Disabled: (boolean | q.State<boolean>)?,
	OnColor: StateLayer.ColorInput,
	Corner: UDim?,
	Ripple: boolean?,
	FocusRing: boolean?,
	Dragged: q.State<boolean>?,
	OnPress: ((position: Vector2?) -> ())?,
	OnRelease: ((cancelled: boolean) -> ())?,
}

export type Interactive = {
	read Hook: Interaction.Hook,
	read Layer: Frame,
	read Hovered: q.State<boolean>,
	read Pressed: q.State<boolean>,
	read Focused: q.State<boolean>,
	read Corner: UDim,
	read CancelPress: () -> (),
}

-- One invisible selection image for every host: assigning it as `SelectionImageObject` replaces the engine's
-- default white selection box (the M3 focus ring is the StateLayer's UIStroke instead). It is never parented.
local hiddenSelection: Frame? = nil
local function noSelectionImage(): Frame
	if hiddenSelection == nil then
		hiddenSelection = Frame {
			Name = "NoSelectionImage",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}
	end
	return hiddenSelection :: Frame
end

local function new(o: Options): Interactive
	local theme = Theme.resolve(o.Theme)
	local corner = o.Corner or UDim.new(0, 0)
	local useRipple = o.Ripple ~= false

	local ripple: Ripple.Ripple? = nil
	if useRipple then
		ripple = Ripple.new({ Color = o.OnColor, Corner = corner })
	end

	local ix = Interaction.new({
		Disabled = o.Disabled,
		OnHost = function(inst: GuiObject)
			inst.SelectionImageObject = noSelectionImage()
		end,
		OnPressBegan = function(position: Vector2?)
			if ripple then
				ripple:Press(position)
			end
			if o.OnPress then
				o.OnPress(position)
			end
		end,
		OnPressEnded = function(cancelled: boolean)
			if ripple then
				ripple:Release()
			end
			if o.OnRelease then
				o.OnRelease(cancelled)
			end
		end,
	})

	local layer = StateLayer.new({
		Color = o.OnColor,
		Corner = corner,
		Hovered = ix.Hovered,
		Pressed = ix.Pressed,
		Focused = ix.Focused,
		Dragged = o.Dragged,
		Disabled = o.Disabled,
		Ripple = ripple,
		FocusRing = if o.FocusRing == false then nil else theme.Color.Secondary,
	})

	return {
		Hook = ix.Hook,
		Layer = layer,
		Hovered = ix.Hovered,
		Pressed = ix.Pressed,
		Focused = ix.Focused,
		Corner = corner,
		CancelPress = ix.CancelPress,
	}
end

return {
	new = new,
	noSelectionImage = noSelectionImage,
}
