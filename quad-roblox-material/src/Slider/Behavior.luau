--!strict
--[[
	Slider behaviour shared by every slider LOOK (M3 `Slider`/`RangeSlider` in this folder, M2 `M2.Slider`/`M2.RangeSlider`
	in `../M2/`): the value model (Min/Max/Step snapping, the one write path, OnChange/OnChangeEnd), the pointer (press
	jumps + drag, `Interaction.drag`), the keys (`KeyNav`), hover / pressed / focus States and the host width. A look file
	only draws: it places the hooks below on its host and derives its track / handle / label from the States. No look
	branch lives here — the only look input is `Look.Inset`, the px from a host edge to the handle CENTER at Min / Max
	(the pointer maps over the host width minus both insets).

	    local b = Behavior.single(props, { Name = "Slider", Inset = 8 })
	    D.Frame { b.InteractionHook, b.DragHook, b.KeyHook, Interactable = b.Interactable, Selectable = b.Interactable, ... }
	    -- b.Value / b.Frac / b.Dragging / b.Focused / b.Width ... drive the look

	    local r = Behavior.range(props, { Name = "RangeSlider", Inset = 8 })
	    D.Frame { r.InteractionHook, r.DragHook, r.KeyHook, MouseMoved = r.MouseMoved, ... }
	    local s = r.handle("Start")   -- { IsKey, Hovered, Focused, Dragged } of one handle

	Props (both shapes are the public props of the looks; all `read`):
	  single  Value Source<number>? (nil = own, starting at Min)
	  range   Start, End Source<number>? (nil = own, at Min / Max); Start <= End is kept by user input (a handle stops at
	          the other; the two may meet). A programmatic Start > End is shown as given.
	  Min, Max     number?   default 0 / 1, STATIC; Max must be > Min
	  Step         number?   nil = continuous; snaps every written value to Min + n*Step (the looks draw ticks)
	  ShowTicks    boolean?  (read by the looks)
	  KeyStep      number?   arrow increment; default Step, or (Max - Min) / 20
	  Format       ((value: number) -> string)?   label text; default integers plain, else up to 2 decimals
	  ShowLabel    boolean?  (read by the looks)
	  Disabled     boolean | State<boolean>?   no input, not selectable
	  OnChange     single (value) / range (startValue, endValue) -> (): after each USER change, only when changed
	  OnChangeEnd  same shape: on pointer release and after each key adjust; NOT on a cancelled drag
	  Theme, Modifier, Hooks   (read by the looks)

	Pointer: a press anywhere on the host jumps the value (range: grabs the NEAREST handle, equal distance picks by the
	side of the press) and continues as a drag. A range drag that BEGINS on a closed range takes its handle from the first
	movement (right -> End, left -> Start). The pointer maps with AbsolutePosition / AbsoluteSize read at event time.
	Keys (host is ONE selection stop, `KeyNav` "Horizontal"): Left/Right (+ D-pad) +-KeyStep, PageUp/PageDown +-10 KeyStep,
	Home/End = Min/Max; range: Return / KeypadEnter / gamepad ButtonX switch the KEY handle (the one last dragged, Start
	at first). Up/Down are neither mapped nor pinned (they walk the selection on).
	Width: `Width` follows the host's AbsoluteSize.X (0 before layout) through ONE property-changed connection on the
	host itself (dies with it) — the M3 look hides track pieces / ticks that are shorter than a corner or fall in the
	handle gap, which needs pixels.
	Global connections: as `Interaction.drag` (three only while dragging) and `KeyNav` (one only while selected).
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Util = require("../Util")
local Interaction = require("../Interaction")
local Interactive = require("../Interactive")
local KeyNav = require("../KeyNav")
local Ripple = require("../Ripple")

export type SliderProps = {
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

export type RangeSliderProps = {
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

export type Which = "Start" | "End"

export type Look = {
	Name: string, -- for error messages
	Inset: number, -- px from a host edge to the handle center at Min / Max
}

type Hook = Interaction.Hook

export type Common = {
	read Min: number,
	read Max: number,
	read Range: number,
	read Step: number?,
	read Format: (value: number) -> string,
	read Disabled: q.State<boolean>,
	read Interactable: q.State<boolean>,
	read Width: q.State<number>,
	read Hovered: q.State<boolean>,
	read Pressed: q.State<boolean>,
	read Focused: q.State<boolean>,
	read Dragging: q.State<boolean>,
	read InteractionHook: Hook,
	read DragHook: Hook,
	read KeyHook: Hook,
}

export type Single = Common & {
	read Value: q.Source<number>,
	read Frac: q.State<number>,
}

export type HandleStates = {
	read IsKey: q.State<boolean>,
	read Hovered: q.State<boolean>,
	read Focused: q.State<boolean>,
	read Dragged: q.State<boolean>,
}

export type Range = Common & {
	read Start: q.Source<number>,
	read End: q.Source<number>,
	read FracStart: q.State<number>,
	read FracEnd: q.State<number>,
	read Key: q.State<Which>,
	read Nearest: q.State<Which>,
	read MouseMoved: (x: number, y: number) -> (),
	read handle: (h: Which) -> HandleStates,
}

local function defaultFormat(v: number): string
	if v == math.floor(v) then
		return string.format("%d", v)
	end
	local s = string.format("%.2f", v)
	s = string.gsub(s, "0+$", "")
	return s
end

type Config = {
	min: number,
	max: number,
	range: number,
	step: number?,
	keyStep: number,
	format: (value: number) -> string,
	disabled: q.State<boolean>,
}

-- validated static configuration (`level` 3: the caller of the look's constructor)
local function config(
	name: string,
	min0: number?,
	max0: number?,
	step: number?,
	keyStep0: number?,
	format: ((value: number) -> string)?,
	disabled0: (boolean | q.State<boolean>)?
): Config
	local min: number = min0 or 0
	local max: number = max0 or 1
	if not (max > min) then
		error(name .. ": Max must be greater than Min", 4)
	end
	local range = max - min
	if step ~= nil and not (step > 0) then
		error(name .. ": Step must be positive", 4)
	end
	return {
		min = min,
		max = max,
		range = range,
		step = step,
		keyStep = keyStep0 or step or range / 20,
		format = format or defaultFormat,
		disabled = Util.asState(disabled0),
	}
end

local function snapper(c: Config): (number) -> number
	local min, max, step = c.min, c.max, c.step
	return function(v: number): number
		v = math.clamp(v, min, max)
		if step ~= nil then
			v = math.clamp(min + math.floor((v - min) / step + 0.5) * step, min, max)
		end
		return v
	end
end

-- the host tracker: hover / press / focus (hidden engine selection box), the host instance and its width
type HostTracker = {
	ix: Interaction.Interaction,
	width: q.Source<number>,
	valueAt: (x: number) -> number?,
}
local function hostTracker(c: Config, look: Look): HostTracker
	local width = q.Source(0)
	local host: GuiObject? = nil
	local inset = look.Inset
	local ix = Interaction.new({
		Disabled = c.disabled,
		OnHost = function(inst: GuiObject)
			host = inst
			inst.SelectionImageObject = Interactive.noSelectionImage()
			width:Set(inst.AbsoluteSize.X)
			inst:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				width:SetIfChanged(inst.AbsoluteSize.X)
			end)
			inst.Destroying:Connect(function()
				host = nil
			end)
		end,
	})
	-- pointer x -> value (unsnapped), nil before the host is laid out
	local function valueAt(x: number): number?
		local h = host
		if h == nil then
			return nil
		end
		local w = h.AbsoluteSize.X - 2 * inset
		if w <= 0 then
			return nil
		end
		local f = (x - Ripple.Config.PointerInset.X - h.AbsolutePosition.X - inset) / w
		return c.min + f * c.range
	end
	return { ix = ix, width = width, valueAt = valueAt }
end

-- the key -> target mapping shared by both shapes (nil = not a value key)
local function keyTarget(c: Config, kc: Enum.KeyCode, cur: number): number?
	if kc == Enum.KeyCode.Left or kc == Enum.KeyCode.DPadLeft then
		return cur - c.keyStep
	elseif kc == Enum.KeyCode.Right or kc == Enum.KeyCode.DPadRight then
		return cur + c.keyStep
	elseif kc == Enum.KeyCode.PageDown then
		return cur - 10 * c.keyStep
	elseif kc == Enum.KeyCode.PageUp then
		return cur + 10 * c.keyStep
	elseif kc == Enum.KeyCode.Home then
		return c.min
	elseif kc == Enum.KeyCode.End then
		return c.max
	end
	return nil
end

local function single(props: SliderProps, look: Look): Single
	local c = config(look.Name, props.Min, props.Max, props.Step, props.KeyStep, props.Format, props.Disabled)
	local snap = snapper(c)
	local value: q.Source<number> = props.Value or q.Source(c.min)
	local min, range = c.min, c.range

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

	local t = hostTracker(c, look)
	local function commitFromX(x: number)
		local v = t.valueAt(x)
		if v ~= nil then
			commit(v)
		end
	end
	local drag = Interaction.drag({
		Disabled = c.disabled,
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
	local keys = KeyNav.hook(function(input: InputObject)
		if c.disabled:Get() then
			return
		end
		local target = keyTarget(c, input.KeyCode, value:Get())
		if target ~= nil and commit(target) and props.OnChangeEnd then
			props.OnChangeEnd(value:Get())
		end
	end)

	return {
		Min = c.min,
		Max = c.max,
		Range = c.range,
		Step = c.step,
		Format = c.format,
		Disabled = c.disabled,
		Interactable = Util.interactable(c.disabled),
		Width = t.width,
		Hovered = t.ix.Hovered,
		Pressed = t.ix.Pressed,
		Focused = t.ix.Focused,
		Dragging = drag.Dragging,
		InteractionHook = t.ix.Hook,
		DragHook = drag.Hook,
		KeyHook = keys,
		Value = value,
		Frac = frac,
	}
end

local function range(props: RangeSliderProps, look: Look): Range
	local c = config(look.Name, props.Min, props.Max, props.Step, props.KeyStep, props.Format, props.Disabled)
	local snap = snapper(c)
	local min, rangeWidth = c.min, c.range
	local startS: q.Source<number> = props.Start or q.Source(c.min)
	local endS: q.Source<number> = props.End or q.Source(c.max)

	-- the handle a drag / the keys move, and the handle nearest the pointer (hover)
	local which = q.Source("Start" :: Which)
	local nearest = q.Source("Start" :: Which)

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
		return math.clamp((v - min) / rangeWidth, 0, 1)
	end
	local fracStart: q.State<number> = startS:Compute(function(self)
		return toFrac(self:Get())
	end)
	local fracEnd: q.State<number> = endS:Compute(function(self)
		return toFrac(self:Get())
	end)

	local t = hostTracker(c, look)
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
	-- a drag that BEGAN on a closed range picks its handle from the first movement; a handle pushed into the other
	-- during a drag just stops there
	local undecided = false
	local function moveTo(x: number)
		local v = t.valueAt(x)
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
		Disabled = c.disabled,
		OnBegan = function(x: number)
			local v = t.valueAt(x)
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

	local keys = KeyNav.hook(function(input: InputObject)
		if c.disabled:Get() then
			return
		end
		local kc = input.KeyCode
		if kc == Enum.KeyCode.Return or kc == Enum.KeyCode.KeypadEnter or kc == Enum.KeyCode.ButtonX then
			which:Set(if which:Get() == "Start" then "End" else "Start")
			return
		end
		local h = which:Get()
		local target = keyTarget(c, kc, if h == "Start" then startS:Get() else endS:Get())
		if target ~= nil and commit(h, target) and props.OnChangeEnd then
			props.OnChangeEnd(startS:Get(), endS:Get())
		end
	end)

	local ix = t.ix
	local function handle(h: Which): HandleStates
		local isKey: q.State<boolean> = which:Compute(function(self)
			return self:Get() == h
		end)
		local hovered: q.State<boolean> = ix.Hovered:Compute(function(self, _prev, near, dragging)
			-- while a drag runs only the dragged handle reacts
			return self:Get() and not dragging:Get() and near:Get() == h
		end, nearest, drag.Dragging)
		local focused: q.State<boolean> = ix.Focused:Compute(function(self, _prev, me)
			return self:Get() and me:Get()
		end, isKey)
		local dragged: q.State<boolean> = drag.Dragging:Compute(function(self, _prev, me)
			return self:Get() and me:Get()
		end, isKey)
		return { IsKey = isKey, Hovered = hovered, Focused = focused, Dragged = dragged }
	end

	return {
		Min = c.min,
		Max = c.max,
		Range = c.range,
		Step = c.step,
		Format = c.format,
		Disabled = c.disabled,
		Interactable = Util.interactable(c.disabled),
		Width = t.width,
		Hovered = ix.Hovered,
		Pressed = ix.Pressed,
		Focused = ix.Focused,
		Dragging = drag.Dragging,
		InteractionHook = ix.Hook,
		DragHook = drag.Hook,
		KeyHook = keys,
		Start = startS,
		End = endS,
		FracStart = fracStart,
		FracEnd = fracEnd,
		Key = which,
		Nearest = nearest,
		MouseMoved = function(x: number, _y: number)
			local v = t.valueAt(x)
			if v ~= nil then
				nearest:SetIfChanged(nearestTo(v))
			end
		end,
		handle = handle,
	}
end

return {
	single = single,
	range = range,
	defaultFormat = defaultFormat,
}
