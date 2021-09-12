local module = {};

--[[
this feature allows get object without making some created callback and local var
but, it can't allows mulit id and object
this feature should be upgraded
]]

local insert = table.insert;
local remove = table.remove;
function module.init(shared)
	local new = {};
	local items = shared.items;

	local objSpace = {};
	function objSpace:each(func)
		for i,v in ipairs(self) do
			coroutine.resume(coroutine.create(func),i,v);
		end
	end
	function objSpace:eachSync(func)
		for i,v in ipairs(self) do
			local ret = func(i,v);
			if ret then
				break;
			end
		end
	end
	function objSpace:remove(indexOrItem)
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

	function new.getObjects(id)
		return items[id];
	end
	function new.getObject(id)
		local item = items[id];
		return item and item[1];
	end
	-- TODO: if item is exist already, ignore this call
	function new.addObject(id,object)
		local array = items[id];
		if not array then
			array = setmetatable({},{__index = objSpace});
			items[id] = array;
		end
		insert(array, object);
	end

	return new;
end

return module;
