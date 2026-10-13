--!strict
--[[
	M3 list: `ListItem` (one / two / three-line row) and `List` (the vertical container, static children or keyed data).

	    List({ Children = q.Slot<<Instance>>({ ListItem({ Headline = "Inbox", Leading = "rbxassetid://1", OnClick = open }),
	                                           Divider({ Inset = "Start" }), ListItem({ ... }) }) })
	    ListData({ Items = emails, Key = function(e) return e.Id end,
	               Render = function(email, index)       -- email: State<Email> (follows data edits), index: State<number>
	                   return ListItem({ Headline = email:Compute(...), LayoutOrder = index, OnClick = ... })
	               end })

	ListItem props (all `read`):
	  Headline    string | State<string>                       BodyLarge, onSurface (single line, truncated)
	  Supporting  (string | State<string>)?                    BodyMedium, onSurfaceVariant
	  Overline    (string | State<string>)?                    LabelSmall, onSurfaceVariant
	  Lines       number? (1, 2 or 3)    row height 56 / 72 / 88; default inferred (overline + supporting -> 3, either one -> 2, else 1).
	                             Supporting may take two lines in a three-line item WITHOUT an overline (truncated) — with an
	                             overline it is one line, as M3 (the three lines must fit 88 - 2 x 12 px); every other line is one line.
	  Leading     string | State<string> | Instance ?    an image asset id (ImageLabel, `LeadingSize` square, onSurfaceVariant)
	                             or a ready element (avatar, checkbox, ...) which becomes a static child of the row
	  LeadingSize number?        image size, default 24 (use 40 for avatars)
	  Trailing    string | State<string> | Instance ?    same, `TrailingText` is the M3 trailing supporting text (LabelSmall)
	  TrailingText (string | State<string>)?
	  OnClick     (() -> ())?    presence (at construction) makes the row a TextButton host with state layer + ripple
	  Selected    boolean | State<boolean>?   secondaryContainer fill, content onSecondaryContainer
	  Disabled    boolean | State<boolean>?   content onSurface @ 38 %, not clickable
	  LayoutOrder number | State<number>?     direct prop (the data form binds it to the row index)
	  Theme, Modifier, Hooks                   Modifier applies after the base style; Size is fixed by `Lines`; Hooks = array-part values
	Returns the host (Frame, or TextButton with `OnClick`).

	Instances at rest (one-line, headline only, no leading/trailing): host + UIPadding + UIListLayout + text column
	(Frame + UIListLayout + UIFlexItem) + Headline = 7; interactive +4 (state layer 3 + a `Content` frame that
	then carries the padding/layout/row children: the layer must be a direct child of a host with no UIPadding /
	UIListLayout, see Interactive.luau); each optional line / leading image +1; an Instance leading/trailing +1 wrapper. The row has no UICorner (M3 list rows are square).
	Text-column layout needs the engine UIFlexItem (`Fill`) so long text truncates instead of pushing the trailing
	element out; the mock has no layout so specs only check the properties.

	List props: `Children: Slot<Instance>?`, `Gap: number?` (default 0), `Theme`, `Modifier`, `LayoutOrder`. The host
	is a Frame with a vertical UIListLayout, full width, AutomaticSize Y — put it in a ScrollingFrame for long lists.
	ListData props: Items State<{T}>, Key (item -> string | number, unique and stable — duplicate keys error, see
	`Slot:List`), Render (item State, index State -> Instance), Gap, Theme, Modifier. Rows are keyed and recycled: the
	row is built once per key (Render runs once); data edits update the `item` State, reorders update `index`.
	  OnReorder  ((from: number, to: number) -> ())?   presence (at construction) makes the list DRAG-TO-REORDER: every
	             row gets a drag handle at its end (and is wrapped — the rendered instance is no longer the List's direct
	             child, its own `LayoutOrder` is not needed); dragging a handle moves that row with the pointer while the
	             others give way, and the release calls `OnReorder(from, to)` — places from 1, `to` counted AFTER the move
	             (`table.insert(t, to, table.remove(t, from))`), never with `from == to`. The list does not edit `Items`:
	             set it in the callback (or when a server answers) and the rows settle in that order; leave it and they go
	             back after a moment. Everything else — sources, the waiting rule, keys, limits — is in ListReorder.luau.
	             Without `OnReorder` nothing of this exists (same instances as before).
]]

local q = require("./Quad")
local Theme = require("./Theme")
local Util = require("./Util")
local Interactive = require("./Interactive")
local Text = require("./Text")
local Style = require("./Button/Style")
local ListReorder = require("./ListReorder")
local D = q.Declaration
local listName = D.Modifier.Frame():Name("List")
local itemFrameName = D.Modifier.Frame():Name("ListItem")
local itemButtonName = D.Modifier.TextButton():Name("ListItem")

export type Text = string | q.State<string>
export type Slotted = string | q.State<string> | Instance

export type ItemProps = {
	read Headline: Text,
	read Supporting: Text?,
	read Overline: Text?,
	read Lines: number?,
	read Leading: Slotted?,
	read LeadingSize: number?,
	read Trailing: Slotted?,
	read TrailingText: Text?,
	read OnClick: (() -> ())?,
	read Selected: (boolean | q.State<boolean>)?,
	read Disabled: (boolean | q.State<boolean>)?,
	read LayoutOrder: (number | q.State<number>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.IntoGuiObject?,
	read Hooks: Util.Hooks?,
}

export type Props = {
	read Children: q.Slot<Instance>?,
	read Gap: number?,
	read LayoutOrder: (number | q.State<number>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local Heights = { 56, 72, 88 }

local headlineStyle = Text.Label("BodyLarge")
local supportingStyle = Text.Label("BodyMedium")
local overlineStyle = Text.Label("LabelSmall")

local baseFrame = D.Modifier.Frame():BorderSizePixel(0)
local baseButton = D.Modifier.TextButton():BorderSizePixel(0):AutoButtonColor(false):Text("")

local function label(name: string, style: any, text: Text, color: any, transparency: any, height: number, wrap: boolean, order: number): TextLabel
	return D.TextLabel {
		Name = name,
		style,
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = color,
		TextTransparency = transparency,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = wrap,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = order,
	}
end

local function ListItem(props: ItemProps): GuiObject
	local theme = Theme.resolve(props.Theme)
	local disabled = Util.asState(props.Disabled)
	local selected = Util.asState(props.Selected)
	local interactive = props.OnClick ~= nil
	local hasSupporting = props.Supporting ~= nil
	local hasOverline = props.Overline ~= nil
	local lines: number = math.clamp(props.Lines or (if hasOverline and hasSupporting then 3 elseif hasOverline or hasSupporting then 2 else 1), 1, 3)
	local threeLine = lines == 3
	local height = Heights[lines]

	-- content roles: headline follows Selected, supporting/icons stay onSurfaceVariant; disabled -> onSurface @ 38 %
	local headlineRole: q.State<Color3> = Style.choose(selected, theme.Raw.OnSecondaryContainer, theme.Raw.OnSurface)
	local variantRole: q.State<Color3> = Style.choose(selected, theme.Raw.OnSecondaryContainer, theme.Raw.OnSurfaceVariant)
	local headlineColor = Style.disabledPick(disabled, headlineRole, theme.Raw.OnSurface)
	local variantColor = Style.disabledPick(disabled, variantRole, theme.Raw.OnSurface)
	local contentTransparency = Style.disabledNumber(disabled, 0, Style.DisabledContentTransparency)

	local containerTransparency: q.State<number> = selected:Compute(function(self)
		return if self:Get() then 0 else 1
	end)
	local containerAnim = containerTransparency:Apply(Style.animation())

	-- text column
	local textParts: { Instance } = {}
	if hasOverline then
		table.insert(textParts, label("Overline", overlineStyle, props.Overline :: Text, variantColor, contentTransparency, 16, false, 1))
	end
	table.insert(textParts, label("Headline", headlineStyle, props.Headline, headlineColor, contentTransparency, 24, false, 2))
	if hasSupporting then
		-- two supporting lines only when there is no overline: the three-line row's 64 px content box (88 - 2 x 12) holds
		-- headline 24 + supporting 40, or overline 16 + headline 24 + supporting 20 — the overline + 40 px form was 80 px and
		-- ran out of the row onto its bottom edge (Studio QA 2026-10-07, 2nd)
		local twoLines = threeLine and not hasOverline
		table.insert(
			textParts,
			label("Supporting", supportingStyle, props.Supporting :: Text, variantColor, contentTransparency, if twoLines then 40 else 20, twoLines, 3)
		)
	end
	local column = D.Frame {
		Name = "Text",
		Size = UDim2.fromScale(0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		D.UIListLayout { FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder },
		D.UIFlexItem { FlexMode = Enum.UIFlexMode.Fill },
		table.unpack(textParts),
	}

	local function side(name: string, v: Slotted?, size: number, order: number): Instance?
		if v == nil then
			return nil
		end
		if type(v) == "string" or q.isState(v) then
			return D.ImageLabel {
				Name = name,
				Size = UDim2.fromOffset(size, size),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = v :: Text,
				ImageColor3 = variantColor,
				ImageTransparency = contentTransparency,
				LayoutOrder = order,
			}
		end
		return D.Frame {
			Name = name,
			Size = UDim2.fromOffset(0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = order,
			v :: Instance,
		}
	end
	local leading = side("Leading", props.Leading, props.LeadingSize or 24, 1)

	-- trailing: image/element and/or the trailing supporting text, in one row-end group only when both exist
	local trailing = side("Trailing", props.Trailing, 24, 3)
	local trailingText: Instance? = nil
	if props.TrailingText ~= nil then
		trailingText = D.TextLabel {
			Name = "TrailingText",
			overlineStyle,
			Size = UDim2.fromOffset(0, 16),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = props.TrailingText,
			TextColor3 = variantColor,
			TextTransparency = contentTransparency,
			LayoutOrder = if trailing then 4 else 3,
		}
	end
	local hasTrailing = trailing ~= nil or trailingText ~= nil

	local layout = D.UIListLayout {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = if threeLine then Enum.VerticalAlignment.Top else Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 16),
	}
	local padding = D.UIPadding {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, if hasTrailing then 16 else 24),
		PaddingTop = UDim.new(0, if threeLine then 12 else 0),
		PaddingBottom = UDim.new(0, if threeLine then 12 else 0),
	}
	local size = UDim2.new(1, 0, 0, height)

	if interactive then
		local fx = Interactive.new({ Theme = theme, Disabled = disabled, OnColor = theme.Color.OnSurface, Corner = UDim.new(0, 0) })
		local interactable: q.State<boolean> = Util.interactable(disabled)
		return D.TextButton {
			itemButtonName,
			baseButton,
			D.Modifier.TextButton():Size(size),
			if props.Modifier then props.Modifier:AsGuiObject():AsTextButton() else q.None,
			fx.Hook,
			BackgroundColor3 = theme.Color.SecondaryContainer,
			BackgroundTransparency = containerAnim,
			LayoutOrder = props.LayoutOrder,
			Interactable = interactable,
			Activated = function()
				if props.OnClick and not Util.peekBool(disabled) then
					props.OnClick()
				end
			end,
			fx.Layer,
			D.Frame {
				Name = "Content",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				padding,
				layout,
				leading or q.None,
				column,
				trailing or q.None,
				trailingText or q.None,
			},
			table.unpack(Util.hooks(props.Hooks)),
		} :: GuiObject
	end

	return D.Frame {
		itemFrameName,
		baseFrame,
		D.Modifier.Frame():Size(size),
		if props.Modifier then props.Modifier:AsGuiObject():AsFrame() else q.None,
		BackgroundColor3 = theme.Color.SecondaryContainer,
		BackgroundTransparency = containerAnim,
		LayoutOrder = props.LayoutOrder,
		padding,
		layout,
		leading or q.None,
		column,
		trailing or q.None,
		trailingText or q.None,
		table.unpack(Util.hooks(props.Hooks)),
	} :: GuiObject
end

local listBase = D.Modifier.Frame():Size(UDim2.fromScale(1, 0)):AutomaticSize(Enum.AutomaticSize.Y):BackgroundTransparency(1):BorderSizePixel(0)

local function container(
	theme: Theme.Theme?,
	gap: number?,
	order: (number | q.State<number>)?,
	modifier: q.FrameModifier?,
	hooks: Util.Hooks?,
	content: q.Slot<Instance>
): Frame
	local _ = Theme.resolve(theme)
	return D.Frame {
		listName,
		listBase,
		modifier or q.None,
		LayoutOrder = order,
		D.UIListLayout {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, gap or 0),
		},
		content,
		table.unpack(Util.hooks(hooks)),
	}
end

local function List(props: Props?): Frame
	local p: Props = props or {}
	return container(p.Theme, p.Gap, p.LayoutOrder, p.Modifier, p.Hooks, p.Children or q.Slot({} :: { Instance }))
end

export type DataProps<T> = {
	read Items: q.State<{ T }>,
	read Key: (item: T) -> string | number,
	read Render: (item: q.State<T>, index: q.State<number>) -> Instance,
	read OnReorder: ((from: number, to: number) -> ())?,
	read Gap: number?,
	read LayoutOrder: (number | q.State<number>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

type RowUD<T> = { item: q.Source<T>, index: q.Source<number> }
type RowCtx<T> = {
	Item: T | q.KeyGone,
	Index: number,
	Offset: q.State<number>,
	Prev: q.SlotItem<Instance>?,
	UserData: RowUD<T>?,
}

local function ListData<T>(props: DataProps<T>): Frame
	local onReorder = props.OnReorder
	if onReorder ~= nil then
		-- drag-to-reorder: the rows are wrapped and driven by ListReorder (its hooks go on the List host, before the caller's)
		local reorder = ListReorder.new({
			Items = props.Items :: any,
			Key = props.Key :: any,
			Render = props.Render :: any,
			OnReorder = onReorder,
			Gap = props.Gap,
			Theme = props.Theme,
		})
		local hooks = table.clone(reorder.Hooks)
		table.move(Util.hooks(props.Hooks), 1, #Util.hooks(props.Hooks), #hooks + 1, hooks)
		return container(props.Theme, props.Gap, props.LayoutOrder, props.Modifier, hooks, reorder.Slot)
	end
	local slot = q.Slot<<Instance>>()
	slot:List(props.Items, function(ctx: RowCtx<T>): (any, RowUD<T>?)
		if ctx.Item == q.KeyGone then
			return nil, ctx.UserData
		end
		local data = ctx.Item :: T
		local prev, ud = ctx.Prev, ctx.UserData
		if prev and ud then
			ud.item:SetIfChanged(data)
			ud.index:SetIfChanged(ctx.Index)
			return prev, ud
		end
		local item = q.Source(data)
		local index = q.Source(ctx.Index)
		return props.Render(item, index), { item = item, index = index }
	end, function(item: T): any
		return props.Key(item)
	end)
	-- a keyed Slot is a manual-CRUD-free `:List` slot: the host owns it
	return container(props.Theme, props.Gap, props.LayoutOrder, props.Modifier, props.Hooks, slot)
end

return {
	List = List,
	ListItem = ListItem,
	ListData = ListData,
}
