local module = {};

--[[
this feature allows get object without making some created callback and local var
but, it can't allows mulit id and object
this feature should be upgraded
]]
local wrap = coroutine.wrap;
local insert = table.insert;
local remove = table.remove;

local function catch(...)
	local passed,err = pcall(...);
	if not passed then
		warn ("[QUAD] Error occured while operating async task\n" .. tostring(err));
	end
end

local week = {__mode = "vk"};
function module.init(shared)
	local new = {};
	local items = shared.items;

	-- id space (array of object)
	local objSpaceClass = {};
	function objSpaceClass:each(func)
		for i,v in ipairs(self) do
			wrap(catch)(func,i,v);
		end
	end
	function objSpaceClass:eachSync(func)
		for i,v in ipairs(self) do
			local ret = func(i,v);
			if ret then
				break;
			end
		end
	end
	function objSpaceClass:remove(indexOrItem)
		local thisType = type(indexOrItem);
		if thisType == "number" then
			remove(self,indexOrItem);
		else
			for i,v in pairs(self) do
				if v == indexOrItem then
					remove(self,i);
					break;
				end
			end
		end
	end
	function objSpaceClass.__new()
		return setmetatable({},objSpaceClass);
	end
	function objSpaceClass:__newIndex(key,value) -- props setter
		self:each(function (this)
			this[key] = value;
		end);
	end
	objSpaceClass.__mode = "kv"; -- week link for gc
	objSpaceClass.__index = objSpaceClass;

	-- get object array with id (objSpace)
	function new.getObjects(id)
		return items[id];
	end
	-- get first object with id (not array)
	function new.getObject(id)
		local item = items[id];
		return item and item[1];
	end
	--TODO: if item is exist already, ignore this call
	-- adding object with id
	function new.addObject(ids,object)
		for id in ids:gmatch("[^,]+") do -- split by ,
			-- remove trailing, heading spaces
			id = id:gsub("^ +",""):gsub(" +$","");
			local array = items[id];
			if not array then
				array = objSpaceClass.__new();
				items[id] = array;
			end
			insert(array, object);
		end
	end

	local registerClass = {
		register = function (s,efunc)
			local self = s.store;
			local events = self.__evt;
			for key in s.key:gmatch("[^,]+") do
				key = key:gsub("^ +",""):gsub(" +$","");
				local event = events[key];
				if not event then
					event = setmetatable({},week);
					events[key] = event;
				end
				insert(event,efunc);
			end
		end;
		with = function (s,efunc)
			return setmetatable({wfunc = efunc},{__index = s});
		end;
		default = function (s,value)
			return setmetatable({dvalue = value},{__index = s});
		end;
		tween = function (s,value)
			return setmetatable({tvalue = value},{__index = s});
		end;
		from = function (s,value)
			return setmetatable({fvalue = value},{__index = s});
		end;
	};
	registerClass.__index = registerClass;

	-- bindable store object
	local store = {};
	local storeIdSpace = {};
	function store:__index(key)
		return self.__self[key] or store[key];
	end
	function store:__newindex(key,value)
		self.__self[key] = value;
		local event = self.__evt[key];
		if event then
			for _,v in pairs(event) do -- NO ipairs here
				wrap(catch)(v,store,value,key);
			end
		end
	end
	function store:__call(key,func)
		local register = self.__reg[key];
		if not register then
			register = setmetatable({
				key = key;
				store = self;
				t = "reg";
			},registerClass);
			self.__reg[key] = register;
		end

		if func then
			register.register(func);
		end
		return register;
	end
	function store:default(key,value)
		local old = self[key];
		if type(old) == "nil" then
			self[key] = value;
			return;
		end
	end
	function new.new(self,id)
		if id then
			local old = storeIdSpace[id];
			if old then
				return old;
			end
		end
		local this = setmetatable(
			{__self = self or {},__evt = setmetatable({},week),__reg = setmetatable({},week)},store
		);
		if id then
			storeIdSpace[id] = this;
		end
		return this;
	end
	function new.getStore(id)
		return storeIdSpace[id] or new.new({},id);
	end

	return new;
end

return module;
