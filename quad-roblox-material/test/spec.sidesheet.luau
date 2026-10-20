--!strict
-- Side sheets: SideSheet (standard) and ModalSideSheet.open (modal) — MDC SideSheetBehavior geometry, tokens, the release
-- rule (outwards -> Expanded; significant 500 px/s swipe or past half -> Hidden), header, Escape / scrim, dispose.
local H = require("./support/harness")
local ClickSink = require("./support/clicksink")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Frame = q.Elem "Frame"
local Tokens = require("../src/Tokens")
local Overlay = require("../src/Overlay")
local Anchored = require("../src/Sheet/Anchored")
local SheetStateModule = require("../src/Sheet/State")
local SideSheetModule = require("../src/SideSheet")

local SheetState = SheetStateModule.SheetState
local SideSheet = SideSheetModule.SideSheet
local ModalSideSheet = SideSheetModule.ModalSideSheet
local L = Tokens.Color.Light
local UIS = H.UserInputService

Anchored.clock = H.now

local function uisConns(): number
	local u = UIS :: any
	return #u.InputChanged.connections + #u.InputEnded.connections + #u.WindowFocusReleased.connections
end
local function beganConns(): number
	return #(UIS :: any).InputBegan.connections
end
local baseConns, baseBegan = uisConns(), beganConns()

local function own(inst: any, className: string): any
	for _, c in inst:GetChildren() do
		if c.ClassName == className then
			return c
		end
	end
	return nil
end

local function drag(inst: any, x0: number, xs: { number }, dt: number, y: number?)
	H.fire(inst, "InputBegan", H.input({ Position = Vector3.new(x0, 300, 0) }))
	for i, x in xs do
		H.advance(dt)
		UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(x, 300 + (y or 0) * i, 0) }))
	end
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(xs[#xs], 300 + (y or 0) * #xs, 0) }))
end

local function sideState(initial: SheetStateModule.SheetValue): SheetStateModule.SheetState
	return SheetState({ InitialValue = initial, EnabledValues = { "Hidden", "Expanded" } })
end

H.section("standard: tokens (surface, no corner, no shadow, 256 wide, docked at the end), header, instance counts", function()
	local s: any = SideSheet({ Children = q.Slot<<Instance>>({ Frame { Name = "Row" } }) })
	assert(s.Name == "SideSheet" and s.BackgroundColor3 == L.Surface and s.Active == true)
	assert(s.Size == UDim2.new(0, 256, 1, 0) and s.AnchorPoint == Vector2.new(1, 0) and s.Position == UDim2.fromScale(1, 0))
	assert(own(s, "UICorner") == nil and own(s, "UIShadow") == nil and H.find(s, "CornerPatch") == nil)
	assert(H.find(s, "Header") == nil and H.find(s, "Row") ~= nil)
	local bare = H.countDescendants(s) + 1
	local withHeader: any = SideSheet({ Headline = "Filters" })
	local headline = H.find(withHeader, "Headline")
	assert(headline.Text == "Filters" and headline.TextSize == 22 and headline.TextColor3 == L.OnSurface, "TitleLarge onSurface")
	assert(H.find(withHeader, "Close") ~= nil, "close icon button")
	assert(own(H.find(withHeader, "Inner"), "UIPadding").PaddingLeft == UDim.new(0, 16), "16 padding")
	assert(H.find(withHeader, "Body").Position == UDim2.fromOffset(0, 52), "content 24 under the 28 px headline")
	local header = H.countDescendants(withHeader) + 1
	print(`[sidesheet] standard: {bare} instances (1 row), with header {header} (no rows)`)
	H.resetOutput()
	assert(bare == 6 and header == 13, `counts {bare} / {header}`)
	q.dispose(s)
	q.dispose(withHeader)
	assert(not pcall(SideSheet, { SheetState = SheetState() }), "a state with PartiallyExpanded is refused")
	H.assertNoDebugOutput("standard tokens")
end)

H.section("standard: Hide / Expand slide 256 px past the end edge (275 ms) and settle; close button hides; Start edge", function()
	local state = sideState("Expanded")
	local s: any = SideSheet({ SheetState = state, Headline = "H" })
	state.Hide()
	H.finishTweens()
	assert(s.Position == UDim2.new(1, 256, 0, 0), "hidden past the right edge " .. tostring(s.Position))
	H.advance(0.2)
	assert(state.CurrentValue:Get() == "Expanded", "not settled before 275 ms")
	H.advance(0.1)
	assert(state.CurrentValue:Get() == "Hidden")
	state.Expand()
	H.advance(0.3)
	H.fire(H.find(s, "Close"), "Activated", H.input({}), 1)
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Hidden", "the close button hides")
	q.dispose(s)
	-- a sheet that cannot hide has no close button
	local stay = SideSheet({ Headline = "H", SheetState = SheetState({ InitialValue = "Expanded", EnabledValues = { "Expanded" } }) })
	assert(H.find(stay, "Close") == nil)
	q.dispose(stay)
	-- start edge
	local left = sideState("Hidden")
	local l: any = SideSheet({ SheetState = left, SheetEdge = "Start", Width = 300 })
	assert(l.AnchorPoint == Vector2.new(0, 0) and l.Position == UDim2.new(0, -300, 0, 0), "hidden past the left edge")
	left.Expand()
	H.finishTweens()
	assert(l.Position == UDim2.fromScale(0, 0))
	q.dispose(l)
	H.advance(1)
	H.assertNoDebugOutput("standard motion")
end)

H.section("standard drag: outwards keeps it, past half hides, a 500 px/s swipe hides, slow short drags stay", function()
	local state = sideState("Expanded")
	local s: any = SideSheet({ SheetState = state })
	-- the sheet's left edge sits at x = 744 (an 1000 px parent); drag inwards (to the right) 100 px slowly: stays
	drag(s, 800, { 820, 840, 860, 880, 900 }, 0.05)
	H.finishTweens()
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Expanded" and s.Position == UDim2.fromScale(1, 0), "100 px < 128 at 400 px/s: stays")
	-- past half (140 px) slowly
	drag(s, 800, { 820, 840, 860, 880, 900, 920, 940 }, 0.06)
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Hidden", "past half: hidden")
	state.Expand()
	H.advance(0.3)
	-- a short fast swipe (40 px in 50 ms = 800 px/s > 500): hidden
	drag(s, 800, { 820, 840 }, 0.025)
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Hidden", "significant swipe: hidden")
	state.Expand()
	H.advance(0.3)
	-- a fast swipe that is mostly vertical is not significant
	drag(s, 800, { 810, 820 }, 0.025, 40)
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Expanded", "mostly vertical: not significant")
	-- past half but moving outwards (back to the left) at release: expanded
	drag(s, 800, { 840, 880, 920, 960, 940, 920, 900 }, 0.03)
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Expanded", "moving outwards wins")
	-- Draggable = false
	q.dispose(s)
	local fixed = sideState("Expanded")
	local f: any = SideSheet({ SheetState = fixed, Draggable = false })
	drag(f, 800, { 900, 1000 }, 0.02)
	assert(f.Position == UDim2.fromScale(1, 0) and uisConns() == baseConns)
	q.dispose(f)
	H.advance(1)
	assert(uisConns() == baseConns and H.pendingTimers() == 0)
	H.assertNoDebugOutput("standard drag")
end)

H.section("modal: tokens (surfaceContainerLow, inner corner 16, shadow 1), slides in, Overlay scrim, Escape / scrim / drag / Close", function()
	local overlay = Overlay.new()
	local screen = Frame { overlay.Layer }
	local results: { any } = {}
	local handle = ModalSideSheet.open({
		Overlay = overlay,
		Headline = "Details",
		OnClose = function(r: unknown?)
			table.insert(results, r or "nil")
		end,
	})
	local s: any = H.find(screen, "SideSheet")
	assert(s.BackgroundColor3 == L.SurfaceContainerLow and own(s, "UICorner").CornerRadius == UDim.new(0, 16))
	assert(s.Active == true, "the sheet above the scrim keeps 3D input out")
	ClickSink.assertClickSink(s, "the modal side sheet")
	assert(own(s, "UIShadow") ~= nil, "level-1 shadow")
	local patch = H.find(s, "CornerPatch")
	assert(patch.AnchorPoint == Vector2.new(1, 0) and patch.Size == UDim2.new(0, 16, 1, 0), "the outer (right) corners squared off")
	assert(H.find(screen, "Scrim") ~= nil, "the Overlay's scrim")
	assert(s.Position == UDim2.new(1, 256, 0, 0), "mounted hidden")
	H.finishTweens()
	assert(s.Position == UDim2.fromScale(1, 0) and handle.IsOpen:Get(), "slid in")
	local n = H.countDescendants(s) + 1
	print(`[sidesheet] modal with header: {n} instances`)
	H.resetOutput()
	assert(n == 17, "modal count " .. n)
	-- Escape closes; the sheet slides out during the exit time
	UIS.InputBegan:Fire(H.input({ KeyCode = Enum.KeyCode.Escape, UserInputType = Enum.UserInputType.Keyboard }), false)
	assert(not handle.IsOpen:Get() and #results == 1)
	H.finishTweens()
	assert(s.Position == UDim2.new(1, 256, 0, 0), "slid out")
	H.advance(0.3)
	assert(#overlay.Layer:GetChildren() == 0)
	-- the close button
	local h2 = ModalSideSheet.open({ Overlay = overlay, Headline = "x" })
	H.finishTweens()
	H.fire(H.find(screen, "Close"), "Activated", H.input({}), 1)
	assert(not h2.IsOpen:Get())
	H.advance(0.3)
	-- drag off the screen (start edge): closes
	local h3 = ModalSideSheet.open({ Overlay = overlay, SheetEdge = "Start" })
	H.finishTweens()
	local s3: any = H.find(screen, "SideSheet")
	assert(s3.AnchorPoint == Vector2.new(0, 0) and H.find(s3, "CornerPatch").AnchorPoint == Vector2.new(0, 0))
	-- the press on a modal sheet stops at its ClickSink (Util.luau "INPUT RULE"): the Frame has no hook, the sink drags
	H.fire(s3, "InputBegan", H.input({ Position = Vector3.new(200, 300, 0) }))
	assert(uisConns() == baseConns, "the modal sheet Frame carries no drag hook")
	local sink3 = nil
	for _, c in s3:GetChildren() do
		if c.Name == "ClickSink" then
			sink3 = c
		end
	end
	drag(sink3, 200, { 180, 160 }, 0.025)
	assert(not h3.IsOpen:Get(), "swiped off: closed")
	H.advance(0.3)
	-- Close(result) and the flags
	local h4 = ModalSideSheet.open({ Overlay = overlay, DismissOnScrim = false, DismissOnEscape = false, OnClose = function(r: unknown?)
		table.insert(results, r)
	end })
	H.finishTweens()
	H.fire(H.find(screen, "Scrim"), "Activated", H.input({}), 1)
	UIS.InputBegan:Fire(H.input({ KeyCode = Enum.KeyCode.Escape, UserInputType = Enum.UserInputType.Keyboard }), false)
	assert(h4.IsOpen:Get(), "flags off: neither closes")
	h4.Close("done")
	assert(results[#results] == "done")
	H.advance(0.3)
	assert(#overlay.Layer:GetChildren() == 0 and uisConns() == baseConns and beganConns() == baseBegan and H.pendingTimers() == 0)
	q.dispose(screen)
	H.assertNoDebugOutput("modal")
end)

H.section("modal: layer death finalizes, nothing left", function()
	local overlay = Overlay.new()
	local screen = Frame { overlay.Layer }
	local closes = 0
	local handle = ModalSideSheet.open({
		Overlay = overlay,
		OnClose = function()
			closes += 1
		end,
	})
	H.fire(H.find(H.find(screen, "SideSheet"), "ClickSink"), "InputBegan", H.input({ Position = Vector3.new(800, 300, 0) }))
	q.dispose(screen)
	H.advance(1)
	assert(closes == 1 and not handle.IsOpen:Get() and handle.SheetState.CurrentValue:Get() == "Hidden")
	assert(uisConns() == baseConns and beganConns() == baseBegan and H.pendingTimers() == 0)
	H.assertNoDebugOutput("death")
end)

H.section("detached standard: 16 off the top / bottom / edge, four corners 16, still surface and no shadow, Inner clips; hidden = width + margin out", function()
	local state = sideState("Expanded")
	local s: any = SideSheet({ SheetState = state, Detached = true, Children = q.Slot<<Instance>>({ Frame { Name = "Row" } }) })
	assert(s.Size == UDim2.new(0, 256, 1, -32), "256 wide, 16 short at the top and the bottom " .. tostring(s.Size))
	assert(s.AnchorPoint == Vector2.new(1, 0) and s.Position == UDim2.new(1, -16, 0, 16), "16 in from the end edge and the top " .. tostring(s.Position))
	assert(own(s, "UICorner").CornerRadius == UDim.new(0, 16) and H.find(s, "CornerPatch") == nil, "all four corners: a UICorner and no patch")
	assert(s.BackgroundColor3 == L.Surface and own(s, "UIShadow") == nil, "the standard sheet's color and level0 (MDC: the style adds margin + shape only)")
	assert(H.find(s, "Inner").ClipsDescendants == true, "the content holder clips at the sheet's rectangle")
	assert(H.countDescendants(s) + 1 == 7, "bare 6 + the UICorner")
	-- docked sheets keep the old structure
	local docked: any = SideSheet({})
	assert(H.find(docked, "Inner").ClipsDescendants == false and docked.Size == UDim2.new(0, 256, 1, 0))
	q.dispose(docked)
	-- hidden: the sheet AND its margin past the edge (anchored at its right edge: 256 + 16 travel from the -16 spot)
	state.Hide()
	H.finishTweens()
	assert(s.Position == UDim2.new(1, 256, 0, 16), "hidden: its left edge on the parent's right edge " .. tostring(s.Position))
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Hidden")
	state.Expand()
	H.finishTweens()
	H.advance(0.3)
	assert(s.Position == UDim2.new(1, -16, 0, 16) and state.CurrentValue:Get() == "Expanded")
	-- released halfway (end edge): the halfway point counts the margin — (256 + 16) / 2 = 136
	drag(s, 800, { 810, 820, 830, 840, 850, 860, 870, 880, 890, 900, 910, 920, 930 }, 0.05)
	H.finishTweens()
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Expanded" and s.Position == UDim2.new(1, -16, 0, 16), "130 px < 136: stays")
	drag(s, 800, { 810, 820, 830, 840, 850, 860, 870, 880, 890, 900, 910, 920, 930, 940 }, 0.05)
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Hidden", "140 px > 136: hidden")
	q.dispose(s)
	-- start edge: 16 in from the left, hidden the same travel to the left; its halfway point is Width / 2 = 128
	local left = sideState("Hidden")
	local l: any = SideSheet({ SheetState = left, SheetEdge = "Start", Detached = true })
	assert(l.AnchorPoint == Vector2.new(0, 0) and l.Position == UDim2.new(0, -256, 0, 16), "hidden: its right edge on the parent's left edge " .. tostring(l.Position))
	left.Expand()
	H.finishTweens()
	H.advance(0.3)
	assert(l.Position == UDim2.new(0, 16, 0, 16), "16 in from the start edge")
	drag(l, 200, { 190, 180, 170, 160, 150, 140, 130, 120, 110, 100, 90, 80, 70 }, 0.05)
	H.advance(0.3)
	assert(left.CurrentValue:Get() == "Hidden", "130 px > 128 at the start edge: hidden")
	q.dispose(l)
	H.advance(1)
	assert(uisConns() == baseConns and H.pendingTimers() == 0)
	H.assertNoDebugOutput("detached standard")
end)

H.section("detached modal: four corners (no patch), the modal color + level-1 shadow, enters from fully past the edge, drag / close as docked", function()
	local overlay = Overlay.new()
	local screen = Frame { overlay.Layer }
	local handle = ModalSideSheet.open({ Overlay = overlay, Headline = "Details", Detached = true })
	local s: any = H.find(screen, "SideSheet")
	assert(s.BackgroundColor3 == L.SurfaceContainerLow and own(s, "UICorner").CornerRadius == UDim.new(0, 16))
	assert(own(s, "UIShadow") ~= nil, "level-1 shadow (a child of the Sheet, outside the clipping Inner)")
	assert(H.find(s, "CornerPatch") == nil, "no corner squared off")
	assert(H.find(s, "Inner").ClipsDescendants == true and own(H.find(s, "Inner"), "UIShadow") == nil)
	ClickSink.assertClickSink(s, "the detached modal side sheet")
	assert(s.Size == UDim2.new(0, 256, 1, -32))
	assert(s.Position == UDim2.new(1, 256, 0, 16), "mounted hidden, margin included " .. tostring(s.Position))
	assert(H.find(screen, "Scrim") ~= nil, "over the Overlay's scrim")
	H.finishTweens()
	assert(s.Position == UDim2.new(1, -16, 0, 16) and handle.IsOpen:Get(), "slid in to 16 from the edge")
	assert(H.countDescendants(s) + 1 == 16, "the docked modal's 17 without the CornerPatch")
	-- dragging it off closes it
	local sink = nil
	for _, c in s:GetChildren() do
		if c.Name == "ClickSink" then
			sink = c
		end
	end
	drag(sink, 800, { 820, 840 }, 0.025)
	assert(not handle.IsOpen:Get(), "swiped off: closed")
	H.finishTweens()
	assert(s.Position == UDim2.new(1, 256, 0, 16), "slid out past the edge")
	H.advance(0.3)
	assert(#overlay.Layer:GetChildren() == 0)
	-- start edge, and it opens again
	local h2 = ModalSideSheet.open({ Overlay = overlay, SheetEdge = "Start", Detached = true })
	local s2: any = H.find(screen, "SideSheet")
	assert(s2.Position == UDim2.new(0, -256, 0, 16), "mounted hidden at the start edge")
	H.finishTweens()
	assert(s2.Position == UDim2.new(0, 16, 0, 16) and H.find(s2, "CornerPatch") == nil)
	h2.Close(nil)
	H.advance(0.3)
	assert(#overlay.Layer:GetChildren() == 0 and uisConns() == baseConns and beganConns() == baseBegan and H.pendingTimers() == 0)
	q.dispose(screen)
	H.assertNoDebugOutput("detached modal")
end)

H.done()
