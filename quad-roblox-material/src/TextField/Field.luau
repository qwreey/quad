--!strict
--[[
	TextField engine (internal): builds the field and returns its parts. `TextField/init.luau` is the public
	component (`TextField(props) -> Frame`, public `Props`); `Select` reuses this module to get at the container (menu
	anchor) and to drive the read-only mode. Read the public header in `init.luau` for the user-facing description.

	Files: Ctx (shared types: the internal `Props` superset, `Parts`, the `Ctx` bundle) / Palette (status + role colors) /
	Slots (leading, trailing, error mark, affixes) / Container (floating label + the container) / Support (supporting row)
	/ this file (derived States, the TextBox, the row, the host).

	Structure (Filled, with label, no extras) — host + 11 children:
	    Host Frame (AutomaticSize Y, vertical list)                         "TextField"
	      UIListLayout
	      Container Frame (56, rounded 4, hover Interaction hook)           "Container"
	        UICorner · StateLayer (Frame+UICorner) · active indicator Frame · Row Frame (UIPadding+UIListLayout,
	        TextBox+UIFlexItem) · floating Label TextLabel
	      Supporting TextLabel (+UIPadding, counter TextLabel child)        only when needed
	Outlined replaces the state layer + indicator with ONE UIStroke on the container.

	Write-back: `q.Out("Text", value)`. With `MaxLength` (or an `OnChange` callback) the write-back is
	`q.OnChange("Text", fn)`: it clips the engine text to the limit and writes the clipped string with `value:Set` — NOT
	`SetIfChanged`: when the source is already at the limit the clipped string equals the source, `SetIfChanged` would be a
	no-op and the TextBox would keep the overflowing characters (the property binding only rewrites on a publish). `:Set`
	republishes, the `Text = value` binding rewrites the TextBox. This is the docs' "truncate in the write-back
	path" (how-to 02 section 6): the engine -> Source direction is an engine event handler, never an Observer
	feeding its own upstream. Cost: a consumer of `value` sees one extra emission (same value) per overflow keystroke.
	`OnChange(text)` fires for USER edits only: a Text change whose (clipped) result differs from what `value` already
	holds (a programmatic `value:Set` writes the TextBox through the `Text = value` binding, so its echo equals `value`
	and is ignored).
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Util = require("../Util")
local Interaction = require("../Interaction")
local Interactive = require("../Interactive")
local Style = require("../Button/Style")
local Text = require("../Text")
local Ctx = require("./Ctx")
local Palette = require("./Palette")
local Slots = require("./Slots")
local Container = require("./Container")
local Support = require("./Support")
local D = q.Declaration
local fieldName = D.Modifier.Frame():Name("TextField")

export type Variant = Ctx.Variant
export type Props = Ctx.Props
export type Parts = Ctx.Parts

local FieldHeight = 56
local MultiLineHeight = 120

local hostModifier = D.Modifier.Frame()
	:Size(UDim2.fromOffset(210, 0))
	:AutomaticSize(Enum.AutomaticSize.Y)
	:BackgroundTransparency(1)
	:BorderSizePixel(0)

local inputStyle = Text.Box("BodyLarge")

-- utf8-aware clip to `max` characters (invalid utf8 falls back to bytes)
local function clip(s: string, max: number): string
	local n = utf8.len(s)
	if n == nil then
		return string.sub(s, 1, max)
	end
	if n <= max then
		return s
	end
	return string.sub(s, 1, (utf8.offset(s, max + 1) :: number) - 1)
end

local function build(props: Props): Parts
	local theme = Theme.resolve(props.Theme)
	local filled = (props.Variant or "Filled") == "Filled"
	local multi = props.MultiLine == true
	local height = props.Height or (if multi then MultiLineHeight else FieldHeight)
	local disabled = Util.asState(props.Disabled)
	local errorS = Util.asState(props.Error)
	local readOnly = props.Text ~= nil
	local value: q.Source<string> = props.Value or q.Source("")
	local shown: q.State<string> = props.Text or value
	local hasLabel = props.Label ~= nil
	local maxLength = props.MaxLength
	local onChange = props.OnChange

	local interactable: q.State<boolean> = Util.interactable(disabled)

	-- the editable TextBox, once mounted: a click anywhere on the container (label, padding, icons, the strip under the
	-- text) focuses it, like M3's whole-container tap target. The TextBox only covers the row's padded box (24 px high in
	-- a Filled field with a label), and the engine focuses a TextBox only on a click inside its own bounds — Studio QA
	-- 2026-10-07 (2nd): "had to click the text part".
	local inputInst: TextBox? = nil

	local ix = Interaction.new({
		Disabled = disabled,
		OnHost = function(inst: GuiObject)
			inst.SelectionImageObject = Interactive.noSelectionImage()
		end,
		OnPressEnded = function(cancelled: boolean)
			if cancelled or Util.peekBool(disabled) then
				return
			end
			if props.OnClick then
				props.OnClick()
			end
			local box = inputInst
			if box ~= nil and not readOnly and not box:IsFocused() then
				box:CaptureFocus()
			end
		end,
	})

	-- focus: written from the TextBox events (engine -> state), the gamepad selection of the Container (read-only) or of
	-- the TextBox (editable), plus an optional forced look
	local typedFocus = q.Source(false)
	local boxSelected = q.Source(false)
	local force: q.State<boolean> = props.ForceFocused or q.Source(false)
	local focused: q.State<boolean> = typedFocus:Compute(function(self, _prev, f, sel, cont)
		return self:Get() or f:Get() or sel:Get() or cont:Get()
	end, force, boxSelected, ix.Focused)
	local nonEmpty: q.State<boolean> = shown:Compute(function(self)
		return #self:Get() > 0
	end)
	local floated: q.State<boolean> = focused:Compute(function(self, _prev, ne)
		return self:Get() or ne:Get()
	end, nonEmpty)

	local status = Palette.status(focused, ix.Hovered, errorS, disabled)
	local c: Ctx.Ctx = {
		Props = props,
		Theme = theme,
		Filled = filled,
		Multi = multi,
		Height = height,
		Disabled = disabled,
		Error = errorS,
		ReadOnly = readOnly,
		HasLabel = hasLabel,
		MaxLength = maxLength,
		ShowCounter = props.ShowCounter ~= false,
		Value = value,
		Focused = focused,
		Floated = floated,
		Hovered = ix.Hovered,
		ContentTransparency = Style.disabledNumber(disabled, 0, Style.DisabledContentTransparency),
		Colors = Palette.colors(status, theme, filled),
	}

	-- ── slots + row geometry ────────────────────────────────────────────────
	local leading = Slots.leading(c)
	local trailing, errorMark = Slots.trailing(c)
	local hasTrailing = props.TrailingIcon ~= nil or props.TrailingGlyph ~= nil
	local inset = if props.LeadingIcon ~= nil then 52 else 16
	local rightPad: UDim | q.State<UDim> = UDim.new(0, if hasTrailing then 52 else 16)
	if not hasTrailing and props.Error ~= nil then
		-- the row makes room for the error mark only while it shows
		rightPad = errorS:Compute(function(self)
			return UDim.new(0, if self:Get() then 52 else 16)
		end)
	end
	local padTop = if hasLabel and filled then 24 elseif multi then 16 else 0
	local padBottom = if hasLabel and filled then 8 elseif multi then 16 else 0

	local placeholder: string | q.State<string> = ""
	if props.Placeholder ~= nil then
		local ph = props.Placeholder
		if hasLabel then
			-- the label occupies the empty field; the placeholder appears once it has floated
			local phState: q.State<string> = focused:Compute(function(self)
				return if self:Get() then ph else ""
			end)
			placeholder = phState
		else
			placeholder = ph
		end
	end

	local inputMod = D.Modifier.TextBox():TextXAlignment(Enum.TextXAlignment.Left)
	if multi then
		inputMod = inputMod:MultiLine(true):TextWrapped(true):TextYAlignment(Enum.TextYAlignment.Top)
	else
		inputMod = inputMod:TextWrapped(false):TextYAlignment(Enum.TextYAlignment.Center)
	end

	local editable: q.State<boolean> = if readOnly then q.Source(false) else interactable

	-- engine -> Source: user edits only (see the header); the plain `q.Out` form when nothing needs the callback / clip
	local function writeBack(v: string)
		local clipped = if maxLength ~= nil then clip(v, maxLength) else v
		local userEdit = clipped ~= value:Get()
		if clipped ~= v then
			value:Set(clipped) -- republish even if equal to the source: rewrites the TextBox (see header)
		else
			value:SetIfChanged(v)
		end
		if userEdit and onChange then
			onChange(clipped)
		end
	end

	local input = D.TextBox {
		Name = "Input",
		inputStyle,
		inputMod,
		Size = UDim2.fromScale(0, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Text = shown,
		PlaceholderText = placeholder,
		PlaceholderColor3 = theme.Color.OnSurfaceVariant,
		TextColor3 = Style.disabledPick(disabled, theme.Raw.OnSurface, theme.Raw.OnSurface),
		TextTransparency = c.ContentTransparency,
		TextEditable = editable,
		-- read-only: not focusable, does not sink input, so the container's press hook gets the click
		Interactable = if readOnly then false else interactable,
		LayoutOrder = 2,
		D.UIFlexItem { FlexMode = Enum.UIFlexMode.Fill },
		if readOnly
			then q.None
			elseif maxLength ~= nil or onChange ~= nil then q.OnChange("Text", writeBack)
			else q.Out("Text", value),
		if readOnly
			then q.None
			else Util.preHook(function(inst: GuiObject)
				inst.SelectionImageObject = Interactive.noSelectionImage() -- the focused look replaces the engine box
				inputInst = inst :: TextBox
			end),
		SelectionGained = function()
			boxSelected:SetIfChanged(true)
		end,
		SelectionLost = function()
			boxSelected:SetIfChanged(false)
		end,
		Focused = function()
			typedFocus:SetIfChanged(true)
			if props.OnFocusChanged then
				props.OnFocusChanged(true)
			end
		end,
		FocusLost = function(enterPressed: boolean, _input: InputObject)
			typedFocus:SetIfChanged(false)
			if props.OnFocusChanged then
				props.OnFocusChanged(false)
			end
			if enterPressed and props.OnSubmit then
				props.OnSubmit(value:Get())
			end
		end,
	}

	local row = D.Frame {
		Name = "Row",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		D.UIPadding {
			PaddingLeft = UDim.new(0, inset),
			PaddingRight = rightPad,
			PaddingTop = UDim.new(0, padTop),
			PaddingBottom = UDim.new(0, padBottom),
		},
		D.UIListLayout {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
		},
		if props.Prefix ~= nil then Slots.affix(c, "Prefix", props.Prefix) else q.None,
		input,
		if props.Suffix ~= nil then Slots.affix(c, "Suffix", props.Suffix) else q.None,
	}

	local container = Container.container(c, {
		Hook = ix.Hook,
		Selectable = if readOnly then interactable else false,
		Row = row,
		Label = Container.label(c, inset),
		Leading = leading,
		Trailing = trailing,
		ErrorMark = errorMark,
	})

	local host = D.Frame {
		fieldName,
		hostModifier,
		props.Modifier or q.None,
		D.UIListLayout {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		container,
		Support.build(c) or q.None,
		table.unpack(Util.hooks(props.Hooks)),
	}

	return {
		Host = host,
		Container = container,
		Input = input,
		Focused = focused,
		Floated = floated,
		Value = value,
	}
end

return {
	build = build,
	clip = clip,
}
