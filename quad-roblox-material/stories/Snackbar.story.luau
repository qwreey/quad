--!strict
-- Snackbar: two hosts bound to the story overlay — the default one at the bottom and one placed at the top (`Position`
-- picks which one "Show" uses). Text / Duration / Close / Action are read from the controls when "Show" is pressed; the
-- hosts' `Pending` States (queue lengths, summed) and the last dismiss reason are shown live.
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local D = q.Declaration
local StoryParts = require("./StoryParts")
local themed = StoryParts.themed

return StoryKit.story({
	controls = {
		Text = "Message archived",
		Duration = StoryKit.Slider(4, 1, 12, 1),
		Persistent = false,
		Close = false,
		Action = true,
		Position = StoryKit.Choose({ "Bottom", "Top" }),
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c, ctx)
		local theme, follow = themed(c.Scheme)
		local bar = Material.Snackbar.new({ Overlay = ctx.Overlay, Theme = theme })
		local topBar = Material.Snackbar.new({ Overlay = ctx.Overlay, Theme = theme, Position = "Top" })
		local last = q.Source("(none yet)")
		local count = 0

		local function show(text: string, withAction: boolean, duration: number?)
			local host = if c.Position:Get() == "Top" then topBar else bar
			host:Show({
				Text = text,
				Action = if withAction
					then {
						Label = "Undo",
						OnClick = function()
							last:Set("undo pressed")
						end,
					}
					else nil,
				Close = c.Close:Get() == true,
				Duration = duration,
				OnDismiss = function(reason: Material.SnackbarDismissReason)
					last:Set(`dismissed: {reason}`)
				end,
			})
		end

		return D.Frame {
			follow,
			-- the hosts die with the story root (the overlay layer's death would finalize them too)
			q.OnDestroyed(function()
				bar:Destroy()
				topBar:Destroy()
			end),
			Name = "SnackbarStory",
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Color.Surface,
			UIPaddingOffset = 24,
			D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12) },
			D.Frame {
				Name = "Row",
				LayoutOrder = 1,
				Size = UDim2.fromOffset(460, 40),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				D.UIListLayout {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 8),
				},
				Material.Button({
					Theme = theme,
					Label = "Show",
					LayoutOrder = 1,
					OnClick = function()
						show(
							c.Text:Get(),
							c.Action:Get() == true,
							if c.Persistent:Get() == true then math.huge else c.Duration:Get()
						)
					end,
				}),
				Material.Button({
					Theme = theme,
					Variant = "Tonal",
					Label = "Queue three",
					LayoutOrder = 2,
					OnClick = function()
						for _ = 1, 3 do
							count += 1
							show(`Queued message {count}`, false, 2)
						end
					end,
				}),
			},
			D.TextLabel {
				Material.Text.Label("BodyMedium"),
				Name = "Status",
				LayoutOrder = 2,
				Size = UDim2.fromOffset(460, 24),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = theme.Color.OnSurface,
				Text = bar.Pending:Compute(function(self: q.StateData<number>, _prev: string?, top: q.State<number>): string
					return `Waiting in the queue: {self:Get() + top:Get()}`
				end, topBar.Pending),
			},
			D.TextLabel {
				Material.Text.Label("BodyMedium"),
				Name = "Last",
				LayoutOrder = 3,
				Size = UDim2.fromOffset(460, 24),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = theme.Color.OnSurfaceVariant,
				Text = last:Compute(function(self: q.StateData<string>): string
					return `Last: {self:Get()}`
				end),
			},
		}
	end,
})
