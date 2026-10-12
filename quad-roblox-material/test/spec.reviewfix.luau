--!strict
-- Review 2026-10-12 (triage): one section per class-A fix. Each section FAILS on the unpatched source.
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Anchored = require("../src/Sheet/Anchored")
local SheetStateModule = require("../src/Sheet/State")
local BottomSheet = require("../src/BottomSheet")
local Nav = require("../src/NavigationDrawer")
local Rail = require("../src/NavigationRail")
local Slider = require("../src/Slider")
local RangeSlider = require("../src/Slider/Range")
local SplitButton = require("../src/Button/Split")
local UIS = H.UserInputService
Anchored.clock = H.now

local function sinkOf(holder: any): any
	for _, c in holder:GetChildren() do
		if c.Name == "ClickSink" then
			return c
		end
	end
	error("no ClickSink")
end
local function mouseMove(x: number, y: number)
	UIS.InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(x, y, 0) }))
end
local function mouseUp(x: number, y: number)
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(x, y, 0) }))
end
local function drawer(state: any): any
	return Nav.ModalNavigationDrawer({
		DrawerState = state,
		DrawerContent = Nav.ModalDrawerSheet({ Children = q.Slot<<Instance>>({}) }),
		Content = q.Slot<<Instance>>({ D.Frame { Name = "Page" } }),
	})
end
local function sheet(state: any, contentH: number): (any, any)
	local host: any = BottomSheet.BottomSheetScaffold({ SheetState = state, SheetContent = q.Slot<<Instance>>({ D.Frame { Name = "Row" } }) })
	local screen = D.Frame { host }
	local s: any = H.find(host, "BottomSheet")
	H.setAbs(host, 0, 0, 400, 800)
	H.setAbs(H.find(s, "Content"), 0, 0, 400, contentH)
	H.finishTweens()
	return screen, s
end

H.section("A1 Slide: a second finger on another hook does not move or end the first finger's drag", function()
	local state = Nav.DrawerState({ InitialValue = "Open" })
	local host: any = drawer(state)
	local d: any, scrim: any = H.find(host, "Drawer"), H.find(host, "Scrim")
	local a: any = H.input({ UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(300, 300, 0) })
	H.fire(sinkOf(d), "InputBegan", a)
	H.advance(0.05)
	a.Position = Vector3.new(200, 300, 0)
	UIS.InputChanged:Fire(a)
	assert(d.Position.X.Offset == -100, "A drags the drawer 100 px")
	local b: any = H.input({ UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(1000, 300, 0) })
	H.fire(scrim, "InputBegan", b)
	b.Position = Vector3.new(900, 300, 0)
	UIS.InputChanged:Fire(b)
	assert(d.Position.X.Offset == -100, "B's move does not move A's drag")
	UIS.InputEnded:Fire(b)
	H.finishTweens()
	assert(d.Position.X.Offset == -100, `B's lift does not end A's drag (got {d.Position.X.Offset})`)
	a.Position = Vector3.new(100, 300, 0)
	UIS.InputChanged:Fire(a)
	assert(d.Position.X.Offset == -200, "A still drags")
	UIS.InputEnded:Fire(a)
	H.advance(0.5)
	H.finishTweens()
	q.dispose(host)
	H.advance(0.5)
end)

H.section("A2 Slide: a drawer destroyed mid-drag does not write the state another drawer took over", function()
	local state = Nav.DrawerState({ InitialValue = "Open" })
	local h1: any = drawer(state)
	H.fire(sinkOf(H.find(h1, "Drawer")), "InputBegan", H.input({ Position = Vector3.new(300, 300, 0) }))
	H.advance(0.05)
	mouseMove(0, 300)
	local h2: any = drawer(state) -- the rebuilt drawer takes the state over (a Slot:Single builds new before it removes old)
	q.dispose(h1)
	H.advance(0.5)
	assert(state.TargetValue:Get() == "Open" and state.CurrentValue:Get() == "Open", `target {state.TargetValue:Get()} / current {state.CurrentValue:Get()}`)
	q.dispose(h2)
	-- without a takeover: destroying mid-drag leaves the value alone too
	local state2 = Nav.DrawerState({ InitialValue = "Open" })
	local h3: any = drawer(state2)
	H.fire(sinkOf(H.find(h3, "Drawer")), "InputBegan", H.input({ Position = Vector3.new(300, 300, 0) }))
	H.advance(0.05)
	mouseMove(0, 300)
	q.dispose(h3)
	H.advance(0.5)
	assert(state2.TargetValue:Get() == "Open" and state2.CurrentValue:Get() == "Open", "destroyed mid-drag: the state keeps its value")
end)

H.section("A3 Slide: a relayout during a motion re-aims the tween AND its settle (Current follows the new end)", function()
	local state = SheetStateModule.SheetState({ InitialValue = "PartiallyExpanded", EnabledValues = { "PartiallyExpanded", "Expanded" } })
	local screen, s = sheet(state, 200)
	state.Expand()
	H.advance(0.15)
	H.setAbs(H.find(s, "Content"), 0, 0, 400, 300) -- the content grows mid-motion: a fresh 0.2 s tween starts at 0.15
	H.advance(0.06)
	assert(state.CurrentValue:Get() == "PartiallyExpanded", "at 0.21 the re-aimed motion (ends at 0.35) has not settled")
	H.advance(0.15)
	assert(state.CurrentValue:Get() == "Expanded", "settled when the re-aimed motion ends")
	H.finishTweens()
	q.dispose(screen)
end)

H.section("A4 Slide: a request during a drag does not settle Current while the finger is down", function()
	local state = SheetStateModule.SheetState({ InitialValue = "Expanded", EnabledValues = { "PartiallyExpanded", "Expanded" } })
	local screen, s = sheet(state, 400)
	H.fire(sinkOf(s), "InputBegan", H.input({ Position = Vector3.new(200, 500, 0) }))
	H.advance(0.05)
	mouseMove(200, 520)
	state.PartialExpand()
	H.advance(0.5)
	assert(state.CurrentValue:Get() == "Expanded", `finger down: Current stays (got {state.CurrentValue:Get()})`)
	mouseUp(200, 520)
	H.advance(0.5)
	assert(state.TargetValue:Get() == "Expanded" and state.CurrentValue:Get() == "Expanded", "the release settles")
	H.finishTweens()
	q.dispose(screen)
end)

H.section("A5 WideNavigationRailState: with its rail gone a request settles at once again", function()
	local state = Rail.WideNavigationRailState()
	local items: any = { { Key = "a", Label = "A" }, { Key = "b", Label = "B" } }
	local r1: any = Rail.WideNavigationRail<<string>>({ Items = items, Selected = q.Source("a"), State = state })
	local r2: any = Rail.WideNavigationRail<<string>>({ Items = items, Selected = q.Source("a"), State = state }) -- a rebuild: new before old
	q.dispose(r1)
	state.Expand()
	assert(state.CurrentValue:Get() == "Collapsed", "a rail still shows the state: Current waits for its motion")
	H.advance(0.1)
	q.dispose(r2) -- destroyed mid-motion
	assert(state.CurrentValue:Get() == "Expanded", "the last rail died mid-motion: the state settles at its target")
	state.Collapse()
	assert(state.CurrentValue:Get() == "Collapsed", "no rail: settles at once")
end)

H.section("A6 Slider: the default Format never ends in a bare point", function()
	local v = q.Source(0)
	local s: any = Slider({ Value = v, ShowLabel = true })
	local _screen = D.Frame { s }
	local label: any = H.find(s, "Label")
	local function text(x: number): string
		v:Set(x)
		return label.Text
	end
	assert(text(0.004) == "0", text(0.004))
	assert(text(0.996) == "1", text(0.996))
	assert(text(0.5) == "0.5" and text(0.25) == "0.25" and text(0.3) == "0.3", "short decimals")
	assert(text(-0.001) == "0", text(-0.001))
end)

H.section("A7 Slider / RangeSlider: Disabled set during a drag stops the drag's writes", function()
	local dis = q.Source(false)
	local v = q.Source(0)
	local s: any = Slider({ Value = v, Disabled = dis })
	H.setAbs(s, 104, 50, 212, 44)
	H.fire(s, "InputBegan", H.input({ Position = Vector3.new(210, 60, 0) }))
	local at = v:Get()
	assert(at > 0, "the press wrote")
	dis:Set(true)
	mouseMove(260, 60)
	mouseUp(260, 60)
	assert(v:Get() == at, `disabled mid-drag: the value stays (got {v:Get()})`)
	local dis2 = q.Source(false)
	local a, b = q.Source(0), q.Source(1)
	local r: any = RangeSlider({ Start = a, End = b, Disabled = dis2 })
	H.setAbs(r, 104, 50, 212, 44)
	H.fire(r, "InputBegan", H.input({ Position = Vector3.new(150, 60, 0) }))
	local at2 = a:Get()
	dis2:Set(true)
	mouseMove(200, 60)
	mouseUp(200, 60)
	assert(a:Get() == at2, "range: disabled mid-drag keeps the value")
end)

H.section("C1 SplitButton: the first layout places the content without a tween; a press still animates the optical shift", function()
	local host: any = SplitButton({ Label = "Save" })
	local _screen = D.Frame { host }
	local trailing: any = H.find(host, "Trailing")
	local lc: any, tc: any = H.find(H.find(host, "Leading"), "Content"), H.find(trailing, "Content")
	H.mock.resetTweenLog()
	H.setAbs(lc, 0, 0, 68, 40)
	H.setAbs(tc, 0, 0, 48, 40)
	for _, e in H.tweenLog() do
		assert(e.inst ~= lc and e.inst ~= tc, "no Position tween at the first layout")
	end
	assert(lc.Position == UDim2.fromOffset(0, 0) and tc.Position == UDim2.fromOffset(-2, 0), `placed: {lc.Position} / {tc.Position}`)
	H.mock.resetTweenLog()
	H.fire(trailing, "InputBegan", H.input({ Position = Vector3.new(80, 20, 0) }))
	local animated = false
	for _, e in H.tweenLog() do
		if e.inst == tc and e.props.Position ~= nil then
			animated = true
		end
	end
	assert(animated, "pressed: the optical shift (-2 -> -1) animates")
	UIS.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(80, 20, 0) }))
	H.fire(trailing, "InputEnded", H.input({ Position = Vector3.new(80, 20, 0) }))
	H.finishTweens()
	H.advance(1)
end)

H.done()
