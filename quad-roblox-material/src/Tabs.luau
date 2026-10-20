--!strict
--[[
	M3 tabs (fixed): Primary and Secondary, with ONE active indicator that slides between tabs.

	    local page = q.Source("flights")
	    Tabs<<string>>({ Selected = page, Tabs = {
	        { Key = "flights", Label = "Flights", Icon = "rbxassetid://1" },
	        { Key = "trips", Label = "Trips" },
	    } })
	    Tabs<<string>>({ Variant = "Secondary", Selected = page, TabsState = tabsState })   -- a State of the array

	`K` must be spelled out (`Tabs<<string>>`): `Selected: Source<K>` is invariant, so `q.Source("a")` alone makes strict infer
	K = string | nil and reject the call.

	Props (all `read`):
	  Tabs      { Tab<K> }?                      Tab = { Key: K, Label: string, Icon: string? }. A plain array — an inline
	                                             literal works (a `{ Tab<K> } | State<...>` union made strict reject it)
	  TabsState State<{ Tab<K> }>?               the live alternative to `Tabs` (give exactly one). Keyed by `Key` (a tab
	                                             is built once per key; Label/Icon changes arrive through a State)
	  Selected  Source<K>                        the selected key; a click does `Selected:SetIfChanged(key)`
	  Variant   "Primary" | "Secondary"          default "Primary"
	  OnChange  ((key: K) -> ())?                called when a click CHANGES the selection (kit-wide meaning of OnChange)
	  OnClick   ((key: K) -> ())?                called on every click, also on the already selected tab (after OnChange)
	  Theme, Modifier (Frame Modifier, applied after the base style: width / position / LayoutOrder), Hooks
	Returns the host `Frame` (width 100 %, height 48; Primary with icons 64 — decided from the tabs present at
	construction, icons above the label; Secondary: icon beside the label).

	THE INDICATOR is a single Frame (not one per tab). Geometry is computed from the tab COUNT and the selected
	INDEX, in scale units, because fixed tabs share the width equally (`UIFlexItem` Fill): Secondary = 2 px high,
	the full tab width, at `(index-1)/count`; Primary = 3 px high rounded top, as wide as the selected tab's label
	(min 24 px), centered under the tab at `(index-0.5)/count`. So the slide needs NO AbsolutePosition reads and
	survives resizes with no listener. The ONLY measured value is the Primary label width, read from the label's
	`AbsoluteSize` through `q.OnChange` (an engine event, not polling) into a per-key table. Position and Size are
	`q.Animate`d (Medium1 / Emphasized) — the first value snaps (mount), later ones slide.
	The indicator lives in a clipping 3 px "track" strip at the bottom, drawn 6 px high so only its top corners
	round (UICorner rounds all four; the lower half is clipped away) — no extra frames per tab.
	A 1 px OutlineVariant divider runs under the row (M3).

	Structure and cost (counted in test/spec.tabs.luau): host + Row (UIListLayout) + Divider + Track + Indicator
	(+UICorner Primary) + per tab: TextButton, UIFlexItem, state layer (3), Content frame (+UIListLayout), Label
	[+ icon] = 8 per tab (9 with an icon). The Content frame carries the layout so the state layer is not laid out.
	Deviations: NOT scrollable (all tabs share the width; a scrollable variant needs measured tab geometry — left
	out on purpose); a Tab cannot be individually disabled; the label colors animate with the Button motion.
	M3 state layers: active tab = primary-tinted, inactive = onSurface-tinted (OnColor follows the selection).
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Interactive = require("./Interactive")
local Text = require("./Text")
local Style = require("./Button/Style")
local ColorTokens = require("./Tokens/Color")
local KeyedSlot = require("./Chip/KeyedSlot")
local Frame = q.Elem "Frame"
local ImageLabel = q.Elem "ImageLabel"
local TextButton = q.Elem "TextButton"
local TextLabel = q.Elem "TextLabel"
local UIFlexItem = q.Elem "UIFlexItem"
local UIListLayout = q.Elem "UIListLayout"
local FrameModifier = q.Modifier "Frame"
local tabsName = FrameModifier():Name("Tabs")

export type Variant = "Primary" | "Secondary"
export type Tab<K> = { read Key: K, read Label: string, read Icon: string? }


export type Props<K> = {
	read Tabs: { Tab<K> }?,
	read TabsState: q.State<{ Tab<K> }>?,
	read Selected: q.Source<K>,
	read Variant: Variant?,
	read OnChange: ((key: K) -> ())?,
	read OnClick: ((key: K) -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.ModifierInto<Frame>?,
	read Hooks: Util.Hooks?,
}

type Geo = { Index: number, Count: number }

local ICON = 24
local MIN_INDICATOR = 24

local baseModifier = FrameModifier():BackgroundTransparency(1):BorderSizePixel(0)
local labelStyle = Text.Label("TitleSmall")

local function Tabs<K>(props: Props<K>): Frame
	local theme = Theme.resolve(props.Theme)
	local R = theme.Raw
	local primary = props.Variant ~= "Secondary"
	local selected = props.Selected
	local tabsState: q.State<{ Tab<K> }>
	if props.TabsState ~= nil then
		tabsState = props.TabsState
	elseif props.Tabs ~= nil then
		tabsState = q.Source(props.Tabs)
	else
		error("Tabs: pass `Tabs` (a plain array) or `TabsState` (a State of the array)", 2)
	end

	local hasIcons = false
	for _, t in tabsState:Get() do
		if t.Icon ~= nil then
			hasIcons = true
		end
	end
	local height = if primary and hasIcons then 64 else 48
	local trackHeight = if primary then 3 else 2
	local activeRole: ColorTokens.Role = if primary then "Primary" else "OnSurface"
	local motion = q.Animate(Tokens.Motion.options("Medium1", "Emphasized"))

	-- measured label widths (Primary only), keyed by tab key; `widthsVersion` bumps when one changes
	local labelWidths: { [any]: number } = {}
	local widthsVersion = q.Source(0)

	local geo: q.State<Geo> = selected:Compute(function(self, _prev, tabs)
		local key = self:Get()
		local list = tabs:Get()
		for i, t in list do
			if t.Key == key then
				return { Index = i, Count = #list }
			end
		end
		return { Index = 0, Count = #list }
	end, tabsState)

	local found: q.State<boolean> = geo:Compute(function(self)
		return self:Get().Index > 0
	end)
	local position: q.State<UDim2> = geo:Compute(function(self)
		local g = self:Get()
		local n = math.max(g.Count, 1)
		if primary then
			return UDim2.fromScale((g.Index - 0.5) / n, 0)
		end
		return UDim2.fromScale((math.max(g.Index, 1) - 1) / n, 0)
	end)
	local size: q.State<UDim2> = geo:Compute(function(self, _prev, sel, _ver)
		local g = self:Get()
		if primary then
			local w = labelWidths[sel:Get()] or MIN_INDICATOR
			return UDim2.fromOffset(math.max(w, MIN_INDICATOR), trackHeight * 2)
		end
		return UDim2.new(1 / math.max(g.Count, 1), 0, 1, 0)
	end, selected, widthsVersion)

	local function tab(item: q.State<Tab<K>>, order: q.State<number>): Instance
		local first = item:Get()
		local key = first.Key
		local isSel: q.State<boolean> = selected:Compute(function(self)
			return self:Get() == key
		end)
		local textState: q.State<string> = item:Compute(function(self)
			return self:Get().Label
		end)
		local contentRaw = Style.choose(isSel, R[activeRole], R.OnSurfaceVariant)
		local contentColor = Style.animated(contentRaw)
		local fx = Interactive.new({
			Theme = theme,
			OnColor = Style.animated(Style.choose(isSel, R[activeRole], R.OnSurface)),
			Corner = UDim.new(0, 0),
		})

		local hasIcon = first.Icon ~= nil
		local icon: Instance? = nil
		if hasIcon then
			local s: q.State<string> = item:Compute(function(self)
				return self:Get().Icon or ""
			end)
			icon = ImageLabel {
				Name = "Icon",
				Size = UDim2.fromOffset(ICON, ICON),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = s,
				ImageColor3 = contentColor,
				LayoutOrder = 1,
			}
		end
		local stacked = primary and hasIcon

		return TextButton {
			Name = "Tab",
			Size = UDim2.fromScale(0, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = order,
			fx.Hook,
			Activated = function()
				local changed = selected:Get() ~= key
				selected:SetIfChanged(key)
				if changed and props.OnChange then
					props.OnChange(key)
				end
				if props.OnClick then
					props.OnClick(key)
				end
			end,
			UIFlexItem { FlexMode = Enum.UIFlexMode.Fill },
			fx.Layer,
			Frame {
				Name = "Content",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				UIListLayout {
					FillDirection = if stacked then Enum.FillDirection.Vertical else Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, if stacked then 2 else 8),
				},
				icon or q.None,
				TextLabel {
					Name = "Label",
					labelStyle,
					Size = UDim2.fromScale(0, 0),
					AutomaticSize = Enum.AutomaticSize.XY,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Text = textState,
					TextColor3 = contentColor,
					LayoutOrder = 2,
					if primary
						then q.OnChange "TextLabel" "AbsoluteSize" (function(v: Vector2)
							if labelWidths[key] ~= v.X then
								labelWidths[key] = v.X
								widthsVersion:Set(widthsVersion:Get() + 1)
							end
						end)
						else q.None,
					q.OnDestroyed(function()
						labelWidths[key] = nil
					end),
				},
			},
		}
	end

	local trackBase = UDim2.new(1, 0, 0, trackHeight)
	return Frame {
		tabsName,
		baseModifier:Size(UDim2.new(1, 0, 0, height)),
		props.Modifier or q.None,
		Frame {
			Name = "Row",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			UIListLayout {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			},
			KeyedSlot.new<<Tab<K>>>(tabsState, function(t: Tab<K>): any
				return t.Key
			end, tab),
		},
		Frame {
			Name = "Divider",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Color.OutlineVariant,
		},
		Frame {
			Name = "Track",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = trackBase,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Frame {
				Name = "Indicator",
				AnchorPoint = if primary then Vector2.new(0.5, 0) else Vector2.new(0, 0),
				Position = position:Apply(motion),
				Size = size:Apply(motion),
				Visible = found,
				BorderSizePixel = 0,
				BackgroundColor3 = theme.Color.Primary,
				UICorner = if primary then UDim.new(0, trackHeight) else nil,
			},
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return Tabs
