--!strict
--[[
	Gallery section "Navigation": the layout pieces for moving around an app, each inside a mock screen (`Common.Screen` —
	they are layouts, not floating things). Now: the three navigation drawers (Compose ModalNavigationDrawer /
	DismissibleNavigationDrawer / PermanentNavigationDrawer) with their sheets and a NavigationDrawerItems list of many
	destinations (headlines, dividers, badges — the drawer scrolls). The navigation bar / rail, app bars and toolbars join
	this tab later.
	The selected destination of every drawer is ONE Memo Source (`nav.page`), so the three drawers show the same choice and
	it survives leaving the tab. The destination icons are Material Design Icons image ids from the kit's icon dump
	(qwreey/qwreey.roblox.plugins@7b6552a:IconPack.Plugin/res/IconDump.lua, baseline — each checked as an image asset,
	AssetTypeId 1, creator qwreey74_icon); the menu button uses `Icons` "menu".
]]

local q = require("./Quad")
local Common = require("./Common")
local Material = require("../src")
local D = q.Declaration

type Ctx = Common.Ctx

local INBOX = "rbxassetid://6035067831" -- baseline/content/inbox
local SEND = "rbxassetid://6035067832" -- baseline/content/send
local FAVORITE = "rbxassetid://6023426974" -- baseline/action/favorite
local DELETE = "rbxassetid://6022668885" -- baseline/action/delete

local titleStyle = Material.Text.Label("TitleLarge")

local function destinations(): { Material.NavigationDrawerEntry<string> }
	local items: { Material.NavigationDrawerEntry<string> } = {
		{ Headline = "Mail" },
		{ Key = "inbox", Label = "Inbox", Icon = INBOX, Badge = "24" },
		{ Key = "outbox", Label = "Outbox", Icon = SEND },
		{ Key = "favorites", Label = "Favorites", Icon = FAVORITE },
		{ Key = "trash", Label = "Trash", Icon = DELETE },
		"divider",
		{ Headline = "Labels" },
	}
	for i = 1, 8 do
		table.insert(items, { Key = `label{i}`, Label = `Label {i}`, Icon = "check" })
	end
	return items
end

-- a top bar inside the mock screen: an optional menu button, the selected destination as the title
local function topBar(ctx: Ctx, page: q.State<string>, onMenu: (() -> ())?): Frame
	local theme = ctx.Theme
	return D.Frame {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		D.UIPadding { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 16) },
		D.UIListLayout {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 4),
		},
		if onMenu
			then Material.IconButton({
				Theme = theme,
				Icon = Material.Icons.asset("menu") or "",
				OnClick = onMenu,
				TouchTarget = true,
			})
			else q.None,
		D.TextLabel {
			Name = "Title",
			titleStyle,
			Size = UDim2.fromOffset(0, 28),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = 2,
			TextColor3 = theme.Color.OnSurface,
			Text = Common.text<<string>>(page, function(v: string): string
				return `Page: {v}`
			end),
		},
	}
end

local function screenContent(ctx: Ctx, page: q.State<string>, onMenu: (() -> ())?, note: string): q.Slot<Instance>
	return q.Slot<<Instance>>({
		D.Frame {
			Name = "Page",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) },
			topBar(ctx, page, onMenu),
			D.Frame {
				Name = "Body",
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = 2,
				UIPaddingOffset = 16,
				Common.Caption(ctx, note),
			},
		},
	})
end

return function(ctx: Ctx): Instance
	local theme = ctx.Theme
	local page = ctx.Memo("nav.page", function()
		return q.Source("inbox")
	end)

	local function isPage(key: string): q.State<boolean>
		local selected: q.State<boolean> = page:Compute(function(self)
			return self:Get() == key
		end)
		return selected
	end

	local modalState = Material.DrawerState({ InitialValue = "Closed" })
	local modal = Common.Screen(ctx, "ModalDrawerScreen", 400, 520, {
		Material.ModalNavigationDrawer({
			Theme = theme,
			DrawerState = modalState,
			DrawerContent = Material.ModalDrawerSheet({
				Theme = theme,
				Children = q.Slot<<Instance>>({
					Material.NavigationDrawerItems<<string>>({
						Theme = theme,
						Items = destinations(),
						Selected = page,
						-- Compose's sample closes the drawer when a destination is picked
						OnClick = function()
							modalState.Close()
						end,
					}),
				}),
			}),
			Content = screenContent(ctx, page, modalState.Open, "ModalNavigationDrawer: the menu button opens it over a scrim; tap the scrim, drag it left or press Escape / B to close."),
		}),
	})

	local dismissibleState = Material.DrawerState({ InitialValue = "Open" })
	local dismissible = Common.Screen(ctx, "DismissibleDrawerScreen", 640, 420, {
		Material.DismissibleNavigationDrawer({
			Theme = theme,
			DrawerState = dismissibleState,
			DrawerContent = Material.DismissibleDrawerSheet({
				Theme = theme,
				Width = 280,
				Children = q.Slot<<Instance>>({
					Material.NavigationDrawerItems<<string>>({ Theme = theme, Items = destinations(), Selected = page }),
				}),
			}),
			Content = screenContent(ctx, page, function()
				if dismissibleState.TargetValue:Get() == "Open" then
					dismissibleState.Close()
				else
					dismissibleState.Open()
				end
			end, "DismissibleNavigationDrawer: the drawer pushes the content aside; the menu button toggles it."),
		}),
	})

	local permanent = Common.Screen(ctx, "PermanentDrawerScreen", 640, 420, {
		Material.PermanentNavigationDrawer({
			Theme = theme,
			DrawerContent = Material.PermanentDrawerSheet({
				Theme = theme,
				Width = 240,
				Children = q.Slot<<Instance>>({
					Material.NavigationDrawerHeadline({ Theme = theme, Text = "Single items", LayoutOrder = 1 }),
					Material.NavigationDrawerItem({
						Theme = theme,
						Label = "Inbox",
						Icon = INBOX,
						Badge = "24",
						LayoutOrder = 2,
						Selected = isPage("inbox"),
						OnClick = function()
							page:Set("inbox")
						end,
					}),
					Material.NavigationDrawerItem({
						Theme = theme,
						Label = "Outbox",
						Icon = SEND,
						LayoutOrder = 3,
						Selected = isPage("outbox"),
						OnClick = function()
							page:Set("outbox")
						end,
					}),
					Material.NavigationDrawerDivider({ Theme = theme, LayoutOrder = 4 }),
					Material.NavigationDrawerItem({
						Theme = theme,
						Label = "Trash",
						Icon = DELETE,
						LayoutOrder = 5,
						Selected = isPage("trash"),
						OnClick = function()
							page:Set("trash")
						end,
					}),
				}),
			}),
			Content = screenContent(ctx, page, nil, "PermanentNavigationDrawer (240 wide): always shown beside the content. Built from single NavigationDrawerItem rows, each with its own Selected."),
		}),
	})

	return Common.Section(ctx, "Navigation", "Navigation", {
		Common.Group(ctx, "Modal navigation drawer", { modal }, "360 wide, end corners 16, surfaceContainerLow; many destinations scroll."),
		Common.Group(ctx, "Dismissible navigation drawer", { dismissible }),
		Common.Group(ctx, "Permanent navigation drawer", { permanent }),
	})
end
