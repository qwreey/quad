local open = q.Source(false)

local size = open:Compute(function(self: q.StateData<boolean>): RobloxModule.Tween<UDim2>
	return q.Tween({
		Value = if self:Get() then UDim2.fromOffset(320, 200) else UDim2.fromOffset(320, 0),
		Time = 0.25,
		Style = Enum.EasingStyle.Quart,
		Direction = Enum.EasingDirection.Out,
		Override = "Finish",
	})
end)

local panel = D.Frame({ Size = size })
