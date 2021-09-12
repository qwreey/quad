local module = {};

function module.init(shared)
    local new = {};

    local mount = {};
    mount.__index = mount;
    function mount:unmount()
        local this = self.this;
        local typeThis = type(this);
        if typeThis == "userdata" then
            this:Destroy();
        elseif typeThis == "table" then
            pcall(function()
                this.Parent = nil;
            end);
            local destroyThis = this.Destroy;
            if destroyThis then
                pcall(destroyThis);
            end
        end
    end

    -- we should add plugin support
    function new.mount(to,this)
        this.Parent = to;
        return setmetatable({to = to,this = this},mount);
    end

    setmetatable(new,{
        __call = function (self,...)
            return new.mount(...);
        end;
    });

    return new;
end

return module;