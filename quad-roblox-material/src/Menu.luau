--!strict
--[[
	M3 menu: a surface-container panel (elevation 2, corner 4) of 48 px items opened under an anchor element
	through the kit's `Overlay`. Closes on item click and on a click outside (a fully transparent scrim).

	    local handle = Menu.open({
	        Anchor = someButton,                                  -- any GuiObject; the menu opens under it
	        Items = {
	            { Label = "Rename", OnClick = rename, Leading = "rbxassetid://1" },
	            { Label = "Duplicate", Trailing = "Ctrl+D", OnClick = dup },
	            "divider",
	            { Label = "Delete", OnClick = delete, Disabled = locked },
	        },
	    })
	    handle.Close()                                            -- idempotent (Overlay handle)
	    Menu.Button({ Label = "Actions", Items = items })         -- a Button that opens the menu under itself
	                                                              --   (`Width: number?` as in OpenOptions; nil = fit)

	OpenOptions
	  Anchor     GuiObject                       position source: `AbsolutePosition`/`AbsoluteSize` are read ONCE at open;
	                                             the menu closes when the anchor is destroyed
	  Items      { Item | "divider" }            fixed for the lifetime of the open menu (it is rebuilt per open)
	  Overlay    Overlay.Overlay?                default `Overlay.default()`
	  Theme      Theme?
	  Width      number?                         fixed panel width (labels truncate with "…"). nil = fit the widest item
	                                             (leading + label + trailing + padding), at least 112 — see WIDTH below
	  MaxHeight  number?                         the list scrolls past this (default: the room left on screen)
	  OnClose    Overlay.OnCloseFn?      once, at the start of closing (item click, outside click, Escape, `.Close()`,
	                                             or "Destroyed" when the overlay layer died)
	Item = { Label, OnClick?, Disabled? (boolean | State<boolean>, read live: a disabled item is skipped by the keyboard
	         navigation and does nothing when activated; no item does anything once the menu is closing), Leading? (image id), Trailing? (image id, or any other string = text),
	         Selected? (container highlight, as the Select field shows the chosen option) }

	WIDTH. Compose's DropdownMenu sizes its column to the widest item (`width(IntrinsicSize.Max)`, each item
	`sizeIn(minWidth = 112.dp, maxWidth = 280.dp)` — androidx/androidx@5ac4c7c compose/material3/material3/src/commonMain/
	kotlin/androidx/compose/material3/Menu.kt 1867, 2163-2166, 2388-2391) and does NOT follow the anchor's width; only the
	exposed dropdown (`ExposedDropdownMenuBox`, `exposedDropdownSize(matchAnchorWidth = true)` — ExposedDropdownMenu.kt
	202-211) matches its field, which `Select` does by passing `Width`. Without `Width` the kit lets the engine measure
	(FontFace text cannot be measured synchronously): the panel and its list are `AutomaticSize` X, each row is
	`AutomaticSize` X (label `AutomaticSize` X + a right UIPadding that reserves the trailing room — for a trailing text,
	its laid-out width + 12 + 16, measured like the panel) and stretched to the
	widest row (`UIFlexItem` `ItemLineAlignment = Stretch`), and a 0-high 112-wide spacer in the list sets the floor
	(a `UISizeConstraint.MinSize` on the panel does grow it, but the rows only stretch to the widest SIBLING — Studio
	2026-10-15). Deviation: no 280 maximum (user decision 2026-10-15 — a long label shows in full rather than "…").
	The width is read back from the laid-out panel (`AbsoluteSize` / its UIScale) right after the overlay mounts it (the
	engine lays out on read), and the panel is re-placed when that width later changes by 2 px or more (a FontFace that
	loads). Every reading — the panel's and the trailing texts' — is taken at the panel's FULL scale only: text under a
	UIScale renders at whole font sizes, so a width read during the open animation is up to ~4 % off and not proportional
	(Studio 2026-10-15), and following those readings fed back through the re-placing into "Maximum event re-entrancy
	depth exceeded". The first reading sets the panel's UIScale to 1 and back to the closed scale in the same step (nothing
	is drawn in between). While it animates open the panel's width breathes with the text's whole font sizes.

	Placement: below the anchor, flipped above when the list does not fit below and there is more room above;
	clamped horizontally into the overlay layer (so the layer's AbsoluteSize must be laid out — with a zero
	size, e.g. a mock, no flipping/clamping happens). Coordinates are converted to layer space, so a ScreenGui
	inset does not matter. A panel wider than the layer starts at the layer's left edge (and runs past the right one).

	Motion: the panel mounts at scale .9 (snapped) and a `Util.postHook` flips a Source, so the next write
	animates to 1 (Motion Short4 / EmphasizedDecelerate); the exit runs the same tween back during the
	overlay's closing phase (`ExitTime` Short2). Pure scale: no fade (a fade would need a CanvasGroup around
	the whole panel and the UIShadow does not render through one) — deviation from M3's fade+expand. The scale
	pivots at the panel's top-center (bottom-center when flipped): it grows away from the anchor edge, symmetric left/right.

	Input: pointer/touch via the items (`Activated`); gamepad via engine selection (the items are Selectable and show the
	kit focus ring). Escape / gamepad B close the menu (Overlay `DismissOnEscape`); the gamepad selection is confined to
	the menu while it is open and starts on the first enabled item (Overlay `TrapSelection` / `InitialSelection`; the
	previous selection is restored on close). Keyboard: Up/Down move the selection through the enabled items (wrapping),
	Return activates the highlighted one — handled by ONE `InputBegan` connection held by the panel (closed when the
	panel is destroyed) that ignores keys the engine already processed, so it never doubles the engine's own navigation.
	NOT implemented: type-ahead, submenus.

	Per item at rest: TextButton + state layer (Frame, UICorner, UIStroke) + label = 5 (+1 per icon/trailing text; +2 when
	the width fits the items — the row's UIFlexItem and the label's UIPadding);
	a press adds the transient ripple (Ripple.luau, 3) over the whole row — the M3 DropdownMenuItem has a bounded ripple
	(Compose Menu.kt, see itemRow). Panel: Frame, UICorner, UIShadow, UIScale (+ScrollingFrame when it scrolls),
	UIListLayout, UIPadding (+ the 112 spacer Frame when the width fits the items). Divider = 2.
	Scrolling list: the rows span the full panel width (`VerticalScrollBarInset` None — the thumb overlays the rows'
	right edge, so a row's layer and ripple reach the panel edge), thumb onSurface at 50 % (Tokens/State.luau
	`ScrollBar` — M3 has no scrollbar token; the engine default thumb is white).
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Text = require("./Text")
local Interactive = require("./Interactive")
local Elevation = require("./Elevation")
local Overlay = require("./Overlay")
local Button = require("./Button")
local D = q.Declaration

export type Item = {
	read Label: string,
	read OnClick: (() -> ())?,
	read Disabled: (boolean | q.State<boolean>)?,
	read Leading: string?,
	read Trailing: string?,
	read Selected: boolean?,
}
export type Entry = Item | "divider"

export type OpenOptions = {
	read Anchor: GuiObject,
	read Items: { Entry },
	read Overlay: Overlay.Overlay?,
	read Theme: Theme.Theme?,
	read Width: number?,
	read MaxHeight: number?,
	read OnClose: Overlay.OnCloseFn?,
}

local ItemHeight = 48
local DividerHeight = 17
local ListPadding = 8
local MinWidth = 112
local TrailingTextWidth = 64
local ClosedScale = 0.9
local Corner = Tokens.Shape.corner("ExtraSmall")
local labelLarge = Text.Label("LabelLarge")

local function isImage(s: string): boolean
	return string.sub(s, 1, 4) == "rbxa" or string.sub(s, 1, 4) == "http"
end

local Input = require("./Input")
local GuiService = game:GetService("GuiService")

type NavItem = { Inst: GuiObject, Activate: () -> (), Enabled: () -> boolean }

-- (fit) shared by one open menu: the panel's UIScale once built, and the trailing-text measures to run at full scale
type FitCtx = { Scale: UIScale?, Measures: { () -> () } }

local function itemRow(
	item: Item,
	theme: Theme.Theme,
	close: () -> boolean, -- closes the menu; false when it was closed already (the item then does nothing)
	register: (inst: GuiObject, activate: () -> (), enabled: () -> boolean) -> (),
	fit: FitCtx? -- the panel fits its items (no `Width`): the row and label size to their content (header WIDTH)
)
	local disabled = Util.asState(item.Disabled)
	local selected = item.Selected == true
	local fx = Interactive.new({
		Theme = theme,
		Disabled = disabled,
		OnColor = if selected then theme.Color.OnSecondaryContainer else theme.Color.OnSurface,
		Corner = UDim.new(0, 0),
		-- a bounded ripple over the whole row, as Compose's DropdownMenuItem (clickable(indication = ripple(true)) BEFORE
		-- fillMaxWidth / padding: androidx/androidx@5ac4c7c compose/material3/material3/src/commonMain/kotlin/androidx/
		-- compose/material3/Menu.kt 2141-2160). Until 2026-10-08 the kit had `Ripple = false` ("the menu closes on click") —
		-- but a press is held before the click, and the user saw only the static darkening (Studio QA 2026-10-08, 9th).
	})
	local textColor = if selected then theme.Color.OnSecondaryContainer else theme.Color.OnSurface
	local iconColor = if selected then theme.Color.OnSecondaryContainer else theme.Color.OnSurfaceVariant
	local transparency: q.State<number> = disabled:Compute(function(self)
		return if self:Get() then 1 - Tokens.State.Opacity.DisabledContent else 0
	end)
	local function activate()
		if Util.peekBool(disabled) then
			return
		end
		-- the rows stay mounted (and clickable) while the menu animates out: a second tap on the row within the exit
		-- time must not run OnClick again
		if not close() then
			return
		end
		if item.OnClick then
			item.OnClick()
		end
	end

	local left = if item.Leading ~= nil then 12 + 24 + 12 else 16
	local trailing = item.Trailing
	local trailingIsImage = trailing ~= nil and isImage(trailing)
	local right = if trailing == nil then 16 elseif trailingIsImage then 12 + 24 + 12 else 16 + TrailingTextWidth
	-- (fit) the label's right padding = the room the trailing part takes. A trailing TEXT is measured once laid out
	-- (FontFace text has no synchronous measure): 16 + its width + 12 (Compose: the text's end padding next to a
	-- trailing slot, DropdownMenuItemHorizontalPadding — Menu.kt 2183-2196, 2376-2377); until then the fixed 64 px guess
	local labelPadRight: q.Source<UDim> = q.Source(UDim.new(0, right))
	local fitting = fit ~= nil

	local leadingIcon: Instance? = nil
	if item.Leading ~= nil then
		leadingIcon = D.ImageLabel {
			Name = "Leading",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(24, 24),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = item.Leading,
			ImageColor3 = iconColor,
			ImageTransparency = transparency,
		}
	end
	local trailingEl: Instance? = nil
	if trailing ~= nil then
		if trailingIsImage then
			trailingEl = D.ImageLabel {
				Name = "Trailing",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(24, 24),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = trailing,
				ImageColor3 = iconColor,
				ImageTransparency = transparency,
			}
		else
			trailingEl = D.TextLabel {
				Name = "Trailing",
				labelLarge,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -16, 0, 0),
				-- (fit) as wide as its text; the label's padding follows it (AbsoluteSize carries every UIScale above:
				-- divide by the known 48 px row height it fills)
				Size = if fitting then UDim2.fromScale(0, 1) else UDim2.new(0, TrailingTextWidth, 1, 0),
				AutomaticSize = if fitting then Enum.AutomaticSize.X else Enum.AutomaticSize.None,
				if fit
					then Util.preHook(function(inst: GuiObject)
						-- read only while the panel is at FULL scale: text under a UIScale renders at whole font sizes, so
						-- a reading during the open animation is not proportional (Studio 2026-10-15 — following those
						-- readings fed back through the panel's re-placing into "Maximum event re-entrancy depth
						-- exceeded"); a change under 2 px is ignored (sub-pixel jitter)
						local function measure()
							local sc = fit.Scale
							local abs = inst.AbsoluteSize
							if sc == nil or sc.Scale ~= 1 or abs.Y <= 0 then
								return
							end
							local pad = 16 + math.ceil(abs.X * ItemHeight / abs.Y - 0.01) + 12
							if math.abs(pad - labelPadRight:Get().Offset) >= 2 then
								labelPadRight:Set(UDim.new(0, pad))
							end
						end
						table.insert(fit.Measures, measure)
						inst:GetPropertyChangedSignal("AbsoluteSize"):Connect(measure)
					end)
					else q.None,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = trailing,
				TextColor3 = iconColor,
				TextTransparency = transparency,
				TextXAlignment = Enum.TextXAlignment.Right,
			}
		end
	end

	return D.TextButton {
		Name = "Item",
		Size = if fitting then UDim2.fromOffset(0, ItemHeight) else UDim2.new(1, 0, 0, ItemHeight),
		AutomaticSize = if fitting then Enum.AutomaticSize.X else Enum.AutomaticSize.None,
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		BackgroundColor3 = theme.Color.SecondaryContainer,
		BackgroundTransparency = if selected then 0 else 1,
		Interactable = Util.interactable(disabled),
		fx.Hook,
		Util.preHook(function(inst: GuiObject)
			register(inst, activate, function()
				return not Util.peekBool(disabled)
			end)
		end),
		Activated = activate,
		-- (fit) the row is as wide as its label, then stretched to the widest row of the list
		if fitting then D.UIFlexItem { ItemLineAlignment = Enum.ItemLineAlignment.Stretch } else q.None,
		fx.Layer,
		leadingIcon or q.None,
		D.TextLabel {
			Name = "Label",
			labelLarge,
			Position = UDim2.fromOffset(left, 0),
			Size = if fitting then UDim2.fromScale(0, 1) else UDim2.new(1, -(left + right), 1, 0),
			AutomaticSize = if fitting then Enum.AutomaticSize.X else Enum.AutomaticSize.None,
			-- (fit) the label's own width carries the trailing room, so the row's automatic width includes it
			if fitting then D.UIPadding { PaddingRight = labelPadRight } else q.None,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = item.Label,
			TextColor3 = textColor,
			TextTransparency = transparency,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		},
		trailingEl or q.None,
	}
end

local function dividerRow(theme: Theme.Theme, fit: boolean)
	return D.Frame {
		Name = "Divider",
		-- (fit) a scale width inside the automatic-width list feeds back into it (Studio 2026-10-15: the panel grew to
		-- half the layer); stretched like the rows instead
		Size = if fit then UDim2.fromOffset(0, DividerHeight) else UDim2.new(1, 0, 0, DividerHeight),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		if fit then D.UIFlexItem { ItemLineAlignment = Enum.ItemLineAlignment.Stretch } else q.None,
		D.Frame {
			Name = "Line",
			Position = UDim2.fromOffset(0, 8),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = theme.Color.OutlineVariant,
			BorderSizePixel = 0,
		},
	}
end

local function open(o: OpenOptions): Overlay.Handle
	local theme = Theme.resolve(o.Theme)
	local overlay = o.Overlay or Overlay.default()
	local anchor = o.Anchor

	-- content height + placement (read once, in layer space)
	local contentH = ListPadding * 2
	for _, e in o.Items do
		contentH += if type(e) == "string" then DividerHeight else ItemHeight
	end
	local fit = o.Width == nil
	local fitCtx: FitCtx? = if fit then { Scale = nil, Measures = {} } else nil
	-- the panel's width: fixed, or (fit) a first guess until the laid-out panel is read back below
	local width = o.Width or MinWidth
	local layer = overlay.Layer
	local layerPos, layerSize = layer.AbsolutePosition, layer.AbsoluteSize
	local aTop = anchor.AbsolutePosition.Y - layerPos.Y
	local aBottom = aTop + anchor.AbsoluteSize.Y
	local aLeft = anchor.AbsolutePosition.X - layerPos.X
	local measured = layerSize.Y > 0
	local below = if measured then layerSize.Y - aBottom - 8 else math.huge
	local above = if measured then aTop - 8 else math.huge
	local flipUp = contentH > below and above > below
	local avail = if flipUp then above else below
	local panelH = math.min(contentH, o.MaxHeight or math.huge, math.max(avail, ItemHeight + ListPadding * 2))
	-- the panel's center x for a given width (clamped into the layer when the layer is laid out)
	local function centerX(w: number): number
		local x = aLeft
		if layerSize.X > 0 then
			x = math.clamp(aLeft, 0, math.max(0, layerSize.X - w))
		end
		return x + w / 2
	end
	local y = if flipUp then aTop else aBottom
	local position: q.Source<UDim2> = q.Source(UDim2.fromOffset(centerX(width), y))
	local scrolls = panelH < contentH

	local navItems: { NavItem } = {}
	local navIndex: number? = nil
	local function register(inst: GuiObject, activate: () -> (), enabled: () -> boolean)
		local index = #navItems + 1
		navItems[index] = { Inst = inst, Activate = activate, Enabled = enabled }
		inst.SelectionGained:Connect(function()
			navIndex = index
		end)
	end

	-- the anchor going away (its screen was torn down) takes the menu with it: nothing else would close it, and its
	-- transparent scrim would keep swallowing clicks until one lands on it
	local anchorGone: RBXScriptConnection? = nil
	-- (fit) the panel and its UIScale, to read the laid-out width back
	local panel: Frame? = nil
	local panelScale: UIScale? = nil
	local handle = overlay:Open({
		Scrim = true,
		ScrimOpacity = 0,
		Dismissable = true,
		DismissOnEscape = true,
		TrapSelection = true,
		InitialSelection = function(): GuiObject?
			for _, nav in navItems do
				if nav.Enabled() then
					return nav.Inst
				end
			end
			return nil
		end,
		ExitTime = Tokens.Motion.Duration.Short2,
		OnClose = function(reason: Overlay.CloseReason, result: unknown?)
			local conn = anchorGone
			if conn ~= nil then
				anchorGone = nil
				conn:Disconnect()
			end
			if o.OnClose then
				o.OnClose(reason, result)
			end
		end,
		Content = function(handle: Overlay.Handle)
			local rows = {} :: { Instance }
			for _, e in o.Items do
				if type(e) == "string" then
					table.insert(rows, dividerRow(theme, fit))
				else
					table.insert(
						rows,
						itemRow(e, theme, function(): boolean
							if not handle.IsOpen:Get() then
								return false
							end
							handle.Close()
							return true
						end, register, fitCtx)
					)
				end
			end
			if fit then
				-- the minimum width: a 0-high spacer (the rows stretch to the widest sibling — header WIDTH)
				table.insert(rows, 1, D.Frame { Name = "MinWidth", Size = UDim2.fromOffset(MinWidth, 0), BackgroundTransparency = 1, BorderSizePixel = 0 })
			end
			local slot = q.Slot(rows)

			local shown = q.Source(false)
			local scale: q.State<number> = shown:Compute(function(self, _prev, closing)
				return if self:Get() and not closing:Get() then 1 else ClosedScale
			end, handle.Closing)

			local list = D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder }
			local pad = D.UIPadding { PaddingTop = UDim.new(0, ListPadding), PaddingBottom = UDim.new(0, ListPadding) }
			local body: Instance
			-- (fit) the list is as wide as its widest row and the panel as wide as the list
			local bodySize = if fit then UDim2.fromScale(0, 1) else UDim2.fromScale(1, 1)
			local bodyAuto = if fit then Enum.AutomaticSize.X else Enum.AutomaticSize.None
			if scrolls then
				body = D.ScrollingFrame {
					Name = "Scroll",
					Size = bodySize,
					AutomaticSize = bodyAuto,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					CanvasSize = UDim2.fromOffset(0, 0),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollBarThickness = 4,
					-- themed thumb (Tokens/State.luau `ScrollBar`); it overlays the rows (inset None), so an item's state
					-- layer and ripple reach the panel edge and show through the half-transparent thumb
					ScrollBarImageColor3 = theme.Color.OnSurface,
					ScrollBarImageTransparency = 1 - Tokens.State.Opacity.ScrollBar,
					VerticalScrollBarInset = Enum.ScrollBarInset.None,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					list,
					pad,
					slot,
				}
			else
				body = D.Frame {
					Name = "List",
					Size = bodySize,
					AutomaticSize = bodyAuto,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					list,
					pad,
					slot,
				}
			end

			local uiScale = D.UIScale { Scale = scale:Apply(q.Animate(Tokens.Motion.options("Short4", "EmphasizedDecelerate"))) }
			panelScale = uiScale
			if fitCtx then
				fitCtx.Scale = uiScale
			end
			local built = D.Frame {
				Name = "Menu",
				-- pivot at the TOP-CENTER (bottom-center when flipped): UIScale scales about the AnchorPoint, so a left
				-- pivot made the opening scale look glued to the left edge (Studio QA 2026-10-07)
				AnchorPoint = Vector2.new(0.5, if flipUp then 1 else 0),
				Position = position,
				Size = UDim2.fromOffset(if fit then 0 else width, panelH),
				AutomaticSize = if fit then Enum.AutomaticSize.X else Enum.AutomaticSize.None,
				BackgroundColor3 = theme.Color.SurfaceContainer,
				BorderSizePixel = 0,
				Active = true, -- 3D / camera input only; a GUI click is sunk by the ClickSink child below
				Util.clickSink(),
				UICorner = Corner,
				Elevation.Shadow({ Level = 2, Theme = theme }),
				uiScale,
				body,
				-- keyboard navigation: one connection for the life of this panel
				Util.preHook(function(inst: GuiObject)
					local conn = Input.service().InputBegan:Connect(function(input: InputObject, processed: boolean)
						if processed or not handle.IsOpen:Get() or #navItems == 0 then
							return
						end
						local kc = input.KeyCode
						if kc == Enum.KeyCode.Down or kc == Enum.KeyCode.Up then
							local n = #navItems
							local dir = if kc == Enum.KeyCode.Down then 1 else -1
							local i = navIndex
							-- step through the items (wrapping) until an enabled one comes up
							for _ = 1, n do
								if i == nil then
									i = if dir == 1 then 1 else n
								else
									i = (i - 1 + dir) % n + 1
								end
								if navItems[i].Enabled() then
									navIndex = i
									GuiService.SelectedObject = navItems[i].Inst
									break
								end
							end
						elseif kc == Enum.KeyCode.Return or kc == Enum.KeyCode.KeypadEnter then
							local i = navIndex
							if i ~= nil then
								navItems[i].Activate() -- (a disabled item's activate is a no-op)
							end
						end
					end)
					inst.Destroying:Connect(function()
						conn:Disconnect()
					end)
				end),
				-- mounted snapped at ClosedScale, then the second write animates
				Util.postHook(function()
					shown:Set(true)
				end),
			}
			panel = built
			return built
		end,
	})
	if handle.IsOpen:Get() then
		anchorGone = anchor.Destroying:Connect(function()
			handle.Close()
		end)
		local p, ps = panel, panelScale
		if fitCtx ~= nil and p ~= nil and ps ~= nil then
			-- (fit) place the panel by its laid-out width. Read only at FULL scale (see the trailing measure in itemRow):
			-- now — the panel is momentarily set to scale 1 and back to its closed scale in this same step, so nothing is
			-- drawn in between and the running open tween is not disturbed — and later whenever the full-scale width
			-- changes by 2 px or more (the end of the open animation, a FontFace that loads)
			local placing = false
			local placedWidth = 0
			local function place()
				if placing or ps.Scale ~= 1 then
					return
				end
				placing = true
				local w = math.ceil(p.AbsoluteSize.X - 0.01)
				if w > 0 and math.abs(w - placedWidth) >= 2 then
					placedWidth = w
					position:Set(UDim2.fromOffset(centerX(w), y))
				end
				placing = false
			end
			local closedScale = ps.Scale
			ps.Scale = 1
			for _, measure in fitCtx.Measures do
				measure() -- (direct calls: under Deferred signals the AbsoluteSize handlers would run after the restore)
			end
			place()
			ps.Scale = closedScale
			p:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
		end
	end
	return handle
end

export type ButtonProps = {
	read Label: string | q.State<string>,
	read Items: { Entry },
	read Variant: Button.Variant?,
	read Icon: (string | q.State<string>)?,
	read Width: number?,
	read Disabled: (boolean | q.State<boolean>)?,
	read Overlay: Overlay.Overlay?,
	read Theme: Theme.Theme?,
	read Modifier: q.TextButtonModifier?,
	read Hooks: Util.Hooks?,
}

-- A `Button` that opens `Items` under itself (the menu is rebuilt per open; the Button is the anchor).
local function MenuButton(props: ButtonProps)
	local btn: GuiObject? = nil
	local el = Button({
		Variant = props.Variant,
		Label = props.Label,
		Icon = props.Icon,
		Disabled = props.Disabled,
		Theme = props.Theme,
		Modifier = props.Modifier,
		Hooks = props.Hooks,
		OnClick = function()
			local a = btn
			if a ~= nil then
				open({ Anchor = a, Items = props.Items, Overlay = props.Overlay, Theme = props.Theme, Width = props.Width })
			end
		end,
	})
	btn = el
	return el
end

return {
	open = open,
	Button = MenuButton,
}
