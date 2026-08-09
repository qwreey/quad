local module = {}

--[[
this feature allows get object without making some created callback and local var
but, it can't allows mulit id and object
this feature should be upgraded
]]
local wrap   = coroutine.wrap
local insert = table.insert
local remove = table.remove
local gmatch = string.gmatch
local gsub   = string.gsub
local match  = string.match
local find  = table.find

if not find then
	find = function (table,item)
		for i,v in pairs(table) do
			if v == item then return i end
		end
		return nil
	end
end

local function catch(...)
	local passed,err = pcall(...)
	if not passed then
		warn ("[QUAD] Error occured while operating async task\n" .. tostring(err))
	end
end

local week = {__mode = "v"}

---@param shared quad_export
---@return quad_module_store
function module.init(shared)
	local warn = shared.warn
	---@class quad_module_store
	local new = {__type = "quad_module_store"}
	local items = {}
	new.Items = items

	local function RawGetProperty(item,index)
		return item[index]
	end
	local function PcallGetProperty(item,index)
		local ok,err = pcall(RawGetProperty,item,index)
		if ok then return err end
		return nil
	end
	new.PcallGetProperty = PcallGetProperty

	-- id space (array of object)
	local objectListClass = {__type = "quad_objectlist"}
	function objectListClass:EachAsync(func)
		local index = 1
		for i,v in pairs(self) do
			wrap(catch)(func,v,index)
			index = index + 1
		end
	end
	function objectListClass:Each(func)
		local index = 1
		for _,v in pairs(self) do
			local ret = func(v,index)
			index = index + 1
			if ret then
				break
			end
		end
	end
	function objectListClass:Remove(indexOrItem)
		if self.__locked then
			error("This objectList is locked, maybe used Store.GetObjects('a,b')? AdvancedObjectQuery does not support :Remove")
		end
		local thisType = type(indexOrItem)
		if thisType == "number" then
			return remove(self,indexOrItem),indexOrItem
		else
			for i,v in pairs(self) do
				if v == indexOrItem then
					return remove(self,i),i
				end
			end
		end
	end
	function objectListClass:IsEmpty()
		if next(self) then return true end
		return false
	end
	function objectListClass.__new()
		return setmetatable({},objectListClass)
	end
	function objectListClass:__newIndex(key,value) -- props setter
		self:Each(function (this)
			this[key] = value
		end)
	end
	objectListClass.__mode = "v" -- week link for gc
	objectListClass.__index = objectListClass

	-- get object array with id (objSpace)
	function new.GetObjects(ids)
		if match(ids,"[,&]") then
			local list = objectListClass.__new()
			objectListClass.__locked = true
			local checked = {}
			for query in gmatch(ids,"[^,]+") do -- split by ,
				if match(query,"&") then
					-- multi ids (and)

					-- make list of combined ids
					local queryIds = {}
					for id in gmatch(query,"[^&]+") do
						id = gsub(gsub(id,"^ +","")," +$","")
						insert(queryIds,id)
					end

					-- loop as first list
					local targetList = queryIds[1] and items[remove(queryIds,1)]
					if targetList then
						for _,item in pairs(targetList) do
							if not checked[item] then
								-- check item has all of ids from queryIds
								local ok = true
								for _,id in ipairs(queryIds) do
									local checkList = items[id]
									if (not checkList) or (not find(checkList,item)) then
										ok = false
										break
									end
								end

								-- insert in return list
								if ok then
									insert(list,item)
									-- prevent multi insert
									checked[item] = true
								end
							end
						end
					end
				else
					query = gsub(gsub(query,"^ +","")," +$","")
					local idItem = items[query]
					if idItem then
						for _,item in pairs(idItem) do
							if not checked[item] then
								insert(list,item)
								checked[item] = true -- prevent multi insert
							end
						end
					end
				end
			end
			return list
		else
			local list = items[ids]
			if list then return list end
			list = objectListClass.__new()
			items[ids] = list
			return list
		end
	end
	-- get first object with id (not array)
	function new.GetObject(id)
		local item = items[id]
		return item and item[next(item)]
	end
	-- adding object with id
	function new.AddObject(ids,object)
		-- prevent gc
		if type(object) == "userdata" then
			object:GetPropertyChangedSignal("ClassName"):Connect(function()
				return object
			end)
		end
		for id in gmatch(ids,"[^,]+") do -- split by ,
			-- remove trailing, heading spaces
			id = gsub(gsub(id,"^ +","")," +$","")
			local array = items[id]
			if not array then
				array = objectListClass.__new()
				items[id] = array
			end
			if not find(array,object) then
				insert(array, object)
			end
		end
	end

	-- resolve tween object
	local function ResolveRegisterTween(s,tween)
		if not tween then return end
		if type(tween) == "table" and PcallGetProperty(tween,"__type") == "quad_register" then
			tween = tween:CalcWithDefault(s)
		end
		local result = {}
		for i,v in pairs(tween) do
			if type(v) == "table" and PcallGetProperty(tween,"__type" == "quad_register") then
				result[i] = tween:CalcWithDefault(v)
			else
				result[i] = v
			end
		end
		return result
	end

	local registerClass = {
		__type = "quad_register";
		Unregister = function(s,efunc)
			local self = s.store
			local events = self.__evt
			for key in gmatch(s.key,"[^,]+") do
				key = gsub(gsub(key,"^ +","")," +$","")
				local event = events[key]
				if event then
					for i,v in pairs(event) do
						if efunc == v then
							event[i] = nil
						end
					end
				end
			end
		end;
		Register = function (s,efunc)
			local self = s.store
			local events = self.__evt
			for key in gmatch(s.key,"[^,]+") do
				key = gsub(gsub(key,"^ +","")," +$","")
				local event = events[key]
				if not event then
					event = setmetatable({},week)
					events[key] = event
				end
				insert(event,efunc)
			end
			return efunc
		end;
		Observe = function(s,efunc)
			local self = s.store
			local events = self.__evt
			local function update(_,newValue,key)
				local value = s:CalcWithNewValue(self,newValue,key)
				efunc(value)
			end
			insert(self.__keep,update)
			for key in gmatch(s.key,"[^,]+") do
				key = gsub(gsub(key,"^ +","")," +$","")
				local event = events[key]
				if not event then
					event = setmetatable({},week)
					events[key] = event
				end
				insert(event,update)
			end
		end;
		With = function (s,wfunc)
			-- s.wfunc = wfunc
			-- return s
			return setmetatable({wfunc = wfunc},{__index = s})
		end;
		Default = function (s,dvalue)
			-- s.dvalue = dvalue
			-- return s
			return setmetatable({dvalue = dvalue},{__index = s})
		end;
		Tween = function (s,tvalue)
			-- s.tvalue = tvalue
			-- return s
			if tvalue == true then tvalue = {} end
			return setmetatable({tvalue = tvalue},{__index = s})
		end;
		---@deprecated
		From = function (s,fvalue)
			warn "[QUAD] register:from() is deprecated. Use register:add(t:table|function) instead"
			-- s.fvalue = fvalue
			-- return s
			return setmetatable({fvalue = fvalue},{__index = s})
		end;
		Add = function (s,avalue)
			-- s.avalue = avalue
			-- return s
			return setmetatable({avalue = avalue},{__index = s})
		end;
		Link = function(s,lvalue)
			return setmetatable({avalue = lvalue},{__index = s})
		end;
		-- return init data
		CalcWithDefault = function (s,withItem)
			local with = s.wfunc
			local tstore = s.store
			local rawKey = s.key
			local tween = ResolveRegisterTween(s,s.tvalue or tstore.__tweens[rawKey])
			local from = s.fvalue
			local add = s.avalue
			local set = tstore[rawKey]
			if set ~= nil or (match(rawKey,",") and with) then
				if add then
					set = set + add
				end
				if from then
					set = from[set]
				end
				if with then
					local typeWith = type(with)
					if typeWith == "table" then
						set = with[set]
					elseif typeWith == "function" then
						set = with(tstore,set,rawKey,withItem)
					else
						error(("Unsupported type :With(). got %s"):format(typeWith))
					end
				end
				return set,tween
			else
				local dset = s.dvalue
				if dset ~= nil then
					return dset,tween
				end
				warn "[Quad] no default value found."
			end
		end;
		CalcWithNewValue = function(s,withItem,updatedValue,updatedKey)
			local with = s.wfunc
			local tstore = s.store
			local rawKey = s.key
			local tween = ResolveRegisterTween(s,s.tvalue or tstore.__tweens[rawKey])
			local from = s.fvalue
			local add = s.avalue
			if add then
				updatedValue = updatedValue + add
			end
			if from then
				updatedValue = from[updatedValue]
			end
			if with then
				updatedValue = with(tstore,updatedValue,updatedKey,withItem)
			end
			return updatedValue,tween
		end
	}
	registerClass.__index = registerClass

	-- bindable store object
	local store = {__type = "quad_store"}
	local storeIdSpace = {}
	function store:__index(key)
		local this = self.__self[key]
		if this ~= nil then
			return this
		end
		return store[key]
	end
	function store:__newindex(key,value)
		-- if got register, just copy data to self and connect
		if PcallGetProperty(value,"__type") == "quad_register" then
			error "[Quad] adding register value on store is only allowed when init store. set value request was ignored"
			-- local selfValues = self.__self
			-- local selfTweens = self.__tweens

			-- -- fetch data from origin
			-- do
			-- 	local tstore = value.store
			-- 	for tkey in gmatch(value.key,"^[,]") do
			-- 		if not selfValues[tkey] then
			-- 			selfValues[tkey] = tstore[tkey]
			-- 		end
			-- 	end
			-- end

			-- -- calc value
			-- do
			-- 	local setValue,tween = value:CalcWithDefault(self)
			-- 	selfValues[key] = setValue
			-- 	selfTweens[key] = tween
			-- end

			-- -- make event connection
			-- value:Register(function (_,newValue,eventKey)
			-- 	-- !HOLD IT SELF TO PREVENT THIS REGISTER BEGIN REMOVED FROM MEMORY
			-- 	local setValue = value:CalcWithNewValue(self,newValue,eventKey)
			-- 	self[key] = setValue
			-- end)

			-- return
		end
		self.__self[key] = value
		local event = self.__evt[key]
		if event then
			for _,v in pairs(event) do -- NO ipairs here
				wrap(catch)(v,store,value,key)
			end
		end
	end
	-- init bindings (reflect all changes into class or other store, just wrapping it)
	function new.__initStoreRegisterBinding(self,withItem,extend)
		local selfTweens = self.__tweens
		local selfValues = self.__self
		local selfKeep = self.__keep
		for key,item in pairs(selfValues) do
			if PcallGetProperty(item,"__type") == "quad_register" then
				-- fetch data from origin
				-- do
				-- 	local tstore = item.store
				-- 	for tkey in item.key:gmatch("^[,]") do
				-- 		if not selfValues[tkey] then
				-- 			selfValues[tkey] = tstore[tkey]
				-- 		end
				-- 	end
				-- end

				-- calc value
				do
					local setValue,tween = item:CalcWithDefault(withItem)
					selfValues[key] = setValue
					selfTweens[key] = tween
				end

				-- make event connection
				local function regFn(_,newValue,eventKey)
					-- !HOLD IT SELF TO PREVENT THIS REGISTER BEGIN REMOVED FROM MEMORY
					local setValue = item:CalcWithNewValue(withItem,newValue,eventKey)
					if extend then
						extend[key] = setValue
					else
						self[key] = setValue
					end
				end
				item:Register(regFn)
				insert(selfKeep,{func=regFn,register=item,key=key})
			end
		end
	end
	-- create register
	function store:__call(key,func)
		local last = self.__self[key]
		if last and type(last) == "table" and getmetatable(last) == registerClass then
			return last
		end
		local register = self.__reg[key]
		if not register then
			register = setmetatable({
				key = key;
				store = self;
			},registerClass)
			self.__reg[key] = register
		end

		if func then
			register:Register(func)
		end
		return register
	end
	function store:Default(key,value)
		if self[key] == nil then
			self[key] = value
			return
		end
	end
	function new.New(self,id)
		local this = setmetatable(
			{
				__self = self or {}, -- real value storage
				__evt = {}, -- changed event handler functions (dict of array)
				__reg = setmetatable({},week), -- save registers
				__tweens = {}, -- tweens (if inited with register, save tween and use as default tween data)
				__keep = {} -- store data which should not be destoryed
			},store
		)
		if id then -- save in id space
			storeIdSpace[id] = this
		end
		return this
	end
	local storeNew = new.New
	function new.GetStore(id)
		return storeIdSpace[id] or storeNew({},id)
	end
	local getStore = new.GetStore

	setmetatable(new,{
		__call = function (self,...)
			return getStore(...)
		end;
	})

	return new
end

return module
