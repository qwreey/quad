local module = {};
local insert = table.insert;

---@param shared quad_export
---@return quad_module_style
function module.init(shared)
	local warn = shared.warn;
	---@class quad_module_style
	local new = {__type = "quad_module_style"};

	local styles = {};
	new.styles = styles;

	---@class quad_style
	local styleClass = {__type = "quad_style"};
	styleClass.__index = styleClass;

	function new.new(props)
		return setmetatable(props,styleClass);
	end
	local newStyle = new.new;

	setmetatable(new,{
		---@return quad_style
		__call = function (_,styleTable)
			if type(styleTable) == "string" then
				return function (nstyleTable)
					local this = newStyle(nstyleTable);
					styles[styleTable] = this;
					return this;
				end
			end
			return newStyle(styleTable);
		end
	});

	local function recursionStyleParse(style,parseTable)
		for _,value in ipairs(parseTable) do
			if value == style then
				warn("[Quad] infinity recursion detected on parsing style. ignored recursion");
				return;
			end
		end
		insert(parseTable,style);
		for key,value in pairs(style) do
			if type(key) == "number" and type(value) == "table" and value.__type == "quad_style" then
				recursionStyleParse(value,parseTable);
			end
		end
	end

	local parsed = {};
	function new.parseStyles(style)
		do -- check cache
			local cached = parsed[style];
			if cached then return cached; end
		end

		-- type check
		if type(style) ~= "table" or style.__type ~= "quad_style" then
			error(("Unknown type type '%s:%s' got"):format(tostring(style),tostring(type(style))));
		end

		local this = {}
		recursionStyleParse(style,this);

		parsed[style] = this;
		return this;
	end

	return new;
end

return module;
