--!strict
--[[
	Ripple BOUNDED check shared by the sheet / drawer specs (Ripple.luau "BOUNDED" and "NOT SCALE"): press `host` near a
	corner and, frame by frame while the ripple grows, every ripple group is the full-cover form and every disc is either
	the full-cover form or whole Offsets INSIDE the host rectangle — nothing a partial Scale, nothing past the host.
	The host's state layer is laid out with the host's size (the mock has no layout).
]]
local H = require("./harness")

local function groups(host: any): { any }
	return H.findAll(host, function(c: any): boolean
		return c.ClassName == "CanvasGroup"
	end)
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
		for _, g in groups(host) do
			seen += 1
			assert((g.Position or UDim2.new()) == UDim2.fromScale(0, 0) and g.Size == UDim2.fromScale(1, 1), label .. ": the group covers the host")
			for _, d in H.findAll(g, function(c: any): boolean
				return c.ClassName == "ImageLabel"
			end) do
				local p: UDim2, z: UDim2 = d.Position or UDim2.new(), d.Size
				if z ~= UDim2.fromScale(1, 1) then
					assert(p.X.Scale == 0 and p.Y.Scale == 0 and z.X.Scale == 0 and z.Y.Scale == 0, `{label}: partial Scale {tostring(p)} {tostring(z)}`)
					assert(
						p.X.Offset >= 0 and p.Y.Offset >= 0 and p.X.Offset + z.X.Offset <= w and p.Y.Offset + z.Y.Offset <= h,
						`{label}: the disc leaves the host {tostring(p)} {tostring(z)}`
					)
				end
			end
		end
	end
	assert(seen > 0, label .. ": a ripple ran")
	H.fire(host, "InputEnded", H.input({}))
	H.UserInputService.InputEnded:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(w - 2, 2, 0) }))
	H.advance(1)
	assert(#groups(host) == 0, label .. ": ripples gone")
end

return { pressBounded = pressBounded }
