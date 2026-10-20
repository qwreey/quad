--!strict
-- Dialog: buttons open Dialog.open / confirm / alert in the story overlay. The options are read from the controls at
-- click time (Dialog options are plain values), the result of the last dialog is a Source shown live.
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local Frame = q.Elem "Frame"
local TextLabel = q.Elem "TextLabel"
local UIListLayout = q.Elem "UIListLayout"
local StoryParts = require("./StoryParts")
local themed = StoryParts.themed

return StoryKit.story({
	controls = {
		Headline = "Discard draft?",
		Body = "Your changes will be lost.",
		Width = StoryKit.Slider(312, 280, 560, 8),
		DismissOnScrim = true,
		DismissOnEscape = true,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c, ctx)
		local theme, follow = themed(c.Scheme)
		local result = q.Source("(none yet)")
		local function describe(r: unknown?): string
			return if r == nil then "(closed without result)" else tostring(r)
		end

		local function row(...: Instance): Frame
			return Frame {
				Name = "Row",
				Size = UDim2.fromOffset(420, 40),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				UIListLayout {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 8),
				},
				...
			}
		end

		return Frame {
			follow,
			Name = "DialogStory",
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Color.Surface,
			UIPaddingOffset = 24,
			UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12) },
			row(
				Material.Button({
					Theme = theme,
					Label = "Open dialog",
					LayoutOrder = 1,
					OnClick = function()
						Material.Dialog.open({
							Headline = c.Headline:Get(),
							Body = c.Body:Get(),
							Width = c.Width:Get(),
							DismissOnScrim = c.DismissOnScrim:Get() == true,
							DismissOnEscape = c.DismissOnEscape:Get() == true,
							DismissResult = "dismissed",
							Actions = {
								{ Label = "Cancel", Result = "cancel" },
								{ Label = "Discard", Result = "discard", Variant = "Filled" },
								{ Label = "Later", Result = "later", Disabled = true },
							},
							OnClose = function(r: unknown?)
								result:Set(describe(r))
							end,
							Overlay = ctx.Overlay,
							Theme = theme,
						})
					end,
				}),
				Material.Button({
					Theme = theme,
					Variant = "Tonal",
					Label = "Confirm",
					LayoutOrder = 2,
					OnClick = function()
						Material.Dialog.confirm({
							Headline = c.Headline:Get(),
							Body = c.Body:Get(),
							OnClose = function(ok: unknown?)
								result:Set(describe(ok))
							end,
							Overlay = ctx.Overlay,
							Theme = theme,
						})
					end,
				}),
				Material.Button({
					Theme = theme,
					Variant = "Outlined",
					Label = "Alert",
					LayoutOrder = 3,
					OnClick = function()
						Material.Dialog.alert({
							Headline = c.Headline:Get(),
							Body = c.Body:Get(),
							OnClose = function(r: unknown?)
								result:Set(describe(r))
							end,
							Overlay = ctx.Overlay,
							Theme = theme,
						})
					end,
				})
			),
			TextLabel {
				Material.Text.Label("BodyMedium"),
				Name = "Result",
				LayoutOrder = 2,
				Size = UDim2.fromOffset(420, 24),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = theme.Color.OnSurface,
				Text = result:Compute(function(self: q.StateData<string>): string
					return `Last dialog result: {self:Get()}`
				end),
			},
		}
	end,
})
