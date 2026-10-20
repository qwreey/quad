--!strict
--[[
	Hex field: the kit's outlined `TextField` ("Hex", floating label) bound to a LOCAL string Source.

	Flow (nothing here feeds its own upstream):
	  model.hsv --Compute--> model.hex ("#RRGGBB") --Effect--> hexText (Source<string>) --Text/q.Out--> TextBox
	  TextBox typing -> hexText (TextField's own write-back); the model is NOT touched while typing
	  blur / Enter (`OnFocusChanged(false)`) -> `model.setHex(hexText)` (hue-preserving), then hexText is rewritten
	  to the canonical "#RRGGBB" — so "f80" becomes "#FF8800" and garbage reverts to the current color.
	The Effect fires when the MODEL's hex changes; typing changes only `hexText`, so it never overwrites an edit in
	progress. While the text does not parse the field shows the error color.
	No live (per-keystroke) commit, BY CHOICE: the kit TextField does have `OnChange` (after a user edit), but a
	commit from it would make `model.hex` change as soon as the text parses ("f80" -> "#FF8800"), and the Effect above
	would then rewrite `hexText` under the user's fingers mid-typing. (An Observer on `hexText` that wrote the model
	would also feed its own upstream through that Effect — a loop the rules forbid.) Committing on blur / Enter keeps
	the field editable until the user is done.

	Returns `{ Field, Sync }`: `Field` is the TextField host (place it where it goes), `Sync` is the Effect — it must
	sit in the array part of an element that lives as long as the picker (the panel host does that).
]]

local q = require("../../Quad")
local Theme = require("../../Theme")
local TextField = require("../../TextField")
local ColorModel = require("../ColorModel")
local Model = require("./Model")

export type Props = {
	read Model: Model.Model,
	read Theme: Theme.Theme?,
	read Disabled: (boolean | q.State<boolean>)?,
	read Modifier: q.ModifierInto<Frame>?,
}

export type Hex = { read Field: Frame, read Sync: q.Effect }

local function HexField(props: Props): Hex
	local model = props.Model
	local hexText = q.Source(model.hex:Get())
	local invalid: q.State<boolean> = hexText:Compute(function(self)
		return ColorModel.parseHex(self:Get()) == nil
	end)
	local sync = q.Effect(function()
		hexText:SetIfChanged(model.hex:Get())
	end, model.hex)

	local field = TextField({
		Variant = "Outlined",
		Label = "Hex",
		Value = hexText,
		Error = invalid,
		Disabled = props.Disabled,
		Theme = props.Theme,
		Modifier = props.Modifier,
		OnFocusChanged = function(focused: boolean)
			if focused then
				return
			end
			if model.setHex(hexText:Get()) then
				model.remember()
			end
			hexText:SetIfChanged(model.hex:Get())
		end,
	})
	return { Field = field, Sync = sync }
end

return HexField
