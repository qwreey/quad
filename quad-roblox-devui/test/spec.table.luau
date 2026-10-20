--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local TableModule = require("../src/Table")
local Table = TableModule.Table
local Text = require("../src/Text")
local Style = require("../src/Style")
local style = Style.default

type Row = { Id: string, Name: string, Hp: number }

local UIS = H.UserInputService
local function conns(): number
	return #(UIS.InputChanged :: any).connections + #(UIS.InputEnded :: any).connections + #(UIS.WindowFocusReleased :: any).connections
end
local function get(root: Instance, name: string): any
	local found = H.find(root, name)
	assert(found ~= nil, `missing {name}`)
	return found
end
local function rowChildren(list: any): { any }
	local out: { any } = {}
	for _, c in list:GetChildren() do
		if c.Name == "Row" then
			table.insert(out, c)
		end
	end
	return out
end
local function rowsOf(tbl: Instance): { any }
	return rowChildren(get(tbl, "Rows"))
end
local function orderOf(tbl: Instance): { string }
	local rows = rowsOf(tbl)
	table.sort(rows, function(a: any, b: any)
		return a.LayoutOrder < b.LayoutOrder
	end)
	local out: { string } = {}
	for _, row in rows do
		-- first cell's first child = name label
		local cells = get(row, "Cells"):GetChildren()
		local label: any = nil
		for _, c in cells do
			if c.Name == "Cell" and c.LayoutOrder == 1 then
				label = c:GetChildren()[1]
				if label.ClassName ~= "TextLabel" then
					label = H.find(c, "Text")
				end
			end
		end
		table.insert(out, label.Text)
	end
	return out
end

local built = 0
type Opts = { RowBg: boolean?, Borders: boolean?, Header: boolean? }
local function newTable(rows: any, opts: Opts?): Frame
	local o: Opts = opts or {}
	return Table({
		Columns = ({ { Title = "Name", Width = 80 }, { Title = q.Source("HP") :: any } } :: { TableModule.Column }),
		Rows = rows,
		Key = function(r: Row)
			return r.Id
		end,
		Cell = function(row: any, col: number): Instance
			built += 1
			if col == 1 then
				return Text.Text({ Text = row:Compute(function(self: any)
					return self:Get().Name
				end) })
			end
			return Text.Text({ Text = row:Compute(function(self: any)
				return tostring(self:Get().Hp)
			end) })
		end,
		RowBg = o.RowBg,
		Borders = o.Borders,
		Header = o.Header,
	})
end

local function data(): { Row }
	return {
		{ Id = "a", Name = "Ann", Hp = 10 },
		{ Id = "b", Name = "Bob", Hp = 20 },
		{ Id = "c", Name = "Cy", Hp = 30 },
	}
end

H.section("Table: header, columns, rows mounted in order", function()
	local rows = q.Source(data())
	local tbl = newTable(rows)
	local header = get(tbl, "Header")
	local titles = get(header, "Cells"):GetChildren()
	local cells: { any } = {}
	for _, c in titles do
		if c.Name == "HeaderCell" then
			cells[c.LayoutOrder] = c
		end
	end
	assert(cells[1].Text == "Name" and cells[2].Text == "HP", "titles (State title too)")
	assert(cells[1].Size == UDim2.fromOffset(80, 0), "fixed width column")
	assert(cells[2].Size == UDim2.fromOffset(0, 0) and H.find(cells[2], "UIFlexItem") ~= nil, "fill column")
	assert(#rowsOf(tbl) == 3)
	local order = orderOf(tbl)
	assert(order[1] == "Ann" and order[2] == "Bob" and order[3] == "Cy", table.concat(order, ","))
	assert(built == 6, `Cell called once per (row, col): {built}`)
	q.dispose(tbl)
	assert(H.isDestroyed(tbl))
	H.assertNoDebugOutput("table mount")
end)

H.section("Table: insert / remove / reorder keep surviving rows (instance identity, no rebuild)", function()
	built = 0
	local base = conns()
	local rows = q.Source(data())
	local tbl = newTable(rows)
	local list = get(tbl, "Rows")
	local before = rowChildren(list)
	local count0 = H.countDescendants(tbl)
	assert(#before == 3 and built == 6)
	-- identify rows by their name label
	local function find(name: string): any
		for _, row in rowChildren(list) do
			for _, lbl in H.findAll(row, function(i: any)
				return i.ClassName == "TextLabel" and i.Text == name
			end) do
				return row
			end
		end
		return nil
	end
	local rowA, rowB, rowC = find("Ann"), find("Bob"), find("Cy")
	assert(rowA and rowB and rowC)

	-- reorder: c, a, b
	rows:Set({ data()[3], data()[1], data()[2] })
	assert(built == 6, "reorder rebuilds nothing")
	assert(find("Ann") == rowA and find("Bob") == rowB and find("Cy") == rowC, "same row instances")
	local order = orderOf(tbl)
	assert(order[1] == "Cy" and order[2] == "Ann" and order[3] == "Bob", table.concat(order, ","))
	assert(H.countDescendants(tbl) == count0)

	-- insert d in the middle
	rows:Set({ data()[3], { Id = "d", Name = "Di", Hp = 40 }, data()[1], data()[2] })
	assert(built == 8, "only the new row builds its two cells")
	assert(find("Cy") == rowC and find("Ann") == rowA)
	order = orderOf(tbl)
	assert(table.concat(order, ",") == "Cy,Di,Ann,Bob", table.concat(order, ","))

	-- remove a: its row dies, the rest survive
	rows:Set({ data()[3], { Id = "d", Name = "Di", Hp = 40 }, data()[2] })
	assert(H.isDestroyed(rowA) and find("Ann") == nil and find("Cy") == rowC)
	assert(table.concat(orderOf(tbl), ",") == "Cy,Di,Bob")
	assert(H.countDescendants(tbl) == count0, "3 rows again -> same instance count")

	-- clear
	rows:Set({})
	assert(#rowChildren(list) == 0)
	q.dispose(tbl)
	assert(conns() == base)
	H.assertNoDebugOutput("table crud")
end)

H.section("Table: ctx.Prev reuse — a changed row value flows through the row State", function()
	built = 0
	local rows = q.Source(data())
	local tbl = newTable(rows)
	local function texts(): { string }
		local out: { string } = {}
		local labels: { any } = H.findAll(get(tbl, "Rows"), function(i: any): boolean
			return i.ClassName == "TextLabel"
		end)
		for _, t in labels do
			table.insert(out, t.Text)
		end
		table.sort(out)
		return out
	end
	assert(table.concat(texts(), ",") == "10,20,30,Ann,Bob,Cy")
	local updated = data()
	updated[2] = { Id = "b", Name = "Bobby", Hp = 99 }
	rows:Set(updated)
	assert(built == 6, "no Cell call for a surviving key")
	assert(table.concat(texts(), ",") == "10,30,99,Ann,Bobby,Cy", table.concat(texts(), ","))
	-- same row tables again: no republish needed, nothing changes
	rows:Set(updated)
	assert(built == 6 and table.concat(texts(), ",") == "10,30,99,Ann,Bobby,Cy")
	q.dispose(tbl)
	H.assertNoDebugOutput("table reuse")
end)

H.section("Table: RowBg zebra, Borders, Header=false, plain array data, duplicate key", function()
	local tbl = newTable(data(), { RowBg = true, Borders = true, Header = false })
	assert(H.find(tbl, "Header") == nil, "Header=false")
	local byOrder: { any } = {}
	for _, row in rowsOf(tbl) do
		byOrder[(row :: any).LayoutOrder] = row
	end
	local alt, normal = style.Transparency.TableRowBgAlt:Get(), style.Transparency.TableRowBg:Get()
	local t1, t2 = byOrder[1].BackgroundTransparency, byOrder[2].BackgroundTransparency
	assert(t1 ~= t2 and (t1 == alt or t1 == normal) and (t2 == alt or t2 == normal), "alternating rows")
	assert(#H.findAll(tbl, function(i: any)
		return i.Name == "RowRule"
	end) == 3, "one hairline per row")
	assert(#H.findAll(tbl, function(i: any)
		return i.Name == "ColumnRule"
	end) == 3, "one per non-last cell")
	assert(H.find(tbl, "UIStroke") ~= nil, "outer stroke")
	q.dispose(tbl)

	local ok = pcall(function()
		newTable({ { Id = "x", Name = "1", Hp = 1 }, { Id = "x", Name = "2", Hp = 2 } })
	end)
	assert(not ok, "duplicate keys are rejected by Slot:List")
	q.debug = true
	H.resetOutput()
end)

H.section("Table: Borders rules are never children of a list-layout parent (a horizontal row would lay them out as items)", function()
	local tbl = newTable(data(), { Borders = true, RowBg = true })
	local function hasLayout(parent: any): boolean
		for _, c in parent:GetChildren() do
			if c.ClassName == "UIListLayout" or c.ClassName == "UIGridLayout" then
				return true
			end
		end
		return false
	end
	local rules = H.findAll(tbl, function(i: any)
		return i.Name == "RowRule" or i.Name == "ColumnRule"
	end)
	assert(#rules == 8, `header: 1 row rule + 1 column rule; rows: 3 + 3 (got {#rules})`)
	for _, rule in rules do
		local parent = (rule :: any).Parent
		assert(parent ~= nil and not hasLayout(parent), `a {(rule :: any).Name} sits under a list-layout parent ({parent.Name})`)
	end
	-- column rules sit on the cell's full edge: shifted out by the CellPadding tokens (the cell frame is padded)
	local pad = (require("../src/Style") :: any).default.Metrics.CellPadding:Get()
	local cols = H.findAll(tbl, function(i: any)
		return i.Name == "ColumnRule"
	end)
	assert(#cols == 4)
	for _, rule in cols do
		local r: any = rule
		assert(r.Position == UDim2.new(1, pad.X, 0, -pad.Y), "rule x/y offset by the padding")
		assert(r.Size == UDim2.new(0, 1, 1, 2 * pad.Y), "rule height = padded area + both vertical paddings")
	end
	-- the cells' own list is a separate Frame: it holds only cells
	local cellLists: { any } = H.findAll(tbl, function(i: any): boolean
		return i.Name == "Cells"
	end)
	for _, cells in cellLists do
		assert(hasLayout(cells))
		for _, c in (cells :: any):GetChildren() do
			assert(c.ClassName == "UIListLayout" or c.Name == "Cell" or c.Name == "HeaderCell", `only cells (and the layout) in the list, got {c.Name}`)
		end
	end
	q.dispose(tbl)
	H.assertNoDebugOutput("table rules")
end)

H.done()
