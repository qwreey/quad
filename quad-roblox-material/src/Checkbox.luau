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
	and the dash is one Frame, so it needs no upload and tints with any theme role. (An `rbxassetid` check would cost
	one ImageLabel instead of two Frames but needs an asset the kit cannot ship; the Frame form is crisp at every scale.)

	Toggle motion (ported from qwreey MaterialUI's CheckBox — four edge bars, 0.15 s + 0.15 s linear): when the look
	(empty / check / dash) changes, four bars in the OLD look's outline color grow in to 40 % each from the INNER edge
	of the outline (a frame that FOLLOWS the swelling box: box - 2 * STROKE + 2 * OVERLAP, i.e. the stroke's inner edge
	overlapped by 1 px per side, so no empty ring opens between the swollen outline and the bars) while the outline
	swells 2 px per side; then the new look is swapped in under the bars, which shrink back in the NEW color —
	so a check appears from the middle outward and an uncheck folds the fill in. One Heartbeat connection while a change animates (0.3 s), none at rest; an interrupting change
	resumes from the current bar width. The mounted look is snapped (no motion at construction).

	Structure at rest: host TextButton > Target Frame (40 px, anchor center) > state layer (Frame + UICorner +
	UIStroke focus ring) + Box (Frame + UICorner(2) + UIStroke(2, Inner)) > CheckShort, CheckLong, Dash, Bars > 4 bars
	= 15 descendants (+1 Label TextLabel). A press adds a transient 4 (ripple).
	M3 deviations: none in size/shape; the mark animation is the bars motion above (M3 draws the check as a path).
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Interactive = require("./Interactive")
local Style = require("./Button/Style")
local ControlLabel = require("./ControlLabel")
local Frame = q.Elem "Frame"
local TextButton = q.Elem "TextButton"
local UIStroke = q.Elem "UIStroke"
local TextButtonModifier = q.Modifier "TextButton"
local checkboxName = TextButtonModifier():Name("Checkbox")

local RunService = game:GetService("RunService")


export type Props = {
	read Value: q.Source<boolean>?,
	read Checked: q.State<boolean>?,
	read Indeterminate: (boolean | q.State<boolean>)?,
	read Error: (boolean | q.State<boolean>)?,
	read Disabled: (boolean | q.State<boolean>)?,
	read OnChange: ((value: boolean) -> ())?,
	read Label: (string | q.State<string>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.ModifierInto<TextButton>?,
	read Hooks: Util.Hooks?,
}

local DisabledTransparency = Style.DisabledContentTransparency
local BOX = 18
local HALF = 0.15 -- each phase of the toggle motion (the original's 0.15 s, linear)
local CLOSE = 0.4 -- how far each bar grows in (fraction of the box)
local SWELL = 4 -- extra box size at the closed point (2 px per side) — only the outline/fill swells, not the bars
local STROKE = 2 -- outline thickness (Inner): the bars frame starts at its inner edge
local OVERLAP = 1 -- the bars frame reaches this far (per side) OVER the outline, so the swollen outline never leaves a gap

type Look = "none" | "check" | "dash"

local baseModifier = TextButtonModifier()
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

	-- filled look: checked OR indeterminate (the REAL value — the state layer follows it at once)
	local marked: q.State<boolean> = value:Compute(function(self, _prev, ind)
		return self:Get() or ind:Get()
	end, indeterminate)
	local look: q.State<Look> = value:Compute(function(self, _prev, ind): Look
		return if ind:Get() then "dash" elseif self:Get() then "check" else "none"
	end, indeterminate)

	-- the DISPLAYED look lags the real one by the first motion phase (see the header); `closing` 0..1 is the bars' phase
	local displayed = q.Source(look:Get())
	local closing = q.Source(0)
	local motion = q.Effect(function()
		local target = look:Get()
		if target == displayed:Get() and closing:Get() == 0 then
			return nil :: any
		end
		local t = closing:Get() * HALF -- an interrupted motion resumes from the current bar width
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function(dt: number)
			t += dt
			if t < HALF then
				closing:Set(t / HALF)
				return
			end
			displayed:SetIfChanged(target)
			local k = math.max(0, 1 - (t - HALF) / HALF)
			closing:Set(k)
			if k == 0 then
				conn:Disconnect()
			end
		end)
		return function()
			conn:Disconnect()
		end
	end, look)
	local shownMarked: q.State<boolean> = displayed:Compute(function(self)
		return self:Get() ~= "none"
	end)

	local accent: q.State<Color3> = isError:Compute(function(self, _prev, pri, err)
		return if self:Get() then err:Get() else pri:Get()
	end, R.Primary, R.Error)
	local onAccent: q.State<Color3> = isError:Compute(function(self, _prev, onPri, onErr)
		return if self:Get() then onErr:Get() else onPri:Get()
	end, R.OnPrimary, R.OnError)

	local fillRaw: q.State<Color3> = disabled:Compute(function(self, _prev, acc, onSurface)
		return if self:Get() then onSurface:Get() else acc:Get()
	end, accent, R.OnSurface)
	local fillTransparency: q.State<number> = shownMarked:Compute(function(self, _prev, dis)
		if not self:Get() then
			return 1
		end
		return if dis:Get() then DisabledTransparency else 0
	end, disabled)
	local strokeRaw: q.State<Color3> = shownMarked:Compute(function(self, _prev, dis, err, acc, onSurface, onSurfaceVariant, errColor)
		if dis:Get() then
			return onSurface:Get()
		elseif self:Get() then
			return acc:Get()
		elseif err:Get() then
			return errColor:Get()
		end
		return onSurfaceVariant:Get()
	end, disabled, isError, accent, R.OnSurface, R.OnSurfaceVariant, R.Error)
	-- disabled + marked: the 38 % fill already draws the box, so the 38 % outline on top of it would double up
	-- (M3 draws no outline on a selected box) — hide it
	local strokeTransparency: q.State<number> = disabled:Compute(function(self, _prev, marked)
		if not self:Get() then
			return 0
		end
		return if marked:Get() then 1 else DisabledTransparency
	end, shownMarked)
	local markRaw: q.State<Color3> = disabled:Compute(function(self, _prev, onAcc, surface)
		return if self:Get() then surface:Get() else onAcc:Get()
	end, onAccent, R.Surface)
	local checkTransparency: q.State<number> = displayed:Compute(function(self)
		return if self:Get() == "check" then 0 else 1
	end)
	local dashTransparency: q.State<number> = displayed:Compute(function(self)
		return if self:Get() == "dash" then 0 else 1
	end)
	local boxSize: q.State<UDim2> = closing:Compute(function(self)
		local n = BOX + SWELL * self:Get()
		return UDim2.fromOffset(n, n)
	end)
	-- bars frame = the box's inner edge grown by OVERLAP, tracking the swell (a fixed frame left a square gap ring)
	local barsSize: q.State<UDim2> = closing:Compute(function(self)
		local n = BOX + SWELL * self:Get() - 2 * STROKE + 2 * OVERLAP
		return UDim2.fromOffset(n, n)
	end)
	local barWidth: q.State<UDim2> = closing:Compute(function(self)
		return UDim2.fromScale(CLOSE * self:Get(), 1)
	end)
	local barHeight: q.State<UDim2> = closing:Compute(function(self)
		return UDim2.fromScale(1, CLOSE * self:Get())
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

	local function leg(name: string, size: UDim2, position: UDim2, rotation: number)
		return Frame {
			Name = name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = position,
			Size = size,
			Rotation = rotation,
			BackgroundColor3 = markColor,
			BackgroundTransparency = checkTransparency,
			BorderSizePixel = 0,
		}
	end

	-- one closing bar (inside the `Bars` frame, which is ZIndex 2 over the marks); color = the displayed look's outline color, not animated (the
	-- bars are zero-sized at rest, so a scheme change needs no cross-fade)
	local function bar(name: string, anchor: Vector2, size: q.State<UDim2>)
		return Frame {
			Name = name,
			AnchorPoint = anchor,
			Position = UDim2.fromScale(anchor.X, anchor.Y),
			Size = size,
			BackgroundColor3 = strokeRaw,
			BackgroundTransparency = strokeTransparency,
			BorderSizePixel = 0,
		}
	end

	local box = Frame {
		Name = "Box",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = boxSize,
		BackgroundColor3 = Style.animated(fillRaw),
		BackgroundTransparency = fillTransparency,
		BorderSizePixel = 0,
		UICorner = UDim.new(0, 2),
		UIStroke {
			Name = "Outline",
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			BorderStrokePosition = Enum.BorderStrokePosition.Inner,
			Thickness = STROKE,
			Color = Style.animated(strokeRaw),
			Transparency = strokeTransparency:Apply(Style.animation()),
		},
		-- check mark = short leg + long leg (rotated 2 px bars, integer pixel centers (5, 11) / (11, 9) in the 18 px box —
		-- placed from the CENTER so the swell of the motion keeps them still)
		leg("CheckShort", UDim2.fromOffset(6, 2), UDim2.new(0.5, -4, 0.5, 2), 45),
		leg("CheckLong", UDim2.fromOffset(11, 2), UDim2.new(0.5, 2, 0.5, 0), -45),
		Frame {
			Name = "Dash",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(10, 2),
			BackgroundColor3 = markColor,
			BackgroundTransparency = dashTransparency,
			BorderSizePixel = 0,
		},
		-- the bars live in a frame that tracks the box: its size is box - 2 * STROKE + 2 * OVERLAP, so it starts at the
		-- outline's inner edge and overlaps the stroke by OVERLAP px per side (no gap ring while the box swells).
		-- Corner safety: the frame's corner sits (STROKE - OVERLAP) = 1 px in from the box corner on both axes; the
		-- outer corner circle (UICorner 2) has its center 2 px in, so the point is sqrt(2) ~ 1.41 < 2 from the center —
		-- inside the rounded shape, nothing pokes out (holds at every swell: all offsets are relative to the box).
		-- Draw order of the bars (ZIndex 2 child) vs the UIStroke is not provable from code — Studio check: the bars
		-- should paint over the outline's inner 1 px. If a gap still shows, lower SWELL (memo only; value is the
		-- user's call after Studio) or raise OVERLAP.
		Frame {
			Name = "Bars",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = barsSize,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 2,
			bar("BarLeft", Vector2.new(0, 0), barWidth),
			bar("BarRight", Vector2.new(1, 0), barWidth),
			bar("BarTop", Vector2.new(0, 0), barHeight),
			bar("BarBottom", Vector2.new(0, 1), barHeight),
		},
	}
	local hasLabel = props.Label ~= nil

	return TextButton {
		checkboxName,
		baseModifier,
		if hasLabel then ControlLabel.host else q.None,
		props.Modifier or q.None,
		fx.Hook,
		motion,
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
		Frame {
			Name = "Target",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = if hasLabel then ControlLabel.TargetPosition else UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			fx.Layer,
			box,
		},
		if props.Label ~= nil then ControlLabel.new(props.Label, theme, disabled) else q.None,
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return Checkbox
