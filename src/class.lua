local module = {};

-- local exportItemMeta = {
-- 	__index = function (self,key)
-- 		local methods = self.__methods;
-- 		local events = self.__events;
-- 		return (methods and methods[key]) or (events and events[key]) or (self.getters[key](self.__this));
-- 	end;
-- 	__newindex = function (self,key,value)
-- 		self.__setters[key](self.__this,value);
-- 	end;
-- };

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
			if ClassName.__noSetup then -- if is support initing props
				local childs,props = {},{...};
				local parsed;
				for iprop,prop in ipairs(props) do
					for i,v in ipairs(prop) do
						childs[i] = ((iprop == 1) and v or v:Clone());
						prop[i] = nil;
					end
					if next(prop) then -- there are (key/value)s
						if parsed then
							for i,v in pairs(prop) do
								prop[i] = v;
							end
						else
							parsed = prop;
						end
					end
				end
				item = func(props);
				local holder = (type(item) == "table") and (item.__holder or item.holder) or item;
				for _,v in ipairs(childs) do
					v.Parent = holder;
				end
				return item;
			end
			item = func();
		end
		if not item then -- if cannot make new object, ignore this call
			local str = tostring(ClassName);
			print(("fail to make item '%s', did you forget to checking the class '%s' is exist?"):format(str,str));
		end

		-- set property and adding child and binding functions
		local holder = (type(item) == "table") and (item.__holder or item.holder) or item; -- to __holder or holder or it self (for tabled)
		for iprop,prop in pairs({...}) do
			for index,value in pairs(prop) do
				local valueType = typeof(value);
				local indexType = typeof(index);

				-- child
				if valueType == "function" and bind(value) then -- connect event
				elseif indexType == "string" then
					item[index] = value; -- set property
				elseif indexType == "number" then -- object
					((iprop == 1) and value or value:Clone()).Parent = holder;
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

	-- function new.export(newFn,setters,getters,methods,events) -- make quad importable class
	-- 	return function ()
	-- 		return setmetatable({
	-- 			__this = newFn();
	-- 			__setters = setters;
	-- 			__getters = getters;
	-- 			__methods = methods;
	-- 			__events = events;
	-- 		},exportItemMeta);
	-- 	end;
	-- end

	-- set module calling function
	setmetatable(new,{
		__call = function (self,...)
			return new.import(...);
		end;
	});

	return new;
end

return module;