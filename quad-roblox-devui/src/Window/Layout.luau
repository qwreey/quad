--!strict
--[[
	Window layout format (internal; the types are exported from the kit root as `WindowLayout` / `WindowState`): the
	plain, JSON-ready tables a WindowManager hands out and takes back. devui never stores them — the app keeps them
	wherever it likes (plugin settings, a DataStore, an attribute) and passes them back.

	Only strings, numbers, booleans, arrays and string-keyed tables appear, so `HttpService:JSONEncode` /
	`JSONDecode` round-trip them (an empty table encodes as `[]` and decodes back as an empty table — fine either way).

		WindowLayout = {
			Version = 1,
			Windows = { [key] = { Kind = "outline", Open = true }, ... },   -- every window of the layout, by Key
			Floating = {                                                     -- the floating groups
				{ Position = { 0, 60, 0, 60 },      -- UDim2: X.Scale, X.Offset, Y.Scale, Y.Offset (outer top-left)
				  Size = { 300, 200 },              -- pixels: width, height (outer, title bar included)
				  Collapsed = false,
				  Node = { Tabs = { "outline" }, Selected = "outline" } },
				...
			},
			Left = {                                                         -- optional: the window docked on that edge
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
	a two-way split), and a floating window is a group whose node is a tab set with one tab. This devui writes and reads
	only one-tab nodes; a layout with a wider tab set or a split is rejected until docking reads them. A window's own
	facts (its Kind, whether it is open) live in `Windows`, the group's (rectangle, collapsed) in `Floating`, `Left` and
	`Right`. Every key of `Windows` has exactly one place (a floating group or an edge).
	`Floating` is in stacking order, bottom first (the keyed windows' z-order; Window/Manager header STACKING). The
	edge-docked windows' stacking is not saved: a load puts them under the floating ones [2026-10-20 user decision —
	their strip at the screen edge is never covered, so they cannot get buried]. An edge group carries the docked
	window's floating rectangle too [2026-10-20 user decision], optional on read: a group without it leaves the
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
	-- the FLOATING outer rectangle (also while docked); nil only in a state read from a layout's edge group
	Position: { number }?,
	Size: { number }?,
	Dock: Side?, -- nil = floating
	DockWidth: number?, -- the dock width (nil when floating)
}

export type DockGroup = {
	Width: number,
	Collapsed: boolean,
	Node: { Tabs: { string }, Selected: string },
	Position: { number }?, -- the floating rectangle it goes back to when undocked (exported for a live window; a pending key may lack it)
	Size: { number }?,
}

export type WindowLayout = {
	Version: number,
	Windows: { [string]: { Kind: string, Open: boolean } },
	Floating: { {
		Position: { number },
		Size: { number },
		Collapsed: boolean,
		Node: { Tabs: { string }, Selected: string },
	} },
	Left: DockGroup?,
	Right: DockGroup?,
}

local Layout = {}

Layout.VERSION = 1

-- a floating group must have a rectangle: a still-pending docked state that has to be saved as floating (its edge is
-- held by another window) and was never given one gets Window's own defaults
local DEFAULT_POSITION = { 0, 60, 0, 60 }
local DEFAULT_SIZE = { 300, 200 }

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

function Layout.copyState(s: WindowState): WindowState
	local position, size = s.Position, s.Size
	return {
		Kind = s.Kind,
		Open = s.Open,
		Collapsed = s.Collapsed,
		Position = if position ~= nil then table.clone(position) else nil,
		Size = if size ~= nil then table.clone(size) else nil,
		Dock = s.Dock,
		DockWidth = if s.Dock ~= nil then s.DockWidth else nil,
	}
end

-- an empty layout (no window)
function Layout.empty(): WindowLayout
	return { Version = Layout.VERSION, Windows = {}, Floating = {} }
end

local function tab(key: string): { Tabs: { string }, Selected: string }
	return { Tabs = { key }, Selected = key }
end

-- the layout of `keys` (in that order), each one's state from `stateOf`. `holders` names the key saved on each edge;
-- any other key whose state is docked there is saved as floating (a saved layout never holds two windows on one edge)
function Layout.build(keys: { string }, stateOf: (key: string) -> WindowState, holders: { [Side]: string }): WindowLayout
	local out = Layout.empty()
	for _, key in keys do
		local s = stateOf(key)
		out.Windows[key] = { Kind = s.Kind, Open = s.Open }
		local side = s.Dock
		if side ~= nil and holders[side] == key then
			local position, size = s.Position, s.Size
			local group: DockGroup = {
				Width = s.DockWidth :: number,
				Collapsed = s.Collapsed,
				Node = tab(key),
				-- (absent only for a still-pending state read from a group without them)
				Position = if position ~= nil then table.clone(position) else nil,
				Size = if size ~= nil then table.clone(size) else nil,
			}
			if side == "Left" then
				out.Left = group
			else
				out.Right = group
			end
		else
			local position, size = s.Position, s.Size
			table.insert(out.Floating, {
				Position = table.clone(position or DEFAULT_POSITION),
				Size = table.clone(size or DEFAULT_SIZE),
				Collapsed = s.Collapsed,
				Node = tab(key),
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

-- one tab-set node holding one key (the only node this devui reads); returns that key
local function readNode(component: string, where: string, node: any): string
	if type(node) ~= "table" or type(node.Tabs) ~= "table" then
		Util.fail(component, `{where}.Node must be a tab set \{ Tabs = \{ key }, Selected = key }`)
	end
	if #node.Tabs ~= 1 or node.Split ~= nil then
		Util.fail(component, `{where}.Node: tab groups and splits are not supported by this devui yet (one tab per group)`)
	end
	local key = node.Tabs[1]
	if type(key) ~= "string" or node.Selected ~= key then
		Util.fail(component, `{where}.Node: Tabs[1] must be a string key and Selected the same key`)
	end
	return key
end

local function windowOf(component: string, windows: any, key: string): { Kind: string, Open: boolean }
	local w = windows[key]
	if type(w) ~= "table" or type(w.Kind) ~= "string" or type(w.Open) ~= "boolean" then
		Util.fail(component, `layout.Windows["{key}"] must be \{ Kind = string, Open = boolean }`)
	end
	return w
end

-- a WindowLayout from the app (ImportLayout): its windows as (key, private state) pairs, the edge-docked keys first
-- and then the floating ones in Floating order (the stacking an import applies: docked windows under the floating)
function Layout.read(component: string, layout: any): ({ string }, { [string]: WindowState })
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
	local placedAt: { [string]: string } = {}
	local function place(key: string, where: string)
		local before = placedAt[key]
		if before ~= nil then
			Util.fail(component, `window "{key}" is placed twice in the layout ({before} and {where})`)
		end
		placedAt[key] = where
		table.insert(keys, key)
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
			local key = readNode(component, where, group.Node)
			place(key, where)
			local w = windowOf(component, windows, key)
			states[key] = {
				Kind = w.Kind,
				Open = w.Open,
				Collapsed = group.Collapsed,
				Position = if group.Position ~= nil then table.clone(group.Position) else nil,
				Size = if group.Size ~= nil then table.clone(group.Size) else nil,
				Dock = side,
				DockWidth = group.Width,
			}
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
		local key = readNode(component, where, group.Node)
		place(key, where)
		local w = windowOf(component, windows, key)
		states[key] = {
			Kind = w.Kind,
			Open = w.Open,
			Collapsed = group.Collapsed,
			Position = table.clone(group.Position),
			Size = table.clone(group.Size),
			Dock = nil,
			DockWidth = nil,
		}
	end
	for key in windows do
		if type(key) ~= "string" or states[key] == nil then
			Util.fail(component, `layout.Windows["{tostring(key)}"] has no place in layout.Floating, layout.Left or layout.Right`)
		end
	end
	return keys, states
end

return Layout
