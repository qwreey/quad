--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Devui = require("../src")

type Row = { Name: string, Size: number }

local function visibleRows(t: any): { any }
	local rows = H.findAll(t, function(i: any)
		return i.Name == "TableRow" and i.Parent.Visible ~= false
	end)
	table.sort(rows, function(a: any, b: any)
		return a.Parent.Position.Y.Offset < b.Parent.Position.Y.Offset
	end)
	return rows
end

H.section("VirtualTable: columns before the fill from the left, after it from the right; only shown rows exist", function()
	local data: { Row } = {}
	for i = 1, 5000 do
		table.insert(data, { Name = `item{i}`, Size = i * 10 })
	end
	local rows = q.Source(data)
	local selected = q.Source({ ["item2"] = true } :: { [any]: boolean })
	local clicked: { string } = {}
	local t = Devui.VirtualTable({
		Columns = {
			{ Title = "#", Width = 40, Text = function(r: Row): string
				return string.sub(r.Name, 5)
			end },
			{ Title = "Name", Text = function(r: Row): string
				return r.Name
			end },
			{ Title = "Size", Width = 60, Align = Enum.TextXAlignment.Right, Text = function(r: Row): string
				return tostring(r.Size)
			end, Color = function(r: Row): Color3?
				return if r.Size > 20 then Color3.new(1, 0, 0) else nil
			end },
			{ Title = "Kind", Width = 50, Text = function(_r: Row): string
				return "k"
			end },
		},
		Rows = rows,
		Key = function(r: Row): any
			return r.Name
		end,
		SelectedKeys = selected,
		OnRowClick = function(r: Row, index: number)
			table.insert(clicked, `{r.Name}@{index}`)
		end,
		RowHeight = 20,
		RowBg = true,
	})
	local header = H.find(t, "Header") :: any
	assert(header ~= nil and (H.find(header, "Cell2") :: any).Text == "Name")
	-- placement: 40 from the left, then the fill; Size and Kind against the right edge in order
	assert((H.find(header, "Cell1") :: any).Position == UDim2.fromOffset(0, 0))
	assert((H.find(header, "Cell2") :: any).Position == UDim2.fromOffset(40, 0))
	assert((H.find(header, "Cell2") :: any).Size == UDim2.new(1, -150, 1, 0))
	assert((H.find(header, "Cell3") :: any).Position == UDim2.new(1, -110, 0, 0))
	assert((H.find(header, "Cell4") :: any).Position == UDim2.new(1, -50, 0, 0))
	local list = H.find(t, "VirtualRows") :: any
	list.CanvasPosition = Vector2.zero
	list.AbsoluteWindowSize = Vector2.new(300, 100)
	local shown = visibleRows(t)
	assert(#shown >= 5 and #shown <= 8, `only the rows on screen ({#shown})`)
	assert((H.find(shown[1], "Cell2") :: any).Text == "item1" and (H.find(shown[3], "Cell3") :: any).Text == "30")
	assert((H.find(shown[3], "Cell3") :: any).TextColor3 == Color3.new(1, 0, 0), "Color per row")
	assert((H.find(shown[3], "Cell3") :: any).TextXAlignment == Enum.TextXAlignment.Right)
	-- selected row: Header colour; the others striped
	local style = require("../src/Style").default
	assert(shown[2].BackgroundColor3 == style.Color.Header:Get(), "selected row")
	assert(shown[1].BackgroundTransparency == style.Transparency.TableRowBg:Get())
	assert(shown[3].BackgroundColor3 == style.Color.TableRowBg:Get() and shown[4].BackgroundColor3 == style.Color.TableRowBgAlt:Get())
	H.fire(shown[3], "Activated", H.input({}), 1)
	assert(clicked[1] == "item3@3")
	-- hover lights a row
	shown[4].MouseEnter:Fire()
	assert(shown[4].BackgroundColor3 == style.Color.HeaderHovered:Get())
	shown[4].MouseLeave:Fire()
	-- selection and data changes reach the shown rows
	selected:Set({ ["item1"] = true })
	assert(shown[1].BackgroundColor3 == style.Color.Header:Get() and shown[2].BackgroundColor3 ~= style.Color.Header:Get())
	local changed = table.clone(data)
	changed[1] = { Name = "renamed", Size = 1 }
	rows:Set(changed)
	assert((H.find(shown[1], "Cell2") :: any).Text == "renamed")
	q.dispose(t)
	H.assertNoDebugOutput("virtual table")
end)

H.section("VirtualTable: two width-less columns is an error; with none the last column fills; no header", function()
	local ok, err = pcall(function()
		Devui.VirtualTable({
			Columns = {
				{ Title = "a", Text = tostring },
				{ Title = "b", Text = tostring },
			},
			Rows = { 1 },
		})
	end)
	assert(not ok and string.find(tostring(err), "more than one column", 1, true), tostring(err))
	local t = Devui.VirtualTable({
		Columns = { { Title = "a", Width = 30, Text = tostring }, { Title = "b", Width = 20, Text = tostring } },
		Rows = { 1, 2 },
		Header = false,
	})
	assert(H.find(t, "Header") == nil)
	local list = H.find(t, "VirtualRows") :: any
	list.CanvasPosition = Vector2.zero
	list.AbsoluteWindowSize = Vector2.new(100, 100)
	local first = visibleRows(t)[1]
	assert((H.find(first, "Cell2") :: any).Size == UDim2.new(1, -30, 1, 0), "the last column fills")
	q.dispose(t)
end)

H.done()
