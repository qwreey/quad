--!strict
-- Table: Rows is a State derived from the RowCount slider (rows are recycled by Id); Borders / RowBg are construction
-- flags, so the table is rebuilt when either control flips (StoryKit.rebuild over a Compute of both).
local Devui = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local Shared = require("./Shared")
local Kids = Devui.Kids

type Row = { Id: number, Name: string, Hp: number }
type Flags = { Borders: boolean, RowBg: boolean }

local NAMES = { "Ada", "Bob", "Cy", "Dee", "Eli", "Fay", "Gus", "Hal" }

return StoryKit.story({
	controls = {
		RowCount = StoryKit.Slider(4, 0, 30, 1),
		Borders = true,
		RowBg = true,
	},
	render = function(c)
		local rows: q.State<{ Row }> = c.RowCount:Compute(function(self)
			local out: { Row } = {}
			for i = 1, math.floor(self:Get()) do
				table.insert(out, { Id = i, Name = NAMES[(i - 1) % #NAMES + 1] :: string, Hp = (i * 37) % 100 })
			end
			return out
		end)
		local flags: q.State<Flags> = c.Borders:Compute(function(self, _prev, rowBg)
			return { Borders = self:Get(), RowBg = rowBg:Get() }
		end, c.RowBg)
		local function text(row: q.State<Row>, col: number): Instance
			local t: q.State<string> = row:Compute(function(self)
				local r = self:Get()
				return if col == 1 then tostring(r.Id) elseif col == 2 then r.Name else tostring(r.Hp)
			end)
			return Devui.Text({ Text = t })
		end
		local tableView = StoryKit.rebuild<<Flags>>(flags, function(f: Flags)
			return Devui.Table<<Row>>({
				Columns = { { Title = "Id", Width = 40 }, { Title = "Name" }, { Title = "Hp", Width = 50 } },
				Rows = rows,
				Key = function(r: Row)
					return r.Id
				end,
				Borders = f.Borders,
				RowBg = f.RowBg,
				Cell = function(row: q.State<Row>, col: number): Instance
					return text(row, col)
				end,
			})
		end, { Size = UDim2.new(1, 0, 0, 420), AutomaticSize = Enum.AutomaticSize.None })
		return Devui.Window({
			Title = "Table",
			Size = q.Source(Vector2.new(360, 480)),
			Children = Kids(Shared.show("rows", c.RowCount), tableView),
		})
	end,
})
