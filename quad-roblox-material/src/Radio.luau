--!strict
--[[
	M3 radio button (`Radio`) and a convenience column/row of them (`RadioGroup`).

	    local choice = q.Source("a")
	    Radio({ Value = choice, Option = "a" })
	    Radio({ Value = choice, Option = "b", OnChange = function(v) print(v) end })
	    RadioGroup({ Value = choice, Options = { { Option = "a", Label = "Alpha" }, { Option = "b", Label = "Beta" } } })

	Radio props (all `read`):
	  Value     Source<T>                 the selected option of the group, two-way: selected = (Value == Option);
	                                      a click writes `Value:Set(Option)` (a click on the selected radio is a no-op,
	                                      as in M3 a radio cannot be unselected by the user)
	  Option    T                         the option of this radio (compared with `==`)
	  Error / Disabled  boolean | State<boolean>?   as Checkbox
	  OnChange  ((option: T) -> ())?      after a USER selection (not on programmatic Value writes)
	  Theme, Modifier, Hooks              as Button
	Returns the host `TextButton` (48x48, transparent).

	Look: the ring + dot come from qwreey MaterialUI's sprite sheet (one ImageLabel `Sprite`, 10 frames of 40 px shown at
	20 px; frames step 0 -> 9 in 0.2 s on selection, reversed on deselection, tinted `OnSurfaceVariant` / `Primary` /
	`Error`), 40 px state layer + ripple. Structure at rest: host > Target Frame (40) > state layer (3) + Sprite = 5
	descendants (+1 Label TextLabel). (The header described the earlier Ring + Dot Frames until 2026-10-07.)

	RadioGroup props: Value, Options (`{ { Option: T, Label: string, Disabled: (boolean | State<boolean>)? } }`, fixed at
	construction), Direction ("Vertical" default | "Horizontal"), Disabled, Error, OnChange, Theme, Modifier
	(Frame Modifier), Hooks. Each row is a Radio with its `Label` (one host per row: the text hovers / clicks with the
	radio and gamepad focus stops once per row). It builds one Radio per option — for a dynamic option list
	build the rows yourself with `Slot:List` and plain `Radio`s.
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Interactive = require("./Interactive")
local Style = require("./Button/Style")
local ControlLabel = require("./ControlLabel")
local D = q.Declaration
local groupName = D.Modifier.Frame():Name("RadioGroup")
local radioName = D.Modifier.TextButton():Name("Radio")

local RunService = game:GetService("RunService")


-- KIT WORKAROUND for a quad typing limit (kit feedback A1): the fields below MIRROR quad's phantom fields
-- (`__quadState`, `__quadStateValue`) so a `Source<T>` is accepted structurally. Delete this alias and take
-- `q.Source<T>` directly once strict can instantiate a generic parameter from a Source.
-- `q.Source<T>` cannot be a generic parameter type (strict: "No valid instantiation could be inferred for generic
-- type parameter T ... at least string | nil, at most string" even for `local v = q.Source("a")`), so the public
-- Props take this structural stand-in: a Source of T seen through read-only `Get`/`Set` with `self: never`
-- (which new-solver variance accepts). Checks T against Option / OnChange; passing a non-Source fails.
export type ValueSource<T> = {
	read __quadState: true,
	read __quadStateValue: T,
	read Get: (self: never) -> T,
	read Set: (self: never, value: T) -> any,
}

export type Props<T> = {
	read Value: ValueSource<T>,
	read Option: T,
	read Error: (boolean | q.State<boolean>)?,
	read Disabled: (boolean | q.State<boolean>)?,
	read OnChange: ((option: T) -> ())?,
	read Label: (string | q.State<string>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.TextButtonModifier?,
	read Hooks: Util.Hooks?,
}

export type GroupOption<T> = { read Option: T, read Label: string, read Disabled: (boolean | q.State<boolean>)? }

export type GroupProps<T> = {
	read Value: ValueSource<T>,
	read Options: { GroupOption<T> },
	read Direction: ("Vertical" | "Horizontal")?,
	read Error: (boolean | q.State<boolean>)?,
	read Disabled: (boolean | q.State<boolean>)?,
	read OnChange: ((option: T) -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local DisabledTransparency = Style.DisabledContentTransparency
local SPRITE = "rbxassetid://4667411351"
local FRAME = 40 -- px per frame in the sheet
local LAST = 9 -- frames 0..9
local STEP_TIME = 0.2 -- the whole 0 -> 9 run (the original's 0.2 s, linear)

local baseModifier = D.Modifier.TextButton()
	:Size(UDim2.fromOffset(48, 48))
	:BackgroundTransparency(1)
	:BorderSizePixel(0)
	:AutoButtonColor(false)
	:Text("")

local function Radio<T>(props: Props<T>)
	local theme = Theme.resolve(props.Theme)
	local R = theme.Raw
	local rawValue: any = props.Value -- see ValueSource
	local value = rawValue :: q.Source<T>
	local option = props.Option
	local disabled = Util.asState(props.Disabled)
	local isError = Util.asState(props.Error)
	local corner = Tokens.Shape.corner("Full")

	local selected: q.State<boolean> = value:Compute(function(self)
		return self:Get() == option
	end)

	local accent: q.State<Color3> = isError:Compute(function(self, _prev, pri, err)
		return if self:Get() then err:Get() else pri:Get()
	end, R.Primary, R.Error)
	-- ring + dot: disabled onSurface@38 %; selected accent; unselected onSurfaceVariant (error -> Error)
	local ringRaw: q.State<Color3> = selected:Compute(function(self, _prev, dis, err, acc, onSurface, onSurfaceVariant, errColor)
		if dis:Get() then
			return onSurface:Get()
		elseif self:Get() then
			return acc:Get()
		elseif err:Get() then
			return errColor:Get()
		end
		return onSurfaceVariant:Get()
	end, disabled, isError, accent, R.OnSurface, R.OnSurfaceVariant, R.Error)
	local contentTransparency: q.State<number> = disabled:Compute(function(self)
		return if self:Get() then DisabledTransparency else 0
	end)
	local layerRaw: q.State<Color3> = selected:Compute(function(self, _prev, err, errColor, pri, onSurface)
		if err:Get() then
			return errColor:Get()
		end
		return if self:Get() then pri:Get() else onSurface:Get()
	end, isError, R.Error, R.Primary, R.OnSurface)

	-- sprite frame: snapped at mount, then stepped toward 0 / LAST while `selected` differs (a reversal mid-way
	-- continues from the current frame)
	local frame = q.Source(if selected:Get() then LAST else 0)
	local stepper = q.Effect(function()
		local goal = if selected:Get() then LAST else 0
		if frame:Get() == goal then
			return nil :: any
		end
		local pos = frame:Get()
		local dir = if goal > pos then 1 else -1
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function(dt: number)
			pos += dir * dt * LAST / STEP_TIME
			if (dir == 1 and pos >= goal) or (dir == -1 and pos <= goal) then
				pos = goal
				conn:Disconnect()
			end
			frame:SetIfChanged(if dir == 1 then math.floor(pos) else math.ceil(pos))
		end)
		return function()
			conn:Disconnect()
		end
	end, selected)
	local rectOffset: q.State<Vector2> = frame:Compute(function(self)
		return Vector2.new(FRAME * self:Get(), 0)
	end)
	local interactable: q.State<boolean> = Util.interactable(disabled)

	local fx = Interactive.new({
		Theme = theme,
		Disabled = disabled,
		OnColor = Style.animated(layerRaw),
		Corner = corner,
	})

	local tint = contentTransparency:Apply(Style.animation())

	local hasLabel = props.Label ~= nil
	return D.TextButton {
		radioName,
		baseModifier,
		if hasLabel then ControlLabel.host else q.None,
		props.Modifier or q.None,
		fx.Hook,
		stepper,
		Interactable = interactable,
		Activated = function()
			if Util.peekBool(disabled) or value:Get() == option then
				return
			end
			value:Set(option)
			if props.OnChange then
				props.OnChange(option)
			end
		end,
		D.Frame {
			Name = "Target",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = if hasLabel then ControlLabel.TargetPosition else UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			fx.Layer,
			D.ImageLabel {
				Name = "Sprite",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(20, 20),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = SPRITE,
				ImageRectSize = Vector2.new(FRAME, FRAME),
				ImageRectOffset = rectOffset,
				ImageColor3 = Style.animated(ringRaw),
				ImageTransparency = tint,
			},
		},
		if props.Label ~= nil then ControlLabel.new(props.Label, theme, disabled) else q.None,
		table.unpack(Util.hooks(props.Hooks)),
	}
end

local baseGroup = D.Modifier.Frame():Size(UDim2.fromOffset(0, 0)):AutomaticSize(Enum.AutomaticSize.XY):BackgroundTransparency(1):BorderSizePixel(0)

local function RadioGroup<T>(props: GroupProps<T>)
	local theme = Theme.resolve(props.Theme)
	local horizontal = props.Direction == "Horizontal"
	local groupDisabled = Util.asState(props.Disabled)
	local rows: { Instance } = {}

	for i, opt in props.Options do
		local optDisabled: q.State<boolean> = groupDisabled
		if opt.Disabled ~= nil then
			-- an option is disabled when the group is OR its own flag is
			optDisabled = groupDisabled:Compute(function(self, _prev, own)
				return self:Get() or own:Get()
			end, Util.asState(opt.Disabled))
		end
		-- one host per row: the label is the radio's own `Label` (hover + click on the text act on the radio)
		table.insert(
			rows,
			Radio<<T>>({
				Value = props.Value,
				Option = opt.Option,
				Label = opt.Label,
				Error = props.Error,
				Disabled = optDisabled,
				OnChange = props.OnChange,
				Theme = theme,
				Modifier = D.Modifier.TextButton():LayoutOrder(i),
			})
		)
	end

	return D.Frame {
		groupName,
		baseGroup,
		props.Modifier or q.None,
		D.UIListLayout {
			FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			-- side by side, a gap between one row's text and the next radio (a column needs none)
			Padding = UDim.new(0, if horizontal then 16 else 0),
		},
		q.Slot<<Instance>>(rows),
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return {
	Radio = Radio,
	RadioGroup = RadioGroup,
}
