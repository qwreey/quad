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
		}
		WindowState = { Kind = "outline", Open = true, Collapsed = false, Position = { 0, 60, 0, 60 }, Size = { 300, 200 } }

	The layout is a TREE from the start (`.claude/research/devui-docking-plan.md` 2.5): a node is a tab set (later also
	a two-way split), and a floating window is a group whose node is a tab set with one tab. This devui writes and reads
	only one-tab nodes; a layout with a wider tab set or a split is rejected until docking reads them. A window's own
	facts (its Kind, whether it is open) live in `Windows`, the group's (rectangle, collapsed) in `Floating`.
	Z-order and focus are not saved; neither is the content.
]]

local Util = require("../Util")

export type WindowState = {
	Kind: string,
	Open: boolean,
	Collapsed: boolean,
	Position: { number },
	Size: { number },
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
}

local Layout = {}

Layout.VERSION = 1

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
	return {
		Kind = s.Kind,
		Open = s.Open,
		Collapsed = s.Collapsed,
		Position = table.clone(s.Position),
		Size = table.clone(s.Size),
	}
end

-- an empty layout (no window)
function Layout.empty(): WindowLayout
	return { Version = Layout.VERSION, Windows = {}, Floating = {} }
end

-- the layout of `keys` (in that order), each one's state from `stateOf`
function Layout.build(keys: { string }, stateOf: (key: string) -> WindowState): WindowLayout
	local out = Layout.empty()
	for _, key in keys do
		local s = stateOf(key)
		out.Windows[key] = { Kind = s.Kind, Open = s.Open }
		table.insert(out.Floating, {
			Position = table.clone(s.Position),
			Size = table.clone(s.Size),
			Collapsed = s.Collapsed,
			Node = { Tabs = { key }, Selected = key },
		})
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
		local x = v[i]
		if type(x) ~= "number" or x ~= x or x == math.huge or x == -math.huge then
			return false
		end
	end
	return true
end

local function checkRect(where: string, component: string, position: any, size: any)
	if not isNumberArray(position, 4) then
		Util.fail(component, `{where}.Position must be an array of 4 numbers (UDim2 X.Scale, X.Offset, Y.Scale, Y.Offset)`)
	end
	if not isNumberArray(size, 2) then
		Util.fail(component, `{where}.Size must be an array of 2 numbers (width, height in pixels)`)
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
	checkRect("state", component, state.Position, state.Size)
	return Layout.copyState(state)
end

-- a WindowLayout from the app (ImportLayout): its windows in Floating order, as (key, private state) pairs
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
	for i, group in floating do
		local where = `layout.Floating[{i}]`
		if type(i) ~= "number" or type(group) ~= "table" then
			Util.fail(component, "layout.Floating must be an array of tables")
		end
		checkRect(where, component, group.Position, group.Size)
		if type(group.Collapsed) ~= "boolean" then
			Util.fail(component, `{where}.Collapsed must be a boolean`)
		end
		local node = group.Node
		if type(node) ~= "table" or type(node.Tabs) ~= "table" then
			Util.fail(component, `{where}.Node must be a tab set \{ Tabs = \{ key }, Selected = key }`)
		end
		if #node.Tabs ~= 1 or node.Split ~= nil then
			Util.fail(component, `{where}.Node: tab groups and splits are not supported by this devui yet (one tab per floating group)`)
		end
		local key = node.Tabs[1]
		if type(key) ~= "string" or node.Selected ~= key then
			Util.fail(component, `{where}.Node: Tabs[1] must be a string key and Selected the same key`)
		end
		if states[key] ~= nil then
			Util.fail(component, `window "{key}" is placed twice in layout.Floating`)
		end
		local w = windows[key]
		if type(w) ~= "table" or type(w.Kind) ~= "string" or type(w.Open) ~= "boolean" then
			Util.fail(component, `layout.Windows["{key}"] must be \{ Kind = string, Open = boolean }`)
		end
		table.insert(keys, key)
		states[key] = {
			Kind = w.Kind,
			Open = w.Open,
			Collapsed = group.Collapsed,
			Position = table.clone(group.Position),
			Size = table.clone(group.Size),
		}
	end
	for key in windows do
		if type(key) ~= "string" or states[key] == nil then
			Util.fail(component, `layout.Windows["{tostring(key)}"] has no place in layout.Floating`)
		end
	end
	return keys, states
end

return Layout
