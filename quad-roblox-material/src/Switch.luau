--!strict
--[[
	M3 switch: 52x32 pill track, a handle that grows 16 (off) -> 24 (on / has icon) -> 28 (pressed) and slides
	between the two ends, optional icons on the handle.

	    Switch({ Value = enabled })
	    Switch({ Value = sound, IconOn = "rbxassetid://1", IconOff = "rbxassetid://2", OnChange = apply })
	    Switch({ Checked = isDark, OnChange = function(v) theme:SetScheme(if v then "Dark" else "Light") end })   -- controlled

	Props (all `read`):
	  Value     Source<boolean>?           on/off, two-way (click writes `Value:Set(not Value)`); nil = own state
	  Checked   State<boolean>?            the CONTROLLED alternative to `Value` (see Checkbox): displayed only, a click calls
	                                       `OnChange(new)` and writes nothing. `Value` and `Checked` together is an error.
	  IconOn    string?                    handle icon while on  (16 px; asset id — the kit ships no icon assets)
	  IconOff   string?                    handle icon while off; giving either icon makes the OFF handle 24 px
	  Disabled  boolean | State<boolean>?  track onSurface@12 %, handle onSurface@38 % (on: Surface), no layer
	  OnChange  ((value: boolean) -> ())?  after a USER toggle
	  Theme, Modifier, Hooks               as Button (Modifier = TextButton Modifier, applied after the base)
	Returns the host `TextButton` — the 52x32 track.

	Colors: track off `SurfaceContainerHighest` + 2 px `Outline`, on `Primary` (outline merges into the fill);
	handle off `Outline` (hover/press `OnSurfaceVariant`), on `OnPrimary` (hover/press `PrimaryContainer`); state
	layer 40 px circle around the HANDLE (`OnSurface` off / `Primary` on).
	Motion: handle position Medium2/Emphasized, size Short4/Emphasized, colors Short4/Standard.
	Structure at rest: track + UICorner + UIStroke, Halo Frame (40 px, follows the handle) > state layer (3) +
	Handle (Frame + UICorner) [+ Icon ImageLabel] = 8 descendants (9 with an icon).
	M3 deviations: the touch target is the 52x32 track (M3 asks for 48 px height); extra hit height would cost one
	more Frame, so it is not done here — give the Switch a row with enough height instead; the handle has no
	squish-while-moving stage; hover on the TRACK lights the halo (M3 lights it over the handle only).
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Interactive = require("./Interactive")
local Style = require("./Button/Style")
local D = q.Declaration


export type Props = {
	read Value: q.Source<boolean>?,
	read Checked: q.State<boolean>?,
	read IconOn: string?,
	read IconOff: string?,
	read Disabled: (boolean | q.State<boolean>)?,
	read OnChange: ((value: boolean) -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.TextButtonModifier?,
	read Hooks: Util.Hooks?,
}

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
	if props.Value ~= nil and props.Checked ~= nil then
		error("Switch: pass `Value` (two-way Source) or `Checked` (controlled State), not both", 2)
	end
	local own: q.Source<boolean>? = props.Value or (if props.Checked == nil then q.Source(false) else nil)
	local on: q.State<boolean> = props.Checked or own :: q.Source<boolean>
	local disabled = Util.asState(props.Disabled)
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

	-- handle
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
		fx.Pressed,
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
	local handleSize: q.State<UDim2> = on:Compute(function(self, _prev, pressed)
		local px = if pressed:Get() then 28 elseif self:Get() or hasIcon then 24 else 16
		return UDim2.fromOffset(px, px)
	end, fx.Pressed)
	local haloPosition: q.State<UDim2> = on:Compute(function(self)
		return UDim2.fromOffset(if self:Get() then ON_X else OFF_X, TRACK_H / 2)
	end)

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

	local interactable: q.State<boolean> = Util.interactable(disabled)

	return D.TextButton {
		Name = "Switch",
		baseModifier,
		props.Modifier or q.None,
		fx.Hook,
		BackgroundColor3 = Style.animated(trackRaw),
		BackgroundTransparency = trackTransparency:Apply(Style.animation()),
		Interactable = interactable,
		Activated = function()
			if Util.peekBool(disabled) then
				return
			end
			local nextValue = not on:Get()
			if own ~= nil then
				own:Set(nextValue)
			end
			if props.OnChange then
				props.OnChange(nextValue)
			end
		end,
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
			-- mounted snapped at the current end, later flips slide
			Position = haloPosition:Apply(q.Animate(Tokens.Motion.options("Medium2", "Emphasized"))),
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
