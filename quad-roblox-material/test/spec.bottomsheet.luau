--!strict
-- Bottom sheets: BottomSheetScaffold (standard) and ModalBottomSheet.open (modal) — Compose geometry, SheetState,
-- drag thresholds (positional 56 / velocity 125), handle clicks, back key, scrim, dispose.
local H = require("./support/harness")
local ClickSink = require("./support/clicksink")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Tokens = require("../src/Tokens")
local Overlay = require("../src/Overlay")
local Anchored = require("../src/Sheet/Anchored")
local SheetStateModule = require("../src/Sheet/State")
local BottomSheet = require("../src/BottomSheet")
local Bounded = require("./support/bounded")

local SheetState = SheetStateModule.SheetState
local Scaffold = BottomSheet.BottomSheetScaffold
local Modal = BottomSheet.ModalBottomSheet
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

-- the surface's ClickSink: a press on the sheet stops at this GuiButton (the Frame under it never gets InputBegan — Studio
-- 2026-10-08, Util.luau "INPUT RULE"), so the drag hook lives here
local function sinkOf(sheet: any): any
	for _, c in sheet:GetChildren() do
		if c.Name == "ClickSink" then
			return c
		end
	end
	error("no ClickSink")
end

-- a real click on the handle, in the engine's order (Studio 2026-10-08): InputBegan, Activated, the element's InputEnded,
-- then UserInputService.InputEnded
local function clickHandle(handle: any)
	local i = H.input({ Position = Vector3.new(200, 10, 0) })
	H.fire(handle, "InputBegan", i)
	H.fire(handle, "Activated", i, 1)
	H.fire(handle, "InputEnded", i)
	UIS.InputEnded:Fire(i)
end

-- drag: press on `inst` at y, then moves (each after `dt` seconds), release at the last y
local function drag(inst: any, y0: number, ys: { number }, dt: number, restBeforeRelease: number?)
	H.fire(inst, "InputBegan", H.input({ Position = Vector3.new(200, y0, 0) }))
	for _, y in ys do
		H.advance(dt)
		UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(200, y, 0) }))
	end
	if restBeforeRelease then
		H.advance(restBeforeRelease)
	end
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(200, ys[#ys], 0) }))
end

local function key(code: Enum.KeyCode)
	UIS.InputBegan:Fire(H.input({ KeyCode = code, UserInputType = Enum.UserInputType.Keyboard }), false)
end

local function offsetOf(sheet: any): number
	local p: UDim2 = sheet.Position
	assert(p.Y.Scale == 1 and p.X.Scale == 0.5 and p.X.Offset == 0, "bottom-anchored, centered: " .. tostring(p))
	return p.Y.Offset
end

local function scaffold(props: any): (any, any, any)
	local body = D.Frame { Name = "Body content", Size = UDim2.fromOffset(100, 200) }
	local host = Scaffold(props)
	local screen = D.Frame { host }
	local sheet = H.find(host, "BottomSheet")
	H.setAbs(host, 0, 0, 400, 800)
	H.setAbs(H.find(sheet, "Content"), 0, 0, 400, props.ContentHeight or 200)
	local _ = body
	return screen, host, sheet
end

-- ── standard ────────────────────────────────────────────────────────────────

H.section("scaffold: structure, tokens, instance count", function()
	local host = Scaffold({ SheetContent = q.Slot<<Instance>>({ D.Frame { Name = "Row" } }), Content = q.Slot<<Instance>>({ D.Frame { Name = "Page" } }) })
	assert(host.Name == "BottomSheetScaffold" and host.BackgroundColor3 == L.Surface and host.ClipsDescendants == true)
	assert(host.Size == UDim2.fromScale(1, 1))
	local body = H.find(host, "Body")
	assert(own(body, "UIPadding").PaddingBottom == UDim.new(0, 56), "content padded by the peek height")
	assert(H.find(body, "Page") ~= nil)
	local sheet: any = H.find(host, "BottomSheet")
	assert(sheet.BackgroundColor3 == L.SurfaceContainerLow and sheet.Active == true)
	assert(own(sheet, "UICorner").CornerRadius == UDim.new(0, 28), "top corners 28 (CornerExtraLargeTop)")
	assert(own(sheet, "UISizeConstraint").MaxSize.X == 640, "max width 640")
	assert(own(sheet, "UIShadow") ~= nil, "standard sheet: shadow (Level1)")
	local patch = H.find(sheet, "CornerPatch")
	assert(patch.Size == UDim2.new(1, 0, 0, 28) and patch.AnchorPoint == Vector2.new(0, 1) and patch.BackgroundColor3 == L.SurfaceContainerLow)
	local handle = H.find(sheet, "DragHandle")
	assert(handle.Size == UDim2.fromOffset(32, 48), "the clickable handle box 32 x 48")
	local bar = H.find(handle, "Bar")
	assert(bar.Size == UDim2.fromOffset(32, 4) and bar.BackgroundColor3 == L.OnSurfaceVariant)
	assert(own(bar, "UICorner").CornerRadius == UDim.new(0.5, 0))
	assert(H.find(sheet, "ContentClip").ClipsDescendants == true and H.find(sheet, "Row") ~= nil)
	local n = H.countDescendants(sheet) + 1
	print(`[bottomsheet] standard sheet: {n} instances (1 content row)`)
	H.resetOutput()
	assert(n == 16, "sheet instances " .. n)
	-- an M3 Surface blocks pointer input (Surface.kt 131): the standard sheet carries the sink too
	ClickSink.assertClickSink(sheet, "the standard bottom sheet")
	q.dispose(host)
	H.assertNoDebugOutput("structure")
end)

H.section("scaffold: first layout snaps to the peek; Expand / handle click / PartialExpand animate and settle", function()
	local state = SheetState({ InitialValue = "PartiallyExpanded", EnabledValues = { "PartiallyExpanded", "Expanded" } })
	local screen, _host, sheet = scaffold({ SheetState = state })
	assert(offsetOf(sheet) == -56, "peeks 56 " .. offsetOf(sheet))
	assert(sheet.Size == UDim2.new(1, 0, 0, 248), "handle 48 + content 200")
	state.Expand()
	assert(state.TargetValue:Get() == "Expanded" and state.CurrentValue:Get() == "PartiallyExpanded", "target first")
	H.finishTweens()
	assert(offsetOf(sheet) == -248)
	H.advance(0.25)
	assert(state.CurrentValue:Get() == "Expanded", "settled when the motion ends")
	-- handle click on Expanded: no Hidden -> PartialExpand
	clickHandle(H.find(sheet, "DragHandle"))
	H.finishTweens()
	H.advance(0.25)
	assert(state.CurrentValue:Get() == "PartiallyExpanded" and offsetOf(sheet) == -56)
	clickHandle(H.find(sheet, "DragHandle"))
	H.advance(0.25)
	assert(state.CurrentValue:Get() == "Expanded", "handle on Partial expands")
	assert(not pcall(state.Hide), "Hide errors when Hidden is not enabled")
	q.dispose(screen)
	H.advance(1)
	assert(H.pendingTimers() == 0)
	H.assertNoDebugOutput("scaffold motion")
end)

H.section("scaffold drag: follow, positional threshold 56, velocity 125, clamp, veto", function()
	local state = SheetState({ InitialValue = "Expanded", EnabledValues = { "PartiallyExpanded", "Expanded" } })
	local screen, _host, sheet = scaffold({ SheetState = state })
	assert(offsetOf(sheet) == -248)
	-- slow drag 50 px down (5 px per 50 ms = 100 px/s < 125): under the 56 threshold -> back to Expanded
	drag(sinkOf(sheet), 600, { 605, 610, 615, 620, 625, 630, 635, 640, 645, 650 }, 0.05)
	assert(uisConns() == baseConns, "drag connections closed")
	H.finishTweens()
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Expanded" and offsetOf(sheet) == -248, "50 px < 56: stays")
	-- slow drag 60 px (100 px/s): past 56 -> PartiallyExpanded
	drag(sinkOf(sheet), 600, { 605, 610, 615, 620, 625, 630, 635, 640, 645, 650, 655, 660 }, 0.05)
	H.finishTweens()
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "PartiallyExpanded", "60 px >= 56: next anchor")
	-- while dragging the sheet follows the pointer (snapped), clamped to the anchors' range
	H.fire(sinkOf(sheet), "InputBegan", H.input({ Position = Vector3.new(200, 760, 0) }))
	H.advance(0.05)
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(200, 700, 0) }))
	assert(offsetOf(sheet) == -116, "follows: -56 - 60 = " .. offsetOf(sheet))
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(200, 100, 0) }))
	assert(offsetOf(sheet) == -248, "clamped at Expanded")
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(200, 900, 0) }))
	assert(offsetOf(sheet) == -56, "clamped at PartiallyExpanded (no Hidden)")
	H.advance(0.1)
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(200, 900, 0) }))
	H.advance(0.3)
	-- fling: 30 px up in 0.05 s = 600 px/s >= 125 -> the next anchor up, whatever the distance
	drag(sinkOf(sheet), 760, { 745, 730 }, 0.025)
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Expanded", "fling up expands")
	-- a pause > 40 ms before the release zeroes the velocity: back to the closest anchor
	drag(sinkOf(sheet), 600, { 580, 560 }, 0.01, 0.1)
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Expanded")
	-- the click that ends a real drag on the handle is not a click
	local handle = H.find(sheet, "DragHandle")
	drag(handle, 560, { 540, 520 }, 0.2)
	H.fire(handle, "Activated", H.input({}), 1)
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Expanded", "no handle click after a drag")
	q.dispose(screen)
	H.advance(1)
	-- veto
	local vetoed = SheetState({
		InitialValue = "Expanded",
		EnabledValues = { "PartiallyExpanded", "Expanded" },
		ConfirmValueChange = function(v)
			return v ~= "PartiallyExpanded"
		end,
	})
	local screen2, _h2, sheet2 = scaffold({ SheetState = vetoed })
	drag(sinkOf(sheet2), 600, { 610, 620, 630, 640, 650, 660, 670, 680 }, 0.05)
	H.finishTweens()
	H.advance(0.3)
	assert(vetoed.CurrentValue:Get() == "Expanded" and offsetOf(sheet2) == -248, "vetoed target settles back")
	vetoed.PartialExpand()
	assert(vetoed.TargetValue:Get() == "Expanded", "methods ask the veto too")
	q.dispose(screen2)
	H.advance(1)
	-- swipe disabled
	local still = SheetState({ InitialValue = "Expanded", EnabledValues = { "PartiallyExpanded", "Expanded" } })
	local screen3, _h3, sheet3 = scaffold({ SheetState = still, SheetSwipeEnabled = false })
	drag(sinkOf(sheet3), 600, { 650, 700, 750 }, 0.02)
	assert(offsetOf(sheet3) == -248 and still.CurrentValue:Get() == "Expanded" and uisConns() == baseConns, "SheetSwipeEnabled = false")
	q.dispose(screen3)
	H.advance(1)
	assert(uisConns() == baseConns and H.pendingTimers() == 0)
	H.assertNoDebugOutput("scaffold drag")
end)

H.section("scaffold with Hidden: drag down hides, handle shows it again; peek 0 / no handle", function()
	local state = SheetState({ InitialValue = "PartiallyExpanded" })
	local screen, _host, sheet = scaffold({ SheetState = state })
	drag(sinkOf(sheet), 760, { 790, 820 }, 0.02) -- fast, down
	H.finishTweens()
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Hidden" and offsetOf(sheet) == 0, "hidden below the host")
	state.Show()
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "PartiallyExpanded", "Show -> PartiallyExpanded (the anchor exists)")
	state.Hide()
	H.advance(0.3)
	clickHandle(H.find(sheet, "DragHandle"))
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "PartiallyExpanded", "handle on Hidden shows")
	q.dispose(screen)
	H.advance(1)
	local s2 = SheetState({ InitialValue = "Expanded", EnabledValues = { "PartiallyExpanded", "Expanded" } })
	local screen2, _h, sheet2 = scaffold({ SheetState = s2, SheetDragHandle = false, SheetPeekHeight = 80 })
	assert(H.find(sheet2, "DragHandle") == nil and sheet2.Size == UDim2.new(1, 0, 0, 200), "no handle box")
	s2.PartialExpand()
	H.finishTweens()
	assert(offsetOf(sheet2) == -80, "custom peek")
	q.dispose(screen2)
	H.advance(1)
	H.assertNoDebugOutput("scaffold hidden")
end)

H.section("press hooks where the engine delivers the press; the handle's canon ripple, drag cancel, armed click", function()
	local state = SheetState({ InitialValue = "Expanded", EnabledValues = { "PartiallyExpanded", "Expanded" } })
	local screen, _host, sheet = scaffold({ SheetState = state })
	-- the engine never delivers InputBegan to the Frame under a full-cover GuiButton (Util.luau "INPUT RULE"): no hook there
	H.fire(sheet, "InputBegan", H.input({ Position = Vector3.new(200, 600, 0) }))
	assert(uisConns() == baseConns, "the sheet Frame carries no drag hook (the press lands on its ClickSink)")
	H.fire(sinkOf(sheet), "InputBegan", H.input({ Position = Vector3.new(200, 600, 0) }))
	assert(uisConns() > baseConns, "the ClickSink starts the drag")
	UIS.InputEnded:Fire(H.input({ Position = Vector3.new(200, 600, 0) }))
	assert(uisConns() == baseConns)
	-- canon: `Modifier.clickable` with LocalIndication = ripple (BottomSheet.kt 364-372, Clickable.kt 199-210)
	local handle = H.find(sheet, "DragHandle")
	local layer = H.find(handle, "StateLayer")
	assert(layer ~= nil and layer.Size == UDim2.fromScale(1, 1), "the handle box has the state layer / ripple (canon)")
	-- a drag past the slop cancels the handle's press: its ripple fades and no click follows, even after the 0.25 s window
	H.setAbs(handle, 184, 552, 32, 48)
	H.setAbs(layer, 184, 552, 32, 48)
	local press = H.input({ Position = Vector3.new(200, 560, 0) })
	H.fire(handle, "InputBegan", press)
	H.advance(1 / 60)
	assert(H.find(layer, "Ripple") ~= nil, "pressed: a ripple")
	for _, y in { 550, 540, 530 } do
		H.advance(0.05)
		UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(200, y, 0) }))
	end
	H.advance(0.5)
	assert(H.find(layer, "Ripple") == nil, "the drag cancelled the press: the ripple faded out")
	H.fire(handle, "Activated", press, 1)
	H.fire(handle, "InputEnded", press)
	UIS.InputEnded:Fire(press)
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Expanded", "no click from a press the drag took over")
	-- the engine fires Activated on mouse-up over a button that kept an unfinished earlier press, even when this press
	-- began elsewhere (Studio 2026-10-08): a pointer Activated without a live press on the handle is ignored
	H.fire(handle, "Activated", H.input({}), 1)
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Expanded", "no click without a press that began on the handle")
	-- gamepad / keyboard activation is not filtered
	H.fire(handle, "Activated", H.input({ UserInputType = Enum.UserInputType.Gamepad1, KeyCode = Enum.KeyCode.ButtonA }), 1)
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "PartiallyExpanded", "gamepad activation clicks")
	clickHandle(handle)
	H.advance(0.3)
	assert(state.CurrentValue:Get() == "Expanded", "a real click still toggles (Partial -> Expanded)")
	assert(uisConns() == baseConns)
	q.dispose(screen)
	H.advance(1)
	H.assertNoDebugOutput("handle input")
end)

H.section("drag handle: its ripple stays inside the 32 x 48 box (BOUNDED)", function()
	local state = SheetState({ InitialValue = "Expanded" })
	local screen, _host, sheet = scaffold({ SheetState = state })
	Bounded.pressBounded(H.find(sheet, "DragHandle"), 32, 48, "drag handle")
	assert(uisConns() == baseConns, "the press's drag session closed")
	q.dispose(screen)
	H.advance(1)
	H.assertNoDebugOutput("handle ripple")
end)

H.section("SheetState: options are checked; without a component a request settles at once; the latest component drives it", function()
	assert(not pcall(SheetState :: any, { EnabledValues = { "Hidden", "PartiallyExpanded" } }), "Expanded required")
	assert(not pcall(SheetState :: any, { InitialValue = "PartiallyExpanded", EnabledValues = { "Hidden", "Expanded" } }), "initial enabled")
	assert(not pcall(SheetState :: any, { EnabledValues = { "Open" :: any, "Expanded" } }), "unknown value")
	local s = SheetState()
	assert(s.CurrentValue:Get() == "Hidden")
	s.Show()
	assert(s.CurrentValue:Get() == "PartiallyExpanded" and s.TargetValue:Get() == "PartiallyExpanded")
	s.Expand()
	assert(s.CurrentValue:Get() == "Expanded")
	local s2 = SheetState({ InitialValue = "Hidden", EnabledValues = { "Hidden", "Expanded" } })
	assert(not pcall(s2.PartialExpand), "PartialExpand without the value")
	s2.Show()
	assert(s2.CurrentValue:Get() == "Expanded", "Show without PartiallyExpanded -> Expanded")
	-- the component built last drives the state (a rebuild takes it over); the old one's dispose leaves it alone
	local shown = SheetState({ InitialValue = "Expanded" })
	local a = Scaffold({ SheetState = shown })
	local b = Scaffold({ SheetState = shown })
	q.dispose(a)
	H.setAbs(b, 0, 0, 400, 800)
	H.setAbs(H.find(b, "Content"), 0, 0, 400, 100)
	shown.PartialExpand()
	assert(shown.CurrentValue:Get() == "Expanded", "still driven (by b): settles after the motion")
	H.finishTweens()
	assert(H.find(b, "BottomSheet").Position == UDim2.new(0.5, 0, 1, -56), "b moved")
	H.advance(0.3)
	assert(shown.CurrentValue:Get() == "PartiallyExpanded")
	q.dispose(b)
	H.advance(1)
	H.assertNoDebugOutput("state")
end)

-- ── modal ───────────────────────────────────────────────────────────────────

local function setup(): (Overlay.Overlay, any)
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	return overlay, screen
end

local function layout(screen: any, contentHeight: number): (any, any)
	local root = H.find(screen, "ModalBottomSheet")
	local sheet = H.find(root, "BottomSheet")
	H.setAbs(root, 0, 0, 400, 800)
	H.setAbs(H.find(sheet, "Content"), 0, 0, 400, contentHeight)
	return root, sheet
end

H.section("modal: opens Hidden, shows after the first layout (rises), scrim follows the target; no shadow", function()
	local overlay, screen = setup()
	local closes: { any } = {}
	local handle = Modal.open({
		Overlay = overlay,
		Children = q.Slot<<Instance>>({ D.Frame { Name = "Row" } }),
		OnClose = function(r: unknown?)
			table.insert(closes, r or "nil")
		end,
	})
	assert(handle.IsOpen:Get() and handle.SheetState.CurrentValue:Get() == "Hidden")
	local root = H.find(screen, "ModalBottomSheet")
	local sheet = H.find(root, "BottomSheet")
	local scrim = H.find(root, "Scrim")
	assert(own(sheet, "UIShadow") == nil, "modal: no shadow (tonal 0)")
	assert(sheet.Active == true and root.Active ~= true, "the sheet above the scrim keeps 3D input out; the full-size root does not")
	ClickSink.assertClickSink(sheet, "the modal bottom sheet")
	assert(scrim.BackgroundColor3 == L.Scrim and scrim.BackgroundTransparency == 1 and scrim.Selectable == false)
	assert(offsetOf(sheet) == 0, "mounted hidden")
	layout(screen, 200)
	assert(handle.SheetState.TargetValue:Get() == "PartiallyExpanded", "Show after layout")
	H.finishTweens()
	-- 248 tall < half of 800: PartiallyExpanded converges with Expanded at the sheet's height
	assert(offsetOf(sheet) == -248 and math.abs(scrim.BackgroundTransparency - 0.68) < 1e-6, "risen, scrim 0.32")
	H.advance(0.3)
	assert(handle.SheetState.CurrentValue:Get() == "PartiallyExpanded")
	-- scrim tap: hide + close
	H.fire(scrim, "Activated", H.input({}), 1)
	assert(not handle.IsOpen:Get() and #closes == 1, "closing at once")
	H.finishTweens()
	assert(offsetOf(sheet) == 0 and scrim.BackgroundTransparency == 1, "slid out, scrim faded")
	H.advance(0.3)
	assert(#overlay.Layer:GetChildren() == 0 and H.pendingTimers() == 0 and beganConns() == baseBegan, "entry removed, Escape released")
	assert(handle.SheetState.CurrentValue:Get() == "Hidden")
	q.dispose(screen)
	H.assertNoDebugOutput("modal open")
end)

H.section("modal tall content: partial at half the layer; handle expands; back steps down then closes", function()
	local overlay, screen = setup()
	local handle = Modal.open({ Overlay = overlay })
	local _root, sheet = layout(screen, 600)
	H.finishTweens()
	assert(sheet.Size == UDim2.new(1, 0, 0, 648) and offsetOf(sheet) == -400, "PartiallyExpanded = half of 800")
	H.advance(0.3)
	clickHandle(H.find(sheet, "DragHandle"))
	H.finishTweens()
	H.advance(0.3)
	assert(handle.SheetState.CurrentValue:Get() == "Expanded" and offsetOf(sheet) == -648)
	key(Enum.KeyCode.Escape)
	H.advance(0.3)
	assert(handle.IsOpen:Get() and handle.SheetState.CurrentValue:Get() == "PartiallyExpanded", "back: Expanded -> PartiallyExpanded")
	key(Enum.KeyCode.ButtonB)
	assert(not handle.IsOpen:Get(), "back again: hide + close")
	H.advance(0.3)
	assert(#overlay.Layer:GetChildren() == 0)
	-- the same state opens another sheet at once (handed back when closing started)
	local state = SheetState({ InitialValue = "Hidden" })
	local h1 = Modal.open({ Overlay = overlay, SheetState = state })
	layout(screen, 100)
	h1.Close()
	local h2 = Modal.open({ Overlay = overlay, SheetState = state })
	assert(h2.IsOpen:Get(), "reopened while the first slides out")
	h2.Close()
	H.advance(0.5)
	q.dispose(screen)
	H.assertNoDebugOutput("modal tall")
end)

H.section("modal drag: fling down dismisses; Close(result) animates out; veto; DismissOnScrim / DismissOnEscape false", function()
	local overlay, screen = setup()
	local got: { any } = {}
	local handle = Modal.open({
		Overlay = overlay,
		OnClose = function(r: unknown?)
			table.insert(got, r or "nil")
		end,
	})
	local _root, sheet = layout(screen, 200)
	H.advance(0.3)
	drag(sinkOf(sheet), 600, { 630, 660 }, 0.02)
	assert(not handle.IsOpen:Get() and #got == 1, "flung to Hidden: closed")
	H.advance(0.3)
	assert(#overlay.Layer:GetChildren() == 0)
	-- Close(result)
	local h2 = Modal.open({
		Overlay = overlay,
		OnClose = function(r: unknown?)
			table.insert(got, r)
		end,
	})
	local _r2, sheet2 = layout(screen, 200)
	H.finishTweens()
	h2.Close(42)
	assert(got[2] == 42 and h2.SheetState.TargetValue:Get() == "Hidden")
	H.finishTweens()
	assert(offsetOf(sheet2) == 0)
	H.advance(0.3)
	-- veto Hidden: scrim and handle do nothing, Close still closes
	local state = SheetState({
		InitialValue = "Hidden",
		ConfirmValueChange = function(v)
			return v ~= "Hidden"
		end,
	})
	local h3 = Modal.open({ Overlay = overlay, SheetState = state })
	local root3 = layout(screen, 200)
	H.advance(0.3)
	H.fire(H.find(root3, "Scrim"), "Activated", H.input({}), 1)
	assert(h3.IsOpen:Get(), "veto: the scrim does not hide")
	h3.Close()
	assert(not h3.IsOpen:Get())
	H.advance(0.3)
	-- flags
	local h4 = Modal.open({ Overlay = overlay, DismissOnScrim = false, DismissOnEscape = false })
	local root4 = layout(screen, 200)
	H.advance(0.3)
	H.fire(H.find(root4, "Scrim"), "Activated", H.input({}), 1)
	key(Enum.KeyCode.Escape)
	assert(h4.IsOpen:Get(), "neither the scrim nor Escape close it")
	h4.Close()
	H.advance(0.3)
	assert(#overlay.Layer:GetChildren() == 0 and uisConns() == baseConns and beganConns() == baseBegan)
	q.dispose(screen)
	H.assertNoDebugOutput("modal drag")
end)

H.section("modal: layer death finalizes; nothing left behind", function()
	local overlay, screen = setup()
	local reasons = 0
	local handle = Modal.open({
		Overlay = overlay,
		OnClose = function()
			reasons += 1
		end,
	})
	layout(screen, 200)
	H.fire(sinkOf(H.find(screen, "BottomSheet")), "InputBegan", H.input({ Position = Vector3.new(200, 600, 0) }))
	q.dispose(screen)
	H.advance(1)
	assert(reasons == 1 and not handle.IsOpen:Get(), "OnClose once")
	assert(uisConns() == baseConns and beganConns() == baseBegan and H.pendingTimers() == 0, "connections and timers released")
	assert(handle.SheetState.CurrentValue:Get() == "Hidden")
	H.assertNoDebugOutput("layer death")
end)

H.done()
