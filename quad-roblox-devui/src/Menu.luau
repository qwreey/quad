--!strict
--[[
	Menus (Iris: MenuBar / Menu / MenuItem / MenuToggle).

		MenuBar    { Children: Slot<Instance>?, Style?, Modifier: FrameModifier? }       a horizontal bar (MenubarBg)
		Menu       { Text, Children: (scope: MenuScope) -> Slot<Instance>, Scope: MenuScope?, Disabled?, Overlay?, Style? }
		MenuItem   { Text, OnClick: () -> (), Shortcut: string?, Disabled?, Scope: MenuScope?, Style? }
		MenuToggle { Text, Value: Source<boolean>? | Checked: State<boolean>? + OnToggle?, Shortcut?, Disabled?, Scope?, Style? }
		           an item with a check mark. Two forms: `Value = source` (the item flips the Source, then calls OnToggle),
		           or CONTROLLED `Checked = state` + `OnToggle = function(new) ... end` (the item only reports; the caller
		           decides, e.g. maps it onto an enum Source). Neither given: an internal Source. Both given: an error.

	THE SCOPE (decision): a menu's items are built LAZILY — `Children` is a factory called every time the menu opens, and
	the Overlay owns (and destroys) what it returns when the menu closes. So a closed menu costs one bar item, and
	nothing stays alive in the popup layer. The factory receives a `MenuScope` — the explicit handle of the open chain
	(quad passes values explicitly, no hidden "current menu"): put it in the `Scope` prop of every MenuItem / MenuToggle /
	nested Menu you build inside, e.g.

		Devui.Menu({ Text = "File", Children = function(scope)
			return Kids(
				Devui.MenuItem({ Text = "Open", Shortcut = "Ctrl+O", Scope = scope, OnClick = openFile }),
				Devui.Menu({ Text = "Recent", Scope = scope, Children = function(sub)
					return Kids(Devui.MenuItem({ Text = "a.txt", Scope = sub, OnClick = openA }))
				end })
			)
		end })

	The Scope is what makes (1) clicking an item close the WHOLE chain (root popup and every submenu) before `OnClick`
	runs, (2) a nested Menu open to the right of its item (on hover or click) instead of below it, and (3) hovering a
	sibling item close an open submenu. Without a Scope an item just runs its callback (a standalone row).

	Open behaviour: a bar item opens its popup under itself on click (toggle). The root popup has the Overlay's
	click-outside catcher, so any click outside the chain closes it (the click does not reach the UI underneath);
	Escape closes the whole chain. NOT implemented: Dear ImGui's hover-to-switch between open top-level menus — the
	catcher covers the bar while a menu is open, so the bar items never see the hover (a second click on another
	title closes the open one, a third opens it).

	Escape is listened for only while a root menu is open (one UserInputService.InputBegan connection). The Overlay is
	resolved when a menu OPENS (`Scope.Overlay`, else `props.Overlay`, else `Overlay.getDefault()`), and the scope handed to
	`Children` is made fresh for every open. If the overlay layer dies while a menu is open, the Overlay closes the popup
	(`OnClose` runs, so the Escape listener is dropped).
]]

local Quad = require("./Quad")
local q = Quad
local D = q.Declaration
local Overlay = require("./Overlay")
local PopupParts = require("./PopupParts")
local Style = require("./Style")
local Util = require("./Util")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Slot<T> = Quad.Slot<T>
type Style = Style.Style

-- The handle of one open menu level (see the header). Read-only to callers: the level's open submenu popup is tracked
-- in the module-private `openChild` table below, not in a field a caller could overwrite.
export type MenuScope = {
	read Overlay: Overlay.Overlay,
	read Style: Style,
	read CloseAll: () -> (),
	read CloseSubmenu: (self: MenuScope) -> (),
}

export type MenuBarProps = {
	read Children: Slot<Instance>?,
	read Style: Style?,
	read Modifier: Quad.FrameModifier?,
}

export type MenuProps = {
	read Text: string | State<string>,
	read Children: (scope: MenuScope) -> Slot<Instance>,
	read Scope: MenuScope?,
	read Disabled: (boolean | State<boolean>)?,
	read Overlay: Overlay.Overlay?,
	read Style: Style?,
}

export type MenuItemProps = {
	read Text: string | State<string>,
	read OnClick: () -> (),
	read Shortcut: string?,
	read Disabled: (boolean | State<boolean>)?,
	read Scope: MenuScope?,
	read Style: Style?,
}

export type MenuToggleProps = {
	read Text: string | State<string>,
	read Value: Source<boolean>?,
	read Checked: State<boolean>?,
	read OnToggle: ((checked: boolean) -> ())?,
	read Shortcut: string?,
	read Disabled: (boolean | State<boolean>)?,
	read Scope: MenuScope?,
	read Style: Style?,
}

local Menu = {}

-- scope -> its open submenu popup (weak keys: a dropped scope takes its entry along)
local openChild: { [MenuScope]: Overlay.Popup? } = setmetatable({}, { __mode = "k" }) :: any

local function disabledState(d: (boolean | State<boolean>)?): State<boolean>?
	if d == nil then
		return nil
	elseif type(d) == "boolean" then
		return q.Source(d)
	end
	return d :: State<boolean>
end

function Menu.MenuBar(props: MenuBarProps): Frame
	local style = props.Style or Style.default
	return D.Frame({
		props.Modifier or q.None,
		Name = "MenuBar",
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = style.Color.MenubarBg,
		BackgroundTransparency = style.Transparency.MenubarBg,
		BorderSizePixel = 0,
		D.UIListLayout({
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		props.Children or q.None,
	})
end

-- the popup body: a vertical list that sizes to its widest row
local function panel(style: Style, children: Slot<Instance>): Frame
	local pad: State<UDim> = Util.pxY(style.Metrics.ItemInnerSpacing)
	return D.Frame({
		Name = "MenuPanel",
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = style.Color.PopupBg,
		BackgroundTransparency = style.Transparency.PopupBg,
		BorderSizePixel = 0,
		Active = true,
		UICorner = style.Metrics.PopupRounding,
		PopupParts.stroke(style),
		D.UIPadding({ PaddingTop = pad, PaddingBottom = pad }),
		D.UIListLayout({
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		children,
	})
end

function Menu.Menu(props: MenuProps): TextButton
	local parent = props.Scope
	local style = props.Style or (if parent then parent.Style else Style.default)
	local disabled = disabledState(props.Disabled)
	local factory = props.Children

	local isOpen: Source<boolean> = q.Source(false)
	-- the open popup of THIS menu (nil while closed)
	local popup: Overlay.Popup? = nil
	-- assigned right after the element is built; read only from event handlers
	local item: TextButton? = nil

	local function closeRoot()
		local p = popup
		if p then
			p:Close()
		end
	end

	local function open()
		local anchor = item
		if popup or anchor == nil then
			return
		end
		if disabled and disabled:Get() then
			return
		end
		-- resolved now, not at construction: a rebuilt default overlay is picked up
		local overlay = if parent then parent.Overlay else (props.Overlay or Overlay.getDefault())
		if not overlay.Alive:Get() then
			return
		end
		if parent then
			-- a sibling's submenu makes way
			parent:CloseSubmenu()
		end
		-- the scope handed to this menu's children (fresh per open)
		local scope: MenuScope = {
			Overlay = overlay,
			Style = style,
			CloseAll = if parent then parent.CloseAll else closeRoot,
			CloseSubmenu = function(self: MenuScope)
				local c = openChild[self]
				if c then
					c:Close()
				end
			end,
		}
		local pos, size = anchor.AbsolutePosition, anchor.AbsoluteSize
		local at = if parent then Vector2.new(pos.X + size.X, pos.Y) else Vector2.new(pos.X, pos.Y + size.Y)
		local disconnectEscape: (() -> ())? = nil
		local opened: Overlay.Popup? = nil
		local newPopup = overlay:Open({
			Content = panel(style, factory(scope)),
			Position = at,
			-- only the root has the catcher: submenus sit above it, so a click inside the chain never reaches it
			CloseOnClickOutside = parent == nil,
			OnClose = function()
				popup = nil
				isOpen:Set(false)
				local c = openChild[scope]
				openChild[scope] = nil
				if c then
					c:Close()
				end
				if parent and openChild[parent] == opened then
					openChild[parent] = nil
				end
				local off = disconnectEscape
				if off then
					disconnectEscape = nil
					off()
				end
			end,
		})
		opened = newPopup
		popup = newPopup
		isOpen:Set(true)
		if parent then
			openChild[parent] = newPopup
		else
			disconnectEscape = PopupParts.onEscape(scope.CloseAll)
		end
	end

	local function toggle()
		local p = popup
		if p then
			p:Close()
		else
			open()
		end
	end

	item = PopupParts.row({
		Style = style,
		Name = "Menu",
		Text = props.Text,
		Active = isOpen,
		Disabled = disabled,
		Arrow = parent ~= nil,
		Width = if parent then "Stretch" else nil,
		OnClick = if parent then open else toggle,
		-- nested menus open on hover (a bar item needs a click)
		OnHover = if parent then open else nil,
		OnDestroyed = closeRoot,
	})
	return item :: TextButton
end

local function closeThen(scope: MenuScope?, fn: () -> ()): () -> ()
	return function()
		if scope then
			scope.CloseAll()
		end
		fn()
	end
end

function Menu.MenuItem(props: MenuItemProps): TextButton
	local scope = props.Scope
	local style = props.Style or (if scope then scope.Style else Style.default)
	return PopupParts.row({
		Style = style,
		Name = "MenuItem",
		Text = props.Text,
		Shortcut = props.Shortcut,
		Disabled = disabledState(props.Disabled),
		Width = "Stretch",
		OnClick = closeThen(scope, props.OnClick),
		OnHover = if scope
			then function()
				scope:CloseSubmenu()
			end
			else nil,
	})
end

function Menu.MenuToggle(props: MenuToggleProps): TextButton
	local scope = props.Scope
	local style = props.Style or (if scope then scope.Style else Style.default)
	if props.Value ~= nil and props.Checked ~= nil then
		error("MenuToggle: give `Value` (a Source) or `Checked` (a State, controlled), not both", 2)
	end
	local own: Source<boolean>? = props.Value
	if own == nil and props.Checked == nil then
		own = q.Source(false)
	end
	local shown: State<boolean> = props.Checked or (own :: Source<boolean>)
	local onToggle = props.OnToggle
	return PopupParts.row({
		Style = style,
		Name = "MenuToggle",
		Text = props.Text,
		Shortcut = props.Shortcut,
		Checked = shown,
		Disabled = disabledState(props.Disabled),
		Width = "Stretch",
		OnClick = closeThen(scope, function()
			local nextValue = not shown:Get()
			if own then
				own:Set(nextValue)
			end
			if onToggle then
				onToggle(nextValue)
			end
		end),
		OnHover = if scope
			then function()
				scope:CloseSubmenu()
			end
			else nil,
	})
end

return Menu
