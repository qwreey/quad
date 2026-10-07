--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Interactive = require("../src/Interactive")
local Ripple = require("../src/Ripple")
local Theme = require("../src/Theme")
local StateLayer = require("../src/StateLayer")

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

H.section("press: one CanvasGroup + circle (4 instances), geometry from the press point", function()
	local btn = mountButton()
	local before = H.countDescendants(btn)
	H.fire(btn, "InputBegan", H.input({ Position = Vector3.new(30, 20, 0) }))
	local added = H.countDescendants(btn) - before
	assert(added == 4, "a press adds CanvasGroup, UICorner, circle, UICorner = 4, got " .. added)
	local gs = groups(btn)
	assert(#gs == 1)
	local group = gs[1]
	assert(H.find(group, "RippleCircle") ~= nil and H.countDescendants(group) == 3)
	local circle = H.find(group, "RippleCircle")
	-- host (10,10) 100x40, press (30,20): rel (20,10); far corner dx 80 dy 30
	assert(circle.Position == UDim2.fromOffset(20, 10), "origin = press point relative to the host: " .. tostring(circle.Position))
	assert(circle.Size == UDim2.fromOffset(0, 0), "mounts at size 0 (snapped)")
	assert(math.abs(circle.BackgroundTransparency - 0.9) < 1e-9, "ripple opacity .10")
	assert(group.Size == UDim2.fromScale(1, 1))
	local round = H.find(circle, "RippleRound")
	-- early in the grow the shape is the circle itself (radius < the 10 px to the nearest edge)
	H.advance(0.002)
	local r = circle.Size.X.Offset / 2
	assert(r > 0 and r < 10 and circle.Size.Y.Offset == circle.Size.X.Offset, "a small circle: " .. tostring(circle.Size))
	assert(math.abs(circle.Position.X.Offset - (20 - r)) <= 1 and math.abs(round.CornerRadius.Offset - r) <= 1, "centered on the press point, fully round")
	-- BOUNDED: at every frame the shape stays inside the host rectangle (AutomaticSize ancestors measure it)
	for _ = 1, 40 do
		H.advance(0.0125)
		local p, z = circle.Position, circle.Size
		assert(p.X.Offset >= 0 and p.Y.Offset >= 0, "inside (top-left): " .. tostring(p))
		assert(p.X.Offset + z.X.Offset <= 100 + 1e-6 and p.Y.Offset + z.Y.Offset <= 40 + 1e-6, "inside (bottom-right): " .. tostring(p) .. " " .. tostring(z))
	end
	H.advance(0.1)
	assert(circle.Position == UDim2.fromOffset(0, 0) and circle.Size == UDim2.fromOffset(100, 40), "ends covering the host: " .. tostring(circle.Size))
	assert(round.CornerRadius == UDim.new(0, 0), "own rounding faded out (the group's corner shapes it)")
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
	assert(circle.BackgroundTransparency == 1, "faded out")
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

H.section("chip-sized host at a fractional position: the ripple stays a circle, then a circle sliced by the edges (no pill)", function()
	-- Studio QA 2026-10-07 (3rd): on Input chips the ripple started as a slight oval and grew as a pill
	local r = Ripple.new({ Color = Color3.new(1, 1, 1), Corner = UDim.new(0, 8) })
	local host = D.Frame { r.Hook, r.Slot }
	H.setAbs(host, 10.4, 10.7, 100, 32) -- a flow layout leaves fractional positions; rel press = (49.6, 15.3)
	r:Press(Vector2.new(60, 26))
	local circle = H.find(host, "RippleCircle")
	local round = H.find(circle, "RippleRound")
	local sawCircle, sawSliced = false, false
	for _ = 1, 40 do
		H.advance(1 / 240)
		local z = circle.Size
		local bw, bh, c = z.X.Offset, z.Y.Offset, round.CornerRadius.Offset
		if bh < 30 then
			-- uncut: a square box (snapped center) with a half-side corner = a circle
			assert(bw == bh and c == bw / 2, "uncut ripple is a circle: " .. tostring(z) .. " corner " .. c)
			sawCircle = sawCircle or bw >= 4
		elseif bw >= 44 and bw <= 80 then
			-- both long edges cut (R 22..40): the corner is the cut-chord inset, far below the pill's 16
			local R = bw / 2 -- = ceil(r): the true radius is in (R - 1, R]
			local lo = math.max(Ripple.cutCorner(R, 15, R), Ripple.cutCorner(R, 17, R))
			local hi = math.max(Ripple.cutCorner(R, 15, R - 1), Ripple.cutCorner(R, 17, R - 1))
			assert(c < 12 and c >= lo - 0.5 and c <= hi + 0.5, "sliced circle, not a pill: " .. tostring(z) .. " corner " .. c)
			sawSliced = true
		end
	end
	assert(sawCircle and sawSliced, "both phases observed")
	H.advance(0.5)
	assert(circle.Size == UDim2.fromOffset(100, 32) and round.CornerRadius == UDim.new(0, 0), "ends covering the host")
	q.dispose(host)
	H.assertNoDebugOutput("chip ripple")
end)

H.section("cutCorner: uncut = r, one corner covered = 0, cut by an edge = the chord inset", function()
	assert(Ripple.cutCorner(10, 10, 10) == 10)
	assert(Ripple.cutCorner(5, 5, 10) == 0, "corner inside the circle")
	assert(math.abs(Ripple.cutCorner(20, 16, 20) - 8) < 1e-9, "20 - sqrt(400 - 256) = 8")
end)

H.done()
