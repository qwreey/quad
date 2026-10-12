--!strict
--[[
	M2 switch (`Material.M2.Switch`) — the Material 2 look: a thin 36 x 14 track (radius 7) and a 20 px round thumb with
	a level-1 shadow that is WIDER than the track (it overhangs the track top and bottom), sliding 16 px; a 40 px halo
	(state layer + ripple) around the thumb. Same props and behaviour as the M3 `Switch` — both build on
	`../Switch/Behavior.luau` (on/off model, tap toggle, handle drag); this file only draws.

	    M2.Switch({ Value = wifi })
	    M2.Switch({ Checked = isDark, OnChange = apply })

	Props: `SwitchBehavior.Props` (Value, Checked, Disabled, OnChange, Theme, Modifier = TextButton Modifier, Hooks).
	`IconOn` / `IconOff` are accepted (shared props) and IGNORED — M2 thumbs carry no icon.
	Returns the host `TextButton` ("M2Switch"), 56 x 40 and transparent.

	BOUNDED: the host is the whole drawn box, not the track — thumb centers at x = 20 (off) and 36 (on), y = 20, so the
	40 px halo spans x 0..40 / 16..56 and y 0..40, the thumb 10..30 / 26..46, the track 10..46 x 13..27. Nothing
	reaches outside the host, so an `AutomaticSize` ancestor measures the switch at exactly 56 x 40 (`Ripple.luau`
	"BOUNDED" — every descendant counts, clipped or not). The thumb overhangs only the TRACK.
	Colors (M2 roles mapped onto the theme): on — thumb `Primary`, track `Primary` @ 50 %; off — thumb a near-white
	(light: `Surface`; dark: `Surface` 70 % toward `OnSurface`, the M2 #BDBDBD), track `OnSurface` @ 38 %; disabled —
	thumb `Surface` 38 % (light) / 25 % (dark) toward `OnSurface` (on: toward `Primary`), opaque, track `OnSurface` @ 12 %.
	Halo color `Primary` on / `OnSurface` off. Motion: thumb Short4 / Standard (M2's 150 ms-ish), colors Short4.
	Drag: as the M3 Switch over the 16 px travel (past a 4 px slop the thumb follows the pointer; released past the half
	it lands on the other state, else springs back; a tap toggles).
	Structure at rest: Track (Frame + UICorner), Halo (Frame) > state layer (3) + Thumb (Frame + UICorner + UIShadow) =
	9 descendants.
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Util = require("../Util")
local Interactive = require("../Interactive")
local Elevation = require("../Elevation")
local Style = require("../Button/Style")
local Behavior = require("../Switch/Behavior")
local D = q.Declaration
local switchName = D.Modifier.TextButton():Name("M2Switch")

export type Props = Behavior.Props

local W, H = 56, 40
local OFF_X, ON_X = 20, 36 -- thumb centers
local THUMB = 20
local TRACK_W, TRACK_H = 36, 14

local baseModifier = D.Modifier.TextButton()
	:Size(UDim2.fromOffset(W, H))
	:BackgroundTransparency(1)
	:BorderSizePixel(0)
	:AutoButtonColor(false)
	:Text("")

local function Switch(props: Props)
	local theme = Theme.resolve(props.Theme)
	local R = theme.Raw
	local s = Behavior.new(props, { Name = "M2.Switch", Travel = ON_X - OFF_X })
	local on, disabled = s.On, s.Disabled
	local corner = Tokens.Shape.corner("Full")

	local layerRaw: q.State<Color3> = on:Compute(function(self, _prev, pri, onSurface)
		return if self:Get() then pri:Get() else onSurface:Get()
	end, R.Primary, R.OnSurface)
	local fx = Interactive.new({
		Theme = theme,
		Disabled = disabled,
		OnColor = Style.animated(layerRaw),
		Corner = corner,
	})

	local trackRaw: q.State<Color3> = on:Compute(function(self, _prev, dis, pri, onSurface)
		return if self:Get() and not dis:Get() then pri:Get() else onSurface:Get()
	end, disabled, R.Primary, R.OnSurface)
	local trackTransparency: q.State<number> = on:Compute(function(self, _prev, dis)
		if dis:Get() then
			return Style.DisabledContainerTransparency
		end
		return if self:Get() then 0.5 else Style.DisabledContentTransparency
	end, disabled)

	local thumbRaw: q.State<Color3> = on:Compute(function(self, _prev, dis, scheme, pri, surface, onSurface)
		local dark = scheme:Get() == "dark"
		if dis:Get() then
			local toward = if self:Get() then pri:Get() else onSurface:Get()
			return surface:Get():Lerp(toward, if dark then 0.25 else 0.38)
		end
		if self:Get() then
			return pri:Get()
		end
		return if dark then surface:Get():Lerp(onSurface:Get(), 0.7) else surface:Get()
	end, disabled, theme.Scheme, R.Primary, R.Surface, R.OnSurface)

	-- the end of the current state, or the pointer while dragged (no tween then)
	local haloPosition: q.State<UDim2> = on:Compute(function(self, _prev, drag)
		local f = drag:Get()
		local x = if f ~= nil then OFF_X + (ON_X - OFF_X) * f elseif self:Get() then ON_X else OFF_X
		return UDim2.fromOffset(x, H / 2)
	end, s.DragFrac)
	local slide = Tokens.Motion.options("Short4", "Standard")

	return D.TextButton {
		switchName,
		baseModifier,
		props.Modifier or q.None,
		fx.Hook,
		s.DragHook,
		Interactable = s.Interactable,
		Activated = s.Activated,
		D.Frame {
			Name = "Track",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset((OFF_X + ON_X) / 2, H / 2), -- 28 = W / 2
			Size = UDim2.fromOffset(TRACK_W, TRACK_H),
			BackgroundColor3 = Style.animated(trackRaw),
			BackgroundTransparency = trackTransparency:Apply(Style.animation()),
			BorderSizePixel = 0,
			UICorner = corner,
		},
		D.Frame {
			Name = "Halo",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = haloPosition:Apply(q.Animate({
				Time = slide.Time,
				Style = slide.Style,
				Direction = slide.Direction,
				CanAnimate = Util.negate(s.Dragging),
			})),
			Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			fx.Layer,
			D.Frame {
				Name = "Thumb",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(THUMB, THUMB),
				BackgroundColor3 = Style.animated(thumbRaw),
				BorderSizePixel = 0,
				UICorner = corner,
				Elevation.Shadow({ Level = 1, Theme = theme }),
			},
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return Switch
