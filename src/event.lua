local module = {};

function module.init(shared)
	local new = {};
	local unpack = table.unpack;
	local coroutineCreate = coroutine.create;
	local coroutineResume = coroutine.resume;

	local prefix = "event::";
	local special = {
		["Property::(.+)"] = function (this,func,property)
			this.GetPropertyChangedSignal(property):Connect(function()
				func(this,this[property]);
			end);
		end;
		["CreatedSync::"] = function (this,func)
			func(this);
		end;
		["Created::"] = function (this,func)
			coroutineResume(coroutineCreate(func),this);
		end;
	};

	local prefixLen = #prefix;
	setmetatable(new,{
		__call = function(self,eventName)
			return prefix .. eventName;
		end;
	});

	-- try binding, if key dose match with anything, ignore call
	function new.bind(this,key,func)
		-- check prefix
		if key:sub(1,prefixLen) ~= prefix then
			return;
		end
		key = key:sub(prefixLen + 1,-1);

		-- find special bindings
		for specKey,specFunc in pairs(special) do
			local find = {key:match(specKey)};
			if #find ~= 0 then
				specFunc(this,func,unpack(find));
				return true;
			end
		end

		-- binding normal events
		local event = this[key];
		if event then
			event:Connect(function(...)
				func(this,...);
			end);
			return true;
		end
	end

	-- property changed binding
	local prefixProperty = prefix .. "Property::";
	function new.prop(name)
		return prefixProperty .. name;
	end

	-- when created binding
	new.created = prefix .. "Created::";
	new.createdSync = prefix .. "CreatedSync::";
	return new;
end

return module;