--!strict
-- Review 2026-10-12 (triage): one section per class-A fix. Each section FAILS on the unpatched source.
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Frame = q.Elem "Frame"
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
		Content = q.Slot<<Instance>>({ Frame { Name = "Page" } }),
	})
end
local function sheet(state: any, contentH: number): (any, any)
	local host: any = BottomSheet.BottomSheetScaffold({ SheetState = state, SheetContent = q.Slot<<Instance>>({ Frame { Name = "Row" } }) })
	local screen = Frame { host }
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
	local _screen = Frame { s }
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
	local _screen = Frame { host }
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

-- Review 2026-10-13 (triage 2): one section per class-A fix. Each section FAILS on the unpatched source.
local Overlay = require("../src/Overlay")
local Menu = require("../src/Menu")
local Select = require("../src/Select")
local Dialog = require("../src/Dialog")
local Snackbar = require("../src/Snackbar")
local DatePicker = require("../src/DatePicker")
local Calendar = require("../src/DatePicker/Calendar")
local TimePicker = require("../src/TimePicker")
local Clock = require("../src/TimePicker/Clock")
local Switch = require("../src/Switch")
local ColorPicker = require("../src/ColorPicker")

local function named(root: any, name: string): { any }
	return H.findAll(root, function(c: any)
		return c.Name == name
	end)
end
local function click(inst: any)
	H.fire(inst, "Activated", H.input({}), 1)
end
local function buttonByLabel(root: any, text: string): any
	for _, b in named(root, "Button") do
		if (H.find(b, "Label") :: any).Text == text then
			return b
		end
	end
	error("no button " .. text)
end
local function overlayRig(): (any, any)
	local overlay = Overlay.new()
	local screen = Frame { overlay.Layer }
	H.setAbs(overlay.Layer, 0, 0, 800, 600)
	return overlay, screen
end

H.section("R1 closing phase: a second tap on a menu item / Select option within the exit time does nothing", function()
	local overlay, screen = overlayRig()
	local anchor: any = Frame { Name = "Anchor" }
	H.setAbs(anchor, 100, 50, 200, 56)
	local clicks, closes = 0, 0
	local handle = Menu.open({
		Anchor = anchor,
		Overlay = overlay,
		Items = { { Label = "Delete", OnClick = function()
			clicks += 1
		end } },
		OnClose = function()
			closes += 1
		end,
	})
	local item: any = H.find(screen, "Item")
	click(item)
	H.advance(0.03)
	assert(handle.Closing:Get() and not H.isDestroyed(item), "the row is still mounted while the menu animates out")
	click(item)
	assert(clicks == 1, `OnClick ran {clicks} times for a double tap`)
	assert(closes == 1)
	H.advance(0.5)
	assert(overlay.Count:Get() == 0)
	-- dismissed by the scrim, then a tap on a row during the exit: the menu was dismissed, the item does nothing
	Menu.open({ Anchor = anchor, Overlay = overlay, Items = { { Label = "Delete", OnClick = function()
		clicks += 1
	end } } })
	click(H.find(screen, "Scrim"))
	click(H.find(screen, "Item"))
	assert(clicks == 1, "an item of a dismissed menu does nothing")
	H.advance(0.5)
	-- Select: OnChange once
	local value = q.Source(nil :: string?)
	local changes = 0
	local field: any = Select({ Label = "F", Options = { "A", "B" }, Value = value, Overlay = overlay, OnChange = function()
		changes += 1
	end })
	local container: any = H.find(field, "Container")
	H.setAbs(container, 50, 20, 240, 56)
	H.fire(container, "InputBegan", H.input({}))
	H.fire(container, "InputEnded", H.input({}))
	local options = named(screen, "Item")
	assert(#options == 2, `the select menu opened ({#options} items)`)
	click(options[1])
	click(options[2])
	assert(value:Get() == "A" and changes == 1, `Select: value {value:Get()}, OnChange {changes}`)
	H.advance(0.5)
	q.dispose(field)
	q.dispose(screen)
	H.advance(0.5)
end)

H.section("R1 closing phase: OK of a date / time modal commits once; OK after Cancel does not commit", function()
	local overlay, screen = overlayRig()
	local value = q.Source(nil :: any)
	local confirms, cancels = 0, 0
	DatePicker.Modal.open({ Overlay = overlay, Value = value, Today = Calendar.date(2026, 10, 5), OnConfirm = function()
		confirms += 1
	end })
	local card: any = H.find(screen, "DatePickerModal")
	local cells = named(card, "Day")
	click(cells[25])
	local first = value:Get()
	local ok = buttonByLabel(card, "OK")
	click(ok)
	local picked = value:Get()
	assert(confirms == 1 and picked ~= nil and first == nil)
	H.advance(0.05)
	click(ok)
	click(cells[26])
	click(ok)
	assert(confirms == 1, `OnConfirm ran {confirms} times`)
	assert(Calendar.equals(value:Get(), picked), "a pick made while the card animates out is not committed")
	H.advance(0.5)
	-- Cancel, then OK within the exit time
	local value2 = q.Source(Calendar.date(2026, 10, 7) :: any)
	confirms = 0
	DatePicker.Modal.open({ Overlay = overlay, Value = value2, Today = Calendar.date(2026, 10, 5), OnConfirm = function()
		confirms += 1
	end, OnCancel = function()
		cancels += 1
	end })
	local card2: any = H.find(screen, "DatePickerModal")
	click(named(card2, "Day")[20])
	click(buttonByLabel(card2, "Cancel"))
	click(buttonByLabel(card2, "OK"))
	assert(cancels == 1 and confirms == 0, `cancelled: OnCancel {cancels}, OnConfirm {confirms}`)
	assert(Calendar.equals(value2:Get(), Calendar.date(2026, 10, 7)), "a cancelled picker leaves the value")
	H.advance(0.5)
	-- time picker
	local time = q.Source(Clock.time(8, 15))
	local tConfirms, tCancels = 0, 0
	TimePicker.Modal.open({ Overlay = overlay, Value = time, OnConfirm = function()
		tConfirms += 1
	end, OnCancel = function()
		tCancels += 1
	end })
	local tcard: any = H.find(screen, "TimePickerModal")
	local tok = buttonByLabel(tcard, "OK")
	click(tok)
	click(tok)
	assert(tConfirms == 1, `time OnConfirm ran {tConfirms} times`)
	H.advance(0.5)
	TimePicker.Modal.open({ Overlay = overlay, Value = time, OnConfirm = function()
		tConfirms += 1
	end, OnCancel = function()
		tCancels += 1
	end })
	local tcard2: any = H.find(screen, "TimePickerModal")
	click(buttonByLabel(tcard2, "Cancel"))
	click(buttonByLabel(tcard2, "OK"))
	assert(tConfirms == 1 and tCancels == 1, `time: cancelled then OK -> confirms {tConfirms}, cancels {tCancels}`)
	H.advance(0.5)
	q.dispose(screen)
	H.advance(0.5)
end)

H.section("R1 closing phase: a dialog action / a snackbar action runs once for a double tap", function()
	local overlay, screen = overlayRig()
	local discards = 0
	local results: { any } = {}
	Dialog.open({
		Overlay = overlay,
		Headline = "Discard?",
		Actions = {
			{ Label = "Cancel", Result = false },
			{ Label = "Discard", Result = true, OnClick = function()
				discards += 1
			end },
		},
		OnClose = function(r: unknown?)
			table.insert(results, r)
		end,
	})
	local discard = buttonByLabel(screen, "Discard")
	click(discard)
	click(discard)
	assert(discards == 1 and #results == 1 and results[1] == true, `Discard ran {discards} times`)
	H.advance(0.5)
	Dialog.open({
		Overlay = overlay,
		Headline = "Discard?",
		Actions = {
			{ Label = "Cancel", Result = false },
			{ Label = "Discard", Result = true, OnClick = function()
				discards += 1
			end },
		},
	})
	click(buttonByLabel(screen, "Cancel"))
	click(buttonByLabel(screen, "Discard"))
	assert(discards == 1, "Cancel, then Discard while the card animates out: Discard does nothing")
	H.advance(0.5)
	local bar = Snackbar.new({ Overlay = overlay })
	local undone = 0
	bar:Show({ Text = "Archived", Duration = math.huge, Action = { Label = "Undo", OnClick = function()
		undone += 1
	end } })
	local act: any = H.find(H.find(screen, "Snackbar"), "Action")
	click(act)
	click(act)
	assert(undone == 1, `Undo ran {undone} times`)
	H.advance(0.5)
	q.dispose(screen)
	H.advance(0.5)
end)

H.section("R2 Menu: the anchor being destroyed closes the menu (and the Select's)", function()
	local overlay, screen = overlayRig()
	local anchor: any = Frame { Name = "Anchor" }
	H.setAbs(anchor, 100, 50, 200, 56)
	local reasons: { string } = {}
	local handle = Menu.open({ Anchor = anchor, Overlay = overlay, Items = { { Label = "A" } }, OnClose = function(reason: string)
		table.insert(reasons, reason)
	end })
	assert(overlay.Count:Get() == 1)
	q.dispose(anchor)
	assert(handle.IsOpen:Get() == false and #reasons == 1, "the menu closes with its anchor")
	H.advance(0.5)
	assert(overlay.Count:Get() == 0 and H.find(screen, "Scrim") == nil, "no scrim left to swallow clicks")
	-- a menu closed normally drops the anchor connection: destroying the anchor later is silent
	local anchor2: any = Frame { Name = "Anchor" }
	H.setAbs(anchor2, 100, 50, 200, 56)
	local closes = 0
	local h2 = Menu.open({ Anchor = anchor2, Overlay = overlay, Items = { { Label = "A" } }, OnClose = function()
		closes += 1
	end })
	h2.Close()
	H.advance(0.5)
	q.dispose(anchor2)
	assert(closes == 1)
	local field: any = Select({ Label = "F", Options = { "A", "B" }, Value = q.Source(nil :: string?), Overlay = overlay })
	local holder = Frame { field }
	local container: any = H.find(field, "Container")
	H.setAbs(container, 50, 20, 240, 56)
	H.fire(container, "InputBegan", H.input({}))
	H.fire(container, "InputEnded", H.input({}))
	assert(overlay.Count:Get() == 1, "select menu open")
	q.dispose(holder)
	H.advance(0.5)
	assert(overlay.Count:Get() == 0, "the select's menu went with the field")
	q.dispose(screen)
	H.advance(0.5)
end)

H.section("R3 Disabled set during a drag: a Switch release and the color areas write nothing", function()
	local value, disabled = q.Source(false), q.Source(false)
	local changes = 0
	local sw: any = Switch({ Value = value, Disabled = disabled, OnChange = function()
		changes += 1
	end })
	local root = Frame { sw }
	H.fire(sw, "InputBegan", H.input({ Position = Vector3.new(100, 10, 0) }))
	mouseMove(105, 10)
	mouseMove(135, 10)
	disabled:Set(true)
	mouseUp(135, 10)
	assert(value:Get() == false and changes == 0, `switch: value {value:Get()}, OnChange {changes}`)
	q.dispose(root)
	-- the same drag without Disabled still switches
	local v2 = q.Source(false)
	local sw2: any = Switch({ Value = v2 })
	local root2 = Frame { sw2 }
	H.fire(sw2, "InputBegan", H.input({ Position = Vector3.new(100, 10, 0) }))
	mouseMove(105, 10)
	mouseMove(135, 10)
	mouseUp(135, 10)
	assert(v2:Get() == true, "an enabled drag past the half switches")
	q.dispose(root2)
	H.advance(0.5)

	local color, off = q.Source(Color3.fromRGB(235, 153, 255)), q.Source(false)
	local colorChanges = 0
	local panel: any = ColorPicker.Panel({ Value = color, Disabled = off, Recent = q.Source({} :: { Color3 }), OnChange = function()
		colorChanges += 1
	end })
	local area: any, hue: any = H.find(panel, "SVArea"), H.find(panel, "HueSlider")
	H.setAbs(panel, 80, 40, 340, 500)
	H.setAbs(area, 100, 50, 300, 160)
	H.setAbs(hue, 100, 230, 300, 40)
	H.fire(area, "InputBegan", H.input({ Position = Vector3.new(150, 100, 0) }))
	mouseMove(200, 120)
	local n = colorChanges
	assert(n >= 1, "the drag writes while enabled")
	local at = color:Get()
	off:Set(true)
	mouseMove(300, 180)
	mouseUp(320, 190)
	assert(color:Get() == at and colorChanges == n, "SV area: disabled mid-drag, the color stays")
	off:Set(false)
	H.fire(hue, "InputBegan", H.input({ Position = Vector3.new(150, 250, 0) }))
	mouseMove(200, 250)
	at, n = color:Get(), colorChanges
	off:Set(true)
	mouseMove(350, 250)
	mouseUp(360, 250)
	assert(color:Get() == at and colorChanges == n, "hue slider: disabled mid-drag, the color stays")
	q.dispose(panel)
	H.advance(0.5)
end)

H.section("R4 ColorPicker channel boxes: a typed edit is remembered at blur; a rejected text remembers nothing", function()
	local color, recent = q.Source(Color3.fromRGB(235, 153, 255)), q.Source({} :: { Color3 })
	local panel: any = ColorPicker.Panel({ Value = color, Recent = recent })
	local g: any = H.find(panel, "Channel2")
	local function edit(text: string)
		H.fire(g, "Focused")
		g.Text = text
		H.fire(g, "FocusLost", false)
	end
	edit("abc")
	assert(#recent:Get() == 0, "a rejected text changed nothing: nothing to remember")
	H.fire(g, "Focused")
	H.fire(g, "FocusLost", false)
	assert(#recent:Get() == 0, "focus alone remembers nothing")
	edit("10")
	assert(#recent:Get() == 1 and math.abs(recent:Get()[1].G * 255 - 10) < 1e-3, `a typed channel is remembered ({#recent:Get()})`)
	-- typed live, then left with a text that does not parse: the color DID change during the edit
	H.fire(g, "Focused")
	g.Text = "77"
	g.Text = ""
	H.fire(g, "FocusLost", false)
	assert(#recent:Get() == 2 and math.abs(recent:Get()[1].G * 255 - 77) < 1e-3, "a live commit is remembered whatever the last text was")
	q.dispose(panel)
	H.advance(0.5)
end)

H.section("R5 DatePicker keys: Home / End stop at the selectable day nearest to the row end", function()
	local GuiService: any = H.GuiService
	local value = q.Source(nil :: any)
	-- weekends disabled, Sunday first: the row of Wed Oct 14 2026 is Sun 11 (disabled) .. Sat 17 (disabled)
	local picker: any = DatePicker.Docked({ Value = value, Today = Calendar.date(2026, 10, 14), IsDisabled = function(d: any): boolean
		local w = Calendar.weekday(d)
		return w == 0 or w == 6
	end })
	local root = Frame { picker }
	local function focusOn(day: number)
		for _, c in named(picker, "Day") do
			if c.Text == tostring(day) and c.Visible then
				GuiService.SelectedObject = c
				H.fire(c, "SelectionGained")
				return
			end
		end
		error("no day " .. day)
	end
	local function key(code: EnumItem)
		UIS.InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = code }), false)
	end
	local function selected(): string
		local s = GuiService.SelectedObject
		return if s ~= nil then s.Text else "nil"
	end
	focusOn(14)
	key(Enum.KeyCode.Home)
	assert(selected() == "12", `Home from Wed 14 with Sun 11 disabled -> Mon 12 (got {selected()})`)
	key(Enum.KeyCode.Home)
	assert(selected() == "12", "Home again stays")
	key(Enum.KeyCode.End)
	assert(selected() == "16", `End -> Fri 16 (got {selected()})`)
	key(Enum.KeyCode.End)
	assert(selected() == "16", "End again stays")
	H.fire(GuiService.SelectedObject, "SelectionLost")
	GuiService.SelectedObject = nil
	q.dispose(root)
	H.advance(0.5)
end)

H.done()
