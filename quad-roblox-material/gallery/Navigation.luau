--!strict
--[[
	Gallery section "Navigation": the layout pieces for moving around an app, each inside a mock screen (`Common.Screen` —
	they are layouts, not floating things): the three navigation drawers (Compose ModalNavigationDrawer /
	DismissibleNavigationDrawer / PermanentNavigationDrawer) with their sheets and a NavigationDrawerItems list of many
	destinations (headlines, dividers, badges — the drawer scrolls); the navigation bar (ShortNavigationBar: equal cells
	with icons on top in a phone screen, centered start-icon items in a wide one); the navigation rail (WideNavigationRail,
	its header menu button expands / collapses it); the app bars — a scrolling screen per scroll behavior (the list starts at
	the bar's current bottom edge and pads its canvas by what the bar has collapsed: rows move as in Compose Scaffold's
	content-behind-the-bar layout while the native scrollbar never sits under the bar), the large bars at
	rest, the bottom app bar and the flexible one (docked toolbar); the floating toolbars (horizontal with leading /
	trailing content, vertical with a FAB, standard and vibrant) with an Expanded switch.
	The selected destination of every drawer is ONE Memo Source (`nav.page`), so the three drawers show the same choice and
	it survives leaving the tab; the bar and the rail share another (`nav.barPage`). The icons are Material Design Icons
	image ids from the kit's icon dump (qwreey/qwreey.roblox.plugins@7b6552a:IconPack.Plugin/res/IconDump.lua, baseline —
	each checked as an image asset, AssetTypeId 1, creator qwreey74_icon, through economy.roblox.com on 2026-10-08); the
	menu button uses `Icons` "menu", the overflow button `Icons` "moreVert".
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
local HOME = "rbxassetid://6026568195" -- baseline/action/home
local SEARCH = "rbxassetid://6031154871" -- baseline/action/search
local SETTINGS = "rbxassetid://6031280882" -- baseline/action/settings
local PERSON = "rbxassetid://6034287594" -- baseline/social/person
local STAR = "rbxassetid://6031068423" -- baseline/toggle/star
local EXPLORE = "rbxassetid://6023426941" -- baseline/action/explore
local BOOKMARK = "rbxassetid://6022852108" -- baseline/action/bookmark
local ARROW_BACK = "rbxassetid://6031091000" -- baseline/navigation/arrow_back
local ADD = "rbxassetid://6035047377" -- baseline/content/add
local SHARE = "rbxassetid://6034230648" -- baseline/social/share
local ATTACH = "rbxassetid://6034898102" -- baseline/editor/attach_file
local MIC = "rbxassetid://6026660078" -- baseline/media/mic
local IMAGE = "rbxassetid://6034407078" -- baseline/image/image
local BOLD = "rbxassetid://6034900732" -- baseline/editor/format_bold
local ITALIC = "rbxassetid://6034910912" -- baseline/editor/format_italic
local UNDERLINED = "rbxassetid://6034925627" -- baseline/editor/format_underlined
local UNDO = "rbxassetid://6035078896" -- baseline/content/undo
local REDO = "rbxassetid://6035056483" -- baseline/content/redo
local PALETTE = "rbxassetid://6034316009" -- baseline/image/palette

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


local function barDestinations(): { Material.NavigationDestination<string> }
	return {
		{ Key = "home", Label = "Home", Icon = HOME },
		{ Key = "explore", Label = "Explore", Icon = EXPLORE, Badge = "" },
		{ Key = "saved", Label = "Saved", Icon = BOOKMARK, Badge = "3" },
		{ Key = "profile", Label = "Profile", Icon = PERSON },
	}
end

-- a fill frame under the screen's bar / beside its rail with the selected page as a caption
local function pageCaption(ctx: Ctx, page: q.State<string>, note: string, order: number?): Frame
	return D.Frame {
		Name = "Body",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = order,
		UIPaddingOffset = 16,
		D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) },
		D.UIFlexItem { FlexMode = Enum.UIFlexMode.Fill },
		D.TextLabel {
			Name = "Title",
			titleStyle,
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = ctx.Theme.Color.OnSurface,
			Text = Common.text<<string>>(page, function(v: string): string
				return `Page: {v}`
			end),
		},
		Common.Caption(ctx, note),
	}
end

-- a screen whose list scrolls under an app bar: rows where Compose Scaffold puts them (behind the bar, padded by its
-- expanded height), but the ScrollingFrame itself starts at the bar's bottom so its scrollbar is never covered
local function scrollScreen(ctx: Ctx, name: string, expanded: number, behavior: Material.TopAppBarScrollBehavior, bar: Instance): Frame
	local rows: { Instance } = {}
	for i = 1, 24 do
		table.insert(
			rows,
			D.TextLabel {
				Name = "Row",
				Material.Text.Label("BodyLarge"),
				Size = UDim2.new(1, 0, 0, 48),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = i,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = ctx.Theme.Color.OnSurface,
				Text = `List item {i}`,
			}
		)
	end
	-- the frame starts at the bar's current bottom edge (so the native scrollbar is never under the bar) and pads its
	-- canvas by what the bar has collapsed, so a row stays where the full-screen layout would put it
	local top: q.State<number> = behavior.State.HeightOffset:Compute(function(self)
		return math.max(0, math.round(expanded + self:Get()))
	end)
	local position: q.State<UDim2> = top:Compute(function(self)
		return UDim2.fromOffset(0, self:Get())
	end)
	local size: q.State<UDim2> = top:Compute(function(self)
		return UDim2.new(1, 0, 1, -self:Get())
	end)
	local padding: q.State<UDim> = top:Compute(function(self)
		return UDim.new(0, expanded - self:Get())
	end)
	return Common.Screen(ctx, name, 360, 420, {
		D.ScrollingFrame {
			Name = "Content",
			Position = position,
			Size = size,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.fromOffset(0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = ctx.Theme.Color.OnSurface,
			behavior.Hook,
			D.UIPadding {
				PaddingTop = padding,
				PaddingLeft = UDim.new(0, 16),
			},
			D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder },
			q.Slot<<Instance>>(rows),
		},
		D.Frame {
			Name = "BarLayer",
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 2,
			bar,
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


	-- ── navigation bar ──
	local barPage = ctx.Memo("nav.barPage", function()
		return q.Source("home")
	end)
	local phoneBar = Common.Screen(ctx, "NavigationBarScreen", 360, 300, {
		D.Frame {
			Name = "Column",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder },
			pageCaption(ctx, barPage, "ShortNavigationBar (EqualWeight, icons on top): Explore has the small badge, Saved the large one.", 1),
			Material.ShortNavigationBar<<string>>({ Theme = theme, Items = barDestinations(), Selected = barPage, LayoutOrder = 2 }),
		},
	})
	local wideBar = Common.Screen(ctx, "WideNavigationBarScreen", 640, 200, {
		D.Frame {
			Name = "Column",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder },
			pageCaption(ctx, barPage, "Centered + Start icons (medium windows): the items share 70 % of the bar.", 1),
			Material.ShortNavigationBar<<string>>({
				Theme = theme,
				Items = barDestinations(),
				Selected = barPage,
				Arrangement = "Centered",
				IconPosition = "Start",
				LayoutOrder = 2,
			}),
		},
	})

	-- ── navigation rail ──
	local railState = Material.WideNavigationRailState()
	local rail = Common.Screen(ctx, "NavigationRailScreen", 640, 440, {
		D.Frame {
			Name = "Row",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.UIListLayout { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder },
			Material.WideNavigationRail<<string>>({
				Theme = theme,
				State = railState,
				Selected = barPage,
				LayoutOrder = 1,
				-- Compose's sample: a menu button offset 24 so it centers on the 96 px collapsed rail
				Header = Material.IconButton({
					Theme = theme,
					Icon = Material.Icons.asset("menu") or "",
					TouchTarget = true,
					ContentColor = theme.Raw.OnSurfaceVariant,
					OnClick = railState.Toggle,
					Modifier = D.Modifier.TextButton():Position(UDim2.fromOffset(24, 0)),
				}),
				Items = {
					{ Key = "home", Label = "Home", Icon = HOME },
					{ Key = "explore", Label = "Explore", Icon = EXPLORE, Badge = "" },
					{ Key = "saved", Label = "Saved", Icon = BOOKMARK, Badge = "3" },
					{ Key = "profile", Label = "Profile", Icon = PERSON },
					{ Key = "settings", Label = "Settings", Icon = SETTINGS },
				},
			}),
			pageCaption(ctx, barPage, "WideNavigationRail: the menu button expands (labels beside the icons, 220..360 wide) and collapses it.", 2),
		},
	})

	-- ── app bars ──
	local barAction = ctx.Memo("nav.barAction", function()
		return q.Source("none")
	end)
	local favorite = ctx.Memo("nav.favorite", function()
		return q.Source(false)
	end)
	local function did(label: string): () -> ()
		return function()
			barAction:Set(label)
		end
	end
	local function actions(): { Material.AppBarEntry }
		return {
			{ Icon = SEARCH, Label = "Search", OnClick = did("Search") },
			{ Icon = FAVORITE, Label = "Favorite", Checked = favorite, OnCheckedChange = function(v: boolean)
				favorite:Set(v)
			end },
			{ Icon = SHARE, Label = "Share", OnClick = did("Share") },
			{ Icon = SETTINGS, Label = "Settings", OnClick = did("Settings") },
		}
	end
	local back: Material.AppBarAction = { Icon = ARROW_BACK, Label = "Back", OnClick = did("Back") }

	local pinned = Material.TopAppBarDefaults.pinnedScrollBehavior()
	local pinnedScreen = scrollScreen(ctx, "PinnedAppBarScreen", 64, pinned, Material.TopAppBar({
		Theme = theme,
		Overlay = ctx.Overlay,
		Title = "Pinned",
		NavigationIcon = back,
		Actions = actions(),
		MaxItemCount = 3,
		ScrollBehavior = pinned,
	}))
	local enter = Material.TopAppBarDefaults.enterAlwaysScrollBehavior()
	local enterScreen = scrollScreen(ctx, "EnterAlwaysAppBarScreen", 64, enter, Material.CenterAlignedTopAppBar({
		Theme = theme,
		Overlay = ctx.Overlay,
		Title = "Enter always",
		NavigationIcon = { Icon = "menu", Label = "Menu", OnClick = did("Menu") },
		Actions = { { Icon = PERSON, Label = "Account", OnClick = did("Account") } },
		ScrollBehavior = enter,
	}))
	local exit = Material.TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
	local exitScreen = scrollScreen(ctx, "ExitUntilCollapsedAppBarScreen", 136, exit, Material.MediumFlexibleTopAppBar({
		Theme = theme,
		Overlay = ctx.Overlay,
		Title = "Exit until collapsed",
		Subtitle = "MediumFlexibleTopAppBar",
		NavigationIcon = back,
		Actions = actions(),
		MaxItemCount = 3,
		ScrollBehavior = exit,
	}))
	local function still(name: string, height: number, bar: Instance): Frame
		return Common.Screen(ctx, name, 360, height, { bar })
	end
	local largeScreens: { Instance } = {
		still("SmallSubtitleAppBar", 64, Material.TopAppBar({
			Theme = theme,
			Overlay = ctx.Overlay,
			Title = "Title",
			Subtitle = "Subtitle",
			TitleHorizontalAlignment = "Center",
			NavigationIcon = back,
			Actions = { { Icon = SEARCH, Label = "Search", OnClick = did("Search") } },
		})),
		still("MediumAppBar", 112, Material.MediumTopAppBar({ Theme = theme, Overlay = ctx.Overlay, Title = "MediumTopAppBar", NavigationIcon = back })),
		still("LargeAppBar", 152, Material.LargeTopAppBar({ Theme = theme, Overlay = ctx.Overlay, Title = "LargeTopAppBar", NavigationIcon = back })),
		still("LargeFlexibleAppBar", 152, Material.LargeFlexibleTopAppBar({
			Theme = theme,
			Overlay = ctx.Overlay,
			Title = "Large flexible",
			Subtitle = "LargeFlexibleTopAppBar",
			TitleHorizontalAlignment = "Center",
			NavigationIcon = back,
			Actions = { { Icon = SEARCH, Label = "Search", OnClick = did("Search") } },
		})),
	}
	local bottomScreen = Common.Screen(ctx, "BottomAppBarScreen", 360, 220, {
		D.Frame {
			Name = "Column",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 12) },
			Material.FlexibleBottomAppBar({
				Theme = theme,
				Overlay = ctx.Overlay,
				LayoutOrder = 1,
				Actions = {
					{ Icon = UNDO, Label = "Undo", OnClick = did("Undo") },
					{ Icon = REDO, Label = "Redo", OnClick = did("Redo") },
					{ Icon = ADD, Label = "Add", OnClick = did("Add") },
					{ Icon = PALETTE, Label = "Palette", OnClick = did("Palette") },
					{ Icon = SHARE, Label = "Share", OnClick = did("Share") },
				},
			}),
			Material.BottomAppBar({
				Theme = theme,
				Overlay = ctx.Overlay,
				LayoutOrder = 2,
				Actions = {
					{ Icon = "check", Label = "Done", OnClick = did("Done") },
					{ Icon = "edit", Label = "Edit", OnClick = did("Edit") },
					{ Icon = MIC, Label = "Voice", OnClick = did("Voice") },
					{ Icon = IMAGE, Label = "Image", OnClick = did("Image") },
				},
				FloatingActionButton = { Icon = ADD, OnClick = did("FAB") },
			}),
		},
	})

	-- ── toolbars ──
	local toolbarExpanded = ctx.Memo("nav.toolbarExpanded", function()
		return q.Source(true)
	end)
	local bold = ctx.Memo("nav.bold", function()
		return q.Source(false)
	end)
	local toolbarScreen = Common.Screen(ctx, "ToolbarScreen", 640, 300, {
		Material.HorizontalFloatingToolbar({
			Theme = theme,
			Overlay = ctx.Overlay,
			Expanded = toolbarExpanded,
			Modifier = D.Modifier.Frame():AnchorPoint(Vector2.new(0.5, 1)):Position(UDim2.new(0.5, 0, 1, -16)),
			LeadingContent = {
				{ Icon = BOLD, Label = "Bold", Checked = bold, OnCheckedChange = function(v: boolean)
					bold:Set(v)
				end },
				{ Icon = ITALIC, Label = "Italic", OnClick = did("Italic") },
			},
			Content = { { Icon = UNDERLINED, Label = "Underline", OnClick = did("Underline") }, { Icon = ATTACH, Label = "Attach", OnClick = did("Attach") } },
			TrailingContent = { { Icon = MIC, Label = "Voice", OnClick = did("Voice") } },
		}),
		Material.VerticalFloatingToolbar({
			Theme = theme,
			Overlay = ctx.Overlay,
			Expanded = toolbarExpanded,
			Colors = "Vibrant",
			Modifier = D.Modifier.Frame():AnchorPoint(Vector2.new(1, 0)):Position(UDim2.new(1, -16, 0, 16)),
			Content = { { Icon = SEARCH, Label = "Search", OnClick = did("Search") }, { Icon = STAR, Label = "Star", OnClick = did("Star") } },
			FloatingActionButton = { Icon = ADD, OnClick = did("Toolbar FAB") },
		}),
		Material.HorizontalFloatingToolbar({
			Theme = theme,
			Overlay = ctx.Overlay,
			Expanded = toolbarExpanded,
			Modifier = D.Modifier.Frame():Position(UDim2.fromOffset(16, 16)),
			Content = { { Icon = IMAGE, Label = "Image", OnClick = did("Image") }, { Icon = "edit", Label = "Edit", OnClick = did("Edit") } },
			FloatingActionButton = { Icon = ADD, OnClick = did("FAB") },
		}),
	})
	local toolbarControls = Common.Flow({
		Common.Labeled(ctx, Material.Switch({ Theme = theme, Value = toolbarExpanded }), "Expanded"),
		Common.Caption(ctx, Common.text<<string>>(barAction, function(v: string): string
			return `Last action: {v}`
		end), false),
	})

	return Common.Section(ctx, "Navigation", "Navigation", {
		Common.Group(ctx, "Modal navigation drawer", { modal }, "360 wide, end corners 16, surfaceContainerLow; many destinations scroll."),
		Common.Group(ctx, "Dismissible navigation drawer", { dismissible }),
		Common.Group(ctx, "Permanent navigation drawer", { permanent }),
		Common.Group(ctx, "Navigation bar", { phoneBar, wideBar }, "ShortNavigationBar (M3 Expressive, 64 tall): the pill grows from its center on selection."),
		Common.Group(ctx, "Navigation rail", { rail }, "WideNavigationRail: collapsed 96 wide, expanded to the widest item."),
		Common.Group(
			ctx,
			"Top app bars that scroll",
			{ pinnedScreen, enterScreen, exitScreen },
			"Scroll each list: pinned turns surfaceContainer, enterAlways hides and returns with any scroll up, exitUntilCollapsed shrinks to 64 and grows back at the top. Four actions with MaxItemCount 3 overflow into a menu."
		),
		Common.Group(ctx, "Top app bars at rest", largeScreens),
		Common.Group(ctx, "Bottom app bars", { bottomScreen }, "FlexibleBottomAppBar (the docked toolbar, 64) above the BottomAppBar (80, FAB secondaryContainer)."),
		Common.Group(ctx, "Floating toolbars", { toolbarControls, toolbarScreen }),
	})
end
