--!strict
--[[
	Table (Iris: Table) — a keyed, recycled table of rows.

		Table<T> { Columns: { Column },                              -- Column = { Title: string | State<string>, Width: number? }
		           Rows: State<{ T }> | { T },                       -- the data
		           Key: (row: T) -> any,                             -- stable unique identity of a row (duplicates error, like Slot:List)
		           Cell: (row: State<T>, col: number) -> Instance,   -- builds ONE cell's content, called once per (row key, column)
		           Header: boolean?,                                 -- column title row (default true)
		           RowBg: boolean?,                                  -- zebra striping from the TableRowBg / TableRowBgAlt tokens
		           Borders: boolean?,                                -- outer stroke + hairlines between rows and columns
		           Style: Style?, Modifier: ModifierInto<Frame>? }

	No type argument needed: `T` is inferred from the annotated parameter of `Key` (`Key = function(r: Row) ... end`) —
	unlike Combo / ComboArray / RadioButton / SelectableOption, whose `Source<T>` argument forces `Combo<<T>>{ ... }`.

	`Width` is in pixels; columns without one share the remaining width equally (UIFlexItem Fill).

	ROWS ARE RECYCLED BY KEY (Slot:List, through the kit's KeyedSlot). When a key survives a data change its row Frame and all its cell instances are
	kept: `Cell` is NOT called again — instead the `row` State it received is republished when the row value changed
	(`~=`, so replace the row table; mutating it in place is not seen) — bind the cell content to it
	(`row:Compute(function(self) return self:Get().Name end)`). Row order follows the data order through `LayoutOrder`
	(physical reordering is never done); a key that leaves the data destroys its row.

	NO VIRTUALIZATION: every row of `Rows` is built, on screen or not — 3 instances per row plus 4 to 6 per column with a
	one-label cell (3 columns with Borders: about 20 per row, so 500 rows are 10,000 instances and most of a second to build).
	Updates are cheap (a surviving key only republishes its row State), the first build is not: for thousands of rows
	filter or page the `Rows` State yourself. For a long list where only the rows on screen exist, use `VirtualRows` (fixed-height rows, a reused slot pool — nothing is built or destroyed while scrolling); quad's keyed recipe is `docs/how-to/03-long-lists-and-windowing.md` (quad repo).

	DEVIATION FROM THE FIRST SKETCH: `Cell` takes `State<T>`, not `T`, because with a plain `T` a surviving key could never
	show new values.

	Structure: root Frame (vertical) > Header (Frame + a `Cells` Frame with one TextLabel per column) + Rows Frame > per row:
	Row Frame (background) > `Cells` Frame (horizontal list) > per column: Cell Frame (UIPadding = CellPadding, plus
	UIFlexItem for fill columns) holding the `Cell(...)` instance. `Borders` adds one hairline Frame per row and per
	non-last cell. A row's (and the header's) bottom rule is a sibling of its `Cells` list under a Frame WITHOUT a layout
	(a rule placed next to the cells inside the horizontal list would be laid out as one more list item); the column rules
	live inside the cells, which have no layout either.
]]

local Quad = require("./Quad")
local q = Quad
local Frame = q.Elem "Frame"
local TextLabel = q.Elem "TextLabel"
local UIFlexItem = q.Elem "UIFlexItem"
local UIListLayout = q.Elem "UIListLayout"
local UIPadding = q.Elem "UIPadding"
local UIStroke = q.Elem "UIStroke"
local FrameModifier = q.Modifier "Frame"
local tableName = FrameModifier():Name("Table")
local KeyedSlot = require("./KeyedSlot")
local Style = require("./Style")
local Util = require("./Util")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

export type Column = {
	read Title: string | State<string>,
	read Width: number?,
}

export type TableProps<T> = {
	read Columns: { Column },
	read Rows: State<{ T }> | { T },
	read Key: (row: T) -> any,
	read Cell: (row: State<T>, col: number) -> Instance,
	read Header: boolean?,
	read RowBg: boolean?,
	read Borders: boolean?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<Frame>?,
}

local function cellSizing(width: number?): UDim2
	return UDim2.new(0, width or 0, 0, 0)
end

local function Table<T>(props: TableProps<T>): Frame
	local style = props.Style or Style.default
	local columns = props.Columns
	local metrics = style.Metrics
	local cellPadX: State<UDim> = Util.pxX(metrics.CellPadding)
	local cellPadY: State<UDim> = Util.pxY(metrics.CellPadding)
	local borders = props.Borders == true
	local last = #columns
	local keyFn = props.Key
	local cellFn = props.Cell

	-- a column rule is a child of a PADDED cell, so its scale rect is the padded inner area: shift it out by the
	-- padding tokens so it spans the cell's full height and sits on the cell's right edge. The same two States for
	-- every column rule of the table (they depend on the style tokens only): one pair, not one per cell.
	local columnRulePosition: State<UDim2>? = nil
	local columnRuleSize: State<UDim2>? = nil
	if borders and last > 1 then
		columnRulePosition = cellPadX:Compute(function(self, _prev, padY)
			return UDim2.new(1, self:Get().Offset, 0, -padY:Get().Offset)
		end, cellPadY)
		columnRuleSize = cellPadY:Compute(function(self)
			return UDim2.new(0, 1, 1, 2 * self:Get().Offset)
		end)
	end

	local function hairline(vertical: boolean, strong: boolean): Frame
		local color = if strong then style.Color.TableBorderStrong else style.Color.TableBorderLight
		local alpha = if strong then style.Transparency.TableBorderStrong else style.Transparency.TableBorderLight
		local position: UDim2 | State<UDim2> = UDim2.fromScale(0, 1)
		local size: UDim2 | State<UDim2> = UDim2.new(1, 0, 0, 1)
		if vertical and columnRulePosition ~= nil and columnRuleSize ~= nil then
			position = columnRulePosition
			size = columnRuleSize
		end
		return Frame({
			Name = if vertical then "ColumnRule" else "RowRule",
			AnchorPoint = if vertical then Vector2.new(1, 0) else Vector2.new(0, 1),
			Position = position,
			Size = size,
			BackgroundColor3 = color,
			BackgroundTransparency = alpha,
			BorderSizePixel = 0,
			ZIndex = 2,
		})
	end

	-- one cell Frame around `content`
	local function cellFrame(col: number, content: Instance): Frame
		local width = columns[col].Width
		return Frame({
			Name = "Cell",
			LayoutOrder = col,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = cellSizing(width),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			if width then q.None else UIFlexItem({ FlexMode = Enum.UIFlexMode.Fill }),
			UIPadding({ PaddingLeft = cellPadX, PaddingRight = cellPadX, PaddingTop = cellPadY, PaddingBottom = cellPadY }),
			content,
			if borders and col < last then hairline(true, false) else q.None,
		})
	end

	-- the horizontal list of cells; the row's rule is NOT a child of it (see the header)
	local function cellsRow(cells: Quad.Slot<Instance>): Frame
		return Frame({
			Name = "Cells",
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			UIListLayout({
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 0),
			}),
			cells,
		})
	end

	local header: Instance | typeof(q.None) = q.None
	if props.Header ~= false then
		local titles: { Instance } = {}
		for i, col in columns do
			local width = col.Width
			titles[i] = TextLabel({
				Name = "HeaderCell",
				LayoutOrder = i,
				Text = col.Title,
				FontFace = metrics.TextFont,
				TextSize = metrics.TextSize,
				TextColor3 = style.Color.Text,
				TextTransparency = style.Transparency.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundColor3 = style.Color.TableHeader,
				BackgroundTransparency = style.Transparency.TableHeader,
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = cellSizing(width),
				if width then q.None else UIFlexItem({ FlexMode = Enum.UIFlexMode.Fill }),
				UIPadding({
					PaddingLeft = cellPadX,
					PaddingRight = cellPadX,
					PaddingTop = cellPadY,
					PaddingBottom = cellPadY,
				}),
				if borders and i < last then hairline(true, false) else q.None,
			})
		end
		header = Frame({
			Name = "Header",
			LayoutOrder = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			cellsRow(q.Slot(titles)),
			if borders then hairline(false, true) else q.None,
		})
	end

	-- one row per key, kept while its key stays (KeyedSlot): the row's State and its 1-based index
	local rows = KeyedSlot.new(props.Rows, keyFn, function(rowSrc: State<T>, indexSrc: State<number>): Instance
		local bgColor: State<Color3>
		local bgAlpha: State<number>
		if props.RowBg == true then
			bgColor = indexSrc:Compute(function(self, _prev, alt, normal)
				return if self:Get() % 2 == 0 then alt:Get() else normal:Get()
			end, style.Color.TableRowBgAlt, style.Color.TableRowBg)
			bgAlpha = indexSrc:Compute(function(self, _prev, alt, normal)
				return if self:Get() % 2 == 0 then alt:Get() else normal:Get()
			end, style.Transparency.TableRowBgAlt, style.Transparency.TableRowBg)
		else
			bgColor = style.Color.TableRowBg
			bgAlpha = style.Transparency.TableRowBg
		end

		local cells: { Instance } = {}
		for col = 1, last do
			cells[col] = cellFrame(col, cellFn(rowSrc, col))
		end
		return Frame({
			Name = "Row",
			LayoutOrder = indexSrc,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundColor3 = bgColor,
			BackgroundTransparency = bgAlpha,
			BorderSizePixel = 0,
			cellsRow(q.Slot(cells)),
			if borders then hairline(false, false) else q.None,
		})
	end)

	return Frame({
		tableName,
		props.Modifier or q.None,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		UIListLayout({
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 0),
		}),
		if borders
			then UIStroke({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = 1,
				Color = style.Color.TableBorderStrong,
				Transparency = style.Transparency.TableBorderStrong,
			})
			else q.None,
		header,
		Frame({
			Name = "Rows",
			LayoutOrder = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			UIListLayout({
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 0),
			}),
			rows,
		}),
	})
end

return {
	Table = Table,
}
