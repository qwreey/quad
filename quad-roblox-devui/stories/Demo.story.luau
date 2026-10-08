--!strict
-- The kit's full Demo window (Iris ShowDemoWindow equivalent), hosted in the story with the story's own overlay so
-- Combo / Menu / Tooltip popups draw inside the story view. A control opens / closes the window.
local Demo = require("../gallery")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")

return StoryKit.story({
	controls = {
		Open = true,
	},
	render = function(c, ctx)
		return Demo.DemoWindow({
			Overlay = ctx.Overlay,
			Open = c.Open,
			Size = q.Source(Vector2.new(460, 560)),
		})
	end,
})
