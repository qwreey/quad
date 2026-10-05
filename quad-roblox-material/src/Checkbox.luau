--!strict
--[[
	M3 checkbox: 18 px box, 2 px outline, filled with `Primary` when checked (check mark) or indeterminate (dash),
	a 40 px circular state layer + ripple around the box, and a 48x48 hit target.

	    Checkbox({ Value = agreed, OnChange = function(v) print(v) end })
	    Checkbox({ Value = parentChecked, Indeterminate = someChildrenChecked })     -- tri-state
	    Checkbox({ Value = ok, Error = hasError, Disabled = busy })
	    Checkbox({ Checked = isOn, OnChange = function(v) store.Set(v) end })          -- controlled form

	Props (all `read`):
	  Value          Source<boolean>?          the checked state, two-way: the component reads it and the user
	                                           click writes it (`Source:Set`). nil = the checkbox keeps its own.
	  Checked        State<boolean>?           the CONTROLLED alternative to `Value`: a read-only State the component only
	                                           displays; a user click never writes anything — it calls `OnChange(new)` and the
	                                           owner decides (derive Checked from the real state, write it in OnChange).
	                                           Passing both `Value` and `Checked` is an error.
	  Indeterminate  boolean | State<boolean>? shows the dash instead of the check (the box is "filled"). The
	                                           component never clears it itself — a click while indeterminate
	                                           sets Value = true (the M3 parent-checkbox behavior) and the owner
	                                           clears Indeterminate in `OnChange`.
	  Error          boolean | State<boolean>? error roles (outline / fill / state layer in `Error`)
	  Disabled       boolean | State<boolean>? onSurface@38 %, no state layer, `Interactable = false`
	  OnChange       ((value: boolean) -> ())?  after a USER toggle (not on programmatic Value writes); with `Checked` it is
	                                           the only effect of a click
	  Theme, Modifier, Hooks                   as Button (Modifier = TextButton Modifier, applied last; Hooks: array-part values)
	Returns the host `TextButton` (48x48, transparent).

	The check mark has NO image asset: it is two rotated 2 px Frames (the short and the long leg, 45 deg / -45 deg)
	and the dash is one Frame, so it needs no upload, tints with any theme role and fades with the same tween as
	the box. (An `rbxassetid` check would cost one ImageLabel instead of two Frames but needs an asset the kit
	cannot ship; the Frame form is crisp at every scale.)

	Structure at rest: host TextButton > Target Frame (40 px, anchor center) > state layer (Frame + UICorner +
	UIStroke focus ring) + Box (Frame + UICorner(2) + UIStroke(2, Inner)) > CheckShort, CheckLong, Dash
	= 10 descendants. A press adds a transient 4 (ripple).
	M3 deviations: none in size/shape; mark animation is a 100 ms fade (M3 draws the check as a path).
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
	read Indeterminate: (boolean | q.State<boolean>)?,
	read Error: (boolean | q.State<boolean>)?,
	read Disabled: (boolean | q.State<boolean>)?,
	read OnChange: ((value: boolean) -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.TextButtonModifier?,
	read Hooks: Util.Hooks?,
}

local DisabledTransparency = Style.DisabledContentTransparency

local baseModifier = D.Modifier.TextButton()
	:Size(UDim2.fromOffset(48, 48))
	:BackgroundTransparency(1)
	:BorderSizePixel(0)
	:AutoButtonColor(false)
	:Text("")

local function Checkbox(props: Props)
	local theme = Theme.resolve(props.Theme)
	local R = theme.Raw
	if props.Value ~= nil and props.Checked ~= nil then
		error("Checkbox: pass `Value` (two-way Source) or `Checked` (controlled State), not both", 2)
	end
	-- `own` is written by a click; the controlled form (`Checked`) has none: the owner writes in OnChange
	local own: q.Source<boolean>? = props.Value or (if props.Checked == nil then q.Source(false) else nil)
	local value: q.State<boolean> = props.Checked or own :: q.Source<boolean>
	local disabled = Util.asState(props.Disabled)
	local isError = Util.asState(props.Error)
	local indeterminate = Util.asState(props.Indeterminate)
	local corner = Tokens.Shape.corner("Full")

	-- filled look: checked OR indeterminate
	local marked: q.State<boolean> = value:Compute(function(self, _prev, ind)
		return self:Get() or ind:Get()
	end, indeterminate)

	local accent: q.State<Color3> = isError:Compute(function(self, _prev, pri, err)
		return if self:Get() then err:Get() else pri:Get()
	end, R.Primary, R.Error)
	local onAccent: q.State<Color3> = isError:Compute(function(self, _prev, onPri, onErr)
		return if self:Get() then onErr:Get() else onPri:Get()
	end, R.OnPrimary, R.OnError)

	local fillRaw: q.State<Color3> = disabled:Compute(function(self, _prev, acc, onSurface)
		return if self:Get() then onSurface:Get() else acc:Get()
	end, accent, R.OnSurface)
	local fillTransparency: q.State<number> = marked:Compute(function(self, _prev, dis)
		if not self:Get() then
			return 1
		end
		return if dis:Get() then DisabledTransparency else 0
	end, disabled)
	local strokeRaw: q.State<Color3> = marked:Compute(function(self, _prev, dis, err, acc, onSurface, onSurfaceVariant, errColor)
		if dis:Get() then
			return onSurface:Get()
		elseif self:Get() then
			return acc:Get()
		elseif err:Get() then
			return errColor:Get()
		end
		return onSurfaceVariant:Get()
	end, disabled, isError, accent, R.OnSurface, R.OnSurfaceVariant, R.Error)
	local strokeTransparency: q.State<number> = disabled:Compute(function(self)
		return if self:Get() then DisabledTransparency else 0
	end)
	local markRaw: q.State<Color3> = disabled:Compute(function(self, _prev, onAcc, surface)
		return if self:Get() then surface:Get() else onAcc:Get()
	end, onAccent, R.Surface)
	local checkTransparency: q.State<number> = value:Compute(function(self, _prev, ind)
		return if self:Get() and not ind:Get() then 0 else 1
	end, indeterminate)
	local dashTransparency: q.State<number> = indeterminate:Compute(function(self)
		return if self:Get() then 0 else 1
	end)
	-- state layer: error > checked (primary) > onSurface
	local layerRaw: q.State<Color3> = marked:Compute(function(self, _prev, err, errColor, pri, onSurface)
		if err:Get() then
			return errColor:Get()
		end
		return if self:Get() then pri:Get() else onSurface:Get()
	end, isError, R.Error, R.Primary, R.OnSurface)

	local interactable: q.State<boolean> = Util.interactable(disabled)

	local fx = Interactive.new({
		Theme = theme,
		Disabled = disabled,
		OnColor = Style.animated(layerRaw),
		Corner = corner,
	})

	local markColor = Style.animated(markRaw)
	local checkT = checkTransparency:Apply(Style.animation())
	local dashT = dashTransparency:Apply(Style.animation())

	local function leg(name: string, size: UDim2, position: UDim2, rotation: number)
		return D.Frame {
			Name = name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = position,
			Size = size,
			Rotation = rotation,
			BackgroundColor3 = markColor,
			BackgroundTransparency = checkT,
			BorderSizePixel = 0,
		}
	end

	local box = D.Frame {
		Name = "Box",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = Style.animated(fillRaw),
		BackgroundTransparency = fillTransparency:Apply(Style.animation()),
		BorderSizePixel = 0,
		UICorner = UDim.new(0, 2),
		D.UIStroke {
			Name = "Outline",
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			BorderStrokePosition = Enum.BorderStrokePosition.Inner,
			Thickness = 2,
			Color = Style.animated(strokeRaw),
			Transparency = strokeTransparency:Apply(Style.animation()),
		},
		-- check mark = short leg + long leg (rotated 2 px bars, integer pixel centers in the 18 px box)
		leg("CheckShort", UDim2.fromOffset(6, 2), UDim2.fromOffset(5, 11), 45),
		leg("CheckLong", UDim2.fromOffset(11, 2), UDim2.fromOffset(11, 9), -45),
		D.Frame {
			Name = "Dash",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(10, 2),
			BackgroundColor3 = markColor,
			BackgroundTransparency = dashT,
			BorderSizePixel = 0,
		},
	}

	return D.TextButton {
		Name = "Checkbox",
		baseModifier,
		props.Modifier or q.None,
		fx.Hook,
		Interactable = interactable,
		Activated = function()
			if Util.peekBool(disabled) then
				return
			end
			local nextValue = if Util.peekBool(indeterminate) then true else not value:Get()
			if own ~= nil then
				own:Set(nextValue)
			end
			if props.OnChange then
				props.OnChange(nextValue)
			end
		end,
		D.Frame {
			Name = "Target",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			fx.Layer,
			box,
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return Checkbox
