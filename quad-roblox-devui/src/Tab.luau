--!strict
--[[
	TabBar / Tab (Iris: TabBar / Tab).

		TabBar<K> { Tabs: { TabDef<K> }, Selected: Source<K>?, OnChange: ((key: K) -> ())?, NoPages: boolean?,
		            Style: Style?, Modifier: ModifierInto<Frame>? }
		Tab<K>    { Key: K, Text: string | State<string>, Children: Slot<Instance>? }   -- returns a plain descriptor

	API shape: `Tab{...}` builds NO instance — it is a descriptor (identity + label + content Slot) the TabBar reads, so the
	TabBar can put the header button in the bar row and the content in a page container without re-parenting anything:

		Devui.TabBar {
			Selected = tabKey,                                  -- optional two-way Source (default: the first tab's Key)
			Tabs = {
				Devui.Tab { Key = "stats", Text = "Stats", Children = Kids(Devui.Text { Text = "..." }) },
				Devui.Tab { Key = "log",   Text = "Log",   Children = Kids(...) },
			},
		}

	`K` is the key type (string, number, ...); `Selected` must be a `Source<K>`. Under the new solver a generic call that
	takes a `Source<K>` does not infer `K`, so write the type argument: `TabBar<<string>>{ ... }`, `Tab<<string>>{ ... }`
	(only needed where `Selected`/typed keys are used strictly). Clicking a header sets `Selected`
	(SetIfChanged) and then calls `OnChange(key)` when the selection really changed (UI-originated only: not for an outside
	`:Set`); setting it from outside switches the page. Only the selected tab's page is Visible; the other pages
	stay mounted (hidden), so their widgets keep their state. The tab list is fixed at construction (build a new TabBar to
	change it); closable/hideable tabs are not provided. A `Selected` value that matches no Key shows no page.

	Structure: root Frame (vertical) > Bar (horizontal row of tab TextButtons) + Underline (1px) + Pages (one Frame per tab).

	`NoPages = true` [2026-10-20 user decision, a consumer hand-built tab buttons twice]: only the Bar and the Underline —
	a tab strip / segmented selector whose content the caller shows elsewhere from `Selected`. A Tab with `Children`
	then has nowhere to go: that is an error (its Slot would be left unmounted). Tab corners use the `TabRounding`
	metric (same default as FrameRounding).
]]

local Quad = require("./Quad")
local q = Quad
local Frame = q.Elem "Frame"
local TextButton = q.Elem "TextButton"
local UIListLayout = q.Elem "UIListLayout"
local UIPadding = q.Elem "UIPadding"
local FrameModifier = q.Modifier "Frame"
local tabBarName = FrameModifier():Name("TabBar")
local Common = require("./Common")
local Interaction = require("./Interaction")
local Style = require("./Style")
local Util = require("./Util")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Slot<T> = Quad.Slot<T>
type Style = Style.Style

export type TabProps<K> = {
	read Key: K,
	read Text: string | State<string>,
	read Children: Slot<Instance>?,
}

export type TabDef<K> = {
	read Key: K,
	read Text: string | State<string>,
	read Children: Slot<Instance>?,
}

export type TabBarProps<K> = {
	read Tabs: { TabDef<K> },
	read Selected: Source<K>?,
	read OnChange: ((key: K) -> ())?,
	read NoPages: boolean?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<Frame>?,
}

local function Tab<K>(props: TabProps<K>): TabDef<K>
	return { Key = props.Key, Text = props.Text, Children = props.Children }
end

local function initialSelection<K>(props: TabBarProps<K>): Source<K>
	if props.Selected then
		return props.Selected
	end
	local first = props.Tabs[1]
	if first == nil then
		error("TabBar: `Tabs` is empty (pass at least one Tab, or pass your own `Selected` Source)", 3)
	end
	return q.Source(first.Key)
end

local function TabBar<K>(props: TabBarProps<K>): Frame
	local style = props.Style or Style.default
	local tabs = props.Tabs
	local selected = initialSelection(props)
	local onChange = props.OnChange

	local metrics = style.Metrics
	local padX, padY = Common.padXY(metrics.FramePadding)
	local noPages = props.NoPages == true
	if noPages then
		for _, def in tabs do
			if def.Children ~= nil then
				error(`TabBar: NoPages draws no pages - Tab "{tostring(def.Key)}" has Children with nowhere to go`, 2)
			end
		end
	end

	local buttons: { Instance } = {}
	local pages: { Instance } = {}
	for i, def in tabs do
		local key = def.Key
		local label = tostring(key)
		local isSelected: State<boolean> = selected:Compute(function(self)
			return self:Get() == key
		end)
		local hover = Interaction.hover()
		local look = Style.interactive(style, "Tab", hover.Hovered, hover.Pressed)
		local color: State<Color3> = isSelected:Compute(function(self, _prev, normal, active)
			return if self:Get() then active:Get() else normal:Get()
		end, look.Color, style.Color.TabActive)
		local alpha: State<number> = isSelected:Compute(function(self, _prev, normal, active)
			return if self:Get() then active:Get() else normal:Get()
		end, look.Transparency, style.Transparency.TabActive)

		buttons[i] = TextButton({
			hover.Hook,
			Name = `Tab:{label}`,
			LayoutOrder = i,
			Text = def.Text,
			FontFace = metrics.TextFont,
			TextSize = metrics.TextSize,
			TextColor3 = style.Color.Text,
			TextTransparency = style.Transparency.Text,
			BackgroundColor3 = color,
			BackgroundTransparency = alpha,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromOffset(0, 0),
			Activated = function()
				if selected:Get() ~= key then
					selected:Set(key)
					if onChange then
						onChange(key)
					end
				end
			end,
			UICorner = metrics.TabRounding,
			UIPadding({ PaddingLeft = padX, PaddingRight = padX, PaddingTop = padY, PaddingBottom = padY }),
		})

		if not noPages then
			pages[i] = Frame({
				Name = `Page:{label}`,
				LayoutOrder = i,
				Visible = isSelected,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				UIListLayout({
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = Util.pxY(metrics.ItemSpacing),
				}),
				def.Children or q.None,
			})
		end
	end

	return Frame({
		tabBarName,
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
		Frame({
			Name = "Bar",
			LayoutOrder = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			UIListLayout({
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = Util.pxX(metrics.ItemInnerSpacing),
			}),
			q.Slot(buttons),
		}),
		Frame({
			Name = "Underline",
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = style.Color.TabActive,
			BackgroundTransparency = style.Transparency.TabActive,
			BorderSizePixel = 0,
		}),
		if noPages
			then q.None
			else Frame({
				Name = "Pages",
				LayoutOrder = 2,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				UIPadding({ PaddingTop = Util.pxY(metrics.ItemSpacing) }),
				q.Slot(pages),
			}),
	})
end

return {
	Tab = Tab,
	TabBar = TabBar,
}
