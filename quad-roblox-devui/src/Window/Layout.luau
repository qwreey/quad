--!strict
--[[
	Window layout format (internal; the types are exported from the kit root as `WindowLayout` / `WindowState`): the
	plain, JSON-ready tables a WindowManager hands out and takes back. devui never stores them — the app keeps them
	wherever it likes (plugin settings, a DataStore, an attribute) and passes them back.

	Only strings, numbers, booleans, arrays and string-keyed tables appear, so `HttpService:JSONEncode` /
	`JSONDecode` round-trip them (an empty table encodes as `[]` and decodes back as an empty table — fine either way).

		WindowLayout = {
			Version = 1,
			Windows = {                                                      -- every window of the layout, by Key
				outline = { Kind = "outline", Open = true },
				notes = { Kind = "notes", Open = false,
				          Position = { 0, 80, 0, 90 }, Size = { 240, 160 } },  -- optional: a tab's own rectangle (below)
			},
			Floating = {                                                     -- the floating groups, bottom first
				{ Position = { 0, 60, 0, 60 },      -- UDim2: X.Scale, X.Offset, Y.Scale, Y.Offset (outer top-left)
				  Size = { 300, 200 },              -- pixels: width, height (outer, title bar / tab strip included)
				  Collapsed = false,
				  Node = { Tabs = { "outline", "notes" }, Selected = "outline" } },
				...
			},
			Left = {                                                         -- optional: the group docked on that edge
				Width = 280,                        -- the dock width in pixels
				Collapsed = false,
				Node = { Tabs = { "explorer" }, Selected = "explorer" },
				Position = { 0, 60, 0, 60 },        -- optional: the floating rectangle it goes back to when undocked
				Size = { 300, 200 },                --   (written for a live window; a pending key read from an older save without them may lack them)
			},
			Right = { ... },                                                 -- optional, the same shape
		}
		WindowState = { Kind = "outline", Open = true, Collapsed = false, Position = { 0, 60, 0, 60 }, Size = { 300, 200 },
		                Dock = "Left", DockWidth = 280 }   -- Dock / DockWidth: nil = floating

	The layout is a TREE from the start (`.claude/research/devui-docking-plan.md` 2.5): a node is a tab set (later also
	a two-way split), and a floating window is a group whose node is a tab set with one tab. [2026-10-21 user decisions —
	docking stage 3] A node may hold several tabs (a tab group: unique keys, `Selected` one of them; a closed tab stays
	in its node with `Windows[key].Open = false`); a split is still rejected. A window's own facts (its Kind, whether it
	is open) live in `Windows`, the group's (rectangle, collapsed, edge) in `Floating`, `Left` and `Right`. Every key
	of `Windows` has exactly one place (one node of a floating group or an edge).
	A TAB'S OWN RECTANGLE [2026-10-21 user decision]: while grouped, a window's Position / Size Sources keep the
	rectangle it had before it joined (the group's rectangle is the node's). `Windows[key].Position` / `Size` carry
	that kept rectangle — written only in a node of two or more saved (keyed) tabs, for a member that has one
	(a window that joined by a drag has one; one grouped by a load without these fields has none), read back as that
	window's kept rectangle (it goes back to it when its tab is dragged out). A window without them is dragged out at
	the group's Size. A single window's rectangle stays in its node's group, as before.
	`Floating` is in stacking order, bottom first (the keyed groups' z-order; Window/Manager header STACKING). The
	edge-docked groups' stacking is not saved: a load puts them under the floating ones [2026-10-20 user decision —
	their strip at the screen edge is never covered, so they cannot get buried]. An edge group carries the docked
	group's floating rectangle too [2026-10-20 user decision], optional on read: a group without it leaves the
	window's Position / Size Sources as they are, which is why `WindowState.Position` / `Size` are optional. The focus
	is not saved; neither is the content.
]]

local Util = require("../Util")

-- the screen edge a window is docked on
export type Side = "Left" | "Right"

export type WindowState = {
	Kind: string,
	Open: boolean,
	Collapsed: boolean,
	-- the FLOATING outer rectangle (also while docked); nil only in a state read from a layout's edge group (or for a
	-- grouped window without a kept rectangle)
	Position: { number }?,
	Size: { number }?,
	Dock: Side?, -- nil = floating
	DockWidth: number?, -- the dock width (nil when floating)
}

-- one window of `WindowLayout.Windows`: Position / Size only for a grouped window's kept rectangle (header)
export type WindowEntry = {
	Kind: string,
	Open: boolean,
	Position: { number }?,
	Size: { number }?,
}

export type TabNode = { Tabs: { string }, Selected: string }

export type DockGroup = {
	Width: number,
	Collapsed: boolean,
	Node: TabNode,
	Position: { number }?, -- the floating rectangle it goes back to when undocked (exported for a live window; a pending key may lack it)
	Size: { number }?,
}

export type WindowLayout = {
	Version: number,
	Windows: { [string]: WindowEntry },
	Floating: { {
		Position: { number },
		Size: { number },
		Collapsed: boolean,
		Node: TabNode,
	} },
	Left: DockGroup?,
	Right: DockGroup?,
}

-- what the manager hands `build` per saved group (a plain window is a unit of one tab), in stacking order
export type Unit = {
	Tabs: { string },
	Selected: string,
	Windows: { [string]: WindowEntry },
	Collapsed: boolean,
	Position: { number }?, -- the group's floating rectangle (nil only for a pending edge state read without one)
	Size: { number }?,
	Dock: Side?,
	Width: number?,
}

-- what `read` hands the manager per node (docked ones first, then `Floating` in order)
export type ReadNode = {
	Tabs: { string },
	Selected: string,
	Collapsed: boolean,
	Position: { number }?,
	Size: { number }?,
	Dock: Side?,
	Width: number?,
}

local Layout = {}

Layout.VERSION = 1

-- a floating group must have a rectangle: a still-pending docked state that has to be saved as floating (its edge is
-- held by another window) and was never given one gets Window's own defaults
local DEFAULT_POSITION = { 0, 60, 0, 60 }
local DEFAULT_SIZE = { 300, 200 }
Layout.DEFAULT_POSITION = DEFAULT_POSITION
Layout.DEFAULT_SIZE = DEFAULT_SIZE

function Layout.positionOf(p: UDim2): { number }
	return { p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset }
end

function Layout.sizeOf(s: Vector2): { number }
	return { s.X, s.Y }
end

function Layout.toPosition(t: { number }): UDim2
	return UDim2.new(t[1], t[2], t[3], t[4])
end

function Layout.toSize(t: { number }): Vector2
	return Vector2.new(t[1], t[2])
end

local function cloneOpt(t: { number }?): { number }?
	return if t ~= nil then table.clone(t) else nil
end

function Layout.copyState(s: WindowState): WindowState
	return {
		Kind = s.Kind,
		Open = s.Open,
		Collapsed = s.Collapsed,
		Position = cloneOpt(s.Position),
		Size = cloneOpt(s.Size),
		Dock = s.Dock,
		DockWidth = if s.Dock ~= nil then s.DockWidth else nil,
	}
end

-- an empty layout (no window)
function Layout.empty(): WindowLayout
	return { Version = Layout.VERSION, Windows = {}, Floating = {} }
end

-- the layout of `units` (in stacking order). `holders` names the unit saved on each edge; any other unit docked there
-- is saved as floating (a saved layout never holds two groups on one edge)
function Layout.build(units: { Unit }, holders: { [Side]: Unit }): WindowLayout
	local out = Layout.empty()
	for _, unit in units do
		for key, w in unit.Windows do
			out.Windows[key] = { Kind = w.Kind, Open = w.Open, Position = cloneOpt(w.Position), Size = cloneOpt(w.Size) }
		end
		local node: TabNode = { Tabs = table.clone(unit.Tabs), Selected = unit.Selected }
		local side = unit.Dock
		if side ~= nil and holders[side] == unit then
			local group: DockGroup = {
				Width = unit.Width :: number,
				Collapsed = unit.Collapsed,
				Node = node,
				-- (absent only for a still-pending state read from a group without them)
				Position = cloneOpt(unit.Position),
				Size = cloneOpt(unit.Size),
			}
			if side == "Left" then
				out.Left = group
			else
				out.Right = group
			end
		else
			table.insert(out.Floating, {
				Position = table.clone(unit.Position or DEFAULT_POSITION),
				Size = table.clone(unit.Size or DEFAULT_SIZE),
				Collapsed = unit.Collapsed,
				Node = node,
			})
		end
	end
	return out
end

-- structural equality of plain tables (the Layout output emits only when the layout really changed)
function Layout.same(a: any, b: any): boolean
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end
	for k, v in a do
		if not Layout.same(v, b[k]) then
			return false
		end
	end
	for k in b do
		if a[k] == nil then
			return false
		end
	end
	return true
end

function Layout.freeze<T>(t: T): T
	local any_: any = t
	if type(any_) == "table" and not table.isfrozen(any_) then
		for _, v in any_ do
			Layout.freeze(v)
		end
		table.freeze(any_)
	end
	return t
end

-- ── reading what the app hands back (it may come from JSON or from an old save: checked, never trusted) ─────────

local function isFinite(x: any): boolean
	return type(x) == "number" and x == x and x ~= math.huge and x ~= -math.huge
end

local function isNumberArray(v: any, n: number): boolean
	if type(v) ~= "table" or #v ~= n then
		return false
	end
	local count = 0
	for _ in v do
		count += 1
	end
	if count ~= n then -- a hole or an extra key
		return false
	end
	for i = 1, n do
		if not isFinite(v[i]) then
			return false
		end
	end
	return true
end

local function checkPosition(where: string, component: string, position: any)
	if not isNumberArray(position, 4) then
		Util.fail(component, `{where}.Position must be an array of 4 numbers (UDim2 X.Scale, X.Offset, Y.Scale, Y.Offset)`)
	end
end

local function checkSize(where: string, component: string, size: any)
	if not isNumberArray(size, 2) then
		Util.fail(component, `{where}.Size must be an array of 2 numbers (width, height in pixels)`)
	end
end

local function checkWidth(where: string, component: string, width: any)
	if not isFinite(width) or width <= 0 then
		Util.fail(component, `{where} must be a positive number (the dock width in pixels)`)
	end
end

-- a WindowState from the app (ImportWindow); returns a private copy
function Layout.readState(component: string, state: any): WindowState
	if type(state) ~= "table" then
		return Util.fail(component, `state must be a WindowState table, got {typeof(state)}`)
	end
	if type(state.Kind) ~= "string" then
		Util.fail(component, "state.Kind must be a string")
	end
	if type(state.Open) ~= "boolean" or type(state.Collapsed) ~= "boolean" then
		Util.fail(component, "state.Open and state.Collapsed must be booleans")
	end
	-- the floating rectangle may be left out (the window keeps the one its Sources hold)
	if state.Position ~= nil then
		checkPosition("state", component, state.Position)
	end
	if state.Size ~= nil then
		checkSize("state", component, state.Size)
	end
	local dock = state.Dock
	if dock ~= nil and dock ~= "Left" and dock ~= "Right" then
		Util.fail(component, `state.Dock must be "Left", "Right" or nil, got {tostring(dock)}`)
	end
	if dock ~= nil then
		checkWidth("state.DockWidth", component, state.DockWidth)
	elseif state.DockWidth ~= nil then
		Util.fail(component, "state.DockWidth must be nil when state.Dock is nil (a floating window has no dock width)")
	end
	return Layout.copyState(state)
end

-- a tab-set node: one or more unique string keys, Selected one of them; returns its tabs
local function readNode(component: string, where: string, node: any): { string }
	if type(node) ~= "table" or type(node.Tabs) ~= "table" then
		Util.fail(component, `{where}.Node must be a tab set \{ Tabs = \{ key, ... }, Selected = key }`)
	end
	if node.Split ~= nil then
		Util.fail(component, `{where}.Node: splits are not supported by this devui yet (a node is a tab set)`)
	end
	local tabs = node.Tabs
	local n = #tabs
	local count = 0
	for _ in tabs do
		count += 1
	end
	if n == 0 or count ~= n then
		Util.fail(component, `{where}.Node.Tabs must be a non-empty array of keys`)
	end
	local seen: { [string]: true } = {}
	for i = 1, n do
		local key = tabs[i]
		if type(key) ~= "string" then
			Util.fail(component, `{where}.Node.Tabs[{i}] must be a string key`)
		end
		if seen[key] then
			Util.fail(component, `{where}.Node.Tabs lists "{key}" twice`)
		end
		seen[key] = true
	end
	if type(node.Selected) ~= "string" or not seen[node.Selected] then
		Util.fail(component, `{where}.Node: Selected must be one of its Tabs`)
	end
	return table.clone(tabs)
end

local function windowOf(component: string, windows: any, key: string): WindowEntry
	local w = windows[key]
	if type(w) ~= "table" or type(w.Kind) ~= "string" or type(w.Open) ~= "boolean" then
		Util.fail(component, `layout.Windows["{key}"] must be \{ Kind = string, Open = boolean }`)
	end
	-- a grouped window's kept rectangle (header "A TAB'S OWN RECTANGLE"), the same encoding as a group's
	if w.Position ~= nil then
		checkPosition(`layout.Windows["{key}"]`, component, w.Position)
	end
	if w.Size ~= nil then
		checkSize(`layout.Windows["{key}"]`, component, w.Size)
	end
	return w
end

-- a WindowLayout from the app (ImportLayout): its windows as keys in stacking order (the edge-docked nodes first, then
-- the floating ones in Floating order — the stacking an import applies: docked windows under the floating), a private
-- state per key and the nodes (groups). A key of a node with several tabs gets the node's collapsed / edge and its
-- own kept rectangle (`Windows[key].Position` / `Size`, nil when absent); a key alone in its node gets the node's
-- rectangle, as before.
function Layout.read(component: string, layout: any): ({ string }, { [string]: WindowState }, { ReadNode })
	if type(layout) ~= "table" then
		Util.fail(component, `layout must be a WindowLayout table, got {typeof(layout)}`)
	end
	if layout.Version ~= Layout.VERSION then
		Util.fail(component, `unknown layout Version {tostring(layout.Version)} (this devui reads Version {Layout.VERSION})`)
	end
	local windows, floating = layout.Windows, layout.Floating
	if type(windows) ~= "table" or type(floating) ~= "table" then
		Util.fail(component, "layout.Windows and layout.Floating must be tables")
	end
	local keys: { string } = {}
	local states: { [string]: WindowState } = {}
	local nodes: { ReadNode } = {}
	local placedAt: { [string]: string } = {}
	local function place(key: string, where: string)
		local before = placedAt[key]
		if before ~= nil then
			Util.fail(component, `window "{key}" is placed twice in the layout ({before} and {where})`)
		end
		placedAt[key] = where
		table.insert(keys, key)
	end
	-- one node's keys: placed, and a state each (`rect` = the group's floating rectangle)
	local function readGroup(where: string, group: any, side: Side?, width: number?)
		local tabs = readNode(component, where, group.Node)
		local position: { number }? = if group.Position ~= nil then table.clone(group.Position) else nil
		local size: { number }? = if group.Size ~= nil then table.clone(group.Size) else nil
		for _, key in tabs do
			place(key, where)
			local w = windowOf(component, windows, key)
			local alone = #tabs == 1
			states[key] = {
				Kind = w.Kind,
				Open = w.Open,
				Collapsed = group.Collapsed,
				Position = if alone then cloneOpt(position) else cloneOpt(w.Position),
				Size = if alone then cloneOpt(size) else cloneOpt(w.Size),
				Dock = side,
				DockWidth = width,
			}
		end
		table.insert(nodes, {
			Tabs = tabs,
			Selected = group.Node.Selected,
			Collapsed = group.Collapsed,
			Position = position,
			Size = size,
			Dock = side,
			Width = width,
		})
	end
	for _, side: Side in { "Left" :: Side, "Right" :: Side } do
		local found: any = layout[side]
		if found ~= nil then
			local where = `layout.{side}`
			if type(found) ~= "table" then
				Util.fail(component, `{where} must be \{ Width = number, Collapsed = boolean, Node = \{ Tabs = \{ key }, Selected = key } } or nil`)
			end
			local group: any = found
			checkWidth(`{where}.Width`, component, group.Width)
			-- the floating rectangle is optional here (a save from before it was written)
			if group.Position ~= nil then
				checkPosition(where, component, group.Position)
			end
			if group.Size ~= nil then
				checkSize(where, component, group.Size)
			end
			if type(group.Collapsed) ~= "boolean" then
				Util.fail(component, `{where}.Collapsed must be a boolean`)
			end
			readGroup(where, group, side, group.Width)
		end
	end
	for i, group in floating do
		local where = `layout.Floating[{i}]`
		if type(i) ~= "number" or type(group) ~= "table" then
			Util.fail(component, "layout.Floating must be an array of tables")
		end
		checkPosition(where, component, group.Position)
		checkSize(where, component, group.Size)
		if type(group.Collapsed) ~= "boolean" then
			Util.fail(component, `{where}.Collapsed must be a boolean`)
		end
		readGroup(where, group, nil, nil)
	end
	for key in windows do
		if type(key) ~= "string" or states[key] == nil then
			Util.fail(component, `layout.Windows["{tostring(key)}"] has no place in layout.Floating, layout.Left or layout.Right`)
		end
	end
	return keys, states, nodes
end

return Layout
