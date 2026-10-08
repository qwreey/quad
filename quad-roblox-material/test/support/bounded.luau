--!strict
--[[
	Ripple shape checks shared by the specs (Ripple.luau "BOUNDED", "NOT SCALE" and "FULL COVER").
	  assertNoScale(root, label)   every ripple group under `root` is Position 0 / Size Scale 1 (the deepest Scale allowed)
	                               and NOTHING below a group has any Scale component in its Size or Position — not a
	                               partial one (the 9th AutomaticSize loop) and not the full-cover Scale 1 either (the
	                               10th follow-up: an auto-width host jumped to the full available width at full cover).
	  isCovered(circle)            the disc has handed over to its group's background (FULL COVER)
	  assertCovered(circle, label) FULL COVER: the disc hidden, the group painted, no Scale below the group
	  pressBounded(host, w, h, label)
	                               press `host` near a corner and, frame by frame while the ripple grows, assertNoScale and
	                               every visible disc whole Offsets INSIDE the host rectangle; the expand ends covered.
	The host's state layer is laid out with the host's size (the mock has no layout).
]]
local H = require("./harness")

local function groups(host: any): { any }
	return H.findAll(host, function(c: any): boolean
		return c.ClassName == "CanvasGroup" and c.Name == "Ripple"
	end)
end

local function noScale(u: UDim2): boolean
	return u.X.Scale == 0 and u.Y.Scale == 0
end

local function assertNoScale(root: any, label: string)
	local gs = groups(root)
	assert(#gs > 0, label .. ": a ripple is running")
	for _, g in gs do
		assert((g.Position or UDim2.new()) == UDim2.fromScale(0, 0) and g.Size == UDim2.fromScale(1, 1), label .. ": the group covers the host")
		for _, c in H.findAll(g, function(x: any): boolean
			return typeof(x.Size) == "UDim2"
		end) do
			local p: UDim2, z: UDim2 = c.Position or UDim2.new(), c.Size
			assert(noScale(p) and noScale(z), `{label}: {c.Name} below the ripple group has a Scale {tostring(p)} {tostring(z)}`)
		end
	end
end

local function isCovered(circle: any): boolean
	return circle.Visible == false
end

local function assertCovered(circle: any, label: string)
	assert(isCovered(circle), label .. ": the disc hands over at full cover (hidden)")
	local g = circle.Parent
	assert(g ~= nil and g.ClassName == "CanvasGroup", label .. ": the disc sits in its group")
	assert(g.BackgroundTransparency < 1, label .. ": the group's background paints the full cover")
	assertNoScale(g.Parent, label)
end

local function pressBounded(host: any, w: number, h: number, label: string)
	H.setAbs(host, 0, 0, w, h)
	local layer = H.find(host, "StateLayer")
	assert(layer ~= nil, label .. ": a state layer")
	H.setAbs(layer, 0, 0, w, h)
	H.fire(host, "InputBegan", H.input({ Position = Vector3.new(w - 2, 2, 0) }))
	local seen = 0
	for _ = 1, 30 do
		H.advance(1 / 60)
		assertNoScale(host, label)
		for _, g in groups(host) do
			seen += 1
			for _, d in H.findAll(g, function(c: any): boolean
				return c.ClassName == "ImageLabel"
			end) do
				if not isCovered(d) then
					local p: UDim2, z: UDim2 = d.Position or UDim2.new(), d.Size
					assert(
						p.X.Offset >= 0 and p.Y.Offset >= 0 and p.X.Offset + z.X.Offset <= w and p.Y.Offset + z.Y.Offset <= h,
						`{label}: the disc leaves the host {tostring(p)} {tostring(z)}`
					)
				end
			end
		end
	end
	assert(seen > 0, label .. ": a ripple ran")
	assertCovered(H.find(host, "RippleCircle"), label)
	H.fire(host, "InputEnded", H.input({}))
	H.UserInputService.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(w - 2, 2, 0) }))
	H.advance(1)
	assert(#groups(host) == 0, label .. ": ripples gone")
end

return { pressBounded = pressBounded, assertNoScale = assertNoScale, isCovered = isCovered, assertCovered = assertCovered }
