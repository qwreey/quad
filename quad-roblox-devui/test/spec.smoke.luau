--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local TextBox = q.Elem "TextBox"
local TextButton = q.Elem "TextButton"

H.section("mount + event + q.Out + tween", function()
	local clicks = 0
	local text = q.Source("hi")
	local hover = q.Source(false)
	local color = hover:Compute(function(self)
		return if self:Get() then Color3.new(1, 0, 0) else Color3.new(0, 0, 1)
	end):Apply(q.Animate({ Time = 0.2 }))
	local box = TextBox({ Text = text, q.Out "TextBox" "Text" (text) })
	local btn = TextButton({
		Text = text,
		BackgroundColor3 = color,
		Size = UDim2.fromOffset(10, 10),
		Activated = function()
			clicks += 1
		end,
		box,
	})
	H.fire(btn, "Activated", H.input({}), 1)
	assert(clicks == 1)
	box.Text = "typed"
	assert(text:Get() == "typed" and btn.Text == "typed", "q.Out round trip")
	assert(btn.BackgroundColor3 == Color3.new(0, 0, 1), "first write snaps")
	hover:Set(true)
	H.finishTweens()
	assert(btn.BackgroundColor3 == Color3.new(1, 0, 0), "tween target written")
	q.dispose(btn)
	assert(H.isDestroyed(box))
	H.assertNoDebugOutput("smoke")
end)

H.section("timers", function()
	local fired = false
	task.delay(1, function() fired = true end)
	H.advance(0.5)
	assert(not fired)
	H.advance(0.6)
	assert(fired)
end)

H.done()
