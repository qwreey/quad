--!strict
-- Cross-component API conventions (src/init.luau "API CONVENTIONS"): controlled Checked form, `Hooks` on every host,
-- ONE handle shape for everything that is opened, `Label` / `Disabled` State / `OnChange` / `Selected` naming.
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local D = q.Declaration
local Util = require("../src/Util")
local Overlay = require("../src/Overlay")
local Button = require("../src/Button")
local IconButton = require("../src/Button/IconButton")
local FAB = require("../src/Button/FAB")
local Checkbox = require("../src/Checkbox")
local Switch = require("../src/Switch")
local RadioModule = require("../src/Radio")
local Slider = require("../src/Slider")
local RangeSlider = require("../src/Slider/Range")
local M2 = require("../src/M2")
local TextField = require("../src/TextField")
local Select = require("../src/Select")
local Menu = require("../src/Menu")
local Card = require("../src/Card")
local Divider = require("../src/Divider")
local ListModule = require("../src/List")
local Dialog = require("../src/Dialog")
local Snackbar = require("../src/Snackbar")
local Tooltip = require("../src/Tooltip")
local Chip = require("../src/Chip")
local Tabs = require("../src/Tabs")
local Progress = require("../src/Progress")
local DatePicker = require("../src/DatePicker")
local ColorPicker = require("../src/ColorPicker")

local Calendar = DatePicker.Calendar

-- ── controlled Checked form ─────────────────────────────────────────────────
H.section("Checkbox / Switch `Checked`: displayed only, a click calls OnChange and writes nothing; Value + Checked errors", function()
	for _, which in { "Checkbox", "Switch" } do
		local make = function(props: any): any
			return if which == "Checkbox" then Checkbox(props) else Switch(props)
		end
		local owner = q.Source(false)
		local calls: { boolean } = {}
		local c = make({
			Checked = owner,
			OnChange = function(v: boolean)
				table.insert(calls, v)
			end,
		})
		H.fire(c, "Activated", H.input({}), 1)
		assert(#calls == 1 and calls[1] == true, which .. ": the click reports the NEW value")
		assert(owner:Get() == false, which .. ": nothing was written")
		H.finishTweens()
		local track = if which == "Checkbox" then H.find(c, "Box").BackgroundTransparency else c.BackgroundColor3
		-- the owner decides: write it, and the control follows
		owner:Set(true)
		H.advance(0.4) -- the Checkbox toggle motion swaps its look at the midpoint (Heartbeat)
		H.finishTweens()
		local trackOn = if which == "Checkbox" then H.find(c, "Box").BackgroundTransparency else c.BackgroundColor3
		assert(trackOn ~= track, which .. ": follows the State")
		H.fire(c, "Activated", H.input({}), 1)
		assert(calls[2] == false, which .. ": from true the next click reports false")
		assert(not pcall(make, { Value = q.Source(false), Checked = owner }), which .. ": both forms is an error")
		-- a State derived from something else (the Gallery's theme switch)
		local derived: Q.State<boolean> = owner:Compute(function(self)
			return not self:Get()
		end)
		local d = make({ Checked = derived })
		H.fire(d, "Activated", H.input({}), 1) -- no OnChange: harmless
		q.dispose(c)
		q.dispose(d)
	end
	H.assertNoDebugOutput("controlled")
end)

-- ── Hooks on every host ─────────────────────────────────────────────────────
H.section("every host component takes `Hooks` (array-part values) and the hook sees the returned host", function()
	local checked = 0
	local function probe(name: string, build: (hooks: Util.Hooks) -> any)
		local seen: { any } = {}
		local hooks: Util.Hooks = {
			Util.preHook(function(inst: GuiObject)
				table.insert(seen, inst)
			end),
		}
		local host = build(hooks)
		assert(seen[1] == host, name .. ": Hooks reached the host (saw " .. #seen .. ")")
		checked += 1
		q.dispose(host)
	end
	local TODAY = Calendar.date(2026, 2, 10)
	probe("Button", function(h) return Button({ Label = "x", Hooks = h }) end)
	probe("IconButton", function(h) return IconButton({ Icon = "rbxassetid://1", Hooks = h }) end)
	probe("FAB", function(h) return FAB({ Icon = "rbxassetid://1", Hooks = h }) end)
	probe("Checkbox", function(h) return Checkbox({ Hooks = h }) end)
	probe("Switch", function(h) return Switch({ Hooks = h }) end)
	probe("Radio", function(h) return RadioModule.Radio<<string>>({ Value = q.Source("a") :: any, Option = "a", Hooks = h }) end)
	probe("RadioGroup", function(h)
		return RadioModule.RadioGroup<<string>>({ Value = q.Source("a") :: any, Options = { { Option = "a", Label = "A" } }, Hooks = h })
	end)
	probe("Slider", function(h) return Slider({ Hooks = h }) end)
	probe("RangeSlider", function(h) return RangeSlider({ Hooks = h }) end)
	probe("M2.Slider", function(h) return M2.Slider({ Hooks = h }) end)
	probe("M2.RangeSlider", function(h) return M2.RangeSlider({ Hooks = h }) end)
	probe("M2.Switch", function(h) return M2.Switch({ Hooks = h }) end)
	probe("TextField", function(h) return TextField({ Label = "x", Hooks = h }) end)
	probe("Select", function(h) return Select<<string>>({ Options = { "a" }, Value = q.Source(nil :: string?), Hooks = h }) end)
	probe("Menu.Button", function(h) return Menu.Button({ Label = "m", Items = { "divider" }, Hooks = h }) end)
	probe("Card", function(h) return Card({ Hooks = h }) end)
	probe("Card (interactive)", function(h) return Card({ OnClick = function() end, Hooks = h }) end)
	probe("Divider", function(h) return Divider({ Hooks = h }) end)
	probe("Divider (inset)", function(h) return Divider({ Inset = "Start", Hooks = h }) end)
	probe("List", function(h) return ListModule.List({ Hooks = h }) end)
	probe("ListData", function(h)
		return ListModule.ListData<<number>>({
			Items = q.Source({ 1 }),
			Key = function(n: number) return n end,
			Render = function(item: Q.State<number>) return D.Frame {} end,
			Hooks = h,
		})
	end)
	probe("ListItem", function(h) return ListModule.ListItem({ Headline = "x", Hooks = h }) end)
	probe("ListItem (interactive)", function(h) return ListModule.ListItem({ Headline = "x", OnClick = function() end, Hooks = h }) end)
	probe("Chip.Assist", function(h) return Chip.Assist({ Label = "x", Hooks = h }) end)
	probe("Chip.Filter", function(h) return Chip.Filter({ Label = "x", Selected = q.Source(false), Hooks = h }) end)
	probe("Chip.Input", function(h) return Chip.Input({ Label = "x", Hooks = h }) end)
	probe("Chip.Suggestion", function(h) return Chip.Suggestion({ Label = "x", Hooks = h }) end)
	probe("ChipSet", function(h)
		return Chip.ChipSet<<number>>({
			Items = q.Source({ 1 }),
			Key = function(n: number) return n end,
			Render = function() return D.Frame {} end,
			Hooks = h,
		})
	end)
	probe("Tabs", function(h) return Tabs<<string>>({ Selected = q.Source("a"), Tabs = { { Key = "a", Label = "A" } }, Hooks = h }) end)
	probe("LinearProgress", function(h) return Progress.LinearProgress({ Value = 0.5, Hooks = h }) end)
	probe("LinearProgress (indeterminate)", function(h) return Progress.LinearProgress({ Hooks = h }) end)
	probe("CircularProgress", function(h) return Progress.CircularProgress({ Value = 0.5, Hooks = h }) end)
	probe("CircularProgress (indeterminate)", function(h) return Progress.CircularProgress({ Hooks = h }) end)
	probe("LoadingIndicator", function(h) return Progress.LoadingIndicator({ Hooks = h }) end)
	probe("WavyProgress", function(h) return Progress.WavyProgress({ Value = 0.5, Hooks = h }) end)
	probe("DatePicker.Docked", function(h) return DatePicker.Docked({ Value = q.Source(nil :: DatePicker.Date?), Today = TODAY, Hooks = h }) end)
	probe("DatePicker.RangeDocked", function(h)
		return DatePicker.RangeDocked({ Start = q.Source(nil :: DatePicker.Date?), End = q.Source(nil :: DatePicker.Date?), Today = TODAY, Hooks = h })
	end)
	probe("ColorPicker.Panel", function(h) return ColorPicker.Panel({ Hooks = h }) end)
	probe("ColorPicker.Classic", function(h) return ColorPicker.Classic({ Hooks = h }) end)
	probe("Tooltip.Plain", function(h) return Tooltip.Plain({ Text = "t", Hooks = h }) end)
	assert(checked == 40, "probed " .. checked)
	H.assertNoDebugOutput("hooks")
end)

-- ── one handle shape ────────────────────────────────────────────────────────
H.section("every opened thing returns closures without self: Close(result?) + IsOpen State", function()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	H.setAbs(overlay.Layer, 0, 0, 800, 600)
	local anchor = D.Frame {}
	H.setAbs(anchor, 100, 50, 200, 56)
	local bar = Snackbar.new({ Overlay = overlay })
	local tipTarget = D.Frame { Name = "TipTarget" }
	local tip = Tooltip.hook({ Text = "t", Overlay = overlay })
	local tipHost = D.TextButton { tip.Hook }
	H.fire(tipHost, "MouseEnter")
	H.advance(1)
	local handles: { [string]: any } = {
		Overlay = overlay:Open({ Content = D.Frame {}, ExitTime = 0 }),
		Menu = Menu.open({ Anchor = anchor, Items = { { Label = "a" } }, Overlay = overlay }),
		Dialog = Dialog.open({ Headline = "x", Overlay = overlay }),
		DatePickerModal = DatePicker.Modal.open({ Overlay = overlay }),
		ColorPickerModal = ColorPicker.Modal.open({ Overlay = overlay }),
		Snackbar = bar:Show({ Text = "hi" }),
		Tooltip = tip,
	}
	local n = 0
	for name, hnd in handles do
		n += 1
		assert(type(hnd.Close) == "function", name .. ": Close is a closure")
		assert(q.isState(hnd.IsOpen) and hnd.IsOpen:Get() == true, name .. ": IsOpen State is true while it is up")
		-- no self: `handle.Close(x)` — and calling it twice is harmless
		hnd.Close(nil)
		hnd.Close(nil)
		H.advance(0.5)
		assert(hnd.IsOpen:Get() == false, name .. ": IsOpen false after Close")
	end
	assert(n == 7)
	assert(handles.Snackbar.Dismiss ~= nil, "Snackbar keeps Dismiss as an alias")
	bar:Destroy()
	q.dispose(screen)
	q.dispose(tipHost)
	q.dispose(tipTarget)
	H.assertNoDebugOutput("handles")
end)

H.section("Dialog.Close(result) reports the result (unknown) and the Overlay hands it to OnClose", function()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	local got: { unknown } = {}
	local d = Dialog.open({
		Headline = "x",
		Overlay = overlay,
		DismissResult = "dismissed",
		OnClose = function(r: unknown?)
			table.insert(got, r)
		end,
	})
	d.Close({ picked = 3 })
	d.Close("again") -- first close wins
	assert(#got == 1 and (got[1] :: any).picked == 3 and (d.Result:Get() :: any).picked == 3)
	local seen: { unknown } = {}
	local h = overlay:Open({
		Content = D.Frame {},
		ExitTime = 0,
		OnClose = function(reason: string, result: unknown?)
			table.insert(seen, reason)
			table.insert(seen, result)
		end,
	})
	h.Close(42)
	assert(seen[1] == "Close" and seen[2] == 42, "Overlay passes the Close result to OnClose")
	q.dispose(screen)
	H.assertNoDebugOutput("dialog result")
end)

-- ── naming ──────────────────────────────────────────────────────────────────
H.section("Menu.Item: `Label`, `Disabled` as a State (skipped by keyboard navigation, no-op on activate)", function()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	H.setAbs(overlay.Layer, 0, 0, 800, 600)
	local anchor = D.Frame {}
	H.setAbs(anchor, 100, 50, 200, 56)
	local locked = q.Source(true)
	local log: { string } = {}
	local handle = Menu.open({
		Anchor = anchor,
		Overlay = overlay,
		Items = {
			{ Label = "First", OnClick = function() table.insert(log, "first") end },
			{ Label = "Locked", Disabled = locked, OnClick = function() table.insert(log, "locked") end },
			{ Label = "Last", OnClick = function() table.insert(log, "last") end },
		},
	})
	local items = H.findAll(screen, function(c: any)
		return c.Name == "Item"
	end)
	assert(#items == 3 and H.find(items[2], "Label").Text == "Locked")
	assert(items[2].Interactable == false, "the State drives Interactable")
	local function key(code: Enum.KeyCode)
		H.UserInputService.InputBegan:Fire(H.input({ KeyCode = code, UserInputType = Enum.UserInputType.Keyboard }), false)
	end
	H.fire(items[1], "SelectionGained")
	key(Enum.KeyCode.Down)
	assert(H.GuiService.SelectedObject == items[3], "Down skips the disabled item")
	locked:Set(false)
	assert(items[2].Interactable == true, "live: enabling it later works")
	key(Enum.KeyCode.Up)
	assert(H.GuiService.SelectedObject == items[2], "now reachable")
	locked:Set(true)
	H.fire(items[2], "Activated", H.input({}), 1)
	assert(#log == 0 and handle.IsOpen:Get(), "activating a disabled item does nothing")
	handle.Close()
	H.advance(0.5)
	H.GuiService.SelectedObject = nil
	q.dispose(screen)
	H.assertNoDebugOutput("menu disabled")
end)

H.section("RadioGroup option `Disabled` accepts a State (group OR option)", function()
	local pick = q.Source("a")
	local off = q.Source(false)
	local g = RadioModule.RadioGroup<<string>>({
		Value = pick :: any,
		Options = { { Option = "a", Label = "A" }, { Option = "b", Label = "B", Disabled = off } },
	})
	local radios = H.findAll(g, function(c: any)
		return c.Name == "Radio"
	end)
	assert(radios[2].Interactable == true)
	off:Set(true)
	assert(radios[2].Interactable == false, "the option State disables it live")
	H.fire(radios[2], "Activated", H.input({}), 1)
	assert(pick:Get() == "a")
	q.dispose(g)
	H.assertNoDebugOutput("radio group")
end)

H.section("OnChange: TextField (user edits only), Select (item click), Chip.Filter, Tabs, DatePicker.Docked", function()
	-- TextField
	local text = q.Source("")
	local edits: { string } = {}
	local tf = TextField({
		Value = text,
		MaxLength = 5,
		OnChange = function(s: string)
			table.insert(edits, s)
		end,
	})
	local input = H.find(tf, "Input")
	input.Text = "abc"
	assert(text:Get() == "abc" and edits[1] == "abc", "user edit: written and reported")
	text:Set("xyz") -- programmatic
	assert(#edits == 1, "a programmatic write is not a user edit")
	input.Text = "abcdefgh" -- over the limit: clipped, reported once
	assert(text:Get() == "abcde" and edits[2] == "abcde" and #edits == 2)
	input.Text = "abcdefgh" -- the same overflow again: nothing changed
	assert(#edits == 2, "no change, no report")
	q.dispose(tf)
	-- Select
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	H.setAbs(overlay.Layer, 0, 0, 800, 600)
	local choice = q.Source(nil :: string?)
	local picked: { string } = {}
	local sel = Select<<string>>({
		Options = { "Apple", "Pear" },
		Value = choice,
		Overlay = overlay,
		OnChange = function(o: string)
			table.insert(picked, o)
		end,
	})
	local root = D.Frame { sel }
	H.setAbs(H.find(sel, "Container"), 100, 50, 200, 56)
	H.fire(H.find(sel, "Container"), "InputBegan", H.input({ UserInputType = Enum.UserInputType.MouseButton1 }))
	H.fire(H.find(sel, "Container"), "InputEnded", H.input({ UserInputType = Enum.UserInputType.MouseButton1 }))
	local opts = H.findAll(screen, function(c: any)
		return c.Name == "Item"
	end)
	assert(#opts == 2, "the menu opened with both options: " .. #opts)
	H.fire(opts[2], "Activated", H.input({}), 1)
	assert(choice:Get() == "Pear" and picked[1] == "Pear", "Select OnChange after the item click")
	choice:Set("Apple")
	assert(#picked == 1, "programmatic Value writes do not report")
	H.advance(0.5)
	q.dispose(root)
	q.dispose(screen)
	-- Chip.Filter
	local on = q.Source(false)
	local toggles: { boolean } = {}
	local chip = Chip.Filter({
		Label = "x",
		Selected = on,
		OnChange = function(v: boolean)
			table.insert(toggles, v)
		end,
	})
	H.fire(chip, "Activated", H.input({}), 1)
	assert(on:Get() == true and toggles[1] == true)
	q.dispose(chip)
	-- Tabs: inline literal, OnChange, TabsState
	local page = q.Source("a")
	local pages: { string } = {}
	local tabs = Tabs<<string>>({
		Selected = page,
		Tabs = { { Key = "a", Label = "Alpha" }, { Key = "b", Label = "Beta" } },
		OnChange = function(k: string)
			table.insert(pages, k)
		end,
	})
	local buttons = H.findAll(tabs, function(c: any)
		return c.Name == "Tab"
	end)
	assert(H.find(buttons[2], "Label").Text == "Beta", "tab `Label`")
	H.fire(buttons[2], "Activated", H.input({}), 1)
	assert(page:Get() == "b" and pages[1] == "b")
	q.dispose(tabs)
	local live = q.Source({ { Key = "a", Label = "A" } } :: { Tabs.Tab<string> })
	local tabs2 = Tabs<<string>>({ Selected = page, TabsState = live })
	live:Set({ { Key = "a", Label = "A" }, { Key = "b", Label = "B" } })
	assert(#H.findAll(tabs2, function(c: any)
		return c.Name == "Tab"
	end) == 2, "TabsState follows the State")
	assert(not pcall(Tabs :: any, { Selected = page }), "neither Tabs nor TabsState is an error")
	q.dispose(tabs2)
	-- DatePicker.Docked
	local day = q.Source(nil :: DatePicker.Date?)
	local days: { DatePicker.Date } = {}
	local docked = DatePicker.Docked({
		Value = day,
		Today = Calendar.date(2026, 2, 10),
		OnChange = function(d: DatePicker.Date)
			table.insert(days, d)
		end,
	})
	local cells = H.findAll(docked, function(c: any)
		return c.Name == "Day"
	end)
	H.fire(cells[15], "Activated", H.input({}), 1)
	assert(#days == 1 and Calendar.equals(days[1], day:Get() :: DatePicker.Date))
	q.dispose(docked)
	H.assertNoDebugOutput("onchange")
end)

H.section("Util helpers: negate / interactable / visible / hooks", function()
	local s = q.Source(true)
	assert(Util.negate(s):Get() == false and Util.interactable(s):Get() == false)
	s:Set(false)
	assert(Util.negate(s):Get() == true)
	assert(Util.visible(nil) == true and Util.visible(false) == false)
	local st = q.Source(false)
	assert(Util.visible(st) == st)
	assert(#Util.hooks(nil) == 0 and #Util.hooks({ 1, 2 }) == 2)
	assert(Util.peekBool(nil) == false and Util.peekBool(s) == false)
	H.assertNoDebugOutput("util")
end)

H.done()
