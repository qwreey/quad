--!strict
--[[
	M3 plain tooltip: a small inverseSurface label that appears after hovering an element for a moment.

	    local tip = Tooltip.hook({ Text = "Add to favorites" })               -- optional: Delay, Overlay, Theme, Gap, Disabled
	    q.Elem "TextButton" { tip.Hook, Text = "Save" }                              -- the hook goes in the target array part
	    Button({ Label = "Save", Hooks = { tip.Hook } })                      -- every kit component takes `Hooks` for this
	    tip.IsOpen                                                            -- State<boolean>: is the tooltip up
	    tip.Close()                                                           -- hide right now (also cancels a pending show)

	Tooltip.Plain({ Text = "...", Closing = state?, MaxWidth = 200, Theme, Modifier }) is the bare visual (a TextLabel) for
	use without the hook (e.g. in your own overlay): inverseSurface, BodySmall (12/16), inverseOnSurface, corner 4,
	padding 8 x 4 (min height 24), wraps at MaxWidth (default 200). Text may be a State. `Hooks` (array-part values) as every kit
	component.

	hook options (all `read`):
	  Text      string | State<string>     the label (an open tooltip follows a State)
	  Delay     number?                    seconds of hovering before it shows, default 0.5
	  Gap       number?                    px between the target and the tooltip, default 4
	  Disabled  boolean | State<boolean>?  read when it would show
	  Overlay   Overlay?                   default `Overlay.default()`;  Theme  Theme?
	The returned Hook is ONE-SHOT and belongs to ONE element (create one `Tooltip.hook` per target). It connects only to
	events of that element (MouseEnter / MouseLeave / InputBegan / SelectionGained / SelectionLost / Destroying), so the
	connections die with it; nothing global is opened. Behavior: hover starts a task.delay (cancelled on leave); leaving,
	pressing (mouse/touch/gamepad A) or destroying the target closes it; gamepad / keyboard selection shows it too (same
	delay) and losing selection hides it. Placement: below the target, centered; flips above near the bottom edge and
	aligns to the target edge near the left/right edges (clamping uses the overlay layer AbsoluteSize; with a zero size —
	no layout yet — it stays centered below). Position is computed when it shows and does not follow a moving target.
	Enter: mounted snapped transparent and faded in from a PostRef hook (150 ms); exit: 100 ms fade through the Overlay
	closing phase. The tooltip does not take input (it is a plain label, not Active) and has no scrim.
	Instances: Tooltip.Plain = TextLabel + UICorner + UIPadding + UISizeConstraint (4). Not here: the M3 rich tooltip
	(subhead / actions) and touch long-press (no hover on touch devices — the press-hide rule keeps taps clean).
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Text = require("./Text")
local Overlay = require("./Overlay")
local TextLabel = q.Elem "TextLabel"
local UIPadding = q.Elem "UIPadding"
local UISizeConstraint = q.Elem "UISizeConstraint"
local TextLabelModifier = q.Modifier "TextLabel"
local tooltipName = TextLabelModifier():Name("Tooltip")

local _hookProto = Util.preHook(function() end)
export type Hook = typeof(_hookProto)

export type PlainProps = {
	read Text: string | q.State<string>,
	read Closing: q.State<boolean>?,
	read MaxWidth: number?,
	read Theme: Theme.Theme?,
	read Modifier: q.ModifierInto<TextLabel>?,
	read Hooks: Util.Hooks?,
}

export type Options = {
	read Text: string | q.State<string>,
	read Delay: number?,
	read Gap: number?,
	read Disabled: (boolean | q.State<boolean>)?,
	read Overlay: Overlay.Overlay?,
	read Theme: Theme.Theme?,
}

-- the kit-wide handle shape (closures without self): `Close()` hides it right now, `IsOpen` is whether it is up
export type Handle = {
	read Hook: Hook,
	read IsOpen: q.State<boolean>,
	Close: (result: unknown?) -> (),
}

local labelStyle = Text.Label("BodySmall")
local baseModifier = TextLabelModifier():AutomaticSize(Enum.AutomaticSize.XY):BorderSizePixel(0):TextWrapped(true)

local function Plain(props: PlainProps): TextLabel
	local theme = Theme.resolve(props.Theme)
	local closing = props.Closing or q.Source(false)
	local entered = q.Source(false)
	local shown: q.State<boolean> = entered:Compute(function(self, _prev, c)
		return self:Get() and not c:Get()
	end, closing)
	local transparency: q.State<number> = shown:Compute(function(self)
		return if self:Get() then 0 else 1
	end)
	local fade = transparency:Apply(q.Animate(Tokens.Motion.options("Short3", "Linear")))
	return TextLabel {
		tooltipName,
		baseModifier,
		labelStyle,
		props.Modifier or q.None,
		Size = UDim2.fromOffset(0, 24),
		Text = props.Text,
		BackgroundColor3 = theme.Color.InverseSurface,
		BackgroundTransparency = fade,
		TextColor3 = theme.Color.InverseOnSurface,
		TextTransparency = fade,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		UICorner = Tokens.Shape.corner("ExtraSmall"),
		UIPadding {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
		},
		UISizeConstraint { MaxSize = Vector2.new(props.MaxWidth or 200, math.huge) },
		Util.postHook(function()
			entered:Set(true)
		end),
		table.unpack(Util.hooks(props.Hooks)),
	}
end

local function isPress(input: InputObject): boolean
	local t = input.UserInputType
	return t == Enum.UserInputType.MouseButton1
		or t == Enum.UserInputType.Touch
		or (t == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonA)
end

local function hook(o: Options): Handle
	-- resolved at show time: a stale default overlay (its ScreenGui died) heals itself
	local function overlayNow(): Overlay.Overlay
		return o.Overlay or Overlay.default()
	end
	local delay = o.Delay or 0.5
	local gap = o.Gap or 4
	local visible = q.Source(false)
	local pending: thread? = nil
	local open: Overlay.Handle? = nil
	local target: GuiObject? = nil
	local hide: () -> ()
	local arm: () -> ()

	local function cancelPending()
		local t = pending
		if t ~= nil then
			pending = nil
			task.cancel(t)
		end
	end

	local function placement(): q.Modifier<TextLabel>
		local mod = TextLabelModifier()
		local host = target
		if host == nil then
			return mod
		end
		local layer = overlayNow().Layer
		local pos = host.AbsolutePosition - layer.AbsolutePosition
		local size = host.AbsoluteSize
		local bounds = layer.AbsoluteSize
		local cx = pos.X + size.X / 2
		local ax, x = 0.5, cx
		local ay, y = 0, pos.Y + size.Y + gap
		if bounds.X > 0 then
			if cx > bounds.X - 100 then
				ax, x = 1, pos.X + size.X
			elseif cx < 100 then
				ax, x = 0, pos.X
			end
		end
		if bounds.Y > 0 and y + 40 > bounds.Y then
			ay, y = 1, pos.Y - gap
		end
		return mod:AnchorPoint(Vector2.new(ax, ay)):Position(UDim2.fromOffset(x, y))
	end

	local function show()
		pending = nil
		if open ~= nil or target == nil or Util.peekBool(o.Disabled) then
			return
		end
		local modifier = placement()
		local h = overlayNow():Open({
			Content = function(oh: Overlay.Handle): Instance
				return Plain({ Text = o.Text, Closing = oh.Closing, Theme = o.Theme, Modifier = modifier })
			end,
			ExitTime = Tokens.Motion.Duration.Short2,
			OnClose = function()
				visible:Set(false)
				open = nil -- also when the layer died under it: the next hover may open a fresh one
			end,
		})
		open = h
		visible:Set(true)
	end

	hide = function()
		cancelPending()
		local h = open
		if h ~= nil then
			open = nil
			h.Close()
		end
	end

	arm = function()
		if open == nil and pending == nil then
			pending = task.delay(delay, show)
		end
	end

	local theHook = Util.preHook(function(inst: GuiObject)
		target = inst
		inst.MouseEnter:Connect(function()
			arm()
		end)
		inst.MouseLeave:Connect(function()
			hide()
		end)
		inst.SelectionGained:Connect(function()
			arm()
		end)
		inst.SelectionLost:Connect(function()
			hide()
		end)
		inst.InputBegan:Connect(function(input: InputObject)
			if isPress(input) then
				hide()
			end
		end)
		inst.Destroying:Connect(function()
			hide()
			target = nil
		end)
	end)

	return {
		Hook = theHook,
		IsOpen = visible,
		Close = function(_result: unknown?)
			hide()
		end,
	}
end

return {
	Plain = Plain,
	hook = hook,
}
