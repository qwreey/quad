--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Input = require("../src/Inputs")

local function field(row: any): any
	return H.find(row, "Field")
end
local function lost(box: any, enter: boolean)
	H.fire(box, "FocusLost", enter, H.input({}))
end

H.section("mount: placeholder, label, text from Source", function()
	local v = q.Source("hello")
	local row = Input.InputText({ Text = "Name", Value = v, Placeholder = "type here" })
	local box = field(row)
	assert(box.Text == "hello" and box.PlaceholderText == "type here")
	assert(box.TextEditable == true and box.ClearTextOnFocus == false)
	assert(box.ClipsDescendants == true, "the box clips its text (a long text / a placeholder does not leak)")
	assert((H.find(row, "Label") :: any).Text == "Name")
	-- Frame + TextBox + Label + UIListLayout + UIPadding + UIStroke + UIFlexItem (+ UICorner shorthand)
	assert(H.countDescendants(row) <= 8, `instances: {H.countDescendants(row)}`)
	q.dispose(row)
	H.assertNoDebugOutput("mount")
end)

H.section("change mode: typing writes the Source, :Set updates the box", function()
	local v = q.Source("")
	local writes = 0
	local obs = v:Observer(function()
		writes += 1
	end)
	obs:Subscribe()
	local row = Input.InputText({ Value = v })
	local box = field(row)
	box.Text = "ab"
	assert(v:Get() == "ab")
	box.Text = "abc"
	assert(v:Get() == "abc")
	local before = writes
	v:Set("zzz")
	assert(box.Text == "zzz", "external write reaches the box")
	assert(writes == before + 1, `no echo wave from the box write-back ({writes - before})`)
	q.dispose(row)
	obs:Unsubscribe()
	H.assertNoDebugOutput("change")
end)

H.section("change mode with OnChange: user edits only, after the Source was written", function()
	local v = q.Source("")
	local log: { string } = {}
	local row = Input.InputText({
		Value = v,
		OnChange = function(t)
			table.insert(log, `{t}|{v:Get()}`)
		end,
	})
	local box = field(row)
	box.Text = "x"
	assert(log[1] == "x|x" and #log == 1, table.concat(log, ","))
	v:Set("prog")
	assert(box.Text == "prog" and #log == 1, "programmatic write is not a user change")
	box.Text = "prog2"
	assert(#log == 2 and v:Get() == "prog2")
	q.dispose(row)
	H.assertNoDebugOutput("onchange")
end)

H.section("OnSubmit fires on Enter only", function()
	local v = q.Source("q")
	local got: { string } = {}
	local row = Input.InputText({
		Value = v,
		OnSubmit = function(t)
			table.insert(got, t)
		end,
	})
	local box = field(row)
	box.Text = "query"
	lost(box, false)
	assert(#got == 0, "focus lost without Enter")
	lost(box, true)
	assert(got[1] == "query" and #got == 1)
	q.dispose(row)
	H.assertNoDebugOutput("submit event")
end)

H.section("submit mode: nothing written until FocusLost; one wave per edit", function()
	local v = q.Source("a")
	local waves: { string } = {}
	local obs = v:Observer(function()
		table.insert(waves, v:Get())
	end)
	obs:Subscribe()
	local changes: { string } = {}
	local submits = 0
	local row = Input.InputText({
		Value = v,
		Commit = "submit",
		OnChange = function(t)
			table.insert(changes, t)
		end,
		OnSubmit = function()
			submits += 1
		end,
	})
	local box = field(row)
	table.clear(waves) -- mount-time delivery(ies) are not what is measured
	box.Text = "ab"
	box.Text = "abc"
	assert(v:Get() == "a" and #waves == 0, `keystrokes do not reach the Source: {v:Get()} / {table.concat(waves, ",")}`)
	lost(box, true)
	assert(v:Get() == "abc" and #waves == 1 and changes[1] == "abc" and submits == 1)
	-- unchanged text: no write, no OnChange
	lost(box, false)
	assert(#waves == 1 and #changes == 1)
	-- an external write still shows
	v:Set("ext")
	assert(box.Text == "ext")
	q.dispose(row)
	obs:Unsubscribe()
	H.assertNoDebugOutput("submit mode")
end)

H.section("Disabled: not editable, follows State", function()
	local dis = q.Source(true)
	local row = Input.InputText({ Disabled = dis })
	local box = field(row)
	assert(box.TextEditable == false)
	dis:Set(false)
	assert(box.TextEditable == true)
	q.dispose(row)
	H.assertNoDebugOutput("disabled")
end)

H.section("Focused: true before mount is taken once on screen; two-way; disabled does not take it", function()
	local f = q.Source(true)
	local disabled = q.Source(false)
	local row = Input.InputText({ Focused = f, Disabled = disabled })
	local box = field(row)
	assert(not box:IsFocused(), "not on screen yet: kept, not taken")
	local gui = Instance.new("ScreenGui")
	row.Parent = gui
	H.fire(box, "AncestryChanged", row, gui) -- the engine fires it on descendants too; the mock fires none
	H.flushDeferred()
	assert(not box:IsFocused() and f:Get() == true, "in a ScreenGui that is not placed yet: still kept")
	gui.Parent = H.playerGui()
	H.fire(box, "AncestryChanged", gui, gui.Parent)
	assert(not box:IsFocused(), "not inside the signal (a capture there is lost)")
	H.flushDeferred()
	assert(box:IsFocused() and f:Get() == true, "the ScreenGui was placed: taken")
	f:Set(false)
	assert(not box:IsFocused() and f:Get() == false, "false releases")
	f:Set(true)
	assert(box:IsFocused())
	box:ReleaseFocus() -- the user clicked elsewhere (the engine fires FocusLost)
	assert(f:Get() == false, "the user's blur is written back")
	box:CaptureFocus() -- the user clicked the box
	assert(f:Get() == true, "the user's focus is written back")
	box:ReleaseFocus()
	disabled:Set(true)
	f:Set(true)
	assert(not box:IsFocused(), "a disabled box does not take the focus")
	q.dispose(gui)
	H.assertNoDebugOutput("focused")
end)

H.section("FieldSpread: a Ref, an OnEvent hook and a property reach the inner box; inline keys still win", function()
	local ref = q.Ref<<TextBox?>>(nil)
	local focused = 0
	local spread = q.Spread "TextBox" {
		ref,
		q.OnEvent "TextBox" "Focused" (function()
			focused += 1
		end),
		ClearTextOnFocus = true, -- the box writes ClearTextOnFocus = false inline: the inline key wins
		MaxVisibleGraphemes = 12,
	}
	local row = Input.InputText({ Value = q.Source("x"), FieldSpread = spread })
	local box = field(row)
	assert(ref.Value == box, "the Spread's Ref took the inner box")
	assert(box.MaxVisibleGraphemes == 12, "a property only the Spread sets")
	assert(box.ClearTextOnFocus == false, "an inline key of the box wins over the Spread")
	box:CaptureFocus()
	assert(focused == 1, "the Spread's OnEvent descriptor is bound")
	box:ReleaseFocus()
	q.dispose(row)
	H.assertNoDebugOutput("field spread")
end)

H.section("dispose: destroyed, Source still usable", function()
	local v = q.Source("x")
	local row = Input.InputText({ Value = v })
	local box = field(row)
	q.dispose(row)
	assert(H.isDestroyed(row) and H.isDestroyed(box))
	v:Set("after")
	H.assertNoDebugOutput("dispose")
end)

H.done()
