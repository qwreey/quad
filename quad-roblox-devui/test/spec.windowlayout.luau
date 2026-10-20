--!strict
-- WindowManager layout: Key / Kind, ExportLayout / ImportLayout / ExportWindow / ImportWindow, the Layout output.
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Devui = require("../src")

local lune = require :: any
local serde = lune("@lune/serde")

type WindowLayout = Devui.WindowLayout
type WindowState = Devui.WindowState

-- every value is JSON-ready: strings, finite numbers, booleans, and tables that are either arrays (1..n) or
-- string-keyed, with no metatable (walked, not assumed)
local function assertPlain(v: any, path: string)
	local t = type(v)
	if t == "string" or t == "boolean" then
		return
	elseif t == "number" then
		assert(v == v and v ~= math.huge and v ~= -math.huge, `{path}: a finite number`)
		return
	end
	assert(t == "table", `{path}: {t} is not JSON-ready`)
	assert(getmetatable(v) == nil, `{path}: a table with a metatable`)
	local n = #v
	local count = 0
	for k, child in v do
		count += 1
		if n > 0 then
			assert(type(k) == "number" and k >= 1 and k <= n and k % 1 == 0, `{path}: an array with a stray key {tostring(k)}`)
		else
			assert(type(k) == "string", `{path}: a non-string key {tostring(k)}`)
		end
		assertPlain(child, `{path}.{tostring(k)}`)
	end
	assert(n == 0 or count == n, `{path}: an array with holes`)
end

local function json(v: any): any
	return serde.decode("json", serde.encode("json", v))
end

local function err(fn: () -> ()): string
	local ok, e = pcall(fn)
	assert(not ok, "expected an error")
	return tostring(e)
end

H.section("Key is the identity: a duplicate raises (and leaves nothing behind); Kind defaults to the Key", function()
	local m = Devui.WindowManager.new()
	local a = Devui.Window({ Title = "A", Key = "outline", Manager = m })
	local e = err(function()
		Devui.Window({ Title = "A again", Key = "outline", Manager = m })
	end)
	assert(string.find(e, 'Devui.Window: Key "outline" is already used', 1, true) ~= nil, e)
	assert(string.find(e, "spec.windowlayout", 1, true) ~= nil, `blames the calling line: {e}`)
	-- the failed window released its slot: the next one takes rank 2 (surface ZIndex 5), not 3
	local b = Devui.Window({ Title = "B", Key = "props", Kind = "inspector", Manager = m })
	assert((b :: any).ZIndex == 5, `rank after a failed window {(b :: any).ZIndex}`)
	local layout = m:ExportLayout()
	assert(layout.Windows.outline.Kind == "outline", "Kind defaults to the Key")
	assert(layout.Windows.props.Kind == "inspector", "an explicit Kind")
	-- two windows of one Kind: two Keys
	local c = Devui.Window({ Title = "Note 1", Key = "note-1", Kind = "notepad", Manager = m })
	local d = Devui.Window({ Title = "Note 2", Key = "note-2", Kind = "notepad", Manager = m })
	local l2 = m:ExportLayout()
	assert(l2.Windows["note-1"].Kind == "notepad" and l2.Windows["note-2"].Kind == "notepad")
	-- a key freed by its window going away can be taken again
	q.dispose(a)
	local a2 = Devui.Window({ Title = "A", Key = "outline", Manager = m })
	for _, w in { a2, b, c, d } do
		q.dispose(w)
	end
	assert(string.find(err(function()
		Devui.Window({ Title = "x", Key = 5 :: any, Manager = m })
	end), "Devui.Window: Key must be a string", 1, true) ~= nil)
	H.assertNoDebugOutput("key")
end)

H.section("ExportLayout: version + tree shape, JSON-ready values only, round-trips through JSON", function()
	local m = Devui.WindowManager.new()
	local pos = q.Source(UDim2.new(0.5, -40, 0, 20))
	local a = Devui.Window({ Title = "A", Key = "a", Manager = m, Position = pos, Size = q.Source(Vector2.new(320, 240)) })
	local b = Devui.Window({ Title = "B", Key = "b", Manager = m, Open = q.Source(false), Collapsed = q.Source(true) })
	local layout = m:ExportLayout()
	assertPlain(layout, "layout")
	assert(layout.Version == 1)
	assert(#layout.Floating == 2, "one floating group per window")
	local ga, gb = layout.Floating[1], layout.Floating[2]
	assert(ga.Node.Tabs[1] == "a" and #ga.Node.Tabs == 1 and ga.Node.Selected == "a", "registration order; a one-tab node")
	assert(ga.Position[1] == 0.5 and ga.Position[2] == -40 and ga.Position[3] == 0 and ga.Position[4] == 20, "UDim2 as 4 numbers")
	assert(ga.Size[1] == 320 and ga.Size[2] == 240 and ga.Collapsed == false)
	assert(gb.Collapsed == true and layout.Windows.b.Open == false and layout.Windows.a.Open == true)
	local back = json(layout)
	assert(back.Version == 1 and back.Windows.a.Kind == "a" and back.Floating[2].Node.Tabs[1] == "b", "JSON round trip")
	-- importing what came back from JSON changes nothing
	m:ImportLayout(back)
	assert(pos:Get() == UDim2.new(0.5, -40, 0, 20))
	-- the exported table is the caller's (a fresh copy every time)
	local mutable: any = layout
	mutable.Windows.a.Open = false
	assert(m:ExportLayout().Windows.a.Open == true)
	q.dispose(a)
	q.dispose(b)
	H.assertNoDebugOutput("export")
end)

H.section("ImportLayout before the window exists: pending, applied the moment it registers (initial state)", function()
	local m = Devui.WindowManager.new()
	m:ImportLayout({
		Version = 1,
		Windows = { tools = { Kind = "tools", Open = false } },
		Floating = { { Position = { 0, 300, 0, 120 }, Size = { 250, 180 }, Collapsed = true, Node = { Tabs = { "tools" }, Selected = "tools" } } },
	})
	local pos, size = q.Source(UDim2.fromOffset(1, 1)), q.Source(Vector2.new(10, 10))
	local open, collapsed = q.Source(true), q.Source(false)
	local w = Devui.Window({ Title = "Tools", Key = "tools", Manager = m, Position = pos, Size = size, Open = open, Collapsed = collapsed })
	assert(pos:Get() == UDim2.fromOffset(300, 120) and size:Get() == Vector2.new(250, 180), "the app's Sources were written")
	assert(open:Get() == false and collapsed:Get() == true)
	assert((w :: any).Visible == false, "built from the applied state")
	assert(m.Focused:Get() == 0, "applying at registration focuses nothing")
	q.dispose(w)
	H.assertNoDebugOutput("pending")
end)

H.section("ImportLayout with the window on screen moves it; a window the layout does not name stays", function()
	local m = Devui.WindowManager.new()
	local pa, pb, pc = q.Source(UDim2.fromOffset(0, 0)), q.Source(UDim2.fromOffset(50, 50)), q.Source(UDim2.fromOffset(70, 70))
	local sa = q.Source(Vector2.new(300, 200))
	local a = Devui.Window({ Title = "A", Key = "a", Manager = m, Position = pa, Size = sa })
	local b = Devui.Window({ Title = "B", Key = "b", Manager = m, Position = pb })
	local loose = Devui.Window({ Title = "loose", Manager = m, Position = pc }) -- no Key
	local saved = m:ExportLayout()
	pa:Set(UDim2.fromOffset(400, 10))
	sa:Set(Vector2.new(100, 100))
	pb:Set(UDim2.fromOffset(9, 9))
	-- a layout naming only "a"
	m:ImportLayout({ Version = 1, Windows = { a = saved.Windows.a }, Floating = { saved.Floating[1] } })
	assert(pa:Get() == UDim2.fromOffset(0, 0) and sa:Get() == Vector2.new(300, 200), "a moved back")
	assert(pb:Get() == UDim2.fromOffset(9, 9), "b (not in the layout) left as it was")
	assert(pc:Get() == UDim2.fromOffset(70, 70), "the key-less window left as it was")
	-- the export keeps b (after the layout's own keys)
	local after = m:ExportLayout()
	assert(after.Floating[1].Node.Tabs[1] == "a" and after.Floating[2].Node.Tabs[1] == "b" and #after.Floating == 2)
	q.dispose(a)
	q.dispose(b)
	q.dispose(loose)
	assert(#H.output() == 1, "the key-less window was noticed (once)")
	H.resetOutput()
end)

H.section("pending keys survive a round trip: an unknown key is exported again unchanged", function()
	local m = Devui.WindowManager.new()
	local a = Devui.Window({ Title = "A", Key = "a", Manager = m })
	local server: WindowLayout = {
		Version = 1,
		Windows = { a = { Kind = "a", Open = true }, server = { Kind = "serverProps", Open = true } },
		Floating = {
			{ Position = { 0, 5, 0, 5 }, Size = { 200, 100 }, Collapsed = false, Node = { Tabs = { "a" }, Selected = "a" } },
			{ Position = { 1, -310, 0, 40 }, Size = { 300, 400 }, Collapsed = false, Node = { Tabs = { "server" }, Selected = "server" } },
		},
	}
	m:ImportLayout(server)
	local out = m:ExportLayout()
	assert(out.Windows.server.Kind == "serverProps" and out.Floating[2].Position[1] == 1 and out.Floating[2].Size[2] == 400, "kept")
	assert((m:ExportWindow("server") :: WindowState).Open == true, "a pending key's state")
	-- a keyed window that goes away leaves its state pending: the layout does not change
	local before = m:ExportLayout()
	q.dispose(a)
	local afterGone = m:ExportLayout()
	assert(afterGone.Windows.a ~= nil and afterGone.Floating[1].Position[2] == 5, "a destroyed window keeps its place")
	-- (same content as before)
	assert(serde.encode("json", afterGone) == serde.encode("json", before))
	assert(m:ExportWindow("nope") == nil, "an unknown key")
	H.assertNoDebugOutput("pending kept")
end)

H.section("factories: by Kind, called with the key, only for keys open when saved and not registered", function()
	local m = Devui.WindowManager.new()
	local made: { string } = {}
	local wins: { any } = {}
	local factories = {
		notepad = function(key: string)
			table.insert(made, key)
			table.insert(wins, Devui.Window({ Title = key, Key = key, Kind = "notepad", Manager = m }))
		end,
		outline = function(key: string)
			table.insert(made, key)
		end,
	}
	local live = Devui.Window({ Title = "outline", Key = "outline", Manager = m })
	local function group(key: string, x: number)
		return { Position = { 0, x, 0, 0 }, Size = { 200, 100 }, Collapsed = false, Node = { Tabs = { key }, Selected = key } }
	end
	m:ImportLayout({
		Version = 1,
		Windows = {
			["note-1"] = { Kind = "notepad", Open = true },
			["note-2"] = { Kind = "notepad", Open = true },
			["note-3"] = { Kind = "notepad", Open = false }, -- closed when saved: not made
			outline = { Kind = "outline", Open = true }, -- registered already: not made
			ghost = { Kind = "unknownKind", Open = true }, -- no factory: stays pending
		},
		Floating = { group("note-1", 10), group("note-2", 20), group("note-3", 30), group("outline", 40), group("ghost", 50) },
	}, factories)
	assert(#made == 2 and made[1] == "note-1" and made[2] == "note-2", `factory calls {table.concat(made, ",")}`)
	assert((wins[1] :: any).Position == UDim2.fromOffset(10, 19) and (wins[2] :: any).Position == UDim2.fromOffset(20, 19),
		"a window made by the factory took its pending state at registration")
	local out = m:ExportLayout()
	assert(out.Windows.ghost.Kind == "unknownKind" and out.Windows["note-3"].Open == false, "the others stay pending")
	-- a second import does not call the factory for registered keys
	table.clear(made)
	m:ImportLayout(out, factories)
	assert(#made == 0, "every open key is registered now")
	assert(string.find(err(function()
		m:ImportLayout(out, { unknownKind = 5 :: any })
	end), "factories must map a Kind string to a function(key), got [string] = number", 1, true) ~= nil)
	-- a bad entry fails even when this layout would never call it (every key is registered or closed here)
	assert(string.find(err(function()
		m:ImportLayout(out, { Notepad = function(_key: string) end, nothingSaved = true :: any })
	end), "got [string] = boolean", 1, true) ~= nil)
	assert(string.find(err(function()
		m:ExportWindow(5 :: any)
	end), "Devui.WindowManager:ExportWindow: key must be a string", 1, true) ~= nil)
	for _, w in wins do
		q.dispose(w)
	end
	q.dispose(live)
	H.assertNoDebugOutput("factories")
end)

H.section("the Layout output: emitted when the layout changes (a raise reorders it), not on a no-op import", function()
	local m = Devui.WindowManager.new()
	local seen: { WindowLayout } = {}
	local obs = m.Layout:Observer(function(self)
		table.insert(seen, self:Get())
	end)
	obs:Subscribe()
	local base = #seen
	local pos = q.Source(UDim2.fromOffset(0, 0))
	local oa = q.Source(true)
	local a = Devui.Window({ Title = "A", Key = "a", Manager = m, Position = pos, Open = oa })
	local b = Devui.Window({ Title = "B", Key = "b", Manager = m })
	assert(#seen == base + 2, `one emission per registered keyed window ({#seen - base})`)
	assert(#m.Layout:Get().Floating == 2 and table.isfrozen(m.Layout:Get()), "a frozen value")
	pos:Set(UDim2.fromOffset(5, 5))
	assert(#seen == base + 3 and seen[#seen].Floating[1].Position[2] == 5, "a move")
	pos:Set(UDim2.fromOffset(5, 5)) -- same value (Set re-emits the Source): no new layout
	assert(#seen == base + 3)
	oa:Set(true) -- raises and focuses A: the stacking is part of the layout (the focus is not)
	assert(m.Focused:Get() ~= 0 and #seen == base + 4, "a raise reorders the layout")
	assert(seen[#seen].Floating[2].Node.Tabs[1] == "a", "A on top now")
	oa:Set(true) -- already on top and focused
	assert(#seen == base + 4, "raising the top window again changes nothing")
	local loose = Devui.Window({ Title = "loose", Manager = m })
	assert(#seen == base + 4, "a key-less window changes nothing")
	-- an import that moves two windows emits once
	local l = m:ExportLayout()
	l.Floating[1].Position[2] = 100
	l.Floating[2].Position[2] = 200
	m:ImportLayout(l)
	assert(#seen == base + 5, `one emission per import ({#seen - base})`)
	m:ImportLayout(l)
	assert(#seen == base + 5, "a no-op import emits nothing")
	q.dispose(a)
	assert(#seen == base + 5, "a destroyed keyed window leaves the layout as it was")
	obs:Unsubscribe()
	q.dispose(b)
	q.dispose(loose)
	assert(#H.output() == 1, "the key-less window was noticed (once)")
	H.resetOutput()
end)

-- the surface ZIndex of each window, bottom first, as names
local function stack(wins: { [string]: any }): string
	local names: { string } = {}
	for name in wins do
		table.insert(names, name)
	end
	table.sort(names, function(x, y)
		return wins[x].ZIndex < wins[y].ZIndex
	end)
	return table.concat(names, ",")
end

local function tabsOf(layout: WindowLayout): string
	local out: { string } = {}
	for _, g in layout.Floating do
		table.insert(out, g.Node.Tabs[1])
	end
	return table.concat(out, ",")
end

H.section("stacking: exported bottom first, a raise moves the key up, windows built after an import stack as saved", function()
	local m = Devui.WindowManager.new()
	local a = Devui.Window({ Title = "A", Key = "a", Manager = m })
	local b = Devui.Window({ Title = "B", Key = "b", Manager = m })
	local c = Devui.Window({ Title = "C", Key = "c", Manager = m })
	assert(tabsOf(m:ExportLayout()) == "a,b,c", "registration order = stacking order")
	-- rebuilt with a Focused Source (setting it true raises the window, as a press does)
	local focusedA = q.Source(false)
	q.dispose(a)
	a = Devui.Window({ Title = "A", Key = "a", Manager = m, Focused = focusedA })
	assert(tabsOf(m:ExportLayout()) == "a,b,c", "a destroyed and rebuilt window takes its saved place back")
	assert(stack({ a = a, b = b, c = c }) == "a,b,c", stack({ a = a, b = b, c = c }))
	focusedA:Set(true)
	assert(tabsOf(m:ExportLayout()) == "b,c,a", tabsOf(m:ExportLayout()))
	local saved = m:ExportLayout()
	for _, w in { a, b, c } do
		q.dispose(w)
	end
	-- a fresh manager: import first, then build the windows in another order
	local m2 = Devui.WindowManager.new()
	m2:ImportLayout(json(saved))
	local loose = Devui.Window({ Title = "loose", Manager = m2 })
	local a2 = Devui.Window({ Title = "A", Key = "a", Manager = m2 })
	local c2 = Devui.Window({ Title = "C", Key = "c", Manager = m2 })
	local b2 = Devui.Window({ Title = "B", Key = "b", Manager = m2 })
	assert(stack({ a = a2, b = b2, c = c2 }) == "b,c,a", stack({ a = a2, b = b2, c = c2 }))
	assert((loose :: any).ZIndex < (b2 :: any).ZIndex, "the key-less window kept its slot (the bottom)")
	assert(m2.Focused:Get() == 0, "the stacking moves no focus")
	-- an import on screen restacks the windows it names; an unnamed key rides with the named key below it
	local d2 = Devui.Window({ Title = "D", Key = "d", Manager = m2 }) -- on top: b,c,a,d
	m2:ImportLayout({
		Version = 1,
		Windows = { a = saved.Windows.a, b = saved.Windows.b },
		Floating = { saved.Floating[3], saved.Floating[1] }, -- a below b
	})
	assert(tabsOf(m2:ExportLayout()) == "a,d,b,c", tabsOf(m2:ExportLayout())) -- c rode with b, d with a
	assert(stack({ a = a2, b = b2, c = c2, d = d2 }) == "a,d,b,c", stack({ a = a2, b = b2, c = c2, d = d2 }))
	for _, w in { a2, b2, c2, d2, loose } do
		q.dispose(w)
	end
	H.resetOutput()
end)

H.section("ForgetWindow: a pending key goes at once, a live one when its window goes away", function()
	local m = Devui.WindowManager.new()
	local seen = 0
	local obs = m.Layout:Observer(function()
		seen += 1
	end)
	obs:Subscribe()
	m:ImportWindow("ghost", { Kind = "ghost", Open = true, Collapsed = false, Position = { 0, 1, 0, 1 }, Size = { 50, 50 } })
	local before = seen
	m:ForgetWindow("ghost")
	assert(m:ExportWindow("ghost") == nil and m:ExportLayout().Windows.ghost == nil and seen == before + 1, "pending: gone")
	m:ForgetWindow("ghost") -- unknown now: a no-op
	m:ForgetWindow("never")
	assert(seen == before + 1)
	-- live: forget, then destroy (a File > Exit item) — the same as destroy, then forget
	local open = q.Source(true)
	local w = Devui.Window({ Title = "W", Key = "w", Manager = m, Open = open, Position = q.Source(UDim2.fromOffset(40, 40)) })
	m:ForgetWindow("w")
	assert(m:ExportLayout().Windows.w ~= nil, "a live window stays in the layout while it is on screen")
	q.dispose(w)
	assert(m:ExportLayout().Windows.w == nil, "dropped when it went away")
	local pos = q.Source(UDim2.fromOffset(0, 0))
	local w2 = Devui.Window({ Title = "W", Key = "w", Manager = m, Position = pos })
	assert(pos:Get() == UDim2.fromOffset(0, 0), "a window built again with that key starts fresh")
	q.dispose(w2)
	m:ForgetWindow("w")
	assert(m:ExportLayout().Windows.w == nil, "destroy, then forget")
	-- importing the key again before the window goes away cancels the forget
	local w3 = Devui.Window({ Title = "W", Key = "w", Manager = m })
	m:ForgetWindow("w")
	m:ImportWindow("w", m:ExportWindow("w") :: WindowState)
	q.dispose(w3)
	assert(m:ExportLayout().Windows.w ~= nil, "imported again: kept pending")
	obs:Unsubscribe()
	assert(string.find(err(function()
		m:ForgetWindow(5 :: any)
	end), "Devui.WindowManager:ForgetWindow: key must be a string", 1, true) ~= nil)
	H.assertNoDebugOutput("forget")
end)

H.section("ExportWindow / ImportWindow: one window's state, live or pending", function()
	local m = Devui.WindowManager.new()
	local pos, open = q.Source(UDim2.fromOffset(30, 40)), q.Source(true)
	local w = Devui.Window({ Title = "W", Key = "w", Kind = "inspector", Manager = m, Position = pos, Open = open })
	local s = m:ExportWindow("w") :: WindowState
	assertPlain(s, "state")
	assert(s.Kind == "inspector" and s.Open == true and s.Collapsed == false)
	local sp, ss = s.Position :: { number }, s.Size :: { number } -- (always filled for a live window)
	assert(sp[2] == 30 and sp[4] == 40 and ss[1] == 300 and ss[2] == 200 and s.Dock == nil and s.DockWidth == nil)
	pos:Set(UDim2.fromOffset(0, 0))
	m:ImportWindow("w", json(s))
	assert(pos:Get() == UDim2.fromOffset(30, 40), "live: moved back")
	-- not registered yet: pending, applied at registration, and part of the layout meanwhile
	m:ImportWindow("later", { Kind = "later", Open = true, Collapsed = false, Position = { 0, 7, 0, 8 }, Size = { 90, 80 } })
	assert(m:ExportLayout().Windows.later ~= nil)
	local lp = q.Source(UDim2.new())
	local later = Devui.Window({ Title = "L", Key = "later", Manager = m, Position = lp })
	assert(lp:Get() == UDim2.fromOffset(7, 8))
	assert(string.find(err(function()
		m:ImportWindow("w", { Kind = "w", Open = true, Collapsed = false, Position = { 1, 2 }, Size = { 1, 2 } } :: any)
	end), "Devui.WindowManager:ImportWindow: state.Position must be an array of 4 numbers", 1, true) ~= nil)
	q.dispose(w)
	q.dispose(later)
	H.assertNoDebugOutput("window round trip")
end)

H.section("a bad layout raises: unknown version, a split / tab group, a window without a place", function()
	local m = Devui.WindowManager.new()
	local e = err(function()
		m:ImportLayout({ Version = 2, Windows = {}, Floating = {} } :: any)
	end)
	assert(string.find(e, "Devui.WindowManager:ImportLayout: unknown layout Version 2", 1, true) ~= nil, e)
	assert(string.find(e, "spec.windowlayout", 1, true) ~= nil, `blames the calling line: {e}`)
	assert(string.find(err(function()
		m:ImportLayout({
			Version = 1,
			Windows = { a = { Kind = "a", Open = true }, b = { Kind = "b", Open = true } },
			Floating = { { Position = { 0, 0, 0, 0 }, Size = { 1, 1 }, Collapsed = false, Node = { Tabs = { "a", "b" }, Selected = "a" } } },
		} :: any)
	end), "tab groups and splits are not supported", 1, true) ~= nil)
	assert(string.find(err(function()
		m:ImportLayout({ Version = 1, Windows = { a = { Kind = "a", Open = true } }, Floating = {} } :: any)
	end), 'layout.Windows["a"] has no place', 1, true) ~= nil)
	assert(string.find(err(function()
		m:ImportLayout(nil :: any)
	end), "layout must be a WindowLayout table", 1, true) ~= nil)
	local function one(key: string, patch: { [string]: any }?): any
		local g: { [string]: any } = { Position = { 0, 0, 0, 0 }, Size = { 1, 1 }, Collapsed = false, Node = { Tabs = { key }, Selected = key } }
		for k, v in patch or {} do
			g[k] = v
		end
		return g
	end
	local function bad(layout: any, expect: string)
		local e2 = err(function()
			m:ImportLayout(layout)
		end)
		assert(string.find(e2, expect, 1, true) ~= nil, `{expect}: {e2}`)
	end
	local wa = { a = { Kind = "a", Open = true } }
	bad({ Version = 1, Windows = wa, Floating = { one("a"), one("a") } }, 'window "a" is placed twice')
	bad({ Version = 1, Windows = {}, Floating = { one("a") } }, 'layout.Windows["a"] must be')
	bad({ Version = 1, Windows = wa, Floating = { one("a", { Collapsed = "no" }) } }, "Collapsed must be a boolean")
	bad({ Version = 1, Windows = wa, Floating = { one("a", { Position = { 0, 0 / 0, 0, 0 } }) } }, "Position must be an array of 4 numbers")
	bad({ Version = 1, Windows = wa, Floating = { one("a", { Size = { 1, 1, extra = 1 } }) } }, "Size must be an array of 2 numbers")
	bad({ Version = 1, Windows = wa, Floating = { one("a", { Node = { Tabs = { "a" }, Selected = "b" } }) } }, "Selected the same key")
	bad({ Version = 1, Windows = wa, Floating = { one("a", { Node = { Split = "Horizontal" } }) } }, "must be a tab set")
	bad({ Version = 1, Windows = wa, Floating = { one("a", { Node = { Tabs = { "a" }, Selected = "a", Split = "Horizontal" } }) } }, "tab groups and splits are not supported")
	bad({ Version = 1, Windows = { a = { Kind = 5, Open = true } }, Floating = { one("a") } }, 'layout.Windows["a"] must be')
	assert(string.find(err(function()
		m:ImportWindow("a", { Kind = 5, Open = true, Collapsed = false, Position = { 0, 0, 0, 0 }, Size = { 1, 1 } } :: any)
	end), "state.Kind must be a string", 1, true) ~= nil)
	assert(string.find(err(function()
		m:ImportWindow("a", { Kind = "a", Open = 1, Collapsed = false, Position = { 0, 0, 0, 0 }, Size = { 1, 1 } } :: any)
	end), "state.Open and state.Collapsed must be booleans", 1, true) ~= nil)
	H.assertNoDebugOutput("bad layout")
end)

H.section("q.debug: one notice per manager about key-less windows, only once the layout API is used", function()
	local m = Devui.WindowManager.new()
	local a = Devui.Window({ Title = "plain", Manager = m })
	H.assertNoDebugOutput("no layout use yet")
	m:ExportLayout()
	local out = H.output()
	assert(#out == 1 and string.find(out[1], 'a window without Key ("plain")', 1, true) ~= nil, table.concat(out, "\n"))
	m:ExportLayout()
	local b = Devui.Window({ Title = "plain 2", Manager = m })
	assert(#H.output() == 1, "once per manager")
	q.dispose(a)
	q.dispose(b)
	H.resetOutput()
end)

-- ── edge docking (docking stage 2): Left / Right, WindowState.Dock / DockWidth ──────────────────────────────────────

local function dockGroup(key: string, width: number, patch: { [string]: any }?): any
	local g: { [string]: any } = { Width = width, Collapsed = false, Node = { Tabs = { key }, Selected = key }, Position = { 0, 40, 0, 50 }, Size = { 260, 180 } }
	for k, v in patch or {} do
		g[k] = v
	end
	return g
end
local function floatGroup(key: string, x: number): any
	return { Position = { 0, x, 0, 0 }, Size = { 200, 100 }, Collapsed = false, Node = { Tabs = { key }, Selected = key } }
end

H.section("Left / Right: written with the floating rectangle, read back (JSON round trip), a pending key docks at registration", function()
	local m = Devui.WindowManager.new()
	m:ImportLayout({
		Version = 1,
		Windows = { explorer = { Kind = "explorer", Open = true }, props = { Kind = "props", Open = true }, out = { Kind = "out", Open = true } },
		Floating = { floatGroup("out", 300) },
		Left = dockGroup("explorer", 280),
		Right = dockGroup("props", 220, { Collapsed = true }),
	})
	local pos, size = q.Source(UDim2.new()), q.Source(Vector2.new(1, 1))
	local explorer = Devui.Window({ Title = "Explorer", Key = "explorer", Manager = m, Position = pos, Size = size })
	local props = Devui.Window({ Title = "Props", Key = "props", Manager = m })
	local out = Devui.Window({ Title = "Out", Key = "out", Manager = m })
	local st = m:ExportWindow("explorer") :: WindowState
	assert(st.Dock == "Left" and st.DockWidth == 280, "docked at registration")
	assert(pos:Get() == UDim2.fromOffset(40, 50) and size:Get() == Vector2.new(260, 180), "its floating rectangle written into the Sources")
	assert((m:ExportWindow("props") :: WindowState).Dock == "Right" and (m:ExportWindow("props") :: WindowState).Collapsed == true)
	local layout = m:ExportLayout()
	assertPlain(layout, "layout")
	local left, right = layout.Left :: any, layout.Right :: any
	assert(left.Width == 280 and left.Node.Tabs[1] == "explorer" and left.Position[2] == 40 and left.Size[1] == 260)
	assert(right.Width == 220 and right.Collapsed == true and right.Node.Selected == "props")
	assert(#layout.Floating == 1 and layout.Floating[1].Node.Tabs[1] == "out", "Floating holds only the floating key")
	assert(layout.Windows.explorer.Open == true and layout.Windows.props.Kind == "props", "Windows lists the docked keys too")
	local back = json(layout)
	assert(back.Left.Width == 280 and back.Right.Node.Tabs[1] == "props", "JSON round trip")
	m:ImportLayout(back)
	assert(serde.encode("json", m:ExportLayout()) == serde.encode("json", layout), "importing it back changes nothing")
	for _, w in { explorer, props, out } do
		q.dispose(w)
	end
	H.assertNoDebugOutput("dock layout")
end)

H.section("an edge group without Position / Size (an older save) is read: the window keeps its Sources' rectangle", function()
	local m = Devui.WindowManager.new()
	local layout: any = {
		Version = 1,
		Windows = { explorer = { Kind = "explorer", Open = true } },
		Floating = {},
		Left = { Width = 280, Collapsed = false, Node = { Tabs = { "explorer" }, Selected = "explorer" } },
	}
	m:ImportLayout(layout)
	local waiting = m:ExportWindow("explorer") :: WindowState
	assert(waiting.Position == nil and waiting.Size == nil and waiting.Dock == "Left", "a pending state without a rectangle")
	assert(m:ExportLayout().Left ~= nil and (m:ExportLayout().Left :: any).Position == nil, "exported again as it came")
	local pos, size = q.Source(UDim2.fromOffset(7, 8)), q.Source(Vector2.new(90, 80))
	local w = Devui.Window({ Title = "E", Key = "explorer", Manager = m, Position = pos, Size = size })
	assert(pos:Get() == UDim2.fromOffset(7, 8) and size:Get() == Vector2.new(90, 80), "nil Position / Size: the Sources are left alone")
	local live = m:ExportWindow("explorer") :: WindowState
	assert((live.Position :: { number })[2] == 7 and (live.Size :: { number })[1] == 90, "a live window's state always has them")
	assert(((m:ExportLayout().Left :: any).Position :: { number })[4] == 8, "and the edge group too, once live")
	-- ImportWindow without a rectangle, live: only the other facts change
	m:ImportWindow("explorer", { Kind = "explorer", Open = true, Collapsed = true, Dock = "Left", DockWidth = 300 })
	assert(pos:Get() == UDim2.fromOffset(7, 8) and (m:ExportWindow("explorer") :: WindowState).DockWidth == 300)
	q.dispose(w)
	H.assertNoDebugOutput("old save")
end)

H.section("stacking after a load: the docked windows start under the floating ones (their order is not saved)", function()
	local m = Devui.WindowManager.new()
	local a = Devui.Window({ Title = "A", Key = "a", Manager = m })
	local b = Devui.Window({ Title = "B", Key = "b", Manager = m })
	local d = Devui.Window({ Title = "D", Key = "d", Manager = m }) -- built last: on top
	m:ImportLayout({
		Version = 1,
		Windows = { a = { Kind = "a", Open = true }, b = { Kind = "b", Open = true }, d = { Kind = "d", Open = true } },
		Floating = { floatGroup("a", 0), floatGroup("b", 10) },
		Left = dockGroup("d", 250),
	})
	assert(stack({ a = a, b = b, d = d }) == "d,a,b", stack({ a = a, b = b, d = d }))
	-- raising the docked window at run time puts it on top; the saved Floating order is the floating keys only
	m:ImportWindow("d", m:ExportWindow("d") :: WindowState)
	local focusD = q.Source(false)
	q.dispose(d)
	d = Devui.Window({ Title = "D", Key = "d", Manager = m, Focused = focusD })
	focusD:Set(true)
	assert(stack({ a = a, b = b, d = d }) == "a,b,d", "raised like any window")
	assert(tabsOf(m:ExportLayout()) == "a,b" and (m:ExportLayout().Left :: any).Node.Tabs[1] == "d")
	-- built after an import in another order: the same
	local saved = m:ExportLayout()
	for _, w in { a, b, d } do
		q.dispose(w)
	end
	local m2 = Devui.WindowManager.new()
	m2:ImportLayout(json(saved))
	local b2 = Devui.Window({ Title = "B", Key = "b", Manager = m2 })
	local a2 = Devui.Window({ Title = "A", Key = "a", Manager = m2 })
	local d2 = Devui.Window({ Title = "D", Key = "d", Manager = m2 })
	assert(stack({ a = a2, b = b2, d = d2 }) == "d,a,b", stack({ a = a2, b = b2, d = d2 }))
	for _, w in { a2, b2, d2 } do
		q.dispose(w)
	end
	H.assertNoDebugOutput("dock stacking")
end)

H.section("one window per edge: a pending docked key finds its edge held -> floats; a closed docked window behind an open one is saved floating", function()
	local m = Devui.WindowManager.new()
	local holder = Devui.Window({ Title = "H", Key = "holder", Manager = m })
	m:ImportWindow("holder", { Kind = "holder", Open = true, Collapsed = false, Dock = "Left", DockWidth = 200 })
	m:ImportWindow("late", { Kind = "late", Open = true, Collapsed = false, Dock = "Left", DockWidth = 300, Position = { 0, 70, 0, 80 }, Size = { 150, 100 } })
	local lp = q.Source(UDim2.new())
	local late = Devui.Window({ Title = "L", Key = "late", Manager = m, Position = lp })
	assert((m:ExportWindow("late") :: WindowState).Dock == nil and lp:Get() == UDim2.fromOffset(70, 80), "the edge is held: it starts floating")
	q.dispose(late)
	-- a closed window remembering the edge while another one holds it: saved floating
	local co = q.Source(false)
	local closed = Devui.Window({ Title = "C", Key = "closed", Manager = m, Open = co })
	m:ImportWindow("closed", { Kind = "closed", Open = false, Collapsed = false, Dock = "Left", DockWidth = 120 })
	assert((m:ExportWindow("closed") :: WindowState).Dock == "Left", "a closed window keeps the edge remembered")
	local layout = m:ExportLayout()
	assert((layout.Left :: any).Node.Tabs[1] == "holder", "the open one holds the edge")
	local floating: { string } = {}
	for _, g in layout.Floating do
		table.insert(floating, g.Node.Tabs[1])
	end
	table.sort(floating)
	assert(table.concat(floating, ",") == "closed,late", table.concat(floating, ","))
	-- the saved layout reads back (no key placed twice)
	m:ImportLayout(json(layout))
	q.dispose(holder)
	q.dispose(closed)
	H.assertNoDebugOutput("one per edge")
end)

H.section("bad edge groups and dock states raise", function()
	local m = Devui.WindowManager.new()
	local function bad(layout: any, expect: string)
		local e2 = err(function()
			m:ImportLayout(layout)
		end)
		assert(string.find(e2, expect, 1, true) ~= nil, `{expect}: {e2}`)
	end
	local wa = { a = { Kind = "a", Open = true } }
	local wab = { a = { Kind = "a", Open = true }, b = { Kind = "b", Open = true } }
	bad({ Version = 1, Windows = wa, Floating = {}, Left = 5 }, "layout.Left must be { Width = number")
	bad({ Version = 1, Windows = wa, Floating = {}, Left = dockGroup("a", 0) }, "layout.Left.Width must be a positive number")
	bad({ Version = 1, Windows = wa, Floating = {}, Right = dockGroup("a", 0 / 0) }, "layout.Right.Width must be a positive number")
	bad({ Version = 1, Windows = wa, Floating = {}, Left = dockGroup("a", 200, { Collapsed = 1 }) }, "layout.Left.Collapsed must be a boolean")
	bad({ Version = 1, Windows = wab, Floating = {}, Left = dockGroup("a", 200, { Node = { Tabs = { "a", "b" }, Selected = "a" } }) }, "tab groups and splits are not supported")
	bad({ Version = 1, Windows = wa, Floating = {}, Left = dockGroup("a", 200, { Position = { 0, 0 } }) }, "layout.Left.Position must be an array of 4 numbers")
	bad({ Version = 1, Windows = wa, Floating = {}, Left = dockGroup("a", 200, { Size = { 1 } }) }, "layout.Left.Size must be an array of 2 numbers")
	bad({ Version = 1, Windows = wa, Floating = { floatGroup("a", 0) }, Left = dockGroup("a", 200) }, 'window "a" is placed twice in the layout (layout.Left and layout.Floating[1])')
	bad({ Version = 1, Windows = wa, Floating = {}, Left = dockGroup("a", 200), Right = dockGroup("a", 200) }, 'window "a" is placed twice in the layout (layout.Left and layout.Right)')
	bad({ Version = 1, Windows = {}, Floating = {}, Left = dockGroup("a", 200) }, 'layout.Windows["a"] must be')
	bad({ Version = 1, Windows = wab, Floating = {}, Left = dockGroup("a", 200) }, 'layout.Windows["b"] has no place in layout.Floating, layout.Left or layout.Right')
	local function badState(state: any, expect: string)
		local e2 = err(function()
			m:ImportWindow("a", state)
		end)
		assert(string.find(e2, "Devui.WindowManager:ImportWindow: " .. expect, 1, true) ~= nil, `{expect}: {e2}`)
	end
	local base = { Kind = "a", Open = true, Collapsed = false }
	local function with(patch: { [string]: any }): any
		local t = table.clone(base) :: { [string]: any }
		for k, v in patch do
			t[k] = v
		end
		return t
	end
	badState(with({ Dock = "Up", DockWidth = 100 }), 'state.Dock must be "Left", "Right" or nil, got Up')
	badState(with({ Dock = "Left" }), "state.DockWidth must be a positive number")
	badState(with({ Dock = "Left", DockWidth = -3 }), "state.DockWidth must be a positive number")
	badState(with({ DockWidth = 100 }), "state.DockWidth must be nil when state.Dock is nil")
	badState(with({ Position = { 0, 0, 0 } }), "state.Position must be an array of 4 numbers")
	-- nil Position / Size is fine
	m:ImportWindow("a", with({}))
	assert((m:ExportWindow("a") :: WindowState).Position == nil)
	H.assertNoDebugOutput("bad dock")
end)

H.done()
