--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Overlay = require("../src/Overlay")
local Tokens = require("../src/Tokens")

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

local function dialog(text: string)
	return D.Frame { Name = "Dialog", D.TextLabel { Name = "Msg", Text = text } }
end

H.section("layer: transparent full-screen frame, empty at first", function()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	local layer = overlay.Layer
	assert(layer.Size == UDim2.fromScale(1, 1) and layer.BackgroundTransparency == 1 and layer.Name == "Overlay")
	assert(layer.ZIndex == 100)
	assert(overlay.Count:Get() == 0 and #layer:GetChildren() == 0)
	q.dispose(screen)
	H.assertNoDebugOutput("layer")
end)

H.section("q.debug: the first Open under a ScreenGui that is not ZIndexBehavior Sibling says so, once; Sibling and no ScreenGui are silent", function()
	local function openOnce(overlay: any)
		overlay:Open({ Content = function() return dialog("x") end }).Close()
	end
	local global = Overlay.new()
	local screenGlobal = D.ScreenGui { Name = "App", ZIndexBehavior = Enum.ZIndexBehavior.Global, global.Layer }
	openOnce(global)
	local out = H.output()
	assert(#out == 1 and string.find(out[1], "ZIndexBehavior = Global", 1, true) ~= nil and string.find(out[1], "\"App\"", 1, true) ~= nil, "one line naming the ScreenGui: " .. table.concat(out, " | "))
	openOnce(global)
	assert(#H.output() == 1, "once per overlay")
	H.resetOutput()
	local sibling = Overlay.new()
	local screenSibling = D.ScreenGui { ZIndexBehavior = Enum.ZIndexBehavior.Sibling, sibling.Layer }
	openOnce(sibling)
	local bare = Overlay.new()
	local holder = D.Frame { bare.Layer }
	openOnce(bare)
	H.assertNoDebugOutput("Sibling / no ScreenGui")
	q.debug = false
	local quiet = Overlay.new()
	local screenQuiet = D.ScreenGui { ZIndexBehavior = Enum.ZIndexBehavior.Global, quiet.Layer }
	openOnce(quiet)
	q.debug = true
	H.assertNoDebugOutput("debug off")
	H.advance(1)
	q.dispose(screenGlobal)
	q.dispose(screenSibling)
	q.dispose(holder)
	q.dispose(screenQuiet)
end)

H.section("open with scrim: mounts snapped, fades in to .32 opacity, click dismisses", function()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	local closed = 0
	local handle = overlay:Open({
		Content = dialog("Hello"),
		Scrim = true,
		OnClose = function()
			closed += 1
		end,
	})
	assert(overlay.Count:Get() == 1 and handle.IsOpen:Get() and not handle.Closing:Get())
	local scrim = H.find(screen, "Scrim")
	assert(scrim ~= nil and scrim.ClassName == "TextButton" and scrim.Size == UDim2.fromScale(1, 1))
	assert(scrim.BackgroundColor3 == Tokens.Color.Light.Scrim)
	assert(H.find(screen, "Msg").Text == "Hello", "content mounted")
	H.finishTweens()
	assert(near(scrim.BackgroundTransparency, 0.68), "scrim fades to opacity .32: " .. scrim.BackgroundTransparency)
	-- click on the scrim
	H.fire(scrim, "Activated", H.input({}), 1)
	assert(not handle.IsOpen:Get() and handle.Closing:Get() and closed == 1)
	assert(H.find(screen, "Dialog") ~= nil, "still mounted during the exit phase")
	H.finishTweens()
	assert(scrim.BackgroundTransparency == 1, "scrim fades out")
	H.advance(0.3)
	assert(H.find(screen, "Dialog") == nil and H.isDestroyed(scrim) and overlay.Count:Get() == 0 and not handle.Closing:Get(), "removed + destroyed after the exit")
	handle.Close() -- idempotent
	assert(closed == 1)
	q.dispose(screen)
	H.assertNoDebugOutput("scrim")
end)

H.section("builder content gets the handle and can close itself", function()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	local handle = overlay:Open({
		Content = function(h)
			return D.TextButton {
				Name = "Ok",
				Activated = function()
					h.Close()
				end,
			}
		end,
		ExitTime = 0,
	})
	assert(overlay.Count:Get() == 1)
	H.fire(H.find(screen, "Ok"), "Activated", H.input({}), 1)
	assert(overlay.Count:Get() == 0 and H.find(screen, "Ok") == nil, "ExitTime 0 removes immediately")
	assert(not handle.IsOpen:Get())
	q.dispose(screen)
	H.assertNoDebugOutput("builder")
end)

H.section("non-dismissable scrim ignores clicks; no scrim means no blocker", function()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	local modal = overlay:Open({ Content = dialog("Modal"), Scrim = true, Dismissable = false })
	H.fire(H.find(screen, "Scrim"), "Activated", H.input({}), 1)
	assert(modal.IsOpen:Get(), "scrim click does nothing")
	local toast = overlay:Open({ Content = dialog("Toast") })
	assert(#H.findAll(screen, function(c: any) return c.Name == "Scrim" end) == 1, "toast has no scrim")
	assert(overlay.Count:Get() == 2, "entries stack")
	toast.Close()
	modal.Close()
	H.advance(0.3)
	assert(overlay.Count:Get() == 0)
	q.dispose(screen)
	H.assertNoDebugOutput("stack")
end)

H.section("custom scrim opacity and the Layer dying with pending closes", function()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	local handle = overlay:Open({ Content = dialog("X"), Scrim = true, ScrimOpacity = 0.5 })
	H.finishTweens()
	assert(near(H.find(screen, "Scrim").BackgroundTransparency, 0.5))
	handle.Close()
	assert(H.pendingTimers() == 1)
	q.dispose(screen)
	assert(H.pendingTimers() == 0, "exit timers cancelled with the layer")
	H.advance(1)
	H.assertNoDebugOutput("layer death")
end)

H.section("default overlay exists and works", function()
	local screen = D.Frame { Overlay.default().Layer }
	local h = Overlay.default():Open({ Content = dialog("Default"), ExitTime = 0 })
	assert(H.find(screen, "Dialog") ~= nil)
	h.Close()
	assert(H.find(screen, "Dialog") == nil)
	q.dispose(screen)
	H.assertNoDebugOutput("default")
end)

H.section("dark scheme scrim color follows the theme", function()
	local Theme = require("../src/Theme")
	local theme = Theme.new({ Scheme = "dark", Overrides = { Dark = { Scrim = Color3.fromRGB(10, 0, 0) } } })
	local overlay = Overlay.new({ Theme = theme })
	local screen = D.Frame { overlay.Layer }
	overlay:Open({ Content = dialog("D"), Scrim = true })
	assert(H.find(screen, "Scrim").BackgroundColor3 == Color3.fromRGB(10, 0, 0))
	q.dispose(screen)
	H.assertNoDebugOutput("theme")
end)

local UIS = H.UserInputService
local GS = H.GuiService
local function inputBeganConns(): number
	return #(UIS :: any).InputBegan.connections
end
local baseConns = inputBeganConns()
local function key(code: any, ut: any?, processed: boolean?)
	UIS.InputBegan:Fire(H.input({ KeyCode = code, UserInputType = ut or Enum.UserInputType.Keyboard }), processed == true)
end

H.section("A-H1 Overlay.default() is lazy and self-healing; Open on a dead overlay errors loudly", function()
	local first = Overlay.default()
	assert(Overlay.default() == first, "stable while alive")
	local screen = D.Frame { first.Layer }
	assert(first.Alive:Get() == true)
	q.dispose(screen)
	assert(first.Alive:Get() == false, "layer death flips Alive")
	local ok, err = pcall(function()
		first:Open({ Content = dialog("dead") })
	end)
	assert(not ok and string.find(tostring(err), "overlay layer was destroyed", 1, true) ~= nil, "loud: " .. tostring(err))
	assert(first.Count:Get() == 0)
	local second = Overlay.default()
	assert(second ~= first and second.Alive:Get() == true, "a fresh default after the old layer died")
	local screen2 = D.Frame { second.Layer }
	local h = second:Open({ Content = dialog("alive"), ExitTime = 0 })
	assert(H.find(screen2, "Dialog") ~= nil)
	h.Close()
	q.dispose(screen2)
	H.assertNoDebugOutput("default heal")
end)

H.section("A-H2 layer death finalizes every live handle (open, closing, scrim), no leaked Escape connection or timer", function()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	local reasons: { string } = {}
	local function onClose(tag: string): (string, unknown?) -> ()
		return function(reason: string, _result: unknown?)
			table.insert(reasons, tag .. ":" .. reason)
		end
	end
	local a = overlay:Open({ Content = dialog("A"), Scrim = true, DismissOnEscape = true, OnClose = onClose("a") })
	local b = overlay:Open({ Content = dialog("B"), OnClose = onClose("b") })
	local c = overlay:Open({ Content = dialog("C"), OnClose = onClose("c") })
	c.Close() -- closing, exit timer pending
	assert(c.Closing:Get() == true and H.pendingTimers() >= 1 and overlay.Count:Get() == 3)
	assert(inputBeganConns() == baseConns + 1, "the shared Escape connection is up while a modal/escapable entry is open")
	q.dispose(screen)
	assert(not a.IsOpen:Get() and not b.IsOpen:Get() and not c.IsOpen:Get())
	assert(not a.Closing:Get() and not b.Closing:Get() and not c.Closing:Get(), "Closing false everywhere")
	assert(overlay.Count:Get() == 0 and overlay.Alive:Get() == false)
	table.sort(reasons)
	assert(table.concat(reasons, ",") == "a:Destroyed,b:Destroyed,c:Close", "OnClose once each: " .. table.concat(reasons, ","))
	assert(inputBeganConns() == baseConns, "Escape connection back at baseline")
	assert(H.pendingTimers() == 0, "timers cancelled")
	a.Close() -- idempotent after death
	H.advance(1)
	assert(#reasons == 3)
	H.assertNoDebugOutput("layer death")
end)

-- the selection trap is a SelectionGroup entry whose four directions Stop (GuiService:AddSelectionParent is deprecated)
local function trapped(root: any): boolean
	local e = H.find(root, "OverlayEntry")
	return e ~= nil
		and e.SelectionGroup == true
		and e.SelectionBehaviorUp == Enum.SelectionBehavior.Stop
		and e.SelectionBehaviorDown == Enum.SelectionBehavior.Stop
		and e.SelectionBehaviorLeft == Enum.SelectionBehavior.Stop
		and e.SelectionBehaviorRight == Enum.SelectionBehavior.Stop
end

H.section("scrim is not Selectable; selection group is set on open and released (and the previous selection restored) on close", function()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	local prev = D.TextButton { Name = "Prev", Selectable = true }
	local prevHost = D.Frame { prev }
	;(UIS :: any).GetLastInputType = function() return Enum.UserInputType.Gamepad1 end
	GS.SelectedObject = prev
	local inner: any = nil
	local h = overlay:Open({
		Content = function()
			inner = D.TextButton { Name = "First", Selectable = true }
			return D.Frame { Name = "Menu", inner }
		end,
		Scrim = true,
		TrapSelection = true,
		InitialSelection = function()
			return inner
		end,
		ExitTime = 0,
	})
	assert(H.find(screen, "Scrim").Selectable == false, "a gamepad never lands on the scrim")
	assert(trapped(screen), "the entry is a selection group with Stop on all four directions")
	assert(GS.SelectedObject == inner, "selection moved into the content")
	h.Close()
	assert(not trapped(screen), "selection group released on close")
	assert(GS.SelectedObject == prev, "previous selection restored")
	-- no gamepad: nothing is moved
	;(UIS :: any).GetLastInputType = nil
	GS.SelectedObject = nil
	local h2 = overlay:Open({ Content = dialog("x"), TrapSelection = true, InitialSelection = inner, ExitTime = 0 })
	assert(GS.SelectedObject == nil, "no gamepad: InitialSelection is not applied")
	h2.Close()
	-- layer death also drops the selection parent
	local h3 = overlay:Open({ Content = dialog("y"), TrapSelection = true })
	assert(trapped(screen))
	q.dispose(screen)
	assert(not h3.IsOpen:Get(), "finalized on layer death")
	GS.SelectedObject = nil
	q.dispose(prevHost)
	H.assertNoDebugOutput("selection")
end)

H.section("Escape / B: top-most dismissable entry only, shielded by a non-dismissable modal, ignored while processed or typing", function()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	local reasons: { string } = {}
	local function track(tag: string): (string, unknown?) -> ()
		return function(reason: string, _result: unknown?)
			table.insert(reasons, tag .. ":" .. reason)
		end
	end
	local low = overlay:Open({ Content = dialog("low"), Scrim = true, DismissOnEscape = true, OnClose = track("low"), ExitTime = 0 })
	local top = overlay:Open({ Content = dialog("top"), DismissOnEscape = true, OnClose = track("top"), ExitTime = 0 })
	assert(inputBeganConns() == baseConns + 1, "ONE shared connection for both")
	key(Enum.KeyCode.Escape, nil, true)
	assert(#reasons == 0, "Escape the engine already processed is ignored")
	local box = D.TextBox { Name = "Typing" }
	;(UIS :: any).FocusedTextBox = box
	key(Enum.KeyCode.Escape)
	assert(#reasons == 0, "a focused TextBox keeps Escape for itself")
	key(Enum.KeyCode.ButtonB, Enum.UserInputType.Gamepad1, true)
	assert(table.concat(reasons, ",") == "top:Escape", "ButtonB is honored even when processed: " .. table.concat(reasons, ","))
	;(UIS :: any).FocusedTextBox = nil
	-- a non-dismissable modal on top shields the dismissable one below
	local shield = overlay:Open({ Content = dialog("shield"), Scrim = true, Dismissable = false, OnClose = track("shield"), ExitTime = 0 })
	key(Enum.KeyCode.Escape)
	assert(#reasons == 1 and low.IsOpen:Get() and shield.IsOpen:Get(), "Escape does nothing while the top modal does not want it")
	shield.Close()
	key(Enum.KeyCode.Escape)
	assert(table.concat(reasons, ",") == "top:Escape,shield:Close,low:Escape", table.concat(reasons, ","))
	assert(not low.IsOpen:Get() and not top.IsOpen:Get())
	assert(inputBeganConns() == baseConns, "connection closed with the last entry")
	-- holdDismiss: suppressed until released
	local h = overlay:Open({ Content = dialog("held"), DismissOnEscape = true, ExitTime = 0 })
	local release = Overlay.holdDismiss()
	key(Enum.KeyCode.Escape)
	assert(h.IsOpen:Get(), "held")
	release()
	release() -- idempotent
	key(Enum.KeyCode.Escape)
	assert(not h.IsOpen:Get())
	q.dispose(screen)
	H.assertNoDebugOutput("escape")
end)

H.section("A-L1 a throwing OnClose does not wedge the entry", function()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	local h = overlay:Open({
		Content = dialog("T"),
		OnClose = function()
			error("boom", 0)
		end,
	})
	local ok, err = pcall(function()
		h.Close()
	end)
	assert(not ok and err == "boom")
	assert(not h.IsOpen:Get() and h.Closing:Get(), "state already consistent")
	H.advance(0.3)
	assert(overlay.Count:Get() == 0 and not h.Closing:Get() and H.find(screen, "Dialog") == nil, "removed anyway")
	q.dispose(screen)
	H.assertNoDebugOutput("throwing onclose")
end)

H.section("R2-1 default() detects layer death synchronously (Deferred Destroying: Parent is nil, handlers have not run yet)", function()
	local first = Overlay.default()
	local screen = D.Frame { first.Layer }
	local reasons: { string } = {}
	local h = first:Open({
		Content = dialog("old"),
		Scrim = true,
		DismissOnEscape = true,
		OnClose = function(reason: string)
			table.insert(reasons, reason)
		end,
	})
	assert(Overlay.default() == first, "alive and mounted")
	-- what Destroy() does first; the Destroying handler runs only later under Deferred signals
	first.Layer.Parent = nil
	assert(first.Alive:Get() == true, "the Destroying handler has not run")
	local second = Overlay.default()
	assert(second ~= first, "a fresh overlay at once")
	local ok = pcall(function()
		first:Open({ Content = dialog("dead") })
	end)
	assert(not ok, "Open on the half-dead overlay raises")
	-- closing from an ancestor handler (layer unparented) does no Slot ops on the dead host
	h.Close()
	assert(not h.IsOpen:Get() and #reasons == 1 and reasons[1] == "Close")
	-- the delayed Destroying runs: everything finalized, nothing leaks
	first.Layer:Destroy()
	assert(first.Alive:Get() == false and first.Count:Get() == 0 and not h.Closing:Get())
	assert(inputBeganConns() == baseConns, "Escape connection at baseline")
	assert(H.pendingTimers() == 0, "no timers left")
	local screen2 = D.Frame { second.Layer }
	local h2 = second:Open({ Content = dialog("new"), ExitTime = 0 })
	assert(H.find(screen2, "Dialog") ~= nil and second.Count:Get() == 1)
	h2.Close()
	q.dispose(screen2)
	q.dispose(screen)
	H.assertNoDebugOutput("sync death")
end)

H.section("R2-2 a builder that closes its own handle synchronously seats nothing (ExitTime 0 and > 0)", function()
	for _, exitTime in { 0, 0.2 } do
		local overlay = Overlay.new()
		local screen = D.Frame { overlay.Layer }
		local made: Instance? = nil
		local reasons = 0
		local h = overlay:Open({
			Content = function(hh)
				hh.Close()
				local c = dialog("self-closed")
				made = c
				return c
			end,
			Scrim = true,
			DismissOnEscape = true,
			ExitTime = exitTime,
			OnClose = function()
				reasons += 1
			end,
		})
		assert(made ~= nil and H.isDestroyed(made), "content destroyed")
		assert(overlay.Count:Get() == 0 and not h.IsOpen:Get() and not h.Closing:Get() and reasons == 1)
		assert(H.find(screen, "OverlayEntry") == nil, "nothing seated")
		assert(inputBeganConns() == baseConns, "no Escape registration")
		H.advance(1)
		assert(H.pendingTimers() == 0 and overlay.Count:Get() == 0)
		q.dispose(screen)
		H.assertNoDebugOutput("self close " .. exitTime)
	end
end)

H.done()
