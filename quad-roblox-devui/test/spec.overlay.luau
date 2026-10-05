--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Overlay = require("../src/Overlay")
Overlay.warnUnmounted = false -- these specs open popups on a bare layer (no ScreenGui); the debug line has its own spec in spec.overlay

H.section("layer: full-screen, transparent, not Active, high ZIndex", function()
	local o = Overlay.new()
	local layer = o.Layer
	assert(layer.Size == UDim2.fromScale(1, 1) and layer.BackgroundTransparency == 1)
	assert(layer.Active == false and layer.ZIndex == 1000)
	assert(Overlay.new({ ZIndex = 5 }).Layer.ZIndex == 5)
	assert(Overlay.getDefault().Layer.Name == "OverlayLayer" and Overlay.getDefault().Alive:Get())
	assert(o.Count:Get() == 0)
	q.dispose(layer)
end)

H.section("open anchors content, click-outside closes, destroys content", function()
	local o = Overlay.new()
	H.setAbs(o.Layer, 10, 20, 800, 600) -- the layer sits under an inset
	local closed = 0
	local content = D.Frame({ Name = "Menu", Size = UDim2.fromOffset(100, 80) })
	local popup = o:Open({
		Content = content,
		Position = Vector2.new(110, 220),
		Anchor = Vector2.new(1, 0),
		OnClose = function()
			closed += 1
		end,
	})
	local holder = popup.Holder
	assert(holder.Position == UDim2.fromOffset(100, 200), "converted into layer space")
	assert(holder.AnchorPoint == Vector2.new(1, 0) and holder.AutomaticSize == Enum.AutomaticSize.XY)
	assert(content.Parent == holder and popup.IsOpen:Get() == true and o.Count:Get() == 1)
	local catcher = H.find(o.Layer, "Catcher")
	assert(catcher ~= nil and (catcher :: any).Size == UDim2.fromScale(1, 1) and (catcher :: any).BackgroundTransparency == 1)

	H.fire(catcher, "Activated", H.input({}), 1)
	assert(popup.IsOpen:Get() == false and closed == 1 and o.Count:Get() == 0)
	assert(H.isDestroyed(content) and H.find(o.Layer, "Popup") == nil, "entry and content are gone")
	popup:Close() -- idempotent
	assert(closed == 1)
	H.assertNoDebugOutput("open/close")
	q.dispose(o.Layer)
end)

H.section("tooltip-style popup has no catcher; later popups draw above; CloseAll", function()
	local o = Overlay.new()
	local tip = o:Open({ Content = D.TextLabel({ Text = "tip" }), Position = Vector2.new(0, 0), CloseOnClickOutside = false })
	assert(H.find(o.Layer, "Catcher") == nil)
	local menu = o:Open({ Content = D.Frame({}), Position = Vector2.new(5, 5) })
	local m2 = o:Open({ Content = D.Frame({}), Position = Vector2.new(6, 6) })
	assert(o.Count:Get() == 3)
	local entries = o.Layer:GetChildren()
	assert(#entries == 3 and tip.Holder.Parent == entries[1] and m2.Holder.Parent == entries[3], "open order = draw order")

	menu:Close()
	assert(o.Count:Get() == 2 and menu.IsOpen:Get() == false and tip.IsOpen:Get() and m2.IsOpen:Get())
	local order: { string } = {}
	o:Open({
		Content = D.Frame({}),
		Position = Vector2.new(0, 0),
		OnClose = function()
			table.insert(order, "third")
		end,
	})
	o:CloseAll()
	assert(o.Count:Get() == 0 and not tip.IsOpen:Get() and not m2.IsOpen:Get() and order[1] == "third")
	assert(#o.Layer:GetChildren() == 0)
	H.assertNoDebugOutput("tooltip/closeall")
	q.dispose(o.Layer)
end)

H.section("a popup can close itself from inside its content's click handler", function()
	local o = Overlay.new()
	local popup: any
	local item = D.TextButton({
		Text = "choose",
		Activated = function()
			popup:Close()
		end,
	})
	popup = o:Open({ Content = D.Frame({ item }), Position = Vector2.new(0, 0) })
	H.fire(item, "Activated", H.input({}), 1)
	assert(not popup.IsOpen:Get() and o.Count:Get() == 0 and H.isDestroyed(item))
	H.assertNoDebugOutput("self close")
	q.dispose(o.Layer)
end)

H.section("destroying the layer: Close is safe, Open raises", function()
	local o = Overlay.new()
	local closed = 0
	local popup = o:Open({
		Content = D.Frame({}),
		Position = Vector2.new(0, 0),
		OnClose = function()
			closed += 1
		end,
	})
	q.dispose(o.Layer)
	popup:Close()
	assert(not popup.IsOpen:Get() and closed == 1)
	local ok, err = pcall(function()
		o:Open({ Content = D.Frame({}), Position = Vector2.new(0, 0) })
	end)
	assert(not ok and string.find(tostring(err), "destroyed", 1, true))
	H.assertNoDebugOutput("layer dispose")
end)

H.section("default overlay: lazy, recreated after its layer dies; rebuilding a ScreenGui never re-parents a dead layer", function()
	local d1 = Overlay.getDefault()
	assert(Overlay.getDefault() == d1 and d1.Alive:Get(), "the same live default is handed out")
	local gui1 = D.ScreenGui({ d1.Layer })
	q.dispose(gui1)
	assert(not d1.Alive:Get())
	local d2 = Overlay.getDefault()
	assert(d2 ~= d1 and d2.Alive:Get() and d2.Layer ~= d1.Layer, "a fresh default after the old layer died")
	local gui2 = D.ScreenGui({ Overlay.getDefault().Layer }) -- would be Quad0219 with the dead layer
	local p = d2:Open({ Content = D.Frame({}), Position = Vector2.new(0, 0) })
	assert(d2.Count:Get() == 1 and p.IsOpen:Get())
	q.dispose(gui2)
	assert(d2.Count:Get() == 0 and not p.IsOpen:Get() and Overlay.getDefault() ~= d2)
	q.dispose(Overlay.getDefault().Layer)
	H.assertNoDebugOutput("default recreate")
end)

H.section("the layer dying closes every open popup: OnClose once each (newest first), Count 0, Alive false, no Slot ops", function()
	local o = Overlay.new()
	local gui = D.ScreenGui({ o.Layer })
	local log: { string } = {}
	local p1 = o:Open({
		Content = D.Frame({}),
		Position = Vector2.new(0, 0),
		OnClose = function()
			table.insert(log, "1")
		end,
	})
	local p2 = o:Open({
		Content = D.Frame({}),
		Position = Vector2.new(0, 0),
		CloseOnClickOutside = false,
		OnClose = function()
			table.insert(log, "2")
		end,
	})
	assert(o.Count:Get() == 2 and o.Alive:Get())
	q.dispose(gui)
	assert(not o.Alive:Get() and o.Count:Get() == 0)
	assert(not p1.IsOpen:Get() and not p2.IsOpen:Get())
	assert(table.concat(log, ",") == "2,1", table.concat(log, ","))
	p1:Close()
	p2:Close()
	o:CloseAll()
	assert(#log == 2, "closing again runs nothing")
	H.assertNoDebugOutput("layer death")
end)

H.section("debug line when the layer is not mounted; a detached entry closes without Slot ops", function()
	Overlay.warnUnmounted = true
	H.resetOutput()
	local o = Overlay.new()
	local bare = o:Open({ Content = D.Frame({}), Position = Vector2.new(0, 0) })
	local out = H.output()
	assert(#out == 1 and string.find(out[1], "not mounted", 1, true) ~= nil, "one debug line for an unmounted layer")
	bare:Close()
	H.resetOutput()
	local gui = D.ScreenGui({ o.Layer })
	local mounted = o:Open({ Content = D.Frame({}), Position = Vector2.new(0, 0) })
	assert(#H.output() == 0, "no line once the layer is in a ScreenGui")
	-- the entry is already detached when the close path runs (Deferred ordering): no Slot op, no error, bookkeeping done
	local entry = (mounted.Holder :: any).Parent
	entry.Parent = nil
	mounted:Close()
	assert(not mounted.IsOpen:Get() and o.Count:Get() == 0)
	q.dispose(gui)
	Overlay.warnUnmounted = false
	H.resetOutput()
end)

H.section("R2-1 getDefault() detects layer death synchronously (Deferred Destroying: Parent is nil, handlers have not run yet)", function()
	local first = Overlay.getDefault()
	local screen = D.Frame({ first.Layer })
	local closed = 0
	local p = first:Open({
		Content = D.Frame({ Name = "OldContent" }),
		Position = Vector2.new(0, 0),
		OnClose = function()
			closed += 1
		end,
	})
	assert(Overlay.getDefault() == first)
	first.Layer.Parent = nil -- what Destroy() does first; the OnDestroyed handler runs later under Deferred signals
	assert(first.Alive:Get() == true)
	local second = Overlay.getDefault()
	assert(second ~= first, "a fresh overlay at once")
	assert(not pcall(function()
		first:Open({ Content = D.Frame({}), Position = Vector2.new(0, 0) })
	end), "Open on the half-dead overlay raises")
	p:Close() -- from an ancestor handler: no Slot ops on the unparented host
	assert(not p.IsOpen:Get() and closed == 1 and first.Count:Get() == 0)
	first.Layer:Destroy()
	assert(first.Alive:Get() == false and first.Count:Get() == 0)
	local screen2 = D.Frame({ second.Layer })
	local p2 = second:Open({ Content = D.Frame({ Name = "NewContent" }), Position = Vector2.new(0, 0) })
	assert(H.find(screen2, "NewContent") ~= nil and second.Count:Get() == 1)
	p2:Close()
	q.dispose(screen2)
	q.dispose(screen)
	H.assertNoDebugOutput("sync death")
end)

H.done()
