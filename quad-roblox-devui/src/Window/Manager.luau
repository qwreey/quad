--!strict
--[[
	WindowManager — the COMPOSITOR of a group of windows: z-order, focus (focus-on-press, "bring to front") and every
	window's decoration. A window (Window) returns only its content SURFACE; the frame, title bar and resize grip around
	it are made here (Window/Decoration.luau, Wayland's server-side decorations) and placed as siblings of the surface
	root, in whatever parent the app gave it (they follow its `Parent`; nil parent = no decoration on screen; the
	surface root's destruction disposes them). The app's placement of the root is never changed.

	Windows hosted as siblings in one container are layered by ZIndex. This needs `ScreenGui.ZIndexBehavior = Sibling`,
	which is the default only for a ScreenGui inserted in Studio: one made in code (`q.Elem "ScreenGui"`, `Instance.new`) is
	Global unless you set it, and under Global a window ranked above another draws over its own content (a ZIndex is
	then compared across the whole ScreenGui, and the content's is 1). The manager keeps the windows in stacking order
	(bottom first) and gives each window a CHUNK of three consecutive ZIndex values by its RANK r in that list (1..n):
	3r - 2 = the decoration frame (below the surface), 3r - 1 = the surface root (`slot.ZIndex`), 3r = the resize grip
	(above the surface). `Focus` moves the window to the end and renumbers, so the ZIndex never grows past 3 x the
	number of live windows (an ever-increasing counter would climb above the Overlay layer's ZIndex 1000 after enough
	focus switches and draw windows over popups). The window that was focused last is `Focused` (its title bar draws in
	the "active" colour). A window releases its slot when it is destroyed (Window does it), so ranks stay compact.
	Supports up to 333 live windows below the default Overlay layer.

	USAGE
		local Manager = require("./Manager")
		local manager = Manager.new()                  -- or Manager.default (shared, used when props.Manager is nil)
		local slot = manager:Register()                -- one per window
		slot.ZIndex   : State<number>                  -- bind to the window root's ZIndex (the middle of its chunk)
		slot.Focused  : State<boolean>                 -- is this the focused window
		slot.Hook     : GuiHook                        -- put in the window ROOT's array part (press-to-front, see below)
		slot:Focus()                                   -- raise to front + focus (idempotent when already focused)
		slot:Blur()                                    -- drop the focus if this window has it (no window focused; the
		                                               -- order is kept) — the false side of Window's two-way `Focused`
		slot:Release()                                 -- leave the manager (idempotent); the others close ranks
		manager.Focused : State<number>                -- id of the focused window (0 = none)
	Window also talks to its slot through the internal Compositor port (Window/Compositor.luau): it hands over its
	hints (Title, the No* flags, MinSize, Position / Size / Open / Collapsed) and gets the surface's placement back,
	and it reports its open state. A hand-made root with only `slot.Hook` is an UNDECORATED window (no frame, no title
	bar; see FOCUS SUCCESSION).

	A newly registered window starts on top but does NOT steal focus (the first press focuses it).

	LAYOUT [2026-10-20 user decision — devui does not store anything: it hands out and takes back plain JSON-ready
	tables, the app keeps them; format in Window/Layout.luau]. A window with a `Key` (its IDENTITY, unique among this
	manager's live windows — a second one raises) is part of the layout; its `Kind` (its TYPE, default = the Key) is
	saved with it so a loader can make it again. A window without a Key behaves the same and is only left out of the
	layout (with `q.debug`, one notice per manager once the app uses the layout API). What is saved per window: Open,
	Collapsed, Position and Size (the floating outer rectangle). Not saved: the title, the content, the focus, the
	z-order.
		manager:ExportLayout() -> WindowLayout          every known key (live or pending), in first-seen order
		manager:ImportLayout(layout, factories?)          put the windows where the layout says (rules below)
		manager:ExportWindow(key) -> WindowState?         one window's state (nil = an unknown key)
		manager:ImportWindow(key, state)                  one window: the same rules, no factory
		manager.Layout : State<WindowLayout>              re-emitted when the layout changes (frozen tables; an Observer
		                                                  on it is the app's auto-save — debounce it, a drag writes on
		                                                  every move)
	Import rules (one API, callable at any time): a key whose window is registered moves there at once (the state is
	written into the window's own Position / Size / Open / Collapsed Sources — the app's Sources change); a key with no
	window yet is PENDING and becomes that window's initial state the moment a window with that Key registers. Windows
	the layout does not name are left as they are. Pending keys are exported again unchanged (an unknown key is never
	dropped: a session without some window keeps its place). `factories` maps a Kind to `function(key)` = "make the
	window of this identity exist" (the app builds it and puts it where it wants; devui never parents a root): it is
	called once per key that was OPEN when saved and is not registered yet; a Kind missing from the map stays pending.
	A keyed window that is destroyed leaves its last state pending (an app rebuilding its UI gets its windows back,
	and the Layout output does not change).

	PRESS TO FRONT. A press stops at the first GuiButton / TextBox under the pointer (engine rule): the window frame
	behind a button, a checkbox or a text box never sees an InputBegan. So the manager listens to ONE global press
	(`UserInputService.InputBegan`, mouse button 1 / touch — through `Input.service()`, opened while at least one root is
	hooked and closed when the last one leaves; `Input.use` moves it to the new service) and finds the window the press
	went to. `gameProcessedEvent` is NOT filtered: a press on a widget is exactly the case that needs it. It focuses on
	PRESS, not release, like the title bar and Dear ImGui (devui has no drag-and-drop between windows that would need
	release-time focus).
	Hit test (the internal Pointer rule, shared with hover and tooltips): walk `PlayerGui:GetGuiObjectsAtPosition` from
	the top; the first object inside a hooked window root OR inside one of its decoration instances focuses that
	window, and an object that TAKES THE CLICK before that (a button, a text box or an Active object outside every
	window: an open popup's row or click-outside catcher, a HUD button of another ScreenGui) means the press is not the
	window's — nothing changes. Objects that take no input (a tooltip, a transparent layer) are passed through, as the
	engine passes the press. A window that is hidden or detached from the tree is never in that list.
	Without a PlayerGui (a story host renders into a plugin widget) it falls back to rectangles: an open popup that
	takes input (the internal PopupHits registry) changes nothing, else the highest-rank window on screen whose root
	or decoration AbsolutePosition / AbsoluteSize rectangle holds the point is focused.

	FOCUS SUCCESSION (Dear ImGui: closing the focused window gives focus to the topmost remaining one). When the focused
	window is closed or released, the topmost window still open is focused (and raised); none left = `Focused` 0.
	"Open" is the window's own state, told by Window through the Compositor port (`Open`), NOT its root's `Visible`:
	the surface root is also hidden while collapsed (and, later, while another surface of its group is shown), and
	that must not pass the focus on. Still open = open AND its container on screen (shown, ancestors shown, in a
	placed LayerCollector). An undecorated window (a hand-made root) keeps the older rule: its root's `Visible` going
	false is a close, and "still open" = its root on screen. A closed window keeps its slot; when it is opened again
	it comes to the front WITH the focus (Dear ImGui focuses an appearing window — user decision 2026-10-15). A window
	that is open from the start does not steal the focus (the line above).
]]

local GlobalInput = require("../GlobalInput")
local Input = require("../Input")
local Pointer = require("../Pointer")
local PopupHits = require("../PopupHits")
local Quad = require("../Quad")
local q = Quad
local Types = require("../Types")
local Visibility = require("../Visibility")
local Util = require("../Util")
local Compositor = require("./Compositor")
local Decoration = require("./Decoration")
local Layout = require("./Layout")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>

export type Slot = {
	Id: number,
	ZIndex: State<number>,
	Focused: State<boolean>,
	Hook: Types.GuiHook,
	Focus: (self: Slot) -> (),
	Blur: (self: Slot) -> (),
	Release: (self: Slot) -> (),
}

export type WindowLayout = Layout.WindowLayout
export type WindowState = Layout.WindowState

export type Manager = {
	Focused: State<number>,
	Layout: State<WindowLayout>,
	Register: (self: Manager) -> Slot,
	ExportLayout: (self: Manager) -> WindowLayout,
	ImportLayout: (self: Manager, layout: WindowLayout, factories: { [string]: (key: string) -> () }?) -> (),
	ExportWindow: (self: Manager, key: string) -> WindowState?,
	ImportWindow: (self: Manager, key: string, state: WindowState) -> (),
}

type Entry = {
	Id: number,
	Rank: Source<number>, -- 1..n, bottom first
	Root: GuiObject?,
	Open: State<boolean>?, -- the surface's open state (decorated windows only; nil = the root's Visible decides)
	Deco: Decoration.Decoration?,
	Hints: Decoration.Hints?, -- decorated windows: the Sources a layout is read from and written into
	Key: string?, -- decorated windows with a Key: their identity in the layout
	Kind: string,
}

-- ZIndex values per window (decoration frame, surface, resize grip): see the header
local SPAN = 3

local Manager = {}

local function isPrimaryDown(input: InputObject): boolean
	local t = input.UserInputType
	return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch
end

-- the point is in gui's on-screen rectangle
local function holds(gui: Instance, x: number, y: number): boolean
	if not Visibility.isGuiObject(gui) then
		return false
	end
	local g = gui :: GuiObject
	local p, s = g.AbsolutePosition, g.AbsoluteSize
	return x >= p.X and y >= p.Y and x < p.X + s.X and y < p.Y + s.Y and Visibility.isOnScreen(g)
end

function Manager.new(): Manager
	local nextId = 0
	local focusedId: Source<number> = q.Source(0)
	-- live windows, bottom first; Rank = position
	local order: { Entry } = {}
	-- entries whose root is hooked (the global press listener is open while this is > 0)
	local hooked = 0
	local offPress: (() -> ())? = nil

	-- LAYOUT (header "LAYOUT"): every key this manager knows, in first-seen order (the export order); a known key is
	-- either live (a registered window holds it) or pending (its state waits for that window)
	local known: { string } = {}
	local live: { [string]: Entry } = {}
	local pending: { [string]: WindowState } = {}
	local layoutOut: Source<WindowLayout> = q.Source(Layout.freeze(Layout.empty()))
	local batching = 0
	local layoutDirty = false
	-- the q.debug notice about windows without a Key: once per manager, after the app used the layout API
	local layoutUsed = false
	local keylessNoticed = false
	local keyless: { [Entry]: string } = {} -- decorated windows without a Key -> their title (for the notice)

	local function remember(key: string)
		if live[key] == nil and pending[key] == nil then
			table.insert(known, key)
		end
	end

	local function snapshot(entry: Entry): WindowState
		local h = entry.Hints :: Decoration.Hints
		return {
			Kind = entry.Kind,
			Open = h.Open:Get(),
			Collapsed = h.Collapsed:Get(),
			Position = Layout.positionOf(h.Position:Get()),
			Size = Layout.sizeOf(h.Size:Get()),
		}
	end

	local function stateOf(key: string): WindowState
		local entry = live[key]
		return if entry ~= nil then snapshot(entry) else pending[key]
	end

	-- write a saved state into a window's own Sources (the app's Sources change; the window follows them). The
	-- window's Kind is its own: a saved Kind never renames a live window.
	local function apply(entry: Entry, state: WindowState)
		local h = entry.Hints :: Decoration.Hints
		h.Collapsed:SetIfChanged(state.Collapsed)
		h.Size:SetIfChanged(Layout.toSize(state.Size))
		h.Position:SetIfChanged(Layout.toPosition(state.Position))
		h.Open:SetIfChanged(state.Open)
	end

	local function refresh()
		if batching > 0 then
			layoutDirty = true
			return
		end
		layoutDirty = false
		local nextLayout = Layout.build(known, stateOf)
		if not Layout.same(nextLayout, layoutOut:Get()) then
			layoutOut:Set(Layout.freeze(nextLayout))
		end
	end

	-- run `body` with the Layout output held back, then emit once (also when body throws: the error goes on)
	local function batch(body: () -> ())
		batching += 1
		local ok, err = pcall(body)
		batching -= 1
		if batching == 0 and layoutDirty then
			refresh()
		end
		if not ok then
			error(err, 0)
		end
	end

	local function noticeKeyless()
		if not q.debug or keylessNoticed or not layoutUsed then
			return
		end
		local _, title = next(keyless)
		if title ~= nil then
			keylessNoticed = true
			print(`Devui.WindowManager: a window without Key ("{title}") is left out of the layout — give each window you want saved a Key (its identity in the manager)`)
		end
	end

	local function renumber()
		for i, entry in order do
			entry.Rank:SetIfChanged(i)
		end
		-- what is on top under a still pointer may have changed (hover looks re-judge)
		Pointer.invalidate()
	end

	local function focus(entry: Entry)
		if focusedId:Get() == entry.Id and order[#order] == entry then
			return -- already focused AND on top (a newer registration may cover a focused window)
		end
		local at = table.find(order, entry)
		if at == nil then
			return -- released
		end
		table.remove(order, at)
		table.insert(order, entry)
		renumber()
		focusedId:SetIfChanged(entry.Id) -- (a focused window that was only covered: the rank changed, the focus did not)
	end

	-- still open (header FOCUS SUCCESSION)
	local function isOpen(entry: Entry): boolean
		local root = entry.Root
		if root == nil then
			return false
		end
		local open = entry.Open
		if open == nil then
			return Visibility.isOnScreen(root)
		end
		local container = root.Parent
		return open:Get() and container ~= nil and Visibility.isOnScreen(container)
	end

	-- the focused window went away (closed or released): the topmost window still open takes the focus
	local function succeed()
		for i = #order, 1, -1 do
			if isOpen(order[i]) then
				focus(order[i])
				return
			end
		end
		focusedId:Set(0)
	end

	-- the window whose root or decoration instance is `inst`
	local function ownerOf(inst: Instance): Entry?
		for _, entry in order do
			if entry.Root == inst then
				return entry
			end
			local deco = entry.Deco
			if deco ~= nil and table.find(deco.Parts, inst) ~= nil then
				return entry
			end
		end
		return nil
	end

	-- the innermost window whose root or decoration is o or above it
	local function windowOf(o: Instance): Entry?
		local cursor: Instance? = o
		while cursor ~= nil do
			local entry = ownerOf(cursor)
			if entry ~= nil then
				return entry
			end
			cursor = cursor.Parent
		end
		return nil
	end

	local function onPress(input: InputObject)
		if not isPrimaryDown(input) then
			return
		end
		local x, y = input.Position.X, input.Position.Y
		local list = nil
		for i = #order, 1, -1 do
			local root = order[i].Root
			if root ~= nil then
				list = Pointer.objectsAt(root, x, y)
				if list ~= nil then
					break
				end
			end
		end
		if list ~= nil then
			for _, o in list do
				local entry = windowOf(o)
				if entry ~= nil then
					focus(entry)
					return
				elseif Pointer.takesClick(o) then
					return -- the press went to something that is not a window (a popup, another ScreenGui's button)
				end
			end
			return
		end
		-- no PlayerGui (a story host): rectangles
		if PopupHits.covers(x, y) then
			return
		end
		for i = #order, 1, -1 do
			local entry = order[i]
			local root = entry.Root
			if root ~= nil then
				local hit = holds(root, x, y)
				local deco = entry.Deco
				if not hit and deco ~= nil then
					for _, part in deco.Parts do
						if holds(part, x, y) then
							hit = true
							break
						end
					end
				end
				if hit then
					focus(entry)
					return
				end
			end
		end
	end

	local function hook(delta: number)
		hooked += delta
		local off = offPress
		if hooked > 0 and off == nil then
			offPress = GlobalInput.connect(Input.service(), "InputBegan", onPress)
		elseif hooked == 0 and off ~= nil then
			offPress = nil
			off()
		end
	end

	local focusedOut: State<number> = focusedId
	local layoutState: State<WindowLayout> = layoutOut
	local manager: Manager = {
		Focused = focusedOut,
		Layout = layoutState,
		ExportLayout = function(_self: Manager): WindowLayout
			layoutUsed = true
			noticeKeyless()
			return Layout.build(known, stateOf)
		end,
		ImportLayout = function(_self: Manager, layout: WindowLayout, factories: { [string]: (key: string) -> () }?)
			local keys, states = Layout.read("WindowManager:ImportLayout", layout)
			if factories ~= nil and type(factories) ~= "table" then
				Util.fail("WindowManager:ImportLayout", `factories must be a table \{ [Kind] = function(key) }, got {typeof(factories)}`)
			end
			-- check every entry up front: a bad one must fail whether or not this layout happens to need it
			if factories ~= nil then
				for kind, make in factories do
					if type(kind) ~= "string" or type(make) ~= "function" then
						Util.fail("WindowManager:ImportLayout", `factories must map a Kind string to a function(key), got [{typeof(kind)}] = {typeof(make)}`)
					end
				end
			end
			layoutUsed = true
			noticeKeyless()
			batch(function()
				-- the export order follows the layout; keys it does not name keep their order after it
				local reordered: { string } = table.clone(keys)
				for _, key in known do
					if states[key] == nil then
						table.insert(reordered, key)
					end
				end
				known = reordered
				-- a window already on screen moves to its saved place; any other key waits for its window
				for _, key in keys do
					local entry = live[key]
					if entry ~= nil then
						apply(entry, states[key])
					else
						pending[key] = states[key]
					end
				end
				layoutDirty = true
				-- "make the window of this identity exist": only for keys open when saved, never for a registered one;
				-- a Kind missing from the map stays pending (its window may come later)
				if factories ~= nil then
					for _, key in keys do
						local state = states[key]
						local make = factories[state.Kind]
						if state.Open and live[key] == nil and make ~= nil then
							make(key)
						end
					end
				end
			end)
		end,
		ExportWindow = function(_self: Manager, key: string): WindowState?
			if type(key) ~= "string" then
				Util.fail("WindowManager:ExportWindow", `key must be a string, got {typeof(key)}`)
			end
			layoutUsed = true
			noticeKeyless()
			local entry = live[key]
			if entry ~= nil then
				return snapshot(entry)
			end
			local waiting = pending[key]
			return if waiting ~= nil then Layout.copyState(waiting) else nil
		end,
		ImportWindow = function(_self: Manager, key: string, state: WindowState)
			if type(key) ~= "string" then
				Util.fail("WindowManager:ImportWindow", `key must be a string, got {typeof(key)}`)
			end
			local copy = Layout.readState("WindowManager:ImportWindow", state)
			layoutUsed = true
			noticeKeyless()
			batch(function()
				local entry = live[key]
				if entry ~= nil then
					apply(entry, copy)
				else
					remember(key)
					pending[key] = copy
				end
				layoutDirty = true
			end)
		end,
		Register = function(_self: Manager): Slot
			nextId += 1
			local id = nextId
			local rank: Source<number> = q.Source(#order + 1)
			local entry: Entry = { Id = id, Rank = rank, Root = nil, Open = nil, Deco = nil, Hints = nil, Key = nil, Kind = "" }
			table.insert(order, entry)
			local isFocused: State<boolean> = focusedId:Compute(function(self)
				return self:Get() == id
			end)
			local surfaceZ: State<number> = rank:Compute(function(self)
				return (self:Get() - 1) * SPAN + 2
			end)
			local visibleConn: RBXScriptConnection? = nil
			local parentConn: RBXScriptConnection? = nil

			-- the decoration follows the surface root's parent (it is placed as the root's sibling)
			local function follow()
				local root, deco = entry.Root, entry.Deco
				if root == nil or deco == nil or parentConn ~= nil then
					return
				end
				deco.SetParent(root.Parent)
				parentConn = root:GetPropertyChangedSignal("Parent"):Connect(function()
					deco.SetParent(root.Parent)
				end)
			end

			local rootHook: Types.GuiHook = q.PostRef(nil :: GuiObject?)
			local slot: Slot
			rootHook:Callback(function(inst)
				if inst == nil or entry.Root ~= nil or table.find(order, entry) == nil then
					return
				end
				entry.Root = inst
				Compositor.bindRoot(inst, slot)
				hook(1)
				visibleConn = inst:GetPropertyChangedSignal("Visible"):Connect(function()
					Pointer.invalidate()
					if entry.Open ~= nil then
						return -- a decorated surface: its open state comes through the Compositor port
					end
					if inst.Visible then
						focus(entry) -- shown again: to the front with the focus (Dear ImGui focuses an appearing window)
					elseif focusedId:Get() == id then
						succeed()
					end
				end)
				follow()
			end)

			slot = {
				Id = id,
				ZIndex = surfaceZ,
				Focused = isFocused,
				Hook = rootHook,
				Focus = function(_slot: Slot)
					focus(entry)
				end,
				Blur = function(_slot: Slot)
					if focusedId:Get() == id then
						focusedId:Set(0)
					end
				end,
				Release = function(_slot: Slot)
					local at = table.find(order, entry)
					if at == nil then
						return
					end
					table.remove(order, at)
					renumber()
					Compositor.unbind(slot, entry.Root)
					if entry.Root ~= nil then
						entry.Root = nil
						local vc, pc = visibleConn, parentConn
						visibleConn = nil
						parentConn = nil
						if vc then
							vc:Disconnect()
						end
						if pc then
							pc:Disconnect()
						end
						hook(-1)
					end
					-- a keyed window that goes away leaves its last state pending (an app tearing its UI down and building
					-- it again gets its windows back where they were; the Layout output does not change)
					local key = entry.Key
					if key ~= nil and live[key] == entry then
						pending[key] = snapshot(entry)
						live[key] = nil
					end
					keyless[entry] = nil
					local deco = entry.Deco
					if deco ~= nil then
						entry.Deco = nil
						deco.Destroy()
					end
					if focusedId:Get() == id then
						succeed()
					end
				end,
			}

			Compositor.bind(slot, {
				decorate = function(hints: Decoration.Hints): Decoration.Placement
					local key = hints.Key
					if key ~= nil then
						if live[key] ~= nil then
							slot:Release()
							return Util.fail(
								"Window",
								`Key "{key}" is already used by another window of this WindowManager (Key is the window's identity; give two windows of one type the same Kind and different Keys)`
							)
						end
						entry.Key = key
						entry.Kind = hints.Kind or key
						entry.Hints = hints
						-- a state waiting for this key (ImportLayout / ImportWindow before the window existed) is its
						-- initial state: written into its Sources before anything is built from them
						local waiting = pending[key]
						remember(key)
						live[key] = entry
						if waiting ~= nil then
							pending[key] = nil
							apply(entry, waiting)
						end
					else
						entry.Hints = hints
						keyless[entry] = if type(hints.Title) == "string" then hints.Title else hints.Title:Get()
						noticeKeyless()
					end
					local backZ: State<number> = rank:Compute(function(self)
						return (self:Get() - 1) * SPAN + 1
					end)
					local frontZ: State<number> = rank:Compute(function(self)
						return self:Get() * SPAN
					end)
					local deco = Decoration.new(hints, {
						BackZ = backZ,
						FrontZ = frontZ,
						Focused = isFocused,
						Raise = function()
							focus(entry)
						end,
						Changed = if key ~= nil then refresh else nil,
					})
					entry.Deco = deco
					entry.Open = hints.Open
					follow()
					if key ~= nil then
						refresh()
					end
					return deco.Surface
				end,
				setOpen = function(open: boolean)
					Pointer.invalidate()
					if open then
						focus(entry) -- opened (or asked again with `Open:Set(true)`): to the front with the focus
					elseif focusedId:Get() == id then
						succeed()
					end
				end,
				parts = function(): { Instance }
					local deco = entry.Deco
					return if deco ~= nil then table.clone(deco.Parts) else {}
				end,
			})
			return slot
		end,
	}
	-- the methods are public surface: a usage error inside them blames the app's calling line
	Util.tagSurface(manager)
	return manager
end

Manager.default = Manager.new()

return Manager
