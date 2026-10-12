--!strict
--[[
	M3 switch: 52x32 pill track, a handle that grows 16 (off) -> 24 (on / has icon) -> 28 (pressed; off: 24) and slides
	between the two ends, optional icons on the handle.

	    Switch({ Value = enabled })
	    Switch({ Value = sound, IconOn = "rbxassetid://1", IconOff = "rbxassetid://2", OnChange = apply })
	    Switch({ Checked = isDark, OnChange = function(v) theme:SetScheme(if v then "Dark" else "Light") end })   -- controlled

	The M2 look (thin track, round handle that overhangs it) is `Material.M2.Switch` (`../M2/Switch.luau`) — same props,
	same behaviour: both build on `./Behavior.luau` (on/off model, tap, handle drag), this file only draws.

	Props (all `read`):
	  Value     Source<boolean>?           on/off, two-way (a tap or drag writes it); nil = own state
	  Checked   State<boolean>?            the CONTROLLED alternative to `Value` (see Checkbox): displayed only, a toggle
	                                       calls `OnChange(new)` and writes nothing. `Value` and `Checked` together is an error.
	  IconOn    string?                    handle icon while on  (16 px; asset id — the kit ships no icon assets)
	  IconOff   string?                    handle icon while off; giving either icon makes the OFF handle 24 px
	  Disabled  boolean | State<boolean>?  track onSurface@12 %, handle onSurface@38 % (on: Surface), no layer
	  OnChange  ((value: boolean) -> ())?  after a USER toggle (tap, or a drag released past the half)
	  Theme, Modifier, Hooks               as Button (Modifier = TextButton Modifier, applied after the base)
	Returns the host `TextButton` — the 52x32 track.

	Colors: track off `SurfaceContainerHighest` + 2 px `Outline`, on `Primary` (outline merges into the fill);
	handle off `Outline` (hover/press `OnSurfaceVariant`), on `OnPrimary` (hover/press `PrimaryContainer`); state
	layer 40 px circle around the HANDLE (`OnSurface` off / `Primary` on).
	Motion: handle position Medium2/Emphasized, size Short4/Emphasized, colors Short4/Standard.
	Drag (`Behavior.luau` header): past a 4 px slop the handle follows the pointer over its 20 px travel (no tween) and
	stays at the pressed size; released past the half it lands on the other state, else springs back (animated from the
	pointer). A tap toggles as before.
	Structure at rest: track + UICorner + UIStroke, Halo Frame (40 px, follows the handle) > state layer (3) +
	Handle (Frame + UICorner) [+ Icon ImageLabel] = 8 descendants (9 with an icon).
	M3 deviations: the touch target is the 52x32 track (M3 asks for 48 px height); extra hit height would cost one
	more Frame, so it is not done here — give the Switch a row with enough height instead; the handle has no
	squish-while-moving stage; hover on the TRACK lights the halo (M3 lights it over the handle only); the pressed
	handle of an OFF switch grows to 24 px (26 with icons), not 28 — 28 would fill the outline's inside exactly.
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Interactive = require("./Interactive")
local Style = require("./Button/Style")
local Behavior = require("@self/Behavior")
local D = q.Declaration
local switchName = D.Modifier.TextButton():Name("Switch")

export type Props = Behavior.Props

local TRACK_W, TRACK_H = 52, 32
local OFF_X, ON_X = 16, 36 -- handle centers
local DisabledContent = Style.DisabledContentTransparency
local DisabledContainer = Style.DisabledContainerTransparency

local baseModifier = D.Modifier.TextButton()
	:Size(UDim2.fromOffset(TRACK_W, TRACK_H))
	:BorderSizePixel(0)
	:AutoButtonColor(false)
	:Text("")

local function Switch(props: Props)
	local theme = Theme.resolve(props.Theme)
	local R = theme.Raw
	local s = Behavior.new(props, { Name = "Switch", Travel = ON_X - OFF_X })
	local on, disabled = s.On, s.Disabled
	local corner = Tokens.Shape.corner("Full")
	local hasIcon = props.IconOn ~= nil or props.IconOff ~= nil

	-- state layer follows the handle: onSurface off, primary on
	local layerRaw: q.State<Color3> = on:Compute(function(self, _prev, pri, onSurface)
		return if self:Get() then pri:Get() else onSurface:Get()
	end, R.Primary, R.OnSurface)
	local fx = Interactive.new({
		Theme = theme,
		Disabled = disabled,
		OnColor = Style.animated(layerRaw),
		Corner = corner,
	})

	-- track
	local trackRaw: q.State<Color3> = on:Compute(function(self, _prev, dis, pri, highest, onSurface)
		if dis:Get() then
			return if self:Get() then onSurface:Get() else highest:Get()
		end
		return if self:Get() then pri:Get() else highest:Get()
	end, disabled, R.Primary, R.SurfaceContainerHighest, R.OnSurface)
	local trackTransparency: q.State<number> = disabled:Compute(function(self)
		return if self:Get() then DisabledContainer else 0
	end)
	local outlineRaw: q.State<Color3> = on:Compute(function(self, _prev, dis, pri, outline, onSurface)
		if dis:Get() then
			return onSurface:Get()
		end
		return if self:Get() then pri:Get() else outline:Get()
	end, disabled, R.Primary, R.Outline, R.OnSurface)
	local outlineTransparency: q.State<number> = on:Compute(function(self, _prev, dis)
		if dis:Get() then
			return if self:Get() then 1 else DisabledContainer
		end
		return 0
	end, disabled)

	-- handle: a moved drag counts as pressed (the pointer may leave the track, which ends the engine press)
	local held: q.State<boolean> = fx.Pressed:Compute(function(self, _prev, dragging)
		return self:Get() or dragging:Get()
	end, s.Dragging)
	local handleRaw: q.State<Color3> = on:Compute(
		function(self, _prev, dis, hovered, pressed, outline, onSurfaceVariant, onPrimary, primaryContainer, onSurface, surface)
			local sel = self:Get()
			if dis:Get() then
				return if sel then surface:Get() else onSurface:Get()
			end
			local active = hovered:Get() or pressed:Get()
			if sel then
				return if active then primaryContainer:Get() else onPrimary:Get()
			end
			return if active then onSurfaceVariant:Get() else outline:Get()
		end,
		disabled,
		fx.Hovered,
		held,
		R.Outline,
		R.OnSurfaceVariant,
		R.OnPrimary,
		R.PrimaryContainer,
		R.OnSurface,
		R.Surface
	)
	local handleTransparency: q.State<number> = on:Compute(function(self, _prev, dis)
		return if dis:Get() and not self:Get() then DisabledContent else 0
	end, disabled)
	-- pressed: 28 when ON (inside the filled track); when OFF only to 24 (26 with icons): the off track has a 2 px INNER
	-- outline, so its inside is exactly 28 px and a 28 px handle would touch the outline in a near-identical color
	-- (Outline vs OnSurfaceVariant) — kit deviation from M3's 28 dp pressed handle in both states
	local handleSize: q.State<UDim2> = on:Compute(function(self, _prev, pressed)
		local sel = self:Get()
		local px
		if pressed:Get() then
			px = if sel then 28 elseif hasIcon then 26 else 24
		else
			px = if sel or hasIcon then 24 else 16
		end
		return UDim2.fromOffset(px, px)
	end, held)
	-- the end of the current state, or the pointer while dragged (no tween then — `CanAnimate`)
	local haloPosition: q.State<UDim2> = on:Compute(function(self, _prev, drag)
		local f = drag:Get()
		local x = if f ~= nil then OFF_X + (ON_X - OFF_X) * f elseif self:Get() then ON_X else OFF_X
		return UDim2.fromOffset(x, TRACK_H / 2)
	end, s.DragFrac)
	local slide = Tokens.Motion.options("Medium2", "Emphasized")
	local haloAnimated = haloPosition:Apply(q.Animate({
		Time = slide.Time,
		Style = slide.Style,
		Direction = slide.Direction,
		CanAnimate = Util.negate(s.Dragging),
	}))

	local icon: Instance? = nil
	if hasIcon then
		local iconImage: q.State<string> = on:Compute(function(self)
			return (if self:Get() then props.IconOn else props.IconOff) or ""
		end)
		local iconRaw: q.State<Color3> = on:Compute(function(self, _prev, dis, onContainer, highest, onSurface)
			if dis:Get() then
				return if self:Get() then onSurface:Get() else highest:Get()
			end
			return if self:Get() then onContainer:Get() else highest:Get()
		end, disabled, R.OnPrimaryContainer, R.SurfaceContainerHighest, R.OnSurface)
		local iconTransparency: q.State<number> = disabled:Compute(function(self)
			return if self:Get() then DisabledContent else 0
		end)
		icon = D.ImageLabel {
			Name = "Icon",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = iconImage,
			ImageColor3 = Style.animated(iconRaw),
			ImageTransparency = iconTransparency:Apply(Style.animation()),
		}
	end

	return D.TextButton {
		switchName,
		baseModifier,
		props.Modifier or q.None,
		fx.Hook,
		s.DragHook,
		BackgroundColor3 = Style.animated(trackRaw),
		BackgroundTransparency = trackTransparency:Apply(Style.animation()),
		Interactable = s.Interactable,
		Activated = s.Activated,
		UICorner = corner,
		D.UIStroke {
			Name = "Outline",
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			BorderStrokePosition = Enum.BorderStrokePosition.Inner,
			Thickness = 2,
			Color = Style.animated(outlineRaw),
			Transparency = outlineTransparency:Apply(Style.animation()),
		},
		D.Frame {
			Name = "Halo",
			AnchorPoint = Vector2.new(0.5, 0.5),
			-- mounted snapped at the current end, later flips slide; a drag moves it directly
			Position = haloAnimated,
			Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			fx.Layer,
			D.Frame {
				Name = "Handle",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = handleSize:Apply(q.Animate(Tokens.Motion.options("Short4", "Emphasized"))),
				BackgroundColor3 = Style.animated(handleRaw),
				BackgroundTransparency = handleTransparency:Apply(Style.animation()),
				BorderSizePixel = 0,
				UICorner = corner,
				icon or q.None,
			},
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return Switch
