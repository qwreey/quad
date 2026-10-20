--!strict
--[[
	App bar actions: the icon buttons of app bars and toolbars, built from data — the kit's form of Compose's `AppBarRow` /
	`AppBarColumn` item DSL (androidx/androidx@40ff481 compose/material3/material3/src/commonMain/kotlin/androidx/compose/
	material3/AppBarRow.kt 40-104, AppBarColumn.kt, AppBarDsl.kt 47-228 / 434-466).

	    Actions = {
	        { Icon = "rbxassetid://…", Label = "Search", OnClick = search },                       -- clickableItem
	        { Icon = "rbxassetid://…", Label = "Favorite", Checked = fav, OnCheckedChange = setFav }, -- toggleableItem
	        someInstance,                                                                           -- a custom item
	    }

	Action (`read`): Icon (icon prop — an `Icons` name or an image URL; a name with no image draws nothing), Label (string —
	the tooltip and the overflow menu text, Compose's `label`), OnClick (() -> ())?, Checked ((boolean | State<boolean>)?
	— makes it a toggle: Compose IconToggleButton, the icon turns primary when checked), OnCheckedChange ((checked) -> ())? —
	called with the NEW value (Compose onCheckedChange; nothing is written), Disabled (boolean | State<boolean>)?.
	An Instance entry is placed as given (Compose customItem's row content; its width is its `Size.X.Offset`, 48 when it has
	none) and has no menu form, so it never moves into the overflow menu.

	Every action is a kit IconButton with `TouchTarget = true` (48 x 48 around the 40 x 40 button — Compose's IconButton
	measures 48 with the minimum interactive size), in the bar's icon color (`ContentColor`), with a plain tooltip of its
	Label (Compose wraps each item in a TooltipBox; the kit's tooltip opens below the button, flipping above near the bottom
	edge — Compose anchors it Above).
	OVERFLOW (AppBarRow `maxItemCount`): with more entries than MaxItemCount, the first MaxItemCount - 1 stay in the row and
	the rest go to a Menu opened by the overflow button (Icons "moreVert", tooltip "More options" — AppBarOverflowIndicator;
	a click toggles the menu). A menu entry clicks / toggles its action and closes (ClickableAppBarItem / ToggleableAppBarItem
	MenuContent). Compose also overflows by measured width; the kit counts only (it does not measure the bar).
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Util = require("../Util")
local Icons = require("../Icons")
local IconButton = require("../Button/IconButton")
local Tooltip = require("../Tooltip")
local Menu = require("../Menu")
local Overlay = require("../Overlay")
local TextButtonModifier = q.Modifier "TextButton"

export type Action = {
	read Icon: string,
	read Label: string,
	read OnClick: (() -> ())?,
	read Checked: (boolean | q.State<boolean>)?,
	read OnCheckedChange: ((checked: boolean) -> ())?,
	read Disabled: (boolean | q.State<boolean>)?,
}

export type Entry = Action | Instance

export type Options = {
	Theme: Theme.Theme,
	Color: q.State<Color3>,
	Overlay: Overlay.Overlay?,
	MaxItemCount: number?,
}

local SIZE = 48
local MORE_OPTIONS = "More options" -- Strings.FloatingToolbarMoreOptions (AppBarOverflowIndicator's description)

local function sizeOf(inst: Instance, axis: "X" | "Y"): number
	local ok, size = pcall(function(): UDim2
		return (inst :: any).Size
	end)
	if ok and typeof(size) == "UDim2" then
		local v = if axis == "X" then size.X.Offset else size.Y.Offset
		if v > 0 then
			return v
		end
	end
	return SIZE
end

local function isInstance(e: Entry): boolean
	return typeof(e) == "Instance"
end

local function activate(a: Action)
	if a.Checked ~= nil then
		if a.OnCheckedChange then
			a.OnCheckedChange(not Util.peekBool(a.Checked))
		end
	elseif a.OnClick then
		a.OnClick()
	end
end

-- one action as an icon button
local function button(a: Action, o: Options, order: number): Instance
	local tip = Tooltip.hook({ Text = a.Label, Overlay = o.Overlay, Theme = o.Theme })
	return IconButton({
		Icon = Icons.imageOf(a.Icon),
		TouchTarget = true,
		ContentColor = o.Color,
		Selected = a.Checked,
		Disabled = a.Disabled,
		Theme = o.Theme,
		OnClick = function()
			activate(a)
		end,
		Modifier = TextButtonModifier():LayoutOrder(order),
		Hooks = { tip.Hook },
	})
end

-- the entries as instances in order (each with its LayoutOrder) and the main-axis length they take
local function build(entries: { Entry }, o: Options, axis: ("X" | "Y")?): ({ Instance }, number)
	local ax: "X" | "Y" = axis or "X"
	local count = #entries
	local max = o.MaxItemCount
	local cut = if max ~= nil and count > max then math.max(max - 1, 0) else count
	local out: { Instance } = {}
	local length = 0
	local overflow: { Action } = {}
	for i, e in entries do
		if isInstance(e) then
			local inst = e :: Instance
			length += sizeOf(inst, ax)
			table.insert(out, inst)
		elseif i <= cut then
			table.insert(out, button(e :: Action, o, i))
			length += SIZE
		else
			table.insert(overflow, e :: Action)
		end
	end
	if #overflow > 0 then
		local handle: any = nil
		local anchor = q.Ref(nil :: GuiObject?)
		local tip = Tooltip.hook({ Text = MORE_OPTIONS, Overlay = o.Overlay, Theme = o.Theme })
		table.insert(
			out,
			IconButton({
				Icon = Icons.imageOf("moreVert"),
				TouchTarget = true,
				ContentColor = o.Color,
				Theme = o.Theme,
				Modifier = TextButtonModifier():LayoutOrder(count + 1),
				Hooks = { tip.Hook, anchor },
				OnClick = function()
					if handle ~= nil and handle.IsOpen:Get() then
						handle.Close()
						return
					end
					local target = anchor.Value
					if target == nil then
						return
					end
					local items: { Menu.Entry } = {}
					for _, a in overflow do
						table.insert(items, {
							Label = a.Label,
							Disabled = a.Disabled,
							Selected = if a.Checked ~= nil then Util.peekBool(a.Checked) else nil,
							OnClick = function()
								activate(a)
							end,
						})
					end
					handle = Menu.open({ Anchor = target, Items = items, Overlay = o.Overlay, Theme = o.Theme })
				end,
			})
		)
		length += SIZE
	end
	return out, length
end

return {
	build = build,
	sizeOf = sizeOf,
	isInstance = isInstance,
	SIZE = SIZE,
}
