--!strict
-- Window: title, collapse (to an icon), close, resize, edge docking, tab groups, and saving / restoring the layout. Title / Open / Collapsed are
-- control-panel Sources the window binds directly; dragging the grip, the title bar or the collapsed icon shows up in
-- the readouts below (Size / Position are Sources the window writes). "save layout" keeps the manager's export in a
-- local; move / collapse / close the window, then "restore layout" puts it back (ImportLayout writes the same Sources).
local Devui = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local Shared = require("./Shared")
local Frame = q.Elem "Frame"
local Kids = Devui.Kids

return StoryKit.story({
	controls = {
		Title = "My window",
		Open = true,
		Collapsed = false,
	},
	render = function(c)
		local size = q.Source(Vector2.new(320, 220))
		local position = q.Source(UDim2.fromOffset(20, 20))
		-- a manager of its own: the story's layout does not mix with other stories' windows
		local manager = Devui.WindowManager.new()
		local saved: Devui.WindowLayout? = nil
		local savedText = q.Source("(nothing saved)")
		local window = Devui.Window({
			Title = c.Title,
			Key = "story",
			Manager = manager,
			Open = c.Open,
			Collapsed = c.Collapsed,
			Size = size,
			Position = position,
			Children = Kids(
				Devui.Text({ Text = "Drag the title bar, the corner grip, collapse to an icon (press it to expand, drag it to move) or close me. Drag the title bar to the left or right edge to dock me; drag it off again to float. Drop me on another window's title bar or centre to make tabs; drag a tab out to take it apart." }),
				Devui.Separator({}),
				Shared.show("Open", c.Open),
				Shared.show("Collapsed", c.Collapsed),
				Shared.show("Size", size),
				Shared.show("Position", position)
			),
		})
		-- two more windows of the same manager to group as tabs (drop one on another's title bar or centre)
		local function extra(title: string, key: string, x: number): Frame
			return Devui.Window({
				Title = title,
				Key = key,
				Manager = manager,
				Position = q.Source(UDim2.fromOffset(x, 260)),
				Size = q.Source(Vector2.new(220, 150)),
				Children = Kids(Devui.Text({ Text = `{title}: drag my title bar onto another window` })),
			})
		end
		local notes = extra("Notes", "notes", 360)
		local log = extra("Log", "log", 600)
		local function button(text: string, x: number, onClick: () -> ())
			return Frame({
				Name = text,
				Position = UDim2.new(0, x, 1, -40),
				Size = UDim2.fromOffset(150, 24),
				ZIndex = 0, -- the story's own controls stay under the windows (a docked panel covers them)
				BackgroundTransparency = 1,
				Devui.Button({ Text = text, OnClick = onClick }),
			})
		end
		return Frame({
			Name = "WindowStory",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			window,
			notes,
			log,
			button("reopen the window", 20, function()
				c.Open:Set(true)
			end),
			button("save layout", 180, function()
				local layout = manager:ExportLayout()
				saved = layout
				local g: any = nil
				for _, group in layout.Floating do
					if table.find(group.Node.Tabs, "story") ~= nil then
						g = group
					end
				end
				-- the edge the story window is docked on (another window may hold the other edge)
				local dock: any, edge = nil, ""
				for _, at in { "Left", "Right" } do
					local d = (layout :: any)[at]
					if d ~= nil and table.find(d.Node.Tabs, "story") ~= nil then
						dock, edge = d, string.lower(at)
					end
				end
				if g ~= nil and #g.Node.Tabs > 1 then
					savedText:Set(`saved: a tab group of {#g.Node.Tabs} ({table.concat(g.Node.Tabs, ", ")}), selected {g.Node.Selected}`)
				elseif g ~= nil then
					savedText:Set(`saved: ({g.Position[2]}, {g.Position[4]}) {g.Size[1]} x {g.Size[2]}, collapsed {g.Collapsed}, open {layout.Windows.story.Open}`)
				elseif dock ~= nil then
					savedText:Set(`saved: docked {edge}, width {dock.Width}, collapsed {dock.Collapsed}, open {layout.Windows.story.Open}`)
				end
			end),
			button("restore layout", 340, function()
				if saved ~= nil then
					manager:ImportLayout(saved)
				end
			end),
			Frame({
				Name = "Saved",
				Position = UDim2.new(0, 20, 1, -70),
				Size = UDim2.fromOffset(470, 24),
				ZIndex = 0,
				BackgroundTransparency = 1,
				Devui.Text({ Text = savedText }),
			}),
		})
	end,
})
