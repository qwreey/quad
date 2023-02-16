local module = {}
local unpack = table.unpack
local wrap = coroutine.wrap

---@param shared quad_export
---@return quad_module_event
function module.init(shared)
	local warn = shared.warn
	---@class quad_module_event
	local new = {__type = "quad_module_event"}

	local prefix = "Event::"
	local special = {
		["Property::(.+)"] = function (this,func,property)
			this:GetPropertyChangedSignal(property):Connect(function()
				func(this,this[property])
			end)
		end;
		["CreatedSync::"] = function (this,func)
			func(this)
		end;
		["CreatedAsync::"] = function (this,func)
			wrap(func)(this)
		end;
	}

	local prefixLen = #prefix
	setmetatable(new,{
		__call = function(self,eventName)
			return prefix .. eventName
		end;
		__index = function(self,key)
			if key == "createdSync" then
				warn "[Quad] event.createdSync is deprecated. Use event.created instead"
				return self.created
			end
		end;
	})

	-- try binding, if key dose match with anything, ignore call
	function new.Bind(this,key,func,typefunc)
		if not key then
			key = this
			this = nil
		end

		-- if is advanced binding (self setted)
		typefunc = typefunc or type(func)
		local self
		if typefunc == "table" then
			local t = func
			self = t.self
			func = t.func
			if not self then self = t[1] end
			if not func then func = t[2] end
		end
		-- check prefix
		if key:sub(1,prefixLen) ~= prefix then
			return
		end
		key = key:sub(prefixLen + 1,-1)

		-- find special bindings
		for specKey,specFunc in pairs(special) do
			local find = {key:match(specKey)}
			if #find ~= 0 then
				if func then
					specFunc(this,func,unpack(find))
				end
				return true
			end
		end

		-- binding normal events
		if this then
			local event = this[key]
			if event then
				if func then
					event:Connect(function(...)
						func(self or this,...)
					end)
				end
				return true
			end
		end
	end

	-- property changed binding
	local prefixProperty = prefix .. "Property::"
	function new.Prop(name)
		return prefixProperty .. name
	end

	-- when created binding
	new.CreatedAsync = prefix .. "CreatedAsync::"
	new.Created = prefix .. "CreatedSync::"

	return new
end

return module