--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local Frame = q.Elem "Frame"
local TextBox = q.Elem "TextBox"
local KeyNav = require("../src/KeyNav")

local UIS = H.UserInputService
local function conns(): number
	return #(UIS :: any).InputBegan.connections
end
local base = conns()

local function press(code: Enum.KeyCode, processed: boolean?)
	UIS.InputBegan:Fire(H.input({ KeyCode = code, UserInputType = Enum.UserInputType.Keyboard }), processed == true)
end

H.section("one InputBegan connection only while the host holds selection; closed on lost and on destroy", function()
	local got: { string } = {}
	local ends = 0
	local host = Frame {
		Selectable = true,
		KeyNav.hook(function(input: InputObject)
			table.insert(got, input.KeyCode.Name)
		end, function()
			ends += 1
		end),
	}
	assert(conns() == base, "nothing at rest")
	H.fire(host, "SelectionGained")
	H.fire(host, "SelectionGained") -- idempotent
	assert(conns() == base + 1)
	press(Enum.KeyCode.Left)
	press(Enum.KeyCode.Right, true) -- `processed` is NOT consulted by default
	assert(#got == 2 and got[1] == "Left" and got[2] == "Right")
	H.fire(host, "SelectionLost")
	assert(conns() == base and ends == 1)
	H.fire(host, "SelectionGained")
	q.dispose(host)
	assert(conns() == base, "destroying the host closes it")
	H.assertNoDebugOutput("keynav life")
end)

H.section("Pin: Horizontal (default) pins Left/Right, None pins nothing", function()
	local a = Frame { Selectable = true, KeyNav.hook(function() end) }
	assert(a.NextSelectionLeft == a and a.NextSelectionRight == a and a.NextSelectionUp == nil)
	local b = Frame { Selectable = true, KeyNav.hook(function() end, nil, { Pin = "None" }) }
	assert(b.NextSelectionLeft == nil and b.NextSelectionRight == nil)
	local n: any = Frame { Selectable = true, KeyNav.hook(function() end, nil, { Pin = "None" }) }
	assert(n.NextSelectionUp == nil and n.NextSelectionDown == nil, "None pins nothing (the date grid)")
	local c: any = Frame { Selectable = true, KeyNav.hook(function() end, nil, { Pin = "All" }) }
	assert(c.NextSelectionLeft == c and c.NextSelectionRight == c and c.NextSelectionUp == c and c.NextSelectionDown == c, "All pins four directions")
	q.dispose(a)
	q.dispose(b)
	q.dispose(c)
end)

H.section("a focused TextBox suppresses every key; HonorProcessed drops engine-processed keys", function()
	local got = 0
	local plain = Frame { Selectable = true, KeyNav.hook(function() got += 1 end) }
	local honoring = 0
	local picky = Frame { Selectable = true, KeyNav.hook(function() honoring += 1 end, nil, { Pin = "None", HonorProcessed = true }) }
	H.fire(plain, "SelectionGained")
	H.fire(picky, "SelectionGained")
	press(Enum.KeyCode.Left, true)
	assert(got == 1 and honoring == 0, "processed: delivered by default, dropped when honored")
	press(Enum.KeyCode.Left, false)
	assert(got == 2 and honoring == 1)
	;(UIS :: any).FocusedTextBox = TextBox {}
	press(Enum.KeyCode.Left, false)
	assert(got == 2 and honoring == 1, "typing wins")
	;(UIS :: any).FocusedTextBox = nil
	q.dispose(plain)
	q.dispose(picky)
	assert(conns() == base)
	H.assertNoDebugOutput("keynav keys")
end)

H.section("Engage mode: A engages (pins all four), B disengages and never dismisses a dialog meanwhile", function()
	local got = 0
	local engaged = q.Source(false)
	local host: any = Frame { Selectable = true, KeyNav.hook(function() got += 1 end, nil, { Pin = "Engage", Engaged = engaged }) }
	H.fire(host, "SelectionGained")
	press(Enum.KeyCode.Left)
	assert(got == 0 and host.NextSelectionUp == nil, "not engaged: keys ignored, nothing pinned")
	press(Enum.KeyCode.ButtonA)
	assert(engaged:Get() == true and host.NextSelectionUp == host and host.NextSelectionDown == host)
	press(Enum.KeyCode.Left)
	assert(got == 1)
	press(Enum.KeyCode.ButtonB)
	assert(engaged:Get() == false and host.NextSelectionUp == nil)
	q.dispose(host)
	H.advance(0.1)
	H.assertNoDebugOutput("keynav engage")
end)

H.done()
