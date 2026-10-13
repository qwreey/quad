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

	OpenOptions
	  Anchor     GuiObject                       position source: `AbsolutePosition`/`AbsoluteSize` are read ONCE at open;
	                                             the menu closes when the anchor is destroyed
	  Items      { Item | "divider" }            fixed for the lifetime of the open menu (it is rebuilt per open)
	  Overlay    Overlay.Overlay?                default `Overlay.default()`
	  Theme      Theme?
	  Width      number?                         default = anchor width clamped to 112..280 (M3 min/max; the menu does
	                                             NOT fit its widest item — Roblox cannot measure FontFace text
	                                             synchronously; pass `Width` for a wider list)
	  MaxHeight  number?                         the list scrolls past this (default: the room left on screen)
	  OnClose    Overlay.OnCloseFn?      once, at the start of closing (item click, outside click, Escape, `.Close()`,
	                                             or "Destroyed" when the overlay layer died)
	Item = { Label, OnClick?, Disabled? (boolean | State<boolean>, read live: a disabled item is skipped by the keyboard
	         navigation and does nothing when activated; no item does anything once the menu is closing), Leading? (image id), Trailing? (image id, or any other string = text),
	         Selected? (container highlight, as the Select field shows the chosen option) }

	Placement: below the anchor, flipped above when the list does not fit below and there is more room above;
	clamped horizontally into the overlay layer (so the layer's AbsoluteSize must be laid out — with a zero
	size, e.g. a mock, no flipping/clamping happens). Coordinates are converted to layer space, so a ScreenGui
	inset does not matter.

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

	Per item at rest: TextButton + state layer (Frame, UICorner, UIStroke) + label = 5 (+1 per icon/trailing text);
	a press adds the transient ripple (Ripple.luau, 3) over the whole row — the M3 DropdownMenuItem has a bounded ripple
	(Compose Menu.kt, see itemRow). Panel: Frame, UICorner, UIShadow, UIScale (+ScrollingFrame when it scrolls),
	UIListLayout, UIPadding. Divider = 2.
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
local MinWidth, MaxWidth = 112, 280
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

local function itemRow(
	item: Item,
	theme: Theme.Theme,
	close: () -> boolean, -- closes the menu; false when it was closed already (the item then does nothing)
	register: (inst: GuiObject, activate: () -> (), enabled: () -> boolean) -> ()
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
				Size = UDim2.new(0, TrailingTextWidth, 1, 0),
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
		Size = UDim2.new(1, 0, 0, ItemHeight),
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
		fx.Layer,
		leadingIcon or q.None,
		D.TextLabel {
			Name = "Label",
			labelLarge,
			Position = UDim2.fromOffset(left, 0),
			Size = UDim2.new(1, -(left + right), 1, 0),
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

local function dividerRow(theme: Theme.Theme)
	return D.Frame {
		Name = "Divider",
		Size = UDim2.new(1, 0, 0, DividerHeight),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
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
	local width = o.Width or math.clamp(anchor.AbsoluteSize.X, MinWidth, MaxWidth)
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
	local x = aLeft
	if layerSize.X > 0 then
		x = math.clamp(aLeft, 0, math.max(0, layerSize.X - width))
	end
	local y = if flipUp then aTop else aBottom
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
					table.insert(rows, dividerRow(theme))
				else
					table.insert(
						rows,
						itemRow(e, theme, function(): boolean
							if not handle.IsOpen:Get() then
								return false
							end
							handle.Close()
							return true
						end, register)
					)
				end
			end
			local slot = q.Slot(rows)

			local shown = q.Source(false)
			local scale: q.State<number> = shown:Compute(function(self, _prev, closing)
				return if self:Get() and not closing:Get() then 1 else ClosedScale
			end, handle.Closing)

			local list = D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder }
			local pad = D.UIPadding { PaddingTop = UDim.new(0, ListPadding), PaddingBottom = UDim.new(0, ListPadding) }
			local body: Instance
			if scrolls then
				body = D.ScrollingFrame {
					Name = "Scroll",
					Size = UDim2.fromScale(1, 1),
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
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					list,
					pad,
					slot,
				}
			end

			return D.Frame {
				Name = "Menu",
				-- pivot at the TOP-CENTER (bottom-center when flipped): UIScale scales about the AnchorPoint, so a left
				-- pivot made the opening scale look glued to the left edge (Studio QA 2026-10-07)
				AnchorPoint = Vector2.new(0.5, if flipUp then 1 else 0),
				Position = UDim2.fromOffset(x + width / 2, y),
				Size = UDim2.fromOffset(width, panelH),
				BackgroundColor3 = theme.Color.SurfaceContainer,
				BorderSizePixel = 0,
				Active = true, -- 3D / camera input only; a GUI click is sunk by the ClickSink child below
				Util.clickSink(),
				UICorner = Corner,
				Elevation.Shadow({ Level = 2, Theme = theme }),
				D.UIScale { Scale = scale:Apply(q.Animate(Tokens.Motion.options("Short4", "EmphasizedDecelerate"))) },
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
		end,
	})
	if handle.IsOpen:Get() then
		anchorGone = anchor.Destroying:Connect(function()
			handle.Close()
		end)
	end
	return handle
end

export type ButtonProps = {
	read Label: string | q.State<string>,
	read Items: { Entry },
	read Variant: Button.Variant?,
	read Icon: (string | q.State<string>)?,
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
				open({ Anchor = a, Items = props.Items, Overlay = props.Overlay, Theme = props.Theme })
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
