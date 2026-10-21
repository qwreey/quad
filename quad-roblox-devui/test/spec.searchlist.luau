--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Devui = require("../src")
local SearchList = require("../src/SearchList")
local Overlay = require("../src/Overlay")
Overlay.warnUnmounted = false -- (popups on a bare layer)

local UIS = H.UserInputService
local function key(code: Enum.KeyCode)
	UIS.InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = code }), true)
end
local function click(inst: any)
	H.fire(inst, "Activated", H.input({}), 1)
end
-- the shown rows' label texts, in index order (the pool lays them out by Position)
local function shown(layer: any): { string }
	local rows = H.findAll(layer, function(i: any)
		return i.Name == "SearchRow" and i.Parent.Visible ~= false
	end)
	table.sort(rows, function(a: any, b: any)
		return a.Parent.Position.Y.Offset < b.Parent.Position.Y.Offset
	end)
	local out: { string } = {}
	for _, r: any in rows do
		table.insert(out, (H.find(r, "Label") :: any).Text)
	end
	return out
end
local function lit(layer: any): any
	for _, r: any in H.findAll(layer, function(i: any)
		return i.Name == "SearchRow" and i.Parent.Visible ~= false
	end) do
		if r.BackgroundTransparency < 1 then
			return (H.find(r, "Label") :: any).Text
		end
	end
	return nil
end

H.section("filter: case-insensitive substring, prefix matches first, each group in the given order", function()
	local list = SearchList.filter({ "Part", "SpawnLocation", "PartOperation", "Model", "WedgePart" }, "part", tostring, nil)
	local texts: { string } = {}
	for _, r in list do
		table.insert(texts, r.Text)
	end
	assert(table.concat(texts, ",") == "Part,PartOperation,WedgePart", table.concat(texts, ","))
	assert(#SearchList.filter({ "a", "b" }, "", tostring, nil) == 2, "empty query: everything")
end)

H.section("OpenSearchList: typing filters, Up / Down skip blocked rows, Enter / click pick, Escape closes", function()
	local o = Overlay.new()
	local picked: { string } = {}
	local handle = Devui.OpenSearchList({
		At = Rect.new(10, 10, 210, 29),
		Items = { "Part", "Script", "SpawnLocation", "PartOperation", "Model" },
		DisabledReason = function(item: string): string?
			return if item == "Script" then "no script access" else nil
		end,
		ItemIcon = function(item: string): string?
			return "rbxassetid://" .. #item
		end,
		OnPick = function(item: string)
			table.insert(picked, item)
		end,
		Overlay = o,
	})
	assert(handle.IsOpen:Get() and o.Count:Get() == 1)
	local list = H.find(o.Layer, "VirtualRows") :: any
	list.CanvasPosition = Vector2.zero
	list.AbsoluteWindowSize = Vector2.new(200, 200)
	assert(#shown(o.Layer) == 5, `all five ({#shown(o.Layer)})`)
	assert(shown(o.Layer)[2] == "Script  (no script access)", "blocked: the reason after the text")
	assert(lit(o.Layer) == "Part", "the first pickable row is lit")
	key(Enum.KeyCode.Down)
	assert(lit(o.Layer) == "SpawnLocation", `Down skips the blocked row ({lit(o.Layer)})`)
	key(Enum.KeyCode.Up)
	assert(lit(o.Layer) == "Part")
	-- typing filters; the first pickable result is lit again
	local box = H.find(o.Layer, "SearchBox") :: any
	local field = H.findAll(box, function(i: any)
		return i.ClassName == "TextBox"
	end)[1] :: any
	field.Text = "ion"
	assert(table.concat(shown(o.Layer), ",") == "SpawnLocation,PartOperation", table.concat(shown(o.Layer), ","))
	key(Enum.KeyCode.Down)
	field.FocusLost:Fire(true, nil) -- Enter
	assert(picked[1] == "PartOperation" and not handle.IsOpen:Get(), "Enter picks the lit row and closes")
	-- click; a blocked row does nothing; Escape closes
	local again = Devui.OpenSearchList({
		At = Vector2.new(0, 0),
		Items = { "Script", "Model" },
		DisabledReason = function(item: string): string?
			return if item == "Script" then "no" else nil
		end,
		OnPick = function(item: string)
			table.insert(picked, item)
		end,
		Overlay = o,
	})
	local list2 = H.find(o.Layer, "VirtualRows") :: any
	list2.CanvasPosition = Vector2.zero
	list2.AbsoluteWindowSize = Vector2.new(200, 200)
	local rows = H.findAll(o.Layer, function(i: any)
		return i.Name == "SearchRow" and i.Parent.Visible ~= false
	end)
	for _, r: any in rows do
		click(r)
	end
	assert(#picked == 2 and picked[2] == "Model" and not again.IsOpen:Get(), "the blocked row did nothing, Model picked")
	local third = Devui.OpenSearchList({ At = Vector2.zero, Items = { "x" }, OnPick = function() end, Overlay = o })
	key(Enum.KeyCode.Escape)
	assert(not third.IsOpen:Get() and o.Count:Get() == 0)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("search list")
end)

H.section("SearchCombo: the box opens the search list under it; picking writes Value and calls OnChange", function()
	local o = Overlay.new()
	local value = q.Source("Part")
	local changed: { string } = {}
	local combo = Devui.SearchCombo<<string>>({
		Text = "Class",
		Value = value,
		Options = { "Part", "Model", "Folder" },
		OnChange = function(v: string)
			table.insert(changed, v)
		end,
		Overlay = o,
	})
	local box = H.find(combo, "Box") :: any
	assert(box.Text == "Part")
	H.setAbs(box, 10, 10, 150, 19)
	click(box)
	assert(H.find(o.Layer, "SearchList") ~= nil and H.find(o.Layer, "PopupHolder").Position == UDim2.fromOffset(10, 29), "under the box")
	local list = H.find(o.Layer, "VirtualRows") :: any
	list.CanvasPosition = Vector2.zero
	list.AbsoluteWindowSize = Vector2.new(150, 100)
	key(Enum.KeyCode.Down)
	local field = H.findAll(H.find(o.Layer, "SearchBox"), function(i: any)
		return i.ClassName == "TextBox"
	end)[1] :: any
	field.FocusLost:Fire(true, nil)
	assert(value:Get() == "Model" and changed[1] == "Model" and box.Text == "Model" and o.Count:Get() == 0)
	click(box)
	assert(o.Count:Get() == 1)
	click(box)
	assert(o.Count:Get() == 0, "the box toggles it")
	q.dispose(combo)
	q.dispose(o.Layer)
	H.assertNoDebugOutput("search combo")
end)

H.done()
