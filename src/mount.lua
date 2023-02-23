local module = {}
local insert = table.insert
local pack = table.pack

---@param shared quad_export
---@return quad_module_mount
function module.init(shared)
	local PcallGetProperty = shared.Store.PcallGetProperty
	---@class quad_module_mount
	local new = {__type = "quad_module_mount"}

	-- get Holder object
	local function getHolder(item)
		return (type(item) == "table") and (item._holder or item.holder or item.__holder) or item
	end
	new.GetHolder = getHolder

	-- mount class
	local mountClass = {__type = "quad_mount"}
	mountClass.__index = mountClass
	function mountClass:Unmount()
		local this = self.this
		local typeThis = type(this)
		if typeThis == "userdata" then
			this:Destroy()
		elseif typeThis == "table" then
			pcall(function()
				this.Parent = nil
			end)
			local destroyThis = this.Destroy
			if destroyThis then
				pcall(destroyThis,this)
			end
			if type(self.to) == "table" then
				local parentChild = rawget(self.to,"__child")
				if parentChild then
					for i,v in pairs(parentChild) do
						if v == this then
							parentChild[i] = nil
						end
					end
				end
			end
		end
		self.this = nil
	end

	-- mount function
	local function mount(to,this,holder,noReturn)
		local thisObject = this
		if type(this) == "table" then
			thisObject = rawget(this,"__object")
			local parent = rawget(this,"__parent")
			if type(parent) == "table" then
				local parentChild = rawget(parent,"__child")
				if parentChild then
					for i,v in pairs(parentChild) do
						if v == this then
							parentChild[i] = nil
						end
					end
				end
			end
			rawset(this,"__parent",to)
		end
		if thisObject then
			thisObject.Parent = holder or getHolder(to)
		else
			this.Parent = holder or getHolder(to)
		end
		if type(to) == "table" then
			local child = rawget(to,"__child")
			if not child then
				child = {}
				rawset(to,"__child",child)
			end
			insert(child,this)

			-- ChildAdded call
			local childAdded = rawget(to,"ChildAdded")
			if childAdded and PcallGetProperty(childAdded,"__type") == "quad_bindable" then
				childAdded:Fire(this)
			end
		end
		if noReturn then return end
		return setmetatable({to = to,this = this},mountClass)
	end
	new.MountOne = mount

	-- mount(s) class
	local mountsClass = {__type = "quad_mounts"}
	mountsClass.__index = mountsClass
	function mountsClass:Unmount()
		for i,v in pairs(self) do -- DO NOT IPAIRS (REASON: gc...)
			if type(i) == "number" then
				v:Unmount()
				self[i] = nil
			end
		end
	end

	function mountsClass:Add(...)
		for i = 1,select('#',...) do
			insert(self,mount(self.to,select(i,...)))
		end
	end

	-- handle __call
	setmetatable(new,{
		__call = function (self,to,...)
			-- it not working for :Add()
			-- if select("#",...) == 1 then
			-- 	return mount(to,...)
			-- end
			local mounts = {to = to}
			for i = 1,select('#',...) do
				insert(mounts,mount(to,select(i,...)))
			end
			setmetatable(mounts,mountsClass)
			return mounts
		end
	})

	return new
end

return module
