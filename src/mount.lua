local module = {};

function module.init(shared)
    local new = {};

    -- we should add plugin support
    function new.mount(to,this)
        this.Parent = to;
    end

    setmetatable(new,{
        __call = function (self,...)
            self.mount(...);
        end;
    });

    return new;
end

return module;