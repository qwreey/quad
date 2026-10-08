--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Interactive = require("../src/Interactive")
local Ripple = require("../src/Ripple")
local Theme = require("../src/Theme")
local StateLayer = require("../src/StateLayer")
local Button = require("../src/Button")
local Chip = require("../src/Chip")
local Overlay = require("../src/Overlay")
local DatePicker = require("../src/DatePicker")
local Calendar = require("../src/DatePicker/Calendar")

local theme = Theme.default
local FULL = UDim.new(0.5, 0)

local function mountButton(opts: Interactive.Options?)
	local o: Interactive.Options = opts or { OnColor = theme.Color.OnPrimary, Corner = FULL }
	local fx = Interactive.new(o)
	local btn = D.TextButton {
		fx.Hook,
		fx.Layer,
		Size = UDim2.fromOffset(100, 40),
		BackgroundColor3 = theme.Color.Primary,
	}
	H.setAbs(btn, 10, 10, 100, 40)
	local layer = H.find(btn, "StateLayer")
	H.setAbs(layer, 10, 10, 100, 40)
	return btn, layer, fx
end

-- the circle's box in host local units (= screen pixels here: no UIScale). Ripple writes whole Offsets, or the full-cover
-- form Position 0 / Size Scale 1 once the box covers the host — never a PARTIAL Scale (an AutomaticSize ancestor cannot
-- resolve one: Studio QA 2026-10-08, 9th — Ripple.luau "NOT SCALE")
local function box(circle: any, w: number, h: number): (number, number, number, number)
	local p, z = circle.Position, circle.Size
	if z == UDim2.fromScale(1, 1) then
		assert(p == UDim2.fromScale(0, 0), "full cover sits at the origin: " .. tostring(p))
		return 0, 0, w, h
	end
	assert(p.X.Scale == 0 and p.Y.Scale == 0 and z.X.Scale == 0 and z.Y.Scale == 0, "no partial Scale: " .. tostring(p) .. " " .. tostring(z))
	return p.X.Offset, p.Y.Offset, z.X.Offset, z.Y.Offset
end

local function groups(host: any): { any }
	return H.findAll(host, function(c: any)
		return c.ClassName == "CanvasGroup"
	end)
end

H.section("rest: the whole interaction layer is 3 instances, no CanvasGroup", function()
	local btn, layer = mountButton()
	assert(H.countDescendants(btn) == 3, "layer + UICorner + UIStroke, got " .. H.countDescendants(btn))
	assert(#groups(btn) == 0, "no CanvasGroup at rest")
	assert(layer.ClassName == "Frame")
	assert(H.find(btn, "FocusRing") ~= nil, "focus ring stroke exists (disabled)")
	q.dispose(btn)
	H.assertNoDebugOutput("rest")
end)

H.section("press: one CanvasGroup + disc (3 instances), geometry from the press point", function()
	local btn = mountButton()
	local before = H.countDescendants(btn)
	H.fire(btn, "InputBegan", H.input({ Position = Vector3.new(30, 20, 0) }))
	local added = H.countDescendants(btn) - before
	assert(added == 3, "a press adds CanvasGroup, UICorner, disc ImageLabel = 3, got " .. added)
	local gs = groups(btn)
	assert(#gs == 1)
	local group = gs[1]
	assert(H.find(group, "RippleCircle") ~= nil and H.countDescendants(group) == 2)
	local circle = H.find(group, "RippleCircle")
	-- host (10,10) 100x40, press (30,20): rel (20,10); far corner dx 80 dy 30
	assert(circle.Position == UDim2.fromOffset(20, 10), "origin = press point relative to the host: " .. tostring(circle.Position))
	assert(circle.Size == UDim2.fromOffset(0, 0), "mounts at size 0 (snapped)")
	assert(math.abs(circle.ImageTransparency - 0.9) < 1e-9 and circle.BackgroundTransparency == 1, "ripple opacity .10")
	assert(group.Size == UDim2.fromScale(1, 1))
	assert(circle.ClassName == "ImageLabel" and circle.Image == "rbxassetid://89858938964426")
	-- early in the grow the shape is the whole disc (radius < the 10 px to the nearest edge)
	H.advance(0.002)
	local cx0, _, cbw, cbh = box(circle, 100, 40)
	local r = cbw / 2
	assert(r > 0 and r < 10 and cbh == cbw, "a small circle: " .. tostring(circle.Size))
	assert(math.abs(cx0 - (20 - r)) <= 1, "centered on the press point")
	assert(circle.ImageRectOffset == Vector2.zero and math.abs(circle.ImageRectSize.X - 1024) < 1e-3, "uncut: the whole texture")
	-- BOUNDED: at every frame the shape stays inside the host rectangle (AutomaticSize ancestors measure it)
	for _ = 1, 40 do
		H.advance(0.0125)
		local x0, y0, bw, bh = box(circle, 100, 40)
		assert(x0 >= 0 and y0 >= 0, "inside (top-left): " .. tostring(circle.Position))
		assert(x0 + bw <= 100 + 1e-6 and y0 + bh <= 40 + 1e-6, "inside (bottom-right): " .. tostring(circle.Position) .. " " .. tostring(circle.Size))
	end
	H.advance(0.1)
	assert(circle.Position == UDim2.fromScale(0, 0) and circle.Size == UDim2.fromScale(1, 1), "ends covering the host: " .. tostring(circle.Size))
	-- rounded clip: the group carries the host's corner
	local corner = H.find(group, "_quad_round")
	assert(corner ~= nil and corner.CornerRadius == FULL, "group clips with the host's corner radius")
	q.dispose(btn)
	H.assertNoDebugOutput("press")
end)

H.section("release fades and the ripple is removed after the fade (instances back to rest)", function()
	local btn = mountButton()
	local rest = H.countDescendants(btn)
	H.fire(btn, "InputBegan", H.input({ Position = Vector3.new(30, 20, 0) }))
	H.finishTweens()
	H.fire(btn, "InputEnded", H.input({}))
	local circle = H.find(btn, "RippleCircle")
	assert(circle ~= nil)
	H.finishTweens()
	assert(circle.ImageTransparency == 1, "faded out")
	assert(#groups(btn) == 1, "still mounted until the fade timer")
	H.advance(0.1)
	assert(#groups(btn) == 1, "fade not over yet")
	H.advance(0.2)
	assert(#groups(btn) == 0 and H.countDescendants(btn) == rest, "removed after the fade")
	assert(H.isDestroyed(circle), "destroyed, not just unparented")
	assert(H.pendingTimers() == 0)
	q.dispose(btn)
	H.assertNoDebugOutput("release")
end)

H.section("pointer leaving cancels the press and fades the ripple", function()
	local btn = mountButton()
	H.fire(btn, "InputBegan", H.input({ Position = Vector3.new(30, 20, 0) }))
	H.fire(btn, "MouseLeave")
	H.advance(0.4)
	assert(#groups(btn) == 0)
	q.dispose(btn)
end)

H.section("gamepad press ripples from the center", function()
	local btn = mountButton()
	H.fire(btn, "InputBegan", H.input({ UserInputType = Enum.UserInputType.Gamepad1, KeyCode = Enum.KeyCode.ButtonA }))
	local circle = H.find(btn, "RippleCircle")
	assert(circle ~= nil and circle.Position == UDim2.fromOffset(50, 20), "center of 100x40")
	H.fire(btn, "InputEnded", H.input({ UserInputType = Enum.UserInputType.Gamepad1, KeyCode = Enum.KeyCode.ButtonA }))
	H.advance(0.4)
	assert(#groups(btn) == 0)
	q.dispose(btn)
end)

H.section("bounded: repeated presses never keep more than Max ripples", function()
	local btn = mountButton()
	for i = 1, 12 do
		H.fire(btn, "InputBegan", H.input({ Position = Vector3.new(20 + i, 20, 0) }))
		H.fire(btn, "InputEnded", H.input({}))
		assert(#groups(btn) <= 3, "ripples alive: " .. #groups(btn))
	end
	H.advance(0.5)
	assert(#groups(btn) == 0, "all cleaned up")
	assert(H.pendingTimers() == 0)
	q.dispose(btn)
	H.assertNoDebugOutput("bounded")
end)

H.section("host destroyed mid-fade: pending removal timers are cancelled, no error", function()
	local btn = mountButton()
	H.fire(btn, "InputBegan", H.input({ Position = Vector3.new(30, 20, 0) }))
	H.fire(btn, "InputEnded", H.input({}))
	assert(H.pendingTimers() == 1)
	q.dispose(btn)
	assert(H.pendingTimers() == 0, "timer cancelled with the host")
	H.advance(1)
	H.assertNoDebugOutput("destroy mid-fade")
end)

H.section("Ripple = false: static pressed layer, never a CanvasGroup", function()
	local btn, layer = mountButton({ OnColor = theme.Color.OnPrimary, Corner = FULL, Ripple = false })
	H.fire(btn, "InputBegan", H.input({ Position = Vector3.new(30, 20, 0) }))
	assert(#groups(btn) == 0 and H.countDescendants(btn) == 3)
	H.finishTweens()
	assert(math.abs(layer.BackgroundTransparency - 0.9) < 1e-9, "static layer shows pressed .10")
	q.dispose(btn)
end)

H.section("state layer opacities: hover .08, focus .10, highest wins, disabled hides, ripple replaces pressed", function()
	local btn, layer, fx = mountButton()
	H.fire(btn, "MouseEnter")
	H.finishTweens()
	assert(math.abs(layer.BackgroundTransparency - 0.92) < 1e-9, "hover .08")
	H.fire(btn, "SelectionGained")
	H.finishTweens()
	assert(math.abs(layer.BackgroundTransparency - 0.90) < 1e-9, "focus .10 wins over hover")
	local ring = H.find(btn, "FocusRing")
	assert(ring.Enabled == true, "focus ring on while focused")
	H.fire(btn, "SelectionLost")
	H.fire(btn, "InputBegan", H.input({ Position = Vector3.new(30, 20, 0) }))
	H.finishTweens()
	assert(math.abs(layer.BackgroundTransparency - 0.92) < 1e-9, "with a ripple the static layer stays at hover")
	H.fire(btn, "MouseLeave")
	H.finishTweens()
	assert(layer.BackgroundTransparency == 1, "idle: invisible")
	assert(not fx.Hovered:Get())
	q.dispose(btn)

	local disabled = q.Source(true)
	local b2, l2 = mountButton({ OnColor = theme.Color.OnPrimary, Corner = FULL, Disabled = disabled })
	H.fire(b2, "MouseEnter")
	H.finishTweens()
	assert(l2.BackgroundTransparency == 1, "disabled: no layer")
	q.dispose(b2)
	H.assertNoDebugOutput("opacities")
end)

H.section("StateLayer used standalone (no ripple): pressed static, dragged .16", function()
	local hov, prs, foc, drg = q.Source(false), q.Source(false), q.Source(false), q.Source(false)
	local layer = StateLayer.new({
		Color = Color3.new(1, 1, 1),
		Corner = UDim.new(0, 8),
		Hovered = hov,
		Pressed = prs,
		Focused = foc,
		Dragged = drg,
	})
	local host = D.Frame { layer }
	prs:Set(true)
	H.finishTweens()
	assert(math.abs(layer.BackgroundTransparency - 0.9) < 1e-9)
	drg:Set(true)
	H.finishTweens()
	assert(math.abs(layer.BackgroundTransparency - 0.84) < 1e-9, "dragged .16")
	assert(H.find(host, "FocusRing") == nil, "no ring unless asked")
	q.dispose(host)
	H.assertNoDebugOutput("standalone")
end)

H.section("Ripple.new standalone: Press/Release/Count with a host that has no size is a no-op", function()
	local r = Ripple.new({ Color = Color3.new(1, 1, 1) })
	local host = D.Frame { r.Hook, r.Slot }
	r:Press(Vector2.new(5, 5)) -- AbsoluteSize is zero in the mock until set
	assert(r:Count() == 0)
	H.setAbs(host, 0, 0, 50, 50)
	r:Press(nil)
	assert(r:Count() == 1)
	r:Release()
	H.advance(0.4)
	assert(r:Count() == 0)
	q.dispose(host)
	H.assertNoDebugOutput("standalone ripple")
end)

H.section("wide host (160x48, pressed in the middle): the box stays inside the host and is a part of one circle", function()
	-- Studio QA 2026-10-07 (tab bar): a UICorner could not draw the arcs of a circle cut top and bottom
	local r = Ripple.new({ Color = Color3.new(1, 1, 1), Corner = UDim.new(0, 8) })
	local host = D.Frame { r.Hook, r.Slot }
	H.setAbs(host, 10.4, 10.7, 160, 48) -- fractional position
	r:Press(Vector2.new(90.4, 34.7)) -- rel (80, 24) -> center
	local circle = H.find(host, "RippleCircle")
	local sawSquare, sawCut = false, false
	for _ = 1, 120 do
		H.advance(1 / 240)
		local p, z = circle.Position, circle.Size
		local x0, y0, bw, bh = box(circle, 160, 48)
		assert(x0 == math.floor(x0) and bw == math.floor(bw) and y0 == math.floor(y0) and bh == math.floor(bh), "whole pixels")
		-- (a) inside the host
		assert(x0 >= 0 and y0 >= 0 and x0 + bw <= 160 and y0 + bh <= 48, "inside: " .. tostring(p) .. " " .. tostring(z))
		if bw == 0 then
			continue
		end
		local rs, ro = circle.ImageRectSize, circle.ImageRectOffset
		-- the circle's box: center (80, 24), half-side R; scale s texels per pixel
		local s = rs.X / bw
		assert(math.abs(rs.Y / bh - s) < 1e-3, "one scale on both axes")
		local R = math.round(1024 / (2 * s))
		assert(math.abs(R - math.round(R)) < 1e-2, "R is a whole pixel: " .. R)
		-- (b) the label's box + rect are a sub-rectangle of the SAME circle box [80-R, 80+R] x [24-R, 24+R]
		assert(math.abs(ro.X - (x0 - (80 - R)) * s) < 1e-3 and math.abs(ro.Y - (y0 - (24 - R)) * s) < 1e-3, "rect offset follows the box: " .. tostring(ro) .. " " .. tostring(p) .. " " .. tostring(z) .. " R " .. R)
		assert(x0 == math.max(0, 80 - R) and x0 + bw == math.min(160, 80 + R), "box = circle box ∩ host (x)")
		assert(y0 == math.max(0, 24 - R) and y0 + bh == math.min(48, 24 + R), "box = circle box ∩ host (y)")
		assert(ro.X >= -1e-3 and ro.Y >= -1e-3 and ro.X + rs.X <= 1024 + 1e-3 and ro.Y + rs.Y <= 1024 + 1e-3, "rect inside the texture")
		if 2 * R <= 48 then
			-- (c) uncut: a square box showing the whole texture
			assert(bw == bh and ro == Vector2.zero and math.abs(rs.X - 1024) < 1e-3 and math.abs(rs.Y - 1024) < 1e-3, "uncut = whole texture: " .. tostring(z))
			sawSquare = true
		elseif R < 80 then
			assert(bh == 48 and bw == 2 * R and rs.Y < 1024 - 1e-3 and ro.Y > 0, "cut top and bottom only")
			sawCut = true
		end
	end
	assert(sawSquare and sawCut, "both phases observed")
	H.advance(0.5)
	assert(circle.Size == UDim2.fromScale(1, 1) and circle.Position == UDim2.fromScale(0, 0), "ends covering the host")
	q.dispose(host)
	H.assertNoDebugOutput("wide ripple")
end)

H.section("a press adds 3 instances (CanvasGroup, UICorner, disc)", function()
	local r = Ripple.new({ Color = Color3.new(1, 1, 1) })
	local host = D.Frame { r.Hook, r.Slot }
	H.setAbs(host, 0, 0, 160, 48)
	local before = H.countDescendants(host)
	r:Press(nil)
	assert(H.countDescendants(host) - before == 3, "3 per press, got " .. H.countDescendants(host) - before)
	q.dispose(host)
end)

-- Studio QA 2026-10-08, 9th: with the ripple written as partial Scale fractions of the host (the 8th fix), an auto-width
-- Button / Chip grew to the full width of its row while a ripple ran and the row wrapped — the engine's AutomaticSize
-- cannot resolve a descendant sized by a partial Scale of the auto-sized ancestor. The mock has no AutomaticSize, so the
-- CAUSE is asserted: inside a ripple group there is no partial Scale anywhere (whole Offsets, or the full-cover form that
-- the state layer itself uses), at every frame of the expand, and the box stays inside the host's local size.
local function assertNoPartialScale(root: any, label: string)
	local gs = groups(root)
	assert(#gs > 0, label .. ": a ripple is running")
	for _, g in gs do
		assert(g.Size == UDim2.fromScale(1, 1) and (g.Position or UDim2.new()) == UDim2.new(), label .. ": the group is full-cover")
		local drawn = H.findAll(g, function(x: any): boolean
			return x.ClassName == "ImageLabel" or x.ClassName == "Frame"
		end)
		for _, c in drawn do
			local p, z = c.Position or UDim2.new(), c.Size or UDim2.new()
			local full = p == UDim2.fromScale(0, 0) and z == UDim2.fromScale(1, 1)
			assert(full or (p.X.Scale == 0 and p.Y.Scale == 0 and z.X.Scale == 0 and z.Y.Scale == 0),
				label .. ": no partial Scale under an AutomaticSize host: " .. tostring(p) .. " " .. tostring(z))
		end
	end
end

-- presses `host` at `rel` (screen pixels from its top-left) with the layer laid out at `wl x hl` LOCAL units under a
-- total UIScale `k` (so `wl * k` screen pixels), then checks every frame: no partial Scale, the box (local units) inside the host's local size and
-- centered on the press point, the far edges reached, and the end = the whole host
local function pressAndTrack(host: any, label: string, wl: number, hl: number, k: number, rel: Vector2)
	local layer = H.find(host, "StateLayer")
	assert(layer ~= nil, label .. ": state layer")
	-- the UIScale's Scale is a 32-bit float on the engine (0.8 reads back as 0.800000021): lay out with the measured product
	assert(math.abs(Ripple.localScale(layer) - k) < 1e-6, label .. ": UIScale product " .. Ripple.localScale(layer) .. " vs " .. k)
	k = Ripple.localScale(layer)
	local w, h = wl * k, hl * k
	H.setAbs(host, 200.3, 100.6, w, h)
	H.setAbs(layer, 200.3, 100.6, w, h)
	H.fire(host, "InputBegan", H.input({ Position = Vector3.new(200.3 + rel.X, 100.6 + rel.Y, 0) }))
	local circle = H.find(host, "RippleCircle")
	assert(circle ~= nil, label .. ": a ripple")
	local px, py = math.round(rel.X / k), math.round(rel.Y / k)
	assert(circle.Position == UDim2.fromOffset(px, py), label .. ": starts at the press point in local units: " .. tostring(circle.Position))
	local right, bottom = false, false
	for _ = 1, 60 do
		H.advance(1 / 120)
		assertNoPartialScale(host, label)
		local x0, y0, bw, bh = box(circle, wl, hl)
		assert(x0 >= 0 and y0 >= 0 and x0 + bw <= wl + 1e-6 and y0 + bh <= hl + 1e-6, label .. ": inside the host's local size")
		if bw > 0 and x0 > 0 and y0 > 0 and x0 + bw < math.floor(wl) and y0 + bh < math.floor(hl) then
			assert(bw == bh and math.abs(x0 + bw / 2 - px) <= 0.5 and math.abs(y0 + bh / 2 - py) <= 0.5, label .. ": uncut = centered square")
		end
		right = right or x0 + bw >= math.floor(wl)
		bottom = bottom or y0 + bh >= math.floor(hl)
	end
	assert(right and bottom, label .. ": reaches the right and bottom edges")
	H.advance(0.5)
	assert(circle.Position == UDim2.fromScale(0, 0) and circle.Size == UDim2.fromScale(1, 1), label .. ": ends covering the host")
	H.fire(host, "InputEnded", H.input({}))
	H.advance(0.5)
end

H.section("no partial Scale: auto-width Button and Chip presses (the AutomaticSize loop, 9th)", function()
	local btn = Button({ Label = "Auto width", OnClick = function() end })
	assert(btn.AutomaticSize == Enum.AutomaticSize.X, "the button is auto-width")
	pressAndTrack(btn, "button", 121.5, 40, 1, Vector2.new(100.2, 31.7))
	q.dispose(btn)
	local chip = Chip.Assist({ Label = "Directions", OnClick = function() end })
	pressAndTrack(chip, "chip", 97.25, 32, 1, Vector2.new(12.4, 6.6))
	q.dispose(chip)
	H.assertNoDebugOutput("no partial scale")
end)

local function labelOf(b: any): string?
	local l = H.find(b, "Label")
	return if l ~= nil then l.Text else nil
end

H.section("under a UIScale 0.8 (DatePicker modal fitted to a small layer): offsets in local units, box covers the host", function()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	-- fit = min(1, (W - 32) / 360, (H - 32) / 569) = 0.8 (DatePicker/Modal.luau)
	H.setAbs(overlay.Layer, 0, 0, 1280, 0.8 * 569 + 32)
	-- a picked date: OK is enabled (an empty draft disables it)
	DatePicker.Modal.open({ Overlay = overlay, Today = Calendar.date(2026, 10, 8), Value = q.Source<<Calendar.Date?>>(Calendar.date(2026, 10, 8)) })
	H.finishTweens()
	local card = H.find(screen, "DatePickerModal")
	local scale = H.findAll(card, function(x: any)
		return x.ClassName == "UIScale"
	end)[1]
	assert(math.abs(scale.Scale - 0.8) < 1e-6, "fitted to 0.8: " .. scale.Scale)
	-- the mode toggle (a 40 px round GlyphButton) pressed near its bottom-right, then the auto-width OK button
	pressAndTrack(H.find(card, "ModeToggle"), "mode toggle", 40, 40, 0.8, Vector2.new(29, 30.4))
	local ok: any = nil
	local buttons = H.findAll(card, function(x: any): boolean
		return x.Name == "Button"
	end)
	for _, b in buttons do
		if labelOf(b) == "OK" then
			ok = b
		end
	end
	assert(ok ~= nil and ok.AutomaticSize == Enum.AutomaticSize.X, "the auto-width OK button")
	pressAndTrack(ok, "OK", 58.5, 40, 0.8, Vector2.new(44, 29))
	q.dispose(screen)
	H.assertNoDebugOutput("ripple under UIScale")
end)

H.done()
