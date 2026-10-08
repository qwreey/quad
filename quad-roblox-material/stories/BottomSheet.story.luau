--!strict
-- Bottom sheets: a ModalBottomSheet opened from a button (the options are read at click time) and a BottomSheetScaffold
-- docked in a clipped mock screen. PeekHeight / DragHandle are construction-time props, so the scaffold is rebuilt when
-- they change (StoryKit.rebuild). The scaffold's SheetState value and the last modal result are shown live.
local Material = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local D = q.Declaration
local StoryParts = require("./StoryParts")
local themed = StoryParts.themed

type Config = { Peek: number, Handle: boolean }

return StoryKit.story({
	controls = {
		Rows = StoryKit.Slider(4, 1, 20, 1),
		PeekHeight = StoryKit.Slider(56, 0, 200, 8),
		DragHandle = true,
		DismissOnScrim = true,
		DismissOnEscape = true,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c, ctx)
		local theme, follow = themed(c.Scheme)
		local result = q.Source<<string>>("(none yet)")
		local value = q.Source<<string>>("PartiallyExpanded")

		local function rows(count: number, onPick: ((string) -> ())?): q.Slot<Instance>
			local list: { Instance } = {}
			for i = 1, count do
				table.insert(
					list,
					Material.ListItem({
						Theme = theme,
						Headline = `Row {i}`,
						LayoutOrder = i,
						OnClick = if onPick
							then function()
								onPick(`Row {i}`)
							end
							else nil,
					})
				)
			end
			return q.Slot<<Instance>>(list)
		end

		local config: q.State<Config> = c.PeekHeight:Compute(function(self: q.StateData<any>, _prev: Config?, handle: q.State<any>): Config
			return { Peek = self:Get(), Handle = handle:Get() == true }
		end, c.DragHandle)

		local scaffold = StoryKit.rebuild<<Config>>(config, function(cfg: Config)
			local state = Material.SheetState({ InitialValue = "PartiallyExpanded" })
			return D.Frame {
				Name = "Screen",
				Size = UDim2.fromOffset(360, 400),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				Material.BottomSheetScaffold({
					Theme = theme,
					SheetState = state,
					SheetPeekHeight = cfg.Peek,
					SheetDragHandle = cfg.Handle,
					Content = q.Slot<<Instance>>({ StoryParts.caption(theme, "Screen content (BottomSheetScaffold)") }),
					SheetContent = rows(5, nil),
					Hooks = {
						q.Effect(function()
							value:Set(state.CurrentValue:Get())
						end, state.CurrentValue),
					},
				}),
			}
		end, { Size = UDim2.fromOffset(360, 400) })

		return StoryParts.page(theme, follow, {
			StoryParts.row({
				Material.Button({
					Theme = theme,
					Label = "Open modal sheet",
					OnClick = function()
						local handle: Material.ModalBottomSheetHandle
						handle = Material.ModalBottomSheet.open({
							Overlay = ctx.Overlay,
							Theme = theme,
							DragHandle = c.DragHandle:Get() == true,
							DismissOnScrim = c.DismissOnScrim:Get() == true,
							DismissOnEscape = c.DismissOnEscape:Get() == true,
							Children = rows(c.Rows:Get(), function(label: string)
								handle.Close(label)
							end),
							OnClose = function(r: unknown?)
								result:Set(if r == nil then "dismissed" else tostring(r))
							end,
						})
					end,
				}),
				StoryParts.caption(theme, StoryParts.show<<string>>(result, "Last modal result: ", StoryParts.tostr)),
				StoryParts.caption(theme, StoryParts.show<<string>>(value, "Scaffold sheet: ", StoryParts.tostr)),
			}),
			scaffold,
		})
	end,
})
