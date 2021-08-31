local module = {};

function module.init(shared)
	local new = {};
	local bind = shared.event.bind;
	local items = shared.items;

	function new.make(ClassName,prop)
		-- make thing
		local item;
		local classOfClassName = type(ClassName);
		if classOfClassName == "string" then
			item = Instance.new(ClassName);
		elseif classOfClassName == "function" then
			item = ClassName();
		elseif classOfClassName == "table" then
			local func = ClassName.new or ClassName.New or ClassName.__new;
			item = func();
		end
		if not item then
			local str = tostring(ClassName);
			print(("fail to make item '%s', did you forget to checking the class '%s' is exist?"):format(str,str));
		end

		-- set property and adding child and binding functions
		for index,value in pairs(prop) do
			local valueType = typeof(value);
			local indexType = typeof(index);

			-- child
			if indexType ~= "string" then -- object
				value.Parent = new;
			elseif valueType == "function" and bind(value) then -- connect event
			elseif indexType == "string" then
				new[index] = value; -- set property
			end
		end
		return item;
	end
	local make = new.make;

	function new.import(ClassName)
		return function (prop)
			if type(prop) == "string" then
				local lastName = prop;
				return function (nprop)
					nprop.Name = lastName;
					local item = make(ClassName,nprop);
					items[lastName] = item;
					return item;
				end;
			end
			return make(ClassName,prop);
		end;
	end

	setmetatable(new,{
		__call = function (self,...)
			return self.import(...);
		end;
	});

	return new;
end

return module;