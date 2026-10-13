--!strict
--[[
	Snackbar view: the card for ONE snackbar (init.luau owns the queue, the timers and the Overlay handle; this file only
	draws and reports).

	    View.build({ Text, Action, Close, Width, Theme, Position, BottomOffset, Closing = handle.Closing,
	                 OnHover, OnFocus, OnAction, OnClose, OnDestroyed }) -> CanvasGroup

	Structure: ONE CanvasGroup (inverseSurface, corner 4, row layout) holding the message (BodyMedium, inverseOnSurface,
	wraps; one line = 48 px, two lines = 68 px as in M3) plus an optional action TextButton and an optional close
	`GlyphButton` (each with the kit state layer). Enter: mounted snapped (transparent, 24 px low) and animated from a
	PostRef hook: 250 ms slide up (emphasized decelerate) and fade; exit: the reverse while `Closing` is true.
	Place (`Position`, the host's): "Bottom" = centered, its bottom edge `BottomOffset` above the layer's bottom; "Top" = the
	mirror image — centered, its top edge `BottomOffset` below the layer's top, mounted 24 px HIGH and sliding down (the
	same distance, times and easings; the card itself is the same). Canon has no place of its own to mirror: Compose's
	Snackbar is put wherever the caller puts its SnackbarHost (init.luau "POSITION").
	Touch targets: the action and close buttons are 48 px tall (close 48 x 48) transparent hit hosts around a 36 px visual
	(state layer + label), so the card stays 48 px (one line) / 68 px (two lines) as in M3.
	Reports (all callbacks, no queue knowledge here): `OnHover(over)` pointer over the card; `OnFocus(delta)` a button gained
	(+1) / lost (-1) gamepad / keyboard selection; `OnAction` / `OnClose` a button was activated; `OnDestroyed` the card instance
	is being destroyed.
	CanvasGroup lifetime: the group (needed for the fade) stays a CanvasGroup for the snackbar's whole life — an offscreen
	texture composited every frame while it is up (see init.luau).
	M3 deviations: no shadow (a UIShadow inside the CanvasGroup would be clipped).
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Util = require("../Util")
local Text = require("../Text")
local Interactive = require("../Interactive")
local Icons = require("../Icons")
local GlyphButton = require("../GlyphButton")
local D = q.Declaration

export type Action = { read Label: string, read OnClick: () -> () }

export type Position = "Bottom" | "Top"

export type Options = {
	Text: string,
	Action: Action?,
	Close: boolean?,
	Width: number?,
	Theme: Theme.Theme,
	Position: Position,
	BottomOffset: number,
	Closing: q.State<boolean>,
	OnHover: (over: boolean) -> (),
	OnFocus: (delta: number) -> (),
	OnAction: () -> (),
	OnClose: () -> (),
	OnDestroyed: () -> (),
}

local bodyStyle = Text.Label("BodyMedium")
local actionStyle = Text.Label("LabelLarge")
local SlideDistance = 24

-- a 48 px tall transparent hit host around a 36 px visual: the text action (content-sized)
local function actionButton(o: Options, act: Action): Instance
	local theme = o.Theme
	local corner = Tokens.Shape.corner("Full")
	local color = theme.Color.InversePrimary
	local fx = Interactive.new({ Theme = theme, OnColor = color, Corner = corner })
	return D.TextButton {
		Name = "Action",
		Size = UDim2.fromOffset(0, 48),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = 2,
		fx.Hook,
		Util.preHook(function(inst: GuiObject)
			inst.SelectionGained:Connect(function()
				o.OnFocus(1)
			end)
			inst.SelectionLost:Connect(function()
				o.OnFocus(-1)
			end)
		end),
		Activated = function()
			act.OnClick()
			o.OnAction()
		end,
		D.Frame {
			Name = "Visual",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromOffset(0, 36),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			UICorner = corner,
			fx.Layer,
			D.Frame {
				Name = "Content",
				Size = UDim2.fromOffset(0, 36),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				D.UIPadding { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) },
				D.TextLabel {
					Name = "Label",
					actionStyle,
					Size = UDim2.fromOffset(0, 36),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Text = act.Label,
					TextColor3 = color,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
				},
			},
		},
	}
end

local function closeButton(o: Options): Instance
	return GlyphButton.new({
		Name = "Close",
		Glyph = Icons.glyph("close"),
		Asset = Icons.asset("close"),
		Size = 36,
		Hit = 48,
		ColorRole = "InverseOnSurface",
		TextSize = 24,
		Role = "LabelLarge",
		LayoutOrder = 3,
		Theme = o.Theme,
		OnClick = o.OnClose,
		Hooks = {
			Util.preHook(function(inst: GuiObject)
				inst.SelectionGained:Connect(function()
					o.OnFocus(1)
				end)
				inst.SelectionLost:Connect(function()
					o.OnFocus(-1)
				end)
			end),
		},
	})
end

local function build(o: Options): GuiObject
	local theme = o.Theme
	local edge = o.BottomOffset
	local atTop = o.Position == "Top"
	local entered = q.Source(false)
	local shown: q.State<boolean> = entered:Compute(function(self, _prev, closing)
		return self:Get() and not closing:Get()
	end, o.Closing)
	local fadeTarget: q.State<number> = shown:Compute(function(self)
		return if self:Get() then 0 else 1
	end)
	local yTarget: q.State<UDim2> = shown:Compute(function(self)
		-- away from the screen while hidden: below its place at the bottom, above it at the top
		local away = if self:Get() then 0 else SlideDistance
		return if atTop then UDim2.new(0.5, 0, 0, edge - away) else UDim2.new(0.5, 0, 1, -edge + away)
	end)
	local fade = fadeTarget:Apply(q.Animate(Tokens.Motion.options("Short4", "Linear")))
	local position = yTarget:Apply(q.Animate(Tokens.Motion.options("Medium1", "EmphasizedDecelerate")))

	local message = D.TextLabel {
		Name = "Message",
		bodyStyle,
		Size = UDim2.fromScale(0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = o.Text,
		TextColor3 = theme.Color.InverseOnSurface,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		LayoutOrder = 1,
		D.UIPadding {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 14),
			PaddingBottom = UDim.new(0, 14),
		},
		D.UIFlexItem { FlexMode = Enum.UIFlexMode.Fill },
	}

	local act = o.Action
	return D.CanvasGroup {
		Name = "Snackbar",
		AnchorPoint = Vector2.new(0.5, if atTop then 0 else 1),
		Position = position,
		Size = UDim2.fromOffset(o.Width or 344, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Color.InverseSurface,
		BorderSizePixel = 0,
		Active = true,
		GroupTransparency = fade,
		UICorner = Tokens.Shape.corner("ExtraSmall"),
		Util.preHook(function(inst: GuiObject)
			inst.MouseEnter:Connect(function()
				o.OnHover(true)
			end)
			inst.MouseLeave:Connect(function()
				o.OnHover(false)
			end)
			inst.Destroying:Connect(o.OnDestroyed)
		end),
		Util.postHook(function()
			entered:Set(true)
		end),
		D.UIListLayout {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 0),
		},
		D.UIPadding { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) },
		message,
		if act ~= nil then actionButton(o, act) else q.None,
		if o.Close == true then closeButton(o) else q.None,
	} :: GuiObject
end

return { build = build }
