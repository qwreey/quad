--!strict
--[[
	VirtualRows — a virtualized list of fixed-height rows: tens of thousands of rows, but only the rows the viewport
	touches exist as Instances, and scrolling creates and destroys nothing. Ported from devplorer (the user's project)
	— 2026-10-20 user decision: "목록 가상화는 그대로 올려도 될 듯해. 좀만 폴리싱 하고". The arithmetic lives in the internal
	RowWindow module (visible range, slot reuse) and has its own pure spec.

		VirtualRows {
			Count: State<number>,                      -- how many rows there are
			Row: (index: State<number?>) -> Instance,  -- builds ONE pool slot's content, bound to `index` (see below)
			RowHeight: (number | State<number>)?,      -- px; default: style FrameHeight rounded
			Overscan: number?,                         -- extra rows kept above and below the viewport (default 2)
			ScrollToRow: Source<number?>?,             -- write a row index to scroll it into view (see below)
			Style: Style?, Modifier: ModifierInto<ScrollingFrame>?,
		}                                              -> ScrollingFrame

	HOW IT DIFFERS from the other widgets
	  - It is a row FACTORY, not a container: it takes a `Row` builder instead of `Children`.
	  - `ScrollToRow` is a Source the caller writes, like Window's `Open:Set(true)`: quad's `Set` always propagates, so
	    `scrollTo:Set(i)` with the same i scrolls there again. The widget never writes it. The value it holds at install
	    is ignored (the viewport size is not known yet). A row already in view does not move the list; otherwise the
	    list moves the least it takes to bring the row to the nearest edge.
	  - Rows have one fixed height (no variable heights) and touch each other (no ItemSpacing between them).

	THE POOL. Only as many slots as the viewport needs (RowWindow.poolSize, at most Count) are made, and the pool never
	shrinks. A slot is a container Frame ("Row": the widget owns its Position / Size / Visible) holding the Instance
	`Row(index)` made. `Row` runs ONCE per slot and binds its content to the `State<number?>` it gets: scrolling only
	changes that index, the Instances stay. An index of nil (Count shrank, or a spare slot) hides the container. The
	container is the full width x RowHeight, so the Instance `Row` returns should fill it (`Size = UDim2.fromScale(1, 1)`).
	Slots are assigned by RowWindow.assign: a slot whose index is still in view keeps it, only freed slots move.

	ENGINE SIDE. AutomaticCanvasSize is None (the canvas height is Count * RowHeight, set here) and ScrollingDirection
	is Y. The viewport size and scroll position come from `q.OnChange "ScrollingFrame" "AbsoluteWindowSize"` / `"CanvasPosition"`, so
	quad ties those connections to the instance: `q.dispose` / Destroy closes them, and this module opens none itself.
	The real size is known only after layout, so there are no rows before the first layout pass.

	Size is `UDim2.fromScale(1, 1)` of its parent. Inside a Window, wrap it in a Frame that takes the height left over
	(a Modifier cannot carry the UIFlexItem child — Quad0059):
		q.Elem "Frame" ({ Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
			q.Elem "UIFlexItem" ({ FlexMode = Enum.UIFlexMode.Fill }), Devui.VirtualRows({ ... }) })
	(Studio 2026-10-20: 10,000 rows in a 300 x 300 window made 20 row slots; wheel scrolling rebound them, none made.)
]]

local Quad = require("./Quad")
local RowWindow = require("./RowWindow")
local Style = require("./Style")

local q = Quad
local Frame = q.Elem "Frame"
local ScrollingFrame = q.Elem "ScrollingFrame"
local ScrollingFrameModifier = q.Modifier "ScrollingFrame"
local rootName = ScrollingFrameModifier():Name("VirtualRows")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

export type VirtualRowsProps = {
	read Count: State<number>,
	read Row: (index: State<number?>) -> Instance,
	read RowHeight: (number | State<number>)?,
	read Overscan: number?,
	read ScrollToRow: Source<number?>?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<ScrollingFrame>?,
}

type PoolSlot = { Index: Source<number?> }

local DEFAULT_OVERSCAN = 2

-- the row height as a State: a number is fixed, a State is used as is, nothing = the style's frame height rounded
local function resolveRowHeight(given: (number | State<number>)?, style: Style): State<number>
	if type(given) == "number" then
		return q.Source(math.max(1, given))
	elseif given ~= nil then
		return given
	end
	local derived: State<number> = style.FrameHeight:Compute(function(self)
		return math.max(1, math.floor(self:Get() + 0.5))
	end)
	return derived
end

local function VirtualRows(props: VirtualRowsProps): ScrollingFrame
	local style = props.Style or Style.default
	local overscan = math.max(0, props.Overscan or DEFAULT_OVERSCAN)
	local buildRow = props.Row
	local countState = props.Count

	local rowHeight: State<number> = resolveRowHeight(props.RowHeight, style)

	-- inputs read from the engine / the States; update() recomputes the range from these only
	local count = 0
	local viewport = 0
	local scrollY = 0
	local scroller: ScrollingFrame? = nil

	-- the pool: slot containers live in `pool` (a Slot)
	local pool = q.Slot<<Instance>>()
	local slots: { PoolSlot } = {}
	local assigned: { number? } = {}
	local lastFirst, lastLast, lastPool = -1, -1, -1

	local canvasSize: State<UDim2> = countState:Compute(function(self, _prev, height)
		return UDim2.fromOffset(0, RowWindow.canvasHeight(self:Get(), height:Get()))
	end, rowHeight)
	local rowSize: State<UDim2> = rowHeight:Compute(function(self)
		return UDim2.new(1, 0, 0, self:Get())
	end)

	local function addSlot()
		local index = q.Source(nil :: number?)
		local position: State<UDim2> = index:Compute(function(self, _prev, height)
			local i = self:Get()
			return UDim2.fromOffset(0, if i then (i - 1) * height:Get() else 0)
		end, rowHeight)
		local shown: State<boolean> = index:Compute(function(self)
			return self:Get() ~= nil
		end)
		-- the Row builder runs once per slot
		local content = buildRow(index)
		local container = Frame({
			Name = "Row",
			Position = position,
			Size = rowSize,
			Visible = shown,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			content,
		})
		table.insert(slots, { Index = index })
		pool:Add(container)
	end

	local function update()
		local height = rowHeight:Get()
		local first, last = RowWindow.visible(count, height, viewport, scrollY, overscan)
		local want = math.min(count, RowWindow.poolSize(viewport, height, overscan))
		while #slots < want do
			addSlot()
		end
		local size = #slots
		if first == lastFirst and last == lastLast and size == lastPool then
			return
		end
		lastFirst, lastLast, lastPool = first, last, size
		assigned = RowWindow.assign(assigned, size, first, last)
		for i = 1, size do
			slots[i].Index:SetIfChanged(assigned[i])
		end
	end

	-- ScrollToRow: the install run is skipped (the same way as Window's raise-on-open)
	local scrollTo = props.ScrollToRow
	local scrollInstalled = false
	local scrollToObserver = if scrollTo
		then scrollTo:Observer(function(self)
			if not scrollInstalled then
				scrollInstalled = true
				return
			end
			local target = self:Get()
			local frame = scroller
			if target == nil or frame == nil then
				return
			end
			local y = RowWindow.scrollIntoView(target, count, rowHeight:Get(), viewport, scrollY)
			if y ~= scrollY then
				scrollY = y
				frame.CanvasPosition = Vector2.new(frame.CanvasPosition.X, y)
				update()
			end
		end)
		else q.None

	local built = ScrollingFrame({
		rootName,
		-- a shown scrollbar takes its width from the rows instead of covering their right end (a row's ▾ / +). Ref: devplorer U30
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		props.Modifier or q.None,
		scrollToObserver,
		-- the count and the row height change the range (both run once at install)
		countState:Observer(function(self)
			count = math.max(0, math.floor(self:Get()))
			update()
		end),
		rowHeight:Observer(function(_self)
			update()
		end),
		-- the viewport size and the scroll position come from the engine
		q.OnChange "ScrollingFrame" "AbsoluteWindowSize" (function(v: Vector2)
			if v.Y ~= viewport then
				viewport = v.Y
				update()
			end
		end),
		q.OnChange "ScrollingFrame" "CanvasPosition" (function(v: Vector2)
			if v.Y ~= scrollY then
				scrollY = v.Y
				update()
			end
		end),
		Size = UDim2.fromScale(1, 1),
		CanvasSize = canvasSize,
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Active = true,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = style.Metrics.ScrollbarSize,
		ScrollBarImageColor3 = style.Color.ScrollbarGrab,
		ScrollBarImageTransparency = style.Transparency.ScrollbarGrab,
		pool,
	})
	scroller = built
	return built
end

return VirtualRows
