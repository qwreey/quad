
local module = {}

local running = coroutine.running
local resume = coroutine.resume
local yield = coroutine.yield
local insert = table.insert

local customConnection = {}
customConnection.__index = customConnection
function customConnection.new(signal,func)
    func
end

local customSignal = {}
customSignal.__index = customSignal
function customSignal:emit(...)
    local waitting = self.waitting
    self.waitting = {}

    for _,v in pairs(waitting) do
        task.spawn(resume,v,...)
    end

    for _,v in pairs(self.connection) do
        task.spawn(v,...)
    end
end
function customSignal:Wait()
    insert(self.waitting,running())
    return yield()
end
function customSignal:Connect(func)
    local connection = self.connection
    for _,v in pairs(connection) do
        if v == func then
            error("Function %s Connected already")
        end
    end
    insert(self.connection,func)
    return customConnection.new(self,func) 
end
local function onceWaitter(targetFunction)
    
end
function customSignal:Once()
    
end
function customSignal.new()
    local self = {waitting={},onceConnection={},connection={}}
    setmetatable(self,customSignal)
end
function this.new(...)
    customSignal.new(...)
end
this.customSignal = customSignal
