local module = {};

--[[
this feature allows get object without making some created callback and local var
but, it can't allows mulit id and object
this feature should be upgraded
]]

local insert = table.insert;
function module.init(shared)
	local new = {};
	local items = shared.items;

	local objSpace = {};
	function objSpace:each(func)
		for i,v in ipairs(self) do
			local ret = func(i,v);
			if ret then
				break;
			end
		end
	end

	function new.getObjects(id)
		return items[id];
	end
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
