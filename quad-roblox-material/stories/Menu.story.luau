--!strict
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local StoryParts = require("./StoryParts")
local ICON = StoryParts.ICON
local row = StoryParts.row
local holder = StoryParts.holder
local caption = StoryParts.caption
local show = StoryParts.show
local tostr = StoryParts.tostr
local page = StoryParts.page
local themed = StoryParts.themed

-- Menu: `Menu.Button` (a Button that opens the items under itself) and `Menu.open` driven by a plain button with a
-- handle. Items are fixed per open, but an item's `Disabled` is a live State. Everything opens in the story's overlay.
return StoryKit.story({
	controls = {
		Label = "Actions",
		DisableDelete = false,
		Width = StoryKit.Slider(0, 0, 320, 8), -- 0 = anchor width (clamped 112..280)
		Variant = StoryKit.Choose({ "Tonal", "Filled", "Outlined", "Text", "Elevated" }),
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c, ctx)
		local theme, follow = themed(c.Scheme)
		local last = q.Source("(nothing yet)")
		local function act(name: string): () -> ()
			return function()
				last:Set(name)
			end
		end
		local items: { Material.MenuEntry } = {
			{ Label = "Rename", OnClick = act("Rename"), Leading = ICON },
			{ Label = "Duplicate", Trailing = "Ctrl+D", OnClick = act("Duplicate") },
			{ Label = "Pinned", Selected = true, OnClick = act("Pinned") },
			"divider",
			{ Label = "Delete", OnClick = act("Delete"), Disabled = c.DisableDelete },
		}
		local variant: q.State<Material.ButtonVariant> = c.Variant:Compute(function(self)
			local v: any = self:Get()
			return v
		end)
		local opener: GuiObject? = nil
		local isOpen = q.Source(false)
		local handleBtn = Material.Button({
			Label = "Menu.open",
			Variant = "Outlined",
			Theme = theme,
			OnClick = function()
				local anchor = opener
				if anchor == nil then
					return
				end
				local w: number = c.Width:Get()
				Material.Menu.open({
					Anchor = anchor,
					Items = items,
					Overlay = ctx.Overlay,
					Theme = theme,
					Width = if w > 0 then w else nil,
					OnClose = function()
						isOpen:Set(false)
					end,
				})
				isOpen:Set(true)
			end,
		})
		opener = handleBtn
		return page(theme, follow, {
			holder(
				48,
				StoryKit.rebuild<<Material.ButtonVariant>>(variant, function(v: Material.ButtonVariant)
					return Material.Menu.Button({
						Label = c.Label,
						Variant = v,
						Items = items,
						Overlay = ctx.Overlay,
						Theme = theme,
					})
				end)
			),
			row({ handleBtn, caption(theme, show<<boolean>>(isOpen, "open: ", tostr)) }),
			caption(theme, show<<string>>(last, "Last item: ", tostr)),
		})
	end,
})
