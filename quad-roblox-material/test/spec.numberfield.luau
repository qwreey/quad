--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local NumberField = require("../src/NumberField")
local Tokens = require("../src/Tokens")

local L = Tokens.Color.Light

local function focus(box: any)
	H.fire(box, "Focused")
end
local function blur(box: any, enter: boolean?)
	H.fire(box, "FocusLost", enter == true, H.input({}))
end
local function typeAndLeave(box: any, text: string, enter: boolean?)
	focus(box)
	box.Text = text
	blur(box, enter)
end

H.section("a unit: the text is the bare number, the unit's prefix / suffix are the field's; commit on blur", function()
	local price = q.Source(1999)
	local changes: { number } = {}
	local nf = NumberField({
		Label = "Price",
		Value = price,
		Unit = { Scale = 0.01, Prefix = "$" },
		Min = 0,
		Step = 1,
		OnChange = function(v: number)
			table.insert(changes, v)
		end,
	})
	assert(nf.ClassName == "Frame" and nf.Name == "TextField", "the TextField host")
	local box = H.find(nf, "Input")
	assert(box.Text == "19.99", "bare number at the unit's precision: " .. box.Text)
	assert(H.find(nf, "Prefix").Text == "$", "the unit's prefix is the field's prefix")
	-- free while focused: nothing is rewritten under the caret
	focus(box)
	box.Text = "5"
	assert(box.Text == "5" and price:Get() == 1999 and #changes == 0, "typing does not write the value")
	blur(box)
	assert(price:Get() == 500 and box.Text == "5.00", "committed and tidied: " .. tostring(price:Get()) .. " / " .. box.Text)
	assert(#changes == 1 and changes[1] == 500, "OnChange once with the new value")
	-- the prefix typed by hand, spaces: read back the same
	typeAndLeave(box, " $ 12.5 ")
	assert(price:Get() == 1250 and box.Text == "12.50")
	-- the same value again: tidied, no OnChange
	typeAndLeave(box, "12.5")
	assert(#changes == 2 and box.Text == "12.50", "no OnChange without a change")
	-- finer than Step: snapped; below Min: clamped
	typeAndLeave(box, "0.014")
	assert(price:Get() == 1 and box.Text == "0.01", "snapped to Step: " .. tostring(price:Get()))
	typeAndLeave(box, "-3")
	assert(price:Get() == 0 and box.Text == "0.00", "clamped to Min")
	q.dispose(nf)
	H.assertNoDebugOutput("unit")
end)

H.section("not a number: nothing is written, the error look until the next edit; empty goes back to the value", function()
	local v = q.Source(10)
	local changes = 0
	local nf = NumberField({
		Value = v,
		Min = 0,
		Max = 100,
		Step = 5,
		InvalidText = "Numbers only",
		OnChange = function()
			changes += 1
		end,
	})
	local box = H.find(nf, "Input")
	assert(box.Text == "10")
	typeAndLeave(box, "ten")
	H.finishTweens()
	assert(v:Get() == 10 and changes == 0 and box.Text == "ten", "the typed text stays, the value too")
	local supporting = H.find(nf, "Supporting")
	assert(supporting ~= nil and supporting.Text == "Numbers only" and supporting.TextColor3 == L.Error, "the error text and color")
	focus(box)
	box.Text = "te"
	H.finishTweens()
	assert(H.find(nf, "Supporting") == nil or H.find(nf, "Supporting").Text ~= "Numbers only", "an edit clears the error look")
	box.Text = ""
	blur(box)
	assert(box.Text == "10" and v:Get() == 10 and changes == 0, "empty: back to the current value, no error")
	typeAndLeave(box, "250")
	assert(v:Get() == 100 and box.Text == "100", "clamped to Max")
	typeAndLeave(box, "42")
	assert(v:Get() == 40 and box.Text == "40", "snapped to Step from Min")
	q.dispose(nf)
	H.assertNoDebugOutput("invalid")
end)

H.section("a programmatic Set shows at once, but not under the caret; Enter submits the committed value", function()
	local v = q.Source(3)
	local submitted: { number } = {}
	local focusLog: { boolean } = {}
	local nf = NumberField({
		Value = v,
		OnSubmit = function(n: number)
			table.insert(submitted, n)
		end,
		OnFocusChanged = function(f: boolean)
			table.insert(focusLog, f)
		end,
	})
	local box = H.find(nf, "Input")
	v:Set(7.25)
	assert(box.Text == "7.25", "no unit, no step: what the value is, without trailing zeros: " .. box.Text)
	focus(box)
	box.Text = "8"
	v:Set(1)
	assert(box.Text == "8", "not rewritten while focused")
	blur(box, true)
	assert(v:Get() == 8 and box.Text == "8" and #submitted == 1 and submitted[1] == 8, "Enter commits the text and submits the value")
	typeAndLeave(box, "x", true)
	assert(#submitted == 1, "no submit for a text that is not a number")
	assert(#focusLog == 4 and focusLog[1] == true and focusLog[2] == false, "OnFocusChanged passes through")
	q.dispose(nf)
	H.assertNoDebugOutput("set")
end)

H.section("own Source, external Error, construction errors", function()
	local nf = NumberField({ Min = 5, Unit = { Scale = 0.1, Suffix = " s" } })
	local box = H.find(nf, "Input")
	assert(box.Text == "0.5" and H.find(nf, "Suffix").Text == " s", "own Source starts at Min: " .. box.Text)
	q.dispose(nf)
	local bad = q.Source(false)
	local nf2 = NumberField({ Value = q.Source(1), Error = bad, ErrorText = "Too low" })
	H.finishTweens()
	local rest = H.find(nf2, "Supporting")
	assert(rest == nil or rest.Text ~= "Too low", "no error text at rest")
	bad:Set(true)
	H.finishTweens()
	assert(H.find(nf2, "Supporting").Text == "Too low", "the external error shows")
	q.dispose(nf2)
	local ok1, err1 = pcall(function()
		return NumberField({ Min = 2, Max = 1 })
	end)
	assert(not ok1 and string.find(tostring(err1), "Max must not be less than Min", 1, true), tostring(err1))
	local ok2, err2 = pcall(function()
		return NumberField({ Step = 0 })
	end)
	assert(not ok2 and string.find(tostring(err2), "Step must be positive", 1, true), tostring(err2))
	local ok3, err3 = pcall(function()
		return NumberField({ Unit = { Scale = 0.3 } })
	end)
	assert(not ok3 and string.find(tostring(err3), "Decimals is required", 1, true), tostring(err3))
	H.assertNoDebugOutput("construction")
end)

H.done()
