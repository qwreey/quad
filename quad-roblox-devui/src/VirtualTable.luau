--!strict
--[[
	VirtualTable — a table whose rows are virtualized (VirtualRows underneath): a header row, then fixed-height rows
	of text cells; tens of thousands of rows, only the ones on screen exist. Ported in shape from devplorer
	(`InspectUi.listRows` / `header`) — 2026-10-21 user decision with the candidate list, kept apart from `Table`
	(which builds every row and lets a cell be any Instance: a different model); names by a three-model review,
	audit/naming-devui-2026-10-21e/.

		VirtualTable<T> {
			Columns: { VirtualColumn<T> },
			Rows: { T } | State<{ T }>,
			Key: ((row: T) -> any)?,                     identity for SelectedKeys (default: the row value itself)
			SelectedKeys: State<{ [any]: boolean }>?,    keys of the rows drawn selected
			OnRowClick: ((row: T, index: number) -> ())?,
			RowHeight: number?,                          px (default: the style's frame height)
			Header: boolean?,                            the title row (default true)
			RowBg: boolean?,                             zebra striping (TableRowBg / TableRowBgAlt)
			Follow: boolean?, ScrollToRow: Source<number?>?,   as VirtualRows
			Style: Style?, Modifier: ModifierInto<Frame>?,
		}                                                -> Frame (fills its parent: give it a sized parent)

		VirtualColumn<T> = { Title: string, Width: number?, Text: (row: T) -> string,
		                     Align: Enum.TextXAlignment?, Color: ((row: T) -> Color3?)? }

	COLUMNS: one column without a Width fills what is left (with none, the last column fills); the columns before it
	are laid from the left edge, the ones after it from the right edge — a narrow "value" column stays against the
	right side however wide the table is. Text is truncated with an ellipsis inside its cell. More than one column
	without a Width is an error (which one fills would be a guess).
	ROWS: hover and selection use the Header colours (as Selectable); a row's click calls OnRowClick. The list is
	`Devui.VirtualRows` (its scroll frame is named "VirtualRows"), so `Devui.RowIndexAt(list, y)` works on it.
]]

local Quad = require("./Quad")
local Style = require("./Style")
local Util = require("./Util")
local VirtualRowsModule = require("./VirtualRows")

local q = Quad
local Frame = q.Elem "Frame"
local TextButton = q.Elem "TextButton"
local TextLabel = q.Elem "TextLabel"
local UIFlexItem = q.Elem "UIFlexItem"
local UIListLayout = q.Elem "UIListLayout"
local UIPadding = q.Elem "UIPadding"
local FrameModifier = q.Modifier "Frame"
local rootName = FrameModifier():Name("VirtualTable")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

export type VirtualColumn<T> = {
	read Title: string,
	read Width: number?,
	read Text: (row: T) -> string,
	read Align: Enum.TextXAlignment?,
	read Color: ((row: T) -> Color3?)?,
}

export type VirtualTableProps<T> = {
	read Columns: { VirtualColumn<T> },
	read Rows: { T } | State<{ T }>,
	read Key: ((row: T) -> any)?,
	read SelectedKeys: State<{ [any]: boolean }>?,
	read OnRowClick: ((row: T, index: number) -> ())?,
	read RowHeight: number?,
	read Header: boolean?,
	read RowBg: boolean?,
	read Follow: boolean?,
	read ScrollToRow: Source<number?>?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<Frame>?,
}

-- each column's Position / Size inside a row (header COLUMNS)
local function placeColumns(columns: { VirtualColumn<any> }): { { Position: UDim2, Size: UDim2 } }
	local fill: number? = nil
	for i, column in columns do
		if column.Width == nil then
			if fill ~= nil then
				error("Devui.VirtualTable: more than one column without a Width (which one fills would be a guess)", 3)
			end
			fill = i
		end
	end
	local fillAt = fill or #columns
	local left, right = 0, 0
	for i, column in columns do
		if i < fillAt then
			left += column.Width or 0
		elseif i > fillAt then
			right += column.Width or 0
		end
	end
	local out: { { Position: UDim2, Size: UDim2 } } = {}
	local x = 0
	local fromRight = right
	for i, column in columns do
		if i < fillAt then
			out[i] = { Position = UDim2.fromOffset(x, 0), Size = UDim2.new(0, column.Width or 0, 1, 0) }
			x += column.Width or 0
		elseif i == fillAt then
			out[i] = { Position = UDim2.fromOffset(left, 0), Size = UDim2.new(1, -(left + right), 1, 0) }
		else
			out[i] = { Position = UDim2.new(1, -fromRight, 0, 0), Size = UDim2.new(0, column.Width or 0, 1, 0) }
			fromRight -= column.Width or 0
		end
	end
	return out
end

local function VirtualTable<T>(props: VirtualTableProps<T>): Frame
	local style = props.Style or Style.default
	local columns = props.Columns
	local places = placeColumns(columns :: any)
	local key: (any) -> any = props.Key or function(row: any): any
		return row
	end
	local selected = props.SelectedKeys
	local onRowClick = props.OnRowClick
	local rows: State<{ T }> = if type(props.Rows) == "table" and (props.Rows :: any).Get == nil
		then q.Source(props.Rows :: { T })
		else props.Rows :: State<{ T }>
	local count: State<number> = rows:Compute(function(self)
		return #self:Get()
	end)
	local rowHeight: State<number> = if props.RowHeight
		then q.Source(props.RowHeight)
		else style.FrameHeight:Compute(function(self)
			return math.max(1, math.floor(self:Get() + 0.5))
		end)
	local headerSize: State<UDim2> = rowHeight:Compute(function(self)
		return UDim2.new(1, 0, 0, self:Get())
	end)
	local cellPadX: State<UDim> = Util.pxX(style.Metrics.CellPadding)
	local hovered: Source<number?> = q.Source(nil :: number?)
	local noSelection: State<{ [any]: boolean }> = q.Source({})
	local selectedSet = selected or noSelection

	local function cell(i: number, text: State<string> | string, color: State<Color3> | Color3, transparency: any): TextLabel
		local column = columns[i]
		return TextLabel({
			Name = `Cell{i}`,
			Position = places[i].Position,
			Size = places[i].Size,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Text = text,
			TextTruncate = Enum.TextTruncate.AtEnd,
			FontFace = style.Metrics.TextFont,
			TextSize = style.Metrics.TextSize,
			TextColor3 = color,
			TextTransparency = transparency,
			TextXAlignment = column.Align or Enum.TextXAlignment.Left,
			UIPadding({ PaddingLeft = cellPadX, PaddingRight = cellPadX }),
		})
	end

	local function row(index: State<number?>): Instance
		local value: State<T?> = index:Compute(function(self, _prev, list)
			local i = self:Get()
			return if i then list:Get()[i] else nil
		end, rows)
		local cells: { Instance } = {}
		for i, column in columns do
			local text: State<string> = value:Compute(function(self)
				local r = self:Get()
				return if r ~= nil then column.Text(r) else ""
			end)
			local colorOf = column.Color
			local color: State<Color3> = if colorOf
				then value:Compute(function(self, _prev, normal)
					local r = self:Get()
					return (if r ~= nil then colorOf(r) else nil) or normal:Get()
				end, style.Color.Text)
				else style.Color.Text
			table.insert(cells, cell(i, text, color, style.Transparency.Text))
		end
		-- the background: selected or hovered -> Header colours, else the zebra stripe (or nothing)
		local isSelected: State<boolean> = value:Compute(function(self, _prev, set)
			local r = self:Get()
			return r ~= nil and set:Get()[key(r)] == true
		end, selectedSet)
		local isHovered: State<boolean> = index:Compute(function(self, _prev, h)
			local i = self:Get()
			return i ~= nil and i == h:Get()
		end, hovered)
		local bgColor: State<Color3> = isSelected:Compute(function(self, _prev, hov, header, headerHovered, alt, plain, i)
			if self:Get() then
				return if hov:Get() then headerHovered:Get() else header:Get()
			elseif hov:Get() then
				return headerHovered:Get()
			end
			local n = i:Get()
			return if n ~= nil and n % 2 == 0 then alt:Get() else plain:Get()
		end, isHovered, style.Color.Header, style.Color.HeaderHovered, style.Color.TableRowBgAlt, style.Color.TableRowBg, index)
		local stripes = props.RowBg == true
		local bgAlpha: State<number> = isSelected:Compute(function(self, _prev, hov, header, alt, plain, i)
			if self:Get() or hov:Get() then
				return header:Get()
			elseif not stripes then
				return 1
			end
			local n = i:Get()
			return if n ~= nil and n % 2 == 0 then alt:Get() else plain:Get()
		end, isHovered, style.Transparency.Header, style.Transparency.TableRowBgAlt, style.Transparency.TableRowBg, index)
		return TextButton({
			Name = "TableRow",
			Size = UDim2.fromScale(1, 1),
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = bgColor,
			BackgroundTransparency = bgAlpha,
			BorderSizePixel = 0,
			MouseEnter = function()
				hovered:Set(index:Get())
			end,
			MouseLeave = function()
				if hovered:Get() == index:Get() then
					hovered:Set(nil)
				end
			end,
			Activated = function()
				local i = index:Get()
				local r = value:Get()
				if onRowClick and i ~= nil and r ~= nil then
					onRowClick(r, i)
				end
			end,
			q.Slot<<Instance>>(cells),
		})
	end

	local header: Instance | typeof(q.None) = q.None
	if props.Header ~= false then
		local titles: { Instance } = {}
		for i, column in columns do
			table.insert(titles, cell(i, column.Title, style.Color.Text, style.Transparency.Text))
		end
		header = Frame({
			Name = "Header",
			LayoutOrder = 1,
			Size = headerSize,
			BackgroundColor3 = style.Color.TableHeader,
			BackgroundTransparency = style.Transparency.TableHeader,
			BorderSizePixel = 0,
			q.Slot<<Instance>>(titles),
		})
	end

	return Frame({
		rootName,
		props.Modifier or q.None,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		UIListLayout({
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		header,
		Frame({
			Name = "Body",
			LayoutOrder = 2,
			Size = UDim2.fromScale(1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			UIFlexItem({ FlexMode = Enum.UIFlexMode.Fill }),
			VirtualRowsModule.VirtualRows({
				Count = count,
				RowHeight = rowHeight,
				Row = row,
				Follow = props.Follow,
				ScrollToRow = props.ScrollToRow,
				Style = style,
			}),
		}),
	})
end

return VirtualTable
