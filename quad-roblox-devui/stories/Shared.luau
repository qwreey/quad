--!strict
-- Small helpers shared by the stories (not a story itself: UI Labs only lists modules named `*.story`).
local Devui = require("../src")
local q = require("../src/Quad")

local Shared = {}

-- "label: value" row whose value text follows `value` live (tostring of whatever the Source holds)
function Shared.show(label: string, value: q.State<any>, style: Devui.Style?): Frame
	local text: q.State<string> = value:Compute(function(self)
		local v = self:Get()
		if typeof(v) == "Color3" then
			return Devui.NumberFormat.toHex(
				math.floor(v.R * 255 + 0.5),
				math.floor(v.G * 255 + 0.5),
				math.floor(v.B * 255 + 0.5)
			)
		end
		return tostring(v)
	end)
	return Devui.LabelText({ Label = label, Text = text, Style = style })
end

return Shared
