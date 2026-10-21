--!strict
--[[
	OpenSearchList — a search box over a virtualized list, opened NOW at a point or under a rectangle (an auto-complete
	picker for thousands of items: "insert an Instance class"). SearchCombo (Combo.luau) opens it under its box.
	[2026-10-21 user decision with the devplorer candidate list (devplorer `Popups.Insert`); names by a three-model
	review, audit/naming-devui-2026-10-21e/ — the opener's own name was a three-way tie, provisional.]

		OpenSearchList<T> {
			At: Vector2 | Rect,                      a point (top-left), or a rectangle to open under (its width by default)
			Items: { T } | State<{ T }>,
			Format: ((item: T) -> string)?,          the row text and what the search matches (default tostring)
			ItemIcon: ((item: T) -> string?)?,       an image id shown before the text
			DisabledReason: ((item: T) -> string?)?, a reason the item cannot be picked: the row is dimmed with
			                                         "  (reason)" after its text and picking it does nothing
			OnPick: (item: T) -> (),                 the list closes first, then this runs
			Placeholder: string?,                    the empty search box's hint (default "Search")
			Width: number?, MaxHeight: number?,      px (default: the rectangle's width or 260; 320)
			Overlay: Overlay?, Style: Style?,
		}                                            -> { IsOpen: State<boolean>, Close: (self) -> () }

	SEARCH: case-insensitive plain substring of Format(item); items whose text STARTS with the query come first, each
	group in the given order. KEYS (the search box keeps the focus): Up / Down move the highlighted row (skipping rows
	that cannot be picked), Enter picks it, Escape closes. The pointer over a row highlights it too — one highlight.
	The first row that can be picked is highlighted whenever the results change. A click outside closes it (a popup).
]]

local Overlay = require("./Overlay")
local PopupParts = require("./PopupParts")
local Quad = require("./Quad")
local Style = require("./Style")
local Util = require("./Util")
local VirtualRowsModule = require("./VirtualRows")
local InputText = require("./Inputs/InputText")

local q = Quad
local Frame = q.Elem "Frame"
local ImageLabel = q.Elem "ImageLabel"
local TextButton = q.Elem "TextButton"
local TextLabel = q.Elem "TextLabel"
local UIListLayout = q.Elem "UIListLayout"
local UIPadding = q.Elem "UIPadding"
local FrameModifier = q.Modifier "Frame"

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

export type OpenSearchListProps<T> = {
	read At: Vector2 | Rect,
	read Items: { T } | State<{ T }>,
	read Format: ((item: T) -> string)?,
	read ItemIcon: ((item: T) -> string?)?,
	read DisabledReason: ((item: T) -> string?)?,
	read OnPick: (item: T) -> (),
	read Placeholder: string?,
	read Width: number?,
	read MaxHeight: number?,
	read Overlay: Overlay.Overlay?,
	read Style: Style?,
}

export type SearchListHandle = {
	IsOpen: State<boolean>,
	Close: (self: SearchListHandle) -> (),
}

-- one shown result
type Result = { Item: any, Text: string, Reason: string? }

local SearchList = {}

-- the results for a query: prefix matches first, then the other substring matches, each in the given order
function SearchList.filter(items: { any }, query: string, format: (any) -> string, reason: ((any) -> string?)?): { Result }
	local needle = string.lower(query)
	local first: { Result } = {}
	local rest: { Result } = {}
	for _, item in items do
		local text = format(item)
		local at = if needle == "" then 1 else string.find(string.lower(text), needle, 1, true)
		if at ~= nil then
			table.insert(if at == 1 then first else rest, { Item = item, Text = text, Reason = if reason then reason(item) else nil })
		end
	end
	table.move(rest, 1, #rest, #first + 1, first)
	return first
end

-- the next row from `from` in `step` direction that can be picked (nil: none)
local function nextPickable(results: { Result }, from: number, step: number): number?
	local i = from
	while i >= 1 and i <= #results do
		if results[i].Reason == nil then
			return i
		end
		i += step
	end
	return nil
end

-- the shared opener: SearchCombo passes `onClosed`
function SearchList.open(props: OpenSearchListProps<any>, onClosed: (() -> ())?): SearchListHandle
	local style = props.Style or Style.default
	local overlay = props.Overlay or Overlay.getDefault()
	local format: (any) -> string = props.Format or tostring
	local itemIcon = props.ItemIcon
	local isOpen: Source<boolean> = q.Source(false)
	local popup: Overlay.Popup? = nil
	local handle: SearchListHandle = {
		IsOpen = isOpen,
		Close = function(_self: SearchListHandle)
			local p = popup
			if p then
				p:Close()
			end
		end,
	}
	if not overlay.Alive:Get() then
		return handle
	end
	local at = props.At
	local position: Vector2, rect: Rect, width: number
	if typeof(at) == "Rect" then
		local r = at :: Rect
		position, rect, width = Vector2.new(r.Min.X, r.Max.Y), r, props.Width or math.max(r.Width, 160)
	else
		local p = at :: Vector2
		position, rect, width = p, Rect.new(p, p), props.Width or 260
	end
	local maxHeight = props.MaxHeight or 320

	local items: State<{ any }> = if type(props.Items) == "table" and (props.Items :: any).Get == nil
		then q.Source(props.Items :: { any })
		else props.Items :: State<{ any }>
	local query: Source<string> = q.Source("")
	local results: State<{ Result }> = items:Compute(function(self, _prev, text)
		return SearchList.filter(self:Get(), text:Get(), format, props.DisabledReason)
	end, query)
	local count: State<number> = results:Compute(function(self)
		return #self:Get()
	end)
	local highlight: Source<number?> = q.Source(nextPickable(results:Get(), 1, 1))
	local scrollTo: Source<number?> = q.Source(nil :: number?)

	local function pick(index: number?)
		local r = if index then results:Get()[index] else nil
		if r == nil or r.Reason ~= nil then
			return
		end
		handle:Close()
		props.OnPick(r.Item)
	end
	local function move(step: number)
		local list = results:Get()
		local from = highlight:Get()
		local nextIndex = if from == nil then nextPickable(list, if step > 0 then 1 else #list, step) else nextPickable(list, from + step, step)
		if nextIndex ~= nil then
			highlight:Set(nextIndex)
			scrollTo:Set(nextIndex)
		end
	end

	local rowHeight: State<number> = style.FrameHeight:Compute(function(self)
		return math.max(1, math.floor(self:Get() + 0.5))
	end)
	local listSize: State<UDim2> = count:Compute(function(self, _prev, h)
		return UDim2.new(1, 0, 0, math.max(h:Get(), math.min(self:Get() * h:Get(), maxHeight)))
	end, rowHeight)
	local padX: State<UDim> = Util.pxX(style.Metrics.FramePadding)
	local gap: State<UDim> = Util.pxX(style.Metrics.ItemInnerSpacing)
	local iconSize: State<UDim2> = style.Metrics.TextSize:Compute(function(self)
		return UDim2.fromOffset(self:Get(), self:Get())
	end)
	local headerLook = Style.interactive(style, "Header", q.Source(false), q.Source(false))

	local function row(index: State<number?>): Instance
		local result: State<Result?> = index:Compute(function(self, _prev, list)
			local i = self:Get()
			return if i then list:Get()[i] else nil
		end, results)
		local text: State<string> = result:Compute(function(self)
			local r = self:Get()
			if r == nil then
				return ""
			end
			return if r.Reason then `{r.Text}  ({r.Reason})` else r.Text
		end)
		local blocked: State<boolean> = result:Compute(function(self)
			local r = self:Get()
			return r ~= nil and r.Reason ~= nil
		end)
		local lit: State<number> = index:Compute(function(self, _prev, h, look)
			local i = self:Get()
			return if i ~= nil and i == h:Get() then look:Get() else 1
		end, highlight, headerLook.Transparency)
		local icon: State<string> = result:Compute(function(self)
			local r = self:Get()
			return if r and itemIcon then itemIcon(r.Item) or "" else ""
		end)
		return TextButton({
			Name = "SearchRow",
			Size = UDim2.fromScale(1, 1),
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = headerLook.Color,
			BackgroundTransparency = lit,
			BorderSizePixel = 0,
			MouseEnter = function()
				local i = index:Get()
				if i ~= nil and not blocked:Get() then
					highlight:Set(i)
				end
			end,
			Activated = function()
				pick(index:Get())
			end,
			UIPadding({ PaddingLeft = padX, PaddingRight = padX }),
			UIListLayout({
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = gap,
			}),
			if itemIcon
				then ImageLabel({
					Name = "Icon",
					LayoutOrder = 1,
					Size = iconSize,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Image = icon,
				})
				else q.None,
			TextLabel({
				Name = "Label",
				LayoutOrder = 2,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromScale(0, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = text,
				FontFace = style.Metrics.TextFont,
				TextSize = style.Metrics.TextSize,
				TextColor3 = blocked:Compute(function(self, _prev, normal, dim)
					return if self:Get() then dim:Get() else normal:Get()
				end, style.Color.Text, style.Color.TextDisabled),
				TextTransparency = blocked:Compute(function(self, _prev, normal, dim)
					return if self:Get() then dim:Get() else normal:Get()
				end, style.Transparency.Text, style.Transparency.TextDisabled),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		})
	end

	local focused: Source<boolean> = q.Source(true)
	local content = Frame({
		Name = "SearchList",
		Size = UDim2.fromOffset(width, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = style.Color.PopupBg,
		BackgroundTransparency = style.Transparency.PopupBg,
		BorderSizePixel = 0,
		Active = true,
		UICorner = style.Metrics.PopupRounding,
		PopupParts.stroke(style),
		UIPadding({
			PaddingTop = Util.pxY(style.Metrics.ItemInnerSpacing),
			PaddingBottom = Util.pxY(style.Metrics.ItemInnerSpacing),
		}),
		UIListLayout({
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = Util.pxY(style.Metrics.ItemInnerSpacing),
		}),
		InputText({
			Value = query,
			Placeholder = props.Placeholder or "Search",
			Focused = focused,
			OnSubmit = function()
				pick(highlight:Get())
			end,
			Style = style,
			Modifier = FrameModifier():Name("SearchBox"):LayoutOrder(1),
		}),
		Frame({
			Name = "SearchResults",
			LayoutOrder = 2,
			Size = listSize,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			-- the first pickable row is highlighted whenever the results change
			results:Observer(function(self)
				highlight:Set(nextPickable(self:Get(), 1, 1))
			end),
			VirtualRowsModule.VirtualRows({
				Count = count,
				RowHeight = rowHeight,
				ScrollToRow = scrollTo,
				Row = row,
				Style = style,
			}),
		}),
	})

	local offKeys: (() -> ())? = nil
	popup = overlay:Open({
		Content = content,
		Position = position,
		AnchorRect = rect,
		OnClose = function()
			popup = nil
			isOpen:Set(false)
			local off = offKeys
			if off then
				offKeys = nil
				off()
			end
			if onClosed then
				onClosed()
			end
		end,
	})
	isOpen:Set(true)
	-- Escape closes; Up / Down move the highlight (the search box has the focus, so these arrive as processed input)
	offKeys = PopupParts.onEscape(function()
		handle:Close()
	end, function(input: InputObject)
		if input.KeyCode == Enum.KeyCode.Down then
			move(1)
		elseif input.KeyCode == Enum.KeyCode.Up then
			move(-1)
		end
	end)
	return handle
end

function SearchList.OpenSearchList<T>(props: OpenSearchListProps<T>): SearchListHandle
	return SearchList.open(props :: any)
end

return SearchList
