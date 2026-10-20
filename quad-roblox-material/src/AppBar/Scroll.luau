--!strict
--[[
	Top app bar scrolling — Compose material3 `TopAppBarState` and the three `TopAppBarDefaults` scroll behaviors
	(androidx/androidx@40ff481 compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/AppBar.kt
	1400-1436 TopAppBarScrollBehavior, 1712-1984 the factories, 2028-2146 TopAppBarState, 3267-3592 PinnedScrollBehavior /
	EnterAlwaysScrollBehavior / ExitUntilCollapsedScrollBehavior / settleAppBar).

	    local scroll = Material.TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
	    Material.Scaffold({ TopBar = Material.MediumTopAppBar({ Title = "Inbox", ScrollBehavior = scroll }),
	        Content = function(innerPadding)                            -- Compose: Modifier.nestedScroll(scroll.nestedScrollConnection)
	            return q.Elem "ScrollingFrame" { Size = UDim2.fromScale(1, 1), scroll.Hook, q.Elem "UIPadding" { PaddingTop = innerPadding.Top }, ... }
	        end })

	TopAppBarDefaults.pinnedScrollBehavior(opts?) / .enterAlwaysScrollBehavior(opts?) / .exitUntilCollapsedScrollBehavior(opts?)
	  opts (`read`, optional): State (TopAppBarState? — default a fresh one, rememberTopAppBarState), CanScroll ((() -> boolean)?
	  — while it returns false the bar ignores the scroll, Compose canScroll).
	  -> { State: TopAppBarState, IsPinned: boolean, Hook } — put `Hook` in the array part of ONE ScrollingFrame (the content
	  scrolling below the bar — the Scaffold's content; layout under ROBLOX DIFFERENCE); it follows that frame's `CanvasPosition` and, to settle,
	  moves it (a pre-hook: it keeps the frame until the frame is destroyed).
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
	SETTLE (settleAppBar, AppBar.kt 3542-3592): when the scroll stops part way (the canvas has not moved for 0.1 s — the kit's
	stand-in for the end of a fling — and the left mouse button is up: a scrollbar thumb held still is not the end of the
	scroll) a behavior that is not pinned animates HeightOffset to 0 if CollapsedFraction < 0.5, else to the limit
	(snapAnimationSpec = DefaultEffects -> Short4, Standard; one Heartbeat connection while it runs). Compose animates only
	the height: the bar had CONSUMED the scroll (onPreScroll, 3417 / 3485), so the list's own scroll is unchanged and the
	Scaffold's top padding (Scaffold.kt 258-265, the bar's measured height) carries the content with the bar — a settled bar
	never leaves a gap. Here a row's screen place does not follow the bar (layout below), so the settle moves the hooked
	ScrollingFrame's CanvasPosition by the same amount, keeping CanvasPosition.Y + HeightOffset (the content's own scroll
	under the bar) constant — exitUntilCollapsed near the top lands on 0 or the collapse range, enterAlways keeps the first
	row on the bar's bottom. If the canvas cannot scroll far enough for a collapse (a list shorter than the collapse range)
	the settle expands instead. A canvas move that is not the settle's own (wheel, drag, scrollbar) cancels it at once
	(Studio-measured 2026-10-08 on the gallery: a scrollbar drag released part way and a wheel during the settle).
	ROBLOX DIFFERENCE: a ScrollingFrame cannot hand its scroll to a parent (no nested scrolling), so the bar does not CONSUME
	the scroll as Compose's onPreScroll does — the content scrolls by the full distance while the bar collapses alongside.
	USE `Material.Scaffold` (Scaffold.luau): it lays the screen out so the rows move the way Compose's Scaffold places them
	(the first row stays right under the bar's bottom edge while it collapses) while the ScrollingFrame itself stays out
	from under the bar — a Roblox scrollbar spans the whole frame, so a frame behind the bar would have its scrollbar
	covered (fully, at the top of a two-row bar's list). The Scaffold's content region starts at the bar's current bottom
	and hands the content `innerPadding.Top` = expanded - current height; the ScrollingFrame that carries `Hook` takes it as
	its UIPadding.PaddingTop. For a custom layout without the Scaffold, with `expanded` the bar's expanded height and
	`top = max(0, round(expanded + State.HeightOffset))` (the bar's current height):
	    ScrollingFrame Position = (0, top), Size = (1, 0, 1, -top), UIPadding.PaddingTop = expanded - top
	The canvas grows by exactly what the frame grows, so the furthest scroll stays content - screen + expanded and the
	CanvasPosition never clamps (Studio-measured 2026-10-08: wheel scrolls, settle and scrolling up at the bottom move the
	frame with no extra CanvasPosition change; the same through the Scaffold). A wheel over the bar does not reach the list
	(it is not under the bar). The fling decay (flingAnimationSpec) and
	dragging the bar itself (Compose's draggable on the bar) are not reproduced.
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Util = require("../Util")
local Input = require("../Input")

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
local EPS = 0.01 -- px: a canvas read-back within this of the settle's last write is the settle's own

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
	local frame: ScrollingFrame? = nil
	local prevY = 0
	local version = 0
	local settling: RBXScriptConnection? = nil
	local written = 0 -- the canvas Y the running settle wrote last (a different value means someone else scrolled)

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
		local from = rec.Offset:Get()
		local fraction = from / limit
		if fraction < 0.01 or fraction == 1 then
			return
		end
		if Input.service():IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			-- a scrollbar thumb held still is not the end of the scroll (Compose settles on the fling's end, after
			-- the finger lifts): look again once the button is released
			task.delay(IDLE, settle, v)
			return
		end
		local goal = if fraction < 0.5 then 0 else limit
		local inst = frame
		local x, fromY, toY = 0, 0, 0
		if inst ~= nil then
			-- Compose animates only the height; the content's own scroll is untouched and its padding follows the bar.
			-- Here a row sits at `expanded - CanvasPosition.Y` whatever the bar does, so keep CanvasPosition.Y +
			-- HeightOffset (the kit's "content scroll under the bar") constant: the canvas moves with the bar.
			local position = inst.CanvasPosition
			x, fromY = position.X, position.Y
			local maxY = math.max(0, inst.AbsoluteCanvasSize.Y - inst.AbsoluteWindowSize.Y)
			toY = math.clamp(fromY + from - goal, 0, maxY)
			if goal == limit and toY < -limit - EPS then
				-- the content cannot scroll far enough for the first row to meet the collapsed bar: expand instead
				goal = 0
				toY = math.clamp(fromY + from, 0, maxY)
			end
		end
		local t = 0
		stopSettle()
		written = fromY
		settling = RunService.Heartbeat:Connect(function(dt: number)
			if inst ~= nil and math.abs(inst.CanvasPosition.Y - written) >= EPS then
				stopSettle() -- the user scrolled (wheel, drag, scrollbar): the scroll wins
				return
			end
			t += dt
			local k = math.min(t / SETTLE, 1)
			local u = 1 - k
			local e = 1 - u * u * u * u
			setOffset(rec, from + (goal - from) * e)
			if inst ~= nil then
				local y = fromY + (toY - fromY) * e
				written = y -- before the write: an immediate change signal must already see it as the settle's
				inst.CanvasPosition = Vector2.new(x, y)
				written = inst.CanvasPosition.Y
			end
			if k >= 1 then
				stopSettle()
			end
		end)
	end

	local function onCanvas(position: Vector2)
		local y = position.Y
		local dy = y - prevY
		prevY = y
		if settling ~= nil and math.abs(y - written) < EPS then
			-- the settle's own canvas step: it drives HeightOffset itself
			rec.Content:SetIfChanged(-y)
			return
		end
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
			task.delay(IDLE, settle, version)
		end
	end

	local hook = Util.preHook(function(inst: GuiObject)
		local scroller = (inst :: any) :: ScrollingFrame
		frame = scroller
		prevY = 0 -- a pre-hook runs before the element's properties: the canvas is at its default (0, 0)
		scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			onCanvas(scroller.CanvasPosition)
		end)
		scroller.Destroying:Connect(function()
			stopSettle()
			if frame == scroller then
				frame = nil
			end
		end)
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
