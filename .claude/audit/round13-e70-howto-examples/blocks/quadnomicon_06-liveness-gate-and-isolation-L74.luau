local gchold: { [any]: any } = {}
local gcconn = inst:GetPropertyChangedSignal("ClassName"):Connect(function()
    nop(gchold, inst) -- never fires; the capture is the point
end)
gchold[1] = gcconn
InstData:SetWeak(inst, "gchold", gchold)
InstData:SetWeak(inst, "gcconn", gcconn)
