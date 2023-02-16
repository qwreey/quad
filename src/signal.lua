
local module = {}
local signal

local customSignal = {}
customSignal.__index = customSignal
function customSignal:emit(name,...)

end
function customSignal:Connect()
end
function customSignal.new()
    local self = {}
    setmetatable(self,customSignal)
end
function this.new(...)
    customSignal.new(...)
end
this.customSignal = customSignal
