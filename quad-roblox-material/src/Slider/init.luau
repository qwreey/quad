--!strict
--[[
	M3 slider (the 2022 "classic" form): 4 px active/inactive track, 20 px circular handle with a 40 px state layer,
	a value-label bubble above the handle while dragging or focused, tick marks for discrete sliders.

	    local volume = q.Source(30)
	    Slider({ Value = volume, Min = 0, Max = 100 })                                   -- continuous
	    Slider({ Value = level, Min = 0, Max = 10, Step = 1, OnChangeEnd = save })        -- discrete, with ticks
	    Slider({ Value = x, Min = 0, Max = 1, Format = function(v) return string.format("%d%%", v * 100) end })

	Design choice (documented, as the brief asked): the CLASSIC M3 slider (4 px track, 20 px round handle, teardrop-less
	pill value label) is built, not the 2023/expressive one (16 px track with 4x44 bar handle and track gaps) — the
	expressive form needs the track split into pieces around the handle and rounded inner ends, i.e. more
	instances and a per-move relayout, for a look the classic handle already conveys.

	Props (all `read`):
	  Value        Source<number>?           two-way: the handle follows it; dragging / keys write it (`:Set`, only when
	                                         the snapped value changed). nil = the slider keeps its own, starting at Min.
	  Min, Max     number?                   default 0 / 1; STATIC (fixed at construction); Max must be > Min.
	  Step         number?                   nil = continuous. A Step snaps every written value to Min + n*Step and
	                                         shows ticks (`ShowTicks`, default true up to 100 steps).
	  ShowTicks    boolean?
	  KeyStep      number?                   arrow-key increment; default Step, or (Max - Min) / 20
	  Format       ((value: number) -> string)?  label text; default: integers plain, else up to 2 decimals
	  ShowLabel    boolean?                  default true
	  Disabled     boolean | State<boolean>? active onSurface@38 %, inactive onSurface@12 %, no input, not selectable
	  OnChange     ((value: number) -> ())?  after each USER change (drag move, key), only when the value changed
	  OnChangeEnd  ((value: number) -> ())?  on pointer release, and after each key adjust. NOT on a cancelled drag
	                                         (window focus lost, slider destroyed)
	  Theme, Modifier, Hooks                 as Button; Modifier = Frame Modifier, applied after the base (default size
	                                         `UDim2.new(1, 0, 0, 40)` — width comes from the parent, height is the 40 px
	                                         handle halo)
	Returns the host `Frame`.

	Geometry: the rail spans the host minus 10 px on both sides (the handle radius), so the handle CENTER travels
	from the rail start to its end and never leaves the host. Pressing anywhere on the host jumps the value to the
	pointer and continues as a drag (`Interaction.drag`: three `UserInputService` connections, only while dragging,
	closed on release / focus loss / destroy). Drag and keys never animate the handle; only colors tween.
	The pointer maps with `AbsolutePosition`/`AbsoluteSize` read at event time (never at construction).

	Keyboard / gamepad: the host is `Selectable`; the shared `KeyNav` hook keeps ONE `UserInputService.InputBegan` connection
	while it holds selection (`SelectionGained` .. `SelectionLost` / Destroying): Left arrow and DPadLeft = -KeyStep,
	Right arrow and DPadRight = +KeyStep, PageDown/PageUp = +-10 KeyStep, Home/End = Min/Max. NextSelectionLeft/Right
	point at the host so the horizontal D-pad adjusts the value instead of moving selection away; Up/Down are NOT mapped
	and NOT pinned, so they still walk the gamepad selection to the neighbouring control (a pinned axis is a D-pad trap).
	The engine marks nav keys `processed` while a control holds selection, so `processed` is deliberately not consulted
	(a focused TextBox does suppress the keys — see KeyNav).

	Parts: `Ticks.luau` (the tick frames), `Bubble.luau` (the value label), shared `../KeyNav.luau` (keys).
	Label bubble: a pill (28 px, `Primary`, `LabelMedium` in `OnPrimary`) 4 px above the handle; it extends outside the
	host, so an ancestor with `ClipsDescendants` (a ScrollingFrame) clips it — give the slider room above it there.
	Structure at rest (continuous): host > Rail > Inactive + Active (each Frame + UICorner), Halo > state layer (3) +
	Handle (Frame + UICorner) + Label (TextLabel + UICorner + UIPadding) = 14 descendants; discrete adds one 2 px
	Frame per tick (Step + 1).
	M3 deviations: hover lights the halo anywhere over the host, not only over the handle; no teardrop indicator shape;
	Min/Max/Step are static; inactive-track color is `SurfaceVariant`.
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Interactive = require("./Interactive")
local Interaction = require("./Interaction")
local Ripple = require("./Ripple")
local Style = require("./Button/Style")
local Ticks = require("@self/Ticks")
local Bubble = require("@self/Bubble")
local KeyNav = require("./KeyNav")
local D = q.Declaration


export type Props = {
	read Value: q.Source<number>?,
	read Min: number?,
	read Max: number?,
	read Step: number?,
	read ShowTicks: boolean?,
	read KeyStep: number?,
	read Format: ((value: number) -> string)?,
	read ShowLabel: boolean?,
	read Disabled: (boolean | q.State<boolean>)?,
	read OnChange: ((value: number) -> ())?,
	read OnChangeEnd: ((value: number) -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local INSET = 10 -- handle radius: rail margin on both sides

local baseModifier = D.Modifier.Frame():Size(UDim2.new(1, 0, 0, 40)):BackgroundTransparency(1):BorderSizePixel(0)

local function defaultFormat(v: number): string
	if v == math.floor(v) then
		return string.format("%d", v)
	end
	local s = string.format("%.2f", v)
	s = string.gsub(s, "0+$", "")
	return s
end

local function Slider(props: Props)
	local theme = Theme.resolve(props.Theme)
	local R = theme.Raw
	local min: number = props.Min or 0
	local max: number = props.Max or 1
	if not (max > min) then
		error("Slider: Max must be greater than Min", 2)
	end
	local range = max - min
	local step = props.Step
	if step ~= nil and not (step > 0) then
		error("Slider: Step must be positive", 2)
	end
	local keyStep: number = props.KeyStep or step or range / 20
	local value: q.Source<number> = props.Value or q.Source(min)
	local disabled = Util.asState(props.Disabled)
	local format = props.Format or defaultFormat
	local corner = Tokens.Shape.corner("Full")

	local function snap(v: number): number
		v = math.clamp(v, min, max)
		if step ~= nil then
			v = math.clamp(min + math.floor((v - min) / step + 0.5) * step, min, max)
		end
		return v
	end

	-- the one write path for user input (drag + keys): snapped, only when changed
	local function commit(raw: number): boolean
		local v = snap(raw)
		if v == value:Get() then
			return false
		end
		value:Set(v)
		if props.OnChange then
			props.OnChange(v)
		end
		return true
	end

	local frac: q.State<number> = value:Compute(function(self)
		return math.clamp((self:Get() - min) / range, 0, 1)
	end)

	local host: GuiObject? = nil
	local function commitFromX(x: number)
		local h = host
		if h == nil then
			return
		end
		local width = h.AbsoluteSize.X - 2 * INSET
		if width <= 0 then
			return
		end
		local f = (x - Ripple.Config.PointerInset.X - h.AbsolutePosition.X - INSET) / width
		commit(min + f * range)
	end

	local drag = Interaction.drag({
		Disabled = disabled,
		OnBegan = commitFromX,
		OnMoved = function(x: number)
			commitFromX(x)
		end,
		OnEnded = function(x: number, _y: number, cancelled: boolean)
			if not cancelled then
				commitFromX(x)
				if props.OnChangeEnd then
					props.OnChangeEnd(value:Get())
				end
			end
		end,
	})

	local fx = Interactive.new({
		Theme = theme,
		Disabled = disabled,
		OnColor = theme.Color.Primary,
		Corner = corner,
		Ripple = false,
		Dragged = drag.Dragging,
	})

	-- keys: the shared KeyNav hook delivers them (one InputBegan connection while the host holds selection); the keymap
	-- is Left/Right (+ D-pad), PageUp/PageDown, Home/End — Up/Down are neither mapped nor pinned
	local function onKey(input: InputObject)
		if Util.peekBool(disabled) then
			return
		end
		local kc = input.KeyCode
		local cur = value:Get()
		local target: number? = nil
		if kc == Enum.KeyCode.Left or kc == Enum.KeyCode.DPadLeft then
			target = cur - keyStep
		elseif kc == Enum.KeyCode.Right or kc == Enum.KeyCode.DPadRight then
			target = cur + keyStep
		elseif kc == Enum.KeyCode.PageDown then
			target = cur - 10 * keyStep
		elseif kc == Enum.KeyCode.PageUp then
			target = cur + 10 * keyStep
		elseif kc == Enum.KeyCode.Home then
			target = min
		elseif kc == Enum.KeyCode.End then
			target = max
		end
		if target ~= nil and commit(target) and props.OnChangeEnd then
			props.OnChangeEnd(value:Get())
		end
	end
	local keys = KeyNav.hook(onKey)
	local hostHook = Util.preHook(function(inst)
		host = inst
		inst.Destroying:Connect(function()
			host = nil
		end)
	end)

	-- colors
	local activeRaw: q.State<Color3> = disabled:Compute(function(self, _prev, pri, onSurface)
		return if self:Get() then onSurface:Get() else pri:Get()
	end, R.Primary, R.OnSurface)
	local activeTransparency: q.State<number> = disabled:Compute(function(self)
		return if self:Get() then Style.DisabledContentTransparency else 0
	end)
	local inactiveRaw: q.State<Color3> = disabled:Compute(function(self, _prev, variant, onSurface)
		return if self:Get() then onSurface:Get() else variant:Get()
	end, R.SurfaceVariant, R.OnSurface)
	local inactiveTransparency: q.State<number> = disabled:Compute(function(self)
		return if self:Get() then Style.DisabledContainerTransparency else 0
	end)
	local activeColor = Style.animated(activeRaw)
	local activeT = activeTransparency:Apply(Style.animation())

	local ticks = Ticks.build({ Frac = frac, Range = range, Step = step, ShowTicks = props.ShowTicks, Disabled = disabled, Theme = theme })

	local label: Instance? = nil
	if props.ShowLabel ~= false then
		label = Bubble.build({
			Dragging = drag.Dragging,
			Focused = fx.Focused,
			Disabled = disabled,
			Value = value,
			Format = format,
			Theme = theme,
			Inset = INSET,
			Corner = corner,
		})
	end

	local interactable: q.State<boolean> = Util.interactable(disabled)
	local barHeight = 4
	local activeSize: q.State<UDim2> = frac:Compute(function(self)
		return UDim2.new(self:Get(), 0, 0, barHeight)
	end)
	local haloPosition: q.State<UDim2> = frac:Compute(function(self)
		return UDim2.fromScale(self:Get(), 0.5)
	end)

	return D.Frame {
		Name = "Slider",
		baseModifier,
		props.Modifier or q.None,
		fx.Hook,
		drag.Hook,
		hostHook,
		keys,
		Interactable = interactable,
		Selectable = interactable,
		D.Frame {
			Name = "Rail",
			Position = UDim2.fromOffset(INSET, 0),
			Size = UDim2.new(1, -2 * INSET, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.Frame {
				Name = "Inactive",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.new(1, 0, 0, barHeight),
				BackgroundColor3 = Style.animated(inactiveRaw),
				BackgroundTransparency = inactiveTransparency:Apply(Style.animation()),
				BorderSizePixel = 0,
				UICorner = corner,
			},
			D.Frame {
				Name = "Active",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = activeSize,
				BackgroundColor3 = activeColor,
				BackgroundTransparency = activeT,
				BorderSizePixel = 0,
				UICorner = corner,
			},
			q.Slot<<Instance>>(ticks),
			D.Frame {
				Name = "Halo",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = haloPosition,
				Size = UDim2.fromOffset(40, 40),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				fx.Layer,
				D.Frame {
					Name = "Handle",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(20, 20),
					BackgroundColor3 = activeColor,
					BackgroundTransparency = activeT,
					BorderSizePixel = 0,
					UICorner = corner,
				},
				label or q.None,
			},
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return Slider
