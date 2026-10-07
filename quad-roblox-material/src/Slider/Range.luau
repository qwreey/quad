--!strict
--[[
	M3 range slider: the classic Slider (4 px track, 20 px handles, value-label bubbles, ticks) with TWO handles — the
	active track runs between them (m3.material.io/components/sliders: "range slider").

	    local lo, hi = q.Source(20), q.Source(80)
	    RangeSlider({ Start = lo, End = hi, Min = 0, Max = 100 })                           -- continuous
	    RangeSlider({ Start = lo, End = hi, Min = 0, Max = 10, Step = 1, OnChangeEnd = save })  -- discrete, ticks

	Props (all `read`):
	  Start, End   Source<number>?           two-way, like Slider `Value`; nil = own Sources starting at Min / Max.
	                                         Start <= End is kept by user input (a handle stops at the other one; the two may
	                                         meet). A programmatic Start > End is shown as given (the active track is empty).
	  Min, Max, Step, ShowTicks, KeyStep, Format, ShowLabel, Disabled, Theme, Modifier, Hooks   as Slider
	  OnChange     ((startValue: number, endValue: number) -> ())?  after each USER change (drag move, key)
	  OnChangeEnd  ((startValue: number, endValue: number) -> ())?  on pointer release and after each key adjust (not on
	                                         a cancelled drag)
	Returns the host `Frame` (default size `UDim2.new(1, 0, 0, 40)`, like Slider).

	Pointer: a press anywhere on the host grabs the NEAREST handle (equal distance — the handles meet — picks by the side
	of the press) and drags it; a handle stops at the other. A drag that BEGINS on a closed range (both handles on one
	value) takes its handle from the first movement (right -> End, left -> Start), so a closed range can always be reopened.
	Hover lights the halo of the handle nearest the pointer (`MouseMoved`), the dragged handle shows the dragged layer and
	its label bubble.
	Keyboard / gamepad: the host is ONE selection stop (like Slider, `KeyNav` "Horizontal" pin): Left/Right (+ D-pad),
	PageUp/PageDown, Home/End move the KEY handle — the one last dragged, Start at first; Return / KeypadEnter / gamepad
	ButtonX switch the key handle to the other one. The focus ring and the label bubble are on the key handle.
	Structure at rest (continuous): host > Rail > Inactive + Active (each Frame + UICorner), two Halos (`HaloStart`,
	`HaloEnd`) > state layer (3) + Handle (Frame + UICorner) + Label (TextLabel + UICorner + UIPadding) = 23 descendants;
	discrete adds one 2 px Frame per tick (Step + 1), active between the handles.
	M3 deviations: as Slider (classic form, static Min/Max/Step); no minimum distance between the handles; both handles
	share one selection stop (M3 web focuses each thumb separately — a second stop would need its own D-pad pin).
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Util = require("../Util")
local Interaction = require("../Interaction")
local Interactive = require("../Interactive")
local StateLayer = require("../StateLayer")
local Ripple = require("../Ripple")
local Style = require("../Button/Style")
local KeyNav = require("../KeyNav")
local Ticks = require("./Ticks")
local Bubble = require("./Bubble")
local D = q.Declaration

export type Props = {
	read Start: q.Source<number>?,
	read End: q.Source<number>?,
	read Min: number?,
	read Max: number?,
	read Step: number?,
	read ShowTicks: boolean?,
	read KeyStep: number?,
	read Format: ((value: number) -> string)?,
	read ShowLabel: boolean?,
	read Disabled: (boolean | q.State<boolean>)?,
	read OnChange: ((startValue: number, endValue: number) -> ())?,
	read OnChangeEnd: ((startValue: number, endValue: number) -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

type Which = "Start" | "End"

local INSET = 10 -- handle radius: rail margin on both sides (as Slider)

local baseModifier = D.Modifier.Frame():Size(UDim2.new(1, 0, 0, 40)):BackgroundTransparency(1):BorderSizePixel(0)

local function defaultFormat(v: number): string
	if v == math.floor(v) then
		return string.format("%d", v)
	end
	local s = string.format("%.2f", v)
	s = string.gsub(s, "0+$", "")
	return s
end

local function RangeSlider(props: Props)
	local theme = Theme.resolve(props.Theme)
	local R = theme.Raw
	local min: number = props.Min or 0
	local max: number = props.Max or 1
	if not (max > min) then
		error("RangeSlider: Max must be greater than Min", 2)
	end
	local range = max - min
	local step = props.Step
	if step ~= nil and not (step > 0) then
		error("RangeSlider: Step must be positive", 2)
	end
	local keyStep: number = props.KeyStep or step or range / 20
	local startS: q.Source<number> = props.Start or q.Source(min)
	local endS: q.Source<number> = props.End or q.Source(max)
	local disabled = Util.asState(props.Disabled)
	local format = props.Format or defaultFormat
	local corner = Tokens.Shape.corner("Full")

	-- the handle a drag / the keys move
	local which = q.Source("Start" :: Which)
	-- the handle nearest the pointer (hover)
	local nearest = q.Source("Start" :: Which)

	local function snap(v: number): number
		v = math.clamp(v, min, max)
		if step ~= nil then
			v = math.clamp(min + math.floor((v - min) / step + 0.5) * step, min, max)
		end
		return v
	end

	-- the one write path for user input: snapped, kept on its side of the other handle, only when changed
	local function commit(h: Which, raw: number): boolean
		local v = snap(raw)
		local src = if h == "Start" then startS else endS
		if h == "Start" then
			v = math.min(v, endS:Get())
		else
			v = math.max(v, startS:Get())
		end
		if v == src:Get() then
			return false
		end
		src:Set(v)
		if props.OnChange then
			props.OnChange(startS:Get(), endS:Get())
		end
		return true
	end

	local function toFrac(v: number): number
		return math.clamp((v - min) / range, 0, 1)
	end
	local fracStart: q.State<number> = startS:Compute(function(self)
		return toFrac(self:Get())
	end)
	local fracEnd: q.State<number> = endS:Compute(function(self)
		return toFrac(self:Get())
	end)

	local host: GuiObject? = nil
	-- pointer x -> value (unsnapped), nil before the host is laid out
	local function valueAt(x: number): number?
		local h = host
		if h == nil then
			return nil
		end
		local width = h.AbsoluteSize.X - 2 * INSET
		if width <= 0 then
			return nil
		end
		local f = (x - Ripple.Config.PointerInset.X - h.AbsolutePosition.X - INSET) / width
		return min + f * range
	end
	local function nearestTo(v: number): Which
		local s, e = startS:Get(), endS:Get()
		local ds, de = math.abs(v - s), math.abs(v - e)
		if ds < de then
			return "Start"
		elseif de < ds then
			return "End"
		end
		-- equal distance (the handles meet, or the press is exactly between): the side of the press decides
		return if v > e then "End" else "Start"
	end
	-- a drag that BEGAN on a closed range (both handles on one value) picks its handle from the first movement; a handle
	-- pushed into the other during a drag just stops there
	local undecided = false
	local function moveTo(x: number)
		local v = valueAt(x)
		if v == nil then
			return
		end
		if undecided then
			if which:Get() == "Start" and v > endS:Get() then
				which:Set("End")
			elseif which:Get() == "End" and v < startS:Get() then
				which:Set("Start")
			end
		end
		if commit(which:Get(), v) then
			undecided = false
		end
	end

	local drag = Interaction.drag({
		Disabled = disabled,
		OnBegan = function(x: number)
			local v = valueAt(x)
			if v == nil then
				return
			end
			which:Set(nearestTo(v))
			undecided = startS:Get() == endS:Get()
			moveTo(x)
		end,
		OnMoved = function(x: number)
			moveTo(x)
		end,
		OnEnded = function(x: number, _y: number, cancelled: boolean)
			if not cancelled then
				moveTo(x)
				if props.OnChangeEnd then
					props.OnChangeEnd(startS:Get(), endS:Get())
				end
			end
		end,
	})

	-- hover / gamepad focus of the host (the layers below split them per handle)
	local ix = Interaction.new({
		Disabled = disabled,
		OnHost = function(inst: GuiObject)
			inst.SelectionImageObject = Interactive.noSelectionImage()
		end,
	})

	local function onKey(input: InputObject)
		if Util.peekBool(disabled) then
			return
		end
		local kc = input.KeyCode
		if kc == Enum.KeyCode.Return or kc == Enum.KeyCode.KeypadEnter or kc == Enum.KeyCode.ButtonX then
			which:Set(if which:Get() == "Start" then "End" else "Start")
			return
		end
		local h = which:Get()
		local cur = if h == "Start" then startS:Get() else endS:Get()
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
		if target ~= nil and commit(h, target) and props.OnChangeEnd then
			props.OnChangeEnd(startS:Get(), endS:Get())
		end
	end
	local keys = KeyNav.hook(onKey)
	local hostHook = Util.preHook(function(inst)
		host = inst
		inst.Destroying:Connect(function()
			host = nil
		end)
	end)

	-- colors (as Slider)
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

	local ticks = Ticks.build({
		Frac = fracEnd,
		FracLow = fracStart,
		Range = range,
		Step = step,
		ShowTicks = props.ShowTicks,
		Disabled = disabled,
		Theme = theme,
	})

	local barHeight = 4
	local activePosition: q.State<UDim2> = fracStart:Compute(function(self)
		return UDim2.fromScale(self:Get(), 0.5)
	end)
	local activeSize: q.State<UDim2> = fracStart:Compute(function(self, _prev, fe)
		return UDim2.new(math.max(0, fe:Get() - self:Get()), 0, 0, barHeight)
	end, fracEnd)

	local function halo(h: Which, frac: q.State<number>, value: q.State<number>): Instance
		local isMe = function(s: q.State<Which>): q.State<boolean>
			return s:Compute(function(self)
				return self:Get() == h
			end)
		end
		local keyMe = isMe(which)
		local hovered: q.State<boolean> = ix.Hovered:Compute(function(self, _prev, near, dragging)
			-- while a drag runs only the dragged handle reacts
			return self:Get() and not dragging:Get() and near:Get() == h
		end, nearest, drag.Dragging)
		local focused: q.State<boolean> = ix.Focused:Compute(function(self, _prev, me)
			return self:Get() and me:Get()
		end, keyMe)
		local dragged: q.State<boolean> = drag.Dragging:Compute(function(self, _prev, me)
			return self:Get() and me:Get()
		end, keyMe)
		local layer = StateLayer.new({
			Color = theme.Color.Primary,
			Corner = corner,
			Hovered = hovered,
			Pressed = q.Source(false),
			Focused = focused,
			Dragged = dragged,
			Disabled = disabled,
			FocusRing = theme.Color.Secondary,
		})
		local label: Instance? = nil
		if props.ShowLabel ~= false then
			label = Bubble.build({
				Dragging = dragged,
				Focused = focused,
				Disabled = disabled,
				Value = value,
				Format = format,
				Theme = theme,
				Inset = INSET,
				Corner = corner,
			})
		end
		local position: q.State<UDim2> = frac:Compute(function(self)
			return UDim2.fromScale(self:Get(), 0.5)
		end)
		local zIndex: q.State<number> = keyMe:Compute(function(self)
			return if self:Get() then 2 else 1
		end)
		return D.Frame {
			Name = "Halo" .. h,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = position,
			Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			-- the key / dragged handle draws above the other where they overlap
			ZIndex = zIndex,
			layer,
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
		}
	end

	local interactable: q.State<boolean> = Util.interactable(disabled)

	return D.Frame {
		Name = "RangeSlider",
		baseModifier,
		props.Modifier or q.None,
		ix.Hook,
		drag.Hook,
		hostHook,
		keys,
		Interactable = interactable,
		Selectable = interactable,
		MouseMoved = function(x: number, _y: number)
			local v = valueAt(x)
			if v ~= nil then
				nearest:SetIfChanged(nearestTo(v))
			end
		end,
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
				Position = activePosition,
				Size = activeSize,
				BackgroundColor3 = activeColor,
				BackgroundTransparency = activeT,
				BorderSizePixel = 0,
				UICorner = corner,
			},
			q.Slot<<Instance>>(ticks),
			halo("Start", fracStart, startS),
			halo("End", fracEnd, endS),
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return RangeSlider
