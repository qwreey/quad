--!strict
--[[
	Gallery section "TextInput": TextField (Filled / Outlined, floating label, supporting + error text, counter, icons,
	prefix / suffix, multi-line, disabled; Outlined fields on a tinted panel and on a gradient — the label notch is a cut
	in the outline, nothing is painted in a surface color) and Select. The email field validates live: `Error` is a `:Compute` of the same
	Source the field writes, and `ErrorText` swaps in for the supporting text (the M3 error state). Typed text and the
	chosen option live in the Memo, so they survive switching tabs.
]]

local q = require("./Quad")
local Common = require("./Common")
local Material = require("../src")
local D = q.Declaration

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
	local cents = ctx.Memo("text.cents", function()
		return q.Source(1999)
	end)
	local centsCaption: q.State<string> = cents:Compute(function(self)
		return `Stored: {self:Get()} (an integer; the Unit shows it as dollars)`
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
			Material.TextField({
				Theme = theme,
				Label = "Name",
				Value = name,
				SupportingText = "As on your card",
				MaxLength = 20,
			}),
			Common.Caption(ctx, summary, false),
			Material.TextField({
				Theme = theme,
				Label = "Email",
				Value = email,
				Error = bad,
				ErrorText = "Enter a valid address",
				SupportingText = "We never send spam",
				LeadingIcon = ctx.Icon,
			}),
			Material.TextField({ Theme = theme, Label = "Disabled", Value = q.Source("Read only"), Disabled = true }),
		}, 280, 12),
	}

	local outlined: { Instance } = {
		Common.Column({
			Material.TextField({
				Theme = theme,
				Variant = "Outlined",
				Label = "Price",
				Value = price,
				Prefix = "$",
				Suffix = "USD",
			}),
			Material.NumberField({
				Theme = theme,
				Variant = "Outlined",
				Label = "Amount",
				Value = cents,
				Unit = { Scale = 0.01, Prefix = "$" },
				Min = 0,
				Max = 100000,
				Step = 1,
				SupportingText = "NumberField: commits when you leave the field",
				InvalidText = "Not a number",
			}),
			Common.Caption(ctx, centsCaption, false),
			Material.TextField({
				Theme = theme,
				Variant = "Outlined",
				Label = "PIN",
				Value = pin,
				Placeholder = "4 digits",
				TrailingIcon = ctx.Icon,
				SupportingText = "Optional",
			}),
			Material.TextField({
				Theme = theme,
				Variant = "Outlined",
				Label = "Notes",
				Value = note,
				MultiLine = true,
				MaxLength = 80,
				SupportingText = "Multi-line, with a counter",
			}),
			Material.TextField({
				Theme = theme,
				Variant = "Outlined",
				Label = "Error shown",
				Value = q.Source("oops"),
				Error = true,
				ErrorText = "Always in error",
			}),
			Material.TextField({ Theme = theme, Variant = "Outlined", Label = "Disabled", Value = q.Source(""), Disabled = true }),
		}, 280, 12),
	}

	-- Outlined on something that is not the page surface: the outline is cut open under the floated label, so whatever is
	-- behind the field shows through the notch (a picture stands in as a gradient)
	local tinted = ctx.Memo("text.tinted", function()
		return q.Source("Lavender")
	end)
	local pictured = ctx.Memo("text.pictured", function()
		return q.Source("")
	end)
	-- the light scheme's ink on the fixed pastel picture, whichever scheme the gallery is in
	local lightTheme = ctx.Memo("text.lightTheme", function()
		return Material.Theme.new({ Scheme = "light" })
	end)
	local function backdrop(name: string, color: Color3 | q.State<Color3>, gradient: Instance?, field: Instance): Instance
		return D.Frame {
			Name = name,
			Size = UDim2.fromOffset(280, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			UICorner = UDim.new(0, 12),
			UIPaddingOffset = 16,
			gradient or q.None,
			field,
		}
	end
	local backdrops: { Instance } = {
		backdrop(
			"Tinted",
			theme.Color.PrimaryContainer,
			nil,
			Material.TextField({ Theme = theme, Variant = "Outlined", Label = "On a tinted panel", Value = tinted })
		),
		backdrop(
			"Pictured",
			Color3.new(1, 1, 1),
			D.UIGradient {
				Rotation = 35,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 214, 140)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(244, 143, 177)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(144, 202, 249)),
				}),
			},
			Material.TextField({
				Theme = lightTheme,
				Variant = "Outlined",
				Label = "On a picture",
				Value = pictured,
				SupportingText = "Focus it: the line opens under the label",
			})
		),
	}

	local selects: { Instance } = {
		Common.Column({
			Material.Select({
				Theme = theme,
				Overlay = ctx.Overlay,
				Label = "Fruit",
				Options = FRUITS,
				Value = fruit,
				SupportingText = "Opens a menu under the field",
			}),
			Material.Select({
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
			Material.Select({
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
		Common.Group(
			ctx,
			"TextField: Outlined on other backdrops",
			backdrops,
			"The label notch is a cut in the outline (three clipped copies of it), not a patch in the surface color."
		),
		Common.Group(ctx, "Select", selects),
	})
end
