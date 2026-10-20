--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local VirtualRows = require("../src/VirtualRows")

local function rows(list: any): { any }
	return H.findAll(list, function(i: any)
		return i.Name == "Row"
	end)
end
local function shownIndices(list: any, builds: { [any]: any }): { number }
	local out = {}
	for _, r in rows(list) do
		if r.Visible ~= false then
			local label = r:GetChildren()[1]
			local i: number = builds[label]:Get()
			table.insert(out, i)
		end
	end
	table.sort(out)
	return out
end

H.section("pool: only the rows in view exist; scrolling rebinds indices, creates and destroys nothing", function()
	local count = q.Source(10000)
	local builds: { [any]: any } = {}
	local made = 0
	local list = VirtualRows({
		Count = count,
		RowHeight = 20,
		Overscan = 0,
		Row = function(index)
			made += 1
			local label = D.TextLabel({
				Size = UDim2.fromScale(1, 1),
				Text = (index :: any):Compute(function(self: any): string
					local i = self:Get()
					return if i then `row {i}` else ""
				end),
			})
			builds[label] = index
			return label
		end,
	})
	assert(#rows(list) == 0, "no rows before layout")
	assert((list :: any).CanvasSize == UDim2.fromOffset(0, 200000))
	;(list :: any).AbsoluteWindowSize = Vector2.new(200, 100)
	-- 100 px / 20 px = 5 rows in view; the pool bound is 5 + 1
	assert(made == 6, `made {made}`)
	local idx = shownIndices(list, builds)
	assert(#idx == 5 and idx[1] == 1 and idx[5] == 5, table.concat(idx, ","))
	;(list :: any).CanvasPosition = Vector2.new(0, 50) -- rows 3..8
	idx = shownIndices(list, builds)
	assert(idx[1] == 3 and idx[#idx] == 8 and made == 6, "rebinding only")
	;(list :: any).CanvasPosition = Vector2.new(0, 100000)
	assert(made == 6 and shownIndices(list, builds)[1] == 5001)
	count:Set(3)
	idx = shownIndices(list, builds)
	assert(#idx == 3 and idx[3] == 3, "fewer rows than the pool: spares hidden")
	q.dispose(list)
	H.assertNoDebugOutput("pool")
end)

H.section("ScrollToRow: the install value is ignored; a row out of view moves the list the least; in view does not move", function()
	local scrollTo = q.Source(500 :: number?)
	local list = VirtualRows({
		Count = q.Source(1000),
		RowHeight = 10,
		Overscan = 1,
		ScrollToRow = scrollTo,
		Row = function(_index)
			return D.Frame({ Size = UDim2.fromScale(1, 1) })
		end,
	})
	;(list :: any).CanvasPosition = Vector2.zero -- the engine always has one; the mock starts with nil
	;(list :: any).AbsoluteWindowSize = Vector2.new(100, 50)
	assert((list :: any).CanvasPosition.Y == 0, "install value ignored")
	scrollTo:Set(20) -- row 20 spans 190..200: bottom edge to the viewport bottom -> 150
	assert((list :: any).CanvasPosition.Y == 150, `{(list :: any).CanvasPosition}`)
	scrollTo:Set(17) -- in view (160..170 within 150..200)
	assert((list :: any).CanvasPosition.Y == 150)
	scrollTo:Set(1)
	assert((list :: any).CanvasPosition.Y == 0)
	q.dispose(list)
	H.assertNoDebugOutput("ScrollToRow")
end)

H.done()
