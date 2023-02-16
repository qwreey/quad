
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
function customSignal:Fire(...)
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

-- roblox connections disconnecter
local insert = table.insert
local idSpace = {}
local disconnecterClass = {__type = "quad_disconnecter"}
function disconnecterClass:Add(connection)
    insert(self,connection)
end
function disconnecterClass:Disconnect()
    for i,v in pairs(self) do
        pcall(v.Disconnect,v)
        self[i] = nil
    end
end
function disconnecterClass:Destroy()
    local id = self.id
    if id then
        idSpace[id] = nil
    end
    for i,v in pairs(self) do
        pcall(v.Disconnect,v)
        self[i] = nil
    end
end
function disconnecterClass.New(id)
    if id then
        local old = idSpace[id];
        if old then
            return old;
        end
    end
    local this = setmetatable({id = id},disconnecterClass);
    if id then
        idSpace[id] = this;
    end
    return this;
end
disconnecterClass.__index = disconnecterClass
