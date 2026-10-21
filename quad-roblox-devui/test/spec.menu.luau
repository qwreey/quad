--!strict
local H = require("./support/harness")
local Quad = require("../src/Quad")
local q = H.attach(Quad)
q.debug = true
local Frame = q.Elem "Frame"
local ScreenGui = q.Elem "ScreenGui"
local Overlay = require("../src/Overlay")
Overlay.warnUnmounted = false -- these specs open popups on a bare layer (no ScreenGui); the debug line has its own spec in spec.overlay
local MenuModule = require("../src/Menu")

local UIS = H.UserInputService
local function nBegan(): number
	return #(UIS.InputBegan :: any).connections
end
local function byName(root: Instance, name: string): { any }
	return H.findAll(root, function(i: any)
		return i.Name == name
	end)
end
local function get(root: Instance, name: string): any
	local found = H.find(root, name)
	assert(found ~= nil, `missing {name}`)
	return found
end
-- simple rows carry their text; rows with a check / shortcut / arrow hold it in a Label child
local function rowText(inst: any): string
	if inst.Text ~= "" then
		return inst.Text
	end
	return get(inst, "Label").Text
end
local function click(inst: any)
	H.fire(inst, "Activated", H.input({}), 1)
end
local function escape()
	UIS.InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Escape }), false)
end

-- File: Open (Ctrl+O), Autosave toggle, Disabled item, Recent > { a.txt, b.txt }
type Probe = { opened: number, recent: { string }, autosave: any, factoryRuns: number }
local function build(o: Overlay.Overlay): (Frame, Probe)
	local probe: Probe = { opened = 0, recent = {}, autosave = q.Source(false), factoryRuns = 0 }
	local disabledRan = 0
	local bar = MenuModule.MenuBar({
		Children = q.Slot<<Instance>>({
			MenuModule.Menu({
				Text = "File",
				Overlay = o,
				Children = function(scope)
					probe.factoryRuns += 1
					return q.Slot<<Instance>>({
						MenuModule.MenuItem({
							Text = "Open",
							Shortcut = "Ctrl+O",
							Scope = scope,
							OnClick = function()
								probe.opened += 1
							end,
						}),
						MenuModule.MenuToggle({ Text = "Autosave", Value = probe.autosave, Scope = scope }),
						MenuModule.MenuItem({
							Text = "Locked",
							Disabled = true,
							Scope = scope,
							OnClick = function()
								disabledRan += 1
							end,
						}),
						MenuModule.Menu({
							Text = "Recent",
							Scope = scope,
							Children = function(sub)
								return q.Slot<<Instance>>({
									MenuModule.MenuItem({
										Text = "a.txt",
										Scope = sub,
										OnClick = function()
											table.insert(probe.recent, "a")
										end,
									}),
									MenuModule.MenuItem({
										Text = "b.txt",
										Scope = sub,
										OnClick = function()
											table.insert(probe.recent, "b")
										end,
									}),
								})
							end,
						}),
					})
				end,
			}),
			MenuModule.Menu({
				Text = "Edit",
				Overlay = o,
				Children = function(scope)
					return q.Slot<<Instance>>({ MenuModule.MenuItem({ Text = "Undo", Scope = scope, OnClick = function() end }) })
				end,
			}),
		}),
	})
	return bar, probe
end

local function titles(bar: Frame): { any }
	return byName(bar, "Menu")
end

H.section("mount: bar items only, the factory has not run, nothing connected", function()
	local o = Overlay.new()
	local base = nBegan()
	local bar, probe = build(o)
	local items = titles(bar)
	assert(#items == 2 and items[1].Text == "File" and items[2].Text == "Edit")
	assert(bar.Name == "MenuBar" and (bar :: any).AutomaticSize == Enum.AutomaticSize.Y)
	assert(probe.factoryRuns == 0 and o.Count:Get() == 0 and nBegan() == base)
	q.dispose(bar)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("mount")
end)

H.section("click opens under the item; item click runs OnClick after closing the chain; repeated cycles", function()
	local o = Overlay.new()
	local bar, probe = build(o)
	local file = titles(bar)[1]
	H.setAbs(file, 10, 5, 40, 19)
	local base = nBegan()
	for cycle = 1, 3 do
		click(file)
		assert(o.Count:Get() == 1 and probe.factoryRuns == cycle and nBegan() == base + 1)
		local holder = get(o.Layer, "PopupHolder")
		assert(holder.Position == UDim2.fromOffset(10, 24), "under the bar item")
		local open = byName(o.Layer, "MenuItem")
		assert(open[1].Text == "" and get(open[1], "Label").Text == "Open" and get(open[1], "Shortcut").Text == "Ctrl+O")
		-- the label sizes itself (a Fill label is not counted by an automatically sized row: a menu of toggle rows was
		-- as wide as its check column); an empty Fill spacer pushes the shortcut right
		assert(H.find(get(open[1], "Label"), "UIFlexItem") == nil and H.find(get(open[1], "Spacer"), "UIFlexItem") ~= nil)
		click(open[1])
		assert(probe.opened == cycle, "OnClick ran")
		assert(o.Count:Get() == 0 and #o.Layer:GetChildren() == 0 and nBegan() == base, "chain closed, layer empty")
	end
	q.dispose(bar)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("open/close cycles")
end)

H.section("a bar item toggles its own menu; the catcher / Escape close; disabled items are inert", function()
	local o = Overlay.new()
	local bar, probe = build(o)
	local file = titles(bar)[1]
	click(file)
	assert(o.Count:Get() == 1)
	click(file) -- (behind the catcher on a device; the handler itself toggles)
	assert(o.Count:Get() == 0)

	click(file)
	local locked = byName(o.Layer, "MenuItem")[2]
	click(locked)
	assert(o.Count:Get() == 1, "a disabled item does not close the menu")
	H.fire(locked, "MouseEnter", 0, 0)
	click(get(o.Layer, "Catcher"))
	assert(o.Count:Get() == 0, "click outside closes")

	local base = nBegan()
	click(file)
	assert(nBegan() == base + 1)
	escape()
	assert(o.Count:Get() == 0 and nBegan() == base, "Escape closes and disconnects")
	assert(probe.opened == 0)
	q.dispose(bar)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("close paths")
end)

H.section("hover to switch: while a bar menu is open, entering another title opens that one; closed, hovering does nothing", function()
	local o = Overlay.new()
	local bar = build(o)
	local file, edit = titles(bar)[1], titles(bar)[2]
	H.fire(edit, "MouseEnter", 0, 0)
	assert(o.Count:Get() == 0, "nothing open: hovering a title opens nothing")
	click(file)
	assert(rowText(byName(o.Layer, "MenuItem")[1]) == "Open")
	H.fire(edit, "MouseEnter", 0, 0)
	assert(o.Count:Get() == 1 and rowText(byName(o.Layer, "MenuItem")[1]) == "Undo", "switched to Edit")
	H.fire(edit, "MouseEnter", 0, 0)
	assert(o.Count:Get() == 1, "the open one's own title: no change")
	H.fire(file, "MouseEnter", 0, 0)
	assert(rowText(byName(o.Layer, "MenuItem")[1]) == "Open", "and back")
	escape()
	assert(o.Count:Get() == 0)
	H.fire(edit, "MouseEnter", 0, 0)
	assert(o.Count:Get() == 0, "closed again: hovering opens nothing")
	-- a press (touch: no hover) on another title while one is open switches at once — the catcher does not eat it
	H.setAbs(file, 0, 0, 40, 19)
	H.setAbs(edit, 40, 0, 40, 19)
	click(file)
	UIS.InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(50, 10, 0) }), false)
	assert(o.Count:Get() == 1 and rowText(byName(o.Layer, "MenuItem")[1]) == "Undo", "pressed Edit: Edit open")
	UIS.InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(300, 300, 0) }), false)
	assert(o.Count:Get() == 1, "a press elsewhere is left to the catcher")
	escape()
	q.dispose(bar)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("hover switch")
end)

H.section("Hooks on MenuItem / MenuToggle ride on the row", function()
	local seen: { string } = {}
	local function marker(tag: string): any
		local ref = q.PostRef(nil :: Instance?)
		ref:Callback(function(inst)
			if inst ~= nil then
				table.insert(seen, `{tag}:{inst.Name}`)
			end
		end)
		return ref
	end
	local item = MenuModule.MenuItem({ Text = "Copy", OnClick = function() end, Hooks = { marker("item") } })
	local toggle = MenuModule.MenuToggle({ Text = "Wrap", Hooks = { marker("toggle") } })
	assert(table.concat(seen, ",") == "item:MenuItem,toggle:MenuToggle", table.concat(seen, ","))
	q.dispose(item)
	q.dispose(toggle)
	H.assertNoDebugOutput("menu hooks")
end)

H.section("OpenMenu: opens now at a point with the Menu factory; Escape / Close close it; KeepOpen leaves it open", function()
	local o = Overlay.new()
	local ran, flag = 0, q.Source(false)
	local m = MenuModule.OpenMenu({
		At = Vector2.new(50, 60),
		Overlay = o,
		Children = function(scope)
			return q.Slot<<Instance>>({
				MenuModule.MenuItem({ Text = "Run", Scope = scope, OnClick = function()
					ran += 1
				end }),
				MenuModule.MenuToggle({ Text = "Wrap", Value = flag, KeepOpen = true, Scope = scope }),
				MenuModule.MenuItem({ Text = "Again", Scope = scope, KeepOpen = true, OnClick = function()
					ran += 1
				end }),
			})
		end,
	})
	assert(m.IsOpen:Get() and o.Count:Get() == 1 and get(o.Layer, "PopupHolder").Position == UDim2.fromOffset(50, 60), "at the point")
	click(byName(o.Layer, "MenuToggle")[1])
	assert(flag:Get() == true and o.Count:Get() == 1, "KeepOpen toggle: flipped, still open")
	click(byName(o.Layer, "MenuItem")[2])
	assert(ran == 1 and o.Count:Get() == 1, "KeepOpen item: ran, still open")
	click(byName(o.Layer, "MenuItem")[1])
	assert(ran == 2 and o.Count:Get() == 0 and not m.IsOpen:Get(), "an ordinary item closes it")
	local m2 = MenuModule.OpenMenu({ At = Rect.new(10, 10, 110, 29), Overlay = o, Children = function(scope)
		return q.Slot<<Instance>>({ MenuModule.MenuItem({ Text = "x", Scope = scope, OnClick = function() end }) })
	end })
	assert(get(o.Layer, "PopupHolder").Position == UDim2.fromOffset(10, 29), "under a rectangle")
	local base = nBegan()
	escape()
	assert(not m2.IsOpen:Get() and nBegan() == base - 1, "Escape closes and disconnects")
	local m3 = MenuModule.OpenMenu({ At = Vector2.zero, Overlay = o, Children = function(_scope)
		return q.Slot<<Instance>>({})
	end })
	m3:Close()
	assert(o.Count:Get() == 0 and not m3.IsOpen:Get())
	q.dispose(o.Layer)
	H.assertNoDebugOutput("open menu")
end)

H.section("a menu taller than the layer scrolls (rows in MenuScroll capped at the layer's height); a short one stays a plain list", function()
	local o = Overlay.new()
	H.setAbs(o.Layer, 0, 0, 800, 300)
	local function items(n: number): any
		return function(scope: any): any
			local t: { Instance } = {}
			for i = 1, n do
				table.insert(t, MenuModule.MenuItem({ Text = `item {i}`, Scope = scope, OnClick = function() end }))
			end
			return q.Slot<<Instance>>(t)
		end
	end
	local long = MenuModule.OpenMenu({ At = Vector2.new(10, 10), Overlay = o, Children = items(40) })
	local scroll = H.find(o.Layer, "MenuScroll") :: any
	assert(scroll ~= nil and #byName(scroll, "MenuItem") == 40, "the rows are in the scroll")
	local layout: any = nil
	for _, child in scroll:GetChildren() do
		if child.ClassName == "UIListLayout" then
			layout = child
		end
	end
	layout.AbsoluteContentSize = Vector2.new(120, 40 * 19) -- (the engine lays the rows out)
	assert(scroll.Size.Y.Offset < 300 and scroll.Size.Y.Offset > 250 and scroll.ScrollBarThickness > 0, `capped ({scroll.Size})`)
	layout.AbsoluteContentSize = Vector2.new(120, 3 * 19)
	assert(scroll.Size.Y.Offset == 57 and scroll.ScrollBarThickness == 0, "fits: no bar (it would widen the menu)")
	long:Close()
	q.dispose(o.Layer)
	H.assertNoDebugOutput("menu scroll")
end)

H.section("MenuButton: split (body runs OnClick, the arrow opens, a disabled body still opens) and whole (it all opens)", function()
	local o = Overlay.new()
	local clicked = 0
	local function items(scope: any): any
		return q.Slot<<Instance>>({ MenuModule.MenuItem({ Text = "Copy filtered", Scope = scope, OnClick = function() end }) })
	end
	local splitButton = MenuModule.MenuButton({ Text = "Copy", OnClick = function()
		clicked += 1
	end, Disabled = false, Overlay = o, Children = items })
	H.setAbs(splitButton, 20, 30, 80, 19)
	click(get(splitButton, "MenuButtonBody"))
	assert(clicked == 1 and o.Count:Get() == 0, "the body runs OnClick")
	click(get(splitButton, "MenuButtonArrow"))
	assert(o.Count:Get() == 1 and get(o.Layer, "PopupHolder").Position == UDim2.fromOffset(20, 49), "the arrow opens it under the button")
	click(get(splitButton, "MenuButtonArrow"))
	assert(o.Count:Get() == 0, "and closes it")
	H.fire(splitButton, "InputBegan", H.input({ UserInputType = Enum.UserInputType.MouseButton2 }))
	assert(o.Count:Get() == 1, "a right-click opens it")
	o:CloseAll()
	local off = MenuModule.MenuButton({ Text = "Copy", OnClick = function()
		clicked += 1
	end, Disabled = true, Overlay = o, Children = items })
	click(get(off, "MenuButtonBody"))
	assert(clicked == 1, "a disabled body does not run")
	click(get(off, "MenuButtonArrow"))
	assert(o.Count:Get() == 1, "but its menu opens")
	o:CloseAll()
	local whole = MenuModule.MenuButton({ Icon = "rbxassetid://1", Overlay = o, Children = items })
	assert(H.find(whole, "MenuButtonArrow") == nil and H.find(get(whole, "MenuButtonBody"), "Arrow") ~= nil, "one piece with a ▾")
	-- the ▾ is a small glyph; the split form's ▾ part a narrow column (14 / 24 of the frame height), not a square button
	assert((H.find(get(whole, "MenuButtonBody"), "Arrow") :: any).Size == UDim2.fromOffset(6, 6), "a 0.45 TextSize ▾")
	local column = get(splitButton, "MenuButtonArrow") :: any
	assert(column.Size == UDim2.fromOffset(11, 19), `a narrow ▾ column ({column.Size})`)
	click(get(whole, "MenuButtonBody"))
	assert(o.Count:Get() == 1, "the whole button opens it")
	o:CloseAll()
	local wholeOff = MenuModule.MenuButton({ Text = "Filter", Disabled = true, Overlay = o, Children = items })
	click(get(wholeOff, "MenuButtonBody"))
	H.fire(wholeOff, "InputBegan", H.input({ UserInputType = Enum.UserInputType.MouseButton2 }))
	assert(o.Count:Get() == 0, "a disabled one-piece button opens nothing")
	for _, b in { splitButton, off, whole, wholeOff } do
		q.dispose(b)
	end
	q.dispose(o.Layer)
	H.assertNoDebugOutput("menu button")
end)

H.section("PopupPanel: the menu's popup body for app-made popups", function()
	local body = MenuModule.PopupPanel({ Children = q.Slot<<Instance>>({ Frame({ Name = "Row" }) }) })
	assert(body.Name == "MenuPanel" and body.AutomaticSize == Enum.AutomaticSize.XY and H.find(body, "Row") ~= nil)
	q.dispose(body)
end)

H.section("MenuToggle flips its Source and closes; the check mark follows the Source", function()
	local o = Overlay.new()
	local bar, probe = build(o)
	local file = titles(bar)[1]
	click(file)
	local toggle = byName(o.Layer, "MenuToggle")[1]
	local check = get(toggle, "Check")
	assert(check.ImageTransparency == 1)
	probe.autosave:Set(true)
	assert(check.ImageTransparency < 1, "mark shows while true")
	click(toggle)
	assert(probe.autosave:Get() == false and o.Count:Get() == 0)
	click(file)
	click(byName(o.Layer, "MenuToggle")[1])
	assert(probe.autosave:Get() == true and o.Count:Get() == 0)
	q.dispose(bar)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("toggle")
end)

H.section("submenu: opens right of its item on hover, sibling hover closes it, an item closes the whole chain", function()
	local o = Overlay.new()
	local bar, probe = build(o)
	local file = titles(bar)[1]
	click(file)
	local recent = byName(o.Layer, "Menu")[1]
	H.setAbs(recent, 100, 60, 80, 19)
	H.fire(recent, "MouseEnter", 0, 0)
	assert(o.Count:Get() == 2)
	local holders = byName(o.Layer, "PopupHolder")
	assert(holders[2].Position == UDim2.fromOffset(180, 60), "right of the item")
	assert(#byName(o.Layer, "Catcher") == 1, "only the root has a catcher")
	H.fire(recent, "MouseEnter", 0, 0)
	assert(o.Count:Get() == 2, "hovering again does not reopen")

	-- hovering a sibling closes the submenu
	H.fire(byName(o.Layer, "MenuItem")[1], "MouseEnter", 0, 0)
	assert(o.Count:Get() == 1)
	-- reopen by click, then choose inside: both popups close, then OnClick runs
	click(recent)
	assert(o.Count:Get() == 2)
	local all = byName(o.Layer, "MenuItem")
	local a: any = nil
	for _, i in all do
		if rowText(i) == "a.txt" then
			a = i
		end
	end
	assert(a ~= nil)
	click(a)
	assert(#probe.recent == 1 and probe.recent[1] == "a")
	assert(o.Count:Get() == 0 and #o.Layer:GetChildren() == 0)
	H.assertNoDebugOutput("submenu")

	-- Escape closes the root and with it the submenu
	click(file)
	H.fire(byName(o.Layer, "Menu")[1], "MouseEnter", 0, 0)
	assert(o.Count:Get() == 2)
	escape()
	assert(o.Count:Get() == 0 and #o.Layer:GetChildren() == 0)
	-- the catcher closes the root and the submenu
	click(file)
	H.fire(byName(o.Layer, "Menu")[1], "MouseEnter", 0, 0)
	click(get(o.Layer, "Catcher"))
	assert(o.Count:Get() == 0)
	q.dispose(bar)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("submenu close paths")
end)

H.section("Menu row shows the Active look while its menu is open", function()
	local o = Overlay.new()
	local bar = build(o)
	local file = titles(bar)[1]
	assert((file :: any).BackgroundTransparency == 1)
	click(file)
	assert((file :: any).BackgroundTransparency < 1)
	o:CloseAll()
	assert((file :: any).BackgroundTransparency == 1)
	q.dispose(bar)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("active look")
end)

H.section("dispose: destroying the bar with a menu open closes it and leaves no connection", function()
	local o = Overlay.new()
	local base = nBegan()
	local bar = build(o)
	local screen = ScreenGui({ bar, o.Layer })
	click(titles(bar)[1])
	H.fire(byName(o.Layer, "Menu")[1], "MouseEnter", 0, 0)
	assert(o.Count:Get() == 2 and nBegan() == base + 1)
	q.dispose(screen)
	assert(o.Count:Get() == 0 and nBegan() == base)
	H.assertNoDebugOutput("dispose")
end)

H.section("MenuToggle controlled form: Checked + OnToggle report, the caller decides; Value form still works; both is an error", function()
	local o = Overlay.new()
	local mode = q.Source("a")
	local isB: Quad.State<boolean> = mode:Compute(function(self)
		return self:Get() == "b"
	end)
	local reported: { boolean } = {}
	local bar = MenuModule.MenuBar({
		Children = q.Slot<<Instance>>({
			MenuModule.Menu({
				Text = "Mode",
				Overlay = o,
				Children = function(scope)
					return q.Slot<<Instance>>({
						MenuModule.MenuToggle({
							Text = "Use B",
							Checked = isB,
							OnToggle = function(on: boolean)
								table.insert(reported, on)
								mode:Set(if on then "b" else "a")
							end,
							Scope = scope,
						}),
					})
				end,
			}),
		}),
	})
	local title = titles(bar)[1]
	click(title)
	local toggle = byName(o.Layer, "MenuToggle")[1]
	assert(get(toggle, "Check").ImageTransparency == 1)
	click(toggle)
	assert(mode:Get() == "b" and reported[1] == true and o.Count:Get() == 0, "reported, the caller wrote, menu closed")
	click(title)
	toggle = byName(o.Layer, "MenuToggle")[1]
	assert(get(toggle, "Check").ImageTransparency < 1, "the mark follows the controlled State")
	click(toggle)
	assert(mode:Get() == "a" and reported[2] == false)
	-- Value form + OnToggle: the Source is flipped, then reported
	local src = q.Source(false)
	local seen: { boolean } = {}
	local row = MenuModule.MenuToggle({ Text = "v", Value = src, OnToggle = function(on: boolean)
		table.insert(seen, on)
	end })
	click(row)
	assert(src:Get() == true and seen[1] == true)
	-- neither: an internal Source
	local lone = MenuModule.MenuToggle({ Text = "lone" })
	click(lone)
	assert(get(lone, "Check").ImageTransparency < 1)
	local ok = pcall(function()
		MenuModule.MenuToggle({ Text = "both", Value = src, Checked = isB })
	end)
	assert(not ok, "Value and Checked together are rejected")
	q.dispose(bar)
	q.dispose(row)
	q.dispose(lone)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("controlled toggle")
end)

H.section("the layer dying with a menu chain open: popups close, Escape listener released, no throw", function()
	local o = Overlay.new()
	local gui = ScreenGui({ o.Layer })
	local bar = build(o)
	local file = titles(bar)[1]
	local base = nBegan()
	click(file)
	assert(o.Count:Get() == 1 and nBegan() == base + 1)
	q.dispose(gui)
	assert(o.Count:Get() == 0 and nBegan() == base, "Escape listener back to baseline")
	click(file) -- opening on a dead overlay does nothing
	assert(o.Count:Get() == 0 and nBegan() == base)
	q.dispose(bar)
	H.assertNoDebugOutput("layer death")
end)

H.section("the default overlay is resolved when the menu opens (a rebuilt default is picked up)", function()
	local first = Overlay.getDefault()
	local bar = MenuModule.MenuBar({
		Children = q.Slot<<Instance>>({
			MenuModule.Menu({
				Text = "D",
				Children = function(scope)
					return q.Slot<<Instance>>({ MenuModule.MenuItem({ Text = "x", Scope = scope, OnClick = function() end }) })
				end,
			}),
		}),
	})
	q.dispose(ScreenGui({ first.Layer })) -- the first default dies
	local second = Overlay.getDefault()
	assert(second ~= first)
	click(titles(bar)[1])
	assert(second.Count:Get() == 1 and first.Count:Get() == 0, "opened on the live default")
	second:CloseAll()
	q.dispose(bar)
	q.dispose(second.Layer)
	H.assertNoDebugOutput("default at open")
end)


H.section("closing the window the menu bar is in closes the open chain (submenu included); watchers only while open", function()
	local o = Overlay.new()
	local win = Frame({})
	local bar = build(o)
	bar.Parent = win
	local file = titles(bar)[1]
	local winVisible = (win :: any):GetPropertyChangedSignal("Visible")
	local idle = #winVisible.connections
	local base = nBegan()
	click(file)
	local recent = byName(o.Layer, "Menu")[1]
	H.fire(recent, "MouseEnter", 0, 0)
	assert(o.Count:Get() == 2 and #winVisible.connections == idle + 1, "root + submenu open; ancestors watched once")
	win.Visible = false
	assert(o.Count:Get() == 0 and nBegan() == base and #winVisible.connections == idle, "whole chain closed, nothing left")
	win.Visible = true
	click(file)
	assert(o.Count:Get() == 1, "opens again once shown")
	escape()
	assert(o.Count:Get() == 0 and #winVisible.connections == idle)
	q.dispose(win)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("ancestor hidden")
end)

H.done()
