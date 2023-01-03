local module = {};

--[[
this feature allows get object without making some created callback and local var
but, it can't allows mulit id and object
this feature should be upgraded
]]
local wrap = coroutine.wrap;
local insert = table.insert;
local remove = table.remove;
local gmatch = string.gmatch;
local gsub = string.gsub;

local function catch(...)
	local passed,err = pcall(...);
	if not passed then
		warn ("[QUAD] Error occured while operating async task\n" .. tostring(err));
	end
end

local week = {__mode = "v"};

---@param shared quad_export
---@return quad_module_store
function module.init(shared)
	---@class quad_module_store
	local new = {__type = "quad_module_store"};
	local items = shared.items;

	-- id space (array of object)
	local objectListClass = {__type = "quad_objectlist"};
	function objectListClass:each(func)
		local index = 1;
		for i,v in pairs(self) do
			wrap(catch)(func,index,v);
			index = index + 1;
		end
	end
	function objectListClass:eachSync(func)
		local index = 1;
		for _,v in pairs(self) do
			local ret = func(index,v);
			index = index + 1;
			if ret then
				break;
			end
		end
	end
	function objectListClass:remove(indexOrItem)
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
	function objectListClass:isEmpty()
		if next(self) then return true; end
		return false;
	end
	function objectListClass.__new()
		return setmetatable({},objectListClass);
	end
	function objectListClass:__newIndex(key,value) -- props setter
		self:each(function (this)
			this[key] = value;
		end);
	end
	objectListClass.__mode = "kv"; -- week link for gc
	objectListClass.__index = objectListClass;

	-- get object array with id (objSpace)
	function new.getObjects(id)
		local list = items[id];
		if list then return list; end
		list = objectListClass.__new(id);
		items[id] = list;
		return list;
	end
	-- get first object with id (not array)
	function new.getObject(id)
		local item = items[id];
		return item and item[next(item)];
	end
	--TODO: if item is exist already, ignore this call
	-- adding object with id
	function new.addObject(ids,object)
		for id in gmatch(ids,"[^,]+") do -- split by ,
			-- remove trailing, heading spaces
			id = gsub(gsub(id,"^ +","")," +$","");
			local array = items[id];
			if not array then
				array = objectListClass.__new();
				items[id] = array;
			end
			insert(array, object);
		end
	end

	local registerClass = {
		__type = "quad_register";
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
		---@deprecated
		from = function (s,value)
			warn "[QUAD] register:from() is deprecated. You can use register:add(t:table|function) instead";
			return setmetatable({fvalue = value},{__index = s});
		end;
		add = function (s,value)
			return setmetatable({avalue = value},{__index = s});
		end;
	};
	registerClass.__index = registerClass;

	-- bindable store object
	local store = {__type = "quad_store"};
	local storeIdSpace = {};
	function store:__index(key)
		local this = self.__self[key];
		if this ~= nil then
			return this;
		end
		return store[key];
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
		local last = self.__self[key];
		if last and type(last) == "table" and getmetatable(last) == registerClass then
			return last;
		end
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
		if old == nil then
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
			{__self = self or {},__evt = {},__reg = setmetatable({},week)},store
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
