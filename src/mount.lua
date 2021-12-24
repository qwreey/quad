local module = {};

function module.init(shared)
    local new = {};
    local insert = table.insert;

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
                pcall(destroyThis,this);
            end
            --if sef.to when
            -- todo for remove child on parent
        end
    end

    function new.getHolder(item)
		return (type(item) == "table") and (item._holder or item.holder or item.__holder) or item;
	end
	local getHolder = new.getHolder
    -- we should add plugin support
    function new.mount(to,this,inst)
    	local thisO = this;
    	if type(this) == "table" then
    		thisO = this.__object;
            local parent = rawget(this,"__parent");
            if type(parent) == "table" then
                local parentChild = rawget(parent,"__child");
                if parentChild then
                    for i,v in pairs(parentChild) do
                        if v == this then
                            parentChild[i] = nil;
                        end
                    end
                end
            end
    		rawset(this,"__parent",to);
    	end
        if thisO then
            thisO.Parent = inst or getHolder(to);
        end
        if type(to) == "table" then
        	local child = rawget(to,"__child");
        	if not child then
        		child = {};
        		rawset(to,"__child",child);
    		end
    		insert(child,this);
        end
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
