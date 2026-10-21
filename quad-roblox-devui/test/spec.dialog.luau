--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Frame = q.Elem "Frame"
local TextLabel = q.Elem "TextLabel"
local Devui = require("../src")
local Overlay = require("../src/Overlay")
Overlay.warnUnmounted = false -- (popups on a bare layer)

local UIS = H.UserInputService
local function escape()
	UIS.InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Escape }), false)
end
local function click(inst: any)
	H.fire(inst, "Activated", H.input({}), 1)
end

H.section("OpenDialog Modal = Window: the window is veiled (input taken), centred on it, outside clicks keep it; Escape closes", function()
	local o = Overlay.new()
	H.setAbs(o.Layer, 0, 0, 800, 600)
	local win = Frame({ Name = "Window" })
	H.setAbs(win, 100, 100, 300, 200)
	local closes = 0
	local d = Devui.OpenDialog({
		Title = "Rename",
		Window = win,
		Overlay = o,
		OnClose = function()
			closes += 1
		end,
		Children = q.Slot<<Instance>>({ TextLabel({ Name = "Body", Text = "x" }) }),
	})
	assert(d.IsOpen:Get() and o.Count:Get() == 1)
	local cover = win:FindFirstChild("DialogVeil") :: any
	assert(cover ~= nil and cover.Active == true and cover.Size == UDim2.fromScale(1, 1), "the window is veiled")
	local holder = d.IsOpen and H.find(o.Layer, "PopupHolder") :: any
	assert(H.find(o.Layer, "DialogTitle").Text == "Rename" and H.find(o.Layer, "Body") ~= nil)
	assert(holder.Position == UDim2.fromOffset(250, 200) and holder.AnchorPoint == Vector2.new(0.5, 0.5), "centred on the window")
	assert(H.find(o.Layer, "Catcher") == nil, "no click-outside close")
	-- the window moves: the dialog follows
	holder.AbsoluteSize = Vector2.new(120, 60)
	H.setAbs(win, 300, 100, 300, 200)
	assert(holder.Position == UDim2.fromOffset(390, 170), `follows the window ({holder.Position})`)
	escape()
	assert(not d.IsOpen:Get() and o.Count:Get() == 0 and closes == 1 and win:FindFirstChild("DialogVeil") == nil, "Escape closes, the veil goes")
	d:Close()
	assert(closes == 1, "once")
	-- without a Window, "Window" is an error
	local ok, e = pcall(function()
		Devui.OpenDialog({ Title = "x", Overlay = o })
	end)
	assert(not ok and string.find(tostring(e), "give Window", 1, true) ~= nil, tostring(e))
	q.dispose(win)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("window modal")
end)

H.section("OpenDialog Modal = Global: a scrim over the whole layer under the dialog; None: nothing blocked", function()
	local o = Overlay.new()
	H.setAbs(o.Layer, 0, 0, 800, 600)
	local d = Devui.OpenDialog({ Title = "Quit?", Modal = "Global", Overlay = o })
	local scrim = H.find(o.Layer, "DialogScrim") :: any
	assert(scrim ~= nil and scrim.Active == true and scrim.Size == UDim2.fromOffset(800, 600) and o.Count:Get() == 2, "a full-layer scrim")
	local bodyHolder = (H.find(o.Layer, "DialogTitle") :: any).Parent.Parent
	assert(bodyHolder.Name == "PopupHolder" and bodyHolder.Position == UDim2.fromOffset(400, 300), "centred on the screen")
	o.Layer.AbsoluteSize = Vector2.new(1000, 700)
	assert(scrim.Size == UDim2.fromOffset(1000, 700), "follows the layer")
	d:Close()
	assert(o.Count:Get() == 0 and H.find(o.Layer, "DialogScrim") == nil)
	local free = Devui.OpenDialog({ Title = "Find", Modal = "None", Overlay = o })
	assert(o.Count:Get() == 1 and H.find(o.Layer, "DialogScrim") == nil)
	free:Close()
	q.dispose(o.Layer)
	H.assertNoDebugOutput("global modal")
end)

H.section("OpenConfirm: OnResult once — true from the confirm button, false from cancel / Escape / Close / the window closing", function()
	local o = Overlay.new()
	local win = Frame({ Name = "Window" })
	local results: { boolean } = {}
	local function open(): any
		return Devui.OpenConfirm({
			Title = "Delete",
			Text = "Delete Part?",
			ConfirmLabel = "Delete",
			Window = win,
			Overlay = o,
			OnResult = function(ok)
				table.insert(results, ok)
			end,
		})
	end
	local d = open()
	assert(H.find(o.Layer, "ConfirmButton").Text == "Delete" and H.find(o.Layer, "CancelButton").Text == "Cancel")
	click(H.find(o.Layer, "ConfirmButton"))
	assert(#results == 1 and results[1] == true and not d.IsOpen:Get() and win:FindFirstChild("DialogVeil") == nil)
	open()
	click(H.find(o.Layer, "CancelButton"))
	open()
	escape()
	local last = open()
	last:Close()
	open()
	win.Visible = false -- (closing the window it was opened from)
	H.fire(win, "AncestryChanged", win, nil)
	assert(#results == 5, `one result per dialog ({#results})`)
	assert(results[2] == false and results[3] == false and results[4] == false and results[5] == false, "cancel, Escape, Close, the window closing")
	q.dispose(win)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("confirm")
end)

H.section("OpenCopyDialog: read-only box focused with all selected; text put back; focus taken back; one at a time; Close", function()
	local o = Overlay.new()
	local d = Devui.OpenCopyDialog({ Title = "Log", Text = "line 1\nline 2", Overlay = o })
	assert(d.IsOpen:Get() and H.find(o.Layer, "DialogScrim") ~= nil, "no Window: Global")
	local box = H.find(o.Layer, "CopyText") :: any
	assert(box.TextEditable == false and box.MultiLine == true and box:IsFocused(), "focused")
	assert(box.SelectionStart == 1 and box.CursorPosition == #"line 1\nline 2" + 1, "all selected")
	box.Text = "edited"
	assert(box.Text == "line 1\nline 2", "put back")
	box.SelectionStart, box.CursorPosition = 3, 5
	box:ReleaseFocus()
	H.flushDeferred()
	assert(box:IsFocused() and box.SelectionStart == 3 and box.CursorPosition == 5, "taken back with its selection")
	local second = Devui.OpenCopyDialog({ Text = "other", Overlay = o })
	assert(not d.IsOpen:Get() and second.IsOpen:Get(), "one at a time")
	click(H.find(o.Layer, "CloseButton"))
	assert(not second.IsOpen:Get() and o.Count:Get() == 0)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("copy")
end)

H.done()
