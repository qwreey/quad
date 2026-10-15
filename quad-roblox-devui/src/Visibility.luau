--!strict
--[[
	Visibility — internal helpers for "is this element actually on screen" (not exported from init.luau).

		Visibility.isShown(inst)            false when inst or a GUI ancestor has Visible = false, or the LayerCollector
		                                    above it has Enabled = false; true otherwise (also when no LayerCollector
		                                    is found: an unmounted element is not judged here)
		Visibility.hasArea(inst)            inst is a GuiObject or a LayerCollector (it has AbsolutePosition / AbsoluteSize)
		Visibility.whenHidden(inst, fn)     calls `fn` when inst or a GUI ancestor turns Visible = false, or the
		                                    LayerCollector above it turns Enabled = false; returns the disconnect function

	Why: hiding an ANCESTOR fires nothing on the descendants (no MouseLeave, no Visible change on them) — Studio-confirmed.
	A popup opened from inside a window (Combo list, Menu) and a tooltip waiting on a timer would otherwise outlive a
	window that was closed (`Open = false` hides the window root). `whenHidden` is opened only while a popup is open, so
	it costs nothing at rest (one connection per ancestor while open).

	Classes are recognised by ClassName (the spec mock has no IsA hierarchy): reading `Visible` on a Folder or the
	PlayerGui would raise on the engine, so only the GuiObject classes below are read.
]]

local Visibility = {}

local GUI_OBJECT: { [string]: true } = {
	Frame = true,
	ScrollingFrame = true,
	CanvasGroup = true,
	TextButton = true,
	TextLabel = true,
	TextBox = true,
	ImageButton = true,
	ImageLabel = true,
	ViewportFrame = true,
	VideoFrame = true,
}

local LAYER_COLLECTOR: { [string]: true } = {
	ScreenGui = true,
	SurfaceGui = true,
	BillboardGui = true,
	DockWidgetPluginGui = true,
	QWidgetPluginGui = true,
}

function Visibility.hasArea(inst: Instance): boolean
	local class = inst.ClassName
	return GUI_OBJECT[class] == true or LAYER_COLLECTOR[class] == true
end

function Visibility.isShown(inst: Instance): boolean
	local cursor: any = inst
	while cursor ~= nil do
		local class = cursor.ClassName
		if LAYER_COLLECTOR[class] then
			return cursor.Enabled ~= false
		elseif GUI_OBJECT[class] and cursor.Visible == false then
			return false
		end
		cursor = cursor.Parent
	end
	return true
end

function Visibility.whenHidden(inst: Instance, fn: () -> ()): () -> ()
	local conns: { RBXScriptConnection } = {}
	local cursor: Instance? = inst
	while cursor ~= nil do
		local node: any = cursor
		local class = node.ClassName
		local property = if LAYER_COLLECTOR[class] then "Enabled" elseif GUI_OBJECT[class] then "Visible" else nil
		if property ~= nil then
			local conn: RBXScriptConnection = node:GetPropertyChangedSignal(property):Connect(function()
				if node[property] == false then
					fn()
				end
			end)
			table.insert(conns, conn)
		end
		if LAYER_COLLECTOR[class] then
			break
		end
		cursor = node.Parent
	end
	return function()
		for _, c in conns do
			c:Disconnect()
		end
		table.clear(conns)
	end
end

return Visibility
