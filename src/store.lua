local module = {};

--[[
this feature allows get object without making some created callback and local var
but, it can't allows mulit id and object
this feature should be upgraded
]]

function module.init(shared)
	local new = {};
	local items = shared.items;

	function new.getObject(id)
		return items[id];
	end
	function new.setObject(id,object)
		items[id] = object;
	end
end

return module;
