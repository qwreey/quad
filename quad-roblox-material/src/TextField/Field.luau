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
	Outlined replaces the fill, the state layer and the indicator with the outline: ONE UIStroke on the container when
	the field has no label; with a label, three clipped copies of the outline that leave the notch open (Container.luau
	"OUTLINED NOTCH").

	PLACEHOLDER: a TextLabel child of the TextBox ("Placeholder", over the TextBox's own box, input-transparent) instead of
	the engine's `PlaceholderText` — the engine placeholder has no transparency of its own, so it could not fade. Canon:
	Compose `internal/TextFieldImpl.kt` (androidx@26506f4) `placeholderOpacity`: one opacity per input phase — Focused 1,
	UnfocusedEmpty 0 under a label that rests in the field (1 without a label), UnfocusedNotEmpty 0 — animated with
	`MotionSchemeKeyTokens.SlowEffects` for UnfocusedEmpty -> Focused (the fade in on focus) and UnfocusedNotEmpty ->
	UnfocusedEmpty, `FastEffects` for every other change (the fade out on blur); the placeholder is composed only while the
	text is empty (`visualText.isEmpty()`), so typing hides it at once. The kit maps the two springs to the duration token
	nearest their 1 % settling time like the sheets (Sheet/Parts.luau "MOTION"; StandardMotionTokens: FastEffects
	damping 1.0 / stiffness 3800 -> 0.11 s = Short2, SlowEffects 1.0 / 800 -> 6.64 / sqrt(800) = 0.235 s = Medium1), with
	the Standard easing. A disabled flip of the same phase keeps the content animation (Short4). MDC
	(`TextInputLayout.java` material-components-android@60ff094, `createPlaceholderFadeTransition`) fades too: linear,
	motionDurationShort2, the fade in delayed 67 ms (`PLACEHOLDER_START_DELAY`) — the kit follows Compose (no delay).

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
local Tokens = require("../Tokens")
local MotionTokens = require("../Tokens/Motion")
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
local placeholderStyle = Text.Label("BodyLarge")

-- the placeholder fade (see PLACEHOLDER in the header)
local PlaceholderFast = Tokens.Motion.options("Short2", "Standard") -- FastEffects
local PlaceholderSlow = Tokens.Motion.options("Medium1", "Standard") -- SlowEffects
local PlaceholderContent = Tokens.Motion.options("Short4", "Standard") -- a disabled flip (Style.animation)

-- Compose's InputPhase
type Phase = "Focused" | "UnfocusedEmpty" | "UnfocusedNotEmpty"
type PlaceholderLook = { Phase: Phase, Transparency: number, Motion: MotionTokens.AnimateOptions }

-- the motion of a phase change (TextFieldImpl.kt `placeholderOpacity` transitionSpec)
local function placeholderMotion(from: Phase?, to: Phase): MotionTokens.AnimateOptions
	if from == nil or from == to then
		return PlaceholderContent
	elseif (from == "UnfocusedEmpty" and to == "Focused") or (from == "UnfocusedNotEmpty" and to == "UnfocusedEmpty") then
		return PlaceholderSlow
	end
	return PlaceholderFast
end

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

	-- the placeholder (see PLACEHOLDER in the header): its opacity follows the input phase, it shows only while empty
	local placeholder: Instance? = nil
	if props.Placeholder ~= nil then
		local look: q.State<PlaceholderLook> = focused:Compute(function(self, prev: PlaceholderLook?, ne, dis): PlaceholderLook
			local phase: Phase = if self:Get() then "Focused" elseif ne:Get() then "UnfocusedNotEmpty" else "UnfocusedEmpty"
			local alpha = if phase == "Focused" or (phase == "UnfocusedEmpty" and not hasLabel) then 1 else 0
			local content = if dis:Get() then Style.DisabledContentTransparency else 0
			return {
				Phase = phase,
				Transparency = 1 - (1 - content) * alpha,
				Motion = placeholderMotion(if prev ~= nil then prev.Phase else nil, phase),
			}
		end, nonEmpty, disabled)
		local transparency: q.State<q.Tween<number>> = look:Compute(function(self)
			local l = self:Get()
			return q.Tween({ Value = l.Transparency, Time = l.Motion.Time, Style = l.Motion.Style, Direction = l.Motion.Direction })
		end)
		local empty: q.State<boolean> = nonEmpty:Compute(function(self)
			return not self:Get()
		end)
		local phMod = D.Modifier.TextLabel():TextXAlignment(Enum.TextXAlignment.Left)
		if multi then
			phMod = phMod:TextWrapped(true):TextYAlignment(Enum.TextYAlignment.Top)
		else
			phMod = phMod:TextWrapped(false):TextYAlignment(Enum.TextYAlignment.Center)
		end
		placeholder = D.TextLabel {
			Name = "Placeholder",
			placeholderStyle,
			phMod,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Interactable = false, -- clicks reach the TextBox under it
			Text = props.Placeholder,
			TextColor3 = theme.Color.OnSurfaceVariant,
			TextTransparency = transparency,
			Visible = empty,
		}
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
		TextColor3 = Style.disabledPick(disabled, theme.Raw.OnSurface, theme.Raw.OnSurface),
		TextTransparency = c.ContentTransparency,
		TextEditable = editable,
		-- read-only: not focusable, does not sink input, so the container's press hook gets the click
		Interactable = if readOnly then false else interactable,
		LayoutOrder = 2,
		D.UIFlexItem { FlexMode = Enum.UIFlexMode.Fill },
		placeholder or q.None,
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

	-- the prefix / suffix fade (Slots.luau AFFIX), shared by both
	local affixFade = if props.Prefix ~= nil or props.Suffix ~= nil then Slots.affixTransparency(c) else nil

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
		if props.Prefix ~= nil then Slots.affix(c, "Prefix", props.Prefix, affixFade :: Theme.Animated) else q.None,
		input,
		if props.Suffix ~= nil then Slots.affix(c, "Suffix", props.Suffix, affixFade :: Theme.Animated) else q.None,
	}

	local labelInst, notch = Container.label(c, inset)
	local container = Container.container(c, {
		Hook = ix.Hook,
		Selectable = if readOnly then interactable else false,
		Row = row,
		Label = labelInst,
		Notch = notch,
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
