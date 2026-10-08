--!strict
--[[
	App bars (Material 3) — Compose material3 AppBar.kt (androidx/androidx@40ff481 compose/material3/material3/src/commonMain/
	kotlin/androidx/compose/material3/), m3.material.io/components/app-bars.

	    local scroll = Material.TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
	    Material.MediumFlexibleTopAppBar({ Title = "Inbox", Subtitle = "3 unread", ScrollBehavior = scroll,
	        NavigationIcon = { Icon = "rbxassetid://…", Label = "Back", OnClick = back },
	        Actions = { { Icon = "rbxassetid://…", Label = "Search", OnClick = search } } })
	    -- in a Material.Scaffold (TopBar = the bar): the content region starts at the bar's current bottom
	    Content = function(innerPadding) return D.ScrollingFrame { scroll.Hook, D.UIPadding { PaddingTop = innerPadding.Top }, … } end

	Top: TopAppBar / CenterAlignedTopAppBar / MediumTopAppBar / MediumFlexibleTopAppBar / LargeTopAppBar /
	LargeFlexibleTopAppBar (Top.luau). Scrolling: TopAppBarState + TopAppBarDefaults (pinned / enterAlways /
	exitUntilCollapsed behaviors and the default heights — Scroll.luau). Bottom: BottomAppBar and FlexibleBottomAppBar (the
	docked toolbar — Bottom.luau). The action model shared with the toolbars: AppBarAction (Actions.luau).
]]

local Top = require("@self/Top")
local Bottom = require("@self/Bottom")
local Scroll = require("@self/Scroll")
local Actions = require("@self/Actions")

export type TopAppBarProps = Top.Props
export type TopAppBarAlignment = Top.Alignment
export type BottomAppBarProps = Bottom.BottomProps
export type FlexibleBottomAppBarProps = Bottom.FlexibleProps
export type FlexibleArrangement = Bottom.Arrangement
export type Fab = Bottom.Fab
export type TopAppBarState = Scroll.TopAppBarState
export type TopAppBarStateOptions = Scroll.StateOptions
export type TopAppBarScrollBehavior = Scroll.TopAppBarScrollBehavior
export type ScrollBehaviorOptions = Scroll.BehaviorOptions
export type Action = Actions.Action
export type Entry = Actions.Entry

return {
	TopAppBar = Top.TopAppBar,
	CenterAlignedTopAppBar = Top.CenterAlignedTopAppBar,
	MediumTopAppBar = Top.MediumTopAppBar,
	MediumFlexibleTopAppBar = Top.MediumFlexibleTopAppBar,
	LargeTopAppBar = Top.LargeTopAppBar,
	LargeFlexibleTopAppBar = Top.LargeFlexibleTopAppBar,
	BottomAppBar = Bottom.BottomAppBar,
	FlexibleBottomAppBar = Bottom.FlexibleBottomAppBar,
	TopAppBarState = Scroll.TopAppBarState,
	TopAppBarDefaults = Scroll.TopAppBarDefaults,
}
