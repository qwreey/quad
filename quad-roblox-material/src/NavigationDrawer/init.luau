--!strict
--[[
	Navigation drawers (Material 3) — Compose material3 NavigationDrawer.kt (androidx/androidx@40ff481 compose/material3/
	material3/src/commonMain/kotlin/androidx/compose/material3/), with MDC NavigationView's section headline and divider
	(Compose has none) — m3.material.io/components/navigation-drawer.

	    local drawer = Material.DrawerState({ InitialValue = "Closed" })
	    local page = q.Source("inbox")
	    Material.ModalNavigationDrawer({
	        DrawerState = drawer,
	        DrawerContent = Material.ModalDrawerSheet({ Children = q.Slot<<Instance>>({
	            Material.NavigationDrawerItems<<string>>({ Selected = page, Items = {
	                { Headline = "Mail" },
	                { Key = "inbox", Label = "Inbox", Icon = "rbxassetid://…", Badge = "24" },
	                "divider",
	                { Key = "trash", Label = "Trash" },
	            } }),
	        }) }),
	        Content = q.Slot<<Instance>>({ screen }),
	    })

	Layouts: ModalNavigationDrawer / DismissibleNavigationDrawer / PermanentNavigationDrawer (Drawer.luau). Sheets:
	ModalDrawerSheet / DismissibleDrawerSheet / PermanentDrawerSheet (Sheet.luau). Content: NavigationDrawerItem (one row,
	`Selected` per item — Compose's form), NavigationDrawerItems (data + ONE `Selected: Source<K>`, the Tabs form),
	NavigationDrawerHeadline, NavigationDrawerDivider (Item.luau). State: DrawerState (State.luau). The destination item
	model is shared with the coming navigation bar / rail (Navigation/Destination.luau).
]]

local Drawer = require("@self/Drawer")
local Sheet = require("@self/Sheet")
local Item = require("@self/Item")
local State = require("@self/State")

export type DrawerValue = State.DrawerValue
export type DrawerState = State.DrawerState
export type DrawerStateOptions = State.Options
export type ModalProps = Drawer.ModalProps
export type DismissibleProps = Drawer.DismissibleProps
export type PermanentProps = Drawer.PermanentProps
export type SheetProps = Sheet.Props
export type ItemProps = Item.ItemProps
export type HeadlineProps = Item.HeadlineProps
export type DividerProps = Item.DividerProps
export type ItemsProps<K> = Item.ItemsProps<K>
export type Entry<K> = Item.Entry<K>

return {
	DrawerState = State.DrawerState,
	ModalNavigationDrawer = Drawer.ModalNavigationDrawer,
	DismissibleNavigationDrawer = Drawer.DismissibleNavigationDrawer,
	PermanentNavigationDrawer = Drawer.PermanentNavigationDrawer,
	ModalDrawerSheet = Sheet.ModalDrawerSheet,
	DismissibleDrawerSheet = Sheet.DismissibleDrawerSheet,
	PermanentDrawerSheet = Sheet.PermanentDrawerSheet,
	NavigationDrawerItem = Item.NavigationDrawerItem,
	NavigationDrawerItems = Item.NavigationDrawerItems,
	NavigationDrawerHeadline = Item.NavigationDrawerHeadline,
	NavigationDrawerDivider = Item.NavigationDrawerDivider,
}
