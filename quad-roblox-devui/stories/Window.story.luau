--!strict
-- Window: title, collapse (to an icon), close, resize, edge docking, and saving / restoring the layout. Title / Open / Collapsed are
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
				Devui.Text({ Text = "Drag the title bar, the corner grip, collapse to an icon (press it to expand, drag it to move) or close me. Drag the title bar to the left or right edge to dock me; drag it off again to float." }),
				Devui.Separator({}),
				Shared.show("Open", c.Open),
				Shared.show("Collapsed", c.Collapsed),
				Shared.show("Size", size),
				Shared.show("Position", position)
			),
		})
		local function button(text: string, x: number, onClick: () -> ())
			return Frame({
				Name = text,
				Position = UDim2.new(0, x, 1, -40),
				Size = UDim2.fromOffset(150, 24),
				BackgroundTransparency = 1,
				Devui.Button({ Text = text, OnClick = onClick }),
			})
		end
		return Frame({
			Name = "WindowStory",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			window,
			button("reopen the window", 20, function()
				c.Open:Set(true)
			end),
			button("save layout", 180, function()
				local layout = manager:ExportLayout()
				saved = layout
				local g = layout.Floating[1]
				local dock = layout.Left or layout.Right
				if g ~= nil then
					savedText:Set(`saved: ({g.Position[2]}, {g.Position[4]}) {g.Size[1]} x {g.Size[2]}, collapsed {g.Collapsed}, open {layout.Windows.story.Open}`)
				elseif dock ~= nil then
					local edge = if layout.Left ~= nil then "left" else "right"
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
				BackgroundTransparency = 1,
				Devui.Text({ Text = savedText }),
			}),
		})
	end,
})
