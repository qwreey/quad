--!strict
--[[
	Gallery section "TextInput": TextField (Filled / Outlined, floating label, supporting + error text, counter, icons,
	prefix / suffix, multi-line, disabled) and Select. The email field validates live: `Error` is a `:Compute` of the same
	Source the field writes, and `ErrorText` swaps in for the supporting text (the M3 error state). Typed text and the
	chosen option live in the Memo, so they survive switching tabs.
]]

local q = require("../Quad")
local Common = require("./Common")
local TextField = require("../TextField")
local Select = require("../Select")

type Ctx = Common.Ctx

local FRUITS = { "Apple", "Banana", "Cherry", "Dragon fruit", "Elderberry" }

return function(ctx: Ctx): Instance
	local theme = ctx.Theme
	local name = ctx.Memo("text.name", function()
		return q.Source("")
	end)
	local email = ctx.Memo("text.email", function()
		return q.Source("not-an-email")
	end)
	local note = ctx.Memo("text.note", function()
		return q.Source("")
	end)
	local pin = ctx.Memo("text.pin", function()
		return q.Source("")
	end)
	local price = ctx.Memo("text.price", function()
		return q.Source("12.50")
	end)
	local fruit = ctx.Memo("text.fruit", function()
		return q.Source<<string?>>(nil)
	end)
	local fruit2 = ctx.Memo("text.fruit2", function()
		return q.Source<<string?>>("Cherry")
	end)
	local bad: q.State<boolean> = email:Compute(function(self)
		local v = self:Get()
		return v ~= "" and string.match(v, "^[^@%s]+@[^@%s]+%.[^@%s]+$") == nil
	end)
	local summary: q.State<string> = name:Compute(function(self)
		return `Name: "{self:Get()}"`
	end)

	local filled: { Instance } = {
		Common.Column({
			TextField({
				Theme = theme,
				Label = "Name",
				Value = name,
				SupportingText = "As on your card",
				MaxLength = 20,
			}),
			Common.Caption(ctx, summary, false),
			TextField({
				Theme = theme,
				Label = "Email",
				Value = email,
				Error = bad,
				ErrorText = "Enter a valid address",
				SupportingText = "We never send spam",
				LeadingIcon = ctx.Icon,
			}),
			TextField({ Theme = theme, Label = "Disabled", Value = q.Source("Read only"), Disabled = true }),
		}, 280, 12),
	}

	local outlined: { Instance } = {
		Common.Column({
			TextField({
				Theme = theme,
				Variant = "Outlined",
				Label = "Price",
				Value = price,
				Prefix = "$",
				Suffix = "USD",
			}),
			TextField({
				Theme = theme,
				Variant = "Outlined",
				Label = "PIN",
				Value = pin,
				Placeholder = "4 digits",
				TrailingIcon = ctx.Icon,
				SupportingText = "Optional",
			}),
			TextField({
				Theme = theme,
				Variant = "Outlined",
				Label = "Notes",
				Value = note,
				MultiLine = true,
				MaxLength = 80,
				SupportingText = "Multi-line, with a counter",
			}),
			TextField({
				Theme = theme,
				Variant = "Outlined",
				Label = "Error shown",
				Value = q.Source("oops"),
				Error = true,
				ErrorText = "Always in error",
			}),
			TextField({ Theme = theme, Variant = "Outlined", Label = "Disabled", Value = q.Source(""), Disabled = true }),
		}, 280, 12),
	}

	local selects: { Instance } = {
		Common.Column({
			Select({
				Theme = theme,
				Overlay = ctx.Overlay,
				Label = "Fruit",
				Options = FRUITS,
				Value = fruit,
				SupportingText = "Opens a menu under the field",
			}),
			Select({
				Theme = theme,
				Overlay = ctx.Overlay,
				Variant = "Outlined",
				Label = "Fruit (outlined)",
				Options = FRUITS,
				Value = fruit2,
				Format = string.upper,
			}),
			Common.Caption(ctx, Common.text<<string?>>(fruit, function(v: string?)
				return `Chosen: {v or "(nothing)"}`
			end), false),
			Select({
				Theme = theme,
				Overlay = ctx.Overlay,
				Label = "Disabled",
				Options = FRUITS,
				Value = q.Source<<string?>>(nil),
				Disabled = true,
			}),
		}, 280, 12),
	}

	return Common.Section(ctx, "TextInput", "Text input", {
		Common.Group(ctx, "TextField: Filled", filled, "The email field turns to the error state while the text is not an address."),
		Common.Group(ctx, "TextField: Outlined", outlined),
		Common.Group(ctx, "Select", selects),
	})
end
