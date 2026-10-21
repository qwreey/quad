--!strict
--[[
	Tooltip — a hover hint (Iris: Tooltip). A HOOK FACTORY: it is not an element, it is attached to the element it hints.

		local tip = Devui.Tooltip({                           -- (Devui.Tooltip is this module's `hook` function)
			Text = "Saves the file" | State<string>,          -- or
			Content = function() return Devui.Text({ ... }) end,   -- a factory: a fresh element per show (Overlay owns it)
			Delay = 0.5,                                      -- seconds of hovering before it shows (default 0.5)
			Offset = Vector2.new(12, 16),                     -- from the mouse (default 12, 16)
			MaxWidth = 300,                                   -- wrap width for Text (default 300)
			Enabled = true | State<boolean>,                     -- false: no tooltip shows (default true)
			Overlay = ..., Style = ...,
		})
		Devui.Button({ Text = "Save", Hooks = { tip.Hook } })   -- leaf widgets take `Hooks`; on a raw element put `tip.Hook`
		q.Elem "Frame" ({ tip.Hook, ... })                            --   in its ARRAY PART
		tip.Visible                                           -- State<boolean>: is the tooltip showing

	One handle per target element (it owns the pending timer / popup). The hook connects the target's MouseEnter /
	MouseLeave / Destroying. On enter a `task.delay` is scheduled; on leave or destroy it is cancelled and an open
	tooltip is closed — nothing is left behind. When the timer fires the target must still be shown (its own and its
	ancestors' `Visible`, the ScreenGui's `Enabled`): hiding an ancestor — closing the window the target is in — sends
	no MouseLeave, so without that check a hint would appear for a closed window. `Enabled` [2026-10-21 user decision] is
	read on enter and again when the timer fires (a hint for a window title that is cut off only — the window kit's tab
	and title bar); turning it false while the tooltip shows does not close it — the next MouseLeave does. It must also be ON TOP under the
	pointer (the internal Pointer rule — the engine sends MouseEnter to covered elements too): no hint for a row under
	another window or under an open popup. A tooltip already showing when its
	window closes goes on the next mouse move (the engine re-evaluates hover and sends MouseLeave — Studio-confirmed). The tooltip appears at the mouse position read when it SHOWS
	(`UserInputService:GetMouseLocation()`) and does not follow the mouse. It has no click-outside catcher and takes no
	input: a press through it reaches the UI underneath, and a window behind it comes to the front. Text may be a State: the open tooltip follows it.

	PLACEMENT [unverified on a device]: `UserInputService:GetMouseLocation()` does NOT account for the GUI inset (it is
	measured from the very top-left of the screen), while a GuiObject's `AbsolutePosition` is in inset-adjusted GUI space.
	So the tooltip asks the Overlay for `GetMouseLocation() - GuiService:GetGuiInset() + Offset` (AbsolutePosition space);
	`Overlay:Open` then subtracts `Layer.AbsolutePosition`, which makes the hint land under the cursor for a layer under a
	ScreenGui with or without `IgnoreGuiInset`. If a device shows a vertical offset, this reading is wrong and the fix
	belongs here.
	The overlay is resolved when the tooltip SHOWS (`props.Overlay or Overlay.getDefault()`); showing on a destroyed
	overlay does nothing (no error from the delayed thread).
]]

local Pointer = require("./Pointer")
local Quad = require("./Quad")
local q = Quad
local TextLabel = q.Elem "TextLabel"
local UIPadding = q.Elem "UIPadding"
local UISizeConstraint = q.Elem "UISizeConstraint"
local Overlay = require("./Overlay")
local PopupParts = require("./PopupParts")
local Style = require("./Style")
local Types = require("./Types")
local Util = require("./Util")
local Visibility = require("./Visibility")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

export type TooltipProps = {
	read Text: (string | State<string>)?,
	read Content: (() -> Instance)?,
	read Delay: number?,
	read Enabled: (boolean | State<boolean>)?,
	read Offset: Vector2?,
	read MaxWidth: number?,
	read Overlay: Overlay.Overlay?,
	read Style: Style?,
}

export type TooltipHandle = {
	Hook: Types.GuiHook,
	Visible: State<boolean>,
}

local Tooltip = {}

function Tooltip.hook(props: TooltipProps): TooltipHandle
	local style = props.Style or Style.default
	local delay = props.Delay or 0.5
	local offset = props.Offset or Vector2.new(12, 16)
	local maxWidth = props.MaxWidth or 300
	local makeContent = props.Content
	local text = props.Text
	if makeContent == nil and text == nil then
		Util.fail("Tooltip.hook", "give Text or Content")
	end
	local enabledProp = props.Enabled
	local function enabled(): boolean
		if enabledProp == nil then
			return true
		elseif type(enabledProp) == "boolean" then
			return enabledProp
		end
		return (enabledProp :: State<boolean>):Get()
	end

	local visible: Source<boolean> = q.Source(false)
	-- the element the hook was placed on
	local target: GuiObject? = nil
	local pending: thread? = nil
	local popup: Overlay.Popup? = nil

	local function build(): Instance
		if makeContent then
			return makeContent()
		end
		local pad: State<UDim> = Util.pxX(style.Metrics.WindowPadding)
		local padY: State<UDim> = Util.pxY(style.Metrics.WindowPadding)
		return TextLabel({
			Name = "Tooltip",
			Text = text :: string | State<string>,
			FontFace = style.Metrics.TextFont,
			TextSize = style.Metrics.TextSize,
			TextColor3 = style.Color.Text,
			TextTransparency = style.Transparency.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			BackgroundColor3 = style.Color.PopupBg,
			BackgroundTransparency = style.Transparency.PopupBg,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromOffset(0, 0),
			UICorner = style.Metrics.PopupRounding,
			PopupParts.stroke(style),
			UISizeConstraint({ MaxSize = Vector2.new(maxWidth, math.huge) }),
			UIPadding({ PaddingLeft = pad, PaddingRight = pad, PaddingTop = padY, PaddingBottom = padY }),
		})
	end

	local function hide()
		local th = pending
		if th then
			pending = nil
			task.cancel(th)
		end
		local p = popup
		if p then
			p:Close()
		end
	end

	local function show()
		pending = nil
		if popup then
			return
		end
		-- the target (or its window) was hidden while the timer ran: hiding an ancestor sends no MouseLeave, so the
		-- timer was not cancelled — do not show a hint for something that is no longer on screen
		local t = target
		if t == nil or not Visibility.isShown(t) or not enabled() then
			return
		end
		-- GetMouseLocation ignores the GUI inset; AbsolutePosition space includes it (see the header)
		local mouse = Pointer.mouse()
		-- covered (another window, an open popup's catcher, a button of another ScreenGui): no hint for what the
		-- pointer is not really on — the engine sent MouseEnter anyway
		if Pointer.isTop(t, mouse.X, mouse.Y) == false then
			return
		end
		local overlay = props.Overlay or Overlay.getDefault()
		if not overlay.Alive:Get() then
			return
		end
		popup = overlay:Open({
			Content = build(),
			Position = mouse + offset,
			CloseOnClickOutside = false,
			OnClose = function()
				popup = nil
				visible:Set(false)
			end,
		})
		visible:Set(true)
	end

	local hook: Types.GuiHook = q.PostRef(nil :: GuiObject?)
	hook:Callback(function(inst)
		if inst == nil then
			return
		end
		target = inst
		inst.MouseEnter:Connect(function()
			if pending == nil and popup == nil and enabled() then
				pending = task.delay(delay, show)
			end
		end)
		inst.MouseLeave:Connect(hide)
		-- a press means the user is acting on the target: the hint is no longer wanted
		inst.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				hide()
			end
		end)
		inst.Destroying:Connect(hide)
	end)

	return { Hook = hook, Visible = visible }
end

Tooltip.Tooltip = Tooltip.hook

return Tooltip
