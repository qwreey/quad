local module = {};
module.__index = module;

local unpack = table.unpack;
local coroutineCreate = coroutine.create;
local coroutineResume = coroutine.resume;
local clock = os.clock;

local function adaptRoutine(func,callback,...)
    if callback then
        callback(func(...));
    else
        func(...);
    end
end
function module.adapt(func,...)
    local lenArgs = select("#",...);
    local callArgs = {...};
    local callback = table.remove(callArgs);
    coroutineResume(coroutineCreate(adaptRoutine),func,callback,unpack(callArgs));
end
local adapt = module.adapt;

local runable = {};
module.runable = runable;
runable.__index = runable;

function runable:run(callback)
    adapt(self.func,self,callback)
end

function runable:delayedRun(time,callback)
    delay(time,function ()
        if callback then
            callback(self.func(self));
        else
            self.func(self);
        end
    end);
end

local function loopedRun(id,checkId,checkKilled,delay,period,self,func,callback)
    if (delay ~= 0) and (delay) then
        wait(delay);
    end
    while true do
        if id ~= checkId(self) then
            break;
        elseif checkKilled() then
            break;
        end
        if callback then
            callback(func(self));
        else
            func(self);
        end
        if (period ~= 0) and (period) then
            wait(period);
        end
    end
end
function runable:loopedRun(delay,period,callback)
    local id = self.runid;
    local killed = false;
    coroutineResume(coroutineCreate(loopedRun),
        id,self.getRunid,function () return killed; end,delay,period,self,self.func,callback
    );
    return {
        started = clock();
        kill = function ()
            killed = true;
        end;
        isKilled = function ()
            return killed or (id ~= self.runid);
        end;
    };
end

function runable:kill()
    self.runid = self.runid + 1;
end

function runable:getRunid()
    return self.runid;
end

function runable.new(func)
    local new = {runid = 0,func = func};
    setmetatable(new,runable);
    return new;
end
module.new = runable.new;

function module.init()
    return module;
end

return module;