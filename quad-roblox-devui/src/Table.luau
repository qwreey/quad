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
		           Style: Style?, Modifier: FrameModifier? }

	No type argument needed: `T` is inferred from the annotated parameter of `Key` (`Key = function(r: Row) ... end`) —
	unlike Combo / ComboArray / RadioButton / SelectableOption, whose `Source<T>` argument forces `Combo<<T>>{ ... }`.

	`Width` is in pixels; columns without one share the remaining width equally (UIFlexItem Fill).

	ROWS ARE RECYCLED BY KEY (Slot:List). When a key survives a data change its row Frame and all its cell instances are
	kept: `Cell` is NOT called again — instead the `row` State it received is republished when the row value changed
	(`~=`, so replace the row table; mutating it in place is not seen) — bind the cell content to it
	(`row:Compute(function(self) return self:Get().Name end)`). Row order follows the data order through `LayoutOrder`
	(physical reordering is never done); a key that leaves the data destroys its row.

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
local D = q.Declaration
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
	read Modifier: Quad.FrameModifier?,
}

-- per-row data kept in Slot:List userdata (the reused row's State/Source handles)
type RowUD<T> = { row: Source<T>, index: Source<number> }

type RowCtx<T> = {
	Item: T | Quad.KeyGone,
	Index: number,
	Offset: State<number>,
	Prev: Quad.SlotItem<Instance>?,
	UserData: RowUD<T>?,
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

	local function hairline(vertical: boolean, strong: boolean): Frame
		local color = if strong then style.Color.TableBorderStrong else style.Color.TableBorderLight
		local alpha = if strong then style.Transparency.TableBorderStrong else style.Transparency.TableBorderLight
		-- a column rule is a child of a PADDED cell, so its scale rect is the padded inner area: shift it out by the
		-- padding tokens so it spans the cell's full height and sits on the cell's right edge
		local position: UDim2 | State<UDim2> = UDim2.fromScale(0, 1)
		local size: UDim2 | State<UDim2> = UDim2.new(1, 0, 0, 1)
		if vertical then
			position = cellPadX:Compute(function(self, _prev, padY)
				return UDim2.new(1, self:Get().Offset, 0, -padY:Get().Offset)
			end, cellPadY)
			size = cellPadY:Compute(function(self)
				return UDim2.new(0, 1, 1, 2 * self:Get().Offset)
			end)
		end
		return D.Frame({
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
		return D.Frame({
			Name = "Cell",
			LayoutOrder = col,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = cellSizing(width),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			if width then q.None else D.UIFlexItem({ FlexMode = Enum.UIFlexMode.Fill }),
			D.UIPadding({ PaddingLeft = cellPadX, PaddingRight = cellPadX, PaddingTop = cellPadY, PaddingBottom = cellPadY }),
			content,
			if borders and col < last then hairline(true, false) else q.None,
		})
	end

	-- the horizontal list of cells; the row's rule is NOT a child of it (see the header)
	local function cellsRow(cells: Quad.Slot<Instance>): Frame
		return D.Frame({
			Name = "Cells",
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.UIListLayout({
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
			titles[i] = D.TextLabel({
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
				if width then q.None else D.UIFlexItem({ FlexMode = Enum.UIFlexMode.Fill }),
				D.UIPadding({
					PaddingLeft = cellPadX,
					PaddingRight = cellPadX,
					PaddingTop = cellPadY,
					PaddingBottom = cellPadY,
				}),
				if borders and i < last then hairline(true, false) else q.None,
			})
		end
		header = D.Frame({
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

	local rows = q.Slot<<Instance>>()
	rows:List<<T, RowUD<T>>>(props.Rows, function(ctx: RowCtx<T>): (any, RowUD<T>?)
		if ctx.Item == q.KeyGone then
			return nil, nil
		end
		local item = ctx.Item :: T
		local prev, ud = ctx.Prev, ctx.UserData
		if prev and ud then
			ud.row:SetIfChanged(item)
			ud.index:SetIfChanged(ctx.Index)
			return prev, ud
		end

		local rowSrc: Source<T> = q.Source(item)
		local indexSrc: Source<number> = q.Source(ctx.Index)
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
		local row = D.Frame({
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
		return row, { row = rowSrc, index = indexSrc }
	end, function(item: T, _i: number): any
		return keyFn(item)
	end)

	return D.Frame({
		props.Modifier or q.None,
		Name = "Table",
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		D.UIListLayout({
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 0),
		}),
		if borders
			then D.UIStroke({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = 1,
				Color = style.Color.TableBorderStrong,
				Transparency = style.Transparency.TableBorderStrong,
			})
			else q.None,
		header,
		D.Frame({
			Name = "Rows",
			LayoutOrder = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.UIListLayout({
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
