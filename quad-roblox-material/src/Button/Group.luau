--!strict
--[[
	M3 Expressive CONNECTED BUTTON GROUP (the place of the segmented button): a row of toggle buttons 2 px apart that
	make ONE selection — or several. The row's two ends are fully rounded, the corners between cells are small (8) and
	morph: 4 while a cell is pressed, and a SELECTED cell becomes a full pill in the selected colors.

	    local view = q.Source("day" :: string?)
	    ButtonGroup({ Items = { { Key = "day", Label = "Day" }, { Key = "week", Label = "Week" }, { Key = "month", Label = "Month" } },
	                  Value = view })                                                -- single selection
	    local days = q.Source({ mon = true } :: { [string]: boolean })
	    ButtonGroup({ Items = dayItems, Values = days, Variant = "Outlined" })        -- multiple selection
	    ButtonGroup({ Items = items, Value = view, Width = UDim.new(1, 0) })          -- fills its parent, equal cells

	Props (all `read`):
	  Items     { Item }                 static, at least 2 (M3: two to five). Item = { Key: string (unique in the group),
	                                     Label: string | State<string>, Icon: (string | State<string>)? — an ICON PROP value
	                                     (`Icons.luau` "ICON PROPS"), 20 px, 8 px before the label, presence decided at
	                                     construction —, Disabled: (boolean | State<boolean>)? — this cell alone }
	  Value     Source<string?>?         SINGLE selection: the selected Key, or nil for none. A click on another cell writes
	                                     its Key and calls `OnChange(key)`.
	  Values    Source<{ [string]: boolean }>?   MULTIPLE selection: the set of selected Keys (`values[key] == true`). A click
	                                     writes a NEW table with that Key added (`true`) or removed (absent) and calls
	                                     `OnValuesChange(new)`. Keys that are not in `Items` are kept as they are.
	                                     Exactly one of `Value` / `Values` is given (both, or neither, is an error).
	  Required  boolean?                 the selection cannot be emptied by a click. Default TRUE with `Value` (a click on
	                                     the selected cell does nothing — the radio rule of Compose's
	                                     SingleSelectConnectedButtonGroupSample), FALSE with `Values` (every cell toggles
	                                     freely; `true` = the last selected cell cannot be switched off — MDC
	                                     `selectionRequired`). It only limits clicks: the owner may still write nil / {}.
	  Variant   "Filled" | "Tonal" | "Elevated" | "Outlined"   default "Filled" (Compose ToggleButton /
	                                     TonalToggleButton / ElevatedToggleButton / OutlinedToggleButton — colors below)
	  Width     (number | UDim)?         nil = every cell as wide as its content (Compose's connected samples; MDC
	                                     `wrap_content`). A number (px) or a UDim (scale + offset of the parent,
	                                     `UDim.new(1, 0)` = fill) fixes the GROUP's width and the cells share it equally
	                                     (MDC `layout_weight`, Compose `Modifier.weight`), each label centered in its cell.
	  Disabled  (boolean | State<boolean>)?   the whole group (an item's own `Disabled` disables that cell)
	  OnChange        ((value: string?) -> ())?                   after a USER click changed `Value` (never for a write)
	  OnValuesChange  ((values: { [string]: boolean }) -> ())?    after a USER click changed `Values`
	  LayoutOrder (number | State<number>)?, Theme, Modifier (Frame Modifier on the host, after the base), Hooks
	Returns the host `Frame` (height 40; auto width = the cells + 2 px gaps, or `Width`). Cells are TextButtons named
	"Cell" in `Items` order (LayoutOrder 1..n); each is its own gamepad / keyboard selection stop with the kit focus ring.

	WHY TWO PROPS for the two selection models (not one `Value` of two shapes + a `Multiple` flag): under strict a
	callback written in the table literal takes its parameter type from the FIRST member of a union of function types, so
	`OnChange = function(v) ... end` of the multiple form would see `string?`; and nothing ties a `Multiple = true` to
	the shape of the Source next to it. Two props are each one type: the call site needs no annotation and a wrong
	Source or callback is a type error (probed with the kit's strict flag set, 2026-10-13).

	SOURCES — androidx/androidx@b6bfe62 compose/material3 (commonMain .../material3/):
	  tokens/ConnectedButtonGroupSmallTokens.kt 24~36: BetweenSpace 2, ContainerHeight 40, ContainerShape CornerFull,
	    InnerCornerCornerSize = CornerValueSmall (8), PressedInnerCornerCornerSize = CornerValueExtraSmall (4),
	    SelectedInnerCornerCornerSizePercent 50 (a pill). There is no XS / M / L / XL token file for the CONNECTED group
	    (404) — this component is the small size only.
	  ButtonGroup.kt 181~281 (ButtonGroupDefaults): connectedLeadingButtonShapes / connectedMiddleButtonShapes /
	    connectedTrailingButtonShapes = { shape: outer Full + inner 8 (middle: 8 on all four), pressedShape: inner 4 (the
	    outer corners stay Full; middle: 4 on all four), checkedShape: connectedButtonCheckedShape = CornerFull },
	    ConnectedSpaceBetween = 2. `expandedRatio` / `Modifier.animateWidth` (a pressed cell widens by 15 % and squeezes
	    its neighbours) belong to the STANDARD `ButtonGroup` layout; the connected samples are a plain FlowRow of
	    ToggleButtons and do not use it — no width change on press here.
	  ToggleButton.kt 159~217, 1707~1728: shapeByInteraction — pressed wins over checked, checked over rest; the shape
	    animates (FastSpatial spring — here Motion Short4 / Standard, like `./Split.luau`). 521~662: small content padding
	    16 / 16 (ButtonSmallTokens.LeadingSpace / TrailingSpace; the 12 with an icon is the precision-pointer sizing flag,
	    off by default), IconSize 20, IconSpacing 8, text LabelLarge (ButtonDefaults.textStyleFor below 56 dp); no minimum
	    width and no optical centering.
	  Colors (ToggleButton.kt 785~803, 1024~1042, 1211~1226, 1363~1396, 1454~1460; tokens/{Filled,Tonal,Elevated,Outlined}ButtonTokens.kt):
	                unselected container / content            selected container / content
	    Filled      SurfaceContainer / OnSurfaceVariant        Primary / OnPrimary
	    Tonal       SecondaryContainer / OnSecondaryContainer  Secondary / OnSecondary
	    Elevated    SurfaceContainerLow / Primary              Primary / OnPrimary        (shadow level 1, hovered 2)
	    Outlined    none / OnSurfaceVariant, 1 px OutlineVariant   InverseSurface / InverseOnSurface, no outline
	    Disabled (selected or not — ToggleButtonColors.containerColor): container OnSurface @ 10 % (Outlined:
	    OutlineVariant @ 10 %, and its outline OutlineVariant @ 10 % unless selected — ButtonDefaults.outlinedButtonBorder),
	    content OnSurface @ 38 %. (DisabledContainerOpacity is 0.1 in these tokens — the button family's value,
	    `Style.DisabledButtonContainerTransparency`; only the standalone Tonal Button / SplitButton stay at canon's 12 %.)
	  samples/ButtonGroupSamples.kt 152~252: SingleSelectConnectedButtonGroupSample (`onCheckedChange = { selectedIndex =
	    index }`, role RadioButton — one is always selected), MultiSelectConnectedButtonGroupSample (independent toggles).
	    Both swap the cell's icon when it is checked (an outlined icon -> its filled form): pass `Icon` as a State derived
	    from your selection Source for that.
	  material-components-android@60ff094 docs/components/ButtonGroup.md 56~59: "Added connected button group — Use
	    instead of segmented button, which is deprecated"; 160~162: "2dp spacing, 8dp inner corners, and fully rounded
	    outer corners"; 221~370: fixed (`layout_width`) or weighted (`layout_weight`) cells.
	  m3.material.io (components/segmented-buttons, components/button-groups/specs): the pages are script-rendered and
	    returned no text — 사이트 미대조. The numbers above are the Compose tokens; "two to five" cells and the
	    deprecation of the segmented button are from MDC's document and memory of the site, not a site measurement.

	Structure (drawn by `./Segment.luau`, shared with SplitButton — "ASYMMETRIC SHAPE", "ELEVATED SHADOW" there): host
	Frame + UIListLayout; the first and the last cell: TextButton > OuterClip > Face (UICorner, StateLayer > UICorner),
	InnerClip > Face (same), FocusRing (Frame + UICorner + UIStroke), Content (UIPadding + Label [+ UIListLayout + Icon]);
	a middle cell has ONE face and no clip (all four corners share a radius). Outlined: + a UIStroke per face;
	Elevated: + a UIShadow per face, and a middle cell's face sits in one Clip (open by the 2 px gap on both sides).
	Counted in test/spec.buttongroup.luau. A press adds a transient ripple per face.
	NOT here (M3 has it): the standard (unconnected, 12 px apart, width-squeezing) button group and its overflow menu;
	other sizes than small; wrapping onto a second row (Compose's samples are a FlowRow — give the group a `Width` or
	fewer cells); icon-only cells; a vertical group. M3 deviations: the focus ring of an end cell is one rounded rectangle
	at the outer radius (the focused cell is raised above its neighbours so the ring is whole — Segment.luau "FOCUS
	RING"); a shadow ends 2 px past a cell's inner edge; Filled / Tonal do not rise on hover (no shadow
	instance, as the kit Button); the outline fades instead of shrinking to zero width.
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Util = require("../Util")
local Ripple = require("../Ripple")
local Text = require("../Text")
local IconView = require("../IconView")
local Style = require("./Style")
local Segment = require("./Segment")
local ColorTokens = require("../Tokens/Color")
local D = q.Declaration
local groupName = D.Modifier.Frame():Name("ButtonGroup")

export type Variant = "Filled" | "Tonal" | "Elevated" | "Outlined"

export type Item = {
	read Key: string,
	read Label: string | q.State<string>,
	read Icon: (string | q.State<string>)?,
	read Disabled: (boolean | q.State<boolean>)?,
}

export type Props = {
	read Items: { Item },
	read Value: q.Source<string?>?,
	read Values: q.Source<{ [string]: boolean }>?,
	read Required: boolean?,
	read Variant: Variant?,
	read Width: (number | UDim)?,
	read Disabled: (boolean | q.State<boolean>)?,
	read OnChange: ((value: string?) -> ())?,
	read OnValuesChange: ((values: { [string]: boolean }) -> ())?,
	read LayoutOrder: (number | q.State<number>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

type Spec = {
	Container: ColorTokens.Role?, -- unselected; nil = transparent
	Content: ColorTokens.Role,
	SelectedContainer: ColorTokens.Role,
	SelectedContent: ColorTokens.Role,
	DisabledContainer: ColorTokens.Role,
	Stroke: boolean,
	Shadow: number?,
}

-- ToggleButtonDefaults / ElevatedToggleButtonDefaults / FilledTonalToggleButtonDefaults / OutlinedToggleButtonDefaults
-- (see the header)
local Specs: { [Variant]: Spec } = {
	Filled = {
		Container = "SurfaceContainer",
		Content = "OnSurfaceVariant",
		SelectedContainer = "Primary",
		SelectedContent = "OnPrimary",
		DisabledContainer = "OnSurface",
		Stroke = false,
		Shadow = nil,
	},
	Tonal = {
		Container = "SecondaryContainer",
		Content = "OnSecondaryContainer",
		SelectedContainer = "Secondary",
		SelectedContent = "OnSecondary",
		DisabledContainer = "OnSurface",
		Stroke = false,
		Shadow = nil,
	},
	Elevated = {
		Container = "SurfaceContainerLow",
		Content = "Primary",
		SelectedContainer = "Primary",
		SelectedContent = "OnPrimary",
		DisabledContainer = "OnSurface",
		Stroke = false,
		Shadow = 1,
	},
	Outlined = {
		Container = nil,
		Content = "OnSurfaceVariant",
		SelectedContainer = "InverseSurface",
		SelectedContent = "InverseOnSurface",
		DisabledContainer = "OutlineVariant",
		Stroke = true,
		Shadow = nil,
	},
}

-- ConnectedButtonGroupSmallTokens / ToggleButtonDefaults (see the header)
local HEIGHT = 40
local BETWEEN = 2
local OUTER = HEIGHT / 2 -- ContainerShape CornerFull
local INNER = 8 -- InnerCornerCornerSize (CornerValueSmall)
local INNER_PRESSED = 4 -- PressedInnerCornerCornerSize (CornerValueExtraSmall)
local INNER_SELECTED = OUTER -- SelectedInnerCornerCornerSizePercent 50
local PAD = { 16, 16 } -- ButtonSmallTokens.LeadingSpace / TrailingSpace
local ICON = 20 -- ButtonSmallTokens.IconSize
local ICON_GAP = 8 -- ButtonSmallTokens.IconLabelSpace
local DISABLED_CONTAINER_T = Style.DisabledButtonContainerTransparency -- <Variant>ButtonTokens.DisabledContainerOpacity 0.1
local DISABLED_CONTENT_T = 1 - 0.38 -- DisabledLabelTextOpacity

local labelStyle = Text.Label("LabelLarge")
local baseModifier = D.Modifier.Frame()
	:Size(UDim2.fromOffset(0, HEIGHT))
	:AutomaticSize(Enum.AutomaticSize.X)
	:BackgroundTransparency(1)
	:BorderSizePixel(0)

-- how many of the group's own keys are selected in `values`
local function countSelected(items: { Item }, values: { [string]: boolean }): number
	local n = 0
	for _, item in items do
		if values[item.Key] == true then
			n += 1
		end
	end
	return n
end

local function ButtonGroup(props: Props)
	local theme = Theme.resolve(props.Theme)
	local variant: Variant = props.Variant or "Filled"
	local spec = Specs[variant]
	if spec == nil then
		error(`ButtonGroup: Variant must be "Filled", "Tonal", "Elevated" or "Outlined", got {tostring(variant)}`, 2)
	end
	local items = props.Items
	local count = #items
	if count < 2 then
		error(`ButtonGroup: Items needs at least 2 items, got {count}`, 2)
	end
	local seen: { [string]: boolean } = {}
	for index, item in items do
		if type(item.Key) ~= "string" then
			error(`ButtonGroup: Items[{index}].Key must be a string, got {typeof(item.Key)}`, 2)
		elseif seen[item.Key] then
			error(`ButtonGroup: Items[{index}].Key "{item.Key}" is used twice`, 2)
		end
		seen[item.Key] = true
	end
	local single, multiple = props.Value, props.Values
	if single ~= nil and multiple ~= nil then
		error("ButtonGroup: give Value (single selection) or Values (multiple selection), not both", 2)
	elseif single == nil and multiple == nil then
		error("ButtonGroup: Value (single selection) or Values (multiple selection) is required", 2)
	end
	local required = if props.Required ~= nil then props.Required else single ~= nil
	local groupDisabled = Util.asState(props.Disabled)

	-- a fixed `Width`: the host's measured width (local px) is shared equally; 0 until measured (cells = content width)
	local fixed = props.Width
	local hostWidth = q.Source(0)
	local sizing: q.FrameModifier? = nil
	local measureHost: unknown = q.None
	if fixed ~= nil then
		local x = if type(fixed) == "number" then UDim.new(0, fixed) else fixed
		sizing = D.Modifier.Frame():Size(UDim2.new(x, UDim.new(0, HEIGHT))):AutomaticSize(Enum.AutomaticSize.None)
		measureHost = Util.preHook(function(inst: GuiObject)
			local function read()
				local k = Ripple.localScale(inst)
				hostWidth:SetIfChanged(if k > 0 then inst.AbsoluteSize.X / k else inst.AbsoluteSize.X)
			end
			read()
			inst:GetPropertyChangedSignal("AbsoluteSize"):Connect(read)
		end)
	end

	local function click(key: string)
		if single ~= nil then
			if single:Get() == key then
				if required then
					return
				end
				single:Set(nil)
				if props.OnChange then
					props.OnChange(nil)
				end
			else
				single:Set(key)
				if props.OnChange then
					props.OnChange(key)
				end
			end
		elseif multiple ~= nil then
			local now = multiple:Get()
			local on = now[key] == true
			if on and required and countSelected(items, now) <= 1 then
				return
			end
			local nextValues = table.clone(now)
			nextValues[key] = if on then nil else true
			multiple:Set(nextValues)
			if props.OnValuesChange then
				props.OnValuesChange(nextValues)
			end
		end
	end

	local cells: { Instance } = {}
	for index, item in items do
		local key = item.Key
		local selected: q.State<boolean>
		if single ~= nil then
			selected = single:Compute(function(self)
				return self:Get() == key
			end)
		else
			selected = (multiple :: q.Source<{ [string]: boolean }>):Compute(function(self)
				return self:Get()[key] == true
			end)
		end
		local disabled: q.State<boolean> = groupDisabled
		if item.Disabled ~= nil then
			disabled = groupDisabled:Compute(function(self, _prev, own)
				return self:Get() or own:Get()
			end, Util.asState(item.Disabled))
		end

		-- colors: disabled > selected > unselected, cross-faded once (Button/Style.luau)
		local contentRaw: q.State<Color3> = selected:Compute(function(self, _prev, dis, on, off, gone)
			if dis:Get() then
				return gone:Get()
			end
			return if self:Get() then on:Get() else off:Get()
		end, disabled, theme.Raw[spec.SelectedContent], theme.Raw[spec.Content], theme.Raw.OnSurface)
		local contentColor = Style.animated(contentRaw)
		local contentT = Style.disabledNumber(disabled, 0, DISABLED_CONTENT_T)
		-- a transparent (Outlined, unselected) container keeps the SELECTED color: selecting it is a pure fade-in
		local unselectedContainer: ColorTokens.Role = spec.Container or spec.SelectedContainer
		local containerRaw: q.State<Color3> = selected:Compute(
			function(self, _prev, dis, on, off, gone)
				if dis:Get() then
					return gone:Get()
				end
				return if self:Get() then on:Get() else off:Get()
			end,
			disabled,
			theme.Raw[spec.SelectedContainer],
			theme.Raw[unselectedContainer],
			theme.Raw[spec.DisabledContainer]
		)
		local hasContainer = spec.Container ~= nil
		local containerTRaw: q.State<number> = selected:Compute(function(self, _prev, dis)
			if dis:Get() then
				return DISABLED_CONTAINER_T
			end
			return if self:Get() or hasContainer then 0 else 1
		end, disabled)
		local stroke: Segment.Stroke? = nil
		if spec.Stroke then
			-- OutlinedToggleButtonDefaults.border: none while checked; OutlineVariant, @ 10 % while disabled
			local strokeTRaw: q.State<number> = selected:Compute(function(self, _prev, dis)
				if self:Get() then
					return 1
				end
				return if dis:Get() then DISABLED_CONTAINER_T else 0
			end, disabled)
			stroke = { Color = theme.Color.OutlineVariant, Transparency = strokeTRaw:Apply(Style.animation()) }
		end

		-- content: [icon] label
		local content: { Instance } = {}
		local iconValue = item.Icon
		if iconValue ~= nil then
			table.insert(
				content,
				D.UIListLayout {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, ICON_GAP),
				}
			)
			local icon = IconView.new({
				Name = "Icon",
				Icon = iconValue,
				Size = ICON,
				Color = contentColor,
				Transparency = contentT,
				LayoutOrder = 1,
			})
			table.insert(content, icon)
		end
		table.insert(
			content,
			D.TextLabel {
				Name = "Label",
				labelStyle,
				Size = UDim2.fromScale(0, 1),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = item.Label,
				TextColor3 = contentColor,
				TextTransparency = contentT,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				LayoutOrder = 2,
			}
		)

		-- an equal share of a fixed width: the remainder pixels go to the first cells
		local cellWidth: q.State<number>? = nil
		if fixed ~= nil then
			cellWidth = hostWidth:Compute(function(self)
				local total = math.floor(self:Get() + 1e-3) - BETWEEN * (count - 1)
				if total <= 0 then
					return 0
				end
				local base = math.floor(total / count)
				return if index <= total - base * count then base + 1 else base
			end)
		end

		local side: Segment.Side = if index == 1 then "Leading" elseif index == count then "Trailing" else "Middle"
		table.insert(
			cells,
			Segment.new({
				Name = "Cell",
				Side = side,
				LayoutOrder = index,
				Theme = theme,
				Disabled = disabled,
				Selected = selected,
				Height = HEIGHT,
				Between = BETWEEN,
				MinWidth = 0,
				Outer = OUTER,
				Inner = INNER,
				InnerPressed = INNER_PRESSED,
				InnerSelected = INNER_SELECTED,
				Width = cellWidth,
				ContainerColor = Style.animated(containerRaw),
				ContainerTransparency = containerTRaw:Apply(Style.animation()),
				ContentColor = contentColor,
				Stroke = stroke,
				Shadow = spec.Shadow,
				Content = content,
				Pad = PAD,
				Optical = false,
				OnClick = function()
					click(key)
				end,
			})
		)
	end

	-- the cells, then the caller's hooks: ONE multi-value tail (a second `table.unpack` would be truncated)
	local tail: { any } = table.clone(cells)
	for _, hook in Util.hooks(props.Hooks) do
		table.insert(tail, hook)
	end

	return D.Frame {
		groupName,
		baseModifier,
		sizing or q.None,
		props.Modifier or q.None,
		measureHost,
		LayoutOrder = props.LayoutOrder,
		D.UIListLayout {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, BETWEEN),
		},
		table.unpack(tail),
	}
end

return ButtonGroup
