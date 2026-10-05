--!strict
--[[
	InputMode: the text-entry panel of the modal date picker (M3 "input mode"): an outlined field that parses
	what the user types with `Calendar.parseLocalized` and writes the picked date into `Draft`.

	    local panel = InputMode.new({ Draft = draft, Error = err, Locale = "ko", Min = min, Max = max })
	    panel.Frame            the panel (360 x 396, same as the calendar body so the modal keeps its size)
	    panel.Sync()           reload the field from `Draft` (call when switching calendar -> input)

	Behaviour
	  * every keystroke is parsed (an Effect over the text Source — `q.Out("Text", text)` is the write-back):
	      empty                 Draft := nil, no error (the modal's OK stays disabled: nothing picked)
	      unparseable           Error := strings.ErrInvalid     (Draft keeps its last valid value)
	      parsed, out of [Min, Max]      Error := ErrRange
	      parsed, IsDisabled(date)       Error := ErrDisabled
	      valid                 Error := nil, Draft := date (only when it differs, so no churn per keystroke)
	  * accepted forms are Calendar.parseLocalized's: 2026-10-05, 2026/10/5, 2026.10.5, 2026년 10월 5일,
	    "Oct 5, 2026" in English. The field shows ISO `YYYY-MM-DD`.
	  * supporting text shows the format hint, or the error in the error color; the outline turns error-red,
	    2 px primary while focused (TextBox `Focused` / `FocusLost` events).
	A plain TextBox styled as an outlined field (the kit's TextField is being written separately).
	Instances: panel + label + TextBox (+UICorner +UIStroke +UIPadding) + supporting label = 8.
]]

local q = require("../Quad")
local Util = require("../Util")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Text = require("../Text")
local Calendar = require("./Calendar")
local Strings = require("./Strings")
local D = q.Declaration

type Date = Calendar.Date
type State<T> = q.State<T>

export type Options = {
	Draft: q.Source<Date?>,
	Error: q.Source<string?>,
	Locale: string,
	Min: Date?,
	Max: Date?,
	IsDisabled: ((date: Date) -> boolean)?,
	Theme: Theme.Theme?,
	Width: number,
	Height: number,
	Visible: (boolean | State<boolean>)?,
	Position: UDim2?,
}

export type InputMode = {
	read Frame: Frame,
	Sync: () -> (),
}

local labelStyle = Text.Label("LabelMedium")
local supportStyle = Text.Label("BodySmall")
local fieldStyle = Text.Box("BodyLarge")

local function trim(s: string): string
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function new(o: Options): InputMode
	local theme = Theme.resolve(o.Theme)
	local raw = theme.Raw
	local strings = Strings.get(o.Locale)
	local draft, err = o.Draft, o.Error
	local initial = draft:Get()
	local text = q.Source(if initial ~= nil then Calendar.formatISO(initial) else "")
	local focused = q.Source(false)

	local validate = q.Effect(function()
		local t = trim(text:Get())
		if t == "" then
			err:SetIfChanged(nil)
			if draft:Get() ~= nil then
				draft:Set(nil)
			end
			return
		end
		local d = Calendar.parseLocalized(t, o.Locale)
		if d == nil then
			err:SetIfChanged(strings.ErrInvalid)
		elseif not Calendar.isInRange(d, o.Min, o.Max) then
			err:SetIfChanged(strings.ErrRange)
		elseif o.IsDisabled ~= nil and o.IsDisabled(d) then
			err:SetIfChanged(strings.ErrDisabled)
		else
			err:SetIfChanged(nil)
			local cur = draft:Get()
			if cur == nil or not Calendar.equals(cur, d) then
				draft:Set(d)
			end
		end
	end, text)

	local supporting: State<string> = err:Compute(function(self)
		return self:Get() or strings.Hint
	end)
	local supportColor: State<Color3> = err:Compute(function(self, _prev, errorColor, variant)
		return if self:Get() ~= nil then errorColor:Get() else variant:Get()
	end, raw.Error, raw.OnSurfaceVariant)
	local strokeColor: State<Color3> = err:Compute(function(self, _prev, isFocused, errorColor, primary, outline)
		if self:Get() ~= nil then
			return errorColor:Get()
		elseif isFocused:Get() then
			return primary:Get()
		end
		return outline:Get()
	end, focused, raw.Error, raw.Primary, raw.Outline)
	local strokeThickness: State<number> = focused:Compute(function(self)
		return if self:Get() then 2 else 1
	end)
	local labelColor: State<Color3> = err:Compute(function(self, _prev, isFocused, errorColor, primary, variant)
		if self:Get() ~= nil then
			return errorColor:Get()
		elseif isFocused:Get() then
			return primary:Get()
		end
		return variant:Get()
	end, focused, raw.Error, raw.Primary, raw.OnSurfaceVariant)
	local animate = Tokens.Motion.options("Short2", "Standard")

	local fieldW = o.Width - 32
	local frame = D.Frame {
		Name = "DateInput",
		Position = o.Position or UDim2.new(),
		Size = UDim2.fromOffset(o.Width, o.Height),
		Visible = Util.visible(o.Visible),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		validate,
		D.TextLabel {
			Name = "FieldLabel",
			labelStyle,
			Size = UDim2.fromOffset(fieldW, 16),
			Position = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = strings.DateLabel,
			TextColor3 = labelColor:Apply(q.Animate(animate)),
			TextXAlignment = Enum.TextXAlignment.Left,
		},
		D.TextBox {
			Name = "Field",
			fieldStyle,
			q.Out("Text", text),
			Size = UDim2.fromOffset(fieldW, 56),
			Position = UDim2.fromOffset(16, 36),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = text,
			PlaceholderText = strings.Hint,
			PlaceholderColor3 = theme.Color.OnSurfaceVariant,
			ClearTextOnFocus = false,
			TextColor3 = theme.Color.OnSurface,
			TextXAlignment = Enum.TextXAlignment.Left,
			UICorner = Tokens.Shape.corner("ExtraSmall"),
			Focused = function()
				focused:SetIfChanged(true)
			end,
			FocusLost = function()
				focused:SetIfChanged(false)
			end,
			D.UIPadding { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) },
			D.UIStroke {
				Name = "Outline",
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = strokeColor:Apply(q.Animate(animate)),
				Thickness = strokeThickness,
			},
		},
		D.TextLabel {
			Name = "Supporting",
			supportStyle,
			Size = UDim2.fromOffset(fieldW, 16),
			Position = UDim2.fromOffset(16, 98),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = supporting,
			TextColor3 = supportColor:Apply(q.Animate(animate)),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
		},
	}

	return {
		Frame = frame,
		Sync = function()
			local d = draft:Get()
			text:Set(if d ~= nil then Calendar.formatISO(d) else "")
		end,
	}
end

return { new = new }
