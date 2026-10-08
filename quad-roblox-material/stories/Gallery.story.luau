--!strict
-- Gallery: the kit's whole showcase panel in one story. It gets the story overlay (so menus / dialogs / snackbars /
-- tooltips open inside the story view, never in a layer of their own) and a per-story Theme driven by the Scheme control.
-- Tab is a two-way Source: clicking a tab inside the gallery writes it, the control panel can write it too.
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local Gallery = require("../gallery")

return StoryKit.story({
	controls = {
		Scheme = StoryKit.Choose({ "light", "dark" }),
		Tab = StoryKit.Choose({ "Buttons", "Selection", "Text", "Surfaces", "Overlays", "Chips", "Pickers", "Theme" }),
	},
	render = function(c, ctx)
		local theme = Material.Theme.new({ Scheme = c.Scheme:Get() })
		local follow = q.Effect(function()
			theme.Scheme:SetIfChanged(c.Scheme:Get())
		end, c.Scheme)
		-- the follow Effect needs a host to live on (GalleryPanel has no Hooks): a transparent full-size wrapper
		return q.Declaration.Frame {
			follow,
			Name = "GalleryStory",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Gallery.GalleryPanel({ Theme = theme, Overlay = ctx.Overlay, Selected = c.Tab }),
		}
	end,
})
