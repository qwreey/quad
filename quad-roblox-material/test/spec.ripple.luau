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
	assert(circle.AnchorPoint == Vector2.new(0.5, 0.5))
	assert(math.abs(circle.BackgroundTransparency - 0.9) < 1e-9, "ripple opacity .10")
	assert(group.Size == UDim2.fromScale(1, 1))
	H.finishTweens()
	local d = math.ceil(2 * math.sqrt(80 * 80 + 30 * 30))
	assert(math.abs(circle.Size.X.Offset - d) < 1e-6 and circle.Size.Y.Offset == circle.Size.X.Offset, "grows to cover the farthest corner: " .. tostring(circle.Size) .. " vs " .. d)
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

H.done()
