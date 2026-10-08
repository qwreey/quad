--!strict
--[[
	InputSink shape check shared by the specs (Util.inputSink, "a plain frame passes a GUI click down to the scrim button
	beneath; only a GuiButton sinks it"). assertInputSink(surface, label): `surface` has exactly one DIRECT child named
	"InputSink" that is an invisible TextButton, full cover (Scale 1,1), not Selectable, ZIndex 0 — below every sibling.
]]
local function assertInputSink(surface: any, label: string)
	local sinks = {}
	for _, c in surface:GetChildren() do
		if c.Name == "InputSink" then
			table.insert(sinks, c)
		end
	end
	assert(#sinks == 1, label .. ": exactly one direct InputSink child, got " .. #sinks)
	local s: any = sinks[1]
	assert(s.ClassName == "TextButton", label .. ": the sink is a GuiButton")
	assert(s.Size == UDim2.fromScale(1, 1), label .. ": the sink covers the whole surface (direct child, Scale 1,1)")
	assert(s.Selectable == false, label .. ": gamepad never lands on the sink")
	assert(s.BackgroundTransparency == 1 and s.Text == "" and s.AutoButtonColor == false, label .. ": the sink is invisible")
	assert(s.ZIndex == 0, label .. ": ZIndex 0")
	for _, c in surface:GetChildren() do
		if c ~= s and c:IsA("GuiObject") then
			assert(c.ZIndex > s.ZIndex, label .. ": sibling " .. c.Name .. " sits above the sink")
		end
	end
end

return { assertInputSink = assertInputSink }
