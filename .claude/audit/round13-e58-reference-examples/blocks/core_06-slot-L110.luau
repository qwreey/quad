local slot = q.Slot<<Instance>>()
local empty = slot.Length:Compute(function(self)
    return self:Get() == 0
end)
local view = D.Frame { slot, D.TextLabel { Text = "비었음", Visible = empty } }
