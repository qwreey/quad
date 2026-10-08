--!strict
--[[
	Top app bar scrolling — Compose material3 `TopAppBarState` and the three `TopAppBarDefaults` scroll behaviors
	(androidx/androidx@40ff481 compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/AppBar.kt
	1400-1436 TopAppBarScrollBehavior, 1712-1984 the factories, 2028-2146 TopAppBarState, 3267-3590 PinnedScrollBehavior /
	EnterAlwaysScrollBehavior / ExitUntilCollapsedScrollBehavior / settleAppBar).

	    local scroll = Material.TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
	    local list = D.ScrollingFrame { scroll.Hook, ... }              -- Compose: Modifier.nestedScroll(scroll.nestedScrollConnection)
	    Material.MediumTopAppBar({ Title = "Inbox", ScrollBehavior = scroll })

	TopAppBarDefaults.pinnedScrollBehavior(opts?) / .enterAlwaysScrollBehavior(opts?) / .exitUntilCollapsedScrollBehavior(opts?)
	  opts (`read`, optional): State (TopAppBarState? — default a fresh one, rememberTopAppBarState), CanScroll ((() -> boolean)?
	  — while it returns false the bar ignores the scroll, Compose canScroll).
	  -> { State: TopAppBarState, IsPinned: boolean, Hook } — put `Hook` in the array part of ONE ScrollingFrame (the content
	  scrolling under the bar); it follows that frame's `CanvasPosition`.
	TopAppBarState(opts?) — opts: InitialHeightOffset (number?, default 0). Fields (State<number>): HeightOffset (0 .. the
	  limit, <= 0), HeightOffsetLimit (set by the bar: minus its collapsible height), ContentOffset (minus the content's scroll),
	  CollapsedFraction (HeightOffset / HeightOffsetLimit), OverlappedFraction (Compose overlappedFraction: 0 .. 1 over the
	  first |limit| px of content scroll).

	WHAT THE BARS DO WITH IT: a single-row bar (TopAppBar, CenterAlignedTopAppBar) switches to `scrolledContainerColor`
	(surfaceContainer, AppBarTokens.OnScrollContainerColor) once OverlappedFraction > 0.01 and animates the color (DefaultEffects
	-> Short4); a two-row bar (Medium / Large / the flexible ones) blends container -> scrolled color by CollapsedFraction
	(FastOutLinearIn), fades its small title in (TopTitleAlphaEasing) and its large title out. A behavior that is not pinned
	collapses the bar: its height is the full height + HeightOffset (a single-row bar can collapse completely, a two-row
	bar down to its 64 px top row), the content moving with it and clipped.
	  pinned               HeightOffset stays 0 (only the color reacts)
	  enterAlways          every scroll moves HeightOffset by the same distance: scrolling down hides the bar, any scroll up
	                       brings it back
	  exitUntilCollapsed   scrolling down collapses; the bar expands again only as the content reaches its top
	SETTLE (settleAppBar): when the scroll stops part way (the canvas has not moved for 0.1 s — the kit's stand-in for the
	end of a fling) a behavior that is not pinned animates HeightOffset to 0 if CollapsedFraction < 0.5, else to the limit
	(snapAnimationSpec = DefaultEffects -> Short4, Standard; one Heartbeat connection while it runs).
	ROBLOX DIFFERENCE: a ScrollingFrame cannot hand its scroll to a parent (no nested scrolling), so the bar does not CONSUME
	the scroll as Compose's onPreScroll does — the content scrolls by the full distance while the bar collapses alongside.
	Lay the screen out the way Compose's Scaffold does it: the scrolling content fills the screen BEHIND the bar (the bar on
	top, a higher ZIndex) with a top padding of the bar's expanded height, so the first row stays right under the bar's
	bottom edge while it collapses (the gallery's app bar screen). The fling decay (flingAnimationSpec) and dragging the bar
	itself (Compose's draggable on the bar) are not reproduced.
]]

local q = require("../Quad")
local Tokens = require("../Tokens")

local RunService = game:GetService("RunService")

export type Kind = "Pinned" | "EnterAlways" | "ExitUntilCollapsed"

export type TopAppBarState = {
	read HeightOffset: q.State<number>,
	read HeightOffsetLimit: q.State<number>,
	read ContentOffset: q.State<number>,
	read CollapsedFraction: q.State<number>,
	read OverlappedFraction: q.State<number>,
}

export type StateOptions = {
	read InitialHeightOffset: number?,
}

export type BehaviorOptions = {
	read State: TopAppBarState?,
	read CanScroll: (() -> boolean)?,
}

export type TopAppBarScrollBehavior = {
	read State: TopAppBarState,
	read IsPinned: boolean,
	read Hook: any,
}

type Rec = {
	Offset: q.Source<number>,
	Limit: q.Source<number>,
	Content: q.Source<number>,
}

local IDLE = 0.1 -- seconds without a canvas move before the bar settles
local SETTLE = Tokens.Motion.Duration.Short4

local records: { [any]: Rec } = setmetatable({}, { __mode = "k" }) :: any

local function setOffset(rec: Rec, v: number)
	rec.Offset:SetIfChanged(math.clamp(v, math.min(rec.Limit:Get(), 0), 0))
end

local function TopAppBarState(o: StateOptions?): TopAppBarState
	local opts: StateOptions = o or {}
	local rec: Rec = {
		Offset = q.Source(math.min(opts.InitialHeightOffset or 0, 0)),
		Limit = q.Source(-math.huge),
		Content = q.Source(0),
	}
	local collapsed: q.State<number> = rec.Offset:Compute(function(self, _prev, limit)
		local l = limit:Get()
		if l == 0 or l == -math.huge then
			return 0
		end
		return self:Get() / l
	end, rec.Limit)
	local overlapped: q.State<number> = rec.Content:Compute(function(self, _prev, limit)
		local l = limit:Get()
		if l == 0 or l == -math.huge then
			return 0
		end
		return 1 - math.clamp(l + math.abs(self:Get()), l, 0) / l
	end, rec.Limit)
	local state: TopAppBarState = {
		HeightOffset = rec.Offset,
		HeightOffsetLimit = rec.Limit,
		ContentOffset = rec.Content,
		CollapsedFraction = collapsed,
		OverlappedFraction = overlapped,
	}
	records[state] = rec
	return state
end

local function recOf(state: TopAppBarState): Rec
	local rec = records[state]
	if rec == nil then
		error("TopAppBarScrollBehavior: State must come from Material.TopAppBarState", 3)
	end
	return rec
end

local function behavior(kind: Kind, o: BehaviorOptions?): TopAppBarScrollBehavior
	local opts: BehaviorOptions = o or {}
	local state = opts.State or TopAppBarState()
	local rec = recOf(state)
	local canScroll = opts.CanScroll
	local prevY = 0
	local version = 0
	local settling: RBXScriptConnection? = nil

	local function stopSettle()
		if settling then
			settling:Disconnect()
			settling = nil
		end
	end

	local function settle(v: number)
		if v ~= version or kind == "Pinned" then
			return
		end
		local limit = rec.Limit:Get()
		if limit == 0 or limit == -math.huge then
			return
		end
		local fraction = rec.Offset:Get() / limit
		if fraction < 0.01 or fraction == 1 then
			return
		end
		local from = rec.Offset:Get()
		local goal = if fraction < 0.5 then 0 else limit
		local t = 0
		stopSettle()
		settling = RunService.Heartbeat:Connect(function(dt: number)
			t += dt
			local k = math.min(t / SETTLE, 1)
			local u = 1 - k
			setOffset(rec, from + (goal - from) * (1 - u * u * u * u))
			if k >= 1 then
				stopSettle()
			end
		end)
	end

	local hook = q.OnChange("CanvasPosition", function(position: Vector2)
		local y = position.Y
		local dy = y - prevY
		prevY = y
		if canScroll ~= nil and not canScroll() then
			return
		end
		stopSettle()
		rec.Content:SetIfChanged(-y)
		if kind == "EnterAlways" then
			setOffset(rec, rec.Offset:Get() - dy)
		elseif kind == "ExitUntilCollapsed" then
			if dy > 0 then
				setOffset(rec, rec.Offset:Get() - dy)
			else
				-- expand only as the content reaches its top
				setOffset(rec, math.max(rec.Offset:Get(), -y))
			end
		end
		if kind ~= "Pinned" then
			version += 1
			local v = version
			task.delay(IDLE, function()
				settle(v)
			end)
		end
	end)

	return {
		State = state,
		IsPinned = kind == "Pinned",
		Hook = hook,
	}
end

-- the bar sets the collapsible height (adjustHeightOffsetLimit)
local function setLimit(state: TopAppBarState, limit: number)
	local rec = recOf(state)
	rec.Limit:SetIfChanged(limit)
	setOffset(rec, rec.Offset:Get())
end

local TopAppBarDefaults = {
	pinnedScrollBehavior = function(o: BehaviorOptions?): TopAppBarScrollBehavior
		return behavior("Pinned", o)
	end,
	enterAlwaysScrollBehavior = function(o: BehaviorOptions?): TopAppBarScrollBehavior
		return behavior("EnterAlways", o)
	end,
	exitUntilCollapsedScrollBehavior = function(o: BehaviorOptions?): TopAppBarScrollBehavior
		return behavior("ExitUntilCollapsed", o)
	end,
	-- AppBar.kt 1987-2015 (px)
	TopAppBarExpandedHeight = 64,
	MediumAppBarCollapsedHeight = 64,
	MediumAppBarExpandedHeight = 112,
	MediumFlexibleAppBarWithoutSubtitleExpandedHeight = 112,
	MediumFlexibleAppBarWithSubtitleExpandedHeight = 136,
	LargeAppBarCollapsedHeight = 64,
	LargeAppBarExpandedHeight = 152,
	LargeFlexibleAppBarWithoutSubtitleExpandedHeight = 120,
	LargeFlexibleAppBarWithSubtitleExpandedHeight = 152,
}

return {
	TopAppBarState = TopAppBarState,
	TopAppBarDefaults = TopAppBarDefaults,
	setLimit = setLimit,
	recOf = recOf,
}
