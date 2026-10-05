--!strict
--[[
	M3 basic dialog, opened through the kit Overlay (docs/how-to/09).

	    local handle = Dialog.open({
	        Icon = "rbxassetid://1",                       -- optional, 24 px, centers the headline
	        Headline = "Discard draft?",
	        Body = "Your changes will be lost.",           -- string, or a fresh Instance (static child of the dialog)
	        Actions = {
	            { Label = "Cancel", Result = false },
	            { Label = "Discard", Result = true, OnClick = discard },
	        },
	    })
	    handle.Close(true)                                 -- close from code (idempotent, no self), with a result
	    handle.Result                                      -- Source<unknown?>: nil while open, the result once closing starts
	    Dialog.confirm({ Headline = "Delete?", Body = "...", OnClose = function(ok) ... end })   -- Cancel/OK, Result true/false
	    Dialog.alert({ Headline = "Saved", Body = "..." })                                        -- one OK button

	OpenOptions (all `read`):
	  Headline  string?                  HeadlineSmall, onSurface
	  Icon      string?                  image asset id, secondary color
	  Body      (string | Instance)?     BodyMedium onSurfaceVariant text, or your element (it is seated in the dialog and destroyed with it)
	  Actions   { Action }?              text buttons, right aligned. Action = { Label, Result?, OnClick?, Variant?, Disabled? }:
	                                     a click runs OnClick, then closes with Result. Variant default "Text" (kit Button)
	  Width     number?                  default 312, clamped to the M3 range 280..560
	  DismissOnScrim, DismissOnEscape  boolean?   default true; Escape / gamepad B close the TOP dialog only (the Overlay
	                                     owns the Escape plumbing; see Overlay.DismissOnEscape)
	  DismissResult  unknown?            result reported when dismissed (scrim, Escape) rather than by an action
	  OnClose   ((result: unknown?) -> ())?  once, at the start of closing
	  Overlay   Overlay?                 default `Overlay.default()`;  Theme  Theme?
	Handle (the kit-wide shape): Close(result?) (a closure, no self), IsOpen / Closing State<boolean> (the overlay handle
	ones), Result Source<unknown?>.

	Structure: scrim (Overlay, 0.32) + ONE CanvasGroup (surfaceContainerHigh, corner 28, padding 24, vertical list) +
	icon / headline / body / actions row + one kit Button per action. Enter: mounted snapped (transparent, scale 0.8)
	and animated from a PostRef hook: fade 200 ms + scale 300 ms emphasized-decelerate. Exit: fade 200 ms while the Overlay
	holds it in its closing phase (Closing = true), then it is destroyed. Escape / B, the scrim's `Selectable = false` and
	the gamepad selection trap (`TrapSelection`, first enabled action = `InitialSelection`) are the Overlay's; a dialog
	whose layer is destroyed is finalized by the Overlay (IsOpen false, OnClose once, Result = DismissResult).
	Small screens: when the overlay layer is laid out (AbsoluteSize > 0 at open) the width is capped at layer width - 48 and
	the body sits in a ScrollingFrame (`BodyScroll`) capped so the card stays within layer height - 48, with the headline
	and the actions pinned. Not re-measured after open (a resize while open keeps the open-time caps). An unmeasured layer
	(no layout yet, a mock) gets no caps and no scroll wrapper.
	CanvasGroup lifetime: the group (needed for the fade) stays a CanvasGroup for the dialog's whole life — an offscreen
	texture composited every frame while it is up. Fine for one short-lived dialog; swapping to a plain Frame once the enter
	animation ends is possible but not done (it would also lose the exit fade).
	M3 deviations: no shadow (a UIShadow inside the CanvasGroup would be clipped; the scrim does the separating).
	Active = true on the surface keeps clicks on the dialog body from reaching the dismissing scrim.
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Text = require("./Text")
local Overlay = require("./Overlay")
local Button = require("./Button")
local D = q.Declaration

export type Action = {
	read Label: string,
	read Result: unknown?,
	read OnClick: (() -> ())?,
	read Variant: Button.Variant?,
	read Disabled: (boolean | q.State<boolean>)?,
}

export type OpenOptions = {
	read Headline: string?,
	read Icon: string?,
	read Body: (string | Instance)?,
	read Actions: { Action }?,
	read Width: number?,
	read DismissOnScrim: boolean?,
	read DismissOnEscape: boolean?,
	read DismissResult: unknown?,
	read OnClose: ((result: unknown?) -> ())?,
	read Overlay: Overlay.Overlay?,
	read Theme: Theme.Theme?,
}

export type Handle = {
	Close: (result: unknown?) -> (),
	read Result: q.Source<unknown?>,
	read IsOpen: q.State<boolean>,
	read Closing: q.State<boolean>,
}

export type ConfirmOptions = {
	read Headline: string?,
	read Icon: string?,
	read Body: (string | Instance)?,
	read ConfirmLabel: string?,
	read CancelLabel: string?,
	read Width: number?,
	read OnClose: ((confirmed: boolean) -> ())?,
	read Overlay: Overlay.Overlay?,
	read Theme: Theme.Theme?,
}

local LayerMargin = 24 -- min distance between the card and the layer edge when the layer is measured
local ScrollBodyMin = 72
local headlineStyle = Text.Label("HeadlineSmall")
local bodyStyle = Text.Label("BodyMedium")

local function open(o: OpenOptions): Handle
	local overlay = o.Overlay or Overlay.default()
	local theme = Theme.resolve(o.Theme)
	local width = math.clamp(o.Width or 312, 280, 560)
	local layerSize = overlay.Layer.AbsoluteSize
	local measured = layerSize.X > 0 and layerSize.Y > 0
	if measured then
		width = math.min(width, math.max(layerSize.X - 2 * LayerMargin, 0))
	end
	local result = q.Source(nil :: unknown?)

	local ovHandle: Overlay.Handle? = nil
	local firstAction: GuiObject? = nil

	local function close(r: unknown?)
		local ov = ovHandle
		if ov ~= nil then
			ov.Close(r) -- the Overlay keeps the FIRST close (idempotent) and hands `r` to OnClose
		end
	end

	-- `reason` is "Close" for an action / `handle.Close(r)` (r is the result); scrim / Escape / layer death report DismissResult
	local function onClosing(reason: Overlay.CloseReason, r: unknown?)
		local final = if reason == "Close" then r else o.DismissResult
		result:Set(final)
		if o.OnClose then
			o.OnClose(final)
		end
	end

	local function build(h: Overlay.Handle): Instance
		ovHandle = h
		local entered = q.Source(false)
		local fadeTarget: q.State<number> = entered:Compute(function(self, _prev, closing)
			return if self:Get() and not closing:Get() then 0 else 1
		end, h.Closing)
		local scaleTarget: q.State<number> = entered:Compute(function(self)
			return if self:Get() then 1 else 0.8
		end)
		local fade = fadeTarget:Apply(q.Animate(Tokens.Motion.options("Short4", "Linear")))
		local scale = scaleTarget:Apply(q.Animate(Tokens.Motion.options("Medium2", "EmphasizedDecelerate")))

		local hasIcon = o.Icon ~= nil
		local icon: Instance? = nil
		if o.Icon ~= nil then
			icon = D.ImageLabel {
				Name = "Icon",
				Size = UDim2.fromOffset(24, 24),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = o.Icon,
				ImageColor3 = theme.Color.Secondary,
				LayoutOrder = 1,
			}
		end

		local headline: Instance? = nil
		if o.Headline ~= nil then
			headline = D.TextLabel {
				Name = "Headline",
				headlineStyle,
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = o.Headline,
				TextColor3 = theme.Color.OnSurface,
				TextWrapped = true,
				TextXAlignment = if hasIcon then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				LayoutOrder = 2,
			}
		end

		local body: Instance? = nil
		local b = o.Body
		local bodyInner: Instance? = nil
		if type(b) == "string" then
			bodyInner = D.TextLabel {
				Name = "Body",
				bodyStyle,
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = b,
				TextColor3 = theme.Color.OnSurfaceVariant,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				LayoutOrder = 3,
			}
		elseif b ~= nil then
			bodyInner = D.Frame {
				Name = "Body",
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = 3,
				b :: Instance,
			}
		end
		if bodyInner ~= nil then
			if measured then
				-- the card never outgrows the layer: the body scrolls, headline and actions stay pinned
				local fixed = 0
				local parts = 1
				if hasIcon then
					fixed += 24
					parts += 1
				end
				if o.Headline ~= nil then
					fixed += 32
					parts += 1
				end
				if o.Actions ~= nil and #o.Actions > 0 then
					fixed += 48
					parts += 1
				end
				local maxBody = math.max(ScrollBodyMin, layerSize.Y - 2 * LayerMargin - 48 - fixed - 16 * (parts - 1))
				body = D.ScrollingFrame {
					Name = "BodyScroll",
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2.fromOffset(0, 0),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ScrollBarThickness = 4,
					VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = 3,
					D.UISizeConstraint { MaxSize = Vector2.new(math.huge, maxBody) },
					bodyInner,
				}
			else
				body = bodyInner
			end
		end

		local actionsRow: Instance? = nil
		local actions = o.Actions
		if actions ~= nil and #actions > 0 then
			local buttons: { Instance } = {}
			for i, a in actions do
				local btn = Button({
						Variant = a.Variant or "Text",
						Label = a.Label,
						Disabled = a.Disabled,
						Theme = theme,
						OnClick = function()
							if a.OnClick then
								a.OnClick()
							end
							close(a.Result)
						end,
						Modifier = D.Modifier.TextButton():LayoutOrder(i),
					})
				if firstAction == nil and not Util.peekBool(a.Disabled) then
					firstAction = btn
				end
				table.insert(buttons, btn)
			end
			actionsRow = D.Frame {
				Name = "Actions",
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = 4,
				D.UIPadding { PaddingTop = UDim.new(0, 8) }, -- 16 list gap + 8 = M3's 24 above the actions
				D.UIListLayout {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 8),
				},
				table.unpack(buttons),
			}
		end

		return D.CanvasGroup {
			Name = "Dialog",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(width, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = theme.Color.SurfaceContainerHigh,
			BorderSizePixel = 0,
			Active = true,
			GroupTransparency = fade,
			UIScale = scale,
			UICorner = Tokens.Shape.corner("ExtraLarge"),
			UIPaddingOffset = 24,
			Util.postHook(function()
				entered:Set(true)
			end),
			D.UIListLayout {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = if hasIcon then Enum.HorizontalAlignment.Center else Enum.HorizontalAlignment.Left,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 16),
			},
			icon or q.None,
			headline or q.None,
			body or q.None,
			actionsRow or q.None,
		} :: GuiObject
	end

	local ov = overlay:Open({
		Content = build,
		Scrim = true,
		Dismissable = o.DismissOnScrim ~= false,
		DismissOnEscape = o.DismissOnEscape ~= false,
		TrapSelection = true,
		InitialSelection = function(): GuiObject?
			return firstAction
		end,
		OnClose = onClosing,
	})
	ovHandle = ov
	local handle: Handle = { Close = close, Result = result, IsOpen = ov.IsOpen, Closing = ov.Closing }
	return handle
end

local function confirm(o: ConfirmOptions): Handle
	local onClose = o.OnClose
	return open({
		Headline = o.Headline,
		Icon = o.Icon,
		Body = o.Body,
		Width = o.Width,
		Overlay = o.Overlay,
		Theme = o.Theme,
		DismissResult = false,
		Actions = {
			{ Label = o.CancelLabel or "Cancel", Result = false },
			{ Label = o.ConfirmLabel or "OK", Result = true },
		},
		OnClose = function(result: unknown?)
			if onClose then
				onClose(result == true)
			end
		end,
	})
end

local function alert(o: ConfirmOptions): Handle
	local onClose = o.OnClose
	return open({
		Headline = o.Headline,
		Icon = o.Icon,
		Body = o.Body,
		Width = o.Width,
		Overlay = o.Overlay,
		Theme = o.Theme,
		DismissResult = true,
		Actions = { { Label = o.ConfirmLabel or "OK", Result = true } },
		OnClose = function(_result: unknown?)
			if onClose then
				onClose(true)
			end
		end,
	})
end

return {
	open = open,
	confirm = confirm,
	alert = alert,
}
