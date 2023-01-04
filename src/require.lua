-- remove the roblox's require system,
-- now, we can call modules with string path

if (not workspace) and (not game) and (not script) then
	return;
end

return function (query)
	local typeQuery = type(query);

	if typeQuery == "string" then
		local object = script.Parent;
		query = query:gsub("/",".");
		-- local index = 0;
		query:gsub("[^%.]+",function (this)
			-- index = index + 1;
			-- if index == 1 and this == "src" then
			--     return;
			-- end
			local lastObject = object;
			object = object[this];
			if not object then
				object = lastObject.libs
				error(("[Quad] (require) object %s was not found from this worktree, require failed"):format(query));
			end
		end);
		return require(object);
	elseif typeQuery == "userdata" then
		return require(query);
	end
end;