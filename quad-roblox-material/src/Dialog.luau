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
	  Fit       boolean?                 small layers: scale the WHOLE card down (a UIScale factor, like the DatePicker modal)
	                                     instead of capping the width and scrolling the body (default false). For a body that
	                                     is a tool rather than text — the ColorPicker modal: its SV area and sliders are drag
	                                     surfaces, which a scrolling body would fight, and its rows have fixed widths.
	  OnClose   ((result: unknown?) -> ())?  once, at the start of closing
	  Overlay   Overlay?                 default `Overlay.default()`;  Theme  Theme?
	Handle (the kit-wide shape): Close(result?) (a closure, no self), IsOpen / Closing State<boolean> (the overlay handle
	ones), Result Source<unknown?>.

	Structure: scrim (Overlay, 0.32) + ONE CanvasGroup (surfaceContainerHigh, corner 28, padding 24, vertical list) +
	icon / headline / body / actions row + one kit Button per action. Enter: mounted snapped (transparent, scale 0.8)
	and animated from a PostRef hook: fade 200 ms + scale 300 ms emphasized-decelerate. Exit: fade 200 ms + scale to .92 while
	the Overlay holds it in its closing phase (Closing = true), then it is destroyed. (Nothing inside may grow the auto-sized
	card while it closes: the clicked action's ripple used to reach past the button and, through AutomaticSize, stretch
	the actions row and the card — fixed in Ripple.luau, "BOUNDED".) Escape / B, the scrim's `Selectable = false` and
	the gamepad selection trap (`TrapSelection`, first enabled action = `InitialSelection`) are the Overlay's; a dialog
	whose layer is destroyed is finalized by the Overlay (IsOpen false, OnClose once, Result = DismissResult).
	Small screens: when the overlay layer is laid out (AbsoluteSize > 0 at open) the width is capped at layer width - 48 and
	the body sits in a ScrollingFrame (`BodyScroll`) capped so the card stays within layer height - 48, with the headline
	and the actions pinned. An unmeasured layer (no layout yet, a mock) gets no caps and no scroll wrapper.
	CAP (the body's): layer height - 48 - everything in the card that is not the body. Of that, the padding (48), the
	icon (24), the actions row (8 + the 40 px Button) and the 16 px gaps are sizes M3 fixes — constants; the HEADLINE is
	text that wraps (24 for one line at HeadlineSmall, +32 per further line), so its laid-out height is read the way the
	body's is (below) and the cap follows it: a headline of two or three lines takes its lines from the body's window,
	not from the layer margin, and a one-line headline leaves exactly the 24 px margin. Until the headline is laid out it
	counts as one 32 px line; a later change of its height (its text or font replaced from outside) is followed. The cap
	never goes under 72 (`ScrollBodyMin`): on a layer too small for that the card overflows rather than leaving the body
	no window. During the enter / exit scale the headline's local height wobbles like any text (BODY HEIGHT below), so
	the cap of an overflowing body can move by a pixel for those frames.
	KNOWN LIMITS (decided 2026-10-13, not handled): (1) the layer is read ONCE, at open — a window resized while the
	dialog is open keeps the open-time width cap and body cap; (2) the layer size is in screen pixels while the caps
	are used in the card's local units, so under an ancestor UIScale above 1 the card can come out larger than the
	layer by that factor (below 1: smaller than it had to be).
	BODY HEIGHT (the scroll wrapper): the kit WRITES the wrapper's height; the engine's automatic sizing is not used for
	it. The body (`Body`, AutomaticSize Y) is laid out in `BodyRoom`, a transparent frame of a fixed, very tall height
	inside the wrapper; its laid-out height H is read from its AbsoluteSize (re-read whenever that changes, so a body
	that grows or shrinks later is followed) and the wrapper gets Size.Y = min(max(H, 1), cap) and CanvasSize.Y = H above
	the cap, 0 (= the window) within it: the card fits a body below the cap exactly, with nothing to scroll, and only the
	body scrolls above it. H is in the card's local units: Body.AbsoluteSize.Y / card.AbsoluteSize.X * width — both come
	from the same layout pass and every UIScale (the card's animated one, any ancestor's) scales both, so no scale is
	read (the Fit ratio below, the other way round). H is rounded UP to a whole pixel (less 0.001 of float noise): a
	UDim offset is an integer, so a fractional height — an ancestor UIScale of 1.25 makes a 17 px line 13.6 local
	units — would be cut and clip the body's last row. A proportionally scaled body therefore gives the same H on every
	frame of the enter / exit scale; a TEXT body does not — the engine lays text out in whole screen pixels, so its
	local height wobbles by a pixel or two per line while the scale animates (the label's own AbsoluteSize does; an
	auto-sized label outside the wrapper takes its parent along the same way). No loop: the body's height does not
	depend on the wrapper's (only on its width, and a visible scrollbar can only make a body that already overflows
	taller).
	Why not `AutomaticSize = Y` + `AutomaticCanvasSize = Y` + a UISizeConstraint on the wrapper (the form until
	2026-10-13) — engine behaviours measured in Studio with hand-built instances (no kit):
	  1. an auto-sized ScrollingFrame that is a direct child of an auto-sized, UIListLayout-laid frame WITH a UIPadding
	     makes that parent lose min(its vertical padding, the scroll frame's height) of its own automatic height (the
	     card was 48 short — Content's 24 + 24 — and the actions row hung out of it; 14 short with a one-line body).
	     No UIPadding, no UIListLayout, a plain Frame instead of the ScrollingFrame, or an explicit height: correct.
	  2. AutomaticSize ignores a UISizeConstraint's MaxSize (the frame's AbsoluteSize is its content's), so the cap
	     never held.
	  3. a wrapped, auto-sized TextLabel is never taller than the nearest ancestor with a definite height (inside a
	     ScrollingFrame: its canvas), so a long string body was cut at the window instead of scrolling — and a wrapper
	     sized from the label would stay one line tall. Hence `BodyRoom`.
	  4. under a ZERO-height clipping ancestor the engine stops updating a descendant's AbsoluteSize (no changed signal
	     while a UIScale animates, none for a TextLabel whose text changes; the first signal of a text body can carry
	     height 0), so a wrapper that started at 0 could stay there. Hence the 1 px floor — the one visible trace: a
	     body that is 0 tall (an empty element) still gets a 1 px window.
	`Fit = true` instead: no caps, no scroll wrapper; the card keeps its width and natural height and its UIScale is
	multiplied by fit = min(1, (layer width - 48) / width, (layer height - 48) / natural height), floored at 0.25 (the
	DatePicker modal's floor — below it the card would be unusable anyway, so it is left to clip rather than adding a
	second mechanism). The natural height is read from the laid-out card: AbsoluteSize.Y / AbsoluteSize.X * width (the
	UIScale scales both axes, so the ratio is the unscaled one), re-read whenever the card's AbsoluteSize changes (the
	ratio is constant while the scale animates, so only a real content change refits); the layer size is the open-time one.
	CanvasGroup lifetime: the group (needed for the fade) stays a CanvasGroup for the dialog's whole life — an offscreen
	texture composited every frame while it is up. Fine for one short-lived dialog; swapping to a plain Frame once the enter
	animation ends is possible but not done (it would also lose the exit fade).
	M3 deviations: no shadow (a UIShadow inside the CanvasGroup would be clipped; the scrim does the separating).
	Input: only a GuiButton sinks a GUI click (Active = true on a Frame does not), so the surface carries a `Util.clickSink()`
	child; the list-laid content lives in an inner "Content" frame so the sink stays a full-cover sibling.
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
	read Fit: boolean?,
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
-- HeadlineSmall's line height: what the headline counts for in the body cap until it is laid out (header, "CAP")
local HeadlineEstimate = 32
-- the height of the frame the body is laid out in inside the scroll wrapper (header, "BODY HEIGHT" 3): only ever a bound
-- for the body's own automatic height, so any value no body reaches
local BodyRoom = 100000
local ScrollBodyFloor = 1 -- the scroll wrapper's least height (header, "BODY HEIGHT" 4)
local FitMin = 0.25 -- the DatePicker modal's floor (DatePicker/Modal.luau)
local headlineStyle = Text.Label("HeadlineSmall")
local bodyStyle = Text.Label("BodyMedium")

local function open(o: OpenOptions): Handle
	local overlay = o.Overlay or Overlay.default()
	local theme = Theme.resolve(o.Theme)
	local width = math.clamp(o.Width or 312, 280, 560)
	local layerSize = overlay.Layer.AbsoluteSize
	local measured = layerSize.X > 0 and layerSize.Y > 0
	local fitMode = o.Fit == true
	-- Fit: the card keeps its size and is scaled as a whole; this factor joins the animated UIScale (see header)
	local fit = q.Source(1)
	if measured and not fitMode then
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
		-- exit: also shrinks a little (to .92 — Quint Out reaches almost all of it within the 0.2 s exit), like the
		-- DatePicker modal's card, instead of a fade alone (Studio QA 2026-10-07, 2nd: "vanishes ambiguously, unlike the
		-- date picker")
		local scaleTarget: q.State<number> = entered:Compute(function(self, _prev, closing, fitFactor)
			local f = fitFactor:Get()
			if not self:Get() then
				return 0.8 * f
			end
			return (if closing:Get() then 0.92 else 1) * f
		end, h.Closing, fit)
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

		local headline: GuiObject? = nil
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
		local bodyInner: GuiObject? = nil
		-- set when the body sits in the scroll wrapper: starts the measurements (run from the card's PostRef hook)
		-- a no-op until the body sits in the scroll wrapper (not an optional: luau-lsp 1.70.1 cannot call a refined
		-- optional-function upvalue — `((GuiObject) -> ()) & ~nil` in a union)
		local watchLayout: (card: GuiObject) -> () = function(_card: GuiObject) end
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
			if measured and not fitMode then
				-- the card never outgrows the layer: the body scrolls, headline and actions stay pinned (header, "CAP")
				-- everything in the card but the headline and the body — sizes M3 fixes, so constants
				local fixed = 48 -- Content's padding, 24 + 24
				local parts = 1
				if hasIcon then
					fixed += 24
					parts += 1
				end
				if headline ~= nil then
					parts += 1
				end
				if o.Actions ~= nil and #o.Actions > 0 then
					fixed += 48 -- 8 padding + the 40 px Button
					parts += 1
				end
				fixed += 16 * (parts - 1)
				-- what the headline and the body share
				local room = layerSize.Y - 2 * LayerMargin - fixed
				-- the laid-out heights in the card's local units (header, "BODY HEIGHT"): the body's is 0 until the first
				-- layout, the headline's is the one-line estimate until then
				local bodyHeight = q.Source(0)
				local headlineHeight = q.Source(if headline ~= nil then HeadlineEstimate else 0)
				local maxBody: q.State<number> = headlineHeight:Compute(function(self)
					return math.max(ScrollBodyMin, room - self:Get())
				end)
				local inner: GuiObject = bodyInner
				local head: GuiObject? = headline
				watchLayout = function(card: GuiObject)
					-- nil while the card has no width. Up to the whole pixel (a UDim offset is an integer: a fraction would be
					-- cut and clip the body's last row), less the float noise of a scaled layout
					local function localHeight(inst: GuiObject): number?
						local cardWidth = card.AbsoluteSize.X
						if cardWidth <= 0 then
							return nil
						end
						return math.ceil(inst.AbsoluteSize.Y / cardWidth * width - 1e-3)
					end
					local function readBody()
						local height = localHeight(inner)
						if height ~= nil then
							bodyHeight:SetIfChanged(height)
						end
					end
					-- each part's own signal: disconnected with the part
					inner:GetPropertyChangedSignal("AbsoluteSize"):Connect(readBody)
					readBody()
					if head ~= nil then
						local label: GuiObject = head
						local function readHeadline()
							local height = localHeight(label)
							-- 0 = not laid out yet (a headline is at least one line tall): the estimate stays
							if height ~= nil and height > 0 then
								headlineHeight:SetIfChanged(height)
							end
						end
						label:GetPropertyChangedSignal("AbsoluteSize"):Connect(readHeadline)
						readHeadline()
					end
				end
				-- never 0 tall (header, "BODY HEIGHT" 4): a body under a zero-height window is not measured again
				local scrollSize: q.State<UDim2> = bodyHeight:Compute(function(self, _prev, cap)
					return UDim2.new(1, 0, 0, math.min(math.max(self:Get(), ScrollBodyFloor), cap:Get()))
				end, maxBody)
				-- canvas 0 = the window: a body within the cap cannot scroll (and shows no scrollbar) whatever the rounding
				local canvasSize: q.State<UDim2> = bodyHeight:Compute(function(self, _prev, cap)
					local height = self:Get()
					return UDim2.fromOffset(0, if height > cap:Get() then height else 0)
				end, maxBody)
				body = D.ScrollingFrame {
					Name = "BodyScroll",
					Size = scrollSize,
					CanvasSize = canvasSize,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ScrollBarThickness = 4,
					ScrollBarImageColor3 = theme.Color.OnSurface,
					ScrollBarImageTransparency = 1 - Tokens.State.Opacity.ScrollBar,
					VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = 3,
					D.Frame {
						Name = "BodyRoom",
						Size = UDim2.new(1, 0, 0, BodyRoom),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						bodyInner,
					},
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
							-- the card stays mounted (and clickable) while it animates out: a second tap on an action
							-- within the exit time must not run its OnClick again
							local ov = ovHandle
							if ov == nil or not ov.IsOpen:Get() then
								return
							end
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
			Util.clickSink(),
			Util.postHook(function(card: GuiObject)
				entered:Set(true)
				watchLayout(card)
				if fitMode and measured then
					local function refit()
						local abs = card.AbsoluteSize
						if abs.X <= 0 or abs.Y <= 0 then
							return
						end
						local natural = abs.Y / abs.X * width
						local f = math.min(1, (layerSize.X - 2 * LayerMargin) / width, (layerSize.Y - 2 * LayerMargin) / natural)
						f = math.max(f, FitMin)
						if math.abs(f - fit:Get()) > 1e-3 then
							fit:Set(f)
						end
					end
					-- the card's own signal: disconnected with the card
					card:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit)
					refit()
				end
			end),
			D.Frame {
				Name = "Content",
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				UIPaddingOffset = 24,
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
			},
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
