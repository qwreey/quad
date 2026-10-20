--!strict
-- Side sheets: a ModalSideSheet opened from a button (options read at click time) and a standard SideSheet docked in a
-- clipped mock screen, rebuilt when its construction-time props (edge, headline on/off, detached) change; a button
-- toggles it. `Detached` puts both 16 px off the edge with four round corners (the screen's content area is tinted so
-- the surface-colored standard sheet shows).
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local Frame = q.Elem "Frame"
local StoryParts = require("./StoryParts")
local themed = StoryParts.themed

type Config = { Edge: Material.SideSheetEdge, Header: boolean, Detached: boolean }

return StoryKit.story({
	controls = {
		Headline = "Details",
		Header = true,
		Edge = StoryKit.Choose({ "End", "Start" }),
		Draggable = true,
		Detached = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c, ctx)
		local theme, follow = themed(c.Scheme)
		local state = Material.SheetState({ InitialValue = "Expanded", EnabledValues = { "Hidden", "Expanded" } })
		local config: q.State<Config> = c.Edge:Compute(function(
			self: q.StateData<any>,
			_prev: Config?,
			header: q.State<any>,
			detached: q.State<any>
		): Config
			return { Edge = self:Get(), Header = header:Get() == true, Detached = detached:Get() == true }
		end, c.Header, c.Detached)
		local standard = StoryKit.rebuild<<Config>>(config, function(cfg: Config)
			return Frame {
				Name = "Screen",
				Size = UDim2.fromOffset(520, 320),
				BackgroundColor3 = theme.Color.SurfaceContainerHigh,
				BackgroundTransparency = if cfg.Detached then 0 else 1,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Material.SideSheet({
					Theme = theme,
					SheetState = state,
					SheetEdge = cfg.Edge,
					Detached = cfg.Detached,
					Headline = if cfg.Header then c.Headline else nil,
					Children = q.Slot<<Instance>>({ StoryParts.caption(theme, "Standard side sheet content") }),
				}),
			}
		end, { Size = UDim2.fromOffset(520, 320) })

		return StoryParts.page(theme, follow, {
			StoryParts.row({
				Material.Button({
					Theme = theme,
					Label = "Open modal side sheet",
					OnClick = function()
						Material.ModalSideSheet.open({
							Overlay = ctx.Overlay,
							Theme = theme,
							Headline = if c.Header:Get() == true then c.Headline:Get() else nil,
							SheetEdge = c.Edge:Get(),
							Detached = c.Detached:Get() == true,
							Draggable = c.Draggable:Get() == true,
							Children = q.Slot<<Instance>>({ StoryParts.caption(theme, "Modal side sheet content") }),
						})
					end,
				}),
				Material.Button({
					Theme = theme,
					Variant = "Outlined",
					Label = "Toggle the standard sheet",
					OnClick = function()
						if state.TargetValue:Get() == "Hidden" then
							state.Expand()
						else
							state.Hide()
						end
					end,
				}),
			}),
			standard,
		})
	end,
})
