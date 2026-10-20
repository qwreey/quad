--!strict
--[[
	Combo — a drop-down choice (Iris: Combo + Selectable rows).

		Combo<T>      { Text: string | State<string>,         -- the label after the box (Iris convention: the trailing
		                                                      --   label of an input / combo is `Text`)
		                Value: Source<T>,                      -- the chosen option (two-way; REQUIRED)
		                Options: { T } | State<{ T }>,         -- distinct values (they are the list keys)
		                Format: ((T) -> string)?,              -- option -> row text (default tostring)
		                OnChange: ((value: T) -> ())?,         -- after the USER picked a different option (not for :Set)
		                Disabled: (boolean | State<boolean>)?, -- the box neither opens nor shows hover colours
		                Overlay: Overlay?, MaxHeight: number?, Style: Style?, Modifier: FrameModifier? }
		ComboArray<T> { Text, Index: Source<number>, Options: { T } | State<{ T }>, Format?, OnChange: ((index, item) -> ())?, ... }
		                the same, but the Source holds the 1-based INDEX into Options (duplicates are fine)
		ComboEnum     { Text, Value: Source<EnumItem>, Enum: Enum, Format?, OnChange: ((EnumItem) -> ())?, ... }
		              options = Enum:GetEnumItems()

	Call `Combo<<T>>{ ... }` / `ComboArray<<T>>{ ... }` with the type argument — the solver cannot infer `T` from a
	`Source<T>` argument (typing-limits: a generic call that takes a `Source<T>` does not infer).

	NO VIRTUALIZATION: every open builds one row per option (a `Slot:List` keyed by option) inside a ScrollingFrame capped at
	MaxHeight — fine for tens or a few hundred options, but a list of thousands makes the open slow and heavy; filter the
	`Options` State (e.g. by a search box) or page it yourself for such lists. For a long list where only the rows on screen exist, use `VirtualRows` (fixed-height rows, a reused slot pool — nothing is built or destroyed while scrolling); quad's keyed recipe is `docs/how-to/03-long-lists-and-windowing.md` (quad repo).

	Structure: root Frame (row) > Box (TextButton: preview text + arrow image) + label. Clicking the box opens the list in
	the Overlay under the box (position and width read from the box's AbsolutePosition / AbsoluteSize at open time); the
	list is a ScrollingFrame of rows (PopupParts.row, `Slot:List` over the options) capped at MaxHeight (default 200).
	Choosing a row writes the Source and closes; Escape, a click outside (the Overlay's catcher) and destroying the Combo
	close it too. Every open builds a fresh list (the Overlay owns and destroys it), so a closed Combo holds nothing but
	the box. While open, a changing `Options` State updates the list in place.

	Escape is listened for only while the list is open (one UserInputService.InputBegan connection, closed on close).
	Hiding the box or an ancestor of it (closing the window the Combo is in) closes the list too (watched only while open).
]]

local Quad = require("./Quad")
local q = Quad
local D = q.Declaration
local comboName = D.Modifier.Frame():Name("Combo")
local Common = require("./Common")
local Interaction = require("./Interaction")
local Overlay = require("./Overlay")
local PopupParts = require("./PopupParts")
local Style = require("./Style")
local Text = require("./Text")
local Util = require("./Util")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

export type ComboProps<T> = {
	read Text: string | State<string>,
	read Value: Source<T>,
	read Options: { T } | State<{ T }>,
	read Format: ((T) -> string)?,
	read OnChange: ((value: T) -> ())?,
	read Disabled: (boolean | State<boolean>)?,
	read Overlay: Overlay.Overlay?,
	read MaxHeight: number?,
	read Style: Style?,
	read Modifier: Quad.FrameModifier?,
}

export type ComboArrayProps<T> = {
	read Text: string | State<string>,
	read Index: Source<number>,
	read Options: { T } | State<{ T }>,
	read Format: ((T) -> string)?,
	read OnChange: ((index: number, item: T) -> ())?,
	read Disabled: (boolean | State<boolean>)?,
	read Overlay: Overlay.Overlay?,
	read MaxHeight: number?,
	read Style: Style?,
	read Modifier: Quad.FrameModifier?,
}

export type ComboEnumProps = {
	read Text: string | State<string>,
	read Value: Source<EnumItem>,
	read Enum: Enum,
	read Format: ((EnumItem) -> string)?,
	read OnChange: ((item: EnumItem) -> ())?,
	read Disabled: (boolean | State<boolean>)?,
	read Overlay: Overlay.Overlay?,
	read MaxHeight: number?,
	read Style: Style?,
	read Modifier: Quad.FrameModifier?,
}

-- one list row: `Key` identifies it (a value for Combo, an index for ComboArray), `Label` is its text
type Entry = { Key: any, Label: string }

type CoreSpec = {
	Text: string | State<string>,
	Preview: State<string>,
	Entries: State<{ Entry }>,
	-- the key of the current choice
	SelectedKey: State<any>,
	OnPick: (key: any) -> (),
	Disabled: (boolean | State<boolean>)?,
	Overlay: Overlay.Overlay?,
	MaxHeight: number?,
	Style: Style?,
	Modifier: Quad.FrameModifier?,
}

type RowUD = { label: Source<string> }
type RowCtx = {
	Item: Entry | Quad.KeyGone,
	Index: number,
	Offset: State<number>,
	Prev: Quad.SlotItem<Instance>?,
	UserData: RowUD?,
}

local Combo = {}

local function core(spec: CoreSpec): Frame
	local style = spec.Style or Style.default
	local maxHeight = spec.MaxHeight or 200
	local enabled = Common.enabled(spec.Disabled)
	local hover = Interaction.hover()
	local look = Common.fieldLook(style, hover, enabled)
	local textLook = Common.textLook(style, enabled)

	-- the open popup (nil while closed)
	local popup: Overlay.Popup? = nil
	-- assigned right after the element is built; read only from event handlers
	local box: TextButton? = nil

	local function close()
		local p = popup
		if p then
			p:Close()
		end
	end

	local function buildList(width: number): ScrollingFrame
		local rows = q.Slot<<Instance>>()
		rows:List(spec.Entries, function(ctx: RowCtx): (any, RowUD?)
			if ctx.Item == q.KeyGone then
				return nil
			end
			local entry = ctx.Item :: Entry
			local prev, ud = ctx.Prev, ctx.UserData
			if prev and ud then
				ud.label:SetIfChanged(entry.Label)
				return prev, ud
			end
			local label: Source<string> = q.Source(entry.Label)
			local key = entry.Key
			local selected: State<boolean> = spec.SelectedKey:Compute(function(self)
				return self:Get() == key
			end)
			local row = PopupParts.row({
				Style = style,
				Name = "Option",
				Text = label,
				Selected = selected,
				Width = "Fill",
				OnClick = function()
					-- close first (as Menu's closeThen): an OnPick that throws must not leave the list — and its
					-- full-screen click catcher — open
					close()
					spec.OnPick(key)
				end,
			})
			return row, { label = label }
		end, function(entry: Entry): any
			return entry.Key
		end)

		return D.ScrollingFrame({
			Name = "ComboList",
			Size = UDim2.fromOffset(width, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.fromOffset(0, 0),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = style.Metrics.ScrollbarSize,
			ScrollBarImageColor3 = style.Color.ScrollbarGrab,
			ScrollBarImageTransparency = style.Transparency.ScrollbarGrab,
			BackgroundColor3 = style.Color.PopupBg,
			BackgroundTransparency = style.Transparency.PopupBg,
			BorderSizePixel = 0,
			Active = true,
			UICorner = style.Metrics.PopupRounding,
			PopupParts.stroke(style),
			D.UISizeConstraint({ MaxSize = Vector2.new(math.huge, maxHeight) }),
			D.UIListLayout({
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			rows,
		})
	end

	local function open()
		local anchor = box
		if popup or anchor == nil or not enabled:Get() then
			return
		end
		-- resolved now, not at construction: a rebuilt default overlay is picked up
		local overlay = spec.Overlay or Overlay.getDefault()
		if not overlay.Alive:Get() then
			return
		end
		local pos, size = anchor.AbsolutePosition, anchor.AbsoluteSize
		local disconnectEscape: (() -> ())? = nil
		popup = overlay:Open({
			Content = buildList(size.X),
			Position = Vector2.new(pos.X, pos.Y + size.Y),
			OnClose = function()
				popup = nil
				local off = disconnectEscape
				if off then
					disconnectEscape = nil
					off()
				end
			end,
		})
		disconnectEscape = PopupParts.whileOpen(anchor, close)
	end

	local padX: State<UDim> = Util.pxX(style.Metrics.FramePadding)
	local padY: State<UDim> = Util.pxY(style.Metrics.FramePadding)
	-- room for the arrow on the right of the preview text
	local padRight: State<UDim> = style.Metrics.TextSize:Compute(function(self, _prev, pad)
		return UDim.new(0, self:Get() + pad:Get().X * 2)
	end, style.Metrics.FramePadding)
	local boxSize: State<UDim2> = style.Metrics.ContentWidth:Compute(function(self)
		local w = self:Get()
		return UDim2.new(w.Scale, w.Offset, 0, 0)
	end)
	local arrowSize: State<UDim2> = style.Metrics.TextSize:Compute(function(self)
		local s = math.floor(self:Get() * 0.8)
		return UDim2.fromOffset(s, s)
	end)
	-- the arrow sits in the reserved right strip: anchored to the padded content's right edge, pushed out by the strip
	local arrowPos: State<UDim2> = style.Metrics.TextSize:Compute(function(self, _prev, pad)
		return UDim2.new(1, self:Get() + pad:Get().X, 0.5, 0)
	end, style.Metrics.FramePadding)

	box = D.TextButton({
		hover.Hook,
		Name = "Box",
		Text = spec.Preview,
		FontFace = style.Metrics.TextFont,
		TextSize = style.Metrics.TextSize,
		TextColor3 = textLook.Color,
		TextTransparency = textLook.Transparency,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = look.Color,
		BackgroundTransparency = look.Transparency,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = boxSize,
		LayoutOrder = 1,
		Activated = function()
			if popup then
				close()
			elseif enabled:Get() then
				open()
			end
		end,
		UICorner = style.Metrics.FrameRounding,
		D.UIPadding({ PaddingLeft = padX, PaddingRight = padRight, PaddingTop = padY, PaddingBottom = padY }),
		D.ImageLabel({
			Name = "Arrow",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = arrowPos,
			Size = arrowSize,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = style.Icons.DownTriangle,
			ImageColor3 = style.Color.Text,
			ImageTransparency = style.Transparency.Text,
		}),
	})

	return D.Frame({
		comboName,
		spec.Modifier or q.None,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		D.UIListLayout({
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = Util.pxX(style.Metrics.ItemInnerSpacing),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		box :: TextButton,
		Text.Text({ Text = spec.Text, Style = style, Modifier = D.Modifier.TextLabel():LayoutOrder(2) }),
		q.OnDestroyed(function()
			close()
		end),
	})
end

local function toState<T>(options: { T } | State<{ T }>): State<{ T }>
	if q.isState(options) then
		return options :: State<{ T }>
	end
	return q.Source(options :: { T })
end

local function tostr(v: any): string
	return tostring(v)
end

function Combo.Combo<T>(props: ComboProps<T>): Frame
	local value = props.Value
	local onChange = props.OnChange
	local options = toState(props.Options)
	local format: (T) -> string = props.Format or tostr
	local entries: State<{ Entry }> = options:Compute(function(self)
		local out: { Entry } = {}
		for _, item in self:Get() do
			table.insert(out, { Key = item, Label = format(item) })
		end
		return out
	end)
	local preview: State<string> = value:Compute(function(self)
		return format(self:Get())
	end)
	return core({
		Text = props.Text,
		Preview = preview,
		Entries = entries,
		-- `:: any`: core takes State<any> keys; the generic T cannot be widened to any here without a cast (quad: State<T> is invariant)
		SelectedKey = value :: any,
		OnPick = function(key: any)
			if value:Get() ~= key then
				value:Set(key :: T)
				if onChange then
					onChange(key :: T)
				end
			end
		end,
		Disabled = props.Disabled,
		Overlay = props.Overlay,
		MaxHeight = props.MaxHeight,
		Style = props.Style,
		Modifier = props.Modifier,
	})
end

function Combo.ComboArray<T>(props: ComboArrayProps<T>): Frame
	local index = props.Index
	local onChange = props.OnChange
	local options = toState(props.Options)
	local format: (T) -> string = props.Format or tostr
	local entries: State<{ Entry }> = options:Compute(function(self)
		local out: { Entry } = {}
		for i, item in self:Get() do
			table.insert(out, { Key = i, Label = format(item) })
		end
		return out
	end)
	-- preview follows both the index and the options (an option changing under the same index shows up)
	local preview: State<string> = index:Compute(function(self, _prev, opts)
		local item = opts:Get()[self:Get()]
		return if item == nil then "" else format(item)
	end, options)
	return core({
		Text = props.Text,
		Preview = preview,
		Entries = entries,
		SelectedKey = index :: any, -- `:: any`: same reason as ComboEnum's SelectedKey cast (State<number> -> State<any>, invariant)
		OnPick = function(key: any)
			if index:Get() ~= key then
				index:Set(key :: number)
				if onChange then
					onChange(key :: number, options:Get()[key :: number])
				end
			end
		end,
		Disabled = props.Disabled,
		Overlay = props.Overlay,
		MaxHeight = props.MaxHeight,
		Style = props.Style,
		Modifier = props.Modifier,
	})
end

local function enumName(item: EnumItem): string
	return item.Name
end

function Combo.ComboEnum(props: ComboEnumProps): Frame
	return Combo.Combo<<EnumItem>>({
		Text = props.Text,
		Value = props.Value,
		Options = props.Enum:GetEnumItems(),
		Format = props.Format or enumName,
		OnChange = props.OnChange,
		Disabled = props.Disabled,
		Overlay = props.Overlay,
		MaxHeight = props.MaxHeight,
		Style = props.Style,
		Modifier = props.Modifier,
	})
end

return Combo
