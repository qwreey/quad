--!strict
--[[
	Dialogs [2026-10-21 user decisions — research/devui-popup-model-plan.md 3.2 / 3.3; names by a three-model review,
	audit/naming-devui-2026-10-21c/].

		OpenDialog  { Title: string | State<string>, Children: Slot<Instance>?, Window: Instance?,
		              Modal: ("None" | "Window" | "Global")?, OnClose: (() -> ())?, Overlay?, Style? } -> DialogHandle
		            opens NOW, centred on `Window` (the window's root — it follows the window as it moves) or on the
		            screen; DialogHandle = { IsOpen: State<boolean>, Close: (self) -> () }
		OpenConfirm { Title, Text: string | State<string>, ConfirmLabel: string?, CancelLabel: string?, Window?, Modal?,
		              OnResult: (ok: boolean) -> (), Overlay?, Style? } -> DialogHandle
		            "Delete this? [Delete] [Cancel]" in one call: `OnResult(true)` from the confirm button, `false` from
		            the cancel button, Escape, `:Close()` or the window closing — exactly once

	A dialog does not close on an outside click (it waits for an answer). What it blocks while open is `Modal` — the
	user's model, "a popup and a top-level dialog differ by how far the background is dimmed":
	  "Window" (default)  the window it was opened from is veiled (`DialogVeil`, inside the window's root like the split
	                      kit's small-side veil, so it follows a moved / docked / tabbed window) and takes no input; other
	                      windows still work. Needs `Window` (an error without it — what to block would be unclear)
	  "Global"            a veil over the whole overlay layer (`DialogScrim`) takes every press
	  "None"              nothing is blocked (a find box left open while working)
	Escape closes the dialog (the confirm helper: cancel). Hiding the window it was opened from (closing it) closes the
	dialog too. `Window` is the root `Devui.Window` returns (its content surface): the veil covers that, and the title bar
	stays live — the window can still be moved (the dialog follows) or closed (the dialog closes), as a macOS sheet. The veils use the NavWindowingDimBg tokens (Dear ImGui's dim colour), as the small-side veil does.
]]

local Menu = require("./Menu")
local Overlay = require("./Overlay")
local PopupParts = require("./PopupParts")
local Quad = require("./Quad")
local q = Quad
local Frame = q.Elem "Frame"
local TextButton = q.Elem "TextButton"
local TextLabel = q.Elem "TextLabel"
local UIListLayout = q.Elem "UIListLayout"
local UIPadding = q.Elem "UIPadding"
local Button = require("./Button")
local Style = require("./Style")
local Util = require("./Util")
local Visibility = require("./Visibility")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Slot<T> = Quad.Slot<T>
type Style = Style.Style

export type DialogModal = "None" | "Window" | "Global"

export type DialogHandle = {
	IsOpen: State<boolean>,
	Close: (self: DialogHandle) -> (),
}

export type OpenDialogProps = {
	read Title: string | State<string>,
	read Children: Slot<Instance>?,
	read Window: Instance?,
	read Modal: DialogModal?,
	read OnClose: (() -> ())?,
	read Overlay: Overlay.Overlay?,
	read Style: Style?,
}

export type OpenConfirmProps = {
	read Title: string | State<string>,
	read Text: string | State<string>,
	read ConfirmLabel: string?,
	read CancelLabel: string?,
	read Window: Instance?,
	read Modal: DialogModal?,
	read OnResult: (ok: boolean) -> (),
	read Overlay: Overlay.Overlay?,
	read Style: Style?,
}

local Dialog = {}

-- a veil that takes every press under it; `size` follows what it covers
local function veil(style: Style, name: string, size: State<UDim2> | UDim2, z: number): TextButton
	return TextButton({
		Name = name,
		Size = size,
		ZIndex = z,
		Active = true,
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = style.Color.NavWindowingDimBg,
		BackgroundTransparency = style.Transparency.NavWindowingDimBg,
		BorderSizePixel = 0,
	})
end

local function centreOf(target: Instance?, layer: GuiObject): Vector2
	if target ~= nil and Visibility.isGuiObject(target) then
		local g = target :: GuiObject
		return g.AbsolutePosition + g.AbsoluteSize / 2
	end
	return layer.AbsolutePosition + layer.AbsoluteSize / 2
end

function Dialog.OpenDialog(props: OpenDialogProps): DialogHandle
	local style = props.Style or Style.default
	local overlay = props.Overlay or Overlay.getDefault()
	local modal: DialogModal = props.Modal or "Window"
	local window = props.Window
	if modal ~= "None" and modal ~= "Window" and modal ~= "Global" then
		Util.fail("OpenDialog", `Modal must be "None", "Window" or "Global", got {tostring(modal)}`)
	end
	if modal == "Window" and window == nil then
		Util.fail("OpenDialog", `Modal = "Window" blocks the window the dialog was opened from: give Window (that window's root), or Modal = "Global" / "None"`)
	end
	local isOpen: Source<boolean> = q.Source(false)
	local cleanups: { () -> () } = {}
	local popup: Overlay.Popup? = nil
	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		for i = #cleanups, 1, -1 do
			cleanups[i]()
		end
		table.clear(cleanups)
		isOpen:Set(false)
		local onClose = props.OnClose
		if onClose then
			onClose()
		end
	end
	local handle: DialogHandle = {
		IsOpen = isOpen,
		Close = function(_self: DialogHandle)
			close()
		end,
	}
	if not overlay.Alive:Get() then
		closed = true
		return handle
	end
	local layer = overlay.Layer

	-- what it blocks
	if modal == "Global" then
		local layerSize: Source<UDim2> = q.Source(UDim2.fromOffset(layer.AbsoluteSize.X, layer.AbsoluteSize.Y))
		local conn = layer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			layerSize:SetIfChanged(UDim2.fromOffset(layer.AbsoluteSize.X, layer.AbsoluteSize.Y))
		end)
		local scrim = overlay:Open({
			Content = veil(style, "DialogScrim", layerSize, 1),
			Position = layer.AbsolutePosition,
			CloseOnClickOutside = false,
		})
		table.insert(cleanups, function()
			conn:Disconnect()
			scrim:Close()
		end)
	elseif modal == "Window" then
		local cover = veil(style, "DialogVeil", UDim2.fromScale(1, 1), 3)
		cover.Parent = window
		table.insert(cleanups, function()
			q.dispose(cover)
		end)
	end

	-- the body: the popup panel with a title and the content (window padding)
	local pad: State<UDim> = Util.pxX(style.Metrics.WindowPadding)
	local padY: State<UDim> = Util.pxY(style.Metrics.WindowPadding)
	local body = Menu.PopupPanel({
		Style = style,
		Children = q.Slot<<Instance>>({
			TextLabel({
				Name = "DialogTitle",
				LayoutOrder = 1,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = UDim2.fromOffset(0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = props.Title,
				FontFace = style.Metrics.TextFont,
				TextSize = style.Metrics.TextSize,
				TextColor3 = style.Color.Text,
				TextTransparency = style.Transparency.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				UIPadding({ PaddingLeft = pad, PaddingRight = pad, PaddingTop = padY }),
			}),
			Frame({
				Name = "DialogContent",
				LayoutOrder = 2,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = UDim2.fromOffset(0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				UIPadding({ PaddingLeft = pad, PaddingRight = pad, PaddingTop = padY, PaddingBottom = padY }),
				UIListLayout({
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = Util.pxY(style.Metrics.ItemSpacing),
				}),
				props.Children or q.None,
			}),
		}),
	})
	local opened = overlay:Open({
		Content = body,
		Position = centreOf(window, layer),
		Anchor = Vector2.new(0.5, 0.5),
		CloseOnClickOutside = false,
		OnClose = close,
	})
	popup = opened
	table.insert(cleanups, function()
		opened:Close()
	end)
	isOpen:Set(true)

	-- centred on its window while that window moves or resizes
	if window ~= nil and Visibility.isGuiObject(window) then
		local g = window :: GuiObject
		local function follow()
			local holder = opened.Holder
			local size = holder.AbsoluteSize
			local at = centreOf(g, layer) - layer.AbsolutePosition - size / 2
			holder.AnchorPoint = Vector2.zero
			holder.Position = UDim2.fromOffset(math.round(at.X), math.round(at.Y))
		end
		local a = g:GetPropertyChangedSignal("AbsolutePosition"):Connect(follow)
		local b = g:GetPropertyChangedSignal("AbsoluteSize"):Connect(follow)
		table.insert(cleanups, function()
			a:Disconnect()
			b:Disconnect()
		end)
	end
	-- Escape closes it; so does hiding the window it was opened from
	table.insert(cleanups, if window ~= nil then PopupParts.whileOpen(window, close) else PopupParts.onEscape(close))
	return handle
end

function Dialog.OpenConfirm(props: OpenConfirmProps): DialogHandle
	local style = props.Style or Style.default
	local answered = false
	local handle: DialogHandle
	local function answer(ok: boolean)
		if answered then
			return
		end
		answered = true
		props.OnResult(ok)
		handle:Close()
	end
	handle = Dialog.OpenDialog({
		Title = props.Title,
		Window = props.Window,
		Modal = props.Modal,
		Overlay = props.Overlay,
		Style = style,
		-- Escape, :Close() and the window closing: a cancel
		OnClose = function()
			answer(false)
		end,
		Children = q.Slot<<Instance>>({
			TextLabel({
				Name = "ConfirmText",
				LayoutOrder = 1,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = UDim2.fromOffset(0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = props.Text,
				FontFace = style.Metrics.TextFont,
				TextSize = style.Metrics.TextSize,
				TextColor3 = style.Color.Text,
				TextTransparency = style.Transparency.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
			}),
			Frame({
				Name = "ConfirmButtons",
				LayoutOrder = 2,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = UDim2.fromOffset(0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				UIListLayout({
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = Util.pxX(style.Metrics.ItemSpacing),
				}),
				Button.Button({
					Text = props.ConfirmLabel or "OK",
					Style = style,
					Modifier = q.Modifier "TextButton"():Name("ConfirmButton"):LayoutOrder(1),
					OnClick = function()
						answer(true)
					end,
				}),
				Button.Button({
					Text = props.CancelLabel or "Cancel",
					Style = style,
					Modifier = q.Modifier "TextButton"():Name("CancelButton"):LayoutOrder(2),
					OnClick = function()
						answer(false)
					end,
				}),
			}),
		}),
	})
	return handle
end

return Dialog
