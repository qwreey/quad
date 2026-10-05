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

	Look: 20 px outer ring (2 px outline, `OnSurfaceVariant` -> `Primary` when selected), 10 px inner dot (`Primary`)
	that scales 0 -> 10 px with a Motion Short4/Standard `q.Animate` on its Size, 40 px state layer + ripple.
	Structure at rest: host > Target Frame (40) > state layer (3) + Ring (Frame + UICorner + UIStroke) + Dot
	(Frame + UICorner) = 9 descendants.

	RadioGroup props: Value, Options (`{ { Option: T, Label: string, Disabled: (boolean | State<boolean>)? } }`, fixed at
	construction), Direction ("Vertical" default | "Horizontal"), Disabled, Error, OnChange, Theme, Modifier
	(Frame Modifier), Hooks. Each row is a Frame with a Radio and a clickable BodyLarge label (a non-selectable
	TextButton, so gamepad focus stops once per row). It builds one Radio per option — for a dynamic option list
	build the rows yourself with `Slot:List` and plain `Radio`s.
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Interactive = require("./Interactive")
local Style = require("./Button/Style")
local Text = require("./Text")
local D = q.Declaration


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
	local dotRaw: q.State<Color3> = disabled:Compute(function(self, _prev, acc, onSurface)
		return if self:Get() then onSurface:Get() else acc:Get()
	end, accent, R.OnSurface)
	local contentTransparency: q.State<number> = disabled:Compute(function(self)
		return if self:Get() then DisabledTransparency else 0
	end)
	local layerRaw: q.State<Color3> = selected:Compute(function(self, _prev, err, errColor, pri, onSurface)
		if err:Get() then
			return errColor:Get()
		end
		return if self:Get() then pri:Get() else onSurface:Get()
	end, isError, R.Error, R.Primary, R.OnSurface)
	local dotSize: q.State<UDim2> = selected:Compute(function(self)
		return if self:Get() then UDim2.fromOffset(10, 10) else UDim2.fromOffset(0, 0)
	end)
	local interactable: q.State<boolean> = Util.interactable(disabled)

	local fx = Interactive.new({
		Theme = theme,
		Disabled = disabled,
		OnColor = Style.animated(layerRaw),
		Corner = corner,
	})

	local tint = contentTransparency:Apply(Style.animation())

	return D.TextButton {
		Name = "Radio",
		baseModifier,
		props.Modifier or q.None,
		fx.Hook,
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
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			fx.Layer,
			D.Frame {
				Name = "Ring",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(20, 20),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				UICorner = corner,
				D.UIStroke {
					Name = "Outline",
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					BorderStrokePosition = Enum.BorderStrokePosition.Inner,
					Thickness = 2,
					Color = Style.animated(ringRaw),
					Transparency = tint,
				},
			},
			D.Frame {
				Name = "Dot",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				-- first write snaps (an initially selected radio mounts with the dot), later changes tween
				Size = dotSize:Apply(q.Animate(Tokens.Motion.options("Short4", "Standard"))),
				BackgroundColor3 = Style.animated(dotRaw),
				BackgroundTransparency = tint,
				BorderSizePixel = 0,
				UICorner = corner,
			},
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
end

local rowLabelStyle = Text.Button("BodyLarge")
local baseGroup = D.Modifier.Frame():Size(UDim2.fromOffset(0, 0)):AutomaticSize(Enum.AutomaticSize.XY):BackgroundTransparency(1):BorderSizePixel(0)

local function RadioGroup<T>(props: GroupProps<T>)
	local theme = Theme.resolve(props.Theme)
	local rawValue: any = props.Value -- see ValueSource
	local groupValue = rawValue :: q.Source<T>
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
		local option = opt.Option
		local labelTint = Style.disabledNumber(optDisabled, 0, Style.DisabledContentTransparency)
		table.insert(
			rows,
			D.Frame {
				Name = "Row",
				Size = UDim2.fromOffset(0, 48),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = i,
				D.UIListLayout {
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
				},
				Radio<<T>>({
					Value = props.Value,
					Option = option,
					Error = props.Error,
					Disabled = optDisabled,
					OnChange = props.OnChange,
					Theme = theme,
				}),
				D.TextButton {
					Name = "Label",
					rowLabelStyle,
					Size = UDim2.fromOffset(0, 48),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Selectable = false,
					Text = opt.Label,
					TextColor3 = theme.Color.OnSurface,
					TextTransparency = labelTint,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 2,
					D.UIPadding { PaddingRight = UDim.new(0, 16) },
					Activated = function()
						if Util.peekBool(optDisabled) or groupValue:Get() == option then
							return
						end
						groupValue:Set(option)
						if props.OnChange then
							props.OnChange(option)
						end
					end,
				},
			}
		)
	end

	return D.Frame {
		Name = "RadioGroup",
		baseGroup,
		props.Modifier or q.None,
		D.UIListLayout {
			FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		q.Slot<<Instance>>(rows),
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return {
	Radio = Radio,
	RadioGroup = RadioGroup,
}
