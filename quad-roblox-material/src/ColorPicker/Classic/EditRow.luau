--!strict
--[[
	The three edit rows: HSV, RGB, HEX. One generic `EditBox` serves all seven boxes (the original had six
	copy-pasted 22-line handlers plus a hex one, 12 `...UpdateIgnore` flags, `task.wait()` inside a Text-changed
	signal, and a Text -> parse -> fix -> write-back loop).

	How a box works, with NO hand synchronization:
	  displayed text = focused ? buffer : model text           (a Compute of three things)
	  buffer         = what the engine currently holds         (q.OnChange("Text") echo)
	  user types     -> OnChange -> buffer, and if the text parses AND differs from what the model shows,
	                    `model.typeChannel` commits it live (valid text only; invalid/empty text is simply not committed)
	  FocusLost      -> final commit of the buffer (if it was edited), then `focused = false`, so the box flips back
	                    to the model's text: an invalid or empty entry reverts, a clamped one shows its clamp.
	Because the shown text IS the model text whenever the box is not being edited, a drag/other box/cancel never
	needs to write into a box. The "differs from the model text" test stops the echo of the model's own rounded
	display (e.g. H = 0.4812 shown as "123") from being parsed back and quantizing the color.

	Keys: Tab (the `\t` character the TextBox receives) moves focus H -> S -> V -> H / R -> G -> B -> R (focus moves
	are the only imperative calls: CaptureFocus/ReleaseFocus); the mouse wheel is +/-1 on the model value, so an
	empty box no longer errors. Row geometry is absolute (pair k at k * 1/3 of the width) instead of a UIListLayout.
	Deviation: an invalid keystroke ("12a") is not reverted per keystroke but when the box loses focus.
]]

local q = require("../../Quad")
local Model = require("./Model")
local Themes = require("./Themes")
local D = q.Declaration

export type Props = {
	read Model: Model.Model,
	read Theme: Themes.Theme,
	read LayoutOrder: number?,
}

local LABEL_W = 16
local HEX_LABEL_W = 36

type BoxOptions = {
	Model: Model.Model,
	Theme: Themes.Theme,
	Channel: Model.Channel,
	Position: UDim2,
	Size: UDim2,
	Ref: q.PreRef<TextBox?>,
	OnTab: (() -> ())?,
}

local function EditBox(o: BoxOptions)
	local model, theme, ch = o.Model, o.Theme, o.Channel
	local modelText = model.text[ch]
	local focused = q.Source(false)
	local buffer = q.Source("")
	local shown: q.State<string> = focused:Compute(function(self, _prev, m, b)
		return if self:Get() then b:Get() else m:Get()
	end, modelText, buffer)

	return D.TextBox {
		Name = `{ch}Box`,
		o.Ref,
		q.OnChange("Text", function(v: string)
			if string.find(v, "\t", 1, true) then
				-- Tab arrives as a character: drop it (republish so the bound Text loses it) and move on
				buffer:Set((string.gsub(v, "\t", "")))
				if o.OnTab then
					o.OnTab()
				end
				return
			end
			buffer:SetIfChanged(v)
			if focused:Get() and v ~= modelText:Get() then
				model.typeChannel(ch, v, false)
			end
		end),
		ClearTextOnFocus = false,
		Font = Enum.Font.GothamMedium,
		Text = shown,
		TextColor3 = theme.EditBoxTextColor,
		TextSize = 14,
		BackgroundTransparency = 1,
		Position = o.Position,
		Size = o.Size,
		Focused = function()
			focused:SetIfChanged(true)
		end,
		FocusLost = function()
			local b = buffer:Get()
			if b ~= modelText:Get() then
				model.typeChannel(ch, b, true)
			end
			focused:SetIfChanged(false)
		end,
		MouseWheelForward = function()
			model.nudge(ch, 1)
		end,
		MouseWheelBackward = function()
			model.nudge(ch, -1)
		end,

		D.UIPadding { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 8) },
		D.Frame {
			Name = "Underbar",
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = theme.EditorBoxUnderbarColor,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 2),
		},
	}
end

local function Label(theme: Themes.Theme, text: string, pos: UDim2, width: number)
	return D.TextLabel {
		Name = `{text}Label`,
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = theme.EditLabelTextColor,
		TextSize = 14,
		BackgroundTransparency = 1,
		Position = pos,
		Size = UDim2.new(0, width, 1, 0),
	}
end

local function Triple(props: Props, name: string, channels: { Model.Channel })
	local theme = props.Theme
	local refs = {
		q.PreRef(nil :: TextBox?),
		q.PreRef(nil :: TextBox?),
		q.PreRef(nil :: TextBox?),
	}
	local function tabFrom(i: number): () -> ()
		return function()
			local cur, nxt = refs[i].Value, refs[i % 3 + 1].Value
			if cur and nxt then
				cur:ReleaseFocus(false)
				nxt:CaptureFocus()
				nxt.SelectionStart = 1
				nxt.CursorPosition = #nxt.Text + 1
			end
		end
	end
	local function box(i: number)
		return EditBox({
			Model = props.Model,
			Theme = theme,
			Channel = channels[i],
			Position = UDim2.new((i - 1) * 0.333, LABEL_W, 0, 0),
			Size = UDim2.new(0.333, -LABEL_W, 1, 0),
			Ref = refs[i],
			OnTab = tabFrom(i),
		})
	end
	local function label(i: number)
		return Label(theme, channels[i] :: string, UDim2.fromScale((i - 1) * 0.333, 0), LABEL_W)
	end
	return D.Frame {
		Name = name,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, theme.EditBoxSizeY),
		LayoutOrder = props.LayoutOrder or 0,
		label(1),
		box(1),
		label(2),
		box(2),
		label(3),
		box(3),
	}
end

local function HSV(props: Props)
	return Triple(props, "HsvEditRow", { "H", "S", "V" })
end

local function RGB(props: Props)
	return Triple(props, "RgbEditRow", { "R", "G", "B" })
end

local function Hex(props: Props)
	local theme = props.Theme
	return D.Frame {
		Name = "HexEditRow",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, theme.EditBoxSizeY),
		LayoutOrder = props.LayoutOrder or 0,
		Label(theme, "HEX", UDim2.new(), HEX_LABEL_W),
		EditBox({
			Model = props.Model,
			Theme = theme,
			Channel = "HEX",
			Position = UDim2.new(0, HEX_LABEL_W, 0, 0),
			Size = UDim2.new(1, -HEX_LABEL_W, 1, 0),
			Ref = q.PreRef(nil :: TextBox?),
		}),
	}
end

return {
	HSV = HSV,
	RGB = RGB,
	Hex = Hex,
}
