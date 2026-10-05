--!strict
--[[
	Tooltip — a hover hint (Iris: Tooltip). A HOOK FACTORY: it is not an element, it is attached to the element it hints.

		local tip = Devui.Tooltip({                           -- (Devui.Tooltip is this module's `hook` function)
			Text = "Saves the file" | State<string>,          -- or
			Content = function() return Devui.Text({ ... }) end,   -- a factory: a fresh element per show (Overlay owns it)
			Delay = 0.5,                                      -- seconds of hovering before it shows (default 0.5)
			Offset = Vector2.new(12, 16),                     -- from the mouse (default 12, 16)
			MaxWidth = 300,                                   -- wrap width for Text (default 300)
			Overlay = ..., Style = ...,
		})
		Devui.Button({ Text = "Save", Hooks = { tip.Hook } })   -- leaf widgets take `Hooks`; on a raw element put `tip.Hook`
		D.Frame({ tip.Hook, ... })                            --   in its ARRAY PART
		tip.Visible                                           -- State<boolean>: is the tooltip showing

	One handle per target element (it owns the pending timer / popup). The hook connects the target's MouseEnter /
	MouseLeave / Destroying. On enter a `task.delay` is scheduled; on leave or destroy it is cancelled and an open
	tooltip is closed — nothing is left behind. The tooltip appears at the mouse position read when it SHOWS
	(`UserInputService:GetMouseLocation()`) and does not follow the mouse. It has no click-outside catcher (input falls
	through to the UI underneath). Text may be a State: the open tooltip follows it.

	PLACEMENT [unverified on a device]: `UserInputService:GetMouseLocation()` does NOT account for the GUI inset (it is
	measured from the very top-left of the screen), while a GuiObject's `AbsolutePosition` is in inset-adjusted GUI space.
	So the tooltip asks the Overlay for `GetMouseLocation() - GuiService:GetGuiInset() + Offset` (AbsolutePosition space);
	`Overlay:Open` then subtracts `Layer.AbsolutePosition`, which makes the hint land under the cursor for a layer under a
	ScreenGui with or without `IgnoreGuiInset`. If a device shows a vertical offset, this reading is wrong and the fix
	belongs here.
	The overlay is resolved when the tooltip SHOWS (`props.Overlay or Overlay.getDefault()`); showing on a destroyed
	overlay does nothing (no error from the delayed thread).
]]

local Input = require("./Input")
local Quad = require("./Quad")
local q = Quad
local D = q.Declaration
local Overlay = require("./Overlay")
local PopupParts = require("./PopupParts")
local Style = require("./Style")
local Types = require("./Types")
local Util = require("./Util")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

export type TooltipProps = {
	read Text: (string | State<string>)?,
	read Content: (() -> Instance)?,
	read Delay: number?,
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
		error("Tooltip.hook: give Text or Content", 2)
	end

	local visible: Source<boolean> = q.Source(false)
	local pending: thread? = nil
	local popup: Overlay.Popup? = nil

	local function build(): Instance
		if makeContent then
			return makeContent()
		end
		local pad: State<UDim> = Util.pxX(style.Metrics.WindowPadding)
		local padY: State<UDim> = Util.pxY(style.Metrics.WindowPadding)
		return D.TextLabel({
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
			D.UISizeConstraint({ MaxSize = Vector2.new(maxWidth, math.huge) }),
			D.UIPadding({ PaddingLeft = pad, PaddingRight = pad, PaddingTop = padY, PaddingBottom = padY }),
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
		local overlay = props.Overlay or Overlay.getDefault()
		if not overlay.Alive:Get() then
			return
		end
		local mouse = Input.service():GetMouseLocation()
		-- GetMouseLocation ignores the GUI inset; AbsolutePosition space includes it (see the header)
		mouse -= Input.guiInset()
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
		inst.MouseEnter:Connect(function()
			if pending == nil and popup == nil then
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
