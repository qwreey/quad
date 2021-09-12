local module = {};

local exportItemMeta = {
	__index = function (self,key)
		local methods = self.__methods;
		local events = self.__events;
		return (methods and methods[key]) or (events and events[key]) or (self.getters[key](self.__this));
	end;
	__newindex = function (self,key,value)
		self.__setters[key](self.__this,value);
	end;
};

function module.init(shared)
	local new = {};
	local bind = shared.event.bind;
	local addObject = shared.store.addObject;

	function new.make(ClassName,...) -- render object
		-- make thing
		local item;
		local classOfClassName = type(ClassName);
		if classOfClassName == "string" then -- if classname is a string value, cdall instance.new for making new roblox instance
			item = Instance.new(ClassName);
		elseif classOfClassName == "function" then -- if classname is a function value, call it for making new object (OOP object)
			item = ClassName();
		elseif classOfClassName == "table" then -- if classname is a calss what is included new function, call it for making new object (object)
			local func = ClassName.new or ClassName.New or ClassName.__new;
			item = func();
		end
		if not item then -- if cannot make new object, ignore this call
			local str = tostring(ClassName);
			print(("fail to make item '%s', did you forget to checking the class '%s' is exist?"):format(str,str));
		end

		-- set property and adding child and binding functions
		for iprop,prop in pairs({...}) do
			for index,value in pairs(prop) do
				local valueType = typeof(value);
				local indexType = typeof(index);

				-- child
				if valueType == "function" and bind(value) then -- connect event
				elseif indexType == "string" then
					item[index] = value; -- set property
				elseif indexType == "number" then -- object
					if iprop == 1 then -- todo : move bindings
						value.Parent = item;
					else
						value:Clone().Parent = item;
					end
				end
			end
		end
		return item;
	end
	local make = new.make;

	function new.import(ClassName,defaultProperties) -- make new quad class object
		local this = defaultProperties or {};
		setmetatable(this,{
			__call = function (self,prop)
				if type(prop) == "string" then
					local lastName = prop;
					return function (nprop)
						nprop.Name = lastName;
						local item = make(ClassName,nprop);
						addObject(lastName,item);
						return item;
					end;
				end
				return make(ClassName,prop,this);
			end;
		});
		return this;
	end

	function new.export(newFn,setters,getters,methods,events) -- make quad importable class
		return function ()
			return setmetatable({
				__this = newFn();
				__setters = setters;
				__getters = getters;
				__methods = methods;
				__events = events;
			},exportItemMeta);
		end;
	end

	-- set module calling function
	setmetatable(new,{
		__call = function (self,...)
			return new.import(...);
		end;
	});

	return new;
end

return module;